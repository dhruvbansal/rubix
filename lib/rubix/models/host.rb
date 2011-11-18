module Rubix

  class Host < Model

    # The IP for a Host that not supposed to be polled by the Zabbix
    # server.
    BLANK_IP = '0.0.0.0'

    # The default port.
    DEFAULT_PORT = 10050
    
    attr_accessor :name, :ip, :port, :profile, :status, :host_groups, :templates

    #
    # Initialization and properties.
    #
    def initialize properties={}
      super(properties)
      @name        = properties[:name]
      @ip          = properties[:ip]
      @port        = properties[:port]
      @profile     = properties[:profile]
      @status      = properties[:status]
      @host_groups = properties[:host_groups]
      @templates   = properties[:templates]
    end

    def log_name
      "HOST #{name || id}"
    end
    
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
    
    #
    # Actions
    #

    def validate
      raise ValidationError.new("A host must have at least one host group.") if host_groups.nil? || host_groups.empty?
    end

    def load
      response = request('host.get', 'filter' => {'host' => name}, 'select_groups' => 'refer', 'selectParentTemplates' => 'refer', 'select_profile' => 'refer', 'output' => 'extend')
      case
      when response.has_data?
        host          = response.result.first
        @id           = host['hostid'].to_i
        @host_groups  = host['groups'].map { |group| HostGroup.new(:id => group['groupid'].to_i) }
        @templates    = host['parentTemplates'].map { |template| Template.new((template['templateid'] || template['hostid']).to_i) }
        @profile      = host['profile']
        @port         = host['port']
        @exists       = true
        @loaded       = true
      when response.success?
        @exists = false
        @loaded = true
      else
        error("Could not load: #{response.error_message}")
      end
    end
    
    def create
      validate

      host_group_ids = (host_groups || []).map { |g| { 'groupid'    => g.id } }
      template_ids   = (templates || []).map   { |t| { 'templateid' => t.id } }
      response = request('host.create', params.merge('groups' => host_group_ids, 'templates' => template_ids))
      
      if response.has_data?
        @exists  = true
        @id      = response.result['hostids'].first.to_i
        info("Created")
      else
        error("Could not create: #{response.error_message}.")
      end
    end

    def update
      validate
      response = request('host.update', params.merge('hostid' => id))
      if response.has_data?
        info("Updated")
      else
        error("Could not update: #{response.error_message}.")
      end
      mass_update_templates_and_host_groups
    end

    def mass_update_templates_and_host_groups
      response = request('host.massUpdate', { 'groupids' => (host_groups || []).map(&:id), 'templateids' => (templates || []).map(&:id) })
      if response.has_data?
        info("Updated templates and host groups")
      else
        error("Could not update all templates and/or host groups: #{response.error_message}")
      end
    end

    def destroy
      response = request('host.delete', [{'hostid' => id}])
      case
      when response.has_data? && response.result['hostids'].first.to_i == id
        info("Deleted")
      when response.error_message =~ /does not exist/i
        # was never there...
      else
        error("Could not delete: #{response.error_message}")
      end
    end

  end
end
