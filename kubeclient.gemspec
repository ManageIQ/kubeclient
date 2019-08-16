# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kubeclient/version'

Gem::Specification.new do |spec|
  spec.name          = 'kubeclient'
  spec.version       = Kubeclient::VERSION
  spec.authors       = ['Alissa Bonas']
  spec.email         = ['abonas@redhat.com']
  spec.summary       = 'A client for Kubernetes REST api'
  spec.description   = 'A client for Kubernetes REST api'
  spec.homepage      = 'https://github.com/abonas/kubeclient'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.2.0'

  spec.add_development_dependency 'bundler', '>= 1.6'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'minitest-rg'
  spec.add_development_dependency 'webmock', '~> 3.0'
  spec.add_development_dependency 'vcr'
  spec.add_development_dependency 'rubocop', '= 0.49.1'
  spec.add_development_dependency 'googleauth', '~> 0.5.1'
  spec.add_development_dependency('mocha', '~> 1.5')
  spec.add_development_dependency 'openid_connect', '~> 1.1'
  spec.add_development_dependency 'jsonpath', '~> 1.0'

  spec.add_dependency 'rest-client', '~> 2.0'
  spec.add_dependency 'recursive-open-struct', '~> 1.0', '>= 1.0.4'
  spec.add_dependency 'http', '>= 3.0', '< 5.0'
end
