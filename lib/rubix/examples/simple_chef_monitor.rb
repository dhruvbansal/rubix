#!/usr/bin/env ruby

RUBIX_ROOT = File.expand_path('../../../../lib', __FILE__)
$: << RUBIX_ROOT unless $:.include?(RUBIX_ROOT)

require 'rubix'
require 'net/http'
require 'timeout'

class HttpAvailabilityMonitor < Rubix::Monitor

  include Rubix::ChefMonitor

  def chef_node
    begin
      @chef_node ||= chef_node_from_node_name(Chef::Config[:node_name])
    rescue => e
      puts "Could not find a Chef node named #{Chef::Config[:node_name]} -- are you sure your Chef settings are correct?"
    end
  end

  def measure
    begin
      timeout(1) do
        if Net::HTTP.get_response(URI.parse("http://#{chef_node['fqdn']}/")).code.to_i == 200
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
