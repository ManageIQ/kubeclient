# frozen_string_literal: true

require 'delegate'
module Kubeclient
  module Common
    # Kubernetes Entity List
    class EntityList < DelegateClass(Array)
      attr_reader :continue
      attr_reader :kind
      attr_reader :resourceVersion # rubocop:disable Naming/MethodName

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
