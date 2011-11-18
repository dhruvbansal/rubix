module Rubix
  
  class Application < Model

    attr_accessor :name, :host

    def initialize properties={}
      super(properties)
      @name = properties[:name]
      @host = properties[:host]
    end

    def params
      {
        :name   => name,
        :hostid => host.id
      }
    end

    def log_name
      "APP #{name || id}@#{host.name}"
    end

    def load
      response = request('application.get', 'hostids' => [host.id], 'filter' => {'name' => name, 'id' => id}, "output" => "extend")
      case
      when response.has_data?
        app = response.first
        @id          = app['applicationid'].to_i
        @name        = app['name']
        @exists      = true
        @loaded      = true
      when response.success?
        @exists = false
        @loaded = true
      else
        error("Could not load: #{response.error_message}")
      end
    end

    def create
      response = request('application.create', params)
      if response.has_data?
        @id     = response['applicationids'].first.to_i
        @exists = true
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
      response = request('application.delete', [id])
      case
      when response.has_data? && response['applicationids'].first.to_i == id
        info("Deleted")
      when response.zabbix_error? && response.error_message =~ /does not exist/i
        # was never there...
      else
        error("Could not delete: #{response.error_message}.")
      end
    end

    def self.find_or_create_by_name_and_host name, host
      new(:name => name, :host => host).tap do |app|
        app.create unless app.exists?
      end
    end
    
  end
end
