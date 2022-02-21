#!/usr/bin/env ruby
# https://docs.k0sproject.io/latest/k0s-in-docker/
# Runs in --prividged mode, only run this if you trust the k0s distribution.

require 'English'

# Like Kernel#system, returns true iff exit status == 0
def sh?(*cmd)
  puts("+ #{cmd.join(' ')}")
  system(*cmd)
end

# Raises if exit status != 0
def sh!(*cmd)
  sh?(*cmd) || raise("returned #{$CHILD_STATUS}")
end

# allow DOCKER='sudo docker', DOCKER=podman etc.
DOCKER = ENV['DOCKER'] || 'docker'

CONTAINER = 'k0s'.freeze

sh! "#{DOCKER} container inspect #{CONTAINER} --format='exists' ||
  #{DOCKER} run -d --name #{CONTAINER} --hostname k0s --privileged -v /var/lib/k0s -p 6443:6443 \
  docker.io/k0sproject/k0s:v1.23.3-k0s.1"

# sh! "#{DOCKER} exec #{CONTAINER} kubectl config view --raw"
# is another way to dump kubeconfig but succeeds with dummy output even before admin.conf exists;
# so accessing the file is better way as it lets us poll until ready:
sleep(1) until sh?("#{DOCKER} exec #{CONTAINER} ls -l /var/lib/k0s/pki/admin.conf")

sh! "#{DOCKER} exec #{CONTAINER} cat /var/lib/k0s/pki/admin.conf > test/config/allinone.kubeconfig"
# The rest could easily be extracted from allinone.kubeconfig, but the test is more robust
# if we don't reuse YAML and/or Kubeclient::Config parsing to construct test data.
sh! "#{DOCKER} exec #{CONTAINER} cat /var/lib/k0s/pki/ca.crt     > test/config/external-ca.pem"
sh! "#{DOCKER} exec #{CONTAINER} cat /var/lib/k0s/pki/admin.crt  > test/config/external-cert.pem"
sh! "#{DOCKER} exec #{CONTAINER} cat /var/lib/k0s/pki/admin.key  > test/config/external-key.rsa"

sh! 'bundle exec rake test'

sh! "#{DOCKER} rm -f #{CONTAINER}"
