require_relative 'test_helper'

class TestWatchNotice < MiniTest::Test
  #
  # Checks that elements of arrays are converted to instances of `RecursiveOpenStruct`, and that the
  # items can be accessed using the dot notation.
  #
  def test_recurse_over_arrays
    json = JSON.parse(open_test_file('node_notice.json').read)
    notice = Kubeclient::Common::WatchNotice.new(json)
    assert_kind_of(Array, notice.object.status.addresses)
    notice.object.status.addresses.each do |address|
      assert_kind_of(RecursiveOpenStruct, address)
    end
    assert_equal('InternalIP', notice.object.status.addresses[0].type)
    assert_equal('192.168.122.40', notice.object.status.addresses[0].address)
    assert_equal('Hostname', notice.object.status.addresses[1].type)
    assert_equal('openshift.local', notice.object.status.addresses[1].address)
  end

  #
  # Checks that even when arrays are converted to instances of `RecursiveOpenStruct` the items can
  # be accessed using the hash notation.
  #
  def test_access_array_items_as_hash
    json = JSON.parse(open_test_file('node_notice.json').read)
    notice = Kubeclient::Common::WatchNotice.new(json)
    assert_kind_of(Array, notice.object.status.addresses)
    notice.object.status.addresses.each do |address|
      assert_kind_of(RecursiveOpenStruct, address)
    end
    assert_equal('InternalIP', notice.object.status.addresses[0]['type'])
    assert_equal('192.168.122.40', notice.object.status.addresses[0]['address'])
    assert_equal('Hostname', notice.object.status.addresses[1]['type'])
    assert_equal('openshift.local', notice.object.status.addresses[1]['address'])
  end
end
