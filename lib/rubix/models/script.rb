module Rubix
  
  class Script < Model

    # Numeric codes of the access types a script can require to run on
    # a host.
    #
    # Default is 'read'.
    ACCESS_CODES = {
      :read  => 2,
      :write => 3
    }.freeze
    ACCESS_NAMES = ACCESS_CODES.invert.freeze

    #
    # == Properties & Finding ==
    #

    attr_accessor :name, :command
    
    attr_writer   :access
    def access
      @access ||= :read
    end
    
    def initialize properties={}
      super(properties)
      self.name    = properties[:name]
      self.command = properties[:command]
      self.access  = properties[:access]
    end

    #
    # == Validation == 
    #

    def validate
      raise ValidationError.new("A script must have a command.") if command.nil? || command.empty?
      true
    end
    
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
