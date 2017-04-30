# For travis to additionally test rest-client 1.x.

source 'https://rubygems.org'

# Specify your gem's dependencies in kubeclient.gemspec
gemspec

if dependencies.any? # needed for overriding with recent bundler (1.13 ?)
  dependencies.delete('rest-client')
  gem 'rest-client', '= 1.8.0'
end
