require 'minitest/autorun'
require 'webmock/minitest'
require './lib/kubeclient'
require 'kubeclient/replication_controller'
require 'json'

# Replication Controller entity tests
class ReplicationControllerTest < MiniTest::Test
  def test_get_from_json_v1
    stub_request(:get, /\/replicationControllers/)
      .to_return(body: open_test_json_file('replication_controller_b1.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta1'
    rc = client.get_replication_controller 'frontendController'

    assert_instance_of(ReplicationController, rc)
    assert_equal('frontendController', rc.id)
    assert_equal('f4e5966c-8eb2-11e4-a6e7-3c970e4a436a', rc.uid)
    assert_equal('default', rc.namespace)
    assert_equal(3, rc.desiredState.replicas)
    assert_equal('frontend', rc.desiredState.replicaSelector.name)
    # the access to containers is not as nice as rest of the properties,
    # but it's about to change in beta v3, hence it can significantly
    # impact the design of the client. to be revisited after beta v3 api
    # is released.
    assert_equal('php-redis', rc.desiredState.podTemplate
                                .desiredState.manifest.containers[0]['name'])
  end

  def test_get_from_json_v3
    stub_request(:get, /\/replicationcontrollers/)
      .to_return(body: open_test_json_file('replication_controller_b3.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta3'
    rc = client.get_replication_controller 'frontendController'

    assert_instance_of(ReplicationController, rc)
    assert_equal('guestbook-controller', rc.metadata.name)
    assert_equal('c71aa4c0-a240-11e4-a265-3c970e4a436a', rc.metadata.uid)
    assert_equal('default', rc.metadata.namespace)
    assert_equal(3, rc.spec.replicas)
    assert_equal('guestbook', rc.spec.selector.name)
  end
end
