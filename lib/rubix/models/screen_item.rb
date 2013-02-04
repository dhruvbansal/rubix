module Rubix
  class ScreenItem < Model

    zabbix_define :RESOURCE_TYPE, {
      :graph                    => 0,
      :simple_graph             => 1,
      :map                      => 2,
      :plain_text               => 3,
      :host_info                => 4,
      :trigger_info             => 5,
      :server_info              => 6,
      :clock                    => 7,
      :screen                   => 8,
      :trigger_overview         => 9,
      :data_overview            => 10,
      :url                      => 11,
      :action_history           => 12,
      :event_history            => 13,
      :hostgroup_trigger_status => 14,
      :system_status            => 15,
      :host_trigger_status      => 16
    }

    zabbix_define :H_ALIGN, {
      :center => 0,
      :left   => 1,
      :right  => 2
    }

    zabbix_define :V_ALIGN, {
      :middle => 0,
      :top    => 1,
      :bottom => 2
    }

    #
    # == Properties & Finding ==
    #

    def initialize properties={}
      super(properties)
    end

    zabbix_attr :colspan,       :required => true, :default => 1
    zabbix_attr :rowspan,       :required => true, :default => 1
    zabbix_attr :resource_id,   :required => true
    zabbix_attr :resource_type, :required => true
    zabbix_attr :screen_id,     :required => true
    zabbix_attr :dynamic,       :default => 0
    zabbix_attr :elements,      :default => 25
    zabbix_attr :halign,        :default => :center
    zabbix_attr :valign,        :default => :middle
    zabbix_attr :height,        :default => 200
    zabbix_attr :width,         :default => 320
    zabbix_attr :x,             :default => 0
    zabbix_attr :y,             :default => 0
    zabbix_attr :sort_triggers
    zabbix_attr :style
    zabbix_attr :url

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
        :colspan => colspan,
        :rowspan => rowspan,
        :resourceid => resource_id,
        :resourcetype => RESOURCE_TYPE_CODES[resource_type],
        :screenid => screen_id,
        :dynamic => dynamic,
        :elements => elements,
        :halign => H_ALIGN_CODES[halign],
        :valign => V_ALIGN_CODES[valign],
        :height => height,
        :width => width,
        :x => x,
        :y => y,
        :sort_triggers => sort_triggers,
        :style => style,
        :url => url
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

    def self.build params
      params = {
        :id   => params[id_field].to_i,
        :colspan => params["colspan"],
        :rowspan => params["rowspan"],
        :resource_id => params["resourceid"],
        :resource_type => RESOURCE_TYPE_NAMES[params["resourcetype"].to_i],
        :screen_id => params["screenid"],
        :dynamic => params["dynamic"],
        :elements => params["elements"],
        :halign => H_ALIGN_NAMES[params["halign"].to_i],
        :valign => V_ALIGN_NAMES[params["valign"].to_i],
        :height => params["height"],
        :width => params["width"],
        :x => params["x"],
        :y => params["y"],
        :sort_triggers => params["sort_triggers"],
        :style => params["style"],
        :url => params["url"]
      }
      new(params)
    end
  end
end

