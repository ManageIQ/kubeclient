require 'json'
require 'rest-client'
module Kubeclient
  # Common methods
  # this is mixed in by other gems
  module ClientMixin
    DEFAULT_SSL_OPTIONS = {
      client_cert: nil,
      client_key:  nil,
      ca_file:     nil,
      cert_store:  nil,
      verify_ssl:  OpenSSL::SSL::VERIFY_PEER
    }.freeze

    DEFAULT_AUTH_OPTIONS = {
      username:          nil,
      password:          nil,
      bearer_token:      nil,
      bearer_token_file: nil
    }.freeze

    DEFAULT_SOCKET_OPTIONS = {
      socket_class:     nil,
      ssl_socket_class: nil
    }.freeze

    DEFAULT_HTTP_PROXY_URI = nil

    attr_reader :api_endpoint
    attr_reader :ssl_options
    attr_reader :auth_options
    attr_reader :http_proxy_uri
    attr_reader :headers

    def initialize_client(
      uri,
      path,
      version,
      ssl_options: DEFAULT_SSL_OPTIONS,
      auth_options: DEFAULT_AUTH_OPTIONS,
      socket_options: DEFAULT_SOCKET_OPTIONS,
      http_proxy_uri: DEFAULT_HTTP_PROXY_URI
    )
      validate_auth_options(auth_options)
      handle_uri(uri, path)

      @api_version = version
      @headers = {}
      @ssl_options = ssl_options
      @auth_options = auth_options
      @socket_options = socket_options
      @http_proxy_uri = http_proxy_uri.to_s if http_proxy_uri

      if auth_options[:bearer_token]
        bearer_token(@auth_options[:bearer_token])
      elsif auth_options[:bearer_token_file]
        validate_bearer_token_file
        bearer_token(File.read(@auth_options[:bearer_token_file]))
      end
    end

    def handle_exception
      yield
    rescue RestClient::Exception => e
      json_error_msg = begin
        JSON.parse(e.response || '') || {}
      rescue JSON::ParserError
        {}
      end
      err_message = json_error_msg['message'] || e.message
      raise NameError.new if json_error_msg && json_error_msg['reason'] == 'NotFound'
      raise KubeException.new(e.http_code, err_message, e.response)
    end

    def handle_uri(uri, path)
      fail ArgumentError, 'Missing uri' unless uri
      @api_endpoint = (uri.is_a?(URI) ? uri : URI.parse(uri))
      @api_endpoint.path = path if @api_endpoint.path.empty?
      @api_endpoint.path = @api_endpoint.path.chop if @api_endpoint.path.end_with? '/'
    end

    def build_namespace_prefix(namespace)
      namespace.to_s.empty? ? '' : "namespaces/#{namespace}/"
    end

    def method_missing(method_sym, *args, &block)
      resource_method = resource_method?(method_sym)
      super unless resource_method
      rest_method, singular, collection = resource_method
      method_name = [rest_method, collection ? 'entities' : 'entity'].join('_')
      if collection
        options = args[0] || {}
        # This watch_entity method used to take resource_version as a param, so
        # this conversion is to keep backwards compatibility
        options = { resource_version: options } unless options.is_a?(Hash)
        args = [singular, options]
      else
        args = [singular] + args
      end
      send(method_name.to_sym, *args)
    end

    def respond_to?(method_sym)
      resource_method?(method_sym) ? true : super
    end

    def resource_method?(method_sym)
      # return [rest_method, entity_type, collection] (e.g [get, Pod, false])
      # if this method is legal else return false
      m  = method_sym.to_s.match(/^(get|watch|delete|create|update|patch)_(.*)$/)
      ret = false
      if m && (%w(get watch).include?(m[1]) || m[2].singularize == m[2])
        ret = [m[1], m[2].camelize.singularize, m[2].singularize != m[2]]
      end
      ret
    end

    public

    def pluralize_entity(entity_name)
      return entity_name + 's' if entity_name.end_with? 'quota'
      entity_name.pluralize
    end

    def create_rest_client(path = nil)
      path ||= @api_endpoint.path
      options = {
        ssl_ca_file: @ssl_options[:ca_file],
        ssl_cert_store: @ssl_options[:cert_store],
        verify_ssl: @ssl_options[:verify_ssl],
        ssl_client_cert: @ssl_options[:client_cert],
        ssl_client_key: @ssl_options[:client_key],
        proxy: @http_proxy_uri,
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

    # Accepts the following string options:
    #   :namespace - the namespace of the entity.
    #   :name - the name of the entity to watch.
    #   :label_selector - a selector to restrict the list of returned objects by their labels.
    #   :field_selector - a selector to restrict the list of returned objects by their fields.
    #   :resource_version - shows changes that occur after that particular version of a resource.
    def watch_entities(entity_type, options = {})
      ns = build_namespace_prefix(options[:namespace])

      path = "watch/#{ns}#{resource_name(entity_type.to_s)}"
      path += "/#{options[:name]}" if options[:name]
      uri = @api_endpoint.merge("#{@api_endpoint.path}/#{@api_version}/#{path}")

      params = options.slice(:label_selector, :field_selector, :resource_version)
      if params.any?
        uri.query = URI.encode_www_form(params.map { |k, v| [k.to_s.camelize(:lower), v] })
      end

      Kubeclient::Common::WatchStream.new(uri, http_options(uri))
    end

    # Accepts the following string options:
    #   :namespace - the namespace of the entity.
    #   :label_selector - a selector to restrict the list of returned objects by their labels.
    #   :field_selector - a selector to restrict the list of returned objects by their fields.
    def get_entities(entity_type, options = {})
      params = {}
      [:label_selector, :field_selector].each do |p|
        params[p.to_s.camelize(:lower)] = options[p] if options[p]
      end

      ns_prefix = build_namespace_prefix(options[:namespace])
      response = handle_exception do
        rest_client[ns_prefix + resource_name(entity_type)]
        .get({ 'params' => params }.merge(@headers))
      end

      result = JSON.parse(response)

      resource_version = result.fetch('resourceVersion', nil)
      if resource_version.nil?
        resource_version =
            result.fetch('metadata', {}).fetch('resourceVersion', nil)
      end

      # result['items'] might be nil due to https://github.com/kubernetes/kubernetes/issues/13096
      collection = result['items'].to_a.map { |item| new_entity(item, entity_type) }

      Kubeclient::Common::EntityList.new(entity_type, resource_version, collection)
    end

    def get_entity(entity_type, name, namespace = nil)
      ns_prefix = build_namespace_prefix(namespace)
      response = handle_exception do
        rest_client[ns_prefix + resource_name(entity_type) + "/#{name}"]
        .get(@headers)
      end
      result = JSON.parse(response)
      new_entity(result, entity_type)
    end

    def delete_entity(entity_type, name, namespace = nil)
      ns_prefix = build_namespace_prefix(namespace)
      handle_exception do
        rest_client[ns_prefix + resource_name(entity_type) + "/#{name}"]
          .delete(@headers)
      end
    end

    def create_entity(entity_type, entity_config)
      # Duplicate the entity_config to a hash so that when we assign
      # kind and apiVersion, this does not mutate original entity_config obj.
      hash = entity_config.to_hash

      ns_prefix = build_namespace_prefix(hash[:metadata][:namespace])

      # TODO: temporary solution to add "kind" and apiVersion to request
      # until this issue is solved
      # https://github.com/GoogleCloudPlatform/kubernetes/issues/6439
      # TODO: #2 solution for
      # https://github.com/kubernetes/kubernetes/issues/8115
      if entity_type.eql? 'Endpoint'
        hash[:kind] = resource_name(entity_type).capitalize
      else
        hash[:kind] = entity_type
      end
      hash[:apiVersion] = @api_version
      @headers['Content-Type'] = 'application/json'
      response = handle_exception do
        rest_client[ns_prefix + resource_name(entity_type)]
        .post(hash.to_json, @headers)
      end
      result = JSON.parse(response)
      new_entity(result, entity_type)
    end

    def update_entity(entity_type, entity_config)
      name      = entity_config[:metadata][:name]
      ns_prefix = build_namespace_prefix(entity_config[:metadata][:namespace])
      @headers['Content-Type'] = 'application/json'
      handle_exception do
        rest_client[ns_prefix + resource_name(entity_type) + "/#{name}"]
          .put(entity_config.to_h.to_json, @headers)
      end
    end

    def patch_entity(entity_type, name, patch, namespace = nil)
      ns_prefix = build_namespace_prefix(namespace)
      @headers['Content-Type'] = 'application/strategic-merge-patch+json'
      handle_exception do
        rest_client[ns_prefix + resource_name(entity_type) + "/#{name}"]
          .patch(patch.to_json, @headers)
      end
    end

    def new_entity(hash, entity_type)
      resource_class(entity_type).new(hash)
    end

    def resource_class(entity_type)
      # TODO: test binding since there already seems to be a constant with that name
      Kubeclient.const_get(entity_type)
      rescue NameError
        Kubeclient.const_set(
          entity_type,
          Class.new(RecursiveOpenStruct) do
            def initialize(hash = nil, args = {})
              args.merge!(recurse_over_arrays: true)
              super(hash, args)
            end
          end
        )
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

    def get_pod_log(pod_name, namespace, container: nil, previous: false)
      params = {}
      params[:previous] = true if previous
      params[:container] = container if container

      ns = build_namespace_prefix(namespace)
      handle_exception do
        rest_client[ns + "pods/#{pod_name}/log"]
          .get({ 'params' => params }.merge(@headers))
      end
    end

    def watch_pod_log(pod_name, namespace, container: nil)
      # Adding the "follow=true" query param tells the Kubernetes API to keep
      # the connection open and stream updates to the log.
      params = { follow: true }
      params[:container] = container if container

      ns = build_namespace_prefix(namespace)

      uri = @api_endpoint.dup
      uri.path += "/#{@api_version}/#{ns}pods/#{pod_name}/log"
      uri.query = URI.encode_www_form(params)

      Kubeclient::Common::WatchStream.new(uri, http_options(uri), format: :text)
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
      pluralize_entity entity_type.downcase
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

    def http_options(uri)
      options = {
        basic_auth_user: @auth_options[:username],
        basic_auth_password: @auth_options[:password],
        headers: @headers,
        http_proxy_uri: @http_proxy_uri
      }

      if uri.scheme == 'https'
        options[:ssl] = {
          ca_file: @ssl_options[:ca_file],
          cert: @ssl_options[:client_cert],
          cert_store: @ssl_options[:cert_store],
          key: @ssl_options[:client_key],
          # ruby HTTP uses verify_mode instead of verify_ssl
          # http://ruby-doc.org/stdlib-1.9.3/libdoc/openssl/rdoc/OpenSSL/SSL/SSLContext.html
          verify_mode: @ssl_options[:verify_ssl]
        }
      end

      options.merge(@socket_options)
    end
  end
end
