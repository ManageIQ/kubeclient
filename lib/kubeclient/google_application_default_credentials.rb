# frozen_string_literal: true

module Kubeclient
  # Get a bearer token from the Google's application default credentials.
  class GoogleApplicationDefaultCredentials
    class << self
      def token
        require 'googleauth'
        scopes = ['https://www.googleapis.com/auth/cloud-platform']
        authorization = Google::Auth.get_application_default(scopes)
        authorization.apply({})
        authorization.access_token
      end
    end
  end
end
