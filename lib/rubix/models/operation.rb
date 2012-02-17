module Rubix
  
  class Operation < Model

    # Numeric codes for the action's type.
    TYPE_CODES = {
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
    }.freeze
    TYPE_NAMES = TYPE_CODES.invert.freeze

    # Numeric codes for the type of object that should be notified.
    # Default will be 'group'.
    NOTIFICATION_OBJECT_CODES = {
      :user       => 0,
      :user_group => 1
    }.freeze
    NOTIFICATION_OBJECT_NAMES = NOTIFICATION_OBJECT_CODES.invert.freeze

    #
    # == Properties & Finding ==
    #

    zabbix_attr :type,                :default => :message, :required => true
    zabbix_attr :message_subject,     :default => Action::MESSAGE_SUBJECT
    zabbix_attr :message_body,        :default => Action::MESSAGE_BODY
    zabbix_attr :use_default_message, :default => true
    zabbix_attr :escalation_time,     :default => 0
    zabbix_attr :start,               :default => 1
    zabbix_attr :stop,                :default => 1

    def step= s
      self.start = s
      self.stop  = s
    end

    def initialize properties={}
      super(properties)
      self.step          = properties[:step] if properties[:step]

      self.user_id       = properties[:user_id]
      self.user          = properties[:user]

      self.user_group_id = properties[:user_group_id]
      self.user_group    = properties[:user_group]

      self.conditions    = (properties[:conditions] || [])

      self.media_type    = properties[:media_type]
      self.media_type_id = properties[:media_type_id]
    end

    def notification_object_name
      case
      when user_id       then :user
      when user_group_id then :user_group
      else
        raise Error.new("An #{resource_name} must have either a user or a user group.")
      end
    end
      
    def notification_object_id
      if user_id || user_group_id
        return user_id || user_group_id
      else
        raise Error.new("An #{resource_name} must have either a user or a user group.")
      end
    end

    #
    # == Associations ==
    #

    include Associations::HasManyConditions
    include Associations::BelongsToUser
    include Associations::BelongsToUserGroup
    include Associations::BelongsToMediaType

    #
    # == Requests ==
    #

    def create_params
      {
        :operationtype => self.class::TYPE_CODES[type],
        :object        => self.class::NOTIFICATION_OBJECT_CODES[notification_object_name],
        :objectid      => notification_object_id,
        :shortdata     => message_subject,
        :longdata      => message_body,
        :default_msg   => (use_default_message ? 1 : 0),
        :evaltype      => Condition::JOIN_CODES[condition_operator],
        :esc_period    => escalation_time,
        :esc_step_from => start,
        :esc_step_to   => stop
      }.tap do |cp|
        cp[:opconditions] = conditions.map(&:to_hash) unless conditions.empty?
        cp[:opmediatypes] = [{ :mediatypeid => media_type_id }] if media_type_id
      end
    end

    def self.build operation
      new({
            :id                  => operation[id_field].to_i,
            :type                => self::TYPE_NAMES[operation['operationtype'].to_i],
            :message_subject     => operation['shortdata'],
            :message_body        => operation['longdata'],
            :escalation_period   => operation['esc_period'].to_i,
            :use_default_message => (operation['default_msg'].to_i == 1),
            :condition_operator  => Condition::JOIN_NAMES[operation['evaltype'].to_i],
            :conditions          => (operation['opconditions'] || []).map { |c| Condition.build(c) },
            :start               => operation['esc_step_from'].to_i,
            :stop                => operation['esc_step_to'].to_i
          }).tap do |o|
        if self::NOTIFICATION_OBJECT_NAMES[operation['object'].to_i] == :user
          o.user_id = operation['objectid']
        else
          o.user_group_id = operation['objectid']
        end
        if (operation['opmediatypes'] || []).first
          o.media_type_id = (operation['opmediatypes'] || []).first['mediatypeid'].to_i
        end
      end
    end
    
  end
end
