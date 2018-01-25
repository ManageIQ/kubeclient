require_relative 'test_helper'

# Endpoint entity tests
class TestEndpoint < MiniTest::Test
  def test_create_endpoint
    stub_request(:get, %r{/api/v1$})
      .to_return(
        body: open_test_file('core_api_resource_list.json'),
        status: 200
      )

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    testing_ep = Kubeclient::Resource.new
    testing_ep.metadata = {}
    testing_ep.metadata.name = 'myendpoint'
    testing_ep.metadata.namespace = 'default'
    testing_ep.subsets = [
      {
        'addresses' => [{ 'ip' => '172.17.0.25' }],
        'ports' => [{ 'name' => 'https', 'port' => 6443, 'protocol' => 'TCP' }]
      }
    ]

    req_body = '{"metadata":{"name":"myendpoint","namespace":"default"},' \
      '"subsets":[{"addresses":[{"ip":"172.17.0.25"}],"ports":[{"name":"https",' \
      '"port":6443,"protocol":"TCP"}]}],"kind":"Endpoints","apiVersion":"v1"}'

    stub_request(:post, 'http://localhost:8080/api/v1/namespaces/default/endpoints')
      .with(body: req_body)
      .to_return(body: open_test_file('created_endpoint.json'), status: 201)

    created_ep = client.create_endpoint(testing_ep)
    assert_equal('Endpoints', created_ep.kind)
  end
end
