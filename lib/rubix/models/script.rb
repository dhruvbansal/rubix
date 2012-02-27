module Rubix
  
  class Script < Model

    # Numeric codes of the access types a script can require to run on
    # a host.
    #
    # Default is 'read'.
    zabbix_define :ACCESS, {
      :read  => 2,
      :write => 3
    }

    #
    # == Properties & Finding ==
    #

    zabbix_attr :name,    :required => true
    zabbix_attr :command, :required => true
    zabbix_attr :access,  :default => :read

    #
    # == Requests ==
    #

    def create_params
      {
        :name        => name,
        :command     => command,
        :host_access => self.class::ACCESS_CODES[access]
      }
    end

    def self.find_params options={}
      get_params.merge(:filter => {id_field => options[:id], :name => options[:name]})
    end

    def self.build script
      new({
            :id          => script[id_field].to_i,
            :name        => script['name'],
            :command     => script['command'],
            :access      => self::ACCESS_NAMES[script['host_access'].to_i]
          })
    end
    
  end
end
