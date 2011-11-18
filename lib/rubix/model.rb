require 'rubix/log'

module Rubix

  # It might be worth using ActiveModel -- but maybe not.  The goal is
  # to keep dependencies low while still retaining expressiveness.
  class Model

    attr_accessor :properties, :id

    include Logs

    def initialize properties={}
      @properties = properties
      @id         = properties[:id]
      @log_name   = self.class.to_s.split('::').last
    end
    
    def loaded?
      @loaded
    end

    def load
      raise NotImplementedError.new("Override the 'load' method in a subclass.")
    end

    def exists?
      load unless loaded?
      @exists
    end

    def register
      exists? ? update : create
    end

    def unregister
      destroy if exists?
    end
    
    def request method, params
      Rubix.connection && Rubix.connection.request(method, params)
    end

    def self.find_by_id id
      instance = new(:id => id)
      instance if instance.exists?
    end

    def self.find_by_name name
      instance = new(:name => name)
      instance if instance.exists?
    end
    
  end
  
end
