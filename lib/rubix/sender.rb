require 'rubix/log'
require 'socket'
require 'multi_json'

module Rubix

  # A class used to send data to Zabbix.
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

    include Logs

    #
    # == Properties & Initialization ==
    #

    # Create a new sender with the given +settings+.
    #
    # @param [Hash, Configliere::Param] settings
    # @param settings [String, Rubix::Host] host the name of the Zabbix host to write data for
    # @param settings [String] server the IP of the Zabbix server
    # @param settings [Fixnum] port the port to connect to on the Zabbix server
    def initialize settings={}
      @settings = settings
      self.server     = settings[:server] if settings[:server]
      self.host       = settings[:host]   if settings[:host]
      self.port       = settings[:port]   if settings[:port]
    end

    # The hostname of the Zabbix server to connect to.  Defaults to
    # +localhost+.
    #
    # @return [String]
    def server ; @server ||= 'localhost' ; end
    
    # Set the hostname of the Zabbix server to connect to.
    #
    # @param [String] hostname
    def server= hostname ; @server = hostname ; end

    # The port of the Zabbix server to connect to.  Defaults to 10051.
    #
    # @return [Integer]
    def port ; @port ||= 10051 ; end
    
    # Set the port of the Zabbix server to connect to.
    #
    # @param [Integer] num
    def port= num ; @port = num ; end

    # The name of the default Zabbix host that measurements will be
    # associated with if not provided.  Defaults to +localhost+.
    #
    # @return [String]
    def host
      @host ||= 'localhost'
    end
    
    # Set the name of the default Zabbix host associated with
    # measurements.
    #
    # @param [String, Rubix::Host] hostname
    def host= hostname
      @host = (hostname.respond_to?(:name) ? hostname.name : hostname.to_s)
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
    # @param [Hash, Array<Hash>] measurements
    def transmit measurements=[]
      self.socket = TCPSocket.new(host, port)
      send_request([measurements].flatten)
      handle_response
      self.socket.close
    end
    alias_method :<< , :transmit

    # Format a given measurement for Zabbix.
    #
    # Will add the default +host+ of this Sender if not set.
    #
    # @param [Hash] measurement
    # @return [Hash]
    def format_measurement measurement
      {:host => host}.merge(measurement)
    end
    
    private
    
    # :nodoc
    def send_request measurements=[]
      socket.write(payload(measurements))
    end

    # :nodoc
    def handle_response
      header = socket.recv(5)
      if header == "ZBXD\1"
        data_header = socket.recv(8)
        length      = data_header[0,4].unpack("i")[0]
        response    = MultiJson.load(socket.recv(length))
        info(response["info"])
      else
        warn("Invalid response: #{header}")
      end
    end

    # :nodoc
    def payload measurements=[]
      body = body_for(host, measurements)
      header_for(body) + body
    end

    # :nodoc
    def body_for host, measurements=[]
      MultiJson.dump({
        request: "sender data",
        data: measurements.map { |measurement| format_measurement(measurement) }
      })
    end

    # :nodoc
    def header_for body
      length = body.bytesize
      "ZBXD\1".encode("ascii") + [length].pack("i") + "\x00\x00\x00\x00"
    end
    
  end
end
