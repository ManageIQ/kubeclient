require 'minitest/autorun'
require 'webmock/minitest'
require 'kubeclient/node'
require 'json'
require './lib/kubeclient'

# Watch entity tests
class WatchTest < MiniTest::Test
  def test_watch_pod_success
    expected = [
      { 'type' => 'ADDED', 'resourceVersion' => '1389' },
      { 'type' => 'MODIFIED', 'resourceVersion' => '1390' },
      { 'type' => 'DELETED', 'resourceVersion' => '1398' }
    ]

    stub_request(:get, %r{.*\/watch\/pods\?resourceVersion=1})
      .to_return(body: open_test_json_file('watch_stream_b3.json'),
                 status: 200)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta3'

    watch_enum = Enumerator.new do |x, y|
      client.watch(pod: 1) { |entity, notice| [x, y] << [entity, notice] }
    end

    watch_enum.with_index do |entity, notice, index|
      assert_equal(:pod, entity)
      assert_instance_of(WatchNotice, notice)
      assert_equal(expected[index]['type'], notice.type)
      assert_equal('Pod', notice.object.kind)
      assert_equal('php', notice.object.metadata.name)
      assert_equal(expected[index]['resourceVersion'],
                   notice.object.metadata.resourceVersion)
    end
  end

  def test_watch_pod_failure
    stub_request(:get, %r{.*\/watch\/pods\?resourceVersion=1})
      .to_return(status: 404)

    client = Kubeclient::Client.new 'http://localhost:8080/api/', 'v1beta3'
    exception = assert_raises(KubeException) do
      client.watch(pods: 1) do |_notice|
      end
    end
    assert_equal(404, exception.error_code)
  end
end
