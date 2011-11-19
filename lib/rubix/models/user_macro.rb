module Rubix
  
  class UserMacro < Model

    #
    # == Properties & Finding ==
    #
    
    attr_accessor :name, :value

    def initialize properties={}
      super(properties)
      @name  = properties[:name]
      @value = properties[:value]

      self.host    = properties[:host]
      self.host_id = properties[:host_id]
    end

    def self.find_request options={}
      request('usermacro.get', 'hostids' => [options[:host_id]], 'filter' => {'macro' => macro_name(options[:name])}, "output" => "extend")
    end

    def self.build macro
      new({
            :id      => macro['hostmacroid'].to_i,
            :name    => macro['macro'].gsub(/^\{\$/, '').gsub(/\}$/, '').upcase,
            :value   => macro['value'],
            :host_id => macro['hostid']
          })
    end
    
    def log_name
      "MACRO #{macro_name}@#{host.name}"
    end

    def self.macro_name name
      "{$#{name.upcase}}"
    end

    def macro_name
      self.class.macro_name(name)
    end
    
    def self.id_field
      'hostmacroid'
    end

    #
    # == Associations ==
    #
    
    include Associations::BelongsToHost

    #
    # == Validation ==
    #
    def validate
      raise ValidationError.new("A user macro must have both a 'name' and a 'value'") if name.nil? || name.strip.empty? || value.nil? || value.strip.empty?
    end
    
    #
    # == CRUD ==
    #
    
    def create_request
      request('usermacro.massAdd', 'macros' => [{'macro' => macro_name, 'value' => value}], 'hosts' => [{'hostid' => host_id}])
    end
    
    def update_request
      request('usermacro.massUpdate', 'macros' => [{'macro' => macro_name, 'value' => value}], 'hosts' => [{'hostid' => host_id}])
    end

    def destroy_request
      request('usermacro.massRemove', 'hostids' => [host_id], 'macros' => [macro_name])
    end
    
  end
end
