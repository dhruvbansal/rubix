module Rubix

  class Template < Model

    #
    # == Properties & Finding ==
    #

    attr_accessor :name

    def initialize properties={}
      super(properties)
      @name     = properties[:name]

      self.host_ids = properties[:host_ids]
      self.hosts    = properties[:hosts]

      self.host_group_ids = properties[:host_group_ids]
      self.host_groups    = properties[:host_groups]
    end

    #
    # == Validation ==
    #

    def validate
      raise ValidationError.new("A template must have at least one host group.") if host_group_ids.nil? || host_group_ids.empty?
      true
    end

    #
    # == Associations ==
    #

    include Associations::HasManyHosts
    include Associations::HasManyHostGroups

    #
    # == CRUD ==
    #

    def create_params
      {:host => name, :groups => host_group_params}
    end

    def update_params
      [create_params.merge(id_field => id)]
    end

    def destroy_params
      [{id_field => id}]
    end

    def self.get_params
      super().merge(:select_groups => :refer, :select_hosts => :refer)
    end

    def self.find_params options={}
      get_params.merge(:filter => {:host => options[:name], :hostid => options[:id]})
    end

    def self.build template
      new({
            :id       => (template[id_field] || template['hostid']).to_i,
            :name     => template['host'],
            :host_ids => template['hosts'].map { |host_info| host_info['hostid'].to_i },
            :host_group_ids => template['groups'].map { |group| group['groupid'].to_i }
          })
    end

  end
end
