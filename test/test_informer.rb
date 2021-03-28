# frozen_string_literal: true

require_relative 'test_helper'

# tests with_retries in kubeclient.rb
class RetryTest < MiniTest::Test
  def setup
    super
    skip if RUBY_ENGINE == 'truffleruby' # TODO: race condition in truffle-ruby fails random tests
    @slept = []
    stub_core_api_list
  end

  # prevent leftover threads from causing trouble
  def teardown
    (Thread.list - [Thread.current]).each(&:kill)
    super
  end

  def test_lists_at_start
    list = stub_list
    watch = stub_request(:get, %r{/v1/watch/pods}).to_return(body: '', status: 200)
    with_worker do
      assert_equal(['a'], informer.list.map { |p| p.metadata.name })
    end
    assert_requested(list, times: 1)
    assert_requested(watch, times: 1)
  end

  def test_watches_for_updates
    lock = Mutex.new
    lock.lock
    list = stub_list
    watch = stub_request(:get, %r{/v1/watch/pods}).with { lock.lock }.to_return(
      body: {
        type: 'MODIFIED', object: { metadata: { name: 'b', uid: 'id1' } }
      }.to_json << "\n",
      status: 200
    )

    with_worker do
      assert_equal(['a'], informer.list.map { |p| p.metadata.name })
      lock.unlock # trigger watch
      sleep(0.02) # wait for watch to finish
      assert_equal(['b'], informer.list.map { |p| p.metadata.name })
    end

    assert_requested(list, times: 1)
    assert_requested(watch, times: 1)
  end

  def test_watches_for_add
    stub_list
    stub_request(:get, %r{/v1/watch/pods}).to_return(
      body: {
        type: 'ADDED', object: { metadata: { name: 'b', uid: 'id2' } }
      }.to_json << "\n",
      status: 200
    )

    with_worker do
      assert_equal(['a', 'b'], informer.list.map { |p| p.metadata.name })
    end
  end

  def test_watches_for_delete
    stub_list
    stub_request(:get, %r{/v1/watch/pods}).to_return(
      body: {
        type: 'DELETED', object: { metadata: { name: 'b', uid: 'id1' } }
      }.to_json << "\n",
      status: 200
    )

    with_worker do
      assert_equal([], informer.list.map { |p| p.metadata.name })
    end
  end

  def test_restarts_on_error
    list = stub_list
    watch = stub_request(:get, %r{/v1/watch/pods}).to_return(
      body: { type: 'ERROR' }.to_json << "\n",
      status: 200
    )
    slept = []
    informer.stubs(:sleep).with { |x| slept << x; sleep(0.01) }

    with_worker do
      assert_equal(['a'], informer.list.map { |p| p.metadata.name })
      sleep(0.05)
    end

    assert slept.size >= 2, slept
    assert_requested(list, at_least_times: 2)
    assert_requested(watch, at_least_times: 2)
  end

  def test_can_watch_watches
    list = stub_list
    watch = stub_request(:get, %r{/v1/watch/pods}).to_return(
      body: {
        type: 'ADDED', object: { metadata: { name: 'b', uid: 'id2' } }
      }.to_json << "\n",
      status: 200
    )

    seen1 = []
    seen2 = []
    seeer1 = Thread.new { informer.watch { |n| seen1 << n; break } }
    seeer2 = Thread.new { informer.watch { |n| seen2 << n; break } }
    sleep(0.01) until informer.instance_variable_get(:@watching).size == 2

    with_worker do
      assert_equal([['ADDED'], ['ADDED']], [seen1.map(&:type), seen2.map(&:type)])
    end

    assert_requested(list, times: 1)
    assert_requested(watch, times: 1)
  ensure
    seeer1&.kill
    seeer2&.kill
  end

  def test_timeout
    timeout = 0.1
    informer.instance_variable_set(:@reconcile_timeout, timeout)
    stub_list
    Kubeclient::Common::WatchStream.any_instance.expects(:finish)
    stub_request(:get, %r{/v1/watch/pods})
    with_worker { sleep(timeout * 1.9) }
  end

  private

  def with_worker
    informer.start_worker
    sleep(0.03) # wait for worker to watch
    yield
  ensure
    informer.stop_worker
  end

  def stub_list
    stub_request(:get, %r{/v1/pods}).to_return(body: pods_reply.to_json, status: 200)
  end

  def client
    @client ||= Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
  end

  def informer
    @informer ||= Kubeclient::Informer.new(client, 'pods')
  end

  def pods_reply
    @pods_reply ||= {
      metadata: { resourceVersion: 1 },
      items: [{ metadata: { name: 'a', uid: 'id1' } }]
    }
  end
end
