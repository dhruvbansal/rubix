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

    # The numeric codes for the various status types.
    zabbix_define :STATUS, {
      :monitored     => 0,
      :not_monitored => 1,
      :unreachable   => 2,
      :template      => 3,
      :deleted       => 4,
      :proxy_active  => 5,
      :proxy_passive => 6
    }

    zabbix_attr :name
    zabbix_attr :ip
    zabbix_attr :port
    zabbix_attr :profile
    zabbix_attr :dns
    zabbix_attr :status
    zabbix_attr :use_ip,    :default => true
    zabbix_attr :monitored, :default => true
    
    def initialize properties={}
      super(properties)

      self.host_group_ids = properties[:host_group_ids]
      self.host_groups    = properties[:host_groups]

      self.template_ids   = properties[:template_ids]
      self.templates      = properties[:templates]

      self.user_macro_ids = properties[:user_macro_ids]
      self.user_macros    = properties[:user_macros]
    end

    def use_ip
      return @use_ip if (!@use_ip.nil?)
      @use_ip = true
    end

    def monitored
      return @monitored if (!@monitored.nil?)
      @monitored = true
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
        hp[:status]  = (monitored ? 0 : 1) unless monitored.nil?
        
        case
        when use_ip == true && (!ip.nil?) && (!ip.empty?)
          hp[:useip] = 1
          hp[:ip]    = ip
          hp[:port]  = port || self.class::DEFAULT_PORT
        when (!dns.nil?) && (!dns.empty?)
          hp[:useip] = 0
          hp[:dns]   = dns
          hp[:port]  = port || self.class::DEFAULT_PORT
        else
          hp[:ip] = self.class::BLANK_IP
          hp[:useip] = 1
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
            :port           => host['port'],
            :ip             => host['ip'],
            :dns            => host['dns'],
            :use_ip         => (host['useip'].to_i  == '1'),

            # If the status is '1' then this is an unmonitored host.
            # Otherwise it's either '0' for monitored and ok or
            # something else for monitored and *not* ok.
            :monitored      => (host['status'].to_i == 1 ? false : true),
            :status         => self::STATUS_NAMES[host['status'].to_i]
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
