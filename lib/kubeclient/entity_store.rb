module Kubeclient
  module Common
    class EntityStore
      def initialize
        @by_api_version_and_kind = {}
      end

      def add(entity)
        key = [entity.api_version, entity.kind].join(',')

        @by_api_version_and_kind[key] = entity
      end

      def from_api_version_and_kind(api_version, kind)
        key = [api_version, kind].join(',')

        @by_api_version_and_kind[key]
      end

      def from_method
        nil
      end
    end
  end
end
