# frozen_string_literal: true

module Kubeclient
  # An exec-based client auth provide
  # https://kubernetes.io/docs/reference/access-authn-authz/authentication/#configuration
  # Inspired by https://github.com/kubernetes/client-go/blob/master/plugin/pkg/client/auth/exec/exec.go
  class ExecCredentials
    class << self
      def token(opts)
        require 'open3'
        require 'json'

        raise ArgumentError, 'exec options are required' if opts.nil?

        cmd = opts['command']
        args = opts['args']
        env = map_env(opts['env'])

        # Validate exec options
        validate_opts(opts)

        out, err, st = Open3.capture3(env, cmd, *args)

        raise "exec command failed: #{err}" unless st.success?

        creds = JSON.parse(out)
        validate_credentials(opts, creds)
        creds['status']['token']
      end

      private

      def validate_opts(opts)
        raise KeyError, 'exec command is required' unless opts['command']
      end

      def validate_credentials(opts, creds)
        # out should have ExecCredential structure
        raise 'invalid credentials' if creds.nil?

        # Verify apiVersion?
        api_version = opts['apiVersion']
        if api_version && api_version != creds['apiVersion']
          raise "exec plugin is configured to use API version #{api_version}, " \
            "plugin returned version #{creds['apiVersion']}"
        end

        raise 'exec plugin didn\'t return a status field' if creds['status'].nil?
        raise 'exec plugin didn\'t return a token' if creds['status']['token'].nil?
      end

      # Transform name/value pairs to hash
      def map_env(env)
        return {} unless env

        Hash[env.map { |e| [e['name'], e['value']] }]
      end
    end
  end
end
