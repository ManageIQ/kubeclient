module Kubeclient
  module Common
    class Entity
      attr_reader :kind, :api_version, :api_name

      def initialize(kind, api_version, api_name)
        @kind = kind
        @api_version = api_version
        @api_name = api_name
      end

      def klass(owner)
        if owner.const_defined?(kind, false)
          owner.const_get(kind, false)
        else
          create_klass(owner)
        end
      end

      private

        def create_klass(owner)
          owner.const_set(
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
