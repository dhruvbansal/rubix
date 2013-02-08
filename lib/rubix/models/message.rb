module Rubix
  class Message < Model

    #
    # == Properties & Finding ==
    #

    zabbix_attr :use_default_message, :default => true
    zabbix_attr :subject
    zabbix_attr :message

    def initialize properties={}
      super(properties)
      self.media_type_id = properties[:media_type_id]
    end

    #
    # == Associations ==
    #

    include Associations::BelongsToMediaType

    #
    # == Requests ==
    #

    def create_params
      {
        :default_msg => use_default_message ? '1' : '0',
        :subject     => subject,
        :message     => message,
        :mediatypeid => media_type_id
      }
    end

    def self.build msg
      new({
            :use_default_message => msg['default_msg'] == '1',
            :subject => msg['subject'],
            :message => msg['message'],
            :media_type_id => msg['mediatypeid']
          })
    end
  end
end
