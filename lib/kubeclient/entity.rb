require 'weakref'

module Kubeclient
  module Common
    class Entity
      attr_reader :namespace_module, :api, :kind, :api_name, :singular_method, :plural_method

      def initialize(namespace_module, api, kind, api_name, singular_method, plural_method)
        @namespace_module = namespace_module
        @kind = kind
        @api = WeakRef.new(api)
        @api_name = api_name
        @singular_method = singular_method
        @plural_method = plural_method
      end

      def rest_client(namespace = nil)
        ns_prefix =
          if namespace.to_s.empty?
            ''
          else
            "namespaces/#{namespace}/"
          end

        api.rest_client[ns_prefix + api_name]
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
        namespace_module.const_defined?(kind, false)
      end

      def get_klass
        namespace_module.const_get(kind, false)
      end

      def create_klass
        namespace_module.const_set(
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
