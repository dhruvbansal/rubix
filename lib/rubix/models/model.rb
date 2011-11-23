module Rubix

  # It might be worth using ActiveModel -- but maybe not.  The goal is
  # to keep dependencies low while still retaining expressiveness.
  class Model

    attr_accessor :properties, :id

    extend Logs
    include Logs

    #
    # == Identifiers == 
    #

    # This is the name of the resource as used inside Rubix -- Host,
    # HostGroup, UserMacro, &c.
    def self.resource_name
      self.to_s.split('::').last
    end

    # This is the name of *this* resource instance, using this
    # object's 'name' property if possible.
    def resource_name
      "#{self.class.resource_name} #{respond_to?(:name) ? self.name : self.id}"
    end
    
    # This is the name of the resource as used by Zabbix -- host,
    # hostgroup, usermacro, &c.
    def self.zabbix_name
      resource_name.downcase
    end

    # This is the name of the id field returned in Zabbix responses --
    # hostid, groupid, hostmacroid, &c.
    def self.id_field
      "#{zabbix_name}id"
    end

    def id_field
      self.class.id_field
    end

    #
    # == Initialization ==
    #

    def initialize properties={}
      @properties = properties
      @id         = properties[:id]
    end

    def request method, params
      self.class.request(method, params)
    end

    def self.request method, params
      Rubix.connection && Rubix.connection.request(method, params)
    end

    #
    # == CRUD == 
    #
    
    def new_record?
      @id.nil?
    end

    def save
      new_record? ? create : update
    end
    
    def validate
      true
    end

    def create_params
      {}
    end

    def create_request
      request("#{self.class.zabbix_name}.create", create_params)
    end

    def create
      return false unless validate
      response = create_request
      if response.has_data?
        @id = response.result[id_field + 's'].first.to_i
        info("Created #{resource_name}")
        true
      else
        error("Error creating #{resource_name}: #{response.error_message}")
        return false
      end
    end

    def update_params
      create_params.merge({id_field => id})
    end

    def update_request
      request("#{self.class.zabbix_name}.update", update_params)
    end

    def update
      return false unless validate
      return create if new_record?
      return false unless before_update
      response = update_request
      case
      when response.has_data? && response.result.values.first.map(&:to_i).include?(id)
        info("Updated #{resource_name}")
        true
      when response.has_data?
        error("No error, but failed to update #{resource_name}")
        false
      else
        error("Error updating #{resource_name}: #{response.error_message}")
        false
      end
    end

    def before_update
      true
    end

    def destroy_params
      [id]
    end

    def destroy_request
      request("#{self.class.zabbix_name}.delete", destroy_params)
    end
    
    def destroy
      return true if new_record?
      return false unless before_destroy
      response = destroy_request
      case
      when response.has_data? && response.result.values.first.first.to_i == id
        info("Destroyed #{resource_name}")
        true
      when response.zabbix_error? && response.error_message =~ /does not exist/i
        # was never there
        true
      else
        error("Could not destroy #{resource_name}: #{response.error_message}")
        false
      end
    end

    def before_destroy
      true
    end
    
    #
    # == Index == 
    #

    def self.get_params
      { :output => :extend }
    end

    def self.all_params options={}
      get_params.merge(options)
    end

    def self.all_request options={}
      request("#{zabbix_name}.get", all_params(options))
    end

    def self.all options={} 
      response = all_request(options)
      if response.has_data?
        response.result.map { |obj_data| build(obj_data) }
      else
        error("Error listing all #{resource_name}s: #{response.error_message}") unless response.success?
        []
      end
    end

    def self.each &block
      all.each(&block)
    end

    #
    # == Show == 
    #

    def self.find_params options={}
      get_params.merge(options)
    end

    def self.find_request options={}
      request("#{zabbix_name}.get", find_params(options))
    end

    def self.find options={}
      response = find_request(options)
      case
      when response.has_data?
        build(response.result.first)
      when response.success?
        # a successful but empty response means it wasn't found
      else
        error("Error finding #{resource_name} using #{options.inspect}: #{response.error_message}")
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
        error("Error creating #{resource_name} using #{options.inspect}: #{response.error_message}")
        false
      end
    end

  end
end
