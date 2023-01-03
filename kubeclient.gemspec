# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative 'lib/kubeclient/version'

Gem::Specification.new do |spec|
  spec.name          = 'kubeclient'
  spec.version       = Kubeclient::VERSION
  spec.authors       = ['Alissa Bonas']
  spec.email         = ['abonas@redhat.com']
  spec.summary       = 'A client for Kubernetes REST api'
  spec.description   = 'A client for Kubernetes REST api'
  spec.homepage      = 'https://github.com/abonas/kubeclient'
  spec.license       = 'MIT'

  git_files = `git ls-files -z`.split("\x0")
  spec.files         = git_files.grep_v(%r{^(test|spec|features)/})
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = []
  spec.required_ruby_version = '>= 2.7.0'

  spec.add_development_dependency 'bundler', '>= 1.6'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'minitest', '~> 5.15.0'
  spec.add_development_dependency 'minitest-rg'
  spec.add_development_dependency 'webmock', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.3.0' # locked to minor so new cops don't slip in
  spec.add_development_dependency 'googleauth', '~> 0.5'
  spec.add_development_dependency('mocha', '~> 1.5')
  spec.add_development_dependency 'openid_connect', '~> 1.1'
  spec.add_development_dependency 'net-smtp'
  spec.add_development_dependency 'forking_test_runner'

  spec.add_dependency 'faraday', '~> 1.1'
  spec.add_dependency 'faraday_middleware', '~> 1.0'
  spec.add_dependency 'recursive-open-struct', '~> 1.1', '>= 1.1.1'
  spec.add_dependency 'http', '>= 3.0', '< 6.0'
end
