module Rubix
  class Graph < Model
    #
    # == Properties & Finding ==
    #

    def initialize properties={}
      super(properties)
    end

    zabbix_attr :name,   :required => true
    zabbix_attr :width,  :required => true
    zabbix_attr :height, :required => true
    zabbix_attr :graph_items

    #
    # == Validation =
    #

    def validate
      raise ValidationError.new("A graph must have at least one graph item.") if graph_items.nil? || graph_items.empty?
      graph_items.each do |gi|
        raise ValidationError.new("A graph item must have item_id property.") unless gi[:item_id]
        raise ValidationError.new("A graph item must have color property.")   unless gi[:color]
      end
      true
    end

    #
    # == Requests ==
    #

    def create_params
      {
        :name => name, :height => height, :width => width
      }.tap do |cp|
        cp[:gitems] = graph_items.map { |gi| {:itemid => gi[:item_id], :color => gi[:color]}}
      end
    end

    def update_params
      { id_field => id, :name => name, :hosts => {:hostid => host_id}}
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

