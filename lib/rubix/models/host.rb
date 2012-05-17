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
    
    # The numeric codes for IPMI authentication algorithms.
    zabbix_define :IPMI_AUTH, {
      :default   => -1,
      :none      => 0,
      :md2       => 1,
      :md5       => 2,
      :straight  => 4,
      :oem       => 5, 
      :rmcp_plus => 6 
    }

    # The numeric codes for IPMI priviledge levels.
    zabbix_define :IPMI_PRIVILEGE, {
      :callback => 1,
      :user     => 2,
      :operator => 3,
      :admin    => 4, 
      :oem      => 5
    }
    
    zabbix_attr :name
    zabbix_attr :ip
    zabbix_attr :port
    zabbix_attr :profile
    zabbix_attr :dns
    zabbix_attr :status
    zabbix_attr :use_ip,    :default => true
    zabbix_attr :monitored, :default => true
    zabbix_attr :use_ipmi,  :default => false
    zabbix_attr :ipmi_port, :default => 623
    zabbix_attr :ipmi_username
    zabbix_attr :ipmi_password
    zabbix_attr :ipmi_ip
    zabbix_attr :ipmi_authtype 
    zabbix_attr :ipmi_privilege, :default => :user
    
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
    
    def use_ipmi
      return @use_ipmi if (!@use_ipmi.nil?)
      @use_ipmi = false
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
      raise ValidationError.new("A host must have a valid ip address if use_ip is set.") if use_ip && ip == self.class::BLANK_IP
      raise ValidationError.new("A host must have an ip address if use_ip is set.") if use_ip && (ip.nil? || ip.empty?)
      raise ValidationError.new("A host must have a dns name if use_ip is false.") if !use_ip && dns.nil?
      raise ValidationError.new("A host must have a ipmi_privilege defined as one of: " + self.class::IPMI_PRIVILEGE_CODES.keys.to_s) if use_ipmi && self.class::IPMI_PRIVILEGE_CODES[ipmi_privilege].nil?
      raise ValidationError.new("A host must have a ipmi_authtype defined as one of: " + self.class::IPMI_AUTH_CODES.keys.to_s) if use_ipmi && self.class::IPMI_AUTH_CODES[ipmi_authtype].nil?
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
        hp[:profile].delete("hostid") if hp[:profile] && hp[:profile]["hostid"]
        hp[:status]  = (monitored ? 0 : 1) unless monitored.nil?
        
        # Check to see if use_ip is set, otherwise we will use dns
        hp[:useip]          = (use_ip == true ? 1 : 0)
        
        # if we have an IP then use it, otherwise use 0.0.0.0, same goes for the port
        hp[:ip]             = ip   || self.class::BLANK_IP
        hp[:port]           = port || self.class::DEFAULT_PORT
        
        # Always allow for a DNS record to exist even if we dont use it to monitor.
        hp[:dns]            = dns           if dns
        
        hp[:useipmi]        = (use_ipmi == true ? 1 : 0)
        hp[:ipmi_port]      = ipmi_port     if ipmi_port
        hp[:ipmi_username]  = ipmi_username if ipmi_username
        hp[:ipmi_password]  = ipmi_password if ipmi_password
        hp[:ipmi_ip]        = ipmi_ip       if ipmi_ip
        hp[:ipmi_authtype]  = self.class::IPMI_AUTH_CODES[ipmi_authtype]       if ipmi_authtype
        hp[:ipmi_privilege] = self.class::IPMI_PRIVILEGE_CODES[ipmi_privilege] if ipmi_privilege
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
      host['profile'].delete('hostid') if host.is_a?(Hash) && host['profile'].is_a?(Hash) && host['profile']['hostid']
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
            :use_ip         => (host['useip'].to_i  == 1),

            # If the status is '1' then this is an unmonitored host.
            # Otherwise it's either '0' for monitored and ok or
            # something else for monitored and *not* ok.
            :monitored      => (host['status'].to_i == 1 ? false : true),
            :status         => self::STATUS_NAMES[host['status'].to_i],
            :use_ipmi       => (host['useipmi'].to_i == 1),
            :ipmi_port      => host['ipmi_port'].to_i,
            :ipmi_username  => host['ipmi_username'],
            :ipmi_password  => host['ipmi_password'],
            :ipmi_ip        => host['ipmi_ip'],
            :ipmi_authtype  => self::IPMI_AUTH_NAMES[host['ipmi_authtype'].to_i],
            :ipmi_privilege => self::IPMI_PRIVILEGE_NAMES[host['ipmi_privilege'].to_i]
          })
    end
    
    def self.get_params
      super().merge({:select_groups => :refer, :selectParentTemplates => :refer, :select_profile => :refer, :select_macros => :extend})
    end

    def self.find_params options={}
      get_params.merge(:filter => {:host => options[:name], id_field => options[:id], :ip => options[:ip]})
    end
    
  end
end
