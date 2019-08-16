require_relative 'test_helper'
require 'yaml'
require 'open3'

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

  def test_allinone_nopath
    yaml = File.read(config_file('allinone.kubeconfig'))
    # A self-contained config shouldn't depend on kcfg_path.
    config = Kubeclient::Config.new(YAML.safe_load(yaml), nil)
    assert_equal(['default/localhost:8443/system:admin'], config.contexts)
    check_context(config.context, ssl: true)
  end

  def test_external_nopath
    yaml = File.read(config_file('external.kubeconfig'))
    # kcfg_path = nil should prevent file access
    config = Kubeclient::Config.new(YAML.safe_load(yaml), nil)
    assert_raises(StandardError) do
      config.context
    end
  end

  def test_external_nopath_absolute
    yaml = File.read(config_file('external.kubeconfig'))
    # kcfg_path = nil should prevent file access, even if absolute path specified
    ca_absolute_path = File.absolute_path(config_file('external-'))
    yaml = yaml.gsub('external-', ca_absolute_path)
    config = Kubeclient::Config.new(YAML.safe_load(yaml), nil)
    assert_raises(StandardError) do
      config.context
    end
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

  def test_timestamps
    # Test YAML parsing doesn't crash on YAML timestamp syntax.
    Kubeclient::Config.read(config_file('timestamps.kubeconfig'))
  end

  def test_user_exec
    token = '0123456789ABCDEF0123456789ABCDEF'
    creds = {
      'apiVersion': 'client.authentication.k8s.io/v1beta1',
      'status': {
        'token': token
      }
    }

    config = Kubeclient::Config.read(config_file('execauth.kubeconfig'))
    assert_equal(['localhost/system:admin:exec-search-path',
                  'localhost/system:admin:exec-relative-path',
                  'localhost/system:admin:exec-absolute-path'],
                 config.contexts)

    # A bare command name in config means search PATH, so it's executed as bare command.
    stub_exec(%r{^example-exec-plugin$}, creds) do
      context = config.context('localhost/system:admin:exec-search-path')
      check_context(context, ssl: false)
      assert_equal(token, context.auth_options[:bearer_token])
    end

    # A relative path is taken relative to the dir of the kubeconfig.
    stub_exec(%r{.*config/dir/example-exec-plugin$}, creds) do
      context = config.context('localhost/system:admin:exec-relative-path')
      check_context(context, ssl: false)
      assert_equal(token, context.auth_options[:bearer_token])
    end

    # An absolute path is taken as-is.
    stub_exec(%r{^/abs/path/example-exec-plugin$}, creds) do
      context = config.context('localhost/system:admin:exec-absolute-path')
      check_context(context, ssl: false)
      assert_equal(token, context.auth_options[:bearer_token])
    end
  end

  def test_user_exec_nopath
    yaml = File.read(config_file('execauth.kubeconfig'))
    config = Kubeclient::Config.new(YAML.safe_load(yaml), nil)
    config.contexts.each do |context_name|
      Open3.stub(:capture3, proc { flunk 'should not execute command' }) do
        assert_raises(StandardError) do
          config.context(context_name)
        end
      end
    end
  end

  def test_gcp_default_auth
    Kubeclient::GoogleApplicationDefaultCredentials.expects(:token).returns('token1').once
    parsed = YAML.safe_load(File.read(config_file('gcpauth.kubeconfig')), [Date, Time])
    config = Kubeclient::Config.new(parsed, nil)
    config.context(config.contexts.first)
  end

  # Each call to .context() obtains a new token, calling .auth_options doesn't change anything.
  # NOTE: this is not a guarantee, may change, just testing current behavior.
  def test_gcp_default_auth_renew
    Kubeclient::GoogleApplicationDefaultCredentials.expects(:token).returns('token1').once
    parsed = YAML.safe_load(File.read(config_file('gcpauth.kubeconfig')), [Date, Time])
    config = Kubeclient::Config.new(parsed, nil)
    context = config.context(config.contexts.first)
    assert_equal({ bearer_token: 'token1' }, context.auth_options)
    assert_equal({ bearer_token: 'token1' }, context.auth_options)

    Kubeclient::GoogleApplicationDefaultCredentials.expects(:token).returns('token2').once
    context2 = config.context(config.contexts.first)
    assert_equal({ bearer_token: 'token2' }, context2.auth_options)
    assert_equal({ bearer_token: 'token1' }, context.auth_options)
  end

  def test_gcp_command_auth
    Kubeclient::GCPCommandCredentials.expects(:token)
                                     .with('access-token' => '<fake_token>',
                                           'cmd-args' => 'config config-helper --format=json',
                                           'cmd-path' => '/path/to/gcloud',
                                           'expiry' => '2019-04-09 19:26:18 UTC',
                                           'expiry-key' => '{.credential.token_expiry}',
                                           'token-key' => '{.credential.access_token}')
                                     .returns('token1')
                                     .once
    config = Kubeclient::Config.read(config_file('gcpcmdauth.kubeconfig'))
    config.context(config.contexts.first)
  end

  def test_oidc_auth_provider
    Kubeclient::OIDCAuthProvider.expects(:token)
                                .with('client-id' => 'fake-client-id',
                                      'client-secret' => 'fake-client-secret',
                                      'id-token' => 'fake-id-token',
                                      'idp-issuer-url' => 'https://accounts.google.com',
                                      'refresh-token' => 'fake-refresh-token')
                                .returns('token1')
                                .once
    parsed = YAML.safe_load(File.read(config_file('oidcauth.kubeconfig')))
    config = Kubeclient::Config.new(parsed, nil)
    config.context(config.contexts.first)
  end

  private

  def check_context(context, ssl: true)
    assert_equal('https://localhost:8443', context.api_endpoint)
    assert_equal('v1', context.api_version)
    assert_equal('default', context.namespace)
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
      #   cp openshift.local.config/master/admin.kubeconfig test/config/allinone.kubeconfig
      #   cp openshift.local.config/master/ca.crt           test/config/external-ca.pem
      #   cp openshift.local.config/master/admin.crt        test/config/external-cert.pem
      #   cp openshift.local.config/master/admin.key        test/config/external-key.rsa
      assert(context.ssl_options[:cert_store].verify(context.ssl_options[:client_cert]))
    else
      assert_equal(OpenSSL::SSL::VERIFY_NONE, context.ssl_options[:verify_ssl])
    end
  end

  def config_file(name)
    File.join(File.dirname(__FILE__), 'config', name)
  end

  def stub_exec(command_regexp, creds)
    st = Minitest::Mock.new
    st.expect(:success?, true)

    capture3_stub = lambda do |_env, command, *_args|
      assert_match command_regexp, command
      [JSON.dump(creds), nil, st]
    end

    Open3.stub(:capture3, capture3_stub) do
      yield
    end
  end
end
