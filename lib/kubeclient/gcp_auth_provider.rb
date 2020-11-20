# frozen_string_literal: true

require_relative 'google_application_default_credentials'
require_relative 'gcp_command_credentials'

module Kubeclient
  # Handle different ways to get a bearer token for Google Cloud Platform.
  class GCPAuthProvider
    class << self
      def token(config)
        if config.key?('cmd-path')
          Kubeclient::GCPCommandCredentials.token(config)
        else
          Kubeclient::GoogleApplicationDefaultCredentials.token
        end
      end
    end
  end
end
