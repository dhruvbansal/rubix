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

    def validate
    end
    
    def create
      validate
      response = create_request
      if response.has_data?
        @id = response.result[self.class.id_field + 's'].first.to_i
        info("Created")
      else
        error("Could not create: #{response.error_message}")
      end
    end

    def update
      validate
      return create if new_record?
      response = update_request
      if response.has_data?
        info("Updated")
      else
        error("Could not update: #{response.error_message}")
      end
      after_update
    end

    def after_update
    end

    def save
      new_record? ? create : update
    end

    def destroy
      return if new_record?
      response = destroy_request
      case
      when response.has_data? && response.result.values.first.first.to_i == id
        info("Destroyed")
      when response.zabbix_error? && response.error_message =~ /does not exist/i
        # was never there
      else
        error("Could not destroy: #{response.error_message}")
      end
    end

  end
end
