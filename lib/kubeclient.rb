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
    # Dynamically creating classes definitions (class Pod, class Service, etc.),
    # The classes are extending RecursiveOpenStruct.
    # This cancels the need to define the classes
    # manually on every new entity addition,
    # and especially since currently the class body is empty
    ENTITY_TYPES = %w(Pod Service ReplicationController Node Event Endpoint
                      Namespace Secret ResourceQuota LimitRange PersistentVolume
                      PersistentVolumeClaim ComponentStatus ServiceAccount).map do |et|
      clazz = Class.new(RecursiveOpenStruct) do
        def initialize(hash = nil, args = {})
          args.merge!(recurse_over_arrays: true)
          super(hash, args)
        end
      end
      [Kubeclient.const_set(et, clazz), et]
    end

    ClientMixin.define_entity_methods(ENTITY_TYPES)

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
