module Kubeclient
  # Exception that is raised when an http resource is not found
  class ResourceNotFoundError < HttpError
  end
end
