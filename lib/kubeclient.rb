require 'kubeclient/version'
require 'json'
require 'rest-client'
require 'active_support/inflector'
require 'kubeclient/entity_list'
require 'kubeclient/kube_exception'
require 'kubeclient/watch_notice'
require 'kubeclient/watch_stream'
require 'kubeclient/common'
require 'kubeclient/config'

module Kubeclient
  # Kubernetes Client
  class Client
    include ClientMixin

    def initialize(
      uri,
      version = 'v1',
      **options
    )
      initialize_client(
        uri,
        '/api',
        version,
        options
      )
    end

    def all_entities
      retrieve_all_entities(ENTITY_TYPES)
    end
  end
end
