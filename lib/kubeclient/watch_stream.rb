require 'json'
require 'net/http'
module Kubeclient
  module Common
    # HTTP Stream used to watch changes on entities
    class WatchStream
      def initialize(uri, http_options, format: :json)
        @uri = uri
        @http = nil
        @options = http_options.merge(read_timeout: nil)
        @format = format
      end

      def each
        @finished = false
        @http = Net::HTTP.start(@uri.host, @uri.port, @options)

        buffer = ''
        request = generate_request

        @http.request(request) do |response|
          unless response.is_a? Net::HTTPSuccess
            fail KubeException.new(response.code, response.message, response)
          end
          response.read_body do |chunk|
            buffer << chunk
            while (line = buffer.slice!(/.+\n/))
              yield @format == :json ? WatchNotice.new(JSON.parse(line)) : line.chomp
            end
          end
        end
      rescue Errno::EBADF
        raise unless @finished
      end

      def generate_request
        request = Net::HTTP::Get.new(@uri)
        if @options[:basic_auth_user] && @options[:basic_auth_password]
          request.basic_auth @options[:basic_auth_user],
                             @options[:basic_auth_password]
        end

        @options[:headers].each do |header, value|
          request[header.to_s] = value
        end
        request
      end

      def finish
        @finished = true
        @http.finish if !@http.nil? && @http.started?
      end
    end
  end
end
