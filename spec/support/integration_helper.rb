module Rubix
  module IntegrationHelper
    
    def integration_test
      pending("A live Zabbix API to test against") unless $RUBIX_INTEGRATION_TEST
    end

    def ensure_save(obj)
      begin
        raise Rubix::Error.new(Rubix.connection.last_response.error_message) unless obj.save
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
            errors << Rubix.connection.last_response.error_message unless obj.destroy
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

    def self.setup_integration_tests test_yml_path
      return unless File.exist?(test_yml_path)
      
      require 'yaml'
      test_data = YAML.load(open(test_yml_path))
      return if test_data['disable_integration_tests']
      
      api_connection = test_data['api']
      mysql_connection = test_data['mysql']
      return unless api_connection && mysql_connection

      Rubix.connect(api_connection['url'], api_connection['username'], api_connection['password'])
      
      require 'mysql2'
      $RUBIX_MYSQL_CLIENT = Mysql2::Client.new(:host => mysql_connection['host'], :username => mysql_connection['username'], :password => mysql_connection['password'], :database => mysql_connection['database'])

      truncate_all_tables

      $RUBIX_INTEGRATION_TEST = true
    end

    RUBIX_TABLES_TO_TRUNCATE = %w[applications groups hostmacro hosts hosts_groups hosts_profiles hosts_profiles_ext hosts_templates items items_applications profiles triggers trigger_depends]
    
    def self.truncate_all_tables
      return unless $RUBIX_INTEGRATION_TEST
      RUBIX_TABLES_TO_TRUNCATE.each { |table| $RUBIX_MYSQL_CLIENT.query("TRUNCATE TABLE #{table}") }
    end

    def truncate_all_tables
      IntegrationHelper.truncate_all_tables
    end
    
  end
end
