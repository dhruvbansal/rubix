require 'digest/md5'

module Rubix
  module IntegrationHelper

    INTEGRATION_USER     = 'rubix_spec_user'
    INTEGRATION_GROUP    = 'rubix_spec_group'
    INTEGRATION_PASSWORD = 'rubix'

    # Parse the information we need to find the database and Zabbix
    # server we're going to need for any integration tests.  Also set
    # a global variable for easy use of this information when testing.
    def self.setup_integration_tests test_yml_path
      unless parse_integration_settings(test_yml_path)
        puts "Could not parse integration settings in #{test_yml_path}.  Integration tests will be skipped."
        return
      end
      unless connect_to_database
        puts "Could not connect to a MySQL database using: #{$RUBIX_MYSQL_CREDENTIALS.inspect}.  Integration tests will be skipped."
        return
      end
      unless truncate_all_tables
        puts "Could not truncate tables.  Integration tests will be skipped."
        return
      end
      unless create_integration_test_user_and_group
        puts "Could not create integration test user #{INTEGRATION_USER} or group #{INTEGRATION_GROUP}.  Integration tests will be skipped."
        return
      end
      unless connect_to_api
        puts "Could not connect to Zabbix API using: #{$RUBIX_API_CREDENTIALS.inspect}.  Integration tests will be skipped."
        return
      end
      $RUBIX_INTEGRATION = true
    end
      
    def self.parse_integration_settings test_yml_path
      return unless File.exist?(test_yml_path)
      
      require 'yaml'
      test_data = YAML.load(open(test_yml_path))
      return if test_data['disable_integration_tests']
      
      $RUBIX_API_CREDENTIALS   = test_data['api']
      $RUBIX_MYSQL_CREDENTIALS = test_data['mysql']
    end

    def self.connect_to_database
      begin
        require 'mysql2'
        $RUBIX_MYSQL = Mysql2::Client.new(:host => $RUBIX_MYSQL_CREDENTIALS['host'], :username => $RUBIX_MYSQL_CREDENTIALS['username'], :password => $RUBIX_MYSQL_CREDENTIALS['password'], :database => $RUBIX_MYSQL_CREDENTIALS['database'])
      rescue => e
        puts "Could not connect to MySQL database: #{e.class} -- #{e.message}"
        puts e.backtrace
        false
      end
    end
    
    def self.truncate_all_tables
      return unless $RUBIX_MYSQL
      begin
        %w[actions graphs triggers items applications hosts].each do |table|
          $RUBIX_MYSQL.query("DELETE FROM #{table}")
        end
        $RUBIX_MYSQL.query('DELETE FROM groups WHERE `internal` != 1')
        $RUBIX_MYSQL.query('DELETE FROM users  WHERE `alias`    != "Admin" AND `alias` != "guest"')
        true
      rescue => e
        puts "Could not truncate tables in MySQL: #{e.class} -- #{e.message}"
        puts e.backtrace
        false
      end
    end

    def self.create_integration_test_user_and_group
      return unless $RUBIX_MYSQL
      begin
        $RUBIX_MYSQL.query(%Q{INSERT INTO users        (`alias`, `name`, surname, passwd, type) VALUES ("#{INTEGRATION_USER}", "Rubix", "Spec User", "#{Digest::MD5.hexdigest('rubix')}", 3)})
        # $RUBIX_MYSQL.query(%Q{INSERT INTO usrgrp       (`name`, api_access)                     VALUES ("#{INTEGRATION_GROUP}", 1)})
        $RUBIX_MYSQL.query(%Q{INSERT INTO users_groups (usrgrpid, userid)                       SELECT users.userid, usrgrp.usrgrpid FROM users, usrgrp WHERE users.alias = '#{INTEGRATION_USER}' AND usrgrp.name = '#{INTEGRATION_GROUP}'})
        true
      rescue => e
        puts "Could not create integration user or group: #{e.class} -- #{e.message}"
        puts e.backtrace
        false
      end
    end

    def self.connect_to_api
      return unless $RUBIX_API_CREDENTIALS
      begin
        $RUBIX_API = Rubix::Connection.new($RUBIX_API_CREDENTIALS['url'], INTEGRATION_USER, INTEGRATION_PASSWORD)
        $RUBIX_API.authorize!
        Rubix.connection = $RUBIX_API
      rescue => e
        puts "Could not connect to Zabbix API: #{e.class} -- #{e.message}"
        puts e.backtrace
        false
      end
    end

    def integration_test
      if $RUBIX_INTEGRATION
        raise Rubix::Error.new("Could not truncate tables in MySQL.")         unless IntegrationHelper.truncate_all_tables
        raise Rubix::Error.new("Could not create integration user or group.") unless IntegrationHelper.create_integration_test_user_and_group
        raise Rubix::Error.new("Could not connect to Zabbixi API.")           unless IntegrationHelper.connect_to_api
      else
        pending("A live Zabbix API to test against")
      end
    end

    def ensure_save(obj)
      begin
        raise Rubix::Error.new(Rubix.connection.last_response.body) unless obj.save
        obj
      rescue => e
        puts "#{e.class} -- #{e.message}"
        puts e.backtrace
        raise e
      end
    end

    def ensure_destroy *objs, &block
      begin
        if block_given?
          yield
        else
          errors = []
          objs.each do |obj|
            errors << Rubix.connection.last_response.body unless obj.destroy
          end
          raise Rubix::Error.new(errors.join("\n")) if errors.size > 0
        end
      rescue => e
        puts "#{e.class} -- #{e.message}"
        puts e.backtrace
        objs.each do |obj|
          begin
            puts "COULD NOT DESTROY #{obj.resource_name}" unless obj.destroy
          rescue => f
            puts "COULD NOT DESTROY #{obj.resource_name}"
            puts "#{e.class} -- #{e.message}"
            puts e.backtrace
          end
        end
        raise e
      end
    end
    
    def create_history item
      raise Rubix::Error.new("Not connected to MySQL") unless $RUBIX_MYSQL
      (1..10).to_a.collect do |i|
        history = { "itemid" => item.id.to_s, "clock" => (Time.now.to_i - 5*i).to_s, "value" => rand(100).to_s }
        $RUBIX_MYSQL.query("INSERT INTO history_uint (#{history.keys.join(', ')}) VALUES (#{history.values.join(', ')})")
        history
      end
    end

    def truncate_all_tables
      IntegrationHelper.truncate_all_tables
    end

    def data_path *args
      File.join(File.expand_path('../../data', __FILE__), *args)
    end

  end
end
