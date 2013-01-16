module Rubix
  class DatabaseHelper

    attr_accessor :result

    def initialize config
      begin
        if config['postgresql']
          require 'pg'
          @conn = PG::Connection.new(:host => config['postgresql']['host'], :user => config['postgresql']['username'],
                                     :password => config['postgresql']['password'], :dbname => config['postgresql']['database'],
                                     :port => config['postgresql']['port'])
        elsif config['mysql']
          require 'mysql2'
          @conn = Mysql2::Client.new(:host => config['mysql']['host'], :username => config['mysql']['username'], :password => config['mysql']['password'],
                                     :database => config['mysql']['database'])
        end
        @result = true
      rescue => e
        puts "Could not connect to database: #{e.class} -- #{e.message}"
        puts e.backtrace
        @result = false
      end
    end

    def truncate_all_tables
      return unless result
      begin
        %w[actions graphs triggers items applications hosts usrgrp].each do |table|
          @conn.query("DELETE FROM #{table}")
        end
        @conn.query('DELETE FROM groups WHERE internal != 1')
        @conn.query(%Q[DELETE FROM users  WHERE alias    != 'Admin' AND 'alias' != 'guest'])
        true
      rescue => e
        puts "Could not truncate tables: #{e.class} -- #{e.message}"
        puts e.backtrace
        false
      end
    end

    def create_integration_test_user_and_group(user, group, password)
      return unless result
      begin
        @conn.query(%Q{INSERT INTO users        (userid, alias, name, surname, passwd, type) VALUES (42, '#{user}', 'Rubix', 'Spec User', '#{Digest::MD5.hexdigest(password)}', 3)})
        @conn.query(%Q{INSERT INTO usrgrp       (usrgrpid, name, gui_access)                     VALUES (42, '#{group}', 1)})
        @conn.query(%Q{INSERT INTO users_groups (id, usrgrpid, userid)                       SELECT 42, users.userid, usrgrp.usrgrpid FROM users, usrgrp WHERE users.alias = '#{user}' AND usrgrp.name = '#{group}'})
        true
      rescue => e
        puts "Could not create integration user or group: #{e.class} -- #{e.message}"
        puts e.backtrace
        false
      end
    end
  end
end
