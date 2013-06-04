module Rubix

  # Creates/updates complex resources like Hosts from simple input.
  class Builder

    include Logs

    attr_accessor :blueprint

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
      self.blueprint = symbolize_keys(blueprint)
    end

    def build
      error("Implement the #{self.class}#build method")
    end
    
    def find_or_create_host_group params
      HostGroup.find_or_create(params)
    end

    def find_or_create_template params
      Template.find_or_create({host_groups: [template_host_group]}.merge(params))
    end

    def find_or_create_application params
      Application.find_or_create(params)
    end

    def symbolize_keys hsh={}
      Hash[hsh.map { |key, value| [key.to_sym, value] }]
    end

  end
end
