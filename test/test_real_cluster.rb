require_relative 'helper'

class KubeclientRealClusterTest < MiniTest::Test
  # Tests here actually connect to a cluster!
  # For simplicity, these tests use same config/*.kubeconfig files as test_config.rb,
  # so are intended to run from config/update_certs_k0s.rb script.
  def setup
    if ENV['KUBECLIENT_TEST_REAL_CLUSTER'] == 'true'
      WebMock.enable_net_connect!
    else
      skip('Requires real cluster, see test/config/update_certs_k0s.rb.')
    end
  end

  def teardown
    WebMock.disable_net_connect! # Don't allow any connections in other tests.
  end

  def test_real_cluster_verify_peer
    config = Kubeclient::Config.read(config_file('external.kubeconfig'))
    context = config.context
    # localhost and 127.0.0.1 are among names on the certificate
    client1 = Kubeclient::Client.new(
      'https://127.0.0.1:6443', 'v1',
      ssl_options: context.ssl_options.merge(verify_ssl: OpenSSL::SSL::VERIFY_PEER),
      auth_options: context.auth_options
    )
    client1.discover
    client1.get_nodes
    exercise_watcher_with_timeout(client1.watch_nodes)
    # 127.0.0.2 also means localhost but is not included in the certificate.
    client2 = Kubeclient::Client.new(
      'https://127.0.0.2:6443', 'v1',
      ssl_options: context.ssl_options.merge(verify_ssl: OpenSSL::SSL::VERIFY_PEER),
      auth_options: context.auth_options
    )
    # TODO: all OpenSSL exceptions should be wrapped with Kubeclient error.
    assert_raises(Kubeclient::HttpError, OpenSSL::SSL::SSLError) do
      client2.discover
    end
    # Since discovery fails, methods like .get_nodes, .watch_nodes would all fail
    # on method_missing -> discover.  Call lower-level methods to test actual connection.
    assert_raises(Kubeclient::HttpError, OpenSSL::SSL::SSLError) do
      client2.get_entities('Node', 'nodes', {})
    end
    assert_raises(Kubeclient::HttpError, OpenSSL::SSL::SSLError) do
      exercise_watcher_with_timeout(client2.watch_entities('nodes'))
    end
  end

  def test_real_cluster_verify_none
    config = Kubeclient::Config.read(config_file('external.kubeconfig'))
    context = config.context
    # localhost and 127.0.0.1 are among names on the certificate
    client1 = Kubeclient::Client.new(
      'https://127.0.0.1:6443', 'v1',
      ssl_options: context.ssl_options.merge(verify_ssl: OpenSSL::SSL::VERIFY_NONE),
      auth_options: context.auth_options
    )
    client1.get_nodes
    # 127.0.0.2 also means localhost but is not included in the certificate.
    client2 = Kubeclient::Client.new(
      'https://127.0.0.2:6443', 'v1',
      ssl_options: context.ssl_options.merge(verify_ssl: OpenSSL::SSL::VERIFY_NONE),
      auth_options: context.auth_options
    )
    client2.get_nodes
  end

  private

  def exercise_watcher_with_timeout(watcher)
    thread = Thread.new do
      sleep(1)
      watcher.finish
    end
    watcher.each do |_notice|
      break
    end
    thread.join
  end
end
