require 'rubygems'

require 'rubix/log'
require 'rubix/models'
require 'rubix/associations'
require 'rubix/monitors'

module Rubix

  autoload :Connection,     'rubix/connection'
  autoload :Response,       'rubix/response'
  autoload :Sender,         'rubix/sender'
  
  def self.connect server, username=nil, password=nil
    self.connection = Connection.new(server, username, password)
  end

  def self.connection= connection
    @connection = connection
  end

  def self.connection
    @connection ||= Connection.new('http://localhost/api_jsonrpc.php', 'admin', 'zabbix')
    return @connection if @connection.authorized?
    raise ConnectionError.new("Could not authorize with Zabbix API at #{@connection.uri}") unless @connection.authorize!
    @connection
  end

  Error               = Class.new(RuntimeError)
  ConnectionError     = Class.new(Error)
  AuthenticationError = Class.new(Error)
  RequestError        = Class.new(Error)
  ValidationError     = Class.new(Error)
  
end
