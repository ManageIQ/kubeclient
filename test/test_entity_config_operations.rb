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

  def test_update_service
    service = Kubeclient::Resource.new
    name = 'my_service'

    service.apiVersion = 'v1'
    service.kind = 'Service'
    service.metadata = {}
    service.metadata.name      = name
    service.metadata.namespace = 'development'

    stub_request(:get, %r{/api/v1$})
      .to_return(body: open_test_file('core_api_resource_list.json'),
                 status: 200)
    expected_url = "http://localhost:8080/api/v1/namespaces/development/services/#{name}"
    stub_request(:put, expected_url)
      .to_return(body: open_test_file('service_update.json'), status: 201)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1'
    client.update service

    assert_requested(:put, expected_url, times: 1) do |req|
      data = JSON.parse(req.body)
      data['metadata']['name'] == name &&
        data['metadata']['namespace'] == 'development'
    end
  end

  def test_patch_service
    service = Kubeclient::Resource.new
    name = 'my_service'

    service.apiVersion = 'v1'
    service.kind = 'Service'
    service.metadata = {}
    service.metadata.name      = name
    service.metadata.namespace = 'development'

    stub_request(:get, %r{/api/v1$})
      .to_return(body: open_test_file('core_api_resource_list.json'),
                 status: 200)
    expected_url = "http://localhost:8080/api/v1/namespaces/development/services/#{name}"
    stub_request(:patch, expected_url)
      .to_return(body: open_test_file('service_patch.json'), status: 200)

    patch = {
      metadata: {
        annotations: {
          key: 'value'
        }
      }
    }

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1'
    client.patch_service name, patch, 'development'

    assert_requested(:patch, expected_url, times: 1) do |req|
      data = JSON.parse(req.body)
      data['metadata']['annotations']['key'] == 'value'
    end
  end

  def test_delete_service
    our_service = Kubeclient::Resource.new
    # TODO, new ports assignment to be added
    our_service.apiVersion = 'v1'
    our_service.kind = 'Service'
    our_service.metadata = {}
    our_service.metadata.name = 'redis-service'
    our_service.metadata.namespace = 'default'
    our_service.metadata.labels = {}
    our_service.metadata.labels.component = 'apiserver'
    our_service.metadata.labels.provider = 'kubernetes'

    stub_request(:get, %r{/api/v1$})
      .to_return(body: open_test_file('core_api_resource_list.json'),
                 status: 200)
    stub_request(:delete, %r{/namespaces/default/services})
      .to_return(status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1'
    client.delete our_service

    assert_requested(:delete,
                     'http://localhost:8080/api/v1/namespaces/default/services/redis-service',
                     times: 1)
  end
end
