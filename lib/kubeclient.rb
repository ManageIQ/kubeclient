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
  class Client < Common::Client
    attr_reader :api_endpoint

    # Dynamically creating classes definitions (class Pod, class Service, etc.),
    # The classes are extending RecursiveOpenStruct.
    # This cancels the need to define the classes
    # manually on every new entity addition,
    # and especially since currently the class body is empty
    ENTITY_TYPES = %w(Pod Service ReplicationController Node Event Endpoint
                      Namespace).map do |et|
      clazz = Class.new(RecursiveOpenStruct) do
        def initialize(hash = nil, args = {})
          args.merge!(recurse_over_arrays: true)
          super(hash, args)
        end
      end
      [Kubeclient.const_set(et, clazz), et]
    end

    def initialize(uri, version = 'v1beta3')
      handle_uri(uri, '/api')
      @api_version = version
      ssl_options
    end

    def all_entities
      retrieve_all_entities(ENTITY_TYPES)
    end

    def api
      response = handle_exception do
        RestClient::Resource.new(@api_endpoint.to_s).get
      end
      JSON.parse(response)
    end

    def api_valid?
      result = api
      result.is_a?(Hash) && result['versions'].is_a?(Array)
    end

    define_entity_methods(ENTITY_TYPES)
  end
end
