module Kubeclient
  module Common
    class Entity
      attr_reader :klass_owner, :kind, :api_version, :api_name

      def initialize(klass_owner, kind, api_version, api_name)
        @klass_owner = klass_owner
        @kind = kind
        @api_version = api_version
        @api_name = api_name
      end

      def klass
        if klass_exists?
          get_klass
        else
          create_klass
        end
      end

      private

      def klass_exists?
        klass_owner.const_defined?(kind, false)
      end

      def get_klass
        klass_owner.const_get(kind, false)
      end

      def create_klass
        klass_owner.const_set(
          kind,
          Class.new(RecursiveOpenStruct) do
            def initialize(hash = nil, args = {})
              args[:recurse_over_arrays] = true
              super(hash, args)
            end
          end
        )
      end
    end
  end
end
