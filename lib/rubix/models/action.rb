module Rubix
  
  class Action < Model

    # Numeric codes for the event source.  Default will be 'triggers'.
    EVENT_SOURCE_CODES = {
      :triggers          => 0,
      :discovery         => 1,
      :auto_registration => 2
    }.freeze
    EVENT_SOURCE_NAMES = EVENT_SOURCE_CODES.invert.freeze

    # The default subject for messages.
    MESSAGE_SUBJECT = "{TRIGGER.NAME}: {TRIGGER.STATUS}"
    
    # The default body for messages.
    MESSAGE_BODY = "{TRIGGER.NAME}: {TRIGGER.STATUS}\nLast value: {ITEM.LASTVALUE}\n\n{TRIGGER.URL}"

    #
    # == Properties & Finding ==
    #

    zabbix_attr :name,                     :required => true
    zabbix_attr :event_source,             :default => :triggers, :required => true
    zabbix_attr :escalation_time,          :default => 0
    zabbix_attr :enabled,                  :default => true
    zabbix_attr :message_subject,          :default => MESSAGE_SUBJECT
    zabbix_attr :message_body,             :default => MESSAGE_BODY
    zabbix_attr :send_recovery_message,    :default => false
    zabbix_attr :recovery_message_subject, :default => MESSAGE_SUBJECT
    zabbix_attr :recovery_message_body,    :default => MESSAGE_BODY

    def initialize properties={}
      super(properties)

      self.operations = (properties[:operations] || [])
      self.conditions = (properties[:conditions] || [])
    end

    #
    # == Associations ==
    #

    include Associations::HasManyConditions

    def operations
      @operations ||= []
    end

    def operations= os
      @operations = os.map do |o|
        o.kind_of?(Operation) ? o : Operation.new(o)
      end
    end

    #
    # == Validations ==
    #
    def validate
      super()
      raise ValidationError.new("An action must have at least one operation defined.") if operations.empty?
      operations.each do |operation|
        return false unless operation.validate
      end
      true
    end
    
    #
    # == Requests ==
    #

    def create_params
      {
        :name          => name,
        :eventsource   => self.class::EVENT_SOURCE_CODES[event_source],
        :evaltype      => Condition::JOIN_CODES[condition_operator],
        :status        => (enabled ? 0 : 1),
        :esc_period    => escalation_time,
        :def_shortdata => message_subject,
        :def_longdata  => message_body,
        :recovery_msg  => (send_recovery_message ? 1 : 0),
        :r_shortdata   => recovery_message_subject,
        :r_longdata    => recovery_message_body
      }.tap do |cp|
        cp[:conditions] = conditions.map(&:to_hash) unless conditions.empty?
        cp[:operations] = operations.map(&:to_hash) unless operations.empty?
      end
    end

    def self.find_params options={}
      get_params.merge(:filter => {id_field => options[:id], :name => options[:name]})
    end

    def self.get_params
      super().merge({:select_conditions => :refer, :select_operations => :refer})
    end

    def self.build action
      new({
            :id                       => action[id_field].to_i,
            :name                     => action['name'],
            :event_source             => self::EVENT_SOURCE_NAMES[action['eventsource'].to_i],
            :condition_operator       => Condition::JOIN_NAMES[action['evaltype'].to_i],
            :enabled                  => (action['status'].to_i == 0),
            :escalation_time          => action['esc_period'].to_i,
            :message_subject          => action['def_shortdata'],
            :message_body             => action['def_longdata'],
            :send_recovery_message    => (action['recovery_msg'].to_i == 1),
            :recovery_message_subject => action['r_shortdata'],
            :recovery_message_body    => action['r_longdata'],
            :conditions               => (action['conditions'] || []).map { |c| Condition.build(c) },
            :operations               => (action['operations'] || []).map { |o| Operation.build(o) }
          })
    end
    
  end
end
