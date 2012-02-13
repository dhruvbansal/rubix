#!/usr/bin/env ruby

RUBIX_ROOT = File.expand_path('../../../../lib', __FILE__)
$: << RUBIX_ROOT unless $:.include?(RUBIX_ROOT)

require 'rubix'
require 'open-uri'

class UptimeMonitor < Rubix::Monitor

  def measure
    return unless `uptime`.chomp =~ /(\d+) days.*(\d+) users.*load average: ([\d\.]+), ([\d\.]+), ([\d\.]+)/
    
    # can write one value at a time
    write ['uptime', $1.to_i]
    
    # or can use a block
    write do |data|
      # values can be arrays
      data << ['users', $2.to_i]
      # or hashes
      data << { :key => 'load15', :value => $3.to_i }
      data << { :key => 'load5',  :value => $4.to_i }
      # can even pass a different host
      data << { :key => 'load1',  :value => $5.to_i, :host => 'foobar-host' }
    end
  end
end

UptimeMonitor.run if $0 == __FILE__
