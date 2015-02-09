require 'minitest/autorun'
require 'json'
require 'webmock/minitest'
require './lib/kubeclient'

def open_test_json_file(name)
  File.new(File.join(File.dirname(__FILE__), 'json', name))
end

class KubeClientTest < MiniTest::Test

  def test_json
    our_object = Service.new
    our_object.foo = 'bar'
    our_object.nested = {}
    our_object.nested.again = {}
    our_object.nested.again.again = {}
    our_object.nested.again.again.name = "aaron"

    hash = JSON.parse(JSON.dump(our_object.to_h))
    assert_equal({"foo"=>"bar", "nested"=>{"again"=>{"again"=>{"name"=>"aaron"}}}},
                 hash)
  end

  def test_exception
    json_response =  "{\n \"kind\": \"Status\",\n \"apiVersion\": \"v1beta1\",\n  \"status\": \"Failure\",\n \"message\": \"service redisslave already exists\",\n \"reason\": \"AlreadyExists\",\n \"details\": {\n \"id\": \"redisslave\",\n \"kind\": \"service\"\n},\n \"code\": 409\n}"

    stub_request(:post, /\/services/).
        to_return(:body => json_response, :status => 409)

    service = Service.new
    service.id = 'redisslave'
    service.port = 80
    service.container_port = 6379
    service.protocol = "TCP"

    client = Kubeclient::Client.new 'http://localhost:8080/api/' , "v1beta1"
    exception = assert_raises(KubeException) { service = client.create_service service }

    assert_instance_of(KubeException, exception)
    assert_equal( "service redisslave already exists", exception.message )
    assert_equal( 409, exception.error_code )

  end

  def test_entity_list
    json_response = "{\n  \"kind\": \"ServiceList\",\n  \"creationTimestamp\": null,\n  \"selfLink\": \"/api/v1beta1/services\",\n  \"resourceVersion\": 8,\n  \"apiVersion\": \"v1beta1\",\n  \"items\": [\n    {\n      \"id\": \"kubernetes\",\n      \"uid\": \"be10c0ba-8f4e-11e4-814c-3c970e4a436a\",\n      \"creationTimestamp\": \"2014-12-29T13:35:08+02:00\",\n      \"selfLink\": \"/api/v1beta1/services/kubernetes?namespace=default\",\n      \"resourceVersion\": 4,\n      \"namespace\": \"default\",\n      \"port\": 443,\n      \"protocol\": \"TCP\",\n      \"labels\": {\n        \"component\": \"apiserver\",\n        \"provider\": \"kubernetes\"\n      },\n      \"selector\": null,\n      \"containerPort\": 0,\n      \"portalIP\": \"10.0.0.151\"\n    },\n    {\n      \"id\": \"kubernetes-ro\",\n      \"uid\": \"be106b89-8f4e-11e4-814c-3c970e4a436a\",\n      \"creationTimestamp\": \"2014-12-29T13:35:08+02:00\",\n      \"selfLink\": \"/api/v1beta1/services/kubernetes-ro?namespace=default\",\n      \"resourceVersion\": 3,\n      \"namespace\": \"default\",\n      \"port\": 80,\n      \"protocol\": \"TCP\",\n      \"labels\": {\n        \"component\": \"apiserver\",\n        \"provider\": \"kubernetes\"\n      },\n      \"selector\": null,\n      \"containerPort\": 0,\n      \"portalIP\": \"10.0.0.171\"\n    }\n  ]\n}"
    stub_request(:get, /\/services/).
        to_return(:body => json_response, :status => 200)
    client = Kubeclient::Client.new 'http://localhost:8080/api/' , "v1beta1"
    services = client.get_services
    refute_empty(services)
    assert_instance_of(EntityList,services)
    assert_equal("Service",services.kind)
    assert_equal(2,services.size)
    assert_instance_of(Service,services[0])
    assert_instance_of(Service,services[1])
  end

  def test_get_all
    json_response_services = "{\n  \"kind\": \"ServiceList\",\n  \"creationTimestamp\": null,\n  \"selfLink\": \"/api/v1beta1/services\",\n  \"resourceVersion\": 8,\n  \"apiVersion\": \"v1beta1\",\n  \"items\": [\n    {\n      \"id\": \"kubernetes\",\n      \"uid\": \"be10c0ba-8f4e-11e4-814c-3c970e4a436a\",\n      \"creationTimestamp\": \"2014-12-29T13:35:08+02:00\",\n      \"selfLink\": \"/api/v1beta1/services/kubernetes?namespace=default\",\n      \"resourceVersion\": 4,\n      \"namespace\": \"default\",\n      \"port\": 443,\n      \"protocol\": \"TCP\",\n      \"labels\": {\n        \"component\": \"apiserver\",\n        \"provider\": \"kubernetes\"\n      },\n      \"selector\": null,\n      \"containerPort\": 0,\n      \"portalIP\": \"10.0.0.151\"\n    },\n    {\n      \"id\": \"kubernetes-ro\",\n      \"uid\": \"be106b89-8f4e-11e4-814c-3c970e4a436a\",\n      \"creationTimestamp\": \"2014-12-29T13:35:08+02:00\",\n      \"selfLink\": \"/api/v1beta1/services/kubernetes-ro?namespace=default\",\n      \"resourceVersion\": 3,\n      \"namespace\": \"default\",\n      \"port\": 80,\n      \"protocol\": \"TCP\",\n      \"labels\": {\n        \"component\": \"apiserver\",\n        \"provider\": \"kubernetes\"\n      },\n      \"selector\": null,\n      \"containerPort\": 0,\n      \"portalIP\": \"10.0.0.171\"\n    }\n  ]\n}"
    stub_request(:get, /\/services/).
        to_return(:body => json_response_services, :status => 200)
    json_response_pods =  "{\n   \"kind\": \"PodList\", \n  \"creationTimestamp\": null,\n   \"selfLink\": \"/api/v1beta1/pods\",\n  \"resourceVersion\": 7,\n   \"apiVersion\": \"v1beta1\",   \"items\": [] }"
    stub_request(:get, /\/pods/).
        to_return(:body => json_response_pods, :status => 200)
    json_response_nodes = "{\n   \"kind\": \"NodeList\",\n   \"creationTimestamp\": null, \n  \"selfLink\": \"/api/v1beta1/nodes\",\n   \"apiVersion\": \"v1beta1\",\n   \"minions\": [ \n    { \n      \"id\": \"127.0.0.1\",\n       \"uid\": \"a7b13504-9402-11e4-9a08-3c970e4a436a\",\n       \"creationTimestamp\": \"2015-01-04T13:13:05+02:00\",\n       \"selfLink\": \"/api/v1beta1/nodes/127.0.0.1\", \n      \"resourceVersion\": 7,\n       \"resources\": {   \n      \"capacity\": { \n          \"cpu\": 1000,\n           \"memory\": 3221225472    \n     }       }     }   ],   \"items\": [     {       \"id\": \"127.0.0.1\", \n      \"uid\": \"a7b13504-9402-11e4-9a08-3c970e4a436a\", \n      \"creationTimestamp\": \"2015-01-04T13:13:05+02:00\", \n      \"selfLink\": \"/api/v1beta1/nodes/127.0.0.1\",\n       \"resourceVersion\": 7,\n       \"resources\": {         \"capacity\": {           \"cpu\": 1000,           \"memory\": 3221225472         }       }     }   ] }"
    stub_request(:get, /\/nodes/).
        to_return(:body => json_response_nodes, :status => 200)

    json_response_replication_controllers =  "{  \"kind\": \"ReplicationControllerList\", \"creationTimestamp\": null, \"selfLink\": \"/api/v1beta1/replicationControllers\", \"resourceVersion\": 7, \"apiVersion\": \"v1beta1\", \"items\": [] }"
    stub_request(:get, /\/replicationControllers/).
        to_return(:body => json_response_replication_controllers, :status => 200)

    stub_request(:get, /\/events/)
      .to_return(body: open_test_json_file('event_list_b3.json'), status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/' , "v1beta1"
    result = client.get_all_entities
    assert_equal(5, result.keys.size)
    assert_instance_of(EntityList, result["node"])
    assert_instance_of(EntityList, result["service"])
    assert_instance_of(EntityList, result["replication_controller"])
    assert_instance_of(EntityList, result["pod"])
    assert_instance_of(EntityList, result['event'])
    assert_instance_of(Service, result["service"][0])
    assert_instance_of(Node, result["node"][0])
    assert_instance_of(Event, result['event'][0])
  end

  # dup method creates a shallow copy which is not good in this case
  # since rename_keys changes the input hash
  # hence need to create a deep_copy
  private
  def deep_copy(hash)
    Marshal.load(Marshal.dump(hash))
  end

end