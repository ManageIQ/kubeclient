class EntityList < Array
  attr_reader :kind, :resourceVersion

  def initialize(kind,resource_version)
    @kind = kind
    @resourceVersion = resource_version
    super()
  end

end