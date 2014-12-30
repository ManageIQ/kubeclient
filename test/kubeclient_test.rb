require 'minitest/autorun'
require 'json'
require 'webmock/minitest'
require './lib/kubeclient'
require './test/kubeclient'


class KubeClientTest < MiniTest::Test

  def test_renaming_keys
    json_response = "{\n  \"kind\": \"Node\",\n  \"id\": \"127.0.0.1\",\n  \"uid\": \"b0ddfa00-8b5b-11e4-a8c4-3c970e4a436a\",\n  \"creationTimestamp\": \"2014-12-24T12:57:45+02:00\",\n  \"selfLink\": \"/api/v1beta1/nodes/127.0.0.1\",\n  \"resourceVersion\": 7,\n  \"apiVersion\": \"v1beta1\",\n  \"resources\": {\n    \"capacity\": {\n      \"cpu\": 1000,\n      \"memory\": 3221225472\n    }\n  }\n}"
    stub_request(:get, /.*nodes*/).
        to_return(:body => json_response, :status => 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/' , "v1beta1"
    original_hash = JSON.parse(json_response)
    #convert to ruby style
    hash_after_rename_underscore = client.rename_keys(deep_copy(original_hash),"underscore", nil)
    #convert back to camelized style with first word downcase
    hash_after_rename_camelize = client.rename_keys(deep_copy(hash_after_rename_underscore), "camelize", :lower)

    assert_equal(original_hash, hash_after_rename_camelize)
    assert_equal(7,hash_after_rename_camelize["resourceVersion"])
    assert_equal(7,hash_after_rename_underscore["resource_version"])
    assert_equal(nil, hash_after_rename_underscore["resourceVersion"])


  end

  #testing that keys renaming works on deeper level
  #the json doesn't necessarily represent a valid k8s entity , it's for testing renaming purposes
  def test_renaming_keys_deep
    json_response = "{\n  \"kind\": \"Node\",\n  \"id\": \"127.0.0.1\",\n  \"uid\": \"b0ddfa00-8b5b-11e4-a8c4-3c970e4a436a\",\n  \"creationTimestamp\": \"2014-12-24T12:57:45+02:00\",\n  \"selfLink\": \"/api/v1beta1/nodes/127.0.0.1\",\n  \"resourceVersion\": 7,\n  \"apiVersion\": \"v1beta1\",\n  \"hostResources\": {\n    \"capacity\": {\n      \"cpu\": 1000,\n      \"memorySize\": 3221225472\n    }\n  }\n}"
    stub_request(:get, /.*nodes*/).
        to_return(:body => json_response, :status => 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/' , "v1beta1"
    original_hash = JSON.parse(json_response)
    #convert to ruby style
    hash_after_rename_underscore = client.rename_keys(deep_copy(original_hash),"underscore", nil)
    #convert back to camelized style with first word downcase
    hash_after_rename_camelize = client.rename_keys(deep_copy(hash_after_rename_underscore), "camelize", :lower)

    assert_equal(original_hash, hash_after_rename_camelize)
    assert_equal(3221225472,hash_after_rename_camelize["hostResources"]["capacity"]["memorySize"])
    assert_equal(nil,hash_after_rename_underscore["host_resources"]["capacity"]["memorySize"])
    assert_equal(3221225472,hash_after_rename_underscore["host_resources"]["capacity"]["memory_size"])
  end

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

    stub_request(:post, /.*services*/).
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
    stub_request(:get, /.*services*/).
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

  #dup method creates a shallow copy which is not good in this case since rename_keys changes the input hash
  private
  def deep_copy(hash)
    Marshal.load(Marshal.dump(hash))
  end

end