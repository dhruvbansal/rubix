module Rubix
  
  class Operation < Model

    # Numeric codes for the action's type.
    zabbix_define :TYPE, {
      :message           => 0,
      :command           => 1,
      :host_add          => 2,
      :host_remove       => 3,
      :host_group_add    => 4,
      :host_group_remove => 5,
      :template_add      => 6,
      :template_remove   => 7,
      :host_enable       => 8,
      :host_disable      => 9
    }

    #
    # == Properties & Finding ==
    #

    zabbix_attr :type,                :default => :message, :required => true
    zabbix_attr :escalation_time,     :default => 0
    zabbix_attr :start,               :default => 1
    zabbix_attr :stop,                :default => 1

    def step= s
      self.start = s
      self.stop  = s
    end

    def initialize properties={}
      super(properties)
      self.step           = properties[:step] if properties[:step]

      self.user_ids       = properties[:user_ids]
      self.users          = properties[:users]

      self.user_group_ids = properties[:user_group_ids]
      self.user_groups    = properties[:user_groups]

      self.conditions     = (properties[:conditions] || [])
      self.message        = properties[:message] || Message.new
    end

    #
    # == Associations ==
    #

    include Associations::HasManyConditions
    include Associations::HasManyUsers
    include Associations::HasManyUserGroups
    include Associations::HasMessage

    #
    # == Requests ==
    #

    def create_params
      {
        :operationtype => self.class::TYPE_CODES[type],
        :evaltype      => Condition::JOIN_CODES[condition_operator],
        :esc_period    => escalation_time,
        :esc_step_from => start,
        :esc_step_to   => stop
      }.tap do |cp|
        cp[:opconditions]  = conditions.map(&:to_hash) unless conditions.empty?
        if user_ids
          cp[:opmessage_usr] = user_ids.map { |id| { :userid => id } } unless user_ids.empty?
        end
        cp[:opmessage_grp] = user_group_ids.map { |id| { :usrgrpid => id } } unless user_group_ids.empty?
        cp[:opmessage] = message.to_hash
      end
    end

    def self.build operation
      new({
            :id                  => operation[id_field].to_i,
            :type                => self::TYPE_NAMES[operation['operationtype'].to_i],
            :escalation_period   => operation['esc_period'].to_i,
            :condition_operator  => Condition::JOIN_NAMES[operation['evaltype'].to_i],
            :conditions          => (operation['opconditions'] || []).map { |c| Condition.build(c) },
            :start               => operation['esc_step_from'].to_i,
            :stop                => operation['esc_step_to'].to_i,
            :user_ids            => (operation['opmessage_usr'] || []).map { |e| e['userid'].to_i },
            :user_group_ids      => (operation['opmessage_grp'] || []).map { |e| e['usrgrpid'].to_i }
          }).tap do |o|
            if operation['opmessage']
              o.message = Message.build(operation['opmessage'])
            end
      end
    end
  end
end
