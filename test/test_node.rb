require 'test_helper'

# Node entity tests
class TestNode < MiniTest::Test
  def test_get_from_json_v1
    stub_request(:get, %r{/nodes})
      .to_return(body: open_test_file('node.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1'
    node = client.get_node('127.0.0.1')

    assert_instance_of(Kubeclient::Node, node)

    assert_equal('041143c5-ce39-11e4-ac24-3c970e4a436a', node.metadata.uid)
    assert_equal('127.0.0.1', node.metadata.name)
    assert_equal('1724', node.metadata.resourceVersion)
    assert_equal('v1', node.apiVersion)
    assert_equal('2015-03-19T15:08:20+02:00', node.metadata.creationTimestamp)

    assert_requested(:get,
                     'http://localhost:8080/api/v1/nodes/127.0.0.1',
                     times: 1)
  end
end
