require 'minitest/autorun'
require 'webmock/minitest'
require 'kubeclient/pod'
require 'json'
require './lib/kubeclient'

class PodTest < MiniTest::Test

  def test_get_from_json_v1
    json_response =  " { \"apiVersion\": \"v1beta1\",\n \"kind\": \"Pod\", \n \"id\": \"redis-master-pod\", \n  \"desiredState\": { \"manifest\": { \"version\": \"v1beta1\", \"id\": \"redis-master-pod\", \n
    \"containers\": [{ \"name\": \"redis-master\", \"image\": \"gurpartap/redis\", \"ports\": [{ \"name\": \"redis-server\", \"containerPort\": 6379 }] }] } }, \"labels\": { \"name\": \"redis\", \"role\": \"master\" } }"

    stub_request(:get, /\/pods/).
        to_return(:body => json_response, :status => 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/' , "v1beta1"
    pod = client.get_pod "redis-master-pod"

    assert_instance_of(Pod,pod)
    assert_equal("redis-master-pod",pod.id)
    assert_equal("redis-master",pod.desiredState.manifest.containers[0]['name'])
  end

  def test_get_from_json_v3
    json_response =   "{\n  \"kind\": \"Pod\",\n  \"apiVersion\": \"v1beta3\",\n  \"metadata\": {\n   \"name\": \"redis-master3\",\n  \"namespace\": \"default\",\n  \"selfLink\": \"/api/v1beta3/pods/redis-master3?namespace=default\",\n    \"uid\": \"a344023f-a23c-11e4-a36b-3c970e4a436a\",\n    \"resourceVersion\": \"9\",\n    \"creationTimestamp\": \"2015-01-22T15:43:24+02:00\",\n    \"labels\": {\n      \"name\": \"redis-master\"\n    }\n  },\n  \"spec\": {\n    \"volumes\": null,\n    \"containers\": [\n      {\n        \"name\": \"master\",\n        \"image\": \"dockerfile/redis\",\n        \"ports\": [\n          {\n            \"hostPort\": 6379,\n            \"containerPort\": 6379,\n            \"protocol\": \"TCP\"\n          }\n        ],\n        \"memory\": \"0\",\n        \"cpu\": \"100m\",\n        \"imagePullPolicy\": \"\"\n      },\n      {\n        \"name\": \"php-redis\",\n        \"image\": \"kubernetes/example-guestbook-php-redis\",\n        \"ports\": [\n          {\n            \"hostPort\": 8000,\n            \"containerPort\": 80,\n            \"protocol\": \"TCP\"\n          }\n        ],\n        \"memory\": \"50000000\",\n        \"cpu\": \"100m\",\n        \"imagePullPolicy\": \"\"\n      }\n    ],\n    \"restartPolicy\": {\n      \"always\": {}\n    },\n    \"dnsPolicy\": \"ClusterFirst\"\n  },\n  \"status\": {\n    \"phase\": \"Running\",\n    \"host\": \"127.0.0.1\",\n    \"podIP\": \"172.17.0.2\",\n    \"info\": {\n      \"master\": {\n        \"state\": {\n          \"running\": {\n            \"startedAt\": \"2015-01-22T13:43:29Z\"\n          }\n        },
     \n  \"restartCount\": 0,\n   \"containerID\": \"docker://87458d9a12f9dc9a01b52c1eee5f09cf48939380271c0eaf31af298ce67b125e\",\n  \"image\": \"dockerfile/redis\"\n  },\n  \"net\": {\n  \"state\": {\n          \"running\": {\n            \"startedAt\": \"2015-01-22T13:43:27Z\"\n     }\n     },\n    \"restartCount\": 0,\n   \"containerID\": \"docker://3bb5ced1f831322d370f70b58137e1dd41216c2960b7a99394542b5230cbd259\",\n        \"podIP\": \"172.17.0.2\",\n        \"image\": \"kubernetes/pause:latest\"\n      },\n      \"php-redis\": {\n        \"state\": {\n          \"running\": {\n            \"startedAt\": \"2015-01-22T13:43:31Z\"\n          }\n        },\n        \"restartCount\": 0,\n        \"containerID\": \"docker://5f08685c0a7a5c974d438a52c6560d72bb0aae7e805d2a34302b9b460f1297c7\",\n        \"image\": \"kubernetes/example-guestbook-php-redis\"\n      }\n    }\n  }\n}"

    stub_request(:get, /\/pods/).
        to_return(:body => json_response, :status => 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/' , "v1beta3"
    pod = client.get_pod "redis-master-pod"

    assert_instance_of(Pod,pod)
    assert_equal("redis-master3",pod.metadata.name)
    assert_equal("dockerfile/redis",pod.spec.containers[0]["image"])

  end

end