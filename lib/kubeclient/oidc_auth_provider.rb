# frozen_string_literal: true

module Kubeclient
  # Uses OIDC id-tokens and refreshes them if they are stale.
  class OIDCAuthProvider
    class OpenIDConnectDependencyError < LoadError # rubocop:disable Lint/InheritException
    end

    class << self
      def token(provider_config)
        begin
          require 'openid_connect'
        rescue LoadError => e
          raise OpenIDConnectDependencyError,
                'Error requiring openid_connect gem. Kubeclient itself does not include the ' \
                'openid_connect gem. To support auth-provider oidc, you must include it in your ' \
                "calling application. Failed with: #{e.message}"
        end

        issuer_url = provider_config['idp-issuer-url']
        discovery = OpenIDConnect::Discovery::Provider::Config.discover! issuer_url

        if provider_config.key? 'id-token'
          id_token = OpenIDConnect::ResponseObject::IdToken.decode provider_config['id-token'],
                                                                   discovery.jwks
          return provider_config['id-token'] unless expired?(id_token)
        end

        client = OpenIDConnect::Client.new(
          identifier: provider_config['client-id'],
          secret: provider_config['client-secret'],
          authorization_endpoint: discovery.authorization_endpoint,
          token_endpoint: discovery.token_endpoint,
          userinfo_endpoint: discovery.userinfo_endpoint
        )
        client.refresh_token = provider_config['refresh-token']
        client.access_token!.id_token
      end

      def expired?(id_token)
        # If token expired or expiring within 60 seconds
        Time.now.to_i + 60 > id_token.exp.to_i
      end
    end
  end
end
