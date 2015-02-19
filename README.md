# Kubeclient

[![Gem Version](https://badge.fury.io/rb/kubeclient.svg)](http://badge.fury.io/rb/kubeclient)
[![Build Status](https://travis-ci.org/abonas/kubeclient.svg)](https://travis-ci.org/abonas/kubeclient)
[![Code Climate](http://img.shields.io/codeclimate/github/abonas/kubeclient.svg)](https://codeclimate.com/github/abonas/kubeclient)
[![Dependency Status](https://gemnasium.com/abonas/kubeclient.svg)](https://gemnasium.com/abonas/kubeclient)

A Ruby client for Kubernetes REST api.
The client supports GET, POST, PUT, DELETE on pods, services and replication controllers.
Also, GET and DELETE is supported for nodes.
The client currently supports Kubernetes REST api version v1beta1 and v1beta3.

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
`client = Kubeclient::Client.new 'http://localhost:8080/api/' , "v1beta1"`

or for the v3:

`client = Kubeclient::Client.new 'http://localhost:8080/api/' , "v1beta3"`

Examples:

1. Get all pods (and respectively: get_services, get_nodes, get_replication_controllers)
<br>
`pods = client.get_pods`
<br>

2. Get a specific node (and respectively: get_service "service id" , get_pod "pod id" , get_replication_controller "rc id" )
<br>
`node1 = client.get_node "127.0.0.1"`
<br>
Note - Kubernetes doesn't work with the uid, but rather with the 'id' property.
Querying with uid causes 404.

3. Delete a service (and respectively delete_pod "pod id" , delete_replication_controller "rc id", delete node "node id") <br>
Input parameter - id (string) specifying service id, pod id, replication controller id.
<br>
`client.delete_service "redis-service"`
<br>

4. Create a service (and respectively: create_pod pod_object, create_replication_controller rc_obj) <br>
Input parameter - object of type Service, Pod, ReplicationController. <br>
The below example is for v1beta1
<br>
`service = Service.new` <br>
`service.id = "redis-master"`<br>
`service.port = 6379`<br>
`service.containerPort  = "redis-server"`<br>
`service.selector = {}`<br>
`service.selector.name = "redis"`<br>
`service.selector.role = "master"`<br>
`client.create_service service`<br>
<br>

5. Update entity (update pod, service, replication controller) <br>
Input parameter - object of type Service, Pod, ReplicationController <br>
The below example is for v1beta1 <br>
`client.update_service service1`
<br>

6. Get all entities - Returns a hash with 4 keys (node, service,pod, replication_controller). Each key points to an EntityList of same type. This method
 is a convenience method instead of calling each entity's get method separately. <br>
`client.get_all_entities`

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
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Tests

This client is tested with Minitest.
Please run all tests before submitting a Pull Request, and add new tests for new functionality.

Running tests: <br>
`rake test`
