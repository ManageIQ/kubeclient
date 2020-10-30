module Kubeclient
  # Defines the common API for libraries to be used by Kubeclient for making HTTP requests.
  # To create a wrapper for a library, create a new class that inherits from this class
  # and override the +request+ method. See +RestClientWrapper+ or +HTTPClientWrapper+ for examples.
  class HTTPWrapper
    def delete(path = nil, **options)
      request(:delete, path, **options)
    end

    def get(path = nil, **options)
      request(:get, path, **options)
    end

    def patch(path = nil, **options)
      request(:patch, path, **options)
    end

    def post(path = nil, **options)
      request(:post, path, **options)
    end

    def put(path = nil, **options)
      request(:put, path, **options)
    end

    def request
      raise 'Must implement the `request` method.'
    end
  end
end
