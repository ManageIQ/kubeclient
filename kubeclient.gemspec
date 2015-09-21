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
  spec.required_ruby_version = '>= 2.0.0'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'vcr'
  spec.add_development_dependency 'rubocop', '= 0.30.0'
  spec.add_dependency 'rest-client'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'json'
  spec.add_dependency 'recursive-open-struct', '= 0.6.1'
end
