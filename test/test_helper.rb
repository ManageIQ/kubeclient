require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/rg'
require 'webmock/minitest'
require 'mocha/minitest'
require 'json'
require 'kubeclient'

# Assumes test files will be in a subdirectory with the same name as the
# file suffix.  e.g. a file named foo.json would be a "json" subdirectory.
def open_test_file(name)
  File.new(File.join(File.dirname(__FILE__), name.split('.').last, name))
end

def stub_core_api_list
  stub_request(:get, %r{/api/v1$})
    .to_return(body: open_test_file('core_api_resource_list.json'), status: 200)
end
