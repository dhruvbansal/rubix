require 'rubix/log'
require 'socket'
require 'multi_json'

module Rubix

  # Used to send measurements of pre-defined items to Zabbix.
  #
  # It acts as a pure-Ruby implementation of the +zabbix_sender+
  # utility.
  #
  # The following links provide details on the protocol used by Zabbix
  # to receive data:
  #
  # * https://www.zabbix.com/forum/showthread.php?t=20047&highlight=sender
  # * https://gist.github.com/1170577
  # * http://spin.atomicobject.com/2012/10/30/collecting-metrics-from-ruby-processes-using-zabbix-trappers/?utm_source=rubyflow&utm_medium=ao&utm_campaign=collecting-metrics-zabix
  class Sender

    # Used to encapsulate the wire protcol used by Zabbix.
    #
    # The protocol consists of a JSON-encoded body and a binary header
    # which encodes the length of the body in bytes.
    class Request

      HEADER = "ZBXD\1".encode("ascii")
      FOOTER = "\x00\x00\x00\x00"

      # Create a new request for the sender.
      #
      # @param [Array<Hash>] measurements
      def initialize *measurements
        @measurements = measurements.flatten.compact
      end

      # :nodoc:
      def to_s
        header + body
      end

      # :nodoc:
      def header
        HEADER + [body.bytesize].pack("i") + FOOTER
      end

      # :nodoc:
      def body
        @body ||= MultiJson.dump({request: "sender data", data: @measurements})
      end
    end

    # The default Zabbix server hostname used when none is provided at startup.
    DEFAULT_SERVER_HOSTNAME = 'localhost'

    # The default Zabbix server port used when none is provided at startup.
    DEFAULT_SERVER_PORT     = 10051

    # The default Zabbix host to write data for when none is provided
    # at startup or with the data to be written.
    DEFAULT_HOST            = (ENV['HOSTNAME'] || 'localhost')

    include Logs

    #
    # == Properties & Initialization ==
    #

    # Hostname of Zabbix server to connect to.
    attr_accessor :server

    # Port of Zabbix server to connect to.
    attr_accessor :port

    # Host to write data for when none is provided with the data
    # itself.
    attr_reader :host

    # Set the host to write data for when none is provided with the
    # data itself.
    #
    # @param [String, Rubix::Host] host
    # @return [String] the name of the host
    def host= host
      @host = host.respond_to?(:name) ? host.name : host.to_s
    end

    # Create a new sender with the given +settings+.
    #
    # @param [Hash, Configliere::Param] settings
    # @param settings [String, Rubix::Host] host the name of the default Zabbix host
    # @param settings [String] server the hostname of the Zabbix server
    # @param settings [Fixnum] port the port to connect to on the Zabbix server
    def initialize settings={}
      @settings = settings
      self.server     = (settings[:server] || DEFAULT_SERVER_HOSTNAME)
      self.port       = (settings[:port]   || DEFAULT_SERVER_PORT)
      self.host       = (settings[:host]   || DEFAULT_HOST)
    end
    
    #
    # == Sending Data == 
    #

    attr_accessor :socket

    # Send measurements to a Zabbix server.
    #
    # Each measurement passed should be a Hash with the following keys:
    #
    # * +host+ the host that was measured (will default to the host for this sender)
    # * +key+ the key of the item that was measured
    # * +value+ the value that was measured for the item
    #
    # and optionally:
    #
    # * +time+ the UNIX timestamp at time of measurement
    #
    # The Zabbix server must already have a monitored host with the
    # given item set to be a "Zabbix trapper" type.
    #
    # As per the documentation for the [Zabbix sender
    # protocol](https://www.zabbix.com/wiki/doc/tech/proto/zabbixsenderprotocol),
    # a new TCP connection will be created for each batch of
    # measurements.
    #
    # @param [Array<Hash>] measurements
    def transmit measurements
      self.socket = TCPSocket.new(host, port)
      send_request(create_request(measurements))
      handle_response
      self.socket.close
    end
    alias_method :<< , :transmit

    # Format the given measurement for Zabbix.
    #
    # Will add the default +host+ of this Sender if not set.
    #
    # @param [Hash] measurement
    # @return [Hash] the modified measurement
    def format_measurement measurement
      measurement[:host] ||= host
      measurement
    end
    
    private

    # :nodoc:
    def create_request measurements
      Request.new(*measurements.map { |measurement| format_measurement(measurement) })
    end

    # :nodoc:
    def send_request request
      socket.write(request)
    end

    # :nodoc:
    def handle_response
      header = socket.recv(5)
      if header == "ZBXD\1"     # FIXME -- use constant named above in Request
        data_header = socket.recv(8)
        length      = data_header[0,4].unpack("i")[0]
        response    = MultiJson.load(socket.recv(length))
        debug(response["info"])
      else
        warn("Invalid response: #{header}")
      end
    end
    
  end
end
