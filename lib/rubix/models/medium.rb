module Rubix

  class Medium < Model

    # Numeric codes that correspond to accepting triggers that are any
    # priority less than or equal to that listed.  More fine grained
    # control is possible, i.e. - accepting :not_classified and
    # :wanring triggers but rejejcting :information triggers.  In the
    # interests of simplicity, we avoid exposing that degree of
    # freedom here.
    PRIORITY_CODES = {
      :none           => 0,
      :not_classified => 1,
      :information    => 3,
      :warning        => 7,
      :average        => 15,
      :high           => 31,
      :disaster       => 63,
      :all            => 63,
      nil             => 63
    }.freeze
    PRIORITY_NAMES = PRIORITY_CODES.invert.freeze

    #
    # == Properties & Finding ==
    #
    
    zabbix_attr :address,   :required => true
    zabbix_attr :priority,  :required => true, :default => :all
    zabbix_attr :timeframe, :required => true, :default => '1-7,00:00-23:59'
    zabbix_attr :enabled,   :required => true, :default => true

    attr_writer :severity
    def severity
      @severity ||= self.class::PRIORITY_CODES[priority]
    end

    def self.id_field
      'mediaid'
    end

    def initialize properties={}
      super(properties)
      self.severity      = properties[:severity].to_i if properties[:severity]
      self.user          = properties[:user]
      self.user_id       = properties[:user_id]
      self.media_type    = properties[:media_type]
      self.media_type_id = properties[:media_type_id]
    end

    #
    # == Associations == 
    #

    include Associations::BelongsToUser
    include Associations::BelongsToMediaType
    
    #
    # == Requests ==
    #
    
    def create_params
      {
        :mediatypeid => media_type_id,
        :userid      => user_id,
        :sendto      => address,
        :active      => (enabled ? 0 : 1),
        :severity    => (severity || self.class::PRIORITY_CODES[priority]),
        :period      => timeframe
      }
    end

    def self.build medium
      new({
            :id            => medium[id_field].to_i,
            :address       => medium['sendto'],
            :severity      => medium['severity'].to_i,
            :priority      => self::PRIORITY_NAMES[medium['severity'].to_i],
            :timeframe     => medium['period'],
            :enabled       => (medium['active'].to_i == 0),
            :user_id       => medium['userid'].to_i,
            :media_type_id => medium['mediatypeid'].to_i
          })
    end
  end
end
