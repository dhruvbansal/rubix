module Rubix
  class GraphItem < Model

    def self.id_field
      'gitemid'
    end

    zabbix_define :CALC_FUNC, {
      :minimum => 1,
      :average => 2,
      :maximum => 4,
      :last    => 9
    }

    zabbix_define :DRAW_TYPE, {
      :line     => 0,
      :region   => 1,
      :bold     => 2,
      :dot      => 3,
      :dashed   => 4,
      :gradient => 5
    }

    zabbix_define :Y_AXIS_SIDE, {
      :left     => 0,
      :right    => 1
    }

    #
    # == Properties & Finding ==
    #

    def initialize properties={}
      super(properties)
    end

    zabbix_attr :color,         :required => true
    zabbix_attr :item_id,       :required => true
    zabbix_attr :calc_func,     :default => :average
    zabbix_attr :draw_type,     :default => :line
    zabbix_attr :graph_id
    zabbix_attr :sort_order
    zabbix_attr :type,          :default => 0
    zabbix_attr :y_axis_side,   :default => :left

    #
    # == Validation =
    #

    def validate
      super
      true
    end

    #
    # == Requests ==
    #

    def create_params
      {
        :color     => color,
        :itemid    => item_id,
        :calc_fnc  => CALC_FUNC_CODES[calc_func],
        :drawtype  => DRAW_TYPE_CODES[draw_type],
        :type      => type,
        :yaxisside => Y_AXIS_SIDE_CODES[y_axis_side]
      }
    end

    def self.build params
      params = {
        :id   => params[id_field].to_i,
        :color => params["color"],
        :item_id => params["itemid"],
        :calc_func => CALC_FUNC_NAMES[params["calc_fnc"].to_i],
        :draw_type => DRAW_TYPE_NAMES[params["drawtype"].to_i],
        :graph_id => params["graphid"],
        :sort_order => params["sortorder"],
        :type => params["type"],
        :y_axis_side => Y_AXIS_SIDE_NAMES[params["yaxisside"].to_i]
      }
      new(params)
    end
  end
end

