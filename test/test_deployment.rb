require 'test_helper'

# Replication Controller entity tests
class TestDeployment < MiniTest::Test
  def test_get_from_json_v1
    stub_request(:get, %r{/deployment})
      .to_return(body: open_test_file('deployment.json'),
                 status: 200)

    Kubeclient::Deployment.new
    client = Kubeclient::Client.new 'http://localhost:8080/apis', 'extensions/v1beta1'
    deployment = client.get_deployment 'nginx-deployment', 'default'

    assert_instance_of(Kubeclient::Deployment, deployment)
    assert_equal('nginx-deployment', deployment.metadata.name)
    assert_equal('7ec56cb1-9f94-11e5-ab34-42010af00002', deployment.metadata.uid)
    assert_equal('default', deployment.metadata.namespace)
    assert_equal(3, deployment.spec.replicas)
    assert_equal('nginx', deployment.spec.selector.app)

    assert_requested(:get,
                     'http://localhost:8080/apis/extensions/v1beta1/namespaces/default/deployments/nginx-deployment',
                     times: 1)
  end
end
