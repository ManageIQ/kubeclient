require 'kubeclient/version'
require 'json'
require 'rest-client'
require 'active_support/inflector'
require 'em-http-request'
require 'kubeclient/event'
require 'kubeclient/pod'
require 'kubeclient/node'
require 'kubeclient/service'
require 'kubeclient/replication_controller'
require 'kubeclient/endpoint'
require 'kubeclient/entity_list'
require 'kubeclient/kube_exception'
require 'kubeclient/watch'

module Kubeclient
  # Kubernetes Client
  class Client
    attr_reader :api_endpoint
    ENTITIES = %w(Pod Service ReplicationController Node Event Endpoint)

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

    def handling_kube_exception
      yield
    rescue RestClient::Exception => e
      raise KubeException.new(e.http_code, JSON.parse(e.response)['message'])
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

    public

    ENTITIES.each do |entity|
      # get all entities of a type e.g. get_nodes, get_pods, etc.
      define_method("get_#{entity.underscore.pluralize}") do
        # TODO: labels support
        # TODO: namespace support?
        response = handling_kube_exception do
          rest_client[get_resource_name(entity)].get # nil, labels
        end

        result = JSON.parse(response)

        resource_version = result.fetch('resourceVersion', nil)
        if resource_version.nil?
          resource_version =
            result.fetch('metadata', {}).fetch('resourceVersion', nil)
        end

        collection = EntityList.new(entity, resource_version)

        result['items'].each do |item|
          collection.push(create_entity(item, entity))
        end

        collection
      end

      # get a single entity of a specific type by id
      define_method("get_#{entity.underscore}") do |id|
        response = handling_kube_exception do
          rest_client[get_resource_name(entity) + "/#{id}"].get
        end
        result = JSON.parse(response)
        create_entity(result, entity)
      end

      define_method("delete_#{entity.underscore}") do |id|
        handling_kube_exception do
          rest_client[get_resource_name(entity) + "/#{id}"].delete
        end
      end

      define_method("create_#{entity.underscore}") do |entity_config|
        # to_hash should be called because of issue #9 in recursive open
        # struct
        hash = entity_config.to_hash
        handling_kube_exception do
          rest_client[get_resource_name(entity)].post(hash.to_json)
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
        handling_kube_exception do
          rest_client[get_resource_name(entity) + "/#{id}"].put(hash.to_json)
        end
      end
    end

    def all_entities
      ENTITIES.each_with_object({}) do |entity, result_hash|
        # method call for get each entities
        # build hash of entity name to array of the entities
        method_name = "get_#{entity.underscore.pluralize}"
        key_name = entity.underscore
        result_hash[key_name] = send(method_name)
      end
    end

    def watch(entities)
      watch_endpoint = api_endpoint + '/watch/'
      options = { inactivity_timeout: 0, keepalive: true }

      EventMachine.run do
        multi_request = EventMachine::MultiRequest.new

        entities.each do |entity, version|
          uri = URI.parse(watch_endpoint + get_resource_name(entity.to_s))

          unless version.nil?
            uri.query = URI.encode_www_form('resourceVersion' => version)
          end

          request = EventMachine::HttpRequest.new(uri, options).get

          request.errback do
            EventMachine.stop
            fail request.error
          end

          request.callback do
            EventMachine.stop
            unless request.response_header.successful?
              fail KubeException.new(
                request.response_header.status,
                request.response_header.http_reason
              )
            end
          end

          buffer = ''
          request.stream do |chunk|
            if request.response_header.successful?
              buffer += chunk
              while (notice = buffer.slice!(/.+\n/))
                yield entity, WatchNotice.new(JSON.parse(notice))
              end
            end
          end

          multi_request.add(entity, request)
        end
      end
    end
  end
end
