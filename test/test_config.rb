require 'test_helper'

def test_config_file(name)
  File.new(File.join(File.dirname(__FILE__), 'config', name))
end

# Testing Kubernetes client configuration
class KubeClientConfigTest < MiniTest::Test
  def test_allinone
    config = Kubeclient::Config.read(test_config_file('allinone.kubeconfig'))
    assert_equal(['default/localhost:8443/system:admin'], config.contexts)
    check_context(config.context)
  end

  def test_external
    config = Kubeclient::Config.read(test_config_file('external.kubeconfig'))
    assert_equal(['default/localhost:8443/system:admin'], config.contexts)
    check_context(config.context)
  end

  private

  def check_context(context)
    assert_equal('https://localhost:8443', context.api_endpoint)
    assert_equal('v1', context.api_version)
    assert_equal(OpenSSL::SSL::VERIFY_PEER, context.ssl_options[:verify_ssl])
    assert_kind_of(OpenSSL::X509::Store, context.ssl_options[:cert_store])
    assert_kind_of(OpenSSL::X509::Certificate, context.ssl_options[:client_cert])
    assert_kind_of(OpenSSL::PKey::RSA, context.ssl_options[:client_key])
    assert(context.ssl_options[:cert_store].verify(context.ssl_options[:client_cert]))
  end
end
