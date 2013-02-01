module Rubix
  class Screen < Model
    #
    # == Properties & Finding ==
    #

    def initialize properties={}
      super(properties)
    end

    zabbix_attr :name,   :required => true
    zabbix_attr :wsize,  :default => 1
    zabbix_attr :hsize,  :default => 1
    zabbix_attr :screen_items

    #
    # == Validation =
    #

    def validate
      true
    end

    #
    # == Requests ==
    #

    def create_params
      {
        :name => name, :hsize => hsize, :wsize => wsize
      }
    end

    def update_params
      super
    end

    def self.find_params options={}
      super().merge({
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
      new(params)
    end
  end
end

