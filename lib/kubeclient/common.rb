require 'json'
require 'rest-client'
module Kubeclient
  # Common methods
  module ClientMixin
    attr_reader :api_endpoint
    attr_reader :ssl_options
    attr_reader :auth_options
    attr_reader :headers

    def initialize_client(
      uri,
      path,
      version = nil,
      ssl_options: {
        client_cert: nil,
        client_key: nil,
        ca_file: nil,
        verify_ssl: OpenSSL::SSL::VERIFY_PEER
      },
      auth_options: {
        username: nil,
        password: nil,
        bearer_token: nil,
        bearer_token_file: nil
      }
    )
      validate_auth_options(auth_options)
      handle_uri(uri, path)

      @api_version = version
      @headers = {}
      @ssl_options = ssl_options
      @auth_options = auth_options

      if auth_options[:bearer_token]
        @headers[:Authorization] = "Bearer #{@auth_options[:bearer_token]}"
      elsif auth_options[:bearer_token_file]
        validate_bearer_token_file
        @headers[:Authorization] = "Bearer #{File.read(@auth_options[:bearer_token_file])}"
      end
    end

    def handle_exception
      yield
    rescue RestClient::Exception => e
      begin
        json_error_msg = JSON.parse(e.response || '') || {}
      rescue JSON::ParserError
        json_error_msg = {}
      end
      err_message = json_error_msg['message'] || e.message
      raise KubeException.new(e.http_code, err_message, e.response)
    end

    def handle_uri(uri, path)
      fail ArgumentError, 'Missing uri' if uri.nil?
      @api_endpoint = (uri.is_a? URI) ? uri : URI.parse(uri)
      @api_endpoint.path = path if @api_endpoint.path.empty?
      @api_endpoint.path = @api_endpoint.path.chop \
                         if @api_endpoint.path.end_with? '/'
    end

    def build_namespace_prefix(namespace)
      namespace.to_s.empty? ? '' : "namespaces/#{namespace}/"
    end

    public

    def self.define_entity_methods(entity_types)
      entity_types.each do |klass, entity_type|
        entity_name = entity_type.underscore
        entity_name_plural = pluralize_entity(entity_name)

        # get all entities of a type e.g. get_nodes, get_pods, etc.
        define_method("get_#{entity_name_plural}") do |options = {}|
          get_entities(entity_type, klass, options)
        end

        # watch all entities of a type e.g. watch_nodes, watch_pods, etc.
        define_method("watch_#{entity_name_plural}") \
        do |resource_version = nil|
          watch_entities(entity_type, resource_version)
        end

        # get a single entity of a specific type by name
        define_method("get_#{entity_name}") do |name, namespace = nil|
          get_entity(entity_type, klass, name, namespace)
        end

        define_method("delete_#{entity_name}") do |name, namespace = nil|
          delete_entity(entity_type, name, namespace)
        end

        define_method("create_#{entity_name}") do |entity_config|
          create_entity(entity_type, entity_config, klass)
        end

        define_method("update_#{entity_name}") do |entity_config|
          update_entity(entity_type, entity_config)
        end
      end
    end

    def self.pluralize_entity(entity_name)
      return entity_name + 's' if entity_name.end_with? 'quota'
      entity_name.pluralize
    end

    def create_rest_client(path = nil)
      path ||= @api_endpoint.path
      options = {
        ssl_ca_file: @ssl_options[:ca_file],
        verify_ssl: @ssl_options[:verify_ssl],
        ssl_client_cert: @ssl_options[:client_cert],
        ssl_client_key: @ssl_options[:client_key],
        user: @auth_options[:username],
        password: @auth_options[:password]
      }
      RestClient::Resource.new(@api_endpoint.merge(path).to_s, options)
    end

    def rest_client
      @rest_client ||= begin
        create_rest_client("#{@api_endpoint.path}/#{@api_version}")
      end
    end

    def watch_entities(entity_type, resource_version = nil)
      resource = resource_name(entity_type.to_s)
      uri = @api_endpoint
            .merge("#{@api_endpoint.path}/#{@api_version}/watch/#{resource}")

      unless resource_version.nil?
        uri.query = URI.encode_www_form('resourceVersion' => resource_version)
      end

      Kubeclient::Common::WatchStream.new(uri, net_http_options(uri))
    end

    def get_entities(entity_type, klass, options = {})
      params = {}
      if options[:label_selector]
        params['params'] = { labelSelector: options[:label_selector] }
      end

      ns_prefix = build_namespace_prefix(options[:namespace])
      response = handle_exception do
        rest_client[ns_prefix + resource_name(entity_type)]
        .get(params.merge(@headers))
      end

      result = JSON.parse(response)

      resource_version = result.fetch('resourceVersion', nil)
      if resource_version.nil?
        resource_version =
            result.fetch('metadata', {}).fetch('resourceVersion', nil)
      end

      # result['items'] might be nil due to https://github.com/kubernetes/kubernetes/issues/13096
      collection = result['items'].to_a.map { |item| new_entity(item, klass) }

      Kubeclient::Common::EntityList.new(entity_type, resource_version, collection)
    end

    def get_entity(entity_type, klass, name, namespace = nil)
      ns_prefix = build_namespace_prefix(namespace)
      response = handle_exception do
        rest_client[ns_prefix + resource_name(entity_type) + "/#{name}"]
        .get(@headers)
      end
      result = JSON.parse(response)
      new_entity(result, klass)
    end

    def delete_entity(entity_type, name, namespace = nil)
      ns_prefix = build_namespace_prefix(namespace)
      handle_exception do
        rest_client[ns_prefix + resource_name(entity_type) + "/#{name}"]
          .delete(@headers)
      end
    end

    def create_entity(entity_type, entity_config, klass)
      # to_hash should be called because of issue #9 in recursive open
      # struct
      hash = entity_config.to_hash

      ns_prefix = build_namespace_prefix(entity_config.metadata['table'][:namespace])

      # TODO: temporary solution to add "kind" and apiVersion to request
      # until this issue is solved
      # https://github.com/GoogleCloudPlatform/kubernetes/issues/6439
      hash['kind'] = entity_type
      hash['apiVersion'] = @api_version
      response = handle_exception do
        rest_client[ns_prefix + resource_name(entity_type)]
        .post(hash.to_json, @headers)
      end
      result = JSON.parse(response)
      new_entity(result, klass)
    end

    def update_entity(entity_type, entity_config)
      name = entity_config.metadata.name
      # to_hash should be called because of issue #9 in recursive open
      # struct
      hash = entity_config.to_hash
      ns_prefix = build_namespace_prefix(entity_config.metadata['table'][:namespace])
      handle_exception do
        rest_client[ns_prefix + resource_name(entity_type) + "/#{name}"]
          .put(hash.to_json, @headers)
      end
    end

    def new_entity(hash, klass)
      klass.new(hash)
    end

    def retrieve_all_entities(entity_types)
      entity_types.each_with_object({}) do |(_, entity_type), result_hash|
        # method call for get each entities
        # build hash of entity name to array of the entities
        entity_name = ClientMixin.pluralize_entity entity_type.underscore
        method_name = "get_#{entity_name}"
        key_name = entity_type.underscore
        result_hash[key_name] = send(method_name)
      end
    end

    def proxy_url(kind, name, port, namespace = '')
      entity_name_plural = ClientMixin.pluralize_entity(kind.to_s)
      ns_prefix = build_namespace_prefix(namespace)
      # TODO: Change this once services supports the new scheme
      if entity_name_plural == 'pods'
        rest_client["#{ns_prefix}#{entity_name_plural}/#{name}:#{port}/proxy"].url
      else
        rest_client["proxy/#{ns_prefix}#{entity_name_plural}/#{name}:#{port}"].url
      end
    end

    def resource_name(entity_type)
      ClientMixin.pluralize_entity entity_type.downcase
    end

    def api_valid?
      result = api
      result.is_a?(Hash) && (result['versions'] || []).include?(@api_version)
    end

    def api
      response = handle_exception do
        create_rest_client.get(@headers)
      end
      JSON.parse(response)
    end

    private

    def bearer_token(bearer_token)
      @headers ||= {}
      @headers[:Authorization] = "Bearer #{bearer_token}"
    end

    def validate_auth_options(opts)
      # maintain backward compatibility:
      opts[:username] = opts[:user] if opts[:user]

      if [:bearer_token, :bearer_token_file, :username].count { |key| opts[key] } > 1
        fail(ArgumentError, 'Invalid auth options: specify only one of username/password,' \
             ' bearer_token or bearer_token_file')
      elsif [:username, :password].count { |key| opts[key] } == 1
        fail(ArgumentError, 'Basic auth requires both username & password')
      end
    end

    def validate_bearer_token_file
      msg = "Token file #{@auth_options[:bearer_token_file]} does not exist"
      fail ArgumentError, msg unless File.file?(@auth_options[:bearer_token_file])

      msg = "Cannot read token file #{@auth_options[:bearer_token_file]}"
      fail ArgumentError, msg unless File.readable?(@auth_options[:bearer_token_file])
    end

    def net_http_options(uri)
      options = {
        basic_auth_user: @auth_options[:username],
        basic_auth_password: @auth_options[:password],
        headers: @headers
      }

      if uri.scheme == 'https'
        options.merge!(
          use_ssl: true,
          ca_file: @ssl_options[:ca_file],
          cert: @ssl_options[:client_cert],
          key: @ssl_options[:client_key],
          # ruby Net::HTTP uses verify_mode instead of verify_ssl
          # http://ruby-doc.org/stdlib-1.9.3/libdoc/net/http/rdoc/Net/HTTP.html
          verify_mode: @ssl_options[:verify_ssl]
        )
      end

      options
    end
  end
end
