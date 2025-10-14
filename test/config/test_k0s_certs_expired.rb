#!/usr/bin/env ruby

require 'yaml'
require 'kubeclient'

config_file = File.join(__dir__, 'allinone.kubeconfig')
config      = Kubeclient::Config.read(config_file)

valid = config.context.ssl_options[:cert_store].verify(config.context.ssl_options[:client_cert])
abort('Certificates are expired') unless valid
