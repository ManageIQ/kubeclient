require 'minitest/autorun'
require 'webmock/minitest'
require 'kubeclient/pod'
require 'json'
require './lib/kubeclient'

class PodTest < MiniTest::Test

  def test_get_from_json
    json_response =  " { \"apiVersion\": \"v1beta1\",\n \"kind\": \"Pod\", \n \"id\": \"redis-master-pod\", \n  \"desiredState\": { \"manifest\": { \"version\": \"v1beta1\", \"id\": \"redis-master-pod\", \n
    \"containers\": [{ \"name\": \"redis-master\", \"image\": \"gurpartap/redis\", \"ports\": [{ \"name\": \"redis-server\", \"containerPort\": 6379 }] }] } }, \"labels\": { \"name\": \"redis\", \"role\": \"master\" } }"

    stub_request(:get, /.*pods*/).
        to_return(:body => json_response, :status => 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/' , "v1beta1"
    pod = client.get_pod "redis-master-pod"

    assert_instance_of(Pod,pod)
    assert_equal("redis-master-pod",pod.id)
    assert_equal("redis-master",pod.desiredState.manifest.containers[0]['name'])
  end

end