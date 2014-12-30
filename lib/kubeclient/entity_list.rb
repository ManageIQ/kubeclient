class EntityList < Array
  attr_reader :kind, :resource_version

  def initialize(kind,resource_version)
    @kind = kind
    @resource_version = resource_version
    super()
  end

end