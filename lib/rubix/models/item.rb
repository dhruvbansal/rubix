module Rubix
  
  class Item < Model

    #
    # == Properties & Finding ==
    #

    # The numeric codes for the various item types.
    #
    # Items without a type will be set to 'trapper' so they can be
    # easily written to manually.
    TYPE_CODES = {
      :zabbix     => 0,
      :snmpv1     => 1,
      :trapper    => 2,
      :simple     => 3,
      :snmpv2c    => 4,
      :internal   => 5,
      :snmpv3     => 6,
      :active     => 7,
      :aggregate  => 8,
      :httptest   => 9,
      :external   => 10,
      :db_monitor => 11,
      :ipmi       => 12,
      :ssh        => 13,
      :telnet     => 14,
      :calculated => 15
    }.freeze
    TYPE_NAMES = TYPE_CODES.invert.freeze

    # The numeric codes for the value types of a Zabbix item.  This Hash
    # is used by ZabbixPipe#value_code_from_value to dynamically set the
    # type of a value when creating a new Zabbix item.
    VALUE_CODES = {
      :float        => 0,         # Numeric (float)
      :character    => 1,         # Character
      :log_line     => 2,         # Log
      :unsigned_int => 3,         # Numeric (unsigned)
      :text         => 4          # Text
    }.freeze
    VALUE_NAMES = VALUE_CODES.invert.freeze

    # Return the +value_type+ name (:float, :text, &c.) for a Zabbix
    # item's value type by examining the given +value+.
    def self.value_type_from_value value
      case
      when value =~ /\d+/       then :unsigned_int
      when value =~ /-?[\d\.]+/ then :float
      when value.include?("\n") then :text
      else :character
      end
    end

    # Return the +value_type+'s numeric code for a Zabbix item's value
    # type by examining the given +value+.
    def self.value_code_from_value value
      self::VALUE_CODES[value_type_from_value(value)]
    end
    
    attr_accessor :key, :description
    attr_writer :type, :value_type
    
    def initialize properties={}
      super(properties)
      @key            = properties[:key]
      @description    = properties[:description]
      @type           = properties[:type]
      
      self.value_type = properties[:value_type]

      self.host            = properties[:host]
      self.host_id         = properties[:host_id]

      self.template        = properties[:template]
      self.template_id     = properties[:template_id]
      
      self.applications    = properties[:applications]
      self.application_ids = properties[:application_ids]
    end

    def resource_name
      "#{self.class.resource_name} #{self.key || self.id}"
    end

    def value_type
      @value_type ||= :character
    end

    def type
      @type ||= :trapper
    end

    #
    # == Associations ==
    #

    include Associations::BelongsToHost
    include Associations::BelongsToTemplate
    include Associations::HasManyApplications

    #
    # == Requests == 
    #
    
    def create_params
      {
        :hostid       => host_id,
        :description  => (description || 'Unknown'),
        :type         => self.class::TYPE_CODES[type],
        :key_         => key,
        :value_type   => self.class::VALUE_CODES[value_type],
      }.tap do |p|
        p[:applications] = application_ids if application_ids
      end
    end

    def self.get_params
      super().merge(:select_applications => :refer)
    end
    
    def self.find_params options={}
      super().merge({
                      :hostids => [options[:host_id]],
                      :filter => {
                        :key_ => options[:key],
                        :id   => options[:id]
                      }
                    })
    end

    def self.build item
      new({
            :id              => item[id_field].to_i,
            :host_id         => item['hostid'].to_i,
            :description     => item['description'],
            :type            => TYPE_NAMES[item['type'].to_i],
            :value_type      => VALUE_NAMES[item['value_type'].to_i],
            :application_ids => (item['applications'] || []).map { |app| app['applicationid'].to_i },
            :key             => item['key_']
          })
    end
    
  end
end
