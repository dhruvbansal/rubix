module Rubix
  
  # A module for finding hosts for a monitor from Zabbix templates or
  # host groups.
  #
  # Here's an example of a monitor which makes a measurement of all
  # hosts with +Template_Foo+ by making a web request to the physical
  # host.
  #
  #   #!/usr/bin/env ruby
  #   # in cluster_uptime_monitor
  #   
  #   class FooMonitor < Rubix::Monitor
  #
  #     include Rubix::ZabbixMonitor
  #
  #     # Define either 'template' or 'host_group' to select hosts (or
  #     # define 'hosts').
  #     def template
  #       'Template_Foo'
  #     end
  #     
  #     def measure
  #       self.hosts.each do |host|
  #         measure_host(host)
  #       end
  #     end
  #
  #     def measure_host host
  #       ...
  #     end
  #   
  #   FooMonitor.run if $0 == __FILE__
  module ZabbixMonitor

    def self.included klass
      klass.default_settings.tap do |s|
        s.define :zabbix_api_url, :description => "Zabbix API URL" ,         :required => true, :default => 'http://localhost/api_jsonrpc.php'
        s.define :username,       :description => "Username for Zabbix API", :required => true, :default => 'admin'
        s.define :password,       :description => "Password for Zabbix API", :required => true, :default => 'zabbix'
      end
    end
    
    def connect_to_zabbix
      Rubix.connect(settings[:zabbix_api_url], settings[:username], settings[:password])
    end
    
    def template_name
    end

    def host_group_name
    end
    
    def hosts
      connect_to_zabbix
      case
      when template_name
        template = Rubix::Template.find(:name => template_name)
        Rubix::Host.list(template.host_ids).find_all(&:monitored)
      when host_group_name
        host_group = Rubix::HostGroup.find(:name => host_group_name)
        Rubix::Host.list(host_group.host_ids).find_all(&:monitored)
      else
        raise Rubix::Error.new("Must define either a 'template_name' or a 'host_group_name' property for a Zabbix monitor.")
      end
    end
  end
end
