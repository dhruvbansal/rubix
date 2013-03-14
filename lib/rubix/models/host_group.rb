module Rubix

  class HostGroup < Model

    #
    # == Properties & Finding ==
    #

    def initialize properties={}
      super(properties)
      self.host_ids = properties[:host_ids]
      self.hosts    = properties[:hosts]
    end

    zabbix_attr :name, :required => true

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

    def self.get_params
      super().merge(:selectHosts => :refer) # should we add selectTemplates?
    end

    def self.find_params options={}
      get_params.merge(:filter => {id_field => options[:id], :name => options[:name]})
    end

    def self.build host_group
      new({
            :id       => host_group[id_field].to_i,
            :name     => host_group['name'],
            :host_ids => (host_group['hosts'] || []).map { |host_info| host_info['hostid'].to_i }
          })
    end
  end
end
