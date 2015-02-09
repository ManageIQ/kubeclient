require 'minitest/autorun'
require 'webmock/minitest'
require 'kubeclient/service'
require 'json'
require './lib/kubeclient'

# Service entity tests
class ServiceTest < MiniTest::Test
  def test_get_from_json_v1
    mock = Service.new(
      'kind' => 'Service',
      'id' => 'redis-service',
      'uid' => 'fb01a69c-8ae2-11e4-acc5-3c970e4a436a',
      'namespace' => 'default',
      'port' => 80,
      'protocol' => 'TCP',
      'labels' => {
        'component' => 'apiserver',
        'provider' => 'kubernetes'
      },
      'selector' => nil,
      'creation_timestamp' => '2014-12-23T22:33:40+02:00',
      'self_link' => '/api/v1beta1/services/kubernetes-ro?namespace=default',
      'resource_version' => 4,
      'api_version' => 'v1beta1',
      'container_port' => 0,
      'portal_ip' => '10.0.0.54'
    )

    assert_equal 'redis-service', mock.id
    assert_equal 'apiserver', mock.labels.component
  end

  def test_construct_our_own_service
    our_service = Service.new
    our_service.id = 'redis-service'
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

  def test_conversion_from_json_v1
    stub_request(:get, /\/services/)
      .to_return(body: open_test_json_file('service_b1.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta1'
    service = client.get_service 'redisslave'

    assert_instance_of(Service, service)
    # checking that creationTimestamp was renamed properly
    assert_equal('2014-12-28T17:37:21+02:00', service.creationTimestamp)
    assert_equal('6a022e83-8ea7-11e4-a6e7-3c970e4a436a', service.uid)
    assert_equal('redisslave', service.id)
    assert_equal(8, service.resourceVersion)
    assert_equal('v1beta1', service.apiVersion)
    assert_equal('10.0.0.248', service.portalIP)
    assert_equal(6379, service.containerPort)
    assert_equal('TCP', service.protocol)
    assert_equal(10_001, service.port)
    assert_equal('default', service.namespace)
  end

  def test_conversion_from_json_v3
    stub_request(:get, /\/services/)
      .to_return(body: open_test_json_file('service_b3.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta3'
    service = client.get_service 'redisslave'

    assert_instance_of(Service, service)
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
    our_service = Service.new
    our_service.id = 'redis-service'
    our_service.port = 80
    our_service.protocol = 'TCP'
    our_service.labels = {}
    our_service.labels.component = 'apiserver'
    our_service.labels.provider = 'kubernetes'

    stub_request(:delete, /\/services/)
      .to_return(status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta1'
    client.delete_service our_service.id
  end
end
