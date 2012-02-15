require 'configliere'

module Rubix

  # A generic monitor class for constructing Zabbix monitors.
  #
  # This class handles the low-level logic of sleeping, waking up, and
  # sending data to Zabbix.
  #
  # It's up to a subclass to determine how to make a measurement.
  #
  # Here's an example of a script which measures the uptime of the
  # current machine.
  #
  #   #!/usr/bin/env ruby
  #   # in uptime_monitor
  #   class UptimeMonitor < Rubix::Monitor
  #
  #     def measure
  #       return unless `uptime`.chomp =~ /(\d+) days.*(\d+) users.*load average: ([\d\.]+), ([\d\.]+), ([\d\.]+)/
  #
  #       # can write one value at a time
  #       write ['uptime', $1.to_i]
  #
  #       # or can use a block
  #       write do |data|
  #         # values can be arrays
  #         data << ['users', $2.to_i]
  #         # or hashes
  #         data << { :key => 'load15', :value => $3.to_i }
  #         data << { :key => 'load5',  :value => $4.to_i }
  #         # can even pass a different host
  #         data << { :key => 'load1',  :value => $5.to_i, :host => 'foobar-host' }
  #       end
  #     end
  #   end
  #
  #   UptimeMonitor.run if $0 == __FILE__
  #
  # See what the script measures by running it directly.
  #
  #   $ ./uptime_monitor
  #
  # Or have it send its output to another file or FIFO
  #
  #   $ ./uptime_monitor /path/to/some/file
  #
  # Or have it loop every 30 seconds
  #
  #   $ ./uptime_monitor --loop=30 /path/to/some/file &
  class Monitor

    #
    # Class-level settings and a function to run a monito
    #

    def self.default_settings
      @default_settings ||= Configliere::Param.new.tap do |s|
        
        s.use :commandline
        
        s.define :loop,   :description => "Run every this many seconds",                         :required => false, :type => Integer

        # The following options are only used when sending directly
        # with <tt>zabbix_sender</tt>
        s.define :server, :description => "IP of a Zabbix server",                               :required => false, :default => 'localhost'
        s.define :port,   :description => "Port of a Zabbix server",                             :required => false, :default => 10051, :type => Integer
        s.define :host,   :description => "Name of a Zabbix host",                               :required => false, :default => ENV["HOSTNAME"]
        s.define :config, :description => "Local Zabbix agentd configuration file",              :required => false, :default => "/etc/zabbix/zabbix_agentd.conf"
        s.define :send,   :description => "Send data directlyt to Zabbix using 'zabbix_sender'", :required => false, :default => false, :type => :boolean
      end
    end

    def self.run
      settings = default_settings
      begin
        settings.resolve!
      rescue => e
        puts e.message
        exit(1)
      end
      new(settings).run
    end

    #
    # Instance-level settings that provide logic for running once or
    # looping.
    #

    attr_reader :settings

    def initialize settings
      @settings = settings
    end
    
    def loop?
      loop_period > 0
    end

    def loop_period
      settings[:loop].to_i
    end

    def run
      begin
        if loop?
          while true
            measure
            output.flush if output
            sleep loop_period
          end
        else
          measure
        end
      ensure
        close
      end
    end

    def measure
      raise NotImplementedError.new("Override the 'measure' method in a subclass to conduct a measurement.")
    end

    #
    # Methods for writing data to Zabbix.
    #

    def write measurement=nil, &block
      return unless output
      return unless measurement || block_given?
      
      data = [measurement]
      block.call(data) if block_given?

      text = data.compact.map { |measurement| format_measurement(measurement) }.compact.join("\n")

      begin
        output.puts(text)
      rescue Errno::ENXIO
        # FIFO's reader isn't alive...
      end
    end

    def format_measurement measurement
      # <hostname> key <timestamp> value
      [].tap do |vals|
        case measurement
        when Hash
          vals << (measurement[:host].nil? ? '-' : measurement[:host])
          vals << measurement[:key]
          vals << measurement[:timestamp] if measurement[:timestamp]
          
          value = measurement[:value].to_s
          if value.include?(' ')
            value.insert(0,  "'")
            value.insert(-1, "'")
          end
          vals << value
        when Array
          if measurement.length == 2
            vals << '-'
            vals.concat(measurement)
          else
            vals.concat(measurement)
          end
        else
          return
        end
      end.map(&:to_s).join(' ')
    end

    def output_path
      settings.rest && settings.rest.first
    end

    def stdout?
      output_path.nil?
    end

    def file?
      !stdout? && (!File.exist?(output_path) || File.ftype(output_path) == 'file')
    end

    def fifo?
      !stdout? && File.exist?(output_path) && File.ftype(output_path) == 'fifo'
    end

    def sender?
      settings[:send] == true
    end
    
    def output
      return @output if @output
      case
      when sender?
        @output = Sender.new(:host => settings[:host], :server => settings[:server], :port => settings[:port], :config => settings[:config])
      when stdout?
        @output = $stdout
      when fifo?
        begin
          @output = open(output_path, (File::WRONLY | File::NONBLOCK))
        rescue Errno::ENXIO
          nil
          # FIFO's reader isn't alive...
        end
      else
        @output = File.open(output_path, 'a')
      end
    end

    def close
      return unless output
      output.flush
      case
      when stdout?
        return
      else
        output.close
      end
    end
  end
end

