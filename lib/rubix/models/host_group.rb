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

    def self.find_request options={}
      request('hostgroup.get', 'filter' => {'groupid' => options[:id], 'name' => options[:name]}, 'select_hosts' => 'refer', 'output' => 'extend')
    end

    def self.build host_group
      new({
            :id       => host_group['groupid'].to_i,
            :name     => host_group['name'],
            :host_ids => host_group['hosts'].map { |host_info| host_info['hostid'].to_i }
          })
    end
    
    def self.id_field
      'groupid'
    end
    
    #
    # == Associations ==
    #
    
    include Associations::HasManyHosts

    #
    # == CRUD ==
    #
    
    def create_request
      request('hostgroup.create', [{'name' => name}])
    end

    def update_request
      request('hostgroup.update', [{'groupid' => id, 'name' => name}])
    end

    def destroy_request
      request('hostgroup.delete', [{'groupid' => id}])
    end

  end
end
