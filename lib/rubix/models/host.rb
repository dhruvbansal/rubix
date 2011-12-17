module Rubix

  class Host < Model

    #
    # == Properties & Finding ==
    #

    # The IP for a Host that not supposed to be polled by the Zabbix
    # server.
    BLANK_IP = '0.0.0.0'

    # The default port.
    DEFAULT_PORT = 10050

    attr_accessor :name, :ip, :port, :profile, :status

    def initialize properties={}
      super(properties)
      @name        = properties[:name]
      @ip          = properties[:ip]
      @port        = properties[:port]
      @profile     = properties[:profile]
      @status      = properties[:status]

      self.host_group_ids = properties[:host_group_ids]
      self.host_groups    = properties[:host_groups]

      self.template_ids   = properties[:template_ids]
      self.templates      = properties[:templates]

      self.user_macro_ids = properties[:user_macro_ids]
      self.user_macros    = properties[:user_macros]
    end

    #
    # == Associations ==
    #

    include Associations::HasManyHostGroups
    include Associations::HasManyTemplates
    include Associations::HasManyUserMacros

    #
    # == Validation ==
    #

    def validate
      raise ValidationError.new("A host must have at least one host group.") if host_group_ids.nil? || host_group_ids.empty?
      true
    end

    #
    # == Requests ==
    #

    def create_params
      {
        :host      => name,
        :groups    => host_group_params,
        :templates => template_params,
        :macros    => user_macro_params
      }.tap do |hp|
        hp[:profile] = profile if profile
        hp[:status]  = status  if status

        if ip
          hp[:ip]      = ip
          hp[:useip]   = true
          hp[:port]    = port || self.class::DEFAULT_PORT
        else
          hp[:ip] = self.class::BLANK_IP
        end
      end
    end

    def update_params
      create_params.tap do |cp|
        cp.delete(:groups)
        cp.delete(:templates)
        cp.delete(:macros)
        cp[id_field] = id
      end
    end

    def before_update
      response = request('host.massUpdate', { :groups => host_group_params, :templates => template_params, :macros => user_macro_params, :hosts => [{id_field => id}]})
      if response.has_data?
        true
      else
        error("Could not update all templates, host groups, and/or macros for #{resource_name}: #{response.error_message}")
        false
      end
    end

    def destroy_params
      [{id_field => id}]
    end

    def before_destroy
      return true if user_macros.nil? || user_macros.empty?
      user_macros.map { |um| um.destroy }.all?
    end

    def self.build host
      new({
            :id             => host[id_field].to_i,
            :name           => host['host'],
            :host_group_ids => host['groups'].map { |group| group['groupid'].to_i },
            :template_ids   => host['parentTemplates'].map { |template| (template['templateid'] || template[id_field]).to_i },
            :user_macros    => host['macros'].map { |um| UserMacro.new(:host_id => um[id_field].to_i, :id => um['hostmacroid'], :value => um['value'], :macro => um['macro']) },
            :profile        => host['profile'],
            :port           => host['port']
          })
    end

    def self.get_params
      super().merge({:select_groups => :refer, :selectParentTemplates => :refer, :select_profile => :refer, :select_macros => :extend})
    end

    def self.find_params options={}
      get_params.merge(:filter => {:host => options[:name], id_field => options[:id]})
    end

  end
end
