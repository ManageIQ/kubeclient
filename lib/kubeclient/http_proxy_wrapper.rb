module Kubeclient
  module Common
    # Wrapper around Net:HTTP to support k8s services
    class HttpProxyWrapper
      def initialize(uri, options)
        @uri = uri
        @options = options
      end

      def get(path)
        Net::HTTP.start(@uri.host, @uri.port, @options) do |http|
          http.request generate_get_request(path)
        end
      end

      def post(path, form_data)
        Net::HTTP.start(@uri.host, @uri.port, @options) do |http|
          http.request generate_post_request(path, form_data)
        end
      end

      def generate_post_request(path, body = {})
        joined = URI.parse(@uri.to_s + "#{path}")
        request = Net::HTTP::Post.new(joined)
        update_headers(request)
        request.body = body
        request
      end

      def generate_get_request(path)
        joined = URI.parse(@uri.to_s + "#{path}")
        request = Net::HTTP::Get.new(joined)
        update_headers(request)
      end

      def update_headers(request)
        if @options[:basic_auth_user] && @options[:basic_auth_password]
          request.basic_auth @options[:basic_auth_user],
                             @options[:basic_auth_password]
        end

        @options[:headers].each do |header, value|
          request[header.to_s] = value
        end
        request
      end
    end
  end
end
