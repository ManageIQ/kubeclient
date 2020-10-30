require_relative 'test_helper'

class HTTPClientTest < MiniTest::Test
  def test_create
    kubeclient = Kubeclient::Client.new(
      'http://localhost:8000',
      'v1',
      http_client_type: 'httpclient'
    )

    assert_instance_of(HTTPClient, kubeclient.http_client)
  end

  def test_get_namespaces
    stub_core_api_list
    stub_request(:get, 'http://localhost:8000/api/v1/namespaces/staging')
      .to_return(body: open_test_file('namespace.json'), status: 200)

    kubeclient = Kubeclient::Client.new(
      'http://localhost:8000',
      http_client_type: 'httpclient'
    )

    kubeclient.get_entity('namespaces', 'staging')
  end
end
