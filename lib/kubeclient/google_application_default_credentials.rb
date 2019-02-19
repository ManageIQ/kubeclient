# frozen_string_literal: true

module Kubeclient
  # Get a bearer token from the Google's application default credentials.
  class GoogleApplicationDefaultCredentials
    class << self
      def token
        begin
          require 'googleauth'
        rescue LoadError
          puts "Gem 'googleauth' not found. Kubeclient does not include the googleauth gem, "\
          'you must include it in your own application'
          raise
        end
        scopes = ['https://www.googleapis.com/auth/cloud-platform']
        authorization = Google::Auth.get_application_default(scopes)
        authorization.apply({})
        authorization.access_token
      end
    end
  end
end
