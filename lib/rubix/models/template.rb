module Rubix
  
  class Template < Model

    #
    # == Properties & Finding ==
    #

    zabbix_attr :name, :required => true
    
    def initialize properties={}
      super(properties)
      
      self.host_ids = properties[:host_ids]
      self.hosts    = properties[:hosts]

      self.host_group_ids = properties[:host_group_ids]
      self.host_groups    = properties[:host_groups]
    end

    #
    # == Validation ==
    #

    def validate
      super()
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
      [id]
    end

    def self.get_params
      super().merge(:selectGroups => :refer, :selectHosts => :refer)
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

    #
    # == Import/Export ==
    #

    # Options which control the template import process and the Zabbix
    # keys they need to be mapped to.
    IMPORT_OPTIONS = {
      :update_hosts     => 'rules[host][exist]',
      :add_hosts        => 'rules[host][missed]',
      :update_items     => 'rules[item][exist]',
      :add_items        => 'rules[item][missed]',
      :update_triggers  => 'rules[trigger][exist]',
      :add_triggers     => 'rules[trigger][missed]',
      :update_graphs    => 'rules[graph][exist]',
      :add_graphs       => 'rules[graph][missed]',
      :update_templates => 'rules[template][exist]'
    }.freeze

    # Import/update a template from XML contained in an open file
    # handle +fh+.
    #
    # By default all hosts, items, triggers, and graphs the XML
    # defines will be both added and updated.  (Linked templates will
    # also be updated.)  This behavior matches the default behavior of
    # the web interface in Zabbix 1.8.8.
    #
    # This can be controlled with options like <tt>:update_hosts</tt>
    # or <tt>:add_graphs</tt>, all of which default to true.  (Linked
    # templates are controlled with <tt>:update_templates</tt>.)
    def self.import fh, options={}
      response = web_request("POST", "/templates.php", import_options(options).merge(:import_file => fh))
      File.open('/tmp/output.html', 'w') { |f| f.puts(response.body) }
    end

    def self.import_options options
      {}.tap do |o|
        self::IMPORT_OPTIONS.each_pair do |name, zabbix_name|
          o[zabbix_name] = 'yes' unless options[name] == false
        end
      end
    end
  end
end
