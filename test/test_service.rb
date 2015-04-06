require 'test_helper'

# Service entity tests
class TestService < MiniTest::Test
  def test_construct_our_own_service
    our_service = Kubeclient::Service.new
    our_service.name = 'redis-service'
    # TODO, new ports assignment to be added
    our_service.labels = {}
    our_service.labels.component = 'apiserver'
    our_service.labels.provider = 'kubernetes'

    assert_equal('kubernetes', our_service.labels.provider)
    assert_equal('apiserver', our_service.labels.component)

    hash = our_service.to_h

    assert_equal our_service.labels.provider, hash[:labels][:provider]
  end

  def test_conversion_from_json_v3
    stub_request(:get, /\/services/)
      .to_return(body: open_test_json_file('service_b3.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/'
    service = client.get_service 'redisslave'

    assert_instance_of(Kubeclient::Service, service)
    assert_equal('2015-04-05T13:00:31Z',
                 service.metadata.creationTimestamp)
    assert_equal('bdb80a8f-db93-11e4-b293-f8b156af4ae1', service.metadata.uid)
    assert_equal('redis-slave', service.metadata.name)
    assert_equal('2815', service.metadata.resourceVersion)
    assert_equal('v1beta3', service.apiVersion)
    assert_equal('10.0.0.140', service.spec.portalIP)
    assert_equal('development', service.metadata.namespace)

    assert_equal('TCP', service.spec.ports[0].protocol)
    assert_equal(6379, service.spec.ports[0].port)
    assert_equal('', service.spec.ports[0].name)
    assert_equal('redis-server', service.spec.ports[0].targetPort)
  end

  def test_delete_service
    our_service = Kubeclient::Service.new
    our_service.name = 'redis-service'
    # TODO, new ports assignment to be added
    our_service.labels = {}
    our_service.labels.component = 'apiserver'
    our_service.labels.provider = 'kubernetes'

    stub_request(:delete, /\/services/)
      .to_return(status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta3'
    client.delete_service our_service.id
  end
end
