module Rubix
  
  class UserMacro < Model

    #
    # == Properties & Finding ==
    #

    attr_reader :name
    def set_name n, validate=true
      return if n.nil? || n.empty?
      raise ValidationError.new("Cannot change the name of a UserMacro once it's created.") if validate && @name && (!new_record?)
      @name = n
    end
    
    zabbix_attr :value, :required => true
    
    def initialize properties={}
      super(properties)
      set_name(properties[:name]  || self.class.unmacro_name(properties[:macro]), false)
      
      self.host    = properties[:host]
      self.host_id = properties[:host_id]
    end

    def self.unmacro_name name
      (name || '').gsub(/^\{\$/, '').gsub(/\}$/, '').upcase
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

    def resource_name
      "#{self.class.resource_name} #{self.name || self.id}"
    end

    #
    # == Associations ==
    #
    
    include Associations::BelongsToHost

    #
    # == Requests ==
    #

    def create_params
      {:macro => macro_name, :value => value, :hostid => host_id}
    end

    def self.find_params options={}
      super().merge({
                      :hostids => [options[:host_id]],
                      :filter => {
                        :macro => macro_name(options[:name])
                      }
                    })
    end

    def self.build macro
      new({
            :id      => macro[id_field].to_i,
            :name    => unmacro_name(macro['macro']),
            :value   => macro['value'],
            :host_id => macro['hostid']
          })
    end
    
  end
end
