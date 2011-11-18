module Rubix
  # A generic monitor class for constructing Zabbix monitors that need
  # to talk to Chef servers.
  #
  # This class handles the low-level logic of connecting to Chef and
  # parsing results from searches.
  #
  # It's still up to a subclass to determine how to make a measurement.
  #
  # Here's an example of a script which checks the availibility of a web
  # server at the EC2 public hostname of the Chef node 'webserver'.
  #
  #   #!/usr/bin/env ruby
  #   # in webserver_monitor
  #   
  #   require 'net/http'
  #   
  #   class WebserverMonitor < Rubix::ChefMonitor
  #   
  #     def measure
  #       webserver = chef_node_from_node_name('webserver')
  #       begin
  #         if Net::HTTP.get_response(URI.parse("http://#{webserver['ec2']['public_hostname']}")).code.to_i == 200
  #           write do |data|
  #             data << ['webserver.available', 1]
  #           end
  #           return
  #         end
  #       rescue => e
  #       end
  #       write do |data|
  #         data << ([['webserver.available', 0]])
  #       end
  #     end
  #   end
  #   
  #   WebserverMonitor.run if $0 == __FILE__
  #
  # See documentation for Rubix::Monitor to understand how to run this
  # script.
  class ChefMonitor < Monitor

    def self.default_settings
      super().tap do |s|
        s.define :chef_server_url, :description => "Chef server URL" ,                     :required => true
        s.define :chef_node_name,  :description => "Node name to identify to Chef server", :required => true
        s.define :chef_client_key, :description => "Path to Chef client private key",      :required => true
      end
    end
    
    def initialize settings
      super(settings)
      set_chef_credentials
    end

    def set_chef_credentials
      require 'chef'
      Chef::Config[:chef_server_url] = settings[:chef_server_url]
      Chef::Config[:node_name]       = settings[:chef_node_name]
      Chef::Config[:client_key]      = settings[:chef_client_key]
    end

    def search_nodes *args
      Chef::Search::Query.new.search('node', *args)
    end

    def chef_node_from_node_name node_name
      return if node_name.nil? || node_name.empty?
      results = search_nodes("name:#{node_name}")
      return unless results.first.size > 0
      results.first.first
    end

    def chef_node_name_from_ip ip
      return if ip.nil? || ip.empty?
      results = search_nodes("ipaddress:#{ip} OR fqdn:#{ip}")
      return unless results.first.size > 0
      results.first.first['node_name']
    end
    
  end
end
