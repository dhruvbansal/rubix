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

    #
    # == Associations ==
    #

    include Associations::BelongsToHost

    #
    # == Requests ==
    #

    def create_params
      {:name => name, :hostid => host_id}
    end

    def update_params
      { id_field => id, :name => name, :hosts => {:hostid => host_id}}
    end

    def self.find_params options={}
      super().merge({
                      :hostids => [options[:host_id]],
                      :filter => {
                        :name   => options[:name],
                        id_field => options[:id]
                      }
                    })
    end

    def self.build app
      params = {
        :id   => app[id_field].to_i,
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

  end
end
