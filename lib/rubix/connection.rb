require 'uri'
require 'net/http'
require 'json'

require 'rubix/log'

module Rubix

  class Connection

    include Logs

    attr_reader :uri, :server, :auth, :request_id, :username, :password, :last_response

    def initialize uri_or_string, username=nil, password=nil
      self.uri    = uri_or_string
      @username   = username || uri.user
      @password   = password || uri.password
      @request_id = 0
    end

    def uri= uri_or_string
      if uri_or_string.respond_to?(:host)
        @uri = uri_or_string
      else
        string = uri_or_string =~ /^http/ ? uri_or_string : 'http://' + uri_or_string.to_s
        @uri = URI.parse(string)
      end
      @server = Net::HTTP.new(uri.host, uri.port)
    end

    def authorized?
      !auth.nil?
    end

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

    def authorize!
      response = till_response { send_raw_request(authorization_params) }
      raise AuthenticationError.new("Could not authenticate with Zabbix API at #{uri}: #{response.error_message}") if response.error?
      raise AuthenticationError.new("Malformed response from Zabbix API: #{response.body}") unless response.string?
      @auth        = response.result
    end

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

    def raw_post_request raw_params
      json_body = raw_params.to_json
      Rubix.logger.log(Logger::DEBUG, "SEND: #{json_body}") if Rubix.logger
      Net::HTTP::Post.new(uri.path).tap do |req|
        req['Content-Type'] = 'application/json-rpc'
        req.body            = json_body
      end
    end

    def host_with_port
      if uri.port.nil? || uri.port.to_i == 80
        uri.host
      else
        "#{uri.host}:#{uri.port}"
      end
    end

    def send_raw_request raw_params
      @request_id += 1
      begin
        raw_response = server.request(raw_post_request(raw_params))
      rescue NoMethodError, SocketError => e
        raise RequestError.new("Could not connect to Zabbix server at #{host_with_port}")
      end
      raw_response
    end

  end
end
