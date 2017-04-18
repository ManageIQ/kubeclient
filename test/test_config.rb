require 'test_helper'

# Testing Kubernetes client configuration
class KubeclientConfigTest < MiniTest::Test
  def test_allinone
    config = Kubeclient::Config.read(config_file('allinone.kubeconfig'))
    assert_equal(['default/localhost:8443/system:admin'], config.contexts)
    check_context(config.context, ssl: true)
  end

  def test_external
    config = Kubeclient::Config.read(config_file('external.kubeconfig'))
    assert_equal(['default/localhost:8443/system:admin'], config.contexts)
    check_context(config.context, ssl: true)
  end

  def test_nouser
    config = Kubeclient::Config.read(config_file('nouser.kubeconfig'))
    assert_equal(['default/localhost:8443/nouser'], config.contexts)
    check_context(config.context, ssl: false)
  end

  def test_user_token
    config = Kubeclient::Config.read(config_file('userauth.kubeconfig'))
    assert_equal(['localhost/system:admin:token', 'localhost/system:admin:userpass'],
                 config.contexts)
    context = config.context('localhost/system:admin:token')
    check_context(context, ssl: false)
    assert_equal('0123456789ABCDEF0123456789ABCDEF', context.auth_options[:bearer_token])
  end

  def test_user_password
    config = Kubeclient::Config.read(config_file('userauth.kubeconfig'))
    assert_equal(['localhost/system:admin:token', 'localhost/system:admin:userpass'],
                 config.contexts)
    context = config.context('localhost/system:admin:userpass')
    check_context(context, ssl: false)
    assert_equal('admin', context.auth_options[:username])
    assert_equal('pAssw0rd123', context.auth_options[:password])
  end

  private

  def check_context(context, ssl: true)
    assert_equal('https://localhost:8443', context.api_endpoint)
    assert_equal('v1', context.api_version)
    if ssl
      assert_equal(OpenSSL::SSL::VERIFY_PEER, context.ssl_options[:verify_ssl])
      assert_kind_of(OpenSSL::X509::Store, context.ssl_options[:cert_store])
      assert_kind_of(OpenSSL::X509::Certificate, context.ssl_options[:client_cert])
      assert_kind_of(OpenSSL::PKey::RSA, context.ssl_options[:client_key])
      # When certificates expire the quickest way to recreate them is using
      # an OpenShift tool (100% compatible with kubernetes):
      #
      #   $ oc adm ca create-master-certs --hostnames=localhost
      #
      # At the time of this writing the files to be updated are:
      #
      #   test/config/allinone.kubeconfig
      #   test/config/external-ca.pem
      #   test/config/external-cert.pem
      #   test/config/external-key.rsa
      assert(context.ssl_options[:cert_store].verify(context.ssl_options[:client_cert]))
    else
      assert_equal(OpenSSL::SSL::VERIFY_NONE, context.ssl_options[:verify_ssl])
    end
  end

  def config_file(name)
    File.new(File.join(File.dirname(__FILE__), 'config', name))
  end
end
