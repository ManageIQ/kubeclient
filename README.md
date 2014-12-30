# Kubeclient

A Ruby client for Kubernetes REST api.
The client supports GET, POST, PUT, DELETE on pods, services and replication controllers.
Also, GET and DELETE is supported for nodes.
The client currently supports Kubernetes REST api version v1beta1.

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

Please note that all the properties in json objects
are converted to ruby style in the client (and converted back to k8s side
before sent to k8s).
So, containerPort on k8s side is container_port in the client.
resourceVersion --> resource_version

Initialize the client: <br>
`client = Kubeclient::Client.new 'http://localhost:8080/api/' , "v1beta1"`

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
Input parameter - object of type Service, Pod, ReplicationController
<br>
`service = Service.new` <br>
`service.id = "redis-master"`<br>
`service.port = 6379`<br>
`service.container_port  = "redis-server"`<br>
`service.selector = {}`<br>
`service.selector.name = "redis"`<br>
`service.selector.role = "master"`<br>
`client.create_service service`<br>
`<br>

5. Update entity (update pod, service, replication controller) <br>
Input parameter - object of type Service, Pod, ReplicationController <br>
`client.update_service rc1`

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