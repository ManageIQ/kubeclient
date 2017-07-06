require 'test_helper'

# Service entity tests
class TestService < MiniTest::Test
  def test_delete_a_deployment_with_propagation_policy_query
    value_propagation_policy = 'Foreground'
    namespace = 'my_namespace'
    deployment = 'my_deployment'

    stub_request(:get, %r{/api/extensions/v1beta1$})
      .to_return(body: open_test_file('v1beta1_api_resource_list.json'), status: 200)
    stub_request(:delete, %r{/namespaces/#{namespace}/deployments/#{deployment}})
      .to_return(body: open_test_file('entity_list.json'), status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'extensions/v1beta1')
    client.delete_deployment(deployment, namespace, propagation_policy: value_propagation_policy)

    expected_endpoint = "/api/extensions/v1beta1/namespaces/#{namespace}/deployments/#{deployment}"
    expected_query = "?propagationPolicy=#{value_propagation_policy}"
    expected_url = "http://localhost:8080#{expected_endpoint}#{expected_query}"

    assert_requested(:delete, expected_url, times: 1)
  end
end
