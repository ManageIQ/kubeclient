module Kubeclient
  module Common
    class Api
      attr_reader :api_version

      def initialize(namespace_module, server_rest_client, api_version)
        @namespace_module = namespace_module
        @server_rest_client = server_rest_client
        @api_version = api_version
      end

      def path
        @path ||=
          if api_version == 'v1'
            # core api
            "api/#{api_version}"
          else
            "apis/#{api_version}"
          end
      end

      def rest_client
        @rest_client ||= server_rest_client[path]
      end

      def entities
        @entities ||= JSON.parse(rest_client.get)['resources']
                      .reject { |resource| resource['name'].include?('/') }
                      .map { |resource| create_entity(resource) }
                      .compact
      end

      private

      attr_reader :namespace_module, :server_rest_client

      def create_entity(resource)
        resource['kind'] ||=
          Kubeclient::Common::MissingKindCompatibility.resource_kind(resource['name'])
        entity = ClientMixin.parse_definition(resource['kind'], resource['name'])
        return nil unless entity

        Kubeclient::Common::Entity.new(
          namespace_module,
          self,
          entity.entity_type,
          entity.resource_name,
          entity.method_names[0],
          entity.method_names[1]
        )
      end
    end
  end
end
