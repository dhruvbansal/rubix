require 'rubygems'
require 'rubix/log'
module Rubix

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

  autoload :Connection,     'rubix/connection'
  autoload :Response,       'rubix/response'

  autoload :Model,          'rubix/model'
  autoload :HostGroup,      'rubix/models/host_group'
  autoload :Template,       'rubix/models/template'
  autoload :Host,           'rubix/models/host'
  autoload :Item,           'rubix/models/item'
  autoload :Application,    'rubix/models/application'
  
  autoload :Monitor,        'rubix/monitor'
  autoload :ChefMonitor,    'rubix/monitors/chef_monitor'
  autoload :ClusterMonitor, 'rubix/monitors/cluster_monitor'

  autoload :Sender,         'rubix/sender'

  Error               = Class.new(RuntimeError)
  ConnectionError     = Class.new(Error)
  AuthenticationError = Class.new(Error)
  RequestError        = Class.new(Error)
  ValidationError     = Class.new(Error)
  
end
