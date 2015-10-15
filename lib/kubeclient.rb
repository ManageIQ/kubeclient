require 'kubeclient/version'
require 'json'
require 'rest-client'
require 'active_support/inflector'
require 'kubeclient/entity_list'
require 'kubeclient/kube_exception'
require 'kubeclient/watch_notice'
require 'kubeclient/watch_stream'
require 'kubeclient/common'

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
                      PersistentVolumeClaim ComponentStatus).map do |et|
      clazz = Class.new(RecursiveOpenStruct) do
        def initialize(hash = nil, args = {})
          args.merge!(recurse_over_arrays: true)
          super(hash, args)
        end
      end
      [Kubeclient.const_set(et, clazz), et]
    end

    ClientMixin.define_entity_methods(ENTITY_TYPES)

    def initialize(uri,
                   version = 'v1',
                   ssl_options: {
                     client_cert: nil,
                     client_key: nil,
                     ca_file: nil,
                     verify_ssl: OpenSSL::SSL::VERIFY_PEER
                   },
                   auth_options: {
                     username:          nil,
                     password:          nil,
                     bearer_token:      nil,
                     bearer_token_file: nil
                   }
                  )
      initialize_client(uri, '/api', version, ssl_options: ssl_options, auth_options: auth_options)
    end

    def all_entities
      retrieve_all_entities(ENTITY_TYPES)
    end
  end
end
