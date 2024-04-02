# frozen_string_literal: true

module Kubeclient
  # Get a bearer token to authenticate against aws eks.
  class AmazonEksCredentials
    class AmazonEksDependencyError < LoadError # rubocop:disable Lint/InheritException
    end

    class << self
      def token(credentials, eks_cluster, region: 'us-east-1')
        begin
          require 'aws-sigv4'
          require 'base64'
          require 'cgi'
        rescue LoadError => e
          raise AmazonEksDependencyError,
                'Error requiring aws gems. Kubeclient itself does not include the following ' \
                'gems: [aws-sigv4]. To support auth-provider eks, you must ' \
                "include it in your calling application. Failed with: #{e.message}"
        end
        # https://github.com/aws/aws-sdk-ruby/pull/1848
        # Get a signer
        signer = if credentials.respond_to?(:credentials)
                   Aws::Sigv4::Signer.new(
                     service: 'sts',
                     region: region,
                     credentials_provider: credentials
                   )
                 else
                   Aws::Sigv4::Signer.new(
                     service: 'sts',
                     region: region,
                     credentials: credentials
                   )
                 end

        credentials = credentials.credentials if credentials.respond_to?(:credentials)

        # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/Sigv4/Signer.html#presign_url-instance_method
        presigned_url_string = signer.presign_url(
          http_method: 'GET',
          url: "https://sts.#{region}.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15",
          body: '',
          credentials: credentials,
          expires_in: 60,
          headers: {
            'X-K8s-Aws-Id' => eks_cluster
          }
        )
        kube_token = 'k8s-aws-v1.' + Base64.urlsafe_encode64(presigned_url_string.to_s).sub(/=*$/, '') # rubocop:disable Metrics/LineLength
        kube_token
      end
    end
  end
end
