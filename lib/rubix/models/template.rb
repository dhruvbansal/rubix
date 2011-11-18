module Rubix
  
  class Template < Model

    attr_accessor :name, :host_ids

    def initialize properties={}
      super(properties)
      @name = properties[:name]
    end

    def log_name
      "TEMPLATE #{name || id}"
    end

    def register
      exists? ? update : create
    end

    def unregister
      destroy if exists?
    end
    
    def load
      response = request('template.get', 'filter' => {'templateid' => id, 'name' => name}, 'select_hosts' => 'refer', 'output' => 'extend')
      case
      when response.has_data?
        @id       = response.first['templateid'].to_i
        @name     = response.first['name']
        @host_ids = response.first['hosts'].map { |host_info| host_info['hostid'].to_i }
        @loaded   = true
        @exists   = true
      when response.success?
        @exists = false
        @loaded = true
      else
        error("Could not load: #{response.error_messaage}")
      end
    end

    def create
      response = request('template.create', [{'name' => name}])
      if response.has_data?
        @id     = response['templateids'].first.to_i
        @exists = true
        info("Created")
      else
        error("Could not create: #{response.error_message}.")
      end
    end

    def update
      # noop
      info("Updated")
    end

    def destroy
      response = request('template.delete', [{'templateid' => id}])
      case
      when response.has_data? && response['templateids'].first.to_i == id
        info("Deleted")
      when response.zabbix_error? && response.error_message =~ /does not exist/i
        # was never there...
      else
        error("Could not delete: #{response.error_message}")
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
