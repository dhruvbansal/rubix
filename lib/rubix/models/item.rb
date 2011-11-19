module Rubix
  
  class Item < Model

    #
    # == Properties & Finding ==
    #

    # The numeric code for a Zabbix item of type 'Zabbix trapper'.  The
    # item must have this type in order for the Zabbix server to listen
    # and accept data submitted by +zabbix_sender+.
    TRAPPER_TYPE = 2.freeze

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

    VALUE_NAMES = {
      0 => :float,              # Numeric (float)
      1 => :character,          # Character
      2 => :log_line,           # Log
      3 => :unsigned_int,       # Numeric (unsigned)
      4 => :text                # Text
    }.freeze

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
    
    attr_accessor :key, :description, :value_type

    def initialize properties={}
      super(properties)
      @key          = properties[:key]
      @description  = properties[:description]
      @value_type   = properties[:value_type]
      @applications = properties[:applications]

      self.host            = properties[:host]
      self.host_id         = properties[:host_id]
      self.applications    = properties[:applications]
      self.application_ids = properties[:application_ids]
    end

    def self.find_request options={}
      request('item.get', 'hostids' => [options[:host_id]], 'filter' => {'key_' => options[:key], 'id' => options[:id]}, "output" => "extend")
    end

    def self.build item
      new({
            :id          => item['itemid'].to_i,
            :host        => Host.new(:id => item['hostid']),
            :description => item['description'],
            :value_type  => self::VALUE_NAMES[item['value_type']], # it's actually a 'code' that's returned...
            :key         => item['key_']
          })
    end
    
    def log_name
      "ITEM #{key}@#{host.name}"
    end

    def self.id_field
      'itemid'
    end

    #
    # == Associations ==
    #

    include Associations::BelongsToHost
    include Associations::HasManyApplications

    #
    # == CRUD == 
    #
    
    def params
      {
        :hostid       => host_id,
        :description  => (description || 'Unknown'),
        :type         => self.class::TRAPPER_TYPE,
        :key_         => key,
        :value_type   => self.class::VALUE_CODES[value_type],
      }.tap do |p|
        p[:applications] = application_ids if application_ids
      end
    end
    
    def create_request
      request('item.create', params)
    end

    def update_request
      request('item.update', params.merge('itemid' => id))
    end

    def destroy_request
      request('item.delete', [id])
    end
    
  end
end
