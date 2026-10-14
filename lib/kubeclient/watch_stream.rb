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
        @faraday_client = nil
      end

      def each
        @finished = false
        buffer = +''

        @faraday_client = build_client
        begin
          catch(:kubeclient_watch_stop) do
            @faraday_client.get('', nil, @headers) do |request|
              request.options.on_data = proc do |chunk|
                buffer << chunk
                while (line = buffer.slice!(/.+\n/))
                  yield(@formatter.call(line.chomp))
                end
                throw(:kubeclient_watch_stop) if @finished
              end
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
        @faraday_client&.close
      end

      private

      def build_client
        auth = @options[:auth_options] || {}
        max_redirects = @options[:http_max_redirects]

        Faraday.new(@uri, @options[:faraday_options] || {}) do |connection|
          if auth[:username] && auth[:password]
            if connection.respond_to?(:set_basic_auth)
              # Faraday 2.x
              connection.set_basic_auth(auth[:username], auth[:password])
            else
              connection.basic_auth(auth[:username], auth[:password])
            end
          end

          bearer_token = nil
          if @options[:bearer_token_file]
            bearer_token_file = @options[:bearer_token_file]
            if File.file?(bearer_token_file) && File.readable?(bearer_token_file)
              token = File.read(bearer_token_file).chomp
              bearer_token = "Bearer #{token}"
            end
          elsif @options[:bearer_token]
            bearer_token = "Bearer #{@options[:bearer_token]}"
          end

          if bearer_token
            connection.headers['authorization'] = bearer_token
          end

          connection.use(Faraday::FollowRedirects::Middleware, limit: max_redirects)
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
