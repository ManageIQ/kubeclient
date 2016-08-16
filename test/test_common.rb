require 'test_helper'

# Unit tests for the common module
class CommonTest < MiniTest::Test
  def test_pluralize_entity
    %w(
      Pod Pods
      Service Services
      ReplicationController ReplicationControllers
      Node Nodes
      Event Events
      Endpoint Endpoints
      Namespace Namespaces
      Secret Secrets
      ResourceQuota ResourceQuotas
      LimitRange LimitRanges
      PersistentVolume PersistentVolumes
      PersistentVolumeClaim PersistentVolumeClaims
      ComponentStatus ComponentStatuses
      ServiceAccount ServiceAccounts
      Project Projects
      Route Routes
      ClusterRoleBinding ClusterRoleBindings
      Build Builds
      BuildConfig BuildConfigs
      Image Images
      ImageStream ImageStreams
    ).each_slice(2) do |singular, plural|
      assert_equal(Kubeclient::ClientMixin.pluralize_entity(singular), plural)
    end
  end

  def test_underscore_entity
    %w(
      Pod pod
      Service service
      ReplicationController replication_controller
      Node node
      Event event
      Endpoint endpoint
      Namespace namespace
      Secret secret
      ResourceQuota resource_quota
      LimitRange limit_range
      PersistentVolume persistent_volume
      PersistentVolumeClaim persistent_volume_claim
      ComponentStatus component_status
      ServiceAccount service_account
      Project project
      Route route
      ClusterRoleBinding cluster_role_binding
      Build build
      BuildConfig build_config
      Image image
      ImageStream image_stream
    ).each_slice(2) do |singular, plural|
      assert_equal(Kubeclient::ClientMixin.underscore_entity(singular), plural)
    end
  end
end
