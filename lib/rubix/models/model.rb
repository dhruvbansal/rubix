module Rubix

  # It might be worth using ActiveModel -- but maybe not.  The goal is
  # to keep dependencies low while still retaining expressiveness.
  class Model

    attr_accessor :properties, :id

    extend Logs
    include Logs

    def self.model_name
      self.to_s.split('::').last
    end

    def self.log_name
      model_name
    end

    def initialize properties={}
      @properties = properties
      @id         = properties[:id]
      @log_name   = self.class.model_name
    end
    
    def new_record?
      @id.nil?
    end

    def request method, params
      self.class.request(method, params)
    end

    def self.request method, params
      Rubix.connection && Rubix.connection.request(method, params)
    end

    def self.find options={}
      response = find_request(options)
      case
      when response.has_data?
        build(response.result.first)
      when response.success?
        # a successful but empty response means it wasn't found
      else
        error("Could not find #{options.inspect}: #{response.error_message}")
        nil
      end
    end

    def self.find_or_create options={}
      response = find_request(options)
      case
      when response.has_data?
        build(response.result.first)
      when response.success?
        # doesn't exist
        obj = new(options)
        if obj.save
          obj
        else
          false
        end
      else
        error("Could not create #{options.inspect}: #{response.error_message}")
        false
      end
    end

    def validate
      true
    end
    
    def create
      return false unless validate
      response = create_request
      if response.has_data?
        @id = response.result[self.class.id_field + 's'].first.to_i
        info("Created")
        true
      else
        error("Could not create: #{response.error_message}")
        false
      end
    end

    def update
      return false unless validate
      return create if new_record?
      response = update_request
      if response.has_data?
        info("Updated")
        after_update
      else
        error("Could not update: #{response.error_message}")
        false
      end
      after_update
    end

    def after_update
      true
    end

    def save
      new_record? ? create : update
    end

    def destroy
      return false if new_record?
      response = destroy_request
      case
      when response.has_data? && response.result.values.first.first.to_i == id
        info("Destroyed")
        true
      when response.zabbix_error? && response.error_message =~ /does not exist/i
        # was never there
        true
      else
        error("Could not destroy: #{response.error_message}")
        false
      end
    end

  end
end
