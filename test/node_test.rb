require 'minitest/autorun'
require 'webmock/minitest'
require 'kubeclient/node'
require 'json'
require './lib/kubeclient'

class NodeTest < MiniTest::Test
  def test_get_from_json_v1
    json_response = "{\n  \"kind\": \"Node\",\n  \"id\": \"127.0.0.1\",\n  \"uid\": \"b0ddfa00-8b5b-11e4-a8c4-3c970e4a436a\",\n  \"creationTimestamp\": \"2014-12-24T12:57:45+02:00\",\n  \"selfLink\": \"/api/v1beta1/nodes/127.0.0.1\",\n  \"resourceVersion\": 7,\n  \"apiVersion\": \"v1beta1\",\n  \"resources\": {\n    \"capacity\": {\n      \"cpu\": 1000,\n      \"memory\": 3221225472\n    }\n  }\n}"

    stub_request(:get, /\/nodes/).
        to_return(:body => json_response, :status => 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/' , "v1beta1"
    node = client.get_node "127.0.0.1"

    assert_instance_of(Node,node)
    assert_respond_to(node, "creationTimestamp")
    assert_respond_to(node, "uid")
    assert_respond_to(node, "id")
    assert_respond_to(node, "resources")
    assert_respond_to(node, "resourceVersion")
    assert_respond_to(node, "apiVersion")

    assert_equal 7, node.resourceVersion
    assert_equal 1000, node.resources.capacity.cpu
  end

  def test_get_from_json_v3
    json_response = "{\n  \"kind\": \"Node\",\n  \"apiVersion\": \"v1beta3\",\n  \"metadata\": {\n    \"name\": \"127.0.0.1\",\n    \"selfLink\": \"/api/v1beta3/nodes/127.0.0.1\",\n    \"uid\": \"01018013-a231-11e4-a36b-3c970e4a436a\",\n    \"resourceVersion\": \"7\",\n    \"creationTimestamp\": \"2015-01-22T14:20:08+02:00\"\n  },\n  \"spec\": {\n    \"capacity\": {\n      \"cpu\": \"1\",\n      \"memory\": \"3Gi\"\n    }\n  },\n  \"status\": {\n    \"hostIP\": \"127.0.0.1\",\n    \"conditions\": [\n      {\n        \"kind\": \"Ready\",\n        \"status\": \"Full\",\n        \"lastTransitionTime\": null\n      }\n    ]\n  }\n}"

    stub_request(:get, /\/nodes/).
        to_return(:body => json_response, :status => 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/' , "v1beta3"
    node = client.get_node "127.0.0.1"

    assert_instance_of(Node,node)

    assert_equal("01018013-a231-11e4-a36b-3c970e4a436a", node.metadata.uid)
    assert_equal("127.0.0.1", node.metadata.name)
    assert_equal("7", node.metadata.resourceVersion)
    assert_equal("v1beta3", node.apiVersion)
    assert_equal("2015-01-22T14:20:08+02:00", node.metadata.creationTimestamp)

  end

end