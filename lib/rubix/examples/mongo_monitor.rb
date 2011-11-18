#!/usr/bin/env ruby

require 'zabbix_cluster_monitor'
require 'open-uri'
require 'set'
require 'mongo'

class MongoMonitor < ZabbixClusterMonitor
  
  # Hostgroup for any hosts that needs to be created.
  HOSTGROUP = 'MongoDB clusters'

  # Templates for any hosts that need to be created.
  TEMPLATES = 'Template_MongoDB'

  # Names of database to ignore when we find them.
  IGNORED_DATABASES = %w[db test admin local].to_set

  def matching_chef_nodes
    Chef::Search::Query.new.search('node', 'provides_service:*-mongodb-server')
  end
  
  def measure_cluster cluster_name
    measured_mongo_server    = false
    measured_mongo_databases = false
    private_ips_by_cluster[cluster_name].each do |private_ip|
      begin
        connection = Mongo::Connection.new(private_ip)
      rescue Mongo::ConnectionFailure => e
        next
      end
      measured_mongo_server    = measure_mongo_server(cluster_name, connection)    unless measured_mongo_server
      measured_mongo_databases = measure_mongo_databases(cluster_name, connection) unless measured_mongo_databases
      break if measured_mongo_server && measured_mongo_databases
    end
  end

  def measure_mongo_server cluster_name, connection
    initial = nil, final = nil
    db       = connection.db('system') # the name of this db doesn't matter?
    command = {:serverStatus => true}  # the value of the 'serverStatus' key doesn't matter?

    # gather metrics with a 1.0 second gap
    initial = db.command(command) ; sleep 1.0 ; final = db.command(command)
    return false unless initial && final
    dt = final['localTime'].to_f - initial['localTime'].to_f

    write({
             :hostname    => "#{cluster_name}-mongodb",
             :application => '_cluster',
             :hostgroup   => self.class::HOSTGROUP,
             :templates   => self.class::TEMPLATES
           }) do |d|
      
      # operations
      d << ['inserts',       (final['opcounters']['insert']  - initial['opcounters']['insert'])  / dt]
      d << ['queries',       (final['opcounters']['query']   - initial['opcounters']['query'])   / dt]
      d << ['updates',       (final['opcounters']['update']  - initial['opcounters']['update'])  / dt]
      d << ['deletes',       (final['opcounters']['delete']  - initial['opcounters']['delete'])  / dt]
      d << ['getmores',      (final['opcounters']['getmore'] - initial['opcounters']['getmore']) / dt]
      d << ['commands',      (final['opcounters']['command'] - initial['opcounters']['command']) / dt]

      # memory
      d << ['mem.resident',  final['mem']['resident']]
      d << ['mem.virtual',   final['mem']['virtual']]
      d << ['mem.mapped',    final['mem']['mapped']]

      # disk
      d << ['flushes',       (final['backgroundFlushing']['flushes']  - initial['backgroundFlushing']['flushes'])  / dt]
      d << ['flush_time',    (final['backgroundFlushing']['total_ms'] - initial['backgroundFlushing']['total_ms'])     ]
      d << ['faults',        (final['extra_info']['page_faults']      - initial['extra_info']['page_faults'])      / dt]

      # index
      d << ['accesses',        (final['indexCounters']['btree']['accesses'] - initial['indexCounters']['btree']['accesses']) / dt]
      d << ['hits',            (final['indexCounters']['btree']['hits']     - initial['indexCounters']['btree']['hits'])     / dt]
      d << ['misses',          (final['indexCounters']['btree']['misses']   - initial['indexCounters']['btree']['misses'])   / dt]
      d << ['resets',          (final['indexCounters']['btree']['resets']   - initial['indexCounters']['btree']['resets'])   / dt]

      # read/write load
      d << ['queue.total',   final['globalLock']['currentQueue']['total']]
      d << ['queue.read',    final['globalLock']['currentQueue']['readers']]
      d << ['queue.write',   final['globalLock']['currentQueue']['writers']]
      d << ['clients.total', final['globalLock']['activeClients']['total']]
      d << ['clients.read',  final['globalLock']['activeClients']['readers']]
      d << ['clients.write', final['globalLock']['activeClients']['writers']]

      # network
      d << ['net.in',        (final['network']['bytesIn']     - initial['network']['bytesIn'])     / dt]
      d << ['net.out',       (final['network']['bytesOut']    - initial['network']['bytesOut'])    / dt]
      d << ['requests',      (final['network']['numRequests'] - initial['network']['numRequests']) / dt]
      d << ['connections',   final['connections']['current']]
    end
    true
  end

  def measure_mongo_databases cluster_name, connection
    dbs = connection.database_names
    return true if dbs.size == 0 # nothing to do here

    dbs.each do |database_name|
      next if self.class::IGNORED_DATABASES.include?(database_name.downcase)
      stats = connection.db(database_name).stats()

      write({
               :hostname    => "#{cluster_name}-mongodb",
               :application => database_name,
               :hostgroup   => self.class::HOSTGROUP,
               :templates   => self.class::TEMPLATES
             }) do |d|
        d << ["#{database_name}.collections",      stats["collections"] ]
        d << ["#{database_name}.objects.count",    stats["objects"]     ]
        d << ["#{database_name}.objects.avg_size", stats["avgObjSize"]  ]
        d << ["#{database_name}.size.data",        stats["dataSize"]    ]
        d << ["#{database_name}.size.disk",        stats["storageSize"] ]
        d << ["#{database_name}.size.indexes",     stats["indexSize"]   ]
        d << ["#{database_name}.size.file",        stats["fileSize"]    ]
        d << ["#{database_name}.extents",          stats["numExtents"]  ]
        d << ["#{database_name}.indexes",          stats["indexes"]     ]
      end
    end
    true
  end
end

MongoMonitor.run if $0 == __FILE__
