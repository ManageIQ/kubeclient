module Kubeclient
  module Common
    class Apis
      include Kubeclient::ErrorHandling

      def initialize(namespace_module, server_rest_client, api_versions_filter = nil)
        @namespace_module = namespace_module
        @server_rest_client = server_rest_client
        @api_versions_filter = [api_versions_filter].flatten.compact
      end

      def apis
        @apis ||= api_versions
                  .map { |api_version| [api_version, create_api(api_version)] }
                  .to_h
      end

      def purge
        @apis = nil
      end

      private

      attr_reader :namespace_module, :server_rest_client, :api_versions_filter

      def create_api(api_version)
        Kubeclient::Common::Api.new(
          namespace_module,
          server_rest_client,
          api_version
        )
      end

      def api_versions
        ([core_api_version] + discoverable_api_versions).
          select { |v| api_versions_filter.empty? || api_versions_filter.include?(v) }
      end

      def core_api_version
        'v1'
      end

      def discoverable_api_versions
        JSON.parse(server_rest_client['apis'].get)
          .fetch('groups', [])
          .map { |group| group.fetch('versions', []).first['groupVersion'] }
      end
    end
  end
end
