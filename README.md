# Kubeclient

[![Gem Version](https://badge.fury.io/rb/kubeclient.svg)](http://badge.fury.io/rb/kubeclient)
[![Build Status](https://travis-ci.org/abonas/kubeclient.svg?branch=master)](https://travis-ci.org/abonas/kubeclient)
[![Code Climate](http://img.shields.io/codeclimate/github/abonas/kubeclient.svg)](https://codeclimate.com/github/abonas/kubeclient)
[![Dependency Status](https://gemnasium.com/abonas/kubeclient.svg)](https://gemnasium.com/abonas/kubeclient)

A Ruby client for Kubernetes REST api.
The client supports GET, POST, PUT, DELETE on nodes, pods, secrets, services, replication controllers, namespaces, resource quotas, limit ranges, endpoints, persistent volumes, persistent volume claims and component statuses.
The client currently supports Kubernetes REST api version v1.

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
client = Kubeclient::Client.new 'http://localhost:8080/api/' , "v1"
```

Or without specifying version (it will be set by default to "v1"

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
ssl_options = {
  client_cert: OpenSSL::X509::Certificate.new(File.read('/path/to/client.crt')),
  client_key:  OpenSSL::PKey::RSA.new(File.read('/path/to/client.key')),
  ca_file:     '/path/to/ca.crt',
  verify_ssl:  OpenSSL::SSL::VERIFY_PEER
}
client = Kubeclient::Client.new 'https://localhost:8443/api/' , "v1",
                                ssl_options: ssl_options
```

For testing and development purpose you can disable the ssl check with:

```ruby
ssl_options = { verify_ssl: OpenSSL::SSL::VERIFY_NONE }
client = Kubeclient::Client.new 'https://localhost:8443/api/' , 'v1',
                                ssl_options: ssl_options
```

If you are using basic authentication or bearer tokens as described
[here](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/docs/authentication.md) then you can specify one
of the following:

```ruby
auth_options = {
  username: 'username',
  password: 'password'
}
client = Kubeclient::Client.new 'https://localhost:8443/api/' , 'v1',
                                auth_options: auth_options
```

or

```ruby
auth_options = {
  bearer_token: 'MDExMWJkMjItOWY1Ny00OGM5LWJlNDEtMjBiMzgxODkxYzYz'
}
client = Kubeclient::Client.new 'https://localhost:8443/api/' , 'v1',
                                auth_options: auth_options
```

or

```ruby
auth_options = {
  bearer_token_file: '/path/to/token_file'
}
client = Kubeclient::Client.new 'https://localhost:8443/api/' , 'v1',
                                auth_options: auth_options
```

If you are running your app using kubeclient inside a Kubernetes cluster, then you can have a bearer token file
mounted inside your pod by using a
[Service Account](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/docs/design/service_accounts.md). This
will mount a bearer token [secret](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/docs/design/secrets.md)
a/ `/var/run/secrets/kubernetes.io/serviceaccount/token` (see [here](https://github.com/GoogleCloudPlatform/kubernetes/pull/7101)
for more details). For example:

```ruby
auth_options = {
  bearer_token_file: '/var/run/secrets/kubernetes.io/serviceaccount/token'

}
client = Kubeclient::Client.new 'https://localhost:8443/api/' , 'v1',
                                auth_options: auth_options
```

## Examples:

#### Get all instances of a specific entity type
Such as: `get_pods`, `get_secrets`, `get_services`, `get_nodes`, `get_replication_controllers`, `get_resource_quotas`, `get_limit_ranges`, `get_persistent_volumes`, `get_persistent_volume_claims`, `get_component_statuses`

```ruby
pods = client.get_pods
```

Get all entities of a specific type in a namespace:<br>

```ruby
services = client.get_services(namespace: 'development')
```

You can get entities which have specific labels by specifying a parameter named `label_selector` (named `labelSelector` in Kubernetes server):

```ruby
pods = client.get_pods(label_selector: 'name=redis-master')
```

You can specify multiple labels (that option will return entities which have both labels:
```ruby
pods = client.get_pods(label_selector: 'name=redis-master,app=redis')
```

#### Get a specific instance of an entity (by name)
Such as: `get_service "service name"` , `get_pod "pod name"` , `get_replication_controller "rc name"`, `get_secret "secret name"`, `get_resource_quota "resource quota name"`, `get_limit_range "limit range name"` , `get_persistent_volume "persistent volume name"` , `get_persistent_volume_claim "persistent volume claim name"`, `get_component_status "component name"`

The GET request should include the namespace name, except for nodes and namespaces entities.

```ruby
node = client.get_node "127.0.0.1"
```

```ruby
service = client.get_service "guestbook", 'development'
```

Note - Kubernetes doesn't work with the uid, but rather with the 'name' property.
Querying with uid causes 404.

#### Delete an entity (by name)

For example: `delete_pod "pod name"` , `delete_replication_controller "rc name"`, `delete_node "node name"`, `delete_secret "secret name"`

Input parameter - name (string) specifying service name, pod name, replication controller name.
```ruby
client.delete_service "redis-service"
```

#### Create an entity
For example: `create_pod pod_object`, `create_replication_controller rc_obj`, `create_secret secret_object`, `create_resource_quota resource_quota_object`, `create_limit_range limit_range_object`, `create_persistent_volume persistent_volume_object`, `create_persistent_volume_claim persistent_volume_claim_object`

Input parameter - object of type `Service`, `Pod`, `ReplicationController`.

The below example is for v1

```ruby
service = Service.new
service.metadata = {}
service.metadata.name = "redis-master"
service.metadata.namespace = 'staging'
service.spec = {}
service.spec.ports = [{ 'port' => 6379,
                                'targetPort' => 'redis-server'
                              }]
service.spec.selector = {}
service.spec.selector.name = "redis"
service.spec.selector.role = "master"
service.metadata.labels = {}
service.metadata.labels.app = 'redis'
service.metadata.labels.role = 'slave'
client.create_service service`
```

#### Update an entity
For example: `update_pod`, `update_service`, `update_replication_controller`, `update_secret`, `update_resource_quota`, `update_limit_range`, `update_persistent_volume`, `update_persistent_volume_claim`

Input parameter - object of type `Pod`, `Service`, `ReplicationController` etc.

The below example is for v1

```ruby
client.update_service service1
```

#### Get all entities of all types : all_entities
Returns a hash with 13 keys (node, secret, service, pod, replication_controller, namespace, resource_quota, limit_range, endpoint, event, persistent_volume, persistent_volume_claim and component_status). Each key points to an EntityList of same type.
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

#### Get a proxy URL
You can get a complete URL for connecting a kubernetes entity via the proxy.

```ruby
client.proxy_url('service', 'srvname', 'srvportname', 'ns')
 => "https://localhost.localdomain:8443/api/v1/proxy/namespaces/ns/services/srvname:srvportname"
```

Note the third parameter, port, is a port name for services and an integer for pods:

```ruby
client.proxy_url('pod', 'podname', 5001, 'ns')
 => "https://localhost.localdomain:8443/api/v1/namespaces/ns/pods/podname:5001/proxy"
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
