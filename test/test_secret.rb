require 'test_helper'

# Namespace entity tests
class TestSecret < MiniTest::Test
  def test_get_namespace_v1
    stub_request(:get, %r{/secrets})
      .to_return(body: open_test_json_file('secret.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1'
    secret = client.get_secret 'secret'

    assert_instance_of(Kubeclient::Secret, secret)
    assert_equal('e388bc10-c021-11e4-a514-3c970e4a436a', namespace.metadata.uid)
    assert_equal('staging', namespace.metadata.name)
    assert_equal('v1', namespace.apiVersion)

    assert_requested(:get,
                     'http://localhost:8080/api/v1/secrets/secret',
                     times: 1)
  end

  def test_delete_namespace_v1

    stub_request(:delete, %r{/namespaces})
      .to_return(status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta3'
    client.delete_namespace our_namespace.name

    assert_requested(:delete,
                     'http://localhost:8080/api/v1beta3/namespaces/staging',
                     times: 1)
  end

  def test_create_namespace
    stub_request(:post, %r{/namespaces})
      .to_return(body: open_test_json_file('created_namespace_b3.json'),
                 status: 201)

    namespace = Kubeclient::Namespace.new
    namespace.metadata = {}
    namespace.metadata.name = 'development'

    client = Kubeclient::Client.new 'http://localhost:8080/api/'
    created_namespace = client.create_namespace namespace
    assert_instance_of(Kubeclient::Namespace, created_namespace)
    assert_equal(namespace.metadata.name, created_namespace.metadata.name)
  end
end
