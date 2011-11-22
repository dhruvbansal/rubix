#!/usr/bin/env ruby

RUBIX_ROOT = File.expand_path('../../../../lib', __FILE__)
$: << RUBIX_ROOT unless $:.include?(RUBIX_ROOT)

require 'rubix'
require 'open-uri'

class ESMonitor < Rubix::ClusterMonitor

  # Hostgroup for any hosts that needs to be created.
  CLUSTER_HOSTGROUPS = 'Elasticsearch clusters'

  # Templates for any hosts that need to be created.
  CLUSTER_TEMPLATES = 'Template_Elasticsearch_Cluster'
  NODE_TEMPLATES    = 'Template_Elasticsearch_Node'
  
  # Applications for new items
  CLUSTER_APPLICATIONS = '_cluster'
  NODE_APPLICATIONS    = 'Elasticsearch'

  def node_query
    'provides_service:*-elasticsearch'
  end

  def es_url private_ip, *args
    "http://" + File.join(private_ip + ":9200", *args)
  end
  
  def measure_cluster cluster_name
    measured_cluster_health  = false
    measured_cluster_indices = false
    measured_cluster_nodes   = false
    private_ips_by_cluster[cluster_name].each do |private_ip|
      measured_cluster_health  = measure_cluster_health(cluster_name, private_ip)  unless measured_cluster_health
      measured_cluster_indices = measure_cluster_indices(cluster_name, private_ip) unless measured_cluster_indices
      measured_cluster_nodes   = measure_cluster_nodes(cluster_name, private_ip)   unless measured_cluster_nodes
      break if measured_cluster_health && measured_cluster_indices && measured_cluster_nodes
    end
  end

  # Measure the cluster health metrics -- /_cluster/health
  def measure_cluster_health cluster_name, private_ip
    begin
      cluster_health = JSON.parse(open(es_url(private_ip, '_cluster', 'health')).read)
    rescue SocketError, OpenURI::HTTPError, JSON::ParserError, Errno::ECONNREFUSED => e
      # This node may not be running a webnode...
      return false
    end
    write({
            :hostname    => "#{cluster_name}-elasticsearch",
            :hostgroup   => self.class::CLUSTER_HOSTGROUPS
            :templates   => self.class::CLUSTER_TEMPLATES,
            :application => self.class::CLUSTER_APPLICATIONS
          }) do |d|
      d << ['status',              cluster_health['status']               ]
      d << ['nodes.total',         cluster_health['number_of_nodes']      ]
      d << ['nodes.data',          cluster_health['number_of_data_nodes'] ]
      d << ['shards.active',       cluster_health['active_shards']        ]
      d << ['shards.relocating',   cluster_health['relocating_shards']    ]
      d << ['shards.unassigned',   cluster_health['unassigned_shards']    ]
      d << ['shards.initializing', cluster_health['initializing_shards']  ]
    end
    true
  end

  def measure_cluster_indices cluster_name, private_ip
    begin
      index_data = JSON.parse(open(es_url(private_ip, '_status')).read)
    rescue SocketError, OpenURI::HTTPError, JSON::ParserError, Errno::ECONNREFUSED => e
      # This node may not be running a webnode...
      return false
    end
    index_data['indices'].each_pair do |index_name, index_data|
      write({
              :hostname   => "#{cluster_name}-elasticsearch",
              :hostgroup  => self.class::CLUStER_HOSTGROUP,
              :templates  => self.class::CLUSTER_TEMPLATES,
              :appliation => index_name
            }) do |d|
        d << ["#{index_name}.size",           index_data["index"]["size_in_bytes"] ]
        d << ["#{index_name}.docs.num",       index_data["docs"]["num_docs"]       ]
        d << ["#{index_name}.docs.max",       index_data["docs"]["max_doc"]        ]
        d << ["#{index_name}.docs.deleted",   index_data["docs"]["deleted_docs"]   ]
        d << ["#{index_name}.operations",     index_data["translog"]["operations"] ]
        d << ["#{index_name}.merges.total",   index_data["merges"]["total"]        ]
        d << ["#{index_name}.merges.current", index_data["merges"]["current"]      ]
      end
    end
    true
  end

  def measure_cluster_nodes cluster_name, private_ip
    begin
      nodes_data       = JSON.parse(open(es_url(private_ip, '_cluster', 'nodes')).read)
      nodes_stats_data = JSON.parse(open(es_url(private_ip, '_cluster', 'nodes', 'stats')).read)
    rescue SocketError, OpenURI::HTTPError, JSON::ParserError, Errno::ECONNREFUSED => e
      # This node may not be running a webnode...
      return false
    end

    nodes_stats_data['nodes'].each_pair do |id, stats|

      ip        = nodes_data['nodes'][id]['network']['primary_interface']['address']
      node_name = chef_node_name_from_ip(ip)
      next unless node_name
      write({
              :hostname    => node_name,
              :templates   => self.class::NODE_TEMPLATES,
              :application => self.class::NODE_APPLICATIONS
            }) do |d|
        # concurrency
        d << ['es.jvm.threads.count',     stats['jvm']['threads']['count']                   ]

        # garbage collection
        d << ['es.jvm.gc.coll_time',      stats['jvm']['gc']['collection_time_in_millis']    ]
        d << ['es.jvm.gc.coll_count',     stats['jvm']['gc']['collection_count']             ]

        # memory
        d << ['es.jvm.mem.heap_used',     stats['jvm']['mem']['heap_used_in_bytes']          ]
        d << ['es.jvm.mem.non_heap_used', stats['jvm']['mem']['non_heap_used_in_bytes']      ]
        d << ['es.jvm.mem.heap_comm',     stats['jvm']['mem']['heap_committed_in_bytes']     ]
        d << ['es.jvm.mem.non_heap_comm', stats['jvm']['mem']['non_heap_committed_in_bytes'] ]

        # indices
        d << ['es.indices.size',          stats['indices']['size_in_bytes']                  ]
      end
    end
    true
  end

end

ESMonitor.run if $0 == __FILE__
