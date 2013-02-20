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
      self.class.properties.keys.each do |property|
        self.send("#{property}=", (properties[property] || properties[property.to_sym]))
      end
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

    # Return Zabbix API version
    # @return [String]
    def api_version
      self.class.api_version
    end

    # Return Zabbix API version
    # @return [String]
    def self.api_version
      Rubix.connection && Rubix.connection.api_version
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

    # Send a web request to the Zabbix web application.  This is just
    # a convenience method for <tt>Rubix::Connection#web_request</tt>.
    #
    # @param [String] verb one of "GET" or "POST"
    # @param [String] path the path to send the request to
    # @param [Hash] data the data to include with the request
    def self.web_request verb, path, data={}
      Rubix.connection && Rubix.connection.web_request(verb, path, data)
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

    def save!
      raise Rubix::Error.new(Rubix.connection.last_response.body) unless save
    end

    # Validate this record.
    #
    # Override this method in a subclass and have it raise a
    # <tt>Rubix::ValidationError</tt> if validation fails.
    #
    # @return [true, false]
    def validate
      self.class.properties.each_pair do |property, options|
        property_value = self.send property
        if options[:required]
          if property_value.nil?
            raise ValidationError.new("A #{self.class.resource_name} #{property} can't be nil")
          elsif property_value.is_a?(Array) && property_value.empty?
            raise ValidationError.new("A #{self.class.resource_name} must have a #{property}")
          end
        end
      end
      true
    end

    # Return this object as a Hash.
    #
    # @return [Hash]
    def to_hash
      update_params
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
      after_create
    end

    # Run this hook after creating a new resource.
    def after_create
      true
    end

    #
    # == Update ==
    #

    # Parameters for updating a resource of this type.
    #
    # @return [Hash]
    def update_params
      if id
        create_params.merge({id_field => id})
      else
        create_params
      end
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
      when response.has_data? && (response.result.values.first == true || response.result.values.first.map(&:to_i).include?(id))
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
      # Zabbix 2.0.4 returns "result":{"itemids":{"22":22}} on item.delete
      when response.has_data? && (((tmp = response.result.values.first.first).is_a?(Array) && tmp.first.to_i == id ) || response.result.values.first.first.to_i == id)
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
          error("Error creating Zabbix #{resource_name} using #{options.inspect}: #{response.error_message}")
          false
        end
      else
        # should probably never get here...
        error("Error finding or creating Zabbix #{resource_name} using #{options.inspect}: #{response.error_message}")
        false
      end
    end

    #
    # == List ==
    #

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

    #
    # == Helpers ==
    #

    def self.properties
      @properties ||= {}
    end

    def self.zabbix_attr name, options={}
      name = name.to_s.to_sym
      @properties     ||= {}
      @properties[name] = options
      
      if options[:default].nil?
        attr_accessor name
      else
        attr_writer name
        define_method name do
          current_value = instance_variable_get("@#{name}")
          return current_value unless current_value.nil?
          instance_variable_set("@#{name}", options[:default])
        end
      end
    end

    def self.zabbix_define defname, hash
      codes = hash
      names = hash.invert.freeze
      codes.keys.each do |key|
        codes[key.to_s] = codes[key]
      end
      codes.freeze
      const_set "#{defname}_CODES", codes
      const_set "#{defname}_NAMES", names
    end
    
  end
end
