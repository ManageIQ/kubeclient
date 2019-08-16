require 'yaml'
require 'base64'
require 'pathname'

module Kubeclient
  # Kubernetes client configuration class
  class Config
    # Kubernetes client configuration context class
    class Context
      attr_reader :api_endpoint, :api_version, :ssl_options, :auth_options, :namespace

      def initialize(api_endpoint, api_version, ssl_options, auth_options, namespace)
        @api_endpoint = api_endpoint
        @api_version = api_version
        @ssl_options = ssl_options
        @auth_options = auth_options
        @namespace = namespace
      end
    end

    # data (Hash) - Parsed kubeconfig data.
    # kcfg_path (string) - Base directory for resolving relative references to external files.
    #   If set to nil, all external lookups & commands are disabled (even for absolute paths).
    # See also the more convenient Config.read
    def initialize(data, kcfg_path)
      @kcfg = data
      @kcfg_path = kcfg_path
      raise 'Unknown kubeconfig version' if @kcfg['apiVersion'] != 'v1'
    end

    # Builds Config instance by parsing given file, with lookups relative to file's directory.
    def self.read(filename)
      parsed = YAML.safe_load(File.read(filename), [Date, Time])
      Config.new(parsed, File.dirname(filename))
    end

    def contexts
      @kcfg['contexts'].map { |x| x['name'] }
    end

    def context(context_name = nil)
      cluster, user, namespace = fetch_context(context_name || @kcfg['current-context'])

      ca_cert_data     = fetch_cluster_ca_data(cluster)
      client_cert_data = fetch_user_cert_data(user)
      client_key_data  = fetch_user_key_data(user)
      auth_options     = fetch_user_auth_options(user)

      ssl_options = {}

      if !ca_cert_data.nil?
        cert_store = OpenSSL::X509::Store.new
        cert_store.add_cert(OpenSSL::X509::Certificate.new(ca_cert_data))
        ssl_options[:verify_ssl] = OpenSSL::SSL::VERIFY_PEER
        ssl_options[:cert_store] = cert_store
      else
        ssl_options[:verify_ssl] = OpenSSL::SSL::VERIFY_NONE
      end

      unless client_cert_data.nil?
        ssl_options[:client_cert] = OpenSSL::X509::Certificate.new(client_cert_data)
      end

      unless client_key_data.nil?
        ssl_options[:client_key] = OpenSSL::PKey.read(client_key_data)
      end

      Context.new(cluster['server'], @kcfg['apiVersion'], ssl_options, auth_options, namespace)
    end

    private

    def allow_external_lookups?
      @kcfg_path != nil
    end

    def ext_file_path(path)
      unless allow_external_lookups?
        raise "Kubeclient::Config: external lookups disabled, can't load '#{path}'"
      end
      Pathname(path).absolute? ? path : File.join(@kcfg_path, path)
    end

    def ext_command_path(path)
      unless allow_external_lookups?
        raise "Kubeclient::Config: external lookups disabled, can't execute '#{path}'"
      end
      # Like go client https://github.com/kubernetes/kubernetes/pull/59495#discussion_r171138995,
      # distinguish 3 cases:
      # - absolute (e.g. /path/to/foo)
      # - $PATH-based (e.g. curl)
      # - relative to config file's dir (e.g. ./foo)
      if Pathname(path).absolute?
        path
      elsif File.basename(path) == path
        path
      else
        File.join(@kcfg_path, path)
      end
    end

    def fetch_context(context_name)
      context = @kcfg['contexts'].detect do |x|
        break x['context'] if x['name'] == context_name
      end

      raise KeyError, "Unknown context #{context_name}" unless context

      cluster = @kcfg['clusters'].detect do |x|
        break x['cluster'] if x['name'] == context['cluster']
      end

      raise KeyError, "Unknown cluster #{context['cluster']}" unless cluster

      user = @kcfg['users'].detect do |x|
        break x['user'] if x['name'] == context['user']
      end || {}

      namespace = context['namespace']

      [cluster, user, namespace]
    end

    def fetch_cluster_ca_data(cluster)
      if cluster.key?('certificate-authority')
        File.read(ext_file_path(cluster['certificate-authority']))
      elsif cluster.key?('certificate-authority-data')
        Base64.decode64(cluster['certificate-authority-data'])
      end
    end

    def fetch_user_cert_data(user)
      if user.key?('client-certificate')
        File.read(ext_file_path(user['client-certificate']))
      elsif user.key?('client-certificate-data')
        Base64.decode64(user['client-certificate-data'])
      end
    end

    def fetch_user_key_data(user)
      if user.key?('client-key')
        File.read(ext_file_path(user['client-key']))
      elsif user.key?('client-key-data')
        Base64.decode64(user['client-key-data'])
      end
    end

    def fetch_user_auth_options(user)
      options = {}
      if user.key?('token')
        options[:bearer_token] = user['token']
      elsif user.key?('exec')
        exec_opts = expand_command_option(user['exec'], 'command')
        options[:bearer_token] = Kubeclient::ExecCredentials.token(exec_opts)
      elsif user.key?('auth-provider')
        options[:bearer_token] = fetch_token_from_provider(user['auth-provider'])
      else
        %w[username password].each do |attr|
          options[attr.to_sym] = user[attr] if user.key?(attr)
        end
      end
      options
    end

    def fetch_token_from_provider(auth_provider)
      case auth_provider['name']
      when 'gcp'
        config = expand_command_option(auth_provider['config'], 'cmd-path')
        Kubeclient::GCPAuthProvider.token(config)
      when 'oidc'
        Kubeclient::OIDCAuthProvider.token(auth_provider['config'])
      end
    end

    def expand_command_option(config, key)
      config = config.dup
      config[key] = ext_command_path(config[key]) if config[key]

      config
    end
  end
end
