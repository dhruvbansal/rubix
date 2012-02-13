#!/usr/bin/env ruby

RUBIX_ROOT = File.expand_path('../../../../lib', __FILE__)
$: << RUBIX_ROOT unless $:.include?(RUBIX_ROOT)

require 'rubix'
require 'net/http'
require 'timeout'

class HttpAvailabilityMonitor < Rubix::Monitor

  include Rubix::ZabbixMonitor
  include Rubix::ClusterMonitor  

  def host_group_name
    'Zabbix servers'
  end

  def measure_cluster cluster_name
    hosts_by_cluster[cluster_name].each do |host|
      measure_host(host)
    end
    write [cluster_name, 'something', 1]
  end
  
  def measure_host host
    begin
      timeout(1) do
        if Net::HTTP.get_response(URI.parse("http://#{host.ip}/")).code.to_i == 200
          write [host.name, 'webserver.available', 1]
          return
        end
      end
    rescue => e
      puts e.message
    end
    write [host.name, 'webserver.available', 0]
  end

end

HttpAvailabilityMonitor.run if $0 == __FILE__
