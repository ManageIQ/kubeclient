require 'test_helper'

class TestEntityConfigOperations < MiniTest::Test
  def test_create
    our_service = Kubeclient::Resource.new
    our_service.apiVersion = 'v1'
    our_service.kind = 'Service'
    our_service.metadata = {}
    our_service.metadata.name = 'guestbook'
    our_service.metadata.namespace = 'staging'
    our_service.metadata.labels = {}
    our_service.metadata.labels.name = 'guestbook'

    our_service.spec = {}
    our_service.spec.ports = [{
      'port' => 3000,
      'targetPort' => 'http-server',
      'protocol' => 'TCP'
    }]

    assert_equal('guestbook', our_service.metadata.labels.name)

    hash = our_service.to_h

    assert_equal our_service.metadata.labels.name,
                 hash[:metadata][:labels][:name]

    expected_url = 'http://localhost:8080/api/v1/namespaces/staging/services'
    stub_request(:get, %r{/api/v1$})
      .to_return(body: open_test_file('core_api_resource_list.json'),
                 status: 200)

    stub_request(:post, expected_url)
      .to_return(body: open_test_file('created_service.json'), status: 201)

    client = Kubeclient::Client.new 'http://localhost:8080/api/'
    created = client.create our_service

    assert_instance_of(Kubeclient::Service, created)
    assert_equal(created.metadata.name, our_service.metadata.name)
    assert_equal(created.spec.ports.size, our_service.spec.ports.size)

    assert_requested(:post, expected_url, times: 1) do |req|
      data = JSON.parse(req.body)
      data['kind'] == 'Service' &&
        data['apiVersion'] == 'v1' &&
        data['metadata']['name'] == 'guestbook' &&
        data['metadata']['namespace'] == 'staging'
    end

  end
end
