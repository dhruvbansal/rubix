module Rubix

  # Builds a Host.
  #
  # Will automatically construct necessary resources like host groups.
  #
  # @example Build a simple host.  Will choose minimal defaults for all required 
  #
  #   builder = Rubix::HostBuilder.new(name: "My Host")
  #   host = builder.build
  #
  # @example Build a more complicated host.
  #
  #   Rubix::HostBuilder.new(name: "My Host", host_groups: ["First One", "Second "One"], templates: ["Template_First", "Template_Second"]).build
  class HostBuilder < Builder

    include Logs

    attr_accessor :host
    
    def build
      self.host = Host.find_or_create(Hash[%w[name visible_name monitored host_groups interfaces templates user_macros].map { |prop| [ prop.to_sym, send(prop) ] }])
    end

    #
    # == Host ==
    #

    def name
      blueprint[:name]
    end

    def visible_name
      blueprint[:visible_name]
    end
    
    def monitored
      blueprint[:monitored]
    end
    
    #
    # == Host Groups ==
    #

    DEFAULT_HOST_GROUP_NAME = 'All Hosts'

    def default_host_group_name
      @default_host_group_name ||= DEFAULT_HOST_GROUP_NAME
    end
    attr_writer :default_host_group_name
    
    def host_groups
      @host_groups ||= (blueprint[:host_groups] || [default_host_group_name]).map do |host_group_name|
        find_or_create_host_group(name: host_group_name)
      end
    end
    
    #
    # == Templates ==
    #

    def templates
      @templates ||= (blueprint[:templates] || []).map do |template_name|
        find_or_create_template(name: template_name)
      end
    end

    def template_host_group
      find_or_create_host_group(name: "Templates")
    end
    
    #
    # == Interfaces ==
    #

    DEFAULT_IP = "0.0.0.0"

    def default_interface
      { type: :agent, ip: DEFAULT_IP }
    end

    def interfaces
      (blueprint[:interfaces] || [default_interface]).map { |interface| Interface.new(symbolize_keys(interface)) }
    end

    #
    # == User Macros ==
    #
    
    def user_macros
      (blueprint[:user_macros] || []).map { |macro| UserMacro.new(symbolize_keys(macro)) }
    end

  end
  
end
