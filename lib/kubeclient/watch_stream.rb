# frozen_string_literal: true

require 'json'

module Kubeclient
  module Common
    # HTTP Stream used to watch changes on entities
    class WatchStream
      def initialize(uri, options, formatter:)
        @uri = uri
        @options = options
        @headers = options[:headers]
        @options[:http_max_redirects] ||= Kubeclient::Client::DEFAULT_HTTP_MAX_REDIRECTS
        @formatter = formatter

        @faraday_client = build_client
      end

      def each
        @finished = false
        buffer = +''

        begin
          @faraday_client.get('', nil, @headers) do |request|
            request.options.on_data = proc do |chunk|
              buffer << chunk
              while (line = buffer.slice!(/.+\n/))
                yield(@formatter.call(line.chomp))
              end
              next if @finished
            end
          end
        rescue Faraday::Error => e
          err_message = build_http_error_message(e)
          response_code = e.response ? (e.response[:status] || e.response&.env&.status) : nil
          error_klass = (response_code == 404 ? ResourceNotFoundError : HttpError)
          raise error_klass.new(response_code, err_message, e.response)
        end
      end

      def finish
        @finished = true
      end

      private

      def build_client
        auth = @options[:auth_options] || {}
        max_redirects = @options[:http_max_redirects]

        Faraday.new(@uri, @options[:faraday_options] || {}) do |connection|
          if auth[:username] && auth[:password]
            connection.basic_auth(auth[:username], auth[:password])
          end
          connection.use(FaradayMiddleware::FollowRedirects, limit: max_redirects)
          connection.response(:raise_error)
        end
      end

      def build_http_error_message(e)
        json_error_msg =
          begin
            JSON.parse(e.response[:body] || '') || {}
          rescue StandardError
            {}
          end
        json_error_msg['message'] || e.message || ''
      end
    end
  end
end
