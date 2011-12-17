module Rubix

  class UserMacro < Model

    #
    # == Properties & Finding ==
    #

    attr_accessor :value

    def initialize properties={}
      super(properties)
      self.name  = properties[:name] || self.class.unmacro_name(properties[:macro])
      @value = properties[:value]

      self.host    = properties[:host]
      self.host_id = properties[:host_id]
    end

    attr_reader :name
    def name= n
      return if n.nil? || n.empty?
      raise ValidationError.new("Cannot change the name of a UserMacro once it's created.") if @name && (!new_record?)
      @name = n
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
    # == Validation ==
    #

    def validate
      raise ValidationError.new("A user macro must have both a 'name' and a 'value'") if name.nil? || name.strip.empty? || value.nil? || value.strip.empty?
      true
    end

    #
    # == Requests ==
    #

    def mass_add_params
      { :macros => [{:macro => macro_name, :value => value}], :hosts => [{:hostid => host_id}] }
    end

    def create_request
      request('usermacro.massAdd', mass_add_params)
    end

    def update_request
      request('usermacro.massUpdate', mass_add_params)
    end

    def destroy_request
      request('usermacro.massRemove', :hostids => [host_id], :macros => [macro_name])
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
