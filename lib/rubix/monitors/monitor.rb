require 'configliere'
require 'json'

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
  #       return unless `uptime`.chomp =~ /(\d+) days/
  #       write do |data|
  #         data << ([['uptime', $1.to_i]])
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
      Configliere::Param.new.tap do |s|
        s.use :commandline

        s.define :loop,            :description => "Run every this many seconds",          :required => false, :type => Integer
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

    def write options={}, &block
      return unless output
      data = []
      block.call(data) if block_given?
      text = {
        :data => data.map do |measurement|
          key, value = measurement
          { :key => key, :value => value }
        end
      }.merge(options).to_json

      begin
        output.puts(text)
      rescue Errno::ENXIO
        # FIFO's reader isn't alive...
      end
    end

    def output_path
      settings.rest.first
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

    def output
      return @output if @output
      case
      when stdout?
        @output = $stdout
      when fifo?
        begin
          @output = open(output_path, (File::WRONLY | File::NONBLOCK))
        rescue Errno::ENXIO
          # FIFO's reader isn't alive...
        end
      else
        @output = File.open(output_path, 'a')
      end
    end

    def close
      return unless output
      output.flush
      return if stdout?
      output.close
    end

  end
end
