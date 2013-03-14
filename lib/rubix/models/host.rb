module Rubix

  class Host < Model

    #
    # == Properties & Finding ==
    #
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

    # The numeric codes for the various availability types.
    zabbix_define :AVAILABILITY, {
      :unknown      => 0,
      :available    => 1,
      :unavailable  => 2
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
    zabbix_attr :visible_name
    zabbix_attr :status, :default => :monitored

    # IPMI
    zabbix_attr :ipmi_username
    zabbix_attr :ipmi_password
    zabbix_attr :ipmi_authtype 
    zabbix_attr :ipmi_privilege, :default => :user

    # Read-only.  Will be read on 'build' but not transmitted on
    # 'create' or 'update'.
    zabbix_attr :availability
    zabbix_attr :disable_until
    zabbix_attr :error_msg
    zabbix_attr :errors_from
    zabbix_attr :ipmi_availability
    zabbix_attr :ipmi_disable_until
    zabbix_attr :ipmi_error
    zabbix_attr :ipmi_errors_from
    zabbix_attr :jmx_availability
    zabbix_attr :jmx_disable_until
    zabbix_attr :jmx_error
    zabbix_attr :jmx_errors_from
    zabbix_attr :snmp_availability
    zabbix_attr :snmp_disable_until
    zabbix_attr :snmp_error
    zabbix_attr :snmp_errors_from
    zabbix_attr :last_access

    def monitored
      @status == :monitored
    end

    def monitored= value
      if value
        @status = :monitored
      else
        @status = :not_monitored
      end
    end

    def initialize properties={}
      super(properties)

      self.host_group_ids = properties[:host_group_ids]
      self.host_groups    = properties[:host_groups]

      self.template_ids   = properties[:template_ids]
      self.templates      = properties[:templates]

      self.interface_ids   = properties[:interface_ids]
      self.interfaces      = properties[:interfaces]

      self.user_macro_ids = properties[:user_macro_ids]
      self.user_macros    = properties[:user_macros]

      self.inventory      = properties[:inventory]
    end

    #
    # == Associations == 
    #

    include Associations::HasManyHostGroups
    include Associations::HasManyTemplates
    include Associations::HasManyUserMacros
    include Associations::HasManyInterfaces
    include Associations::HasInventory

    #
    # == Validation == 
    #

    def validate
      raise ValidationError.new("A host must have at least one host group.") if host_group_ids.nil? || host_group_ids.empty?
      raise ValidationError.new("A host must have at least one interface.")  if interface_ids.nil?  || interfaces.empty?
      true
    end
    
    #
    # == Requests ==
    #

    def create_params
      {
        :host       => name,
        :name       => visible_name,
        :status     => self.class::STATUS_CODES[status],
        :groups     => host_group_params,
        :templates  => template_params,
        :macros     => user_macro_params,
        :interfaces => interface_params
      }.tap do |hp|
        hp[:ipmi_username]  = ipmi_username if ipmi_username
        hp[:ipmi_password]  = ipmi_password if ipmi_password
        hp[:ipmi_authtype]  = self.class::IPMI_AUTH_CODES[ipmi_authtype]       if ipmi_authtype
        hp[:ipmi_privilege] = self.class::IPMI_PRIVILEGE_CODES[ipmi_privilege] if ipmi_privilege
        hp[:inventory]      = inventory_params if inventory
      end
    end
    
    def update_params
      create_params.tap do |cp|
        cp.delete(:interfaces)
        cp[id_field] = id
      end
    end

    # def before_update
    #   response = request('host.massUpdate', { :interfaces => interface_params, :groups => host_group_params, :templates => template_params, :macros => user_macro_params, :hosts => [{id_field => id}]})
    #   if response.has_data?
    #     true
    #   else
    #     error("Could not update all interfaces, templates, host groups, and/or macros for #{resource_name}: #{response.error_message}")
    #     false
    #   end
    # end
    
    def destroy_params
      [{id_field => id}]
    end

    # def before_destroy
    #   return true if user_macros.nil? || user_macros.empty?
    #   user_macros.map { |um| um.destroy }.all?
    # end

    def self.build host
      new({
            :id             => host[id_field].to_i,
            :name           => host['host'],
            :visible_name   => host['name'],
            
            :host_group_ids => host['groups'].map { |group| group['groupid'].to_i },
            :template_ids   => host['parentTemplates'].map { |template| (template['templateid'] || template[id_field]).to_i },
            :user_macros    => host['macros'].map { |id, um| UserMacro.new(:host_id => um[id_field].to_i, :id => um['hostmacroid'], :value => um['value'], :macro => um['macro']) },
            :interfaces     => host['interfaces'].values,
            
            :status         => self::STATUS_NAMES[host['status'].to_i],
            
            :ipmi_username  => host['ipmi_username'],
            :ipmi_password  => host['ipmi_password'],
            :ipmi_authtype  => self::IPMI_AUTH_NAMES[host['ipmi_authtype'].to_i],
            :ipmi_privilege => self::IPMI_PRIVILEGE_NAMES[host['ipmi_privilege'].to_i],


            :availability       => self::AVAILABILITY_NAMES[host['availability'].to_i],
            :disable_until      => host['disable_until'].to_i,
            :error_msg          => host['error'],
            :errors_from        => host['errors_from'].to_i,
            :ipmi_availability  => self::AVAILABILITY_NAMES[host['ipmi_availability'].to_i],
            :ipmi_disable_until => host['ipmi_disable_until'].to_i,
            :ipmi_error         => host['ipmi_error'],
            :ipmi_errors_from   => host['ipmi_errors_from'].to_i,
            :jmx_availability   => self::AVAILABILITY_NAMES[host['jmx_availability'].to_i],
            :jmx_disable_until  => host['jmx_disable_until'].to_i,
            :jmx_error          => host['jmx_error'],
            :jmx_errors_from    => host['jmx_errors_from'].to_i,
            :snmp_availability  => self::AVAILABILITY_NAMES[host['snmp_availability'].to_i],
            :snmp_disable_until => host['snmp_disable_until'].to_i,
            :snmp_error         => host['snmp_error'],
            :snmp_errors_from   => host['snmp_errors_from'].to_i,
            :last_access        => host['last_access'].to_i
          })
    end
    
    def self.get_params
      super().merge({:selectGroups => :refer, :selectParentTemplates => :refer, :selectInterfaces => :extend, :selectMacros => :extend})
    end

    def self.find_params options={}
      get_params.merge(:filter => {:host => options[:name], id_field => options[:id], :ip => options[:ip]})
    end
    
  end
end
