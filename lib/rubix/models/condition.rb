module Rubix
  
  class Condition < Model

    # Numeric codes for the operator to use to join conditions for
    # this action.  Default is 'and_or'.
    zabbix_define :JOIN, {
      :and_or => 0,
      :and    => 1,
      :or     => 2
    }
    
    # Numeric codes for the event source.
    zabbix_define :TYPE, {
      :host_group         => 0,
      :host               => 1,
      :trigger            => 2,
      :trigger_name       => 3,
      :trigger_severity   => 4,
      :trigger_value      => 5,
      :time_period        => 6,
      :dhost_ip           => 7,
      :dservice_type      => 8,
      :dservice_port      => 9,
      :dstatus            => 10,
      :duptime            => 11,
      :dvalue             => 12,
      :host_template      => 13,
      :event_acknowledged => 14,
      :application        => 15,
      :maintenance        => 16,
      :node               => 17,
      :drule              => 18,
      :dcheck             => 19,
      :proxy              => 20,
      :dobject            => 21,
      :host_name          => 22
    }

    # Numeric codes for the operator used to compare a condition's
    # type to its value.
    zabbix_define :OPERATOR, {
      :equal      => 0,
      :not_equal  => 1,
      :like       => 2,
      :not_like   => 3,
      :in         => 4,
      :gte        => 5,
      :lte        => 6,
      :not_in     => 7
    }

    #
    # == Properties & Finding ==
    #

    zabbix_attr :type,     :required => true
    zabbix_attr :operator, :required => true, :default => :equal
    zabbix_attr :value,    :required => true

    def initialize properties=nil
      if properties.is_a?(Array)
        raise ArgumentError.new("Must provide a condition type, operator, and value when initializing a condition with an array.") unless properties.size == 3
        super({
                :type     => properties[0],
                :operator => properties[1],
                :value    => properties[2]
              })
      else
        super(properties || {})
      end
    end
    
    #
    # == Requests ==
    #

    def create_params
      {
        :conditiontype => self.class::TYPE_CODES[type],
        :operator      => self.class::OPERATOR_CODES[operator],
        :value         => value.to_s
      }
    end

    def self.build condition
      new({
            :id       => condition[id_field].to_i,
            :type     => self::TYPE_NAMES[condition['conditiontype'].to_i],
            :operator => self::OPERATOR_NAMES[condition['operator'].to_i],
            :value    => condition['value'].to_s
          })
    end
    
  end
end
