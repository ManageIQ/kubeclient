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

        raise ArgumentError, "exec options are required" if opts.nil?

        cmd = opts['command']
        args = opts['args']
        env = map_env(opts['env'])
        api_version = opts['apiVersion']

        raise KeyError, "exec command is required" if cmd.nil?

        out, err, st = Open3.capture3(env, cmd, *args)

        if st.success?
          # out should have ExecCredential structure
          creds = JSON.parse(out)
          if creds
            # Verify apiVersion?
            raise "exec plugin is configured to use API version %s, plugin returned version %s" % [api_version, creds["apiVersion"]] if api_version && api_version != creds['apiVersion']
            raise "exec plugin didn't return a status field" if creds["status"].nil?
            raise "exec plugin didn't return a token" if creds["status"]["token"].nil?

            return creds["status"]["token"]
          else
            raise "invalid credentials"
          end
        else
          raise "exec command failed: #{err}"
        end
      end

      private

      # Transform name/value pairs to hash
      def map_env(env)
        return {} unless env

        Hash[env.map { |e| [e["name"], e["value"]] }]
      end
    end
  end
end
