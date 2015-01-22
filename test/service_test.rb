require 'minitest/autorun'
require 'webmock/minitest'
require 'kubeclient/service'
require 'json'
require './lib/kubeclient'

class ServiceTest < MiniTest::Test
  def test_get_from_json
    # creation of the entity from json as if it was read from the server REST api
    mock = Service.new({"kind"=>"Service", "id"=>"redis-service", "uid"=>"fb01a69c-8ae2-11e4-acc5-3c970e4a436a", "namespace"=>"default", "port"=>80, "protocol"=>"TCP", "labels"=>{"component"=>"apiserver", "provider"=>"kubernetes"}, "selector"=>nil, "creation_timestamp"=>"2014-12-23T22:33:40+02:00", "self_link"=>"/api/v1beta1/services/kubernetes-ro?namespace=default", "resource_version"=>4, "api_version"=>"v1beta1", "container_port"=>0, "portal_ip"=>"10.0.0.54"})

    assert_equal 'redis-service', mock.id
    assert_equal 'apiserver', mock.labels.component
  end

  def test_construct_our_own_service
    our_service = Service.new
    our_service.id = 'redis-service'
    our_service.port = 80
    our_service.protocol = "TCP"
    our_service.labels = {}
    our_service.labels.component = 'apiserver'
    our_service.labels.provider = 'kubernetes'

    assert_equal "kubernetes", our_service.labels.provider
    assert_equal "apiserver", our_service.labels.component

    hash = our_service.to_h

    assert_equal our_service.labels.provider, hash[:labels][:provider]
  end


  def test_conversion_from_json
    json_response = "{\n  \"kind\": \"Service\",\n  \"id\": \"redisslave\",\n  \"uid\": \"6a022e83-8ea7-11e4-a6e7-3c970e4a436a\",\n  \"creationTimestamp\": \"2014-12-28T17:37:21+02:00\",\n  \"selfLink\": \"/api/v1beta1/services/redisslave?namespace=default\",\n  \"resourceVersion\": 8,\n  \"apiVersion\": \"v1beta1\",\n  \"namespace\": \"default\",\n  \"port\": 10001,\n  \"protocol\": \"TCP\",\n  \"labels\": {\n    \"name\": \"redisslave\"\n  },\n  \"selector\": {\n    \"name\": \"redisslave\"\n  },\n  \"containerPort\": 6379,\n  \"portalIP\": \"10.0.0.248\"\n}"

    stub_request(:get, /.*services*/).
        to_return(:body => json_response, :status => 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/' , "v1beta1"
    service = client.get_service "redisslave"

    assert_instance_of(Service,service)
    #checking that creationTimestamp was renamed properly
    assert_equal("2014-12-28T17:37:21+02:00",service.creationTimestamp)
    assert_equal("6a022e83-8ea7-11e4-a6e7-3c970e4a436a",service.uid)
    assert_equal("redisslave",service.id)
    assert_equal(8,service.resourceVersion)
    assert_equal("v1beta1",service.apiVersion)
    assert_equal("10.0.0.248",service.portalIP)
    assert_equal(6379,service.containerPort)
    assert_equal("TCP",service.protocol)
    assert_equal(10001,service.port)
    assert_equal("default",service.namespace)

  end

  def test_delete_service
    our_service = Service.new
    our_service.id = 'redis-service'
    our_service.port = 80
    our_service.protocol = "TCP"
    our_service.labels = {}
    our_service.labels.component = 'apiserver'
    our_service.labels.provider = 'kubernetes'

    stub_request(:delete, /.*services*/).
        to_return(:status => 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/' , "v1beta1"
    client.delete_service our_service.id

  end
end
