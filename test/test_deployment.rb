require 'test_helper'

# Service entity tests
class TestService < MiniTest::Test
  def test_delete_a_entity_with_propagation_policy_query
    value_propagation_policy = 'Foreground'
    namespace = 'my_namespace'
    service = 'my_service'

    stub_request(:get, %r{/api/v1$})
      .to_return(body: open_test_file('core_api_resource_list.json'), status: 200)
    stub_request(:delete, %r{/namespaces/#{namespace}/services/#{service}})
      .to_return(body: open_test_file('entity_list.json'), status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    query_hash = { propagationPolicy: value_propagation_policy }
    client.delete_service(service, namespace, query: query_hash)

    expected_endpoint = "/api/v1/namespaces/#{namespace}/services/#{service}"
    expected_query = "?propagationPolicy=#{value_propagation_policy}"
    expected_url = "http://localhost:8080#{expected_endpoint}#{expected_query}"

    assert_requested(:delete, expected_url, times: 1)
  end
end
