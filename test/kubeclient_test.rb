require 'minitest/autorun'
require 'json'
require 'webmock/minitest'
require './lib/kubeclient'

def open_test_json_file(name)
  File.new(File.join(File.dirname(__FILE__), 'json', name))
end

# Kubernetes client entity tests
class KubeClientTest < MiniTest::Test
  def test_json
    our_object = Service.new
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

    service = Service.new
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
    assert_instance_of(EntityList, services)
    assert_equal('Service', services.kind)
    assert_equal(2, services.size)
    assert_instance_of(Service, services[0])
    assert_instance_of(Service, services[1])
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

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta1'
    result = client.get_all_entities
    assert_equal(5, result.keys.size)
    assert_instance_of(EntityList, result['node'])
    assert_instance_of(EntityList, result['service'])
    assert_instance_of(EntityList, result['replication_controller'])
    assert_instance_of(EntityList, result['pod'])
    assert_instance_of(EntityList, result['event'])
    assert_instance_of(Service, result['service'][0])
    assert_instance_of(Node, result['node'][0])
    assert_instance_of(Event, result['event'][0])
  end

  private

  # dup method creates a shallow copy which is not good in this case
  # since rename_keys changes the input hash
  # hence need to create a deep_copy
  def deep_copy(hash)
    Marshal.load(Marshal.dump(hash))
  end
end
