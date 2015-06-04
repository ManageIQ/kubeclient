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

    def initialize(uri,
                   version = 'v1beta3',
                   ssl_options: {
                     client_cert: nil,
                     client_key: nil,
                     ca_file: nil,
                     verify_ssl: OpenSSL::SSL::VERIFY_PEER
                   },
                   auth_options: {
                     user: nil,
                     password: nil,
                     bearer_token: nil
                   })

      fail ArgumentError, 'Missing uri' if uri.nil?

      validate_auth_options(auth_options)

      handle_uri(uri, '/api')
      @api_version = version
      @headers = {}
      @ssl_options = ssl_options

      @basic_auth_user = auth_options[:user]
      @basic_auth_password = auth_options[:password]

      bearer_token(auth_options[:bearer_token]) if auth_options[:bearer_token]
    end

    def all_entities
      retrieve_all_entities(ENTITY_TYPES)
    end

    define_entity_methods(ENTITY_TYPES)

    private

    def validate_auth_options(opts)
      fail ArgumentError,
           'Missing password' if opts[:user] &&
                                 (opts[:password].nil? ||
                                 opts[:password].empty?)
      fail ArgumentError,
           'Specify either user/password or bearer token' if opts[:user] &&
                                                             opts[:bearer_token]
    end
  end
end
