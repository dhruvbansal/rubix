module Rubix
  
  # A generic monitor class for constructing Zabbix monitors that
  # monitor whole clusters.
  #
  # This class handles the low-level logic of finding a set of nodes and
  # then grouping them by cluster.
  #
  # It's still up to a subclass to determine how to make a measurement
  # on the cluster.
  #
  # Here's an example of a script which finds the average uptime of
  # nodes a value of 'bar' set for property 'foo', grouped by cluster.
  #
  #   #!/usr/bin/env ruby
  #   # in cluster_uptime_monitor
  #   
  #   class ClusterUptimeMonitor < Rubix::ClusterMonitor
  #   
  #     def node_query
  #       'role:nginx'
  #     end
  #     
  #     def measure_cluster cluster_name
  #       total_seconds = nodes_by_cluster[cluster_name].inject(0.0) do |sum, node|
  #         sum += node['uptime_seconds']
  #       end
  #       average_uptime = total_seconds.to_f / nodes_by_cluster[cluster_name].size.to_f
  #       write(:hostname => 'cluster_name') do |data|
  #         data << ['uptime.average', average_uptime]
  #       end
  #     end
  #   end
  #   
  #   ClusterUptimeMonitor.run if $0 == __FILE__
  #
  # See documentation for Rubix::Monitor to understand how to run this
  # script.
  class ClusterMonitor < ChefMonitor

    attr_reader :all_private_ips_by_cluster, :private_ips_by_cluster, :all_nodes_by_cluster, :nodes_by_cluster

    def initialize settings
      super(settings)
      group_nodes_by_cluster
    end

    def node_query
      ''
    end

    def matching_chef_nodes
      search_nodes(node_query)
    end

    def group_nodes_by_cluster
      @all_private_ips_by_cluster = {}
      @private_ips_by_cluster     = {}
      @all_nodes_by_cluster       = {}
      @nodes_by_cluster           = {}
      matching_chef_nodes.first.each do |node|
        @all_nodes_by_cluster[node['cluster_name']] ||= []
        @nodes_by_cluster[node['cluster_name']]     ||= []
        
        @all_nodes_by_cluster[node['cluster_name']] << node
        @nodes_by_cluster[node['cluster_name']]     << node unless %w[stopped].include?(node['state'])
        
        
        @all_private_ips_by_cluster[node['cluster_name']] ||= []
        @private_ips_by_cluster[node['cluster_name']]     ||= []
        
        @all_private_ips_by_cluster[node['cluster_name']] << node['ipaddress']
        @private_ips_by_cluster[node['cluster_name']]     << node['ipaddress'] unless %w[stopped].include?(node['state'])
      end
    end
    
    def clusters
      private_ips_by_cluster.keys
    end
    
    def measure
      clusters.each do |cluster_name|
        measure_cluster(cluster_name)
      end
    end

    def measure_cluster cluster_name
      raise NotImplementedError.new("Override the 'measure_cluster' method to make measurements of a given cluster.")
    end
    
  end

end
