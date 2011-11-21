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

    def self.find_request options={}
      params = {'select_groups' => 'refer', 'select_hosts' => 'refer', 'output' => 'extend'}
      case
      when options[:id]
        params['templateids'] = [options[:id]]
      when options[:name]
        params['filter'] = { 'host' => options[:name] }
      end
      request('template.get', params)
    end

    def self.build template
      new({
            :id       => (template['templateid'] || template['hostid']).to_i,
            :name     => template['host'],
            :host_ids => template['hosts'].map { |host_info| host_info['hostid'].to_i },
            :host_group_ids => template['groups'].map { |group| group['groupid'].to_i }
          })
    end

    def self.id_field
      'templateid'
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
    
    def create_request
      request('template.create', {'host' => name, 'groups' => host_group_params})
    end
    
    def update_request
      request('template.update', [{'host' => name, 'templateid' => id, 'groups' => host_group_params}])
    end

    def destroy_request
      request('template.delete', [{'templateid' => id}])
    end
    
  end
end
