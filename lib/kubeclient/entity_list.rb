require 'delegate'
module Kubeclient
  module Common
    # Kubernetes Entity List
    class EntityList < DelegateClass(Array)
      attr_reader :continue, :kind, :resourceVersion

      def initialize(kind, resource_version, list, continue = nil)
        @kind = kind
        @resourceVersion = resource_version # rubocop:disable Naming/VariableName
        @continue = continue
        super(list)
      end

      def last?
        continue.nil?
      end
    end
  end
end
