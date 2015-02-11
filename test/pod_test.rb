require 'minitest/autorun'
require 'webmock/minitest'
require 'kubeclient/pod'
require 'json'
require './lib/kubeclient'

# Pod entity tests
class PodTest < MiniTest::Test
  def test_get_from_json_v1
    stub_request(:get, /\/pods/)
      .to_return(body: open_test_json_file('pod_b1.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta1'
    pod = client.get_pod 'redis-master-pod'

    assert_instance_of(Pod, pod)
    assert_equal('redis-master-pod', pod.id)
    assert_equal('redis-master',
                 pod.desiredState.manifest.containers[0]['name'])
  end

  def test_get_from_json_v3
    stub_request(:get, /\/pods/)
      .to_return(body: open_test_json_file('pod_b3.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta3'
    pod = client.get_pod 'redis-master-pod'

    assert_instance_of(Pod, pod)
    assert_equal('redis-master3', pod.metadata.name)
    assert_equal('dockerfile/redis', pod.spec.containers[0]['image'])
  end
end
