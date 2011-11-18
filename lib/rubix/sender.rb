require 'rubix/log'

module Rubix

  class Sender

    include Logs

    # A Hash of options.
    attr_accessor :settings

    # The host the Sender will send data for.
    attr_accessor :host

    # The hostgroups used to create this host.
    attr_accessor :host_groups

    # The templates used to create this host.
    attr_accessor :templates

    # The applications used to create items.
    attr_accessor :applications
    
    #
    # Initialization
    #

    def initialize settings
      @settings = settings
      confirm_settings
      self.host = Host.new(:name => settings['host'])
      @log_name = "PIPE #{host.name}"
      if settings['fast']
        info("Forwarding...") if settings['verbose']
      else
        initialize_hostgroups
        initialize_templates
        initialize_host
        initialize_applications
        info("Forwarding...") if settings['verbose'] && host.exists?
      end
    end

    def alive?
      settings['fast'] || host.exists?
    end

    def initialize_hostgroups
      self.host_groups = settings['host_groups'].split(',').flatten.compact.map { |group_name | HostGroup.find_or_create_by_name(group_name.strip) }
    end

    def initialize_templates
      self.templates = (settings['templates'] || '').split(',').flatten.compact.map { |template_name | Template.find_or_create_by_name(template_name.strip) }
    end

    def initialize_host
      unless host.exists?
        host.host_groups = host_groups
        host.templates   = templates
        host.create
      end
      # if settings['verbose']
      #   puts "Forwarding data for Host '#{settings['host']}' (#{host_id}) from #{settings['pipe']} to #{settings['server']}"
      #   puts "Creating Items in Application '#{settings['application']}' (#{application_id}) at #{settings['api_server']} as #{settings['username']}"
      # end
    end

    def initialize_applications
      self.applications = (settings['applications'] || '').split(',').flatten.compact.map { |app_name| Application.find_or_create_by_name_and_host(app_name, host) }
    end

    def confirm_settings
      raise ConnectionError.new("Must specify a Zabbix server to send data to.")     unless settings['server']
      raise Error.new("Must specify the path to a local configuraiton file")         unless settings['configuration_file'] && File.file?(settings['configuration_file'])
      raise ConnectionError.new("Must specify the name of a host to send data for.") unless settings['host']
      raise ValidationError.new("Must define at least one host group.")              if settings['host_groups'].nil? || settings['host_groups'].empty?      
    end
    
    #
    # Actions
    #

    def run
      return unless alive?
      case
      when settings['pipe']
        process_pipe
      when settings.rest.size > 0
        settings.rest.each do |path|
          process_file(path)
        end
      else
        process_stdin
      end
      exit(0)
    end
    
    # Process each line of the file at +path+.
    def process_file path
      f = File.new(path)
      process_file_handle(f)
      f.close
    end
    
    # Process each line of standard input.
    def process_stdin
      process_file_handle($stdin)
    end
    
    # Process each line read from the pipe.
    def process_pipe
      # We want to open this pipe in non-blocking read mode b/c
      # otherwise this process becomes hard to kill.
      f = File.new(settings['pipe'], (File::RDONLY | File::NONBLOCK))
      while true
        process_file_handle(f)
        # In non-blocking mode, an EOFError from f.readline doesn't mean
        # there's no more data to read, just that there's no more data
        # right *now*.  If we sleep for a bit there might be more data
        # coming down the pipe.
        sleep settings['pipe_read_sleep']
      end
      f.close
    end
    
    # Process each line of a given file handle +f+.
    def process_file_handle f
      begin
        line = f.readline
      rescue EOFError
        line = nil
      end
      while line
        process_line(line)
        begin
          # FIXME -- this call to File#readline blocks and doesn't let
          # stuff like SIGINT (generated from Ctrl-C on a keyboard,
          # say) take affect.
          line = f.readline
        rescue EOFError
          line = nil
        end
      end
    end
    
    def process_line line
      if looks_like_json?(line)
        process_line_of_json_in_new_pipe(line)
      else
        process_line_of_tsv_in_this_pipe(line)
      end
    end

    # Parse and send a single +line+ of TSV input to the Zabbix server.
    # The line will be split at tabs and expects either
    #
    #   a) two columns: an item key and a value
    #   b) three columns: an item key, a value, and a timestamp
    #
    # Unexpected input will cause an error to be logged.
    def process_line_of_tsv_in_this_pipe line
      parts = line.strip.split("\t")
      case parts.size
      when 2
        timestamp  = Time.now
        key, value = parts
      when 3
        key, value = parts[0..1]
        timestamp  = Time.parse(parts.last)
      else
        error("Each line of input must be a tab separated row consisting of 2 columns (key, value) or 3 columns (timestamp, key, value)")
        return
      end
      send(key, value, timestamp)
    end

    # Parse and send a single +line+ of JSON input to the Zabbix server.
    # The JSON must have a key +data+ in order to be processed.  The
    # value of 'data' should be an Array of Hashes each with a +key+ and
    # +value+.
    #
    # This ZabbixPipe's settings will be merged with the remainder of
    # the JSON hash.  This allows sending values for 'host2' to an
    # instance of ZabbixPipe already set up to receive for 'host1'.
    #
    # This is useful for sending data for keys from multiple hosts
    #
    # Example of expected input:
    #
    #   {
    #     'data': [
    #       {'key': 'foo.bar.baz',      'value': 10},
    #       {'key': 'snap.crackle.pop', 'value': 8 }
    #     ]
    #   }
    #
    # Or when sending for another host:
    # 
    #   {
    #     'hostname': 'shazaam',
    #     'application': 'silly',
    #     'data': [
    #       {'key': 'foo.bar.baz',      'value': 10},
    #       {'key': 'snap.crackle.pop', 'value': 8 }
    #     ]
    #   }
    def process_line_of_json_in_new_pipe line
      begin
        json = JSON.parse(line)
      rescue JSON::ParserError => e
        error("Malformed JSON")
        return
      end
      
      data = json.delete('data')
      unless data && data.is_a?(Array)
        error("A line of JSON input must a have an Array key 'data'")
        return
      end

      if json.empty?
        # If there are no other settings then the daughter will be the
        # same as the parent -- so just use 'self'.
        daughter_pipe = self
      else
        # We merge the settings from 'self' with whatever else is
        # present in the line.
        begin
          daughter_pipe = self.class.new(settings.stringify_keys.merge(json))
          return unless daughter_pipe.alive?
        rescue Error => e
          error(e.message)
          return
        end
      end

      data.each do |point|
        key   = point['key']
        value = point['value']
        unless key && value
          warn("The elements of the 'data' Array must be Hashes with a 'key' and a 'value'")
          next
        end
        
        tsv_line = [key, value].map(&:to_s).join("\t")
        daughter_pipe.process_line(tsv_line)
      end
    end

    # Does the line look like it might be JSON?
    def looks_like_json? line
      line =~ /^\s*\{/
    end

    # Send the +value+ for +key+ at the given +timestamp+ to the Zabbix
    # server.
    #
    # If the +key+ doesn't exist for this local agent's host, it will be
    # added.
    def send key, value, timestamp
      item = Item.new(:key => key, :host => host, :applications => applications, :value_type => Item.value_type_from_value(value))
      unless settings['fast'] || item.exists?
        return unless item.create
        # There is a time lag of about 15-30 seconds between (successfully)
        # creating an item on the Zabbix server and having the Zabbix accept
        # new data for that item.
        #
        # If it is crucial that *every single* data point be written, dial
        # up this sleep period.  The first data point for a new key will put
        # the wrapper to sleep for this period of time, in hopes that the
        # Zabbix server will catch up and be ready to accept new data
        # points.
        #
        # If you don't care that you're going to lose the first few data
        # points you send to Zabbix, then don't worry about it.
        sleep settings['create_item_sleep']
      end
      command = "#{settings['sender']} --config #{settings['configuration_file']} --zabbix-server #{settings['server']} --host #{settings['host']} --key #{key} --value '#{value}'"
      process_zabbix_sender_output(key, `#{command}`)

      # command = "zabbix_sender --config #{configuration_file} --zabbix-server #{server} --input-file - --with-timestamps"
      # open(command, 'w') do |zabbix_sender|
      #   zabbix_sender.write([settings['host'], key, timestamp.to_i, value].map(&:to_s).join("\t"))
      #   zabbix_sender.close_write
      #   process_zabbix_sender_output(zabbix_sender.read)
      # end
    end

    # Parse the +text+ output by +zabbix_sender+.
    def process_zabbix_sender_output key, text
      return unless settings['verbose']
      lines = text.strip.split("\n")
      return if lines.size < 1
      status_line = lines.first
      status_line =~ /Processed +(\d+) +Failed +(\d+) +Total +(\d+)/
      processed, failed, total = $1, $2, $3
      warn("Failed to write #{failed} values to key '#{key}'") if failed.to_i != 0
    end

  end
end
