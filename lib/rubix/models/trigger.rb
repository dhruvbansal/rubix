module Rubix
  
  class Trigger < Model

    #
    # == Properties & Finding ==
    #

    zabbix_define :PRIORITY, {
      :not_classified => 0,
      :information    => 1,
      :warning        => 2,
      :average        => 3,
      :high           => 4,
      :disaster       => 5
    }

    zabbix_define :STATUS, {
      :enabled  => 0,
      :disabled => 1
    }
    
    zabbix_attr :description
    zabbix_attr :url
    zabbix_attr :status
    zabbix_attr :priority
    zabbix_attr :comments
    
    def initialize properties={}
      super(properties)
      self.expression = properties[:expression]
      
      self.host     = properties[:host]
      self.template = properties[:template]
      
      self.template_id = properties[:template_id]
      self.host_id = properties[:host_id]
      
      self.items    = properties[:items]
      self.item_ids = properties[:item_ids]
    end

    attr_reader :expression
    def expression= e
      return unless e
      if e =~ %r!^\{(.*)\}!
        trigger_condition = $1
        if trigger_condition && trigger_condition =~ /:/
          host_or_template_name = trigger_condition.split(':').first
          host_or_template = Template.find(:name => host_or_template_name) || Host.find(:name => host_or_template_name)
          case host_or_template
          when Host     then self.host = host_or_template
          when Template then self.template = host_or_template
          end
        end
      end
      @expression = e
    end

    def resource_name
      "#{self.class.resource_name} #{self.description || self.id}"
    end

    #
    # == Associations ==
    #

    include Associations::BelongsToHost
    include Associations::BelongsToTemplate
    include Associations::HasManyItems

    #
    # == Requests == 
    #
    
    def create_params
      {
        :description  => (description || 'Unknown'),
        :expression   => expression,
        :priority     => self.class::PRIORITY_CODES[priority],
        :status       => self.class::STATUS_CODES[status],
        :comments     => comments,
        :url          => url
      }
    end

    def self.get_params
      super().merge(:selectItems => :refer)
    end
    
    def self.find_params options={}
      fp = {
        :filter => {
          :description => options[:description]
        }
      }.tap do |fp|
        case
        when options[:template_id]
          fp[:templateids] = [options[:template_id]]
        when options[:host_id]
          fp[:hostids] = [options[:host_id]]
        end
      end
      super().merge(fp)
    end

    def self.build trigger
      new({
            :id              => trigger[id_field].to_i,
            :description     => trigger['description'],
            :expression      => trigger['expression'],
            :comments        => trigger['comments'],
            :url             => trigger['url'],
            :status          => STATUS_NAMES[trigger['status'].to_i],
            :priority        => PRIORITY_NAMES[trigger['priority'].to_i],
            :item_ids        => (trigger['items'] || []).map { |item| item['itemid'].to_i }
          }.merge(host_or_template_params_from_id(trigger['hosts'].first['hostid'].to_i)))
    end

    def self.host_or_template_params_from_id id
      template_or_host = Template.find(:id => id) || Host.find(:id => id)
      case template_or_host
      when Template
        { :template => template_or_host }
      when Host
        { :host     => template_or_host }
      else
        {}
      end
    end
    
  end
end
