require 'kubeclient/version'
require 'json'
require 'rest-client'
require 'active_support/inflector'
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

    def initialize(uri, version)
      @api_endpoint = (uri.is_a? URI) ? uri : URI.parse(uri)
      @api_endpoint.merge!(File.join(@api_endpoint.path, version))
      # version flag is needed to take care of the differences between
      # versions
      @api_version = version
      set_ssl
    end

    private

    def rest_client
      options = {
        ssl_ca_file:      @ssl_options[:ca_file],
        verify_ssl:       @ssl_options[:verify_mode],
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

    def set_ssl(client_cert: nil, client_key: nil, ca_file: nil,
                verify_mode: OpenSSL::SSL::VERIFY_PEER)
      @ssl_options = {
        ca_file:      ca_file,
        verify_ssl:   verify_mode,
        client_cert:  client_cert,
        client_key:   client_key
      }
    end

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

      # watch all entities of a type e.g. watch_nodes, watch_pods, etc.
      define_method("watch_#{entity.underscore.pluralize}") \
          do |resourceVersion = nil, &block|
        resource_name = get_resource_name(entity.to_s)

        uri = api_endpoint.merge(
          File.join(api_endpoint.path, 'watch', resource_name))

        unless resourceVersion.nil?
          uri.query = URI.encode_www_form(
            'resourceVersion' => resourceVersion)
        end

        options = {
          use_ssl:      uri.scheme == 'https',
          ca_file:      @ssl_options[:ca_file],
          verify_ssl:   @ssl_options[:verify_mode],
          client_cert:  @ssl_options[:client_cert],
          client_key:   @ssl_options[:client_key]
        }

        buffer = ''

        Net::HTTP.start(uri.host, uri.port, options) do |http|
          request = Net::HTTP::Get.new(uri)

          http.request(request) do |response|
            unless response.is_a? Net::HTTPSuccess
              fail KubeException.new(response.code, response.message)
            end

            response.read_body do |chunk|
              buffer << chunk
              while (line = buffer.slice!(/.+\n/))
                block.call(WatchNotice.new(JSON.parse(line)))
              end
            end
          end
        end
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
  end
end
