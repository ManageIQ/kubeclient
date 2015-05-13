# Kubeclient

[![Gem Version](https://badge.fury.io/rb/kubeclient.svg)](http://badge.fury.io/rb/kubeclient)
[![Build Status](https://travis-ci.org/abonas/kubeclient.svg?branch=master)](https://travis-ci.org/abonas/kubeclient)
[![Code Climate](http://img.shields.io/codeclimate/github/abonas/kubeclient.svg)](https://codeclimate.com/github/abonas/kubeclient)
[![Dependency Status](https://gemnasium.com/abonas/kubeclient.svg)](https://gemnasium.com/abonas/kubeclient)

A Ruby client for Kubernetes REST api.
The client supports GET, POST, PUT, DELETE on nodes, pods, services, replication controllers, namespaces and endpoints.
The client currently supports Kubernetes REST api version v1beta3.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kubeclient'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kubeclient

## Usage

Initialize the client:
```ruby
client = Kubeclient::Client.new 'http://localhost:8080/api/' , "v1beta3"
```

Or without specifying version (it will be set by default to "v1beta3"

```ruby
client = Kubeclient::Client.new 'http://localhost:8080/api/'
```

Another option is to initialize the client with URI object:

```ruby
uri = URI::HTTP.build(host: "somehostname", port: 8080)
client = Kubeclient::Client.new uri
```


It is also possible to use https and configure ssl with:

```ruby
client = Kubeclient::Client.new 'https://localhost:8443/api/' , "v1beta3"
client.ssl_options(
  client_cert: OpenSSL::X509::Certificate.new(File.read('/path/to/client.crt')),
  client_key:  OpenSSL::PKey::RSA.new(File.read('/path/to/client.key')),
  ca_file:     '/path/to/ca.crt',
  verify_ssl:  OpenSSL::SSL::VERIFY_PEER
)
```

For testing and development purpose you can disable the ssl check with:

```ruby
client.ssl_options(verify_ssl: OpenSSL::SSL::VERIFY_NONE)
```

If you are using bearer tokens for authentication as described
[here](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/docs/authentication.md) then you can specify the
bearer token to use for authentication:

```ruby
client.bearer_token('MDExMWJkMjItOWY1Ny00OGM5LWJlNDEtMjBiMzgxODkxYzYz')
```

If you are running your app using kubeclient inside a Kubernetes cluster, then you can have a bearer token file
mounted inside your pod by using a
[Service Account](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/docs/design/service_accounts.md). This
will mount a bearer token [secret](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/docs/design/secrets.md)
a/ `/var/run/secrets/kubernetes.io/serviceaccount/token` (see [here](https://github.com/GoogleCloudPlatform/kubernetes/pull/7101)
for more details).

## Examples:

#### Get all pods
And respectively: `get_services`, `get_nodes`, `get_replication_controllers`

```ruby
pods = client.get_pods
```

You can get entities which have specific labels by specifying a parameter named `label_selector` (named `labelSelector` in Kubernetes server):
```ruby
pods = client.get_pods(label_selector: 'name=redis-master')
```
You can specify multiple labels (that option will return entities which have both labels:
```ruby
pods = client.get_pods(label_selector: 'name=redis-master,app=redis')
```

#### Get a specific node
And respectively: `get_service "service name"` , `get_pod "pod name"` , `get_replication_controller "rc name"`

The GET request should include the namespace name, except for nodes and namespaces entities.

```ruby
node = client.get_node "127.0.0.1"
```

```ruby
service = client.get_service "guestbook", 'development'
```

Note - Kubernetes doesn't work with the uid, but rather with the 'name' property.
Querying with uid causes 404.

#### Delete a service

And respectively `delete_pod "pod id"` , `delete_replication_controller "rc id"`, `delete node "node id"`

Input parameter - id (string) specifying service id, pod id, replication controller id.
```ruby
client.delete_service "redis-service"
```

#### Create a service
And respectively: `create_pod pod_object`, `create_replication_controller rc_obj`

Input parameter - object of type `Service`, `Pod`, `ReplicationController`.

The below example is for v1beta3

```ruby
service = Service.new
service.metadata.name = "redis-master"
service.spec.port = 6379
service.spec.containerPort  = "redis-server"
service.spec.selector = {}
service.spec.selector.name = "redis"
service.spec.selector.role = "master"
client.create_service service`
```

#### Update entity
And respectively `update_pod`, `update_service`, `update_replication_controller`

Input parameter - object of type `Service`, `Pod`, `ReplicationController`

The below example is for v1beta3

```ruby
client.update_service service1
```

#### all_entities
Returns a hash with 7 keys (node, service, pod, replication_controller, namespace, endpoint and event). Each key points to an EntityList of same type.

This method is a convenience method instead of calling each entity's get method separately.

```ruby
client.all_entities
```

#### Receive entity updates
It is possible to receive live update notices watching the relevant entities:

```ruby
watcher = client.watch_pods
watcher.each do |notice|
  # process notice data
end
```

It is possible to interrupt the watcher from another thread with:

```ruby
watcher.finish
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/kubeclient/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Test your changes with `rake test rubocop`, add new tests if needed.
4. If you added a new functionality, add it to README
5. Commit your changes (`git commit -am 'Add some feature'`)
6. Push to the branch (`git push origin my-new-feature`)
7. Create a new Pull Request

## Tests

This client is tested with Minitest.
Please run all tests before submitting a Pull Request, and add new tests for new functionality.

Running tests:
```ruby
rake test
```
