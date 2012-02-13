module Rubix
  
  # A module that lets monitors talk to Chef servers.
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
  #   class WebserverMonitor < Rubix::Monitor
  #   
  #     include Rubix::ChefMonitor
  #     
  #     def measure
  #       webserver = chef_node_from_node_name('webserver')
  #       begin
  #         if Net::HTTP.get_response(URI.parse("http://#{webserver['ec2']['public_hostname']}")).code.to_i == 200
  #           write ['webserver.available', 1]
  #           return
  #         end
  #       rescue => e
  #       end
  #       write ['webserver.available', 0]
  #     end
  #   end
  #   
  #   WebserverMonitor.run if $0 == __FILE__
  module ChefMonitor

    def self.included klass
      klass.default_settings.tap do |s|
        s.define :chef_server_url, :description => "Chef server URL" ,                     :required => true, :default => 'http://localhost'
        s.define :chef_node_name,  :description => "Node name to identify to Chef server", :required => true, :default => ENV["HOSTNAME"]
        s.define :chef_client_key, :description => "Path to Chef client private key",      :required => true, :default => '/etc/chef/client.pem'
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

    def chef_node_from_ip ip
      return if ip.nil? || ip.empty?
      results = search_nodes("ipaddress:#{ip} OR fqdn:#{ip}")
      return unless results.first.size > 0
      results.first.first
    end

    def chef_node_name_from_ip ip
      node = chef_node_from_ip(ip)
      return node['node_name'] if node
    end
    
  end
end
