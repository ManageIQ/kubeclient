require_relative 'http_wrapper'

module Kubeclient
  # Wraps the API of +rest_client+ gem to be used by Kubeclient for making HTTP requests.
  class RestClientWrapper < HTTPWrapper
    def initialize(url, options)
      @client = RestClient::Resource.new(url, options)
    end

    attr_reader :client

    def request(method, path = nil, **options)
      url = path.nil? ? @client.url : @client[path].url
      headers_with_params = create_headers_with_params(options[:headers], options[:params])
      payload = options[:body]

      execute_options = @client.options.merge(
        method: method,
        url: url,
        headers: headers_with_params,
        payload: payload
      )
      RestClient::Request.execute(execute_options)
    end

    private

    # In RestClient, you pass params hash inside the headers hash, in :params key.
    def create_headers_with_params(headers, params)
      headers_with_params = {}.merge(headers || {})
      headers_with_params[:params] = params if params
      headers_with_params
    end
  end
end
