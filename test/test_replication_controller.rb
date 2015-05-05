require 'test_helper'

# Replication Controller entity tests
class TestReplicationController < MiniTest::Test
  def test_get_from_json_v3
    stub_request(:get, %r{/replicationcontrollers})
      .to_return(body: open_test_json_file('replication_controller_b3.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta3'
    rc = client.get_replication_controller 'frontendController', 'default'

    assert_instance_of(Kubeclient::ReplicationController, rc)
    assert_equal('guestbook-controller', rc.metadata.name)
    assert_equal('c71aa4c0-a240-11e4-a265-3c970e4a436a', rc.metadata.uid)
    assert_equal('default', rc.metadata.namespace)
    assert_equal(3, rc.spec.replicas)
    assert_equal('guestbook', rc.spec.selector.name)

    assert_requested(:get,
                     'http://localhost:8080/api/v1beta3/namespaces/default/replicationcontrollers/frontendController',
                     times: 1)
  end
end
