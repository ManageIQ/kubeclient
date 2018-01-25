# Kubeclient

[![Gem Version](https://badge.fury.io/rb/kubeclient.svg)](http://badge.fury.io/rb/kubeclient)
[![Build Status](https://travis-ci.org/abonas/kubeclient.svg?branch=master)](https://travis-ci.org/abonas/kubeclient)
[![Code Climate](http://img.shields.io/codeclimate/github/abonas/kubeclient.svg)](https://codeclimate.com/github/abonas/kubeclient)
[![Dependency Status](https://gemnasium.com/abonas/kubeclient.svg)](https://gemnasium.com/abonas/kubeclient)

A Ruby client for Kubernetes REST api.
The client supports GET, POST, PUT, DELETE on all the entities available in kubernetes in both the core and group apis.
The client currently supports Kubernetes REST api version v1.
To learn more about groups and versions in kubernetes refer to [k8s docs](https://kubernetes.io/docs/api/)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kubeclient'
```

And then execute:

```Bash
bundle
```

Or install it yourself as:

```Bash
gem install kubeclient
```

## Usage

Initialize the client:

```ruby
client = Kubeclient::Client.new('http://localhost:8080/api/', "v1")
```

Or without specifying version (it will be set by default to "v1")

```ruby
client = Kubeclient::Client.new('http://localhost:8080/api/')
```

For A Group Api:

```ruby
client = Kubeclient::Client.new('http://localhost:8080/apis/batch', 'v1')
```

Another option is to initialize the client with URI object:

```ruby
uri = URI::HTTP.build(host: "somehostname", port: 8080)
client = Kubeclient::Client.new(uri)
```

### SSL

It is also possible to use https and configure ssl with:

```ruby
ssl_options = {
  client_cert: OpenSSL::X509::Certificate.new(File.read('/path/to/client.crt')),
  client_key:  OpenSSL::PKey::RSA.new(File.read('/path/to/client.key')),
  ca_file:     '/path/to/ca.crt',
  verify_ssl:  OpenSSL::SSL::VERIFY_PEER
}
client = Kubeclient::Client.new(
  'https://localhost:8443/api/', "v1", ssl_options: ssl_options
)
```

As an alternative to the `ca_file` it's possible to use the `cert_store`:

```ruby
cert_store = OpenSSL::X509::Store.new
cert_store.add_cert(OpenSSL::X509::Certificate.new(ca_cert_data))
ssl_options = {
  cert_store: cert_store,
  verify_ssl: OpenSSL::SSL::VERIFY_PEER
}
client = Kubeclient::Client.new(
  'https://localhost:8443/api/', "v1", ssl_options: ssl_options
)
```

For testing and development purpose you can disable the ssl check with:

```ruby
ssl_options = { verify_ssl: OpenSSL::SSL::VERIFY_NONE }
client = Kubeclient::Client.new(
  'https://localhost:8443/api/', 'v1', ssl_options: ssl_options
)
```

### Authentication

If you are using basic authentication or bearer tokens as described
[here](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/docs/authentication.md) then you can specify one
of the following:

```ruby
auth_options = {
  username: 'username',
  password: 'password'
}
client = Kubeclient::Client.new(
  'https://localhost:8443/api/', 'v1', auth_options: auth_options
)
```

or

```ruby
auth_options = {
  bearer_token: 'MDExMWJkMjItOWY1Ny00OGM5LWJlNDEtMjBiMzgxODkxYzYz'
}
client = Kubeclient::Client.new(
  'https://localhost:8443/api/', 'v1', auth_options: auth_options
)
```

or

```ruby
auth_options = {
  bearer_token_file: '/path/to/token_file'
}
client = Kubeclient::Client.new(
  'https://localhost:8443/api/', 'v1', auth_options: auth_options
)
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
client = Kubeclient::Client.new(
  'https://localhost:8443/api/', 'v1', auth_options: auth_options
)
```

You can find information about tokens in [this guide](http://kubernetes.io/docs/user-guide/accessing-the-cluster/) and in [this reference](http://kubernetes.io/docs/admin/authentication/).

### Non-blocking IO

You can also use kubeclient with non-blocking sockets such as Celluloid::IO, see [here](https://github.com/httprb/http/wiki/Parallel-requests-with-Celluloid%3A%3AIO)
for details. For example:

```ruby
require 'celluloid/io'
socket_options = {
  socket_class: Celluloid::IO::TCPSocket,
  ssl_socket_class: Celluloid::IO::SSLSocket
}
client = Kubeclient::Client.new(
  'https://localhost:8443/api/', 'v1', socket_options: socket_options
)
```

This affects only `.watch_*` sockets, not one-off actions like `.get_*`, `.delete_*` etc.

### Proxies

You can also use kubeclient with an http proxy server such as tinyproxy. It can be entered as a string or a URI object.
For example:
```ruby
proxy_uri = URI::HTTP.build(host: "myproxyhost", port: 8443)
client = Kubeclient::Client.new(
  'https://localhost:8443/api/', http_proxy_uri: proxy_uri
)
```


### Timeouts

Watching never times out.

One-off actions like `.get_*`, `.delete_*` have a configurable timeout:
```ruby
timeouts = {
  open: 10,  # unit is seconds
  read: nil  # nil means never time out
}
client = Kubeclient::Client.new(
  'https://localhost:8443/api/', timeouts: timeouts
)
```

Default timeouts match `Net::HTTP` and `RestClient`, which unfortunately depends on ruby version:
- open was infinite up to ruby 2.2, 60 seconds in 2.3+.
- read is 60 seconds.

If you want ruby-independent behavior, always specify `:open`.

### Discovery

Discovery from the kube-apiserver is done lazily on method calls so it would not change behavior.

It can also  be done explicitly:

```ruby
client = Kubeclient::Client.new('http://localhost:8080/api', 'v1')
client.discover
```

It is possible to check the status of discovery

```ruby
unless client.discovered
  client.discover
end
```

### Kubeclient::Config

If you've been using `kubectl` and have a `.kube/config` file, you can auto-populate a config object using `Kubeclient::Config`:

```ruby
config = Kubeclient::Config.read('/path/to/.kube/config')
```

...and then pass that object to `Kubeclient::Client`:

```
Kubeclient::Client.new(
  config.context.api_endpoint,
    config.context.api_version,
    {
      ssl_options: config.context.ssl_options,
      auth_options: config.context.auth_options
    }
)
```

You can also load your JSONified config in from an ENV variable (e.g. `KUBE_CONFIG`) like so:

```ruby
Kubeclient::Config.new(JSON.parse(ENV['KUBE_CONFIG']), nil)
```

###Supported kubernetes versions

For 1.1 only the core api v1 is supported, all api groups are supported in later versions.

## Examples:

#### Get all instances of a specific entity type
Such as: `get_pods`, `get_secrets`, `get_services`, `get_nodes`, `get_replication_controllers`, `get_resource_quotas`, `get_limit_ranges`, `get_persistent_volumes`, `get_persistent_volume_claims`, `get_component_statuses`, `get_service_accounts`

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
Such as: `get_service "service name"` , `get_pod "pod name"` , `get_replication_controller "rc name"`, `get_secret "secret name"`, `get_resource_quota "resource quota name"`, `get_limit_range "limit range name"` , `get_persistent_volume "persistent volume name"` , `get_persistent_volume_claim "persistent volume claim name"`, `get_component_status "component name"`, `get_service_account "service account name"`

The GET request should include the namespace name, except for nodes and namespaces entities.

```ruby
node = client.get_node "127.0.0.1"
```

```ruby
service = client.get_service "guestbook", 'development'
```

Note - Kubernetes doesn't work with the uid, but rather with the 'name' property.
Querying with uid causes 404.

#### Getting raw responses
By passing `as: :raw`, the response from the client is given as a string, which is the raw JSON body from openshift:

```ruby
pods = client.get_pods as: :raw
node = client.get_node "127.0.0.1", as: :raw
```

#### Delete an entity (by name)

For example: `delete_pod "pod name"` , `delete_replication_controller "rc name"`, `delete_node "node name"`, `delete_secret "secret name"`

Input parameter - name (string) specifying service name, pod name, replication controller name.

```ruby
client.delete_service("redis-service")
```

If you want to cascade delete, for example a deployment, you can use the `delete_options` parameter.

```ruby
deployment_name = 'redis-deployment'
namespace = 'default'
delete_options = Kubeclient::Resource.new(
    apiVersion: 'meta/v1',
    gracePeriodSeconds: 0,
    kind: 'DeleteOptions',
    propagationPolicy: 'Foreground' # Orphan, Foreground, or Background
)
client.delete_deployment(deployment_name, namespace, delete_options: delete_options)
```

#### Create an entity
For example: `create_pod pod_object`, `create_replication_controller rc_obj`, `create_secret secret_object`, `create_resource_quota resource_quota_object`, `create_limit_range limit_range_object`, `create_persistent_volume persistent_volume_object`, `create_persistent_volume_claim persistent_volume_claim_object`, `create_service_account service_account_object`

Input parameter - object of type `Service`, `Pod`, `ReplicationController`.

The below example is for v1

```ruby
service = Kubeclient::Resource.new
service.metadata = {}
service.metadata.name = "redis-master"
service.metadata.namespace = 'staging'
service.spec = {}
service.spec.ports = [{ 
  'port' => 6379,
  'targetPort' => 'redis-server'
}]
service.spec.selector = {}
service.spec.selector.name = "redis"
service.spec.selector.role = "master"
service.metadata.labels = {}
service.metadata.labels.app = 'redis'
service.metadata.labels.role = 'slave'
client.create_service(service)
```

#### Update an entity
For example: `update_pod`, `update_service`, `update_replication_controller`, `update_secret`, `update_resource_quota`, `update_limit_range`, `update_persistent_volume`, `update_persistent_volume_claim`, `update_service_account`

Input parameter - object of type `Pod`, `Service`, `ReplicationController` etc.

The below example is for v1

```ruby
client.update_service(service1)
```

#### Patch an entity (by name)
For example: `patch_pod`, `patch_service`, `patch_secret`, `patch_resource_quota`, `patch_persistent_volume`

Input parameters - name (string) specifying the entity name, patch (hash) to be applied to the resource, optional: namespace name (string)

The PATCH request should include the namespace name, except for nodes and namespaces entities.

The below example is for v1

```ruby
client.patch_pod("docker-registry", {metadata: {annotations: {key: 'value'}}}, "default")
```

#### Get all entities of all types : all_entities
Returns a hash with the following keys (node, secret, service, pod, replication_controller, namespace, resource_quota, limit_range, endpoint, event, persistent_volume, persistent_volume_claim, component_status and service_account). Each key points to an EntityList of same type.
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

Pass `as: :raw` to `watch_*` get raw replies.

#### Watch events for a particular object
You can use the `field_selector` option as part of the watch methods.

```ruby
watcher = client.watch_events(namespace: 'development', field_selector: 'involvedObject.name=redis-master')
watcher.each do |notice|
  # process notice date
end
```

#### Get a proxy URL
You can get a complete URL for connecting a kubernetes entity via the proxy.

```ruby
client.proxy_url('service', 'srvname', 'srvportname', 'ns')
# => "https://localhost.localdomain:8443/api/v1/proxy/namespaces/ns/services/srvname:srvportname"
```

Note the third parameter, port, is a port name for services and an integer for pods:

```ruby
client.proxy_url('pod', 'podname', 5001, 'ns')
# => "https://localhost.localdomain:8443/api/v1/namespaces/ns/pods/podname:5001/proxy"
```

#### Get the logs of a pod
You can get the logs of a running pod, specifying the name of the pod and the
namespace where the pod is running:

```ruby
client.get_pod_log('pod-name', 'default')
# => "Running...\nRunning...\nRunning...\n"
```

If that pod has more than one container, you must specify the container:

```ruby
client.get_pod_log('pod-name', 'default', container: 'ruby')
# => "..."
```

If a container in a pod terminates, a new container is started, and you want to
retrieve the logs of the dead container, you can pass in the `:previous` option:

```ruby
client.get_pod_log('pod-name', 'default', previous: true)
# => "..."
```

You can also watch the logs of a pod to get a stream of data:

```ruby
watcher = client.watch_pod_log('pod-name', 'default', container: 'ruby')
watcher.each do |line|
  puts line
end
```

#### Process a template
Returns a processed template containing a list of objects to create.
Input parameter - template (hash)
Besides its metadata, the template should include a list of objects to be processed and a list of parameters
to be substituted. Note that for a required parameter that does not provide a generated value, you must supply a value.

##### Note: This functionality is not supported by K8s at this moment. See the following [issue](https://github.com/kubernetes/kubernetes/issues/23896)

```ruby
client.process_template template
```

## Upgrading

#### past version 2.6

The gem raises Kubeclient::HttpError or subclasses now. Catching KubeException still works but is deprecated.

#### past version 1.2.0
Replace Specific Entity class references:

```ruby
Kubeclient::Service
```

with the generic

```ruby
Kubeclient::Resource.new
```

Where ever possible.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/kubeclient/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Test your changes with `rake test rubocop`, add new tests if needed.
4. If you added a new functionality, add it to README
5. Commit your changes (`git commit -am 'Add some feature'`)
6. Push to the branch (`git push origin my-new-feature`)
7. Create a new Pull Request

## Tests

This client is tested with Minitest and also uses VCR recordings in some tests.
Please run all tests before submitting a Pull Request, and add new tests for new functionality.

Running tests:
```ruby
rake test
```
