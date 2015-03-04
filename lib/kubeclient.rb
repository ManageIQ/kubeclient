require 'kubeclient/version'
require 'json'
require 'rest-client'
require 'active_support/inflector'
require 'kubeclient/entity_list'
require 'kubeclient/kube_exception'
require 'kubeclient/watch'
require 'kubeclient/watch_stream'

module Kubeclient
  # Kubernetes Client
  class Client
    attr_reader :api_endpoint

    ENTITY_TYPES = %w(Pod Service ReplicationController Node Event Endpoint
                      Namespace)

    # Dynamically creating classes definitions (class Pod, class Service, etc.),
    # The classes are extending RecursiveOpenStruct.
    # This cancels the need to define the classes
    # manually on every new entity addition,
    # and especially since currently the class body is empty
    ENTITY_TYPES.each do |entity_type|
      Object.const_set(entity_type, Class.new(RecursiveOpenStruct))
    end

    def initialize(uri, version)
      @api_endpoint = (uri.is_a? URI) ? uri : URI.parse(uri)
      @api_endpoint.merge!(File.join(@api_endpoint.path, version))
      # version flag is needed to take care of the differences between
      # versions
      @api_version = version
      ssl_options
    end

    private

    def rest_client
      options = {
        ssl_ca_file:      @ssl_options[:ca_file],
        verify_ssl:       @ssl_options[:verify_ssl],
        ssl_client_cert:  @ssl_options[:client_cert],
        ssl_client_key:   @ssl_options[:client_key]
      }

      # TODO: should a new one be created for every request?
      RestClient::Resource.new(@api_endpoint, options)
    end

    def handling_kube_exception
      yield
    rescue RestClient::Exception => e
      raise KubeException.new(e.http_code, JSON.parse(e.response)['message'])
    end

    def get_entities(entity_type)
      # TODO: labels support
      # TODO: namespace support?
      response = handling_kube_exception do
        rest_client[get_resource_name(entity_type)].get # nil, labels
      end

      result = JSON.parse(response)

      resource_version = result.fetch('resourceVersion', nil)
      if resource_version.nil?
        resource_version =
          result.fetch('metadata', {}).fetch('resourceVersion', nil)
      end

      collection = EntityList.new(entity_type, resource_version)

      result['items'].each do |item|
        collection.push(new_entity(item, entity_type))
      end

      collection
    end

    def watch_entities(entity_type, resource_version = nil)
      resource_name = get_resource_name(entity_type.to_s)

      uri = api_endpoint.merge(
        File.join(api_endpoint.path, 'watch', resource_name))

      unless resource_version.nil?
        uri.query = URI.encode_www_form('resourceVersion' => resource_version)
      end

      options = {
        use_ssl:      uri.scheme == 'https',
        ca_file:      @ssl_options[:ca_file],
        verify_ssl:   @ssl_options[:verify_ssl],
        client_cert:  @ssl_options[:client_cert],
        client_key:   @ssl_options[:client_key]
      }

      WatchStream.new(uri, options)
    end

    def get_entity(entity_type, id)
      response = handling_kube_exception do
        rest_client[get_resource_name(entity_type) + "/#{id}"].get
      end
      result = JSON.parse(response)
      new_entity(result, entity_type)
    end

    def delete_entity(entity_type, id)
      handling_kube_exception do
        rest_client[get_resource_name(entity_type) + "/#{id}"].delete
      end
    end

    def create_entity(entity_type, entity_config)
      # to_hash should be called because of issue #9 in recursive open
      # struct
      hash = entity_config.to_hash
      handling_kube_exception do
        rest_client[get_resource_name(entity_type)].post(hash.to_json)
      end
    end

    def update_entity(entity_type, entity_config)
      id = entity_config.id
      # to_hash should be called because of issue #9 in recursive open
      # struct
      hash = entity_config.to_hash
      # TODO: temporary solution to delete id till this issue is solved
      # https://github.com/GoogleCloudPlatform/kubernetes/issues/3085
      hash.delete(:id)
      handling_kube_exception do
        rest_client[get_resource_name(entity_type) + "/#{id}"].put(hash.to_json)
      end
    end

    protected

    def new_entity(hash, entity_type)
      entity_type.classify.constantize.new(hash)
    end

    def get_resource_name(entity_type)
      if @api_version == 'v1beta1'
        entity_type.pluralize.camelize(:lower)
      else
        entity_type.pluralize.downcase
      end
    end

    public

    def ssl_options(client_cert: nil, client_key: nil, ca_file: nil,
                    verify_ssl: OpenSSL::SSL::VERIFY_PEER)
      @ssl_options = {
        ca_file:      ca_file,
        verify_ssl:   verify_ssl,
        client_cert:  client_cert,
        client_key:   client_key
      }
    end

    ENTITY_TYPES.each do |entity_type|
      entity_name = entity_type.underscore
      entity_name_plural = entity_name.pluralize

      # get all entities of a type e.g. get_nodes, get_pods, etc.
      define_method("get_#{entity_name_plural}") do
        get_entities(entity_type)
      end

      # watch all entities of a type e.g. watch_nodes, watch_pods, etc.
      define_method("watch_#{entity_name_plural}") do |resource_version = nil|
        watch_entities(entity_type, resource_version)
      end

      # get a single entity of a specific type by id
      define_method("get_#{entity_name}") do |id|
        get_entity(entity_type, id)
      end

      define_method("delete_#{entity_name}") do |id|
        delete_entity(entity_type, id)
      end

      define_method("create_#{entity_name}") do |entity_config|
        create_entity(entity_type, entity_config)
      end

      define_method("update_#{entity_name}") do |entity_config|
        update_entity(entity_type, entity_config)
      end
    end

    def all_entities
      ENTITY_TYPES.each_with_object({}) do |entity_type, result_hash|
        # method call for get each entities
        # build hash of entity name to array of the entities
        method_name = "get_#{entity_type.underscore.pluralize}"
        key_name = entity_type.underscore
        result_hash[key_name] = send(method_name)
      end
    end
  end
end
