# frozen_string_literal: true

require_relative 'test_helper'

# tests with_retries in common.rb
class RetryTest < MiniTest::Test
  def setup
    @slept = []
    client.stubs(:sleep).with { |t| @slept << t }
    stub_core_api_list
  end

  def test_no_retry_on_success
    request = stub_request(:get, %r{/pods}).to_return(body: '{}', status: 200)
    assert_equal([], client.get_pods)
    assert_equal([], @slept)
    assert_requested(request, times: 1)
  end

  def test_no_retry_on_not_found
    request = stub_request(:get, %r{/pods}).to_return(body: '{}', status: 404)
    assert_raises(Kubeclient::ResourceNotFoundError) { client.get_pod('foo') }
    assert_equal([], @slept)
    assert_requested(request, times: 1)
  end

  def test_retry_until_success
    request = stub_request(:get, %r{/pods}).to_return(
      { body: '{}', status: 400 },
      body: '{}', status: 200
    )
    assert_equal([], client.get_pods)
    assert_equal([0.1], @slept)
    assert_requested(request, times: 2)
  end

  def test_retry_until_failure
    request = stub_request(:get, %r{/pods}).to_return({ body: '{}', status: 400 })
    assert_raises(Kubeclient::HttpError) { client.get_pods }
    assert_equal([0.1, 0.2, 0.4], @slept)
    assert_requested(request, times: 4)
  end

  def test_retry_large_backoff
    @client.instance_variable_set(:@retries, 10)
    request = stub_request(:get, %r{/pods}).to_return({ body: '{}', status: 400 })
    assert_raises(Kubeclient::HttpError) { client.get_pods }
    assert_equal([0.1, 0.2, 0.4, 1, 1, 1, 1, 1, 1, 1], @slept)
    assert_requested(request, times: 11)
  end

  private

  def client
    @client ||= Kubeclient::Client.new('http://localhost:8080/api/', 'v1', retries: 3)
  end
end
