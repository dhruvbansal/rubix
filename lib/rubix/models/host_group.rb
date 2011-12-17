module Rubix

  class HostGroup < Model

    #
    # == Properties & Finding ==
    #

    def initialize properties={}
      super(properties)
      @name     = properties[:name]

      self.host_ids = properties[:host_ids]
      self.hosts    = properties[:hosts]
    end

    attr_accessor :name


    def self.id_field
      'groupid'
    end

    #
    # == Associations ==
    #

    include Associations::HasManyHosts

    #
    # == Requests ==
    #

    def create_params
      {:name => name}
    end

    def destroy_params
      [{id_field => id}]
    end

    def self.get_params
      super().merge(:select_hosts => :refer)
    end

    def self.find_params options={}
      get_params.merge(:filter => {id_field => options[:id], :name => options[:name]})
    end

    def self.build host_group
      new({
            :id       => host_group[id_field].to_i,
            :name     => host_group['name'],
            :host_ids => host_group['hosts'].map { |host_info| host_info['hostid'].to_i }
          })
    end

  end
end
