require 'test_helper'

def open_test_json_file(name)
  File.new(File.join(File.dirname(__FILE__), 'json', name))
end

# Kubernetes client entity tests
class KubeClientTest < MiniTest::Test
  def test_json
    our_object = Kubeclient::Service.new
    our_object.foo = 'bar'
    our_object.nested = {}
    our_object.nested.again = {}
    our_object.nested.again.again = {}
    our_object.nested.again.again.name = 'aaron'

    expected = { 'foo' => 'bar', 'nested' => { 'again' => { 'again' =>
                 { 'name' => 'aaron' } } } }

    assert_equal(expected, JSON.parse(JSON.dump(our_object.to_h)))
  end

  def test_pass_uri
    # URI::Generic#hostname= was added in ruby 1.9.3 and will automatically
    # wrap an ipv6 address in []
    uri = URI::HTTP.build(port: 8080)
    uri.hostname = 'localhost'
    client = Kubeclient::Client.new uri
    rest_client = client.rest_client
    assert_equal 'http://localhost:8080/api/v1beta3', rest_client.url.to_s
  end

  def test_no_path_in_uri
    client = Kubeclient::Client.new 'http://localhost:8080', 'v1beta3'
    rest_client = client.rest_client
    assert_equal 'http://localhost:8080/api/v1beta3', rest_client.url.to_s
  end

  def test_no_version_passed
    client = Kubeclient::Client.new 'http://localhost:8080'
    rest_client = client.rest_client
    assert_equal 'http://localhost:8080/api/v1beta3', rest_client.url.to_s
  end

  def test_exception
    stub_request(:post, /\/services/)
      .to_return(body: open_test_json_file('namespace_exception_b3.json'),
                 status: 409)

    service = Kubeclient::Service.new
    service.id = 'redisslave'
    service.port = 80
    service.container_port = 6379
    service.protocol = 'TCP'

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta3'

    exception = assert_raises(KubeException) do
      service = client.create_service service
    end

    assert_instance_of(KubeException, exception)
    assert_equal("converting  to : type names don't match (Pod, Namespace)",
                 exception.message)
    assert_equal(409, exception.error_code)
  end

  def test_api
    stub_request(:get, 'http://localhost:8080/api')
      .to_return(status: 200, body: open_test_json_file('versions_list.json'))

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta3'
    response = client.api
    assert_includes(response, 'versions')
  end

  def test_api_valid
    stub_request(:get, 'http://localhost:8080/api')
      .to_return(status: 200, body: open_test_json_file('versions_list.json'))

    client = Kubeclient::Client.new 'http://localhost:8080/api/'
    assert client.api_valid?
  end

  def test_api_valid_with_invalid_json
    stub_request(:get, 'http://localhost:8080/api')
      .to_return(status: 200, body: '{}')

    client = Kubeclient::Client.new 'http://localhost:8080/api/'
    refute client.api_valid?
  end

  def test_api_valid_with_bad_endpoint
    stub_request(:get, 'http://localhost:8080/api')
      .to_return(status: [404, 'Resource Not Found'])

    client = Kubeclient::Client.new 'http://localhost:8080/api/'
    assert_raises(KubeException) { client.api_valid? }
  end

  def test_api_valid_with_non_json
    stub_request(:get, 'http://localhost:8080/api')
      .to_return(status: 200, body: '<html></html>')

    client = Kubeclient::Client.new 'http://localhost:8080/api/'
    assert_raises(JSON::ParserError) { client.api_valid? }
  end

  def test_nonjson_exception
    stub_request(:get, /\/servic/)
      .to_return(body: open_test_json_file('service_illegal_json_404.json'),
                 status: 404)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta3'

    exception = assert_raises(KubeException) do
      client.get_services
    end

    assert_instance_of(KubeException, exception)
    assert_equal('404 Resource Not Found', exception.message)
    assert_equal(404, exception.error_code)
  end

  def test_entity_list
    stub_request(:get, /\/services/)
      .to_return(body: open_test_json_file('entity_list_b3.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta3'
    services = client.get_services

    refute_empty(services)
    assert_instance_of(Kubeclient::Common::EntityList, services)
    assert_equal('Service', services.kind)
    assert_equal(2, services.size)
    assert_instance_of(Kubeclient::Service, services[0])
    assert_instance_of(Kubeclient::Service, services[1])
  end

  def test_empty_list
    stub_request(:get, /\/pods/)
      .to_return(body: open_test_json_file('empty_pod_list_b3.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta3'
    pods = client.get_pods
    assert_instance_of(Kubeclient::Common::EntityList, pods)
    assert_equal(0, pods.size)
  end

  def test_get_all
    stub_request(:get, /\/services/)
      .to_return(body: open_test_json_file('get_all_services_b3.json'),
                 status: 200)

    stub_request(:get, /\/pods/)
      .to_return(body: open_test_json_file('pod_list_b3.json'),
                 status: 200)

    stub_request(:get, /\/nodes/)
      .to_return(body: open_test_json_file('node_list_b3.json'),
                 status: 200)

    stub_request(:get, /\/replicationcontrollers/)
      .to_return(body: open_test_json_file('replication_controller_list_' \
                                    'b3.json'), status: 200)

    stub_request(:get, /\/events/)
      .to_return(body: open_test_json_file('event_list_b3.json'), status: 200)

    stub_request(:get, /\/endpoints/)
      .to_return(body: open_test_json_file('endpoint_list_b3.json'),
                 status: 200)

    stub_request(:get, /\/namespaces/)
      .to_return(body: open_test_json_file('namespace_list_b3.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta3'
    result = client.all_entities
    assert_equal(7, result.keys.size)
    assert_instance_of(Kubeclient::Common::EntityList, result['node'])
    assert_instance_of(Kubeclient::Common::EntityList, result['service'])
    assert_instance_of(Kubeclient::Common::EntityList,
                       result['replication_controller'])
    assert_instance_of(Kubeclient::Common::EntityList, result['pod'])
    assert_instance_of(Kubeclient::Common::EntityList, result['event'])
    assert_instance_of(Kubeclient::Common::EntityList, result['namespace'])
    assert_instance_of(Kubeclient::Service, result['service'][0])
    assert_instance_of(Kubeclient::Node, result['node'][0])
    assert_instance_of(Kubeclient::Event, result['event'][0])
    assert_instance_of(Kubeclient::Endpoint, result['endpoint'][0])
    assert_instance_of(Kubeclient::Namespace, result['namespace'][0])
  end

  private

  # dup method creates a shallow copy which is not good in this case
  # since rename_keys changes the input hash
  # hence need to create a deep_copy
  def deep_copy(hash)
    Marshal.load(Marshal.dump(hash))
  end
end
