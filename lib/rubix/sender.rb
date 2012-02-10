require 'rubix/log'
require 'open3'

module Rubix

  # A class used to send data to Zabbix.
  #
  # This sender is used to wrap +zabbix_sender+.
  class Sender

    include Logs

    #
    # == Properties ==
    #

    # @return [String] The IP of the Zabbix server
    attr_writer :server
    def server
      @server ||= 'localhost'
    end

    # @return [String, Rubix::Hosts] the Zabbix host name or Rubix::Host the sender will use by default
    attr_reader :host
    def host= nh
      @host = (nh.respond_to?(:name) ? nh.name : nh.to_s)
    end

    # @return [Fixnum] the port to connect to on the Zabbix server
    attr_writer :port
    def port
      @port ||= 10051
    end

    # @return [String] the path to the local Zabbix agent configuration file.
    attr_writer :config
    def config
      @config ||= '/etc/zabbix/zabbix_agentd.conf'
    end

    # Whether or not to include timestamps with the data.
    attr_writer :timestamps
    def timestamps?
      @timestamps
    end

    #
    # == Initialization ==
    #

    # Create a new sender with the given +settings+.
    #
    # @param [Hash, Configliere::Param] settings
    # @param settings [String, Rubix::Host] host the name of the Zabbix host to write data for
    # @param settings [String] server the IP of the Zabbix server
    # @param settings [Fixnum] port the port to connect to on the Zabbix server
    # @param settings [String] config the path to the local configuration file
    def initialize settings={}
      @settings = settings
      self.server     = settings[:server] if settings[:server]
      self.host       = settings[:host]   if settings[:host]
      self.port       = settings[:port]   if settings[:port]
      self.config     = settings[:config] if settings[:config]
      self.timestamps = settings[:timestamps]
      confirm_settings
    end

    # Check that all settings are correct in order to be able to
    # successfully write data to Zabbix.
    def confirm_settings
      raise Error.new("Must specify a path to a local configuraiton file")    unless config
      raise Error.new("Must specify the IP of a Zabbix server")               unless server
      raise Error.new("Must specify the port of a Zabbix server")             unless port && port.to_i > 0
      raise Error.new("Must specify a default Zabbix host to write data for") unless host
    end
    
    #
    # == Sending Data == 
    #

    # The environment for the Zabbix sender invocation.
    #
    # @return [Hash]
    def zabbix_sender_env
      {}
    end

    # Construct the command that invokes Zabbix sender.
    #
    # @return [String]
    def zabbix_sender_command
      "timeout 3 zabbix_sender --zabbix-server #{server} --host #{host} --port #{port} --config #{config} --real-time --input-file - -vv".tap do |c|
        c += " --with-timestamps" if timestamps?
      end
    end

    # Run a +zabbix_sender+ subprocess in the block.
    #
    # @yield [IO, IO, IO, Thread] Handle the subprocess.
    def with_sender_subprocess &block
      begin
        Open3.popen3(zabbix_sender_env, zabbix_sender_command, &block)
      rescue Errno::ENOENT, Errno::EACCES => e
        warn(e.message)
      end
    end

    # Convenience method for sending a block of text to
    # +zabbix_sender+.
    #
    # @param [String] text
    def puts text
      with_sender_subprocess do |stdin, stdout, stderr, wait_thr|
        stdin.write(text)
        stdin.close
        output = [stdout.read.chomp, stderr.read.chomp].join("\n").strip
        debug(output) if output.size > 0
      end
    end

    # :nodoc:
    def close
      return
    end

    # :nodoc:
    def flush
      return
    end
    
  end
end
