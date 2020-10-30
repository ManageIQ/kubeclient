require_relative 'http_wrapper'

module Kubeclient
  # Wraps the API of +httpclient+ gem to be used by Kubeclient for making HTTP requests.
  class HTTPClientWrapper < HTTPWrapper
    def initialize(url, options)
      @url = url
      @options = options
      @client = HTTPClient.new
    end

    attr_reader :client

    def request(method, path = nil, **options)
      uri = [@url, path].compact.join('/')
      query = options[:params] if options.key?(:params)
      body = options[:body] if options.key?(:body)
      headers = options[:headers] if options.key(:headers)

      @client.request(method, uri, query, body, headers)
    end
  end
end
