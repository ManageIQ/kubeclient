require 'kubeclient/version'
require 'json'
require 'rest-client'
require 'active_support/inflector'
require 'kubeclient/event'
require 'kubeclient/pod'
require 'kubeclient/node'
require 'kubeclient/service'
require 'kubeclient/replication_controller'
require 'kubeclient/entity_list'
require 'kubeclient/kube_exception'
require 'kubeclient/watch'
require 'kubeclient/watch_stream'

module Kubeclient
  # Kubernetes Client
  class Client
    attr_reader :api_endpoint
    ENTITIES = %w(Pod Service ReplicationController Node Event)

    def initialize(api_endpoint, version)
      api_endpoint += '/' unless api_endpoint.end_with? '/'
      @api_endpoint = api_endpoint + version
      # version flag is needed to take care of the differences between
      # versions
      @api_version = version
    end

    private

    def rest_client
      # TODO: should a new one be created for every request?
      RestClient::Resource.new(@api_endpoint)
    end

    protected

    def create_entity(hash, entity)
      entity.classify.constantize.new(hash)
    end

    def get_resource_name(entity)
      if @api_version == 'v1beta1'
        entity.pluralize.camelize(:lower)
      else
        entity.pluralize.downcase
      end
    end

    ENTITIES.each do |entity|
      # get all entities of a type e.g. get_nodes, get_pods, etc.
      define_method("get_#{entity.underscore.pluralize}") do
        # TODO: labels support
        # TODO: namespace support?
        begin
          response = rest_client[get_resource_name(entity)].get # nil, labels
        rescue  RestClient::Exception => e
          exception = KubeException.new(e.http_code,
                                        JSON.parse(e.response)['message'])
          raise exception
        end

        result = JSON.parse(response)

        resourceVersion = result.fetch('resourceVersion', nil)
        if resourceVersion.nil?
          resourceVersion = result.fetch('metadata', {})
                                  .fetch('resourceVersion', nil)
        end

        collection = EntityList.new(entity, resourceVersion)

        result['items'].each do |item|
          collection.push(create_entity(item, entity))
        end

        collection
      end

      # watch all entities of a type e.g. watch_nodes, watch_pods, etc.
      define_method("watch_#{entity.underscore.pluralize}") \
          do |resourceVersion = nil|
        uri = URI.parse(api_endpoint + '/watch/' + get_resource_name(entity))
        uri.query = URI.encode_www_form(
          'resourceVersion' => resourceVersion) unless resourceVersion.nil?
        WatchStream.new(uri).to_enum
      end

      # get a single entity of a specific type by id
      define_method("get_#{entity.underscore}") do |id|
        begin
          response = rest_client[get_resource_name(entity) + "/#{id}"].get
        rescue  RestClient::Exception => e
          exception = KubeException.new(e.http_code,
                                        JSON.parse(e.response)['message'])
          raise exception
        end
        result = JSON.parse(response)
        create_entity(result, entity)
      end

      define_method("delete_#{entity.underscore}") do |id|
        begin
          rest_client[get_resource_name(entity) + "/#{id}"].delete
        rescue  RestClient::Exception => e
          exception = KubeException.new(e.http_code,
                                        JSON.parse(e.response)['message'])
          raise exception
        end
      end

      define_method("create_#{entity.underscore}") do |entity_config|
        # to_hash should be called because of issue #9 in recursive open
        # struct
        hash = entity_config.to_hash
        begin
          rest_client[get_resource_name(entity)].post(hash.to_json)
        rescue  RestClient::Exception => e
          exception = KubeException.new(e.http_code,
                                        JSON.parse(e.response)['message'])
          raise exception
        end
      end

      define_method("update_#{entity.underscore}") do |entity_config|
        id = entity_config.id
        # to_hash should be called because of issue #9 in recursive open
        # struct
        hash = entity_config.to_hash
        # TODO: temporary solution to delete id till this issue is solved
        # https://github.com/GoogleCloudPlatform/kubernetes/issues/3085
        hash.delete(:id)
        begin
          rest_client[get_resource_name(entity) + "/#{id}"].put(hash.to_json)
        rescue RestClient::Exception => e
          exception = KubeException.new(e.http_code,
                                        JSON.parse(e.response)['message'])
          raise exception
        end
      end
    end

    public

    # FIXME: fix the accessor names
    # rubocop:disable Style/AccessorMethodName
    def get_all_entities
      ENTITIES.each_with_object({}) do |entity, result_hash|
        # method call for get each entities
        # build hash of entity name to array of the entities
        method_name = "get_#{entity.underscore.pluralize}"
        key_name = entity.underscore
        result_hash[key_name] = send(method_name)
      end
    end
  end
end
