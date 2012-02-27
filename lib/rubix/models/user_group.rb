module Rubix
  
  class UserGroup < Model

    # Numeric codes for the types of access allowed to the GUI for
    # users in the group.  Default is, well, 'default'.
    zabbix_define :GUI_ACCESS, {
      :default  => 0,
      :internal => 1,
      :disabled => 2
    }

    #
    # == Properties & Finding ==
    #

    zabbix_attr :name
    zabbix_attr :api_access, :default => false
    zabbix_attr :debug_mode, :default => false
    zabbix_attr :banned,     :default => false
    zabbix_attr :gui_access, :default => :default

    def initialize properties={}
      super(properties)
      self.user_ids = properties[:user_ids]
      self.users    = properties[:users]
    end
    
    def self.id_field
      'usrgrpid'
    end
    
    #
    # == Associations ==
    #
    
    include Associations::HasManyUsers

    #
    # == Requests ==
    #

    def create_params
      {
        :name         => name,
        :gui_access   => self.class::GUI_ACCESS_CODES[gui_access],
        :users_status => (banned ? 1 : 0),
        :api_access   => (api_access ? 1 : 0),
        :debug_mode   => (debug_mode ? 1 : 0)
      }
    end

    def after_create
      update_users
    end

    def before_update
      update_users
    end

    def update_users
      return true unless self.user_ids
      response = request("usergroup.massUpdate", { :usrgrpids => [id], :userids => self.user_ids })
      if response.has_data?
        true
      else
        error("Could not update users for #{resource_name}: #{response.error_message}")
        false
      end
    end

    def self.get_params
      super().merge(:select_users => :refer)
    end

    def self.find_params options={}
      get_params.merge(:filter => {id_field => options[:id], :name => options[:name]})
    end

    def self.build user_group
      new({
            :id         => user_group[id_field].to_i,
            :name       => user_group['name'],
            :gui_access => self::GUI_ACCESS_NAMES[user_group['gui_access'].to_i],
            :banned     => (user_group['users_status'].to_i == 1),
            :api_access => (user_group['api_access'].to_i == 1),
            :debug_mode => (user_group['debug_mode'].to_i == 1),
            :user_ids   => user_group['users'].map { |user_info| user_info['userid'].to_i }
          })
    end
    
  end
end
