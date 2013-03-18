module Rubix

  # Allows passing in a static description in a single API call of the
  # complete configuration of a Host, auto-vivifying all child
  # resources like Templates, HostGroups, &c.
  class Builder

    include Logs

    attr_accessor :blueprint
    attr_accessor :host

    CACHE = {
      templates:   {},
      host_groups: {},
      interfaces:  {},
    }

    CACHE_CLEAN_FREQUENCY = 10  # seconds

    def self.clear_cache
      Thread.new do sleep(CACHE_CLEAN_FREQUENCY)
        debug "Clearing builder cache"
        CACHE.values.each(&:clear)
        clear_cache
      end
    end
    
    def initialize blueprint
      self.blueprint = blueprint
    end

    attr_reader :host
    
    def host_groups
      @host_groups ||= (blueprint['host_groups'] || []).map do |host_group_name|
        find_or_create_host_group(name: host_group_name)
      end
    end

    def templates
      @templates ||= (blueprint['templates'] || []).map do |template_name|
        find_or_create_template(name: template_name)
      end
    end

    def interfaces
      blueprint['interfaces'].map { |interface| Interface.new(interface) }
    end
    
    def find_or_create_host
      @host = Host.find_or_create(name: blueprint['name'], monitored: blueprint['monitored'], host_groups: host_groups, interfaces: interfaces, templates: templates)
    end

    def update_interfaces
      host.interfaces = Interface.find(hosts: [host]) # gets the interfaces' IDs in there
    end
    
    def find_or_create_host_group params
      return CACHE[:host_groups][params] if CACHE[:host_groups][params]
      CACHE[:host_groups][params] = HostGroup.find_or_create(params)
    end

    def find_or_create_template params
      return CACHE[:templates][params] if CACHE[:templates][params]
      CACHE[:templates][params] = Template.find_or_create({host_groups: [template_host_group]}.merge(params))
    end

    def template_host_group
      find_or_create_host_group(name: "Templates")
    end

    def find_or_create_application params
      return CACHE[:applications][params] if CACHE[:applications][params]
      CACHE[:applications][params] = Application.find_or_create(params)
    end

    def find_interface params
      host.interfaces.detect do |host_interface|
        host_interface.id && 
          host_interface.type == params['type'] &&
          ((host_interface.dns && (host_interface.dns == params['dns'])) ||
           (host_interface.ip  && (host_interface.dns == params['ip']))) &&
          host_interface.port == params['port']
      end
    end
    
    def items
      (blueprint["items"] || []).map do |item|
        interface_spec = {type: 'agent', main: true}
        
        if item['interface'].nil? || item['interface'].empty?
          warn("No interface for \'#{item['name']}\'")
          next
        end
        item['interface_id'] = (item.delete('interface') || {}).map do |interface_spec|
          (find_interface(interface_spec) or next).id
        end
        
        item['applications'] ||= []
        item['applications'].map! { |app_name| find_or_create_application(host_id: host.id, name: app_name).id }
        Item.new(item.merge(host_id: host.id))
      end
    end

    def triggers
      (blueprint['triggers'] || []).map do |trigger|
        Trigger.new(trigger.merge(host_id: host.id))
      end
    end
    
    def build
      unless find_or_create_host
        error "Could not find or create Zabbix host #{blueprint['name']}"
        return
      end
      update_interfaces
      
      host.interfaces.each { |interface| interface.host = host }
      items.each    { |item|    item.save    }
      triggers.each { |trigger| trigger.save }
    end

  end
  
end

