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

  def test_exception
    stub_request(:post, /\/services/)
      .to_return(body: open_test_json_file('service_exception_b1.json'),
                 status: 409)

    service = Kubeclient::Service.new
    service.id = 'redisslave'
    service.port = 80
    service.container_port = 6379
    service.protocol = 'TCP'

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta1'

    exception = assert_raises(KubeException) do
      service = client.create_service service
    end

    assert_instance_of(KubeException, exception)
    assert_equal('service redisslave already exists', exception.message)
    assert_equal(409, exception.error_code)
  end

  def test_entity_list
    stub_request(:get, /\/services/)
      .to_return(body: open_test_json_file('entity_list_b1.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta1'
    services = client.get_services

    refute_empty(services)
    assert_instance_of(Kubeclient::EntityList, services)
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
    assert_instance_of(Kubeclient::EntityList, pods)
    assert_equal(0, pods.size)
  end

  def test_get_all
    stub_request(:get, /\/services/)
      .to_return(body: open_test_json_file('get_all_services_b1.json'),
                 status: 200)

    stub_request(:get, /\/pods/)
      .to_return(body: open_test_json_file('get_all_pods_b1.json'),
                 status: 200)

    stub_request(:get, /\/nodes/)
      .to_return(body: open_test_json_file('get_all_nodes_b1.json'),
                 status: 200)

    stub_request(:get, /\/replicationControllers/)
      .to_return(body: open_test_json_file('get_all_replication_b1.json'),
                 status: 200)

    stub_request(:get, /\/events/)
      .to_return(body: open_test_json_file('event_list_b3.json'), status: 200)

    stub_request(:get, /\/endpoints/)
      .to_return(body: open_test_json_file('endpoint_list_b3.json'),
                 status: 200)

    stub_request(:get, /\/namespaces/)
      .to_return(body: open_test_json_file('namespace_list_b3.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta1'
    result = client.all_entities
    assert_equal(7, result.keys.size)
    assert_instance_of(Kubeclient::EntityList, result['node'])
    assert_instance_of(Kubeclient::EntityList, result['service'])
    assert_instance_of(Kubeclient::EntityList, result['replication_controller'])
    assert_instance_of(Kubeclient::EntityList, result['pod'])
    assert_instance_of(Kubeclient::EntityList, result['event'])
    assert_instance_of(Kubeclient::EntityList, result['namespace'])
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
