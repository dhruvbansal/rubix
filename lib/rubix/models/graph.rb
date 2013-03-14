module Rubix
  class Graph < Model
    include Associations::HasManyGraphItems
    #
    # == Properties & Finding ==
    #

    def initialize properties={}
      super(properties)
      self.graph_items = properties[:graph_items].map { |gi| gi.is_a?(GraphItem) ? gi : GraphItem.new(gi) } if properties[:graph_items]
    end

    zabbix_attr :name,   :required => true
    zabbix_attr :width,  :required => true
    zabbix_attr :height, :required => true

    #
    # == Validation =
    #

    def validate
      raise ValidationError.new("A graph must have at least one graph item.") if graph_items.nil? || graph_items.empty?
      graph_items.each do |gi|
        raise ValidationError.new("A graph item must have item_id property.") unless gi.item_id
        raise ValidationError.new("A graph item must have color property.")   unless gi.color
      end
      true
    end

    #
    # == Requests ==
    #

    def create_params
      {
        :name => name, :height => height, :width => width,
        :gitems => self.graph_items.map { |gi| gi.create_params }
      }
    end

    def update_params
      { id_field => id, :name => name, :hosts => {:hostid => host_id}}
    end

    def self.find_params options={}
      super().merge({
                      :selectGraphItems => 'extend',
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
        :graph_items => (app['gitems'] || []).map { |id, gi| GraphItem.build gi }
      }
      new(params)
    end
  end
end

