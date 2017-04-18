module Kubeclient
  module Common
    class EntityIndex
      def initialize(apis)
        @apis = apis
        @by_api_version_and_kind = {}
        @by_klass = {}
        @indexed = false
      end

      def from_api_version_and_kind(api_version, kind)
        index!

        key = [api_version, kind].join(',')
        @by_api_version_and_kind[key]
      end

      def from_klass(klass)
        index!
        @by_klass[klass]
      end

      private

      def index!
        return if @indexed

        @apis.apis.values.each do |api|
          api.entities.each do |entity|
            key = [api.api_version, entity.kind].join(',')
            @by_api_version_and_kind[key] = entity
            @by_klass[entity.klass] = entity
          end
        end

        @indexed = true
      end
    end
  end
end
