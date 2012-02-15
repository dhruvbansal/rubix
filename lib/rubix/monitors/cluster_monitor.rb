module Rubix
  
  # A module for building monitors which measure items for several
  # hosts in a cluster as well as items for the cluster itself.
  #
  # This module assumes that an existing +hosts+ method returns an
  # Array of Zabbix hosts that can be grouped into clusters.
  #
  # Here's an example:
  #
  #   #!/usr/bin/env ruby
  #   
  #   class ClusterPingMonitor < Rubix::Monitor
  #
  #     include Rubix::ClusterMonitor
  #
  #     def measure_cluster cluster_name
  #       total_ping = 0.0
  #       num_hosts  = 0
  #       hosts_by_cluster[cluster_name].each do |host|
  #         total_ping += measure_host(host)
  #         num_hosts  += 1
  #       end
  #       write [cluster_name, 'average_ping', total_ping / num_hosts] unless num_hosts == 0
  #     end
  #
  #     def measure_host host
  #       ping = measure_ping_to(host.ip)
  #       write [host.name, 'ping', ping]
  #       ping # return this so the measure_cluster method can use it
  #     end
  #   end
  #   
  #   ClusterPingMonitor.run if $0 == __FILE__
  #
  # You may want to override the +cluster_name_from_host+ method.  By
  # defaul it assumes that hosts in Zabbix are named
  # 'cluster-facet-index', a la Ironfan.
  module ClusterMonitor

    # The name of the default cluster.
    DEFAULT_CLUSTER = 'All Hosts'

    attr_reader :hosts_by_cluster

    def default_cluster
      ::Rubix::ClusterMonitor::DEFAULT_CLUSTER
    end

    def initialize settings
      super(settings)
      @hosts_by_cluster = {}
      group_hosts_by_cluster
    end

    def measure
      clusters.each do |cluster_name|
        measure_cluster(cluster_name)
      end
    end

    def group_hosts_by_cluster
      hosts.each do |host|
        cluster_name = cluster_name_from_host(host)
        @hosts_by_cluster[cluster_name] ||= []
        @hosts_by_cluster[cluster_name] << host
      end
    end

    def cluster_name_from_host host
      return default_cluster if host.name.nil? || host.name.empty?
      parts = host.name.split("-")
      if parts.size == 3
        parts.first
      else
        default_cluster
      end
    end
    
    def clusters
      @hosts_by_cluster.keys
    end
    
  end
end
