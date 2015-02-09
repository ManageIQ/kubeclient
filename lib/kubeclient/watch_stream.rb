require 'json'
require 'net/http'

module Kubeclient
  # HTTP Stream used to watch changes on entities
  class WatchStream
    def initialize(uri)
      @uri = uri
    end

    def each
      buffer = ''
      Net::HTTP.start(@uri.host, @uri.port) do |http|
        request = Net::HTTP::Get.new @uri
        http.request request do |response|
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
      end
    end
  end
end
