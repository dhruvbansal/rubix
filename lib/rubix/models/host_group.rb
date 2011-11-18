module Rubix
  
  class HostGroup < Model

    attr_accessor :name, :host_ids

    def initialize properties={}
      super(properties)
      @name = properties[:name]
    end

    def log_name
      "GROUP #{name || id}"
    end
    
    def load
      response = request('hostgroup.get', 'filter' => {'groupid' => id, 'name' => name}, 'select_hosts' => 'refer', 'output' => 'extend')
      case
      when response.has_data?
        @id       = response.first['groupid'].to_i
        @name     = response.first['name']
        @host_ids = response.first['hosts'].map { |host_info| host_info['hostid'].to_i }
        @exists   = true
        @loaded   = true
      when response.success?
        @exists = false
        @loaded = true
      else
        error("Could not load: #{response.error_message}")
      end
    end

    def create
      response = request('hostgroup.create', [{'name' => name}])
      if response.has_data?
        @id     = response['groupids'].first.to_i
        @exists = true
        @loaded = true
        info("Created")
      else
        error("Could not create: #{response.error_message}")
      end
    end

    def update
      # noop
      info("Updated")
    end

    def destroy
      response = request('hostgroup.delete', [{'groupid' => id}])
      case
      when response.has_data? && response['groupids'].first.to_i == id
        info("Deleted")
      when response.zabbix_error? && response.error_message =~ /does not exist/i
        # was never there...
      else
        error("Could not delete: #{response.error_message}.")
      end
    end

    def contains? host
      return unless exists?
      host_ids.include?(host.id)
    end

    def self.find_or_create_by_name name
      new(:name => name).tap do |group|
        group.create unless group.exists?
      end
    end
    
  end
end
