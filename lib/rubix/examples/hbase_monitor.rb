#!/usr/bin/env ruby

RUBIX_ROOT = File.expand_path('../../../../lib', __FILE__)
$: << RUBIX_ROOT unless $:.include?(RUBIX_ROOT)

require 'rubix'
require 'net/http'
require 'crack'

class HBaseMonitor < Rubix::ClusterMonitor

  # Hostgroups for clusters & hosts that need to be created.
  CLUSTER_HOSTGROUPS = 'HBase clusters'

  # Templates for any hosts that need to be created.
  CLUSTER_TEMPLATES = 'Template_HBase_Cluster'
  NODE_TEMPLATES    = 'Template_HBase_Node'

  # Applications for items that are written
  CLUSTER_APPLICATIONS = '_cluster'
  NODE_APPLICATIONS    = "Hbase"

  def matching_chef_nodes
    Chef::Search::Query.new.search('node', 'provides_service:*hbase-stargate AND facet_name:alpha')
  end
  
  def measure_cluster cluster_name
    measured_cluster_status  = false
    private_ips_by_cluster[cluster_name].each do |private_ip|
      measured_cluster_status  = measure_cluster_status(cluster_name, private_ip)  unless measured_cluster_status
      break if measured_cluster_status
    end
  end

  # Measure the cluster health metrics -- /status/cluster
  def measure_cluster_status cluster_name, private_ip
    begin
      connection = Net::HTTP.new(private_ip, 8080) # FIXME port
      request    = Net::HTTP::Get.new('/status/cluster', 'Accept' => 'text/xml')
      response   = connection.request(request)
      return false unless response.code.to_i == 200
      
      data           = Crack::XML.parse(response.body)
      cluster_status = data['ClusterStatus']
      dead_nodes     = cluster_status['DeadNodes'] ? cluster_status['DeadNodes']['Node'] : []
      live_nodes     = cluster_status['LiveNodes']['Node']
    rescue NoMethodError, SocketError, REXML::ParseException, Errno::ECONNREFUSED => e
      # puts "#{e.class} -- #{e.message}"
      # puts e.backtrace
      return false
    end

    write({
            :hostname    => "#{cluster_name}-hbase",
            :hostgroup   => self.class::CLUSTER_HOSTGROUPS,
            :application => self.class::CLUSTER_APPLICATIONS,
            :templates   => self.class::CLUSTER_TEMPLATES
          }) do |d|
      d << ['requests',    cluster_status['requests']]
      d << ['regions',     cluster_status['regions']]
      d << ['load',        cluster_status['averageLoad']]
      d << ['nodes.dead',  dead_nodes.size]
      d << ['nodes.alive', live_nodes.size]
    end
    measure_cluster_tables(cluster_name, data)
    measure_cluster_nodes(cluster_name, live_nodes)
    true
  end

  def measure_cluster_tables cluster_name, data
    # FIXME...not sure how best to get information about "tables" in HBase...
  end

  def measure_cluster_nodes cluster_name, live_nodes
    live_nodes.each do |live_node|
      next unless live_node
      ip        = (live_node['name'] || '').split(':').first
      node_name = chef_node_name_from_ip(ip)
      next unless node_name
      write({
              :hostname    => node_name,
              :application => self.class::NODE_APPLICATIONS,
              :templates   => self.class::NODE_TEMPLATES
            }) do |d|
        d << ['hbase.regions',   (live_node['Region'] || []).size]
        d << ['hbase.heap_size', live_node['heapSizeMB']]
        d << ['hbase.requests',  live_node['requests']]
      end
    end
  end

end

HBaseMonitor.run if $0 == __FILE__
