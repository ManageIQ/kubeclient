require 'json'
require 'rest-client'
module Kubeclient
  module Common
    # Common methods
    class Client
      def handle_exception
        yield
      rescue RestClient::Exception => e
        begin
          json_error_msg = JSON.parse(e.response || '') || {}
        rescue JSON::ParserError
          json_error_msg = {}
        end
        err_message = json_error_msg['message'] || e.message
        raise KubeException.new(e.http_code, err_message)
      end

      def handle_uri(uri, path)
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
          entity_name_plural = entity_name.pluralize

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

      def create_rest_client(path = nil)
        path ||= @api_endpoint.path
        options = {
          ssl_ca_file: @ssl_options[:ca_file],
          verify_ssl: @ssl_options[:verify_ssl],
          ssl_client_cert: @ssl_options[:client_cert],
          ssl_client_key: @ssl_options[:client_key],
          user: @basic_auth_user,
          password: @basic_auth_password
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

        options = {
          use_ssl: uri.scheme == 'https',
          ca_file: @ssl_options[:ca_file],
          # ruby Net::HTTP uses verify_mode instead of verify_ssl
          # http://ruby-doc.org/stdlib-1.9.3/libdoc/net/http/rdoc/Net/HTTP.html
          verify_mode: @ssl_options[:verify_ssl],
          cert: @ssl_options[:client_cert],
          key: @ssl_options[:client_key],
          basic_auth_user: @basic_auth_user,
          basic_auth_password: @basic_auth_password,
          headers: @headers
        }

        WatchStream.new(uri, options)
      end

      def get_entities(entity_type, klass, options)
        params = {}
        if options[:label_selector]
          params['params'] = { labelSelector: options[:label_selector] }
        end

        # TODO: namespace support?
        response = handle_exception do
          rest_client[resource_name(entity_type)]
          .get(params.merge(@headers))
        end

        result = JSON.parse(response)

        resource_version = result.fetch('resourceVersion', nil)
        if resource_version.nil?
          resource_version =
              result.fetch('metadata', {}).fetch('resourceVersion', nil)
        end

        collection = result['items'].map { |item| new_entity(item, klass) }

        EntityList.new(entity_type, resource_version, collection)
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

        ns_prefix = build_namespace_prefix(entity_config.metadata.namespace)

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
        name = entity_config.name
        # to_hash should be called because of issue #9 in recursive open
        # struct
        hash = entity_config.to_hash
        ns_prefix = build_namespace_prefix(entity_config.metadata.namespace)
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
          method_name = "get_#{entity_type.underscore.pluralize}"
          key_name = entity_type.underscore
          result_hash[key_name] = send(method_name)
        end
      end

      def resource_name(entity_type)
        entity_type.pluralize.downcase
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
    end
  end
end
