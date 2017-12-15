require 'recursive_open_struct'
module Kubeclient
  module Common
    # Represents an individual notice received from a Kubernetes watch
    class WatchNotice < RecursiveOpenStruct
      def initialize(hash = nil, args = {})
        args[:recurse_over_arrays] = true
        super(hash, args)
      end
    end
  end
end
