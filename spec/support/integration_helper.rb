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
        puts "Could not connect to a database using: #{$CONFIG['postgresql'].inspect}.  Integration tests will be skipped."
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
        puts "Could not connect to Zabbix API using: #{$CONFIG['api']}.  Integration tests will be skipped."
        return
      end
      $RUBIX_INTEGRATION = true
    end

    def self.parse_integration_settings test_yml_path
      return unless File.exist?(test_yml_path)

      require 'yaml'
      test_data = YAML.load(open(test_yml_path))
      return if test_data['disable_integration_tests']

      $CONFIG = test_data
    end

    def self.connect_to_database
      begin
        require 'pg'
        $CONN = PG::Connection.new(:host => $CONFIG['postgresql']['host'], :user => $CONFIG['postgresql']['username'],
                                   :password => $CONFIG['postgresql']['password'], :dbname => $CONFIG['postgresql']['database'],
                                   :port => $CONFIG['postgresql']['port'])
      rescue => e
        puts "Could not connect to database: #{e.class} -- #{e.message}"
        puts e.backtrace
        false
      end
    end

    # These are the tables we'll truncate in the database.
    RUBIX_TABLES_TO_TRUNCATE = %w[actions conditions operations opconditions applications groups hostmacro hosts hosts_groups hosts_templates items items_applications profiles triggers trigger_depends history sessions media_type scripts users usrgrp users_groups]

    def self.truncate_all_tables
      return unless $CONN
      begin
        RUBIX_TABLES_TO_TRUNCATE.each { |table| $CONN.query("TRUNCATE TABLE #{table} CASCADE") }
        true
      rescue => e
        puts "Could not truncate tables: #{e.class} -- #{e.message}"
        puts e.backtrace
        false
      end
    end

    def self.create_integration_test_user_and_group
      return unless $CONN
      begin
        $CONN.query(%Q{INSERT INTO users        (userid, alias, name, surname, passwd, type) VALUES (42, '#{INTEGRATION_USER}', 'Rubix', 'Spec User', '#{Digest::MD5.hexdigest('rubix')}', 3)})
        $CONN.query(%Q{INSERT INTO usrgrp       (usrgrpid, name, gui_access)                     VALUES (42, '#{INTEGRATION_GROUP}', 1)})
        $CONN.query(%Q{INSERT INTO users_groups (id, usrgrpid, userid)                       SELECT 42, users.userid, usrgrp.usrgrpid FROM users, usrgrp WHERE users.alias = '#{INTEGRATION_USER}' AND usrgrp.name = '#{INTEGRATION_GROUP}'})
        true
      rescue => e
        puts "Could not create integration user or group: #{e.class} -- #{e.message}"
        puts e.backtrace
        false
      end
    end

    def self.connect_to_api
      return unless $CONFIG['api']
      begin
        $RUBIX_API = Rubix::Connection.new($CONFIG['api'], INTEGRATION_USER, INTEGRATION_PASSWORD)
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
