require_relative 'test_helper'

# Test method_missing, respond_to? and respond_to_missing behaviour
class TestMissingMethods < MiniTest::Test
  def test_missing
    stub_request(:get, %r{/api/v1$}).to_return(
      body: open_test_file('core_api_resource_list.json'),
      status: 200
    )
    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    assert_equal(true, client.respond_to?(:get_pod))
    assert_equal(true, client.respond_to?(:get_pods))
    assert_equal(false, client.respond_to?(:get_pie))
    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1') # Reset discovery
    assert_equal(false, client.respond_to?(:get_pie))
    assert_equal(true, client.respond_to?(:get_pods))
    assert_equal(true, client.respond_to?(:get_pod))
    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1') # Reset discovery
    assert_instance_of(Method, client.method(:get_pods))
    assert_raises(NameError) do
      client.method(:get_pies)
    end
    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1') # Reset discovery
    assert_raises(NameError) do
      client.method(:get_pies)
    end
    assert_instance_of(Method, client.method(:get_pods))

    stub_request(:get, %r{/api/v1$}).to_return(
      body: '',
      status: 404
    ) # If discovery fails we expect the below raise an exception
    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    assert_raises(Kubeclient::HttpError) do
      client.method(:get_pods)
    end
    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    assert_raises(Kubeclient::HttpError) do
      client.respond_to?(:get_pods)
    end
  end
end
