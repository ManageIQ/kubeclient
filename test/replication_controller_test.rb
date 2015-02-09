require 'minitest/autorun'
require 'webmock/minitest'
require './lib/kubeclient'
require 'kubeclient/replication_controller'
require 'json'

class ReplicationControllerTest < MiniTest::Test

  def test_get_from_json_v1
    json_response = "{\n  \"kind\": \"ReplicationController\",\n  \"id\": \"frontendController\",\n  \"uid\": \"f4e5966c-8eb2-11e4-a6e7-3c970e4a436a\",\n  \"creationTimestamp\": \"2014-12-28T18:59:59+02:00\",\n  \"selfLink\": \"/api/v1beta1/replicationControllers/frontendController?namespace=default\",\n  \"resourceVersion\": 11,\n  \"apiVersion\": \"v1beta1\",\n  \"namespace\": \"default\",\n  \"desiredState\": {\n    \"replicas\": 3,\n    \"replicaSelector\": {\n      \"name\": \"frontend\"\n    },\n    \"podTemplate\": {\n      \"desiredState\": {\n        \"manifest\": {\n          \"version\": \"v1beta2\",\n          \"id\": \"\",\n          \"volumes\": null,\n          \"containers\": [\n            {\n              \"name\": \"php-redis\",\n              \"image\": \"brendanburns/php-redis\",\n              \"ports\": [\n                {\n                  \"hostPort\": 8000,\n                  \"containerPort\": 80,\n                  \"protocol\": \"TCP\"\n                }\n              ],\n              \"imagePullPolicy\": \"\"\n            }\n          ],\n          \"restartPolicy\": {\n            \"always\": {}\n          }\n        }\n      },\n      \"labels\": {\n        \"name\": \"frontend\"\n      }\n    }\n  },\n  \"currentState\": {\n    \"replicas\": 3,\n    \"podTemplate\": {\n      \"desiredState\": {\n        \"manifest\": {\n          \"version\": \"\",\n          \"id\": \"\",\n          \"volumes\": null,\n          \"containers\": null,\n          \"restartPolicy\": {}\n        }\n      }\n    }\n  },\n  \"labels\": {\n    \"name\": \"frontend\"\n  }\n}"
    stub_request(:get, /\/replicationControllers/).
        to_return(:body => json_response, :status => 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/' , "v1beta1"
    rc = client.get_replication_controller "frontendController"

    assert_instance_of(ReplicationController,rc)
    assert_equal("frontendController",rc.id)
    assert_equal("f4e5966c-8eb2-11e4-a6e7-3c970e4a436a",rc.uid)
    assert_equal("default",rc.namespace)
    assert_equal(3,rc.desiredState.replicas)
    assert_equal("frontend",rc.desiredState.replicaSelector.name)
    #the access to containers is not as nice as rest of the properties, but it's about to change in beta v3,
    #hence it can significantly impact the design of the client. to be revisited after beta v3 api is released.
    assert_equal("php-redis",rc.desiredState.podTemplate.desiredState.manifest.containers[0]['name'])
  end

  def test_get_from_json_v3
    json_response =  "{\n  \"kind\": \"ReplicationController\",\n  \"apiVersion\": \"v1beta3\",\n  \"metadata\": {\n    \"name\": \"guestbook-controller\",\n    \"namespace\": \"default\",\n    \"selfLink\": \"/api/v1beta3/replicationcontrollers/guestbook-controller?namespace=default\",\n    \"uid\": \"c71aa4c0-a240-11e4-a265-3c970e4a436a\",\n    \"resourceVersion\": \"8\",\n    \"creationTimestamp\": \"2015-01-22T16:13:02+02:00\",\n    \"labels\": {\n      \"name\": \"guestbook\"\n    }\n  },\n  \"spec\": {\n    \"replicas\": 3,\n    \"selector\": {\n      \"name\": \"guestbook\"\n    },\n    \"template\": {\n      \"metadata\": {\n        \"creationTimestamp\": null,\n        \"labels\": {\n          \"name\": \"guestbook\"\n        }\n      },\n      \"spec\": {\n        \"volumes\": null,\n        \"containers\": [\n          {\n            \"name\": \"guestbook\",\n            \"image\": \"kubernetes/guestbook\",\n            \"ports\": [\n              {\n                \"name\": \"http-server\",\n                \"containerPort\": 3000,\n                \"protocol\": \"TCP\"\n              }\n            ],\n            \"memory\": \"0\",\n            \"cpu\": \"0m\",\n            \"imagePullPolicy\": \"\"\n          }\n        ],\n        \"restartPolicy\": {\n          \"always\": {}\n        },\n        \"dnsPolicy\": \"ClusterFirst\"\n      }\n    }\n  },\n  \"status\": {\n    \"replicas\": 3\n  }\n}"

    stub_request(:get, /\/replicationcontrollers/).
        to_return(:body => json_response, :status => 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/' , "v1beta3"
    rc = client.get_replication_controller "frontendController"

    assert_instance_of(ReplicationController,rc)
    assert_equal("guestbook-controller",rc.metadata.name)
    assert_equal("c71aa4c0-a240-11e4-a265-3c970e4a436a",rc.metadata.uid)
    assert_equal("default",rc.metadata.namespace)
    assert_equal(3,rc.spec.replicas)
    assert_equal("guestbook",rc.spec.selector.name)
  end

end