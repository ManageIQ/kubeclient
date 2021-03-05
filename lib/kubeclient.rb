# frozen_string_literal: true

require 'json'

require_relative 'kubeclient/aws_eks_credentials'
require_relative 'kubeclient/common'
require_relative 'kubeclient/config'
require_relative 'kubeclient/entity_list'
require_relative 'kubeclient/exec_credentials'
require_relative 'kubeclient/gcp_auth_provider'
require_relative 'kubeclient/http_error'
require_relative 'kubeclient/informer'
require_relative 'kubeclient/missing_kind_compatibility'
require_relative 'kubeclient/oidc_auth_provider'
require_relative 'kubeclient/resource'
require_relative 'kubeclient/resource_not_found_error'
require_relative 'kubeclient/version'
require_relative 'kubeclient/watch_stream'

module Kubeclient
  # Kubernetes Client
  class Client
    include ClientMixin
    def initialize(
      uri,
      version,
      **options
    )
      unless version.is_a?(String)
        raise ArgumentError, "second argument must be an api version like 'v1'"
      end
      initialize_client(
        uri,
        '/api',
        version,
        **options
      )
    end
  end
end
