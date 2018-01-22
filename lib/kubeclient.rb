require 'json'
require 'rest-client'

require 'kubeclient/common'
require 'kubeclient/config'
require 'kubeclient/entity_list'
require 'kubeclient/http_error'
require 'kubeclient/missing_kind_compatibility'
require 'kubeclient/resource_not_found_error'
require 'kubeclient/version'
require 'kubeclient/watch_notice'
require 'kubeclient/watch_stream'

module Kubeclient
  # Kubernetes Client
  class Client
    include ClientMixin
    # define a multipurpose resource class, available before discovery
    ClientMixin.resource_class(Kubeclient, 'Resource')
    def initialize(
      uri,
      version = 'v1',
      **options
    )
      initialize_client(
        Kubeclient,
        uri,
        '/api',
        version,
        options
      )
    end
  end
end
