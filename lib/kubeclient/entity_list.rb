require 'delegate'

# Kubernetes Entity List
module Kubeclient
  class EntityList < DelegateClass(Array)
    attr_reader :kind, :resourceVersion

    def initialize(kind, resource_version, list)
      @kind = kind
      # rubocop:disable Style/VariableName
      @resourceVersion = resource_version
      super(list)
    end
  end
end
