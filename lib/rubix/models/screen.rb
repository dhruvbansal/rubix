module Rubix
  class Screen < Model
    include Associations::HasManyScreenItems
    #
    # == Properties & Finding ==
    #

    def initialize properties={}
      super(properties)

      self.screen_items    = properties[:screen_items].map { |si| si.is_a?(ScreenItem) ? si : ScreenItem.new(si) } if properties[:screen_items]
    end

    zabbix_attr :name,   :required => true
    zabbix_attr :vsize,  :default => 1
    zabbix_attr :hsize,  :default => 1

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
        :name => name, :hsize => hsize, :vsize => vsize,
        :screenitems => self.screen_items.map { |si| si.create_params }
      }
    end

    def self.find_params options={}
      super().merge({
                      :selectScreenItems => 'refer',
                      :filter => {
                        :name   => options[:name],
                        id_field => options[:id]
                      }
                    })
    end

    def self.build app
      params = {
        :id   => app[id_field].to_i,
        :name => app['name'],
        :screen_items => (app['screenitems'] || []).map { |si| ScreenItem.build si }
      }
      new(params)
    end
  end
end

