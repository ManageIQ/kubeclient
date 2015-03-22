require 'json'
require 'net/http'
module Kubeclient
  module Common
    # HTTP Stream used to watch changes on entities
    class WatchStream
      def initialize(uri, options)
        @uri = uri
        @http = nil
        @options = options.merge(read_timeout: nil)
      end

      def each
        @finished = false
        @http = Net::HTTP.start(@uri.host, @uri.port, @options)

        buffer = ''
        request = Net::HTTP::Get.new(@uri)

        @http.request(request) do |response|
          unless response.is_a? Net::HTTPSuccess
            fail KubeException.new(response.code, response.message)
          end
          response.read_body do |chunk|
            buffer << chunk
            while (line = buffer.slice!(/.+\n/))
              yield WatchNotice.new(JSON.parse(line))
            end
          end
        end
      rescue Errno::EBADF
        raise unless @finished
      end

      def finish
        @finished = true
        @http.finish if !@http.nil? && @http.started?
      end
    end
  end
end
