# frozen_string_literal: true

module Kubeclient
  # Uses OIDC id-tokens and refreshes them if they are stale.
  class OIDCAuthProvider
    class OpenIDConnectDependencyError < LoadError # rubocop:disable Lint/InheritException
    end

    class << self
      def token(auth_provider)
        begin
          require 'openid_connect'
        rescue LoadError => e
          raise OpenIDConnectDependencyError,
                'Error requiring openid_connect gem. Kubeclient itself does not include the ' \
                'openid_connect gem. To support auth-provider oidc, you must include it in your ' \
                "calling application. Failed with: #{e.message}"
        end

        issuer_url = auth_provider['idp-issuer-url']
        discovery = OpenIDConnect::Discovery::Provider::Config.discover! issuer_url

        id_token = OpenIDConnect::ResponseObject::IdToken.decode auth_provider['id-token'],
                                                                 discovery.jwks

        return auth_provider['id-token'] unless expired?(id_token)

        client = OpenIDConnect::Client.new(
          identifier: auth_provider['client-id'],
          secret: auth_provider['client-secret'],
          authorization_endpoint: discovery.authorization_endpoint,
          token_endpoint: discovery.token_endpoint,
          userinfo_endpoint: discovery.userinfo_endpoint
        )
        client.refresh_token = auth_provider['refresh-token']
        client.access_token!.id_token
      end

      def expired?(id_token)
        # If token expired or expiring within 60 seconds
        Time.now.to_i + 60 > id_token.exp.to_i
      end
    end
  end
end
