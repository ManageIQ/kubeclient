require 'test_helper'

# Service entity tests
class TestService < MiniTest::Test
  def test_construct_our_own_service
    our_service = Kubeclient::Service.new
    our_service.metadata = {}
    our_service.metadata.name = 'guestbook'
    our_service.metadata.namespace = 'staging'
    our_service.metadata.labels = {}
    our_service.metadata.labels.name = 'guestbook'

    our_service.spec = {}
    our_service.spec.ports = [{ 'port' => 3000,
                                'targetPort' => 'http-server',
                                'protocol' => 'TCP'
    }]

    assert_equal('guestbook', our_service.metadata.labels.name)

    hash = our_service.to_h

    assert_equal our_service.metadata.labels.name,
                 hash[:metadata][:labels][:name]

    stub_request(:post, %r{namespaces/staging/services})
      .to_return(body: open_test_file('created_service.json'),
                 status: 201)

    client = Kubeclient::Client.new 'http://localhost:8080/api/'
    created = client.create_service our_service

    assert_instance_of(Kubeclient::Service, created)
    assert_equal(created.metadata.name, our_service.metadata.name)
    assert_equal(created.spec.ports.size, our_service.spec.ports.size)
  end

  def test_conversion_from_json_v1
    stub_request(:get, %r{/services})
      .to_return(body: open_test_file('service.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/'
    service = client.get_service 'redis-slave', 'development'

    assert_instance_of(Kubeclient::Service, service)
    assert_equal('2015-04-05T13:00:31Z',
                 service.metadata.creationTimestamp)
    assert_equal('bdb80a8f-db93-11e4-b293-f8b156af4ae1', service.metadata.uid)
    assert_equal('redis-slave', service.metadata.name)
    assert_equal('2815', service.metadata.resourceVersion)
    assert_equal('v1', service.apiVersion)
    assert_equal('10.0.0.140', service.spec.clusterIP)
    assert_equal('development', service.metadata.namespace)

    assert_equal('TCP', service.spec.ports[0].protocol)
    assert_equal(6379, service.spec.ports[0].port)
    assert_equal('', service.spec.ports[0].name)
    assert_equal('redis-server', service.spec.ports[0].targetPort)

    assert_requested(:get,
                     'http://localhost:8080/api/v1/namespaces/development/services/redis-slave',
                     times: 1)
  end

  def test_delete_service
    our_service = Kubeclient::Service.new
    our_service.name = 'redis-service'
    # TODO, new ports assignment to be added
    our_service.labels = {}
    our_service.labels.component = 'apiserver'
    our_service.labels.provider = 'kubernetes'

    stub_request(:delete, %r{/namespaces/default/services})
      .to_return(status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1'
    client.delete_service our_service.name, 'default'

    assert_requested(:delete,
                     'http://localhost:8080/api/v1/namespaces/default/services/redis-service',
                     times: 1)
  end

  def test_get_service_no_ns
    # when not specifying namespace for entities which
    # are not node or namespace, the request will fail
    stub_request(:get, %r{/services/redis-slave})
      .to_return(status: 404)

    client = Kubeclient::Client.new 'http://localhost:8080/api/'

    exception = assert_raises(KubeException) do
      client.get_service 'redis-slave'
    end
    assert_equal(404, exception.error_code)
  end

  def test_get_service
    stub_request(:get, %r{/namespaces/development/services/redis-slave})
      .to_return(body: open_test_file('service.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/'
    service = client.get_service 'redis-slave', 'development'
    assert_equal('redis-slave', service.metadata.name)

    assert_requested(:get,
                     'http://localhost:8080/api/v1/namespaces/development/services/redis-slave',
                     times: 1)
  end

  def test_update_service
    entity = 'service'
    object = Kubeclient::Service.new
    name = 'my_service'
    object.metadata = {
      'name' => name
    }

    stub_request(:put, %r{/services/#{name}})\
      .to_return(
        body: open_test_file('service_update.json'),
        status: 200
      )

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1'
    client.update_entity entity, object

    assert_requested(
      :put,
      "http://localhost:8080/api/v1/services/#{name}",
      times: 1
    )
  end
end
