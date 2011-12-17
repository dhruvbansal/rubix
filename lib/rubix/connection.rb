require 'uri'
require 'net/http'
require 'json'

require 'rubix/log'

module Rubix

  # Wraps and abstracts the process of connecting to a Zabbix API.
  class Connection

    include Logs

    # @return [URI] The URI for the Zabbix API.
    attr_reader :uri

    # @return [Net::HTTP] the HTTP server backing the Zabbix API.
    attr_reader :server

    # @return [String] the authentication token provided by the Zabbix
    # API for this session.
    attr_reader :auth

    # @return [Fixnum] the ID of the next request that will be sent.
    attr_reader :request_id

    # @return [String] the username of the Zabbix account used to authenticate
    attr_reader :username

    # @return [String] the password of the Zabbix account used to authenticate
    attr_reader :password

    # @return [Rubix::Response] the last response from the Zabbix API -- useful for logging purposes
    attr_reader :last_response

    # Set up a connection to a Zabbix API.
    #
    # The +uri_or_string+ can be either a string or a <tt>URI</tt>
    # object.
    #
    # The +username+ and +password+ provided must correspond to an
    # existing Zabbix account with API access enabled.
    #
    # @param [URI,String] uri_or_string the address of the Zabbix API server to connect to
    # @param [String] username the username of an existing Zabbix API <tt>User</tt> account with API access
    # @param [String] password the password for this account
    def initialize uri_or_string, username=nil, password=nil
      self.uri    = uri_or_string
      @username   = username || uri.user
      @password   = password || uri.password
      @request_id = 0
    end

    # Send a request to the Zabbix API.  Will return a Rubix::Response
    # object.
    #
    # Documentation on what methods and parameters are available can
    # be found in the {Zabbix API
    # documentation}[http://www.zabbix.com/documentation/1.8/api]
    #
    #   Rubix.connection.request 'host.get', 'filter' => { 'host' => 'foobar' }
    #
    # @param [String] method the name of the Zabbix API method
    # @param [Hash,Array] params parameters for the method call
    # @retrn [Rubix::Response]
    def request method, params
      authorize! unless authorized?
      till_response do
        raw_params = {
          :jsonrpc => "2.0",
          :id      => request_id,
          :method  => method,
          :params  => params,
          :auth    => auth
        }
        send_raw_request(raw_params)
      end
    end

    # Has this connection already been authorized and provided with a
    # authorization token from the Zabbix API?
    def authorized?
      !auth.nil?
    end

    # Force the connection to execute an authorization request and
    # renew (or set) the authorization token.
    def authorize!
      response = till_response { send_raw_request(authorization_params) }
      raise AuthenticationError.new("Could not authenticate with Zabbix API at #{uri}: #{response.error_message}") if response.error?
      raise AuthenticationError.new("Malformed response from Zabbix API: #{response.body}") unless response.string?
      @auth = response.result
    end

    # Set the URI for this connection's Zabbix API server.
    #
    # @param [String, URI] uri_or_string the address of the Zabbix API.
    # @return [Net::HTTP]
    def uri= uri_or_string
      if uri_or_string.respond_to?(:host)
        @uri = uri_or_string
      else
        string = uri_or_string =~ /^http/ ? uri_or_string : 'http://' + uri_or_string.to_s
        @uri = URI.parse(string)
      end
      @server = Net::HTTP.new(uri.host, uri.port)
    end

    protected

    # The parameters used for constructing an authorization request
    # with the Zabbix API.
    #
    # @return [Hash]
    def authorization_params
      {
        :jsonrpc => "2.0",
        :id      => request_id,
        :method  => "user.login",
        :params  => {
          :user     => username,
          :password => password
        }
      }
    end

    # Attempt to execute a query until a non-5xx response is returned.
    #
    # 5xx responses can occur because the backend PHP server providing
    # the Zabbix API can sometimes be unavailable if the serer is
    # restarting or something like that.  We keep trying until that
    # doesn't happen.
    #
    # You shouldn't have to use this method directly -- the
    # <tt>Rubix::Connection#authorize!</tt> and
    # <tt>Rubix::Connection#request</tt> methods already use this
    # functionality.
    def till_response attempt=1, max_attempts=5, &block
      response = block.call
      Rubix.logger.log(Logger::DEBUG, "RECV: #{response.body}") if Rubix.logger
      case
      when response.code.to_i >= 500 && attempt <= max_attempts
        sleep 1                 # FIXME make the sleep time configurable...
        till_response(attempt + 1, max_attempts, &block)
      when response.code.to_i >= 500
        raise ConnectionError.new("Too many consecutive failed requests (#{max_attempts}) to the Zabbix API at (#{uri}).")
      else
        @last_response = Response.new(response)
      end
    end

    # Send the POST request to the Zabbix API.
    #
    # @param [Hash, #to_json] raw_params the complete parameters of the request.
    # @return [Net::HTTP::Response]
    def send_raw_request raw_params
      @request_id += 1
      begin
        raw_response = server.request(raw_post_request(raw_params))
      rescue NoMethodError, SocketError => e
        raise RequestError.new("Could not connect to Zabbix server at #{host_with_port}")
      end
      raw_response
    end

    # Generate the raw POST request to send to the Zabbix API
    #
    # @param [Hash, #to_json] raw_params the complete parameters of the request.
    # @return [Net::HTTP::Post]
    def raw_post_request raw_params
      json_body = raw_params.to_json
      Rubix.logger.log(Logger::DEBUG, "SEND: #{json_body}") if Rubix.logger
      Net::HTTP::Post.new(uri.path).tap do |req|
        req['Content-Type'] = 'application/json-rpc'
        req.body            = json_body
      end
    end

    # Used for generating helpful error messages.
    #
    # @return [String]
    def host_with_port
      if uri.port.nil? || uri.port.to_i == 80
        uri.host
      else
        "#{uri.host}:#{uri.port}"
      end
    end

  end
end
