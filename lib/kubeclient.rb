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
                      Namespace Secret ResourceQuota LimitRange PersistentVolume
                      PersistentVolumeClaim).map do |et|
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
                   auth_options: {}
                  )

      fail ArgumentError, 'Missing uri' if uri.nil?

      validate_auth_options(auth_options)

      handle_uri(uri, '/api')
      @api_version = version
      @headers = {}
      @ssl_options = ssl_options

      if auth_options[:user]
        @basic_auth_user = auth_options[:user]
        @basic_auth_password = auth_options[:password]
      elsif auth_options[:bearer_token]
        bearer_token(auth_options[:bearer_token])
      elsif auth_options[:bearer_token_file]
        validate_bearer_token_file(auth_options[:bearer_token_file])
        bearer_token(File.read(auth_options[:bearer_token_file]))
      end
    end

    def all_entities
      retrieve_all_entities(ENTITY_TYPES)
    end

    define_entity_methods(ENTITY_TYPES)

    private

    def validate_bearer_token_file(bearer_token_file)
      msg = "Token file #{bearer_token_file} does not exist"
      fail ArgumentError, msg unless File.file?(bearer_token_file)

      msg = "Cannot read token file #{bearer_token_file}"
      fail ArgumentError, msg unless File.readable?(bearer_token_file)
    end
  end
end
