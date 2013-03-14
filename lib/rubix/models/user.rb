require 'digest/md5'

module Rubix

  class User < Model

    # Numeric codes for the various user types.
    zabbix_define :TYPE, {
      :normal      => 1,
      :admin       => 2,
      :super_admin => 3
    }

    #
    # == Properties & Finding ==
    #

    zabbix_attr :username,           :required => true
    zabbix_attr :first_name,         :required => true
    zabbix_attr :last_name,          :required => true
    zabbix_attr :url
    zabbix_attr :auto_login
    zabbix_attr :type
    zabbix_attr :lang
    zabbix_attr :theme
    zabbix_attr :auto_logout_period
    zabbix_attr :refresh_period
    zabbix_attr :rows_per_page
    zabbix_attr :password

    attr_accessor :password_md5

    def initialize properties={}
      super(properties)
      self.password_md5 = properties[:password_md5]

      self.user_group_ids = properties[:user_group_ids]
      self.user_groups    = properties[:user_groups]

      self.media          = properties[:media]
    end

    def resource_name
      "#{self.class.resource_name} #{self.username || self.id}"
    end
    
    #
    # == Validations ==
    #
    
    def validate
      super()
      raise ValidationError.new("A new user must have a password") if new_record? && (password.nil? || password.empty?)
      true
    end

    #
    # == Associations == 
    #

    include Associations::HasManyUserGroups

    attr_reader :media

    def media= ms
      return if ms.nil?
      @media = ms.map do |m|
        m      = Medium.new(m) unless m.kind_of?(Medium)
        m.user = self
        m
      end
    end

    #
    # == Requests ==
    #

    def create_params
      {
        :alias         => username,
        :name          => first_name,
        :surname       => last_name,
        :url           => url,
        :lang          => lang,
        :refresh       => refresh_period,
        :type          => self.class::TYPE_CODES[type],
        :theme         => theme,
        :rows_per_page => rows_per_page,
        :usrgrps       => user_group_ids.map { |id| {'usrgrpid' => id} }
      }.tap do |cp|
        cp[:passwd] = password if password && (!password.empty?)
        
        case
        when auto_login
          cp[:autologin] = 1
        when (!auto_logout_period.nil?)
          cp[:autologout] = auto_logout_period
        end
        
      end
    end

    def after_create
      update_media
    end

    def before_update
      update_media
    end

    def update_media
      return true if media.nil?
      response = request("user.updateMedia", { :users => [{:userid => id}], :medias => media.map(&:to_hash) })
      if response.has_data?
        true
      else
        error("Could not update media for #{resource_name}: #{response.error_message}")
        false
      end
    end
    
    def self.build user
      new({
            :id                 => user[id_field].to_i,
            :username           => user['alias'],
            :first_name         => user['name'],
            :last_name          => user['surname'],
            :password_md5       => user['passwd'],
            :url                => user['url'],
            :auto_login         => (user['autologin'].to_i == 1),
            :auto_logout_period => user['autologout'],
            :lang               => user['lang'],
            :refresh_period     => user['refresh'].to_i,
            :type               => self::TYPE_NAMES[user['type'].to_i],
            :theme              => user['theme'],
            :rows_per_page      => user['rows_per_page'].to_i
          })
    end
    
    def self.get_params
      # FIXME -- select_medias doesn't seem to work here...
      super().merge({})
    end

    def self.find_params options={}
      get_params.merge(:filter => {:alias => options[:username], id_field => options[:id]})
    end

    def destroy_params
      [id_field => id]
    end

  end
end
