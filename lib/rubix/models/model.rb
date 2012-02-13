module Rubix

  # A base class for all Zabbix models to subclass.
  #
  # It might be worth using ActiveModel -- but maybe not.  The goal is
  # to keep dependencies low while still retaining expressiveness.
  class Model

    # @return [Hash]] the properties this model was initialized with
    attr_accessor :properties

    # @return [Fixnum, nil] the ID of this model
    attr_accessor :id

    extend Logs
    include Logs

    #
    # == Identifiers == 
    #

    # This is the name of the resource as used inside Rubix -- Host,
    # HostGroup, UserMacro, &c.
    #
    # @return [String]
    def self.resource_name
      self.to_s.split('::').last
    end

    # This is the name of *this* resource instance, using this
    # object's 'name' property if possible.
    #
    # @return [String]
    def resource_name
      "#{self.class.resource_name} #{respond_to?(:name) ? self.name : self.id}"
    end
    
    # This is the name of the resource as used by Zabbix -- host,
    # hostgroup, usermacro, &c.
    #
    # @return [String]
    def self.zabbix_name
      resource_name.downcase
    end

    # This is the name of the id field returned in Zabbix responses --
    # +hostid+, +groupid+, +hostmacroid+, &c.
    #
    # @return [String]
    def self.id_field
      "#{zabbix_name}id"
    end

    # This is the name of the id field returned in Zabbix responses --
    # +hostid+, +groupid+, +hostmacroid+, &c.
    #
    # @return [String]
    def id_field
      self.class.id_field
    end

    #
    # == Initialization ==
    #

    # Create a new model instance.  This may represent a new or
    # existing Zabbix resource.
    #
    # @param [Hash] properties
    # @option properties [Fixnum] id the ID of the resource in Zabbix (typically blank for a new resource)
    def initialize properties={}
      @properties = properties
      @id         = properties[:id]
    end

    # Send a request to the Zabbix API.  This is just a convenience
    # method for <tt>Rubix::Connection#request</tt>.
    #
    # @param [String] method
    # @param [Hash,Array] params
    # @return [Rubix::Response]
    def request method, params
      self.class.request(method, params)
    end

    # Send a request to the Zabbix API.  This is just a convenience
    # method for <tt>Rubix::Connection#request</tt>.
    #
    # @param [String] method
    # @param [Hash,Array] params
    # @return [Rubix::Response]
    def self.request method, params
      Rubix.connection && Rubix.connection.request(method, params)
    end

    # Is this a new record?  We can tell because the ID must be blank.
    #
    # @return [true, false]
    def new_record?
      @id.nil?
    end

    # Save this record.
    #
    # Will create new records and update old ones.
    #
    # @return [true, false]
    def save
      new_record? ? create : update
    end

    # Validate this record.
    #
    # Override this method in a subclass and have it raise a
    # <tt>Rubix::ValidationError</tt> if validation fails.
    #
    # @return [true, false]
    def validate
      true
    end

    #
    # == Create ==
    #

    # Parameters for creating a new resource of this type.
    #
    # @return [Hash]
    def create_params
      {}
    end

    # Send a request to create this resource.
    #
    # @return [Rubix::Response]
    def create_request
      request("#{self.class.zabbix_name}.create", create_params)
    end

    # Create this resource.
    #
    # @return [true, false]
    def create
      return false unless validate
      response = create_request
      if response.has_data?
        @id = response.result[id_field + 's'].first.to_i
        info("Created Zabbix #{resource_name}")
        true
      else
        error("Error creating Zabbix #{resource_name}: #{response.error_message}")
        return false
      end
    end

    #
    # == Update ==
    #

    # Parameters for updating a resource of this type.
    #
    # @return [Hash]
    def update_params
      create_params.merge({id_field => id})
    end

    # Send a request to update this resource.
    #
    # @return [Rubix::Response]
    def update_request
      request("#{self.class.zabbix_name}.update", update_params)
    end

    # Update this resource.
    #
    # @return [true, false]
    def update
      return false unless validate
      return create if new_record?
      return false unless before_update
      response = update_request
      case
      when response.has_data? && response.result.values.first.map(&:to_i).include?(id)
        info("Updated Zabbix #{resource_name}")
        true
      when response.has_data?
        error("No error, but failed to update Zabbix #{resource_name}")
        false
      else
        error("Error updating Zabbix #{resource_name}: #{response.error_message}")
        false
      end
    end

    # A hook that will be run before this resource is updated.
    #
    # Override this in a subclass to implement any desired
    # before-update functionality.  Must return +true+ or +false+.
    #
    # @return [true, false]
    def before_update
      true
    end

    #
    # == Destroy == 
    #

    # Parameters for destroying this resource.
    #
    # @return [Array<Fixnum>]
    def destroy_params
      [id]
    end

    # Send a request to destroy this resource.
    #
    # @return [Rubix::Response]
    def destroy_request
      request("#{self.class.zabbix_name}.delete", destroy_params)
    end

    # Destroy this resource.
    #
    # @return [true, false]
    def destroy
      return true if new_record?
      return false unless before_destroy
      response = destroy_request
      case
      when response.has_data? && response.result.values.first.first.to_i == id
        info("Destroyed Zabbix #{resource_name}")
        true
      when response.zabbix_error? && response.error_message =~ /does not exist/i
        # was never there
        true
      else
        error("Could not destroy Zabbix #{resource_name}: #{response.error_message}")
        false
      end
    end

    # A hook that will be run before this resource is destroyed.
    #
    # Override this in a subclass to implement any desired
    # before-destroy functionality.  Must return +true+ or +false+.
    #
    # @return [true, false]
    def before_destroy
      true
    end
    
    #
    # == Index == 
    #

    # Parameters for 'get'-type requests for this resource's type.
    #
    # @return [Hash]
    def self.get_params
      { :output => :extend }
    end

    # Parameters to list all the objects of this resource's type.
    #
    # @param [Hash] options options for filtering the list of all resources.
    # @return [Hash]
    def self.all_params options={}
      get_params.merge(options)
    end

    # Send a request to list all objects of this resource's type.
    #
    # @param [Hash] options options for filtering the list of all resources.
    # @return [Rubix::Response]
    def self.all_request options={}
      request("#{zabbix_name}.get", all_params(options))
    end

    # List all objects of this resource's type.
    #
    # @param [Hash] options options for filtering the list of all resources.
    # @return [Array<Rubix::Model>]
    def self.all options={} 
      response = all_request(options)
      if response.has_data?
        response.result.map { |obj_data| build(obj_data) }
      else
        error("Error listing all Zabbix #{resource_name}s: #{response.error_message}") unless response.success?
        []
      end
    end

    # Execute block once for each element of the result set.
    #
    # @param [Hash] options options for filtering the list of all resources.
    # @return [Array<Rubix::Model>]
    def self.each options={}, &block
      all(options).each(&block)
    end

    #
    # == Show == 
    #

    # Parameters for finding a specific resource.
    #
    # @param [Hash] options specify properties about the object to find
    # @return [Hash]
    def self.find_params options={}
      get_params.merge(options)
    end

    # Send a find request for a specific resource.
    # 
    # @param [Hash] options specify properties about the object to find
    # @return [Rubix::Response]
    def self.find_request options={}
      request("#{zabbix_name}.get", find_params(options))
    end

    # Find a resource using the given +options+ or return +nil+ if
    # none is found.
    #
    # @param [Hash] options specify properties about the object to find
    # @return [Rubix::Model, nil]
    def self.find options={}
      response = find_request(options)
      case
      when response.has_data?
        build(response.result.first)
      when response.success?
        # a successful but empty response means it wasn't found
      else
        error("Error finding Zabbix #{resource_name} using #{options.inspect}: #{response.error_message}")
        nil
      end
    end

    # Find a resource using the given +options+ or create one if none
    # can be found.  Will return +false+ if the object cannot be found
    # and cannot be created.
    #
    # @param [Hash] options specify properties about the object to find
    # @return [Rubix::Model, false]
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
        error("Error creating Zabbix #{resource_name} using #{options.inspect}: #{response.error_message}")
        false
      end
    end

    def self.list ids
      return [] if ids.nil? || ids.empty?
      response = request("#{zabbix_name}.get", get_params.merge((id_field + 's') => ids))
      case
      when response.has_data?
        response.result.map do |obj|
          build(obj)
        end
      when response.success?
        []
      else
        error("Error listing Zabbix #{resource_name}s: #{response.error_message}")
      end
    end
    
  end
end
