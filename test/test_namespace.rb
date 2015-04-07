require 'test_helper'

# Namespace entity tests
class TestNamespace < MiniTest::Test
  def test_get_namespace_v1beta3
    stub_request(:get, %r{/namespaces})
      .to_return(body: open_test_json_file('namespace_b3.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta3'
    namespace = client.get_namespace 'staging'

    assert_instance_of(Kubeclient::Namespace, namespace)
    assert_equal('e388bc10-c021-11e4-a514-3c970e4a436a', namespace.metadata.uid)
    assert_equal('staging', namespace.metadata.name)
    assert_equal('1168', namespace.metadata.resourceVersion)
    assert_equal('v1beta3', namespace.apiVersion)
  end

  def test_delete_namespace_v1beta3
    our_namespace = Kubeclient::Namespace.new
    our_namespace.name = 'staging'

    stub_request(:delete, %r{/namespaces})
      .to_return(status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta3'
    client.delete_namespace our_namespace.name
  end
end
