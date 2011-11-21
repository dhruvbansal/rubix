module Rubix
  
  class Application < Model

    #
    # == Properties & Finding ==
    #

    def initialize properties={}
      super(properties)
      @name    = properties[:name]
      
      self.host_id = properties[:host_id]
      self.host    = properties[:host]
    end
    
    attr_accessor :name

    def self.find_request options={}
      request('application.get', 'hostids' => [options[:host_id]], 'filter' => {'name' => options[:name], 'applicationid' => options[:id]}, "output" => "extend")
    end

    def self.build app
      params = {
        :id   => app['applicationid'].to_i,
        :name => app['name']
      }

      # use the host id if available, else use the template id
      if app['hosts'] && app['hosts'].first && app['hosts'].first['hostid']
        params[:host_id] = app['hosts'].first['hostid'].to_i
      else
        params[:host_id] = app['templateid']
      end
      new(params)
    end
    
    def log_name
      "APP #{name || id}@#{host.name}"
    end

    def self.id_field
      'applicationid'
    end
    
    
    #
    # == Associations ==
    #

    include Associations::BelongsToHost
    
    #
    # == CRUD ==
    #
    
    def create_request
      request('application.create', 'name' => name, 'hostid' => host_id)
    end

    def update_request
      request('application.update', 'applicationid' => id, 'name' => name, 'hosts' => {'hostid' => host_id})
    end

    def destroy_request
      request('application.delete', [id])
    end
    
  end
end
