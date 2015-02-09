# Kubernetes Entity List
class EntityList < Array
  attr_reader :kind, :resourceVersion

  def initialize(kind, resource_version)
    @kind = kind
    # rubocop:disable Style/VariableName
    @resourceVersion = resource_version
    super()
  end
end
