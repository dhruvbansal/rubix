module Rubix
  
  class MediaType < Model

    # The numeric codes corresponding to each media type.
    #
    # The default will be 'script'.
    TYPE_CODES = {
      :email      => 0,
      :script     => 1,
      :sms        => 2,
      :jabber     => 3,
      :ez_texting => 100
    }.freeze
    TYPE_NAMES = TYPE_CODES.invert.freeze

    #
    # == Properties & Finding ==
    #

    attr_accessor :description, :server, :helo, :email, :path, :modem, :username, :password
    
    attr_writer   :type
    def type
      @type ||= :script
    end

    def initialize properties={}
      super(properties)
      self.description = properties[:description]
      self.type        = properties[:type]
      self.server      = properties[:server]
      self.helo        = properties[:helo]
      self.email       = properties[:email]
      self.path        = properties[:path]
      self.modem       = properties[:modem]
      self.username    = properties[:username]
      self.password    = properties[:password]
    end
    
    #
    # == Requests ==
    #

    def create_params
      {
        :description => description,
        :type        => TYPE_CODES[type]
      }.tap do |p|
        case type
        when :email
          p[:smtp_server] = server if server
          p[:smtp_helo]   = helo   if helo
          p[:smtp_email]  = email  if email
        when :script
          p[:exec_path]   = path   if path
        when :sms
          p[:gsm_modem]   = modem  if modem
        when :jabber
          p[:username]    = username if username
          p[:passwd]      = password if password
        end
      end
    end

    def self.find_params options={}
      get_params.merge(:filter => {id_field => options[:id], :description => options[:description]})
    end

    def self.build media_type
      new({
            :id          => media_type[id_field].to_i,
            :type        => self::TYPE_NAMES[media_type['type'].to_i],
            :description => media_type['description'],
            :server      => media_type['smtp_server'],
            :helo        => media_type['smtp_helo'],
            :email       => media_type['smtp_email'],
            :path        => media_type['exec_path'],
            :modem       => media_type['gsm_modem'],
            :username    => media_type['username'],
            :password    => media_type['passwd']
          })
    end
    
  end
end
