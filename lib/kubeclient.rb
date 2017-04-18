require 'kubeclient/version'
require 'json'
require 'rest-client'
require 'kubeclient/entity_list'
require 'kubeclient/http_error'
require 'kubeclient/watch_notice'
require 'kubeclient/watch_stream'
require 'kubeclient/common'
require 'kubeclient/config'
require 'kubeclient/missing_kind_compatibility'

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
