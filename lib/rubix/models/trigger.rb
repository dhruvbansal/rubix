module Rubix
  
  class Trigger < Model

    #
    # == Properties & Finding ==
    #

    PRIORITY_NAMES = {
      :not_classified => 0,
      :information    => 1,
      :warning        => 2,
      :average        => 3,
      :high           => 4,
      :disaster       => 5
    }.freeze
    PRIORITY_CODES = PRIORITY_NAMES.invert.freeze

    STATUS_NAMES = {
      :enabled  => 0,
      :disabled => 1
    }.freeze
    STATUS_CODES = STATUS_NAMES.invert.freeze
    
    attr_accessor :description, :url, :status, :priority, :comments
    attr_reader   :expression
    
    def initialize properties={}
      super(properties)
      @description = properties[:description]
      @url         = properties[:url]
      @status      = properties[:status]
      @priority    = properties[:priority]
      @comments    = properties[:comments]

      self.expression  = properties[:expression]
      
      self.host     = properties[:host]
      self.template = properties[:template]
      
      self.template_id = properties[:template_id]
      self.host_id = properties[:host_id]
      
      self.items    = properties[:items]
      self.item_ids = properties[:item_ids]
    end

    def expression= e
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
        :templateid   => (template_id || host_id),
        :description  => (description || 'Unknown'),
        :expression   => expression,
        :priority     => self.class::PRIORITY_NAMES[priority],
        :status       => self.class::STATUS_NAMES[status],
        :comments     => comments,
        :url          => url
      }
    end

    def self.get_params
      super().merge(:select_items => :refer)
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
            :status          => STATUS_CODES[trigger['status'].to_i],
            :priority        => PRIORITY_CODES[trigger['priority'].to_i],
            :item_ids        => (trigger['items'] || []).map { |item| item['itemid'].to_i }
          }.merge(host_or_template_params_from_id(trigger['templateid'].to_i)))
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
