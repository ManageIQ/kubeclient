# frozen_string_literal: true

require_relative 'helper'
require 'stringio'
require 'logger'

class TestInformer < MiniTest::Test
  def setup
    super
    skip if RUBY_ENGINE == 'truffleruby' # TODO: race condition in truffle-ruby fails random tests
    @slept = []
    stub_core_api_list
    logger.expects(:error).with { |m| raise "Error: #{m}" }.never # catch problems early
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

  def test_passing_options
    @informer = Kubeclient::Informer.new(client, 'pods', logger: logger,
                                         options: { namespace: 'my-namespace' })
    list = stub_request(:get, %r{/v1/namespaces/my-namespace/pods})
           .to_return(body: pods_reply.to_json, status: 200)
    watch = stub_request(:get, %r{/v1/watch/namespaces/my-namespace/pods})
            .to_return(body: '', status: 200)
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
    watch_requests = []
    watch = stub_request(:get, %r{/v1/watch/pods}).to_return do |request|
      watch_requests << request
      {
        body: { type: 'ERROR' }.to_json << "\n",
        status: 200
      }
    end
    informer.stubs(:sleep).with { sleep(0.02) }

    with_worker do
      assert_equal(['a'], informer.list.map { |p| p.metadata.name })
      sleep(0.2) until watch_requests.count > 2 # wait for few restarts
    end

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

    # start watchers
    seen1 = []
    seen2 = []
    seeer1 = Thread.new { informer.watch { |n| seen1 << n; break } }
    seeer2 = Thread.new { informer.watch { |n| seen2 << n; break } }

    # wait for them to be registered and ready to receive items
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
    list = stub_list
    Kubeclient::Common::WatchStream.any_instance.expects(:finish)
    watch = stub_request(:get, %r{/v1/watch/pods})

    with_worker { sleep(timeout * 1.9) }

    assert_requested(list)
    assert_requested(watch)
  end

  # test condition that can happen when client calls stop_worker
  # immediatelly after return from start_worker
  # (e.g. in case data from initial list are satisfactory)
  def test_stop_before_watcher_each_race_condition
    stub_list

    # pause watcher to give time to call the stop_worker
    watcher_instance = WatcherMock.new
    watcher_instance.paused = true
    client.stubs(:watch_entities).returns(watcher_instance)

    informer.start_worker

    # wait until execution is at watcher.each
    sleep(0.1) until watcher_instance.waiting

    # stop worker
    stop_thread = Thread.new do
      informer.stop_worker
    end

    # unpause watcher after stop is set to true
    sleep(0.1) until informer.instance_variable_get('@stopped')
    watcher_instance.paused = false

    # wait for stop to return
    stop_thread.join
    assert_equal(watcher_instance.finished, true)
  end

  def test_stop_before_watcher_created_race_condition
    stub_list
    stub_request(:get, %r{/v1/watch/pods}).to_return(body: '', status: 200)

    # pause before creating the watcher
    paused = true
    waiting = false
    watcher_instance = WatcherMock.new

    client.stubs(:watch_entities).with do
      waiting = true
      sleep(0.1) while paused
      true
    end.returns(watcher_instance)

    informer.start_worker

    # wait until execution is at client.watch_entities
    sleep(0.1) until waiting

    # stop worker
    stop_thread = Thread.new do
      informer.stop_worker
    end

    # unpause watch_entities after stop is set to true
    sleep(0.1) until informer.instance_variable_get('@stopped')
    paused = false

    # wait for stop to return
    stop_thread.join
    assert_equal(watcher_instance.finished, true)
  end

  private

  def with_worker
    informer.start_worker
    sleep(0.01) until informer.instance_variable_get(:@watcher) # wait for worker to watch
    sleep(0.01) # give some time for threads to store
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
    @informer ||= Kubeclient::Informer.new(client, 'pods', logger: logger)
  end

  def logger
    @logger ||= Logger.new('/dev/null')
  end

  def pods_reply
    @pods_reply ||= {
      metadata: { resourceVersion: 1 },
      items: [{ metadata: { name: 'a', uid: 'id1' } }]
    }
  end

  class WatcherMock
    attr_accessor :finished
    attr_accessor :waiting
    attr_accessor :paused

    def finish
      @finished = true
    end

    def each
      @waiting = true
      sleep(0.1) while @paused

      @finished = false
      sleep(0.1) until @finished # simulate blocking for receiving events forever (until finished)
    end
  end
end
