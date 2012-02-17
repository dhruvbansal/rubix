require 'rubygems'

require 'rubix/log'
require 'rubix/models'
require 'rubix/associations'
require 'rubix/monitors'

module Rubix

  autoload :Connection,     'rubix/connection'
  autoload :Response,       'rubix/response'
  autoload :Sender,         'rubix/sender'
  autoload :AutoSender,     'rubix/auto_sender'

  # Set up a <tt>Connection</tt> to a Zabbix API server.
  #
  # Only needs to be called once.
  #
  #   # These are the defaults
  #   Rubix.connect 'localhost', 'admin', 'zabbix'
  #
  #   # A server running on a custom port with different
  #   # credentials...
  #   Rubix.connect 'my.server.com:8080', 'foobar', 'bazbooz'
  #
  # @param [URI,String] server the address of the Zabbix API server to connect to
  # @param [String] username the username of an existing Zabbix API <tt>User</tt> account with API access
  # @param [String] password the password for this account
  # @return [Rubix::Connection]
  def self.connect server, username=nil, password=nil
    self.connection = Connection.new(server, username, password)
  end

  # Explicitly set the connection using a <tt>Rubix::Connection</tt>
  # object.
  #
  #   Rubix.connection = Rubix::Connection.new('http://localhost/api_jsonrpc.php', 'admin', 'zabbix')
  #
  # @param [Rubix::Connection] connection
  # @return [Rubix::Connection]
  def self.connection= connection
    @connection = connection
  end

  # Is Rubix presently connected to a Zabbix server?
  #
  # @return [true, false]
  def self.connected?
    (!! connection)
  end

  # Is Rubix presently connected and authorized with a Zabbix server?
  #
  # @return [true, false]
  def self.authorized?
    connection && connection.authorized?
  end

  # Return the current connection to a Zabbix API.  Useful for
  # directly sending queries.
  #
  #   Rubix.connection.request 'host.get', :filter => { "name" => "foobar" }
  #
  # @return [Rubix::Connection]
  def self.connection
    @connection ||= Connection.new('http://localhost/api_jsonrpc.php', 'admin', 'zabbix')
    return @connection if @connection.authorized?
    raise ConnectionError.new("Could not authorize with Zabbix API at #{@connection.uri}") unless @connection.authorize!
    @connection
  end

  # Base class for Rubix errors.
  Error               = Class.new(RuntimeError)

  # Errors with connecting to a Zabbix API.
  ConnectionError     = Class.new(Error)

  # Error authenticating with a Zabbix API.
  AuthenticationError = Class.new(Error)

  # Error in a request to a Zabbix API.
  RequestError        = Class.new(Error)

  # Error detected locally in an API resource that will prevent it
  # from being saved by the Zabbix API (i.e. - no host group for a
  # host).
  ValidationError     = Class.new(Error)

  # Given an incorrect argument.
  ArgumentError       = Class.new(Error)
  
end
