require 'test_helper'

# Http proxy test
class TestHttpProxy < MiniTest::Test
  PARTIAL_PATH = '/some/arbitrary/path'
  def setup
    @path = "http://host:8080/api/v1/proxy/namespaces/ns/services/srvname:5001-tcp#{PARTIAL_PATH}"
    @client = Kubeclient::Client.new 'http://host:8080/api/', 'v1',
                                     auth_options: { bearer_token: 'valid_token' }
    @proxy = @client.proxy_url_service('services', 'srvname', '5001-tcp', 'ns')
  end

  def test_instance_type
    assert_instance_of(Kubeclient::Common::HttpProxyWrapper, @proxy)
  end

  def test_proxied_post_req
    stub_request(:post, @path)
      .with(headers: { Authorization: 'Bearer valid_token' },
            body: '{"hello" => "world", "foo" => "bar"}')
      .to_return(body: open_test_json_file('http_proxy.json'),
                 status: 200)

    @proxy.post(PARTIAL_PATH,
                '{"hello" => "world", "foo" => "bar"}')
    assert_requested(:post,
                     @path,
                     times: 1)
  end

  def test_proxied_get_req
    get_req_helper(@path, PARTIAL_PATH, @proxy)
  end

  def test_proxied_get_req_empty_ns
    full_path = "http://host:8080/api/v1/proxy/pods/srvname:5001-tcp#{PARTIAL_PATH}"
    proxy = @client.proxy_url_service('pods', 'srvname', '5001-tcp')
    get_req_helper(full_path, PARTIAL_PATH, proxy)
  end

  def get_req_helper(full_path, get_req_path, proxy)
    stub_request(:get, full_path)
      .with(headers: { Authorization: 'Bearer valid_token' })
      .to_return(body: open_test_json_file('http_proxy.json'),
                 status: 200)

    proxy.get(get_req_path)
    assert_requested(:get,
                     full_path,
                     times: 1)
  end
end
