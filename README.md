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

Initialize the client: <br>
`client = Kubeclient::Client.new 'http://localhost:8080/api/' , "v1beta3"`

Or without specifying version (it will be set by default to "v1beta3"

`client = Kubeclient::Client.new 'http://localhost:8080/api/' `

Another option is to initialize the client with URI object:

`uri = URI::HTTP.build(host: "somehostname", port: 8080)`
`client = Kubeclient::Client.new uri`


It is also possible to use https and configure ssl with:

`client = Kubeclient::Client.new 'https://localhost:8443/api/' , "v1beta3"`
`client.ssl_options(` <br>
`  client_cert: OpenSSL::X509::Certificate.new(File.read('/path/to/client.crt')),` <br>
`  client_key:  OpenSSL::PKey::RSA.new(File.read('/path/to/client.key')),` <br>
`  ca_file:     '/path/to/ca.crt', ` <br>
`  verify_ssl:  OpenSSL::SSL::VERIFY_PEER` <br>
`)` <br>

For testing and development purpose you can disable the ssl check with:

`client.ssl_options(verify_ssl: OpenSSL::SSL::VERIFY_NONE)`


Examples:

1. Get all pods (and respectively: get_services, get_nodes, get_replication_controllers)
<br>
`pods = client.get_pods`
<br>
You can get entities which have specific labels by specifying input parameter named `label-selector`: <br>
`pods = client.get_pods(label_selector: 'name=redis-master')` <br>
You can specify multiple labels and that returns entities which have both labels:  <br>
`pods = client.get_pods(label_selector: 'name=redis-master,app=redis')`

2. Get a specific node (and respectively: get_service "service name" , get_pod "pod name" , get_replication_controller "rc name" )
<br>
The GET request should include the namespace name, except for nodes and namespaces entities.
<br>
`node = client.get_node "127.0.0.1"`
<br>
`service = client.get_service "guestbook", 'development'`
<br>
Note - Kubernetes doesn't work with the uid, but rather with the 'name' property.
Querying with uid causes 404.

3. Delete a service (and respectively delete_pod "pod id" , delete_replication_controller "rc id", delete node "node id") <br>
Input parameter - id (string) specifying service id, pod id, replication controller id.
<br>
`client.delete_service "redis-service"`
<br>

4. Create a service (and respectively: create_pod pod_object, create_replication_controller rc_obj) <br>
Input parameter - object of type Service, Pod, ReplicationController. <br>
The below example is for v1beta3
<br>
`service = Service.new` <br>
`service.metadata.name = "redis-master"`<br>
`service.spec.port = 6379`<br>
`service.spec.containerPort  = "redis-server"`<br>
`service.spec.selector = {}`<br>
`service.spec.selector.name = "redis"`<br>
`service.spec.selector.role = "master"`<br>
`client.create_service service`<br>
<br>

5. Update entity (update pod, service, replication controller) <br>
Input parameter - object of type Service, Pod, ReplicationController <br>
The below example is for v1beta3 <br>
`client.update_service service1`
<br>

6. all_entities - Returns a hash with 7 keys (node, service, pod, replication_controller, namespace, endpoint and event). Each key points to an EntityList of same type. This method
 is a convenience method instead of calling each entity's get method separately. <br>
`client.all_entities`

7. Receive entity updates <br>
It is possible to receive live update notices watching the relevant entities:
<br>
`watcher = client.watch_pods` <br>
`watcher.each do |notice|` <br>
`  # process notice data` <br>
`end` <br>
It is possible to interrupt the watcher from another thread with:
<br>
`watcher.finish` <br>

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

Running tests: <br>
`rake test`
