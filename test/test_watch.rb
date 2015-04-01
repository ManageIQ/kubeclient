require 'test_helper'

# Watch entity tests
class TestWatch < MiniTest::Test
  def test_watch_pod_success
    expected = [
      { 'type' => 'ADDED', 'resourceVersion' => '1389' },
      { 'type' => 'MODIFIED', 'resourceVersion' => '1390' },
      { 'type' => 'DELETED', 'resourceVersion' => '1398' }
    ]

    stub_request(:get, %r{.*\/watch/pods})
      .to_return(body: open_test_json_file('watch_stream_b3.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta3'

    client.watch_pods.to_enum.with_index do |notice, index|
      assert_instance_of(Kubeclient::Common::WatchNotice, notice)
      assert_equal(expected[index]['type'], notice.type)
      assert_equal('Pod', notice.object.kind)
      assert_equal('php', notice.object.metadata.name)
      assert_equal(expected[index]['resourceVersion'],
                   notice.object.metadata.resourceVersion)
    end
  end

  def test_watch_pod_failure
    stub_request(:get, %r{.*\/watch/pods}).to_return(status: 404)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta3'
    assert_raises KubeException do
      client.watch_pods.each do
      end
    end
  end
end
