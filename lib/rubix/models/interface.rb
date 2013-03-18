module Rubix
  
  class Interface < Model

    # Numeric codes for the interface's type.
    zabbix_define :TYPE, {
      :agent     => 1,
      :snmp      => 2,
      :ipmi      => 3,
      :jmx       => 4
    }

    #
    # == Properties & Finding ==
    #

    zabbix_attr :type,   :default => :agent, :required => true
    zabbix_attr :dns,    :default => ""
    zabbix_attr :ip,     :default => ""
    zabbix_attr :main,   :default => true,   :required => true
    zabbix_attr :port,   :default => 10050,  :required => true
    zabbix_attr :use_ip, :default => true,   :required => true

    def initialize properties={}
      super(properties)
      puts "PROPS: #{self.class.properties.inspect}"
      puts "GIVEN #{properties.inspect}"
      puts "I BECAME : #{self.inspect}"
      self.host_id       = properties[:host_id]
      self.host          = properties[:host]
    end

    #
    # == Associations ==
    #

    include Associations::BelongsToHost

    #
    # == Validation == 
    #

    def validate
      raise ValidationError.new("An interface must have a host") unless host_id || host
      raise ValidationError.new("Either an IP address or a DNS name must be set") if (ip.nil? || ip.empty?) && (dns.nil? || dns.empty?)
    end
    
    #
    # == Requests ==
    #

    def find_params options={}
      super().tap do |params|
        params[:hostids] = [options[:host_ids]].flatten if options[:host_ids]
        params[:hostids] = [options[:hosts]].flatten.map(&:id) if options[:hosts]
      end
    end

    def create_params
      {
        :dns           => dns,
        :ip            => ip,
        :useip         => (use_ip ? 1 : 0),
        :main          => (main ? 1 : 0),
        :port          => port,
        :type          => self.class::TYPE_CODES[type]
      }
    end

    def self.build interface
      new({
            :id                  => interface[id_field].to_i,
            :host_id             => interface['hostid'],
            :main                => (interface['main'].to_i  == 1),
            :type                => self::TYPE_NAMES[interface['type'].to_i],
            :use_ip              => interface['useip'],
            :dns                 => interface['dns'],
            :ip                  => interface['ip'],
          })
    end
    
  end
end
