# frozen_string_literal: true

require_relative 'helper'

# Kubernetes client entity tests
class KubeclientTest < MiniTest::Test
  class TestFaradayMiddleware # rubocop:disable Lint/EmptyClass:
  end

  def test_json
    our_object = Kubeclient::Resource.new
    our_object.foo = 'bar'
    our_object.nested = {}
    our_object.nested.again = {}
    our_object.nested.again.again = {}
    our_object.nested.again.again.name = 'aaron'

    expected = {
      'foo' => 'bar',
      'nested' => { 'again' => { 'again' => { 'name' => 'aaron' } } }
    }

    assert_equal(expected, JSON.parse(JSON.dump(our_object.to_h)))
  end

  def test_pass_uri
    # URI::Generic#hostname= was added in ruby 1.9.3 and will automatically
    # wrap an ipv6 address in []
    uri = URI::HTTP.build(port: 8080)
    uri.hostname = 'localhost'
    client = Kubeclient::Client.new(uri, 'v1')
    faraday_client = client.faraday_client
    assert_equal('http://localhost:8080/api/v1', faraday_client.url_prefix.to_s)
  end

  def test_no_path_in_uri
    client = Kubeclient::Client.new('http://localhost:8080', 'v1')
    faraday_client = client.faraday_client
    assert_equal('http://localhost:8080/api/v1', faraday_client.url_prefix.to_s)
  end

  def test_no_version_passed
    e = assert_raises(ArgumentError) do
      Kubeclient::Client.new('http://localhost:8080')
    end
    assert_includes(e.message, 'wrong number of arguments')
  end

  def test_not_upgraded_to_new_api
    e = assert_raises(ArgumentError) do
      silence_stderr do
        Kubeclient::Client.new('http://localhost:8080', foo: 1)
      end
    end
    if RUBY_VERSION >= '3.0'
      assert_includes(e.message, 'wrong number of arguments')
    else
      assert_includes(e.message, 'second argument')
    end
  end

  def test_pass_proxy
    uri = URI::HTTP.build(host: 'localhost', port: 8080)
    proxy_uri = URI::HTTP.build(host: 'myproxyhost', port: 8888)
    stub_core_api_list

    client = Kubeclient::Client.new(uri, 'v1', http_proxy_uri: proxy_uri)
    faraday_client = client.faraday_client
    assert_equal(proxy_uri.to_s, faraday_client.proxy.uri.to_s)

    watch_client = client.watch_pods
    assert_equal(watch_client.send(:build_client_options)[:proxy][:proxy_address], proxy_uri.host)
    assert_equal(watch_client.send(:build_client_options)[:proxy][:proxy_port], proxy_uri.port)
  end

  def test_pass_max_redirects
    max_redirects = 0
    client = Kubeclient::Client.new(
      'http://localhost:8080/api/', 'v1',
      http_max_redirects: max_redirects
    )

    stub_request(:get, 'http://localhost:8080/api')
      .to_return(status: 302, headers: { location: 'http://localhost:1234/api' })

    exception = assert_raises(Kubeclient::HttpError) { client.api }
    assert_equal(302, exception.error_code)
  end

  def test_exception
    stub_core_api_list
    stub_request(:post, %r{/services})
      .to_return(body: open_test_file('namespace_exception.json'), status: 409)

    service = Kubeclient::Resource.new
    service.metadata = {}
    service.metadata.name = 'redisslave'
    service.metadata.namespace = 'default'
    # service.port = 80
    # service.container_port = 6379
    # service.protocol = 'TCP'

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')

    exception = assert_raises(Kubeclient::HttpError) do
      service = client.create_service(service)
    end

    assert_instance_of(Kubeclient::HttpError, exception)
    assert_equal(
      "converting  to : type names don't match (Pod, Namespace)",
      exception.message
    )

    assert_includes(exception.to_s, ' for POST /api/', 'v1')
    assert_equal(409, exception.error_code)
  end

  def test_deprecated_exception
    error_message = 'certificate verify failed'

    stub_request(:get, 'http://localhost:8080/api')
      .to_raise(OpenSSL::SSL::SSLError.new(error_message))

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')

    exception = assert_raises(KubeException) { client.api }
    assert_equal(error_message, exception.message)
  end

  def test_api
    stub_request(:get, 'http://localhost:8080/api')
      .to_return(status: 200, body: open_test_file('versions_list.json'))

    response = client.api
    assert_includes(response, 'versions')
  end

  def test_api_ssl_failure
    error_message = 'certificate verify failed'

    stub_request(:get, 'http://localhost:8080/api')
      .to_raise(OpenSSL::SSL::SSLError.new(error_message))

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')

    exception = assert_raises(Kubeclient::HttpError) { client.api }
    assert_equal(error_message, exception.message)
  end

  def test_api_timeout
    stub_request(:get, 'http://localhost:8080/api').to_timeout

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')

    exception = assert_raises(Kubeclient::HttpError) { client.api }
    assert_match(/execution expired/i, exception.message)
  end

  def test_api_valid
    stub_request(:get, 'http://localhost:8080/api')
      .to_return(status: 200, body: open_test_file('versions_list.json'))

    args = ['http://localhost:8080/api/']

    %w[v1beta3 v1].each do |version|
      client = Kubeclient::Client.new(*args, version)
      assert client.api_valid?
    end
  end

  def test_api_valid_with_invalid_version
    stub_request(:get, 'http://localhost:8080/api')
      .to_return(status: 200, body: open_test_file('versions_list.json'))

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'foobar1')
    refute client.api_valid?
  end

  def test_api_valid_with_unreported_versions
    stub_request(:get, 'http://localhost:8080/api')
      .to_return(status: 200, body: '{}')

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    refute client.api_valid?
  end

  def test_api_valid_with_invalid_json
    stub_request(:get, 'http://localhost:8080/api')
      .to_return(status: 200, body: '[]')

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    refute client.api_valid?
  end

  def test_api_valid_with_bad_endpoint
    stub_request(:get, 'http://localhost:8080/api')
      .to_return(status: [404, 'Resource Not Found'])

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    assert_raises(Kubeclient::HttpError) { client.api_valid? }
  end

  def test_api_valid_with_non_json
    stub_request(:get, 'http://localhost:8080/api')
      .to_return(status: 200, body: '<html></html>')

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    assert_raises(JSON::ParserError) { client.api_valid? }
  end

  def test_nonjson_exception
    stub_core_api_list
    stub_request(:get, %r{/servic})
      .to_return(body: open_test_file('service_illegal_json_404.json'), status: 404)

    exception = assert_raises(Kubeclient::ResourceNotFoundError) do
      client.get_services
    end

    assert_equal(404, exception.error_code)
  end

  def test_nonjson_exception_raw
    stub_core_api_list
    stub_request(:get, %r{/servic})
      .to_return(body: open_test_file('service_illegal_json_404.json'), status: 404)

    exception = assert_raises(Kubeclient::ResourceNotFoundError) do
      client.get_services(as: :raw)
    end

    assert_equal(404, exception.error_code)
  end

  def test_resource_already_exists_exception
    stub_core_api_list
    stub_request(:post, %r{/api/v1/namespaces})
      .to_return(body: open_test_file('namespace_already_exists.json'), status: 409)

    exception = assert_raises(Kubeclient::ResourceAlreadyExistsError) do
      client.create_namespace(Kubeclient::Resource.new(metadata: { name: 'default' }))
    end

    assert_equal(409, exception.error_code)
  end

  def test_entity_list
    stub_core_api_list
    stub_get_services

    services = client.get_services

    refute_empty(services)
    assert_instance_of(Kubeclient::Common::EntityList, services)
    # Stripping of 'List' in collection.kind RecursiveOpenStruct mode only is historic.
    assert_equal('Service', services.kind)
    assert_equal(2, services.size)
    assert_instance_of(Kubeclient::Resource, services[0])
    assert_instance_of(Kubeclient::Resource, services[1])

    assert_requested(:get, 'http://localhost:8080/api/v1/services', times: 1)
  end

  def test_entity_list_raw
    stub_core_api_list
    stub_get_services

    response = client.get_services(as: :raw)

    refute_empty(response)
    assert_equal(open_test_file('entity_list.json').read, response)

    assert_requested(:get, 'http://localhost:8080/api/v1/services', times: 1)
  end

  def test_entity_list_parsed
    stub_core_api_list
    stub_get_services

    response = client.get_services(as: :parsed)
    assert_equal(Hash, response.class)
    assert_equal('ServiceList', response['kind'])
    assert_equal(%w[metadata spec status], response['items'].first.keys)
  end

  def test_entity_list_parsed_symbolized
    stub_core_api_list
    stub_get_services

    response = client.get_services(as: :parsed_symbolized)
    assert_equal(Hash, response.class)
    assert_equal('ServiceList', response[:kind])
    assert_equal(%i[metadata spec status], response[:items].first.keys)
  end

  def test_delete_collection
    stub_core_api_list
    stub_delete_pods

    pods = client.delete_pods(namespace: 'foo')

    refute_empty(pods)
    assert_instance_of(Kubeclient::Common::EntityList, pods)
    # Stripping of 'List' in collection.kind RecursiveOpenStruct mode only is historic.
    assert_equal('Pod', pods.kind)
    assert_equal(1, pods.size)
    assert_instance_of(Kubeclient::Resource, pods[0])

    assert_requested(:delete, 'http://localhost:8080/api/v1/namespaces/foo/pods', times: 1)
  end

  def test_delete_collection_raw
    stub_core_api_list
    stub_delete_pods

    response = client.delete_pods(namespace: 'foo', as: :raw)

    refute_empty(response)
    assert_equal(open_test_file('pod_list.json').read, response)

    assert_requested(:delete, 'http://localhost:8080/api/v1/namespaces/foo/pods', times: 1)
  end

  def test_delete_collection_parsed
    stub_core_api_list
    stub_delete_pods

    response = client.delete_pods(namespace: 'foo', as: :parsed)
    assert_equal(Hash, response.class)
    assert_equal('PodList', response['kind'])
    assert_equal(%w[metadata spec status], response['items'].first.keys)
  end

  def test_delete_collection_parsed_symbolized
    stub_core_api_list
    stub_delete_pods

    response = client.delete_pods(namespace: 'foo', as: :parsed_symbolized)
    assert_equal(Hash, response.class)
    assert_equal('PodList', response[:kind])
    assert_equal(%i[metadata spec status], response[:items].first.keys)
  end

  def test_custom_faraday_config_options
    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    expected_middlewares = [Faraday::FollowRedirects::Middleware, Faraday::Response::RaiseError]
    expected_middlewares.each do |klass|
      assert(client.faraday_client.builder.handlers.include?(klass))
    end
    client.configure_faraday { |connection| connection.use(TestFaradayMiddleware) }
    expected_middlewares << TestFaradayMiddleware
    expected_middlewares.each do |klass|
      assert(client.faraday_client.builder.handlers.include?(klass))
    end
  end

  class ServiceList
    attr_reader :names

    def initialize(raw)
      items = JSON.parse(raw)['items']
      @names = items.map { |item| item['metadata']['name'] }
    end
  end

  def test_entity_list_class
    stub_core_api_list
    stub_get_services

    response = client.get_services(as: ServiceList)
    assert_equal(%w[kubernetes kubernetes-ro], response.names)
  end

  def test_entity_list_unknown
    stub_core_api_list
    stub_get_services

    e = assert_raises(ArgumentError) { client.get_services(as: :whoops) }
    assert_equal('Unsupported format :whoops', e.message)
  end

  def test_entity_list_raw_failure
    stub_core_api_list
    stub_request(:get, %r{/services})
      .to_return(body: open_test_file('entity_list.json'), status: 500)

    exception = assert_raises(Kubeclient::HttpError) { client.get_services(as: :raw) }
    assert_equal(500, exception.error_code)
  end

  def test_entities_with_label_selector
    selector = 'component=apiserver'

    stub_core_api_list
    stub_get_services

    services = client.get_services(label_selector: selector)

    assert_instance_of(Kubeclient::Common::EntityList, services)
    assert_requested(
      :get,
      "http://localhost:8080/api/v1/services?labelSelector=#{selector}",
      times: 1
    )
  end

  def test_entities_with_resource_version
    version = '329'

    stub_core_api_list
    stub_get_services

    services = client.get_services(resource_version: version)

    assert_instance_of(Kubeclient::Common::EntityList, services)
    assert_requested(
      :get,
      "http://localhost:8080/api/v1/services?resourceVersion=#{version}",
      times: 1
    )
  end

  def test_entities_with_field_selector
    selector = 'involvedObject.name=redis-master'

    stub_core_api_list
    stub_get_services

    services = client.get_services(field_selector: selector)

    assert_instance_of(Kubeclient::Common::EntityList, services)
    assert_requested(
      :get,
      "http://localhost:8080/api/v1/services?fieldSelector=#{selector}",
      times: 1
    )
  end

  def test_empty_list
    stub_core_api_list
    stub_request(:get, %r{/pods})
      .to_return(body: open_test_file('empty_pod_list.json'), status: 200)

    pods = client.get_pods
    assert_instance_of(Kubeclient::Common::EntityList, pods)
    assert_equal(0, pods.size)
  end

  def test_get_all
    stub_core_api_list

    stub_request(:get, %r{/bindings})
      .to_return(body: open_test_file('bindings_list.json'), status: 404)

    stub_request(:get, %r{/configmaps})
      .to_return(body: open_test_file('config_map_list.json'), status: 200)

    stub_request(:get, %r{/podtemplates})
      .to_return(body: open_test_file('pod_template_list.json'), status: 200)

    stub_request(:get, %r{/services})
      .to_return(body: open_test_file('service_list.json'), status: 200)

    stub_request(:get, %r{/pods})
      .to_return(body: open_test_file('pod_list.json'), status: 200)

    stub_request(:get, %r{/nodes})
      .to_return(body: open_test_file('node_list.json'), status: 200)

    stub_request(:get, %r{/replicationcontrollers})
      .to_return(body: open_test_file('replication_controller_list.json'), status: 200)

    stub_request(:get, %r{/events})
      .to_return(body: open_test_file('event_list.json'), status: 200)

    stub_request(:get, %r{/endpoints})
      .to_return(body: open_test_file('endpoint_list.json'), status: 200)

    stub_request(:get, %r{/namespaces})
      .to_return(body: open_test_file('namespace_list.json'), status: 200)

    stub_request(:get, %r{/secrets})
      .to_return(body: open_test_file('secret_list.json'), status: 200)

    stub_request(:get, %r{/resourcequotas})
      .to_return(body: open_test_file('resource_quota_list.json'), status: 200)

    stub_request(:get, %r{/limitranges})
      .to_return(body: open_test_file('limit_range_list.json'), status: 200)

    stub_request(:get, %r{/persistentvolumes})
      .to_return(body: open_test_file('persistent_volume_list.json'), status: 200)

    stub_request(:get, %r{/persistentvolumeclaims})
      .to_return(body: open_test_file('persistent_volume_claim_list.json'), status: 200)

    stub_request(:get, %r{/componentstatuses})
      .to_return(body: open_test_file('component_status_list.json'), status: 200)

    stub_request(:get, %r{/serviceaccounts})
      .to_return(body: open_test_file('service_account_list.json'), status: 200)

    result = client.all_entities
    assert_equal(16, result.keys.size)
    assert_instance_of(Kubeclient::Common::EntityList, result['node'])
    assert_instance_of(Kubeclient::Common::EntityList, result['service'])
    assert_instance_of(Kubeclient::Common::EntityList, result['replication_controller'])
    assert_instance_of(Kubeclient::Common::EntityList, result['pod'])
    assert_instance_of(Kubeclient::Common::EntityList, result['event'])
    assert_instance_of(Kubeclient::Common::EntityList, result['namespace'])
    assert_instance_of(Kubeclient::Common::EntityList, result['secret'])
    assert_instance_of(Kubeclient::Resource, result['service'][0])
    assert_instance_of(Kubeclient::Resource, result['node'][0])
    assert_instance_of(Kubeclient::Resource, result['event'][0])
    assert_instance_of(Kubeclient::Resource, result['endpoint'][0])
    assert_instance_of(Kubeclient::Resource, result['namespace'][0])
    assert_instance_of(Kubeclient::Resource, result['secret'][0])
    assert_instance_of(Kubeclient::Resource, result['resource_quota'][0])
    assert_instance_of(Kubeclient::Resource, result['limit_range'][0])
    assert_instance_of(Kubeclient::Resource, result['persistent_volume'][0])
    assert_instance_of(Kubeclient::Resource, result['persistent_volume_claim'][0])
    assert_instance_of(Kubeclient::Resource, result['component_status'][0])
    assert_instance_of(Kubeclient::Resource, result['service_account'][0])
  end

  def test_get_all_raw
    stub_core_api_list

    stub_request(:get, %r{/bindings})
      .to_return(body: open_test_file('bindings_list.json'), status: 404)

    stub_request(:get, %r{/configmaps})
      .to_return(body: open_test_file('config_map_list.json'), status: 200)

    stub_request(:get, %r{/podtemplates})
      .to_return(body: open_test_file('pod_template_list.json'), status: 200)

    stub_request(:get, %r{/services})
      .to_return(body: open_test_file('service_list.json'), status: 200)

    stub_request(:get, %r{/pods})
      .to_return(body: open_test_file('pod_list.json'), status: 200)

    stub_request(:get, %r{/nodes})
      .to_return(body: open_test_file('node_list.json'), status: 200)

    stub_request(:get, %r{/replicationcontrollers})
      .to_return(body: open_test_file('replication_controller_list.json'), status: 200)

    stub_request(:get, %r{/events})
      .to_return(body: open_test_file('event_list.json'), status: 200)

    stub_request(:get, %r{/endpoints})
      .to_return(body: open_test_file('endpoint_list.json'), status: 200)

    stub_request(:get, %r{/namespaces})
      .to_return(body: open_test_file('namespace_list.json'), status: 200)

    stub_request(:get, %r{/secrets})
      .to_return(body: open_test_file('secret_list.json'), status: 200)

    stub_request(:get, %r{/resourcequotas})
      .to_return(body: open_test_file('resource_quota_list.json'), status: 200)

    stub_request(:get, %r{/limitranges})
      .to_return(body: open_test_file('limit_range_list.json'), status: 200)

    stub_request(:get, %r{/persistentvolumes})
      .to_return(body: open_test_file('persistent_volume_list.json'), status: 200)

    stub_request(:get, %r{/persistentvolumeclaims})
      .to_return(body: open_test_file('persistent_volume_claim_list.json'), status: 200)

    stub_request(:get, %r{/componentstatuses})
      .to_return(body: open_test_file('component_status_list.json'), status: 200)

    stub_request(:get, %r{/serviceaccounts})
      .to_return(body: open_test_file('service_account_list.json'), status: 200)

    result = client.all_entities(as: :raw)
    assert_equal(16, result.keys.size)

    %w[
      component_status config_map endpoint event limit_range namespace node
      persistent_volume persistent_volume_claim pod replication_controller
      resource_quota secret service service_account
    ].each do |entity|
      assert_equal(open_test_file("#{entity}_list.json").read, result[entity])
    end
  end

  def test_api_bearer_token_with_params_success
    stub_request(:get, 'http://localhost:8080/api/v1/pods?labelSelector=name=redis-master')
      .with(headers: { Authorization: 'Bearer valid_token' })
      .to_return(body: open_test_file('pod_list.json'), status: 200)
    stub_request(:get, %r{/api/v1$})
      .with(headers: { Authorization: 'Bearer valid_token' })
      .to_return(body: open_test_file('core_api_resource_list.json'), status: 200)

    client = Kubeclient::Client.new(
      'http://localhost:8080/api/',
      'v1',
      auth_options: { bearer_token: 'valid_token' }
    )

    pods = client.get_pods(label_selector: 'name=redis-master')

    assert_equal('Pod', pods.kind)
    assert_equal(1, pods.size)
  end

  def test_api_bearer_token_success
    stub_core_api_list
    stub_request(:get, 'http://localhost:8080/api/v1/pods')
      .with(headers: { Authorization: 'Bearer valid_token' })
      .to_return(
        body: open_test_file('pod_list.json'), status: 200
      )

    client = Kubeclient::Client.new(
      'http://localhost:8080/api/', 'v1',
      auth_options: { bearer_token: 'valid_token' }
    )

    pods = client.get_pods

    assert_equal('Pod', pods.kind)
    assert_equal(1, pods.size)
  end

  def test_api_bearer_token_failure
    error_message =
      '"/api/v1" is forbidden because ' \
      'system:anonymous cannot list on pods in'
    response = OpenStruct.new(code: 401, message: error_message)

    stub_request(:get, 'http://localhost:8080/api/v1')
      .with(headers: { Authorization: 'Bearer invalid_token' })
      .to_raise(Kubeclient::HttpError.new(403, error_message, response))

    client = Kubeclient::Client.new(
      'http://localhost:8080/api/', 'v1',
      auth_options: { bearer_token: 'invalid_token' }
    )

    exception = assert_raises(Kubeclient::HttpError) { client.get_pods }
    assert_equal(403, exception.error_code)
    assert_equal(error_message, exception.message)
    assert_equal(response, exception.response)
  end

  def test_api_bearer_token_failure_raw
    error_message =
      '"/api/v1" is forbidden because ' \
      'system:anonymous cannot list on pods in'
    response = OpenStruct.new(code: 401, message: error_message)

    stub_request(:get, 'http://localhost:8080/api/v1')
      .with(headers: { Authorization: 'Bearer invalid_token' })
      .to_raise(Kubeclient::HttpError.new(403, error_message, response))

    client = Kubeclient::Client.new(
      'http://localhost:8080/api/', 'v1',
      auth_options: { bearer_token: 'invalid_token' }
    )

    exception = assert_raises(Kubeclient::HttpError) { client.get_pods(as: :raw) }
    assert_equal(403, exception.error_code)
    assert_equal(error_message, exception.message)
    assert_equal(response, exception.response)
  end

  def test_api_basic_auth_success
    stub_request(:get, 'http://localhost:8080/api/v1')
      .with(basic_auth: %w[username password])
      .to_return(body: open_test_file('core_api_resource_list.json'), status: 200)
    stub_request(:get, 'http://localhost:8080/api/v1/pods')
      .with(basic_auth: %w[username password])
      .to_return(body: open_test_file('pod_list.json'), status: 200)

    client = Kubeclient::Client.new(
      'http://localhost:8080/api/', 'v1',
      auth_options: { username: 'username', password: 'password' }
    )

    pods = client.get_pods

    assert_equal('Pod', pods.kind)
    assert_equal(1, pods.size)
    assert_requested(
      :get,
      'http://localhost:8080/api/v1/pods',
      times: 1
    )
  end

  def test_api_basic_auth_back_comp_success
    stub_request(:get, 'http://localhost:8080/api/v1')
      .with(basic_auth: %w[username password])
      .to_return(body: open_test_file('core_api_resource_list.json'), status: 200)
    stub_request(:get, 'http://localhost:8080/api/v1/pods')
      .with(basic_auth: %w[username password])
      .to_return(body: open_test_file('pod_list.json'), status: 200)

    client = Kubeclient::Client.new(
      'http://localhost:8080/api/', 'v1',
      auth_options: { user: 'username', password: 'password' }
    )

    pods = client.get_pods

    assert_equal('Pod', pods.kind)
    assert_equal(1, pods.size)
    assert_requested(:get, 'http://localhost:8080/api/v1/pods', times: 1)
  end

  def test_api_basic_auth_failure
    error_message = 'HTTP status code 401, 401 Unauthorized'
    response = OpenStruct.new(code: 401, message: '401 Unauthorized')

    stub_request(:get, 'http://localhost:8080/api/v1')
      .with(basic_auth: %w[username password])
      .to_raise(Kubeclient::HttpError.new(401, error_message, response))

    client = Kubeclient::Client.new(
      'http://localhost:8080/api/', 'v1',
      auth_options: { username: 'username', password: 'password' }
    )

    exception = assert_raises(Kubeclient::HttpError) { client.get_pods }
    assert_equal(401, exception.error_code)
    assert_equal(error_message, exception.message)
    assert_equal(response, exception.response)
    assert_requested(:get, 'http://localhost:8080/api/v1', times: 1)
  end

  def test_api_basic_auth_failure_raw
    error_message = 'HTTP status code 401, 401 Unauthorized'
    response = OpenStruct.new(code: 401, message: '401 Unauthorized')

    stub_request(:get, 'http://localhost:8080/api/v1')
      .with(basic_auth: %w[username password])
      .to_raise(Kubeclient::HttpError.new(401, error_message, response))

    client = Kubeclient::Client.new(
      'http://localhost:8080/api/', 'v1',
      auth_options: { username: 'username', password: 'password' }
    )

    exception = assert_raises(Kubeclient::HttpError) { client.get_pods(as: :raw) }
    assert_equal(401, exception.error_code)
    assert_equal(error_message, exception.message)
    assert_equal(response, exception.response)

    assert_requested(:get, 'http://localhost:8080/api/v1', times: 1)
  end

  def test_init_username_no_password
    expected_msg = 'Basic auth requires both username & password'
    exception = assert_raises(ArgumentError) do
      Kubeclient::Client.new(
        'http://localhost:8080', 'v1',
        auth_options: { username: 'username' }
      )
    end
    assert_equal(expected_msg, exception.message)
  end

  def test_init_user_no_password
    expected_msg = 'Basic auth requires both username & password'
    exception = assert_raises(ArgumentError) do
      Kubeclient::Client.new(
        'http://localhost:8080', 'v1',
        auth_options: { user: 'username' }
      )
    end
    assert_equal(expected_msg, exception.message)
  end

  def test_init_username_and_bearer_token
    expected_msg = 'Invalid auth options: specify only one of username/password,' \
      ' bearer_token or bearer_token_file'
    exception = assert_raises(ArgumentError) do
      Kubeclient::Client.new(
        'http://localhost:8080', 'v1',
        auth_options: { username: 'username', bearer_token: 'token' }
      )
    end
    assert_equal(expected_msg, exception.message)
  end

  def test_init_username_and_bearer_token_file
    expected_msg = 'Invalid auth options: specify only one of username/password,' \
      ' bearer_token or bearer_token_file'
    exception = assert_raises(ArgumentError) do
      Kubeclient::Client.new(
        'http://localhost:8080', 'v1',
        auth_options: { username: 'username', bearer_token_file: 'token-file' }
      )
    end
    assert_equal(expected_msg, exception.message)
  end

  def test_bearer_token_and_bearer_token_file
    expected_msg =
      'Invalid auth options: specify only one of username/password,' \
      ' bearer_token or bearer_token_file'
    exception = assert_raises(ArgumentError) do
      Kubeclient::Client.new(
        'http://localhost:8080', 'v1',
        auth_options: { bearer_token: 'token', bearer_token_file: 'token-file' }
      )
    end
    assert_equal(expected_msg, exception.message)
  end

  def test_bearer_token_file_not_exist
    expected_msg = 'Token file token-file does not exist'
    exception = assert_raises(ArgumentError) do
      Kubeclient::Client.new(
        'http://localhost:8080', 'v1',
        auth_options: { bearer_token_file: 'token-file' }
      )
    end
    assert_equal(expected_msg, exception.message)
  end

  def test_api_bearer_token_file_success
    stub_core_api_list
    stub_request(:get, 'http://localhost:8080/api/v1/pods')
      .with(headers: { Authorization: 'Bearer valid_token' })
      .to_return(body: open_test_file('pod_list.json'), status: 200)

    file = File.join(File.dirname(__FILE__), 'valid_token_file')
    client = Kubeclient::Client.new(
      'http://localhost:8080/api/', 'v1',
      auth_options: { bearer_token_file: file }
    )

    pods = client.get_pods

    assert_equal('Pod', pods.kind)
    assert_equal(1, pods.size)
  end

  def test_api_bearer_token_file_refreshes
    stub_core_api_list

    file = File.join(File.dirname(__FILE__), 'valid_token_file')
    client = Kubeclient::Client.new(
      'http://localhost:8080/api/', 'v1',
      auth_options: { bearer_token_file: file }
    )

    first_request = stub_request(:get, 'http://localhost:8080/api/v1/pods')
                    .with(headers: { Authorization: 'Bearer valid_token' })
                    .to_return(body: '{}', status: 200)

    client.get_pods

    assert_requested(first_request)

    WebMock.reset!

    File.open(file, 'w') { |f| f.puts('another_valid_token') }

    second_request = stub_request(:get, 'http://localhost:8080/api/v1/pods')
                     .with(headers: { Authorization: 'Bearer another_valid_token' })
                     .to_return(body: '{}', status: 200)

    client.get_pods

    assert_requested(second_request)
  ensure
    File.open(file, 'w') { |f| f.puts('valid_token') }
  end

  def test_impersonate
    pods_stub = stub_request(:get, 'http://localhost:8080/api/v1/pods')
                .with(
                  headers: {
                    Authorization: 'Bearer valid_token',
                    'Impersonate-Extra-Reason': 'reason-1',
                    'Impersonate-Extra-Scopes': 'scope-1',
                    'Impersonate-Group': 'bar',
                    'Impersonate-User': 'foo',
                    'Impersonate-Uid': '123'
                  }
                )
                .to_return(body: { items: [] }.to_json)
    stub_request(:get, %r{/api/v1$})
      .with(headers: { Authorization: 'Bearer valid_token' })
      .to_return(body: open_test_file('core_api_resource_list.json'))

    client = Kubeclient::Client.new(
      'http://localhost:8080/api/',
      'v1',
      auth_options: {
        bearer_token: 'valid_token',
        as: 'foo',
        as_groups: ['bar'],
        as_user_extra: { 'reason' => ['reason-1'], 'scopes' => ['scope-1'] },
        as_uid: '123'
      }
    )

    client.get_pods
    assert_requested(pods_stub)
  end

  def test_impersonate_empty_groups
    pods_headers = nil
    pods_stub = stub_request(:get, 'http://localhost:8080/api/v1/pods')
                .with { |request| pods_headers = request.headers }
                .to_return(body: { items: [] }.to_json)
    stub_request(:get, %r{/api/v1$})
      .with(headers: { Authorization: 'Bearer valid_token' })
      .to_return(body: open_test_file('core_api_resource_list.json'))

    client = Kubeclient::Client.new(
      'http://localhost:8080/api/',
      'v1',
      auth_options: {
        bearer_token: 'valid_token',
        as: 'foo',
        as_groups: [],
        as_user_extra: { 'reason' => [], 'scopes' => [] },
        as_uid: '123'
      }
    )

    client.get_pods
    assert_requested(pods_stub)
    assert_includes(pods_headers, 'Impersonate-User')
    assert_includes(pods_headers, 'Impersonate-Uid')
    refute_includes(pods_headers, 'Impersonate-Groups')
    refute_includes(pods_headers, 'Impersonate-Extra-Reason')
    refute_includes(pods_headers, 'Impersonate-Extra-Scopes')
  end

  def test_impersonate_limitations
    assert_raises(ArgumentError) do
      Kubeclient::Client.new(
        'http://localhost:8080/api/',
        'v1',
        auth_options: {
          bearer_token: 'valid_token',
          as: 'foo',
          as_groups: ['bar', 'baz'],
          as_user_extra: { 'reason' => ['reason-1', 'reason-2'] },
          as_uid: '123'
        }
      )
    end
  end

  def test_proxy_url
    stub_core_api_list

    client = Kubeclient::Client.new('http://host:8080', 'v1')
    assert_equal(
      'http://host:8080/api/v1/namespaces/ns/services/srvname:srvportname/proxy',
      client.proxy_url('service', 'srvname', 'srvportname', 'ns')
    )

    assert_equal(
      'http://host:8080/api/v1/namespaces/ns/services/srvname:srvportname/proxy',
      client.proxy_url('services', 'srvname', 'srvportname', 'ns')
    )

    assert_equal(
      'http://host:8080/api/v1/namespaces/ns/pods/srvname:srvportname/proxy',
      client.proxy_url('pod', 'srvname', 'srvportname', 'ns')
    )

    assert_equal(
      'http://host:8080/api/v1/namespaces/ns/pods/srvname:srvportname/proxy',
      client.proxy_url('pods', 'srvname', 'srvportname', 'ns')
    )

    # Check no namespace provided
    assert_equal(
      'http://host:8080/api/v1/nodes/srvname:srvportname/proxy',
      client.proxy_url('nodes', 'srvname', 'srvportname')
    )

    assert_equal(
      'http://host:8080/api/v1/nodes/srvname:srvportname/proxy',
      client.proxy_url('node', 'srvname', 'srvportname')
    )

    # Check integer port
    assert_equal(
      'http://host:8080/api/v1/nodes/srvname:5001/proxy',
      client.proxy_url('nodes', 'srvname', 5001)
    )

    assert_equal(
      'http://host:8080/api/v1/nodes/srvname:5001/proxy',
      client.proxy_url('node', 'srvname', 5001)
    )
  end

  def test_attr_readers
    client = Kubeclient::Client.new(
      'http://localhost:8080/api/',
      'v1',
      ssl_options: { client_key: 'secret' },
      auth_options: { bearer_token: 'token' }
    )
    assert_equal('/api', client.api_endpoint.path)
    assert_equal('secret', client.ssl_options[:client_key])
    assert_equal('token', client.auth_options[:bearer_token])
  end

  def test_nil_items
    # handle https://github.com/kubernetes/kubernetes/issues/13096
    stub_core_api_list
    stub_request(:get, %r{/persistentvolumeclaims})
      .to_return(body: open_test_file('persistent_volume_claims_nil_items.json'), status: 200)

    client.get_persistent_volume_claims
  end

  # Timeouts

  def test_timeouts_defaults
    client = Kubeclient::Client.new(
      'http://localhost:8080/api/',
      'v1'
    )
    faraday_client = client.faraday_client
    assert_default_open_timeout(faraday_client.options.open_timeout)
    assert_equal(60, faraday_client.options.read_timeout)
  end

  def test_timeouts_open
    client = Kubeclient::Client.new(
      'http://localhost:8080/api/',
      'v1',
      timeouts: { open: 10 }
    )
    faraday_client = client.faraday_client
    assert_equal(10, faraday_client.options.open_timeout)
    assert_equal(60, faraday_client.options.read_timeout)
  end

  def test_timeouts_read
    client = Kubeclient::Client.new(
      'http://localhost:8080/api/',
      'v1',
      timeouts: { read: 300 }
    )
    faraday_client = client.faraday_client
    assert_default_open_timeout(faraday_client.options.open_timeout)
    assert_equal(300, faraday_client.options.read_timeout)
  end

  def test_timeouts_both
    client = Kubeclient::Client.new(
      'http://localhost:8080/api/', 'v1',
      timeouts: { open: 10, read: 300 }
    )
    faraday_client = client.faraday_client
    assert_equal(10, faraday_client.options.open_timeout)
    assert_equal(300, faraday_client.options.read_timeout)
  end

  def test_timeouts_infinite
    client = Kubeclient::Client.new(
      'http://localhost:8080/api/', 'v1',
      timeouts: { open: nil, read: nil }
    )
    faraday_client = client.faraday_client
    assert_nil(faraday_client.options.open_timeout)
    assert_nil(faraday_client.options.read_timeout)
  end

  def assert_default_open_timeout(actual)
    assert_equal(60, actual)
  end

  private

  def stub_get_services
    stub_request(:get, %r{/services})
      .to_return(body: open_test_file('entity_list.json'), status: 200)
  end

  def stub_delete_pods
    stub_request(:delete, %r{/pods})
      .to_return(body: open_test_file('pod_list.json'), status: 200)
  end

  def client
    @client ||= Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
  end

  # dup method creates a shallow copy which is not good in this case
  # since rename_keys changes the input hash
  # hence need to create a deep_copy
  def deep_copy(hash)
    Marshal.load(Marshal.dump(hash))
  end

  def silence_stderr
    old = $stderr
    $stderr = StringIO.new
    yield
  ensure
    $stderr = old
  end
end
