require 'uri'
require 'cgi'
require 'net/http'
require 'net/https'
require 'yajl'

require 'rubix/log'

module Rubix

  # Wraps and abstracts the process of connecting to a Zabbix API.
  class Connection

    include Logs

    # The name of the cookie used by the Zabbix web application.  Used
    # when emulating a request from a browser.
    COOKIE_NAME = 'zbx_sessionid'

    # The content type header to send when emulating a browser.
    CONTENT_TYPE = 'multipart/form-data'

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
    # @return [Rubix::Response]
    def request method, params
      authorize! unless authorized?
      response = till_response do
        send_api_request :jsonrpc => "2.0",
        :id      => request_id,
        :method  => method,
        :params  => params,
        :auth    => auth
      end
      Response.new(response)
    end

    # Send a request to the Zabbix web application.  The request is
    # designed to emulate a web browser.
    #
    # Any values in +data+ which are file handles will trigger a
    # multipart POST request, uploading those files.
    #
    # @param [String] verb one of "GET" or "POST"
    # @param [String] path the path to send the request to
    # @param [Hash] data the data to include in the request
    # @return [Net::HTTP::Response]
    def web_request verb, path, data={}
      authorize! unless authorized?
      till_response do
        send_web_request(verb, path, data)
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
      response = Response.new(till_response { send_api_request(authorization_params) })
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
      if @uri.scheme == 'https'
        @server.use_ssl = true
      end
      return @server
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
    # During long-running connections, the Zabbix server can reap the
    # existing session if some time has passed since the last request
    # from this Connection.  This method will also refresh the
    # connection in that instance.
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
      when response.code.to_i == 200 && authorized? && response.body =~ /-32602/ && response.body =~ /Not authorized/
        authorize!
        till_response(attempt, max_attempts, &block)
      else
        @last_response = response
      end
    end

    # Send the POST request to the Zabbix API.
    #
    # @param [Hash, #to_json] raw_params the complete parameters of the request.
    # @return [Net::HTTP::Response]
    def send_api_request raw_params
      @request_id += 1
      begin
        raw_response = server.request(raw_api_request(raw_params))
      rescue NoMethodError, Errno::ECONNREFUSED, SocketError => e
        raise RequestError.new("Could not connect to Zabbix server at #{host_with_port}")
      end
      raw_response
    end

    # Send a Web request to Zabbix.
    #
    # The existing authorization token will be used to emulate a
    # request sent by a browser.
    #
    # Any values in +data+ which are file handles will trigger a
    # multipart POST request, uploading those files.
    #
    # @param [String] verb one of "GET" or "POST"
    # @param [String] path the path to send the request to
    # @param [Hash] data the data to include in the request
    def send_web_request verb, path, data={}
      # Don't increment this for web requests?
      # @request_id += 1
      begin
        raw_response = server.request(raw_web_request(verb, path, data))
      rescue NoMethodError, Errno::ECONNREFUSED, SocketError => e
        raise RequestError.new("Could not connect to the Zabbix server at #{host_with_port}")
      end
    end

    # Generate the raw POST request to send to the Zabbix API
    #
    # @param [Hash, #to_json] raw_params the complete parameters of the request.
    # @return [Net::HTTP::Post]
    def raw_api_request raw_params
      json_body = raw_params.to_json
      Rubix.logger.log(Logger::DEBUG, "SEND: #{json_body}") if Rubix.logger
      Net::HTTP::Post.new(uri.path).tap do |req|
        req['Content-Type'] = 'application/json-rpc'
        req['User-Agent']   = "Rubix v. #{Rubix.version}"
        req.body            = json_body
      end
    end

    # Generate a raw web request to send to the Zabbix web application
    # as though it came from a browser.
    #
    # @param [String] verb the HTTP verb, either "GET" (default) or "POST"
    # @param [String] path the path on the server to send the request to
    # @param [Hash]   data the data for the request
    def raw_web_request verb, path, data={}
      case
      when verb == "GET"
        raw_get_request(path)
      when verb == "POST" && data.values.any? { |value| value.respond_to?(:read) }
        raw_multipart_post_request(path, data)
      when verb == "POST"
        raw_post_request(path, data)
      else
        raise Rubix::RequestError.new("Invalid HTTP verb: #{verb}")
      end
    end

    # Generate an authenticated GET request emulating a browser.
    #
    # @param [String] path the path to send the request to.
    # @return [Net::HTTP::Get]
    def raw_get_request(path)
      Net::HTTP::Get.new(path).tap do |req|
        req['Content-Type'] = self.class::CONTENT_TYPE
        req['Cookie']       = "#{self.class::COOKIE_NAME}=#{CGI::escape(auth.to_s)}"
      end
    end

    # Generate an authenticated POST request emulating a browser.  It
    # is assumed that +data+ is not multipart data.
    #
    # @param [String] path the path to send the request to.
    # @param [Hash] data the data to send
    # @return [Net::HTTP::Post]
    def raw_post_request(path, data={})
      Net::HTTP::Post.new(path).tap do |req|
        req['Content-Type'] = self.class::CONTENT_TYPE
        req['Cookie']       = "#{self.class::COOKIE_NAME}=#{CGI::escape(auth.to_s)}"
        req.body            = formatted_post_body(data)
      end
    end

    # Generate an authenticated POST request emulating a browser.
    # Assumes data is multipart data, with some values being file
    # handles.
    #
    # @param [String] path the path to send the request to.
    # @param [Hash] data the data to send
    # @return [Net::HTTP::Post::Multipart]
    def raw_multipart_post_request(path, data={})
      require 'net/http/post/multipart'
      Net::HTTP::Post::Multipart.new(path, wrapped_multipart_post_data(data)).tap do |req|
        req['Cookie'] = "#{self.class::COOKIE_NAME}=#{CGI::escape(auth.to_s)}"
      end
    end

    # Wrap +data+ with +UploadIO+ objects so that it can be properly
    # handled by the Net::HTTP::Post::Multipart class.
    #
    # @param [Hash] data
    # @return [Hash]
    def wrapped_multipart_post_data data
      {}.tap do |wrapped|
        data.each_pair do |key, value|
          if value.respond_to?(:read)
            # We are going to assume it's always XML we're uploading.
            wrapped[key] = UploadIO.new(value, "application/xml", File.basename(value.path))
          else
            wrapped[key] = value
          end
        end
      end
    end

    # Format +data+ as a POST data string.
    #
    # @param [Hash] data
    # @return [String]
    def formatted_post_body data
      [].tap do |pairs|
        data.each_pair do |key, value|
          pairs << [key, value].map { |s| CGI::escape(s.to_s) }.join('=')
        end
      end.join('&')
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
