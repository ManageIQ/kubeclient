require 'test_helper'

# Service entity tests
class TestService < MiniTest::Test
  def test_construct_our_own_service
    our_service = Kubeclient::Service.new
    our_service.name = 'redis-service'
    our_service.port = 80
    our_service.protocol = 'TCP'
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

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta3'
    service = client.get_service 'redisslave'

    assert_instance_of(Kubeclient::Service, service)
    # checking that creationTimestamp was renamed properly
    assert_equal('2015-01-22T14:20:05+02:00',
                 service.metadata.creationTimestamp)
    assert_equal('ffb153db-a230-11e4-a36b-3c970e4a436a', service.metadata.uid)
    assert_equal('kubernetes-ro', service.metadata.name)
    assert_equal('4', service.metadata.resourceVersion)
    assert_equal('v1beta3', service.apiVersion)
    assert_equal('10.0.0.154', service.spec.portalIP)
    assert_equal(0, service.spec.containerPort)
    assert_equal('TCP', service.spec.protocol)
    assert_equal(80, service.spec.port)
    assert_equal('default', service.metadata.namespace)
  end

  def test_delete_service
    our_service = Kubeclient::Service.new
    our_service.name = 'redis-service'
    our_service.port = 80
    our_service.protocol = 'TCP'
    our_service.labels = {}
    our_service.labels.component = 'apiserver'
    our_service.labels.provider = 'kubernetes'

    stub_request(:delete, /\/services/)
      .to_return(status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta3'
    client.delete_service our_service.id
  end
end
