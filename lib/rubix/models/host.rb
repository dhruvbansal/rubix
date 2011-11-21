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

    def self.find_request options={}
      request('host.get', 'filter' => {'host' => options[:name], 'hostid' => options[:id]}, 'select_groups' => 'refer', 'selectParentTemplates' => 'refer', 'select_profile' => 'refer', 'select_macros' => 'extend', 'output' => 'extend')
    end

    def self.build host
      new({
            :id             => host['hostid'].to_i,
            :name           => host['host'],
            :host_group_ids => host['groups'].map { |group| group['groupid'].to_i },
            :template_ids   => host['parentTemplates'].map { |template| (template['templateid'] || template['hostid']).to_i },
            :user_macros    => host['macros'].map { |um| UserMacro.new(:host_id => um['hostid'].to_i, :id => um['hostmacroid'], :value => um['value'], :macro => um['macro']) },
            :profile        => host['profile'],
            :port           => host['port']
          })
    end
    
    def self.id_field
      'hostid'
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
    # == CRUD ==
    #

    def params
      {}.tap do |hp|
        hp['host']    = name
        
        hp['profile'] = profile if profile
        hp['status']  = status  if status
        
        if ip
          hp['ip']      = ip
          hp['useip']   = true
          hp['port']    = port || self.class::DEFAULT_PORT
        else
          hp['ip'] = self.class::BLANK_IP
        end
        
      end
    end
    
    def create_request
      request('host.create', params.merge('groups' => host_group_params, 'templates' => template_params, 'macros' => user_macro_params))
    end

    def update_request
      request('host.update', params.merge('hostid' => id))
    end

    def before_update
      response = request('host.massUpdate', { 'groups' => host_group_params, 'templates' => template_params, 'macros' => user_macro_params, 'hosts' => [{'hostid' => id}]})
      if response.has_data?
        true
      else
        error("Could not update all templates, host groups, and/or macros for #{resource_name}: #{response.error_message}")
        false
      end
    end
    
    def destroy_request
      request('host.delete', [{'hostid' => id}])
    end
    
  end
end
