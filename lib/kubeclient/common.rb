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
          err_message = JSON.parse(e.response)['message']
        rescue JSON::ParserError
          err_message = e.message
        end
        raise KubeException.new(e.http_code, err_message)
      end

      def handle_uri(uri, path)
        @api_endpoint = (uri.is_a? URI) ? uri : URI.parse(uri)
        @api_endpoint.path = path if @api_endpoint.path.empty?
        @api_endpoint.path = @api_endpoint.path.chop \
                           if @api_endpoint.path.end_with? '/'
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
          define_method("get_#{entity_name}") do |name|
            get_entity(entity_type, klass, name)
          end

          define_method("delete_#{entity_name}") do |name|
            delete_entity(entity_type, name)
          end

          define_method("create_#{entity_name}") do |entity_config|
            create_entity(entity_type, entity_config)
          end

          define_method("update_#{entity_name}") do |entity_config|
            update_entity(entity_type, entity_config)
          end
        end
      end

      def rest_client
        @rest_client ||= begin
          options = {
            ssl_ca_file: @ssl_options[:ca_file],
            verify_ssl: @ssl_options[:verify_ssl],
            ssl_client_cert: @ssl_options[:client_cert],
            ssl_client_key: @ssl_options[:client_key]
          }
          endpoint_with_ver = @api_endpoint
                              .merge("#{@api_endpoint.path}/#{@api_version}")
          RestClient::Resource.new(endpoint_with_ver, options)
        end
      end

      def watch_entities(entity_type, resource_version = nil)
        resource = get_resource_name(entity_type.to_s)

        uri = @api_endpoint
              .merge("#{@api_endpoint.path}/#{@api_version}/watch/#{resource}")

        unless resource_version.nil?
          uri.query = URI.encode_www_form('resourceVersion' => resource_version)
        end

        options = {
          use_ssl: uri.scheme == 'https',
          ca_file: @ssl_options[:ca_file],
          verify_ssl: @ssl_options[:verify_ssl],
          client_cert: @ssl_options[:client_cert],
          client_key: @ssl_options[:client_key]
        }

        WatchStream.new(uri, options)
      end

      def get_entities(entity_type, klass, options)
        params = {}
        if options[:label_selector]
          params['label-selector'] = options[:label_selector]
        end

        # TODO: namespace support?
        response = handle_exception do
          rest_client[get_resource_name(entity_type)].get(params: params)
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

      def get_entity(entity_type, klass, name)
        response = handle_exception do
          rest_client[get_resource_name(entity_type) + "/#{name}"].get
        end
        result = JSON.parse(response)
        new_entity(result, klass)
      end

      def delete_entity(entity_type, name)
        handle_exception do
          rest_client[get_resource_name(entity_type) + "/#{name}"].delete
        end
      end

      def create_entity(entity_type, entity_config)
        # to_hash should be called because of issue #9 in recursive open
        # struct
        hash = entity_config.to_hash
        # TODO: temporary solution to add "kind" and apiVersion to request
        # until this issue is solved
        # https://github.com/GoogleCloudPlatform/kubernetes/issues/6439
        hash['kind'] = entity_type
        hash['apiVersion'] = @api_version
        handle_exception do
          rest_client[get_resource_name(entity_type)].post(hash.to_json)
        end
      end

      def update_entity(entity_type, entity_config)
        name = entity_config.name
        # to_hash should be called because of issue #9 in recursive open
        # struct
        hash = entity_config.to_hash
        # TODO: temporary solution to delete id till this issue is solved
        # https://github.com/GoogleCloudPlatform/kubernetes/issues/3085
        hash.delete(:id)
        handle_exception do
          rest_client[get_resource_name(entity_type) + "/#{name}"]
            .put(hash.to_json)
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

      def get_resource_name(entity_type)
        if @api_version == 'v1beta1'
          entity_type.pluralize.camelize(:lower)
        else
          entity_type.pluralize.downcase
        end
      end

      def ssl_options(client_cert: nil, client_key: nil, ca_file: nil,
                      verify_ssl: OpenSSL::SSL::VERIFY_PEER)
        @ssl_options = {
          ca_file: ca_file,
          verify_ssl: verify_ssl,
          client_cert: client_cert,
          client_key: client_key
        }
      end
    end
  end
end
