require 'minitest/autorun'
require 'webmock/minitest'
require 'kubeclient/node'
require 'json'
require './lib/kubeclient'

# Node entity tests
class NodeTest < MiniTest::Test
  def test_get_from_json_v1
    stub_request(:get, /\/nodes/)
      .to_return(body: open_test_json_file('node_b1.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta1'
    node = client.get_node('127.0.0.1')

    assert_instance_of(Node, node)
    assert_respond_to(node, 'creationTimestamp')
    assert_respond_to(node, 'uid')
    assert_respond_to(node, 'id')
    assert_respond_to(node, 'resources')
    assert_respond_to(node, 'resourceVersion')
    assert_respond_to(node, 'apiVersion')

    assert_equal(7, node.resourceVersion)
    assert_equal(1000, node.resources.capacity.cpu)
  end

  def test_get_from_json_v3
    stub_request(:get, /\/nodes/)
      .to_return(body: open_test_json_file('node_b3.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta3'
    node = client.get_node('127.0.0.1')

    assert_instance_of(Node, node)

    assert_equal('01018013-a231-11e4-a36b-3c970e4a436a', node.metadata.uid)
    assert_equal('127.0.0.1', node.metadata.name)
    assert_equal('7', node.metadata.resourceVersion)
    assert_equal('v1beta3', node.apiVersion)
    assert_equal('2015-01-22T14:20:08+02:00', node.metadata.creationTimestamp)
  end
end
