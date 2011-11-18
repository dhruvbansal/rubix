module Rubix
  
  class Item < Model

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
    
    attr_accessor :host, :applications, :key, :description, :value_type

    def initialize properties={}
      super(properties)
      @host         = properties[:host]
      @key          = properties[:key]
      @description  = properties[:description]
      @value_type   = properties[:value_type]
      @applications = properties[:applications]
    end

    def log_name
      "ITEM #{key}@#{host.name}"
    end

    def params
      {
        :hostid       => host.id,
        :description  => (description || 'Unknown'),
        :type         => self.class::TRAPPER_TYPE,
        :key_         => key,
        :value_type   => self.class::VALUE_CODES[value_type],
      }.tap do |p|
        p[:applications] = applications.map(&:id) if applications
      end
    end

    def load
      response = request('item.get', 'host' => host.name, 'filter' => {'key_' => key, 'id' => id}, "output" => "extend")
      case
      when response.has_data?
        item = response.first
        @id          = item['itemid'].to_i
        @host        = Host.new(:id => item['hostid'])
        @description = item['description']
        @value_type  = self.class::VALUE_NAMES[item['value_type']] # it's actually a 'code' that's returned...
        @key         = item['key_']
        @exists      = true
        @loaded      = true
      when response.success?
        @exists = false
        @loaded = true
      else
        error("Could not load: #{response.error_message}")
      end
    end

    def create
      response = request('item.create', params)
      if response.has_data?
        @id     = response['itemids'].first.to_i
        @exists = true
        info("Created")
      else
        error("Could not create: #{response.error_message}.")
      end
    end

    def update
      # noop
      info("Updated")
    end

    def destroy
      response = request('item.delete', [id])
      case
      when response.has_data? && response['itemids'].first.to_i == id
        info("Deleted")
      when response.zabbix_error? && response.error_message =~ /does not exist/i
        # was never there...
      else
        error("Could not delete: #{response.error_message}.")
      end
    end

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
    
  end
end
