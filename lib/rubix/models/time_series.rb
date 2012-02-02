module Rubix
  
  class TimeSeries < Model

    #
    # == Properties & Finding ==
    #

    attr_writer   :from, :upto
    attr_writer   :raw_data
    
    def initialize properties={}
      super(properties)
      @from       = properties[:from]
      @upto       = properties[:upto]
      
      self.item    = properties[:item]
      self.item_id = properties[:item_id]
    end

    def self.zabbix_name
      'history'
    end

    def self.default_from
      (Time.now - 3600).utc
    end

    def from
      @from ||= self.class.default_from
    end

    def self.default_upto
      Time.now.utc
    end

    def upto
      @upto ||= self.class.default_upto
    end

    def raw_data
      @raw_data ||= []
    end

    #
    # == Associations ==
    #

    include Associations::BelongsToItem

    #
    # == Requests == 
    #
    
    def self.get_params
      super().merge(:output => :extend)
    end
    
    def self.find_params options={}
      super().merge({
                      :itemids => [options[:item_id].to_s],
                      :time_from => (options[:from] || default_from).to_i.to_s,
                      :time_till => (options[:upto] || default_upto).to_i.to_s
                    })
    end

    def self.find options={}
      response = find_request(options)
      case
      when response.success?
        new(options.merge(:raw_data => response.result))
      else
        error("Error finding #{resource_name} using #{options.inspect}: #{response.error_message}")
      end
    end

    #
    # == Transformations ==
    #
    
    def parsed_data
      return @parsed_data if @parsed_data
      caster = case
               when item.nil?                        then nil
               when item.value_type == :float        then :to_f
               when item.value_type == :unsigned_int then :to_i
               end
      @parsed_data = raw_data.map do |point|
        next unless point.is_a?(Hash) && point['clock'] && point['value']
        timestamp = point['clock'].to_i
        next if timestamp == 0
        {
          'time'  => Time.at(timestamp),
          'value' => (caster ? point['value'].send(caster) : point['value'])
        }
      end.compact
    end
    
  end
end
