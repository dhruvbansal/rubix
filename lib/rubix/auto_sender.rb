require 'rubix/log'

module Rubix

  # == Sender
  #
  # Rubix comes with a +zabbix_pipe+ script which, coupled with the
  # {+zabbix_sender+}[http://www.zabbix.com/documentation/1.8/manpages/zabbix_sender]
  # utility, allows for writing data to Zabbix.
  #
  # By the design of Zabbix, all data written via +zabbix_sender+ (and
  # therefore +zabbix_pipe+) must be written to items with type "Zabbix
  # trapper".  This type instructs Zabbix to accept values written by
  # +zabbix_sender+.
  #
  # +zabbix_pipe+ can consume data from +STDIN+, a file on disk, or a
  # {named pipe}[http://en.wikipedia.org/wiki/Named_pipe].  It consumes
  # data one line at a time from any of these sources and uses the
  # +zabbix_sender+ utility to send this data to a Zabbix server.
  #
  # Here's an example of starting +zabbix_pipe+ and sending some data onto
  # Zabbix.  (Credentials and addresses for the Zabbix server and the
  # Zabbix API can all be customized; see the <tt>--help</tt> option.)
  #
  #   # Send one data point -- this is tab separated!
  #   $ echo "foo.bar.baz	123" | zabbix_pipe --host='My Zabbix Host' --host_groups='My Zabbix Servers,Some Other Group'
  #   # Send a bunch of data points in a file
  #   $ cat my_data.tsv | zabbix_pipe --host='My Zabbix Host' --host_groups='My Zabbix Servers,Some Other Group'
  #
  # You can also pass the file directly:
  #
  #   # Send a bunch of data points in a file
  #   $ zabbix_pipe --host='My Zabbix Host' --host_groups='My Zabbix Servers,Some Other Group' my_data.tsv
  #
  # You can also listen from a named pipe.  This is useful on a
  # "production" system in which many processes may want to simply and
  # easily write somewhere without worrying about what happens.
  #
  #   # In the first terminal
  #   $ mkfifo /dev/zabbix
  #   $ zabbix_pipe --pipe=/dev/zabbix --host='My Zabbix Host' --host_groups='My Zabbix Servers,Some Other Group'
  #
  #   # In another terminal
  #   $ echo "foo.bar.baz	123" > /dev/zabbix
  #   $ cat my_data > /dev/zabbix
  #
  # In any of these modes, you can also send JSON data directly.
  #
  #   $ echo '{"data": [{"key": "foo.bar.baz", "value": 123}, {"key": "foo.bar.baz", "value": 101}]}' > /dev/zabbix
  #
  # This simple block of JSON doesn't really add any power to
  # +zabbix_pipe+.  What becomes more interesting is that we can wedge in
  # data for *diffferent* hosts, items, &c. when using JSON input:
  #
  #   $ echo '{"host": "My first host", "host_groups": "My Zabbix Servers,Some Other Group", "data": [{"key": "foo.bar.baz", "value": 123}, {"key": "foo.bar.baz", "value": 101}]}' > /dev/zabbix
  #   $ echo '{"host": "My second host", "host_groups": "My Zabbix Servers,Some Other Group", "data": [{"key": "foo.bar.baz", "value": 123}, {"key": "foo.bar.baz", "value": 101}]}' > /dev/zabbix
  #   $ echo '{"host": "My third host", "host_groups": "My Zabbix Servers,Some Other Group", "data": [{"key": "foo.bar.baz", "value": 123}, {"key": "foo.bar.baz", "value": 101}]}' > /dev/zabbix
  #
  # Rubix will switch hosts on the fly.
  #
  # === Auto-vivification
  #
  # By default, for every item written into +zabbix_pipe+, Rubix will
  # first check, using the Zabbix API, whether an item with the given key
  # exists for the given host.  If not, Rubix will create the host and
  # the item.  You can pass a few details along with your data (when
  # writing in JSON format) or at startup of the +zabbix_pipe+ to tune
  # some of the properites of newly created hosts and items:
  #
  #   $ echo '{"host": "My host", "hostgroups": "Host Group 1,Host Group 2", "templates": "Template 1,Template 2", "applications": "App 1, App2", "data": [{"key": "foo.bar.baz", "value": 123}, {"key": "foo.bar.baz", "value": 101}]}' > /dev/zabbix
  #
  # If the host 'My host' does not exist, Rubix will create it, putting in
  # each of the host groups 'Host Group 1' and 'Host Group 2' (which will
  # also be auto-vivified), and attach it to templates 'Template 1' and
  # 'Template 2' (auto-vivified).  If the item does not exist for the host
  # 'My host', then it will be created and put inside applications 'App1'
  # and 'App2' (auto-vivified).  The value type of the item (unsigned int,
  # float, character, text, &c.) will be chosen dynamically based on the
  # value being written. The created items will all be of the type "Zabbix
  # trapper" so that they can be written to.
  #
  # Auto-vivification is intended to make it easy to register a lot of
  # dynamic hosts and items in Zabbix.  This is perfect for cloud
  # deployments where resources to be monitored are often dynamic.
  #
  # ==== Failed writes
  #
  # By the design of Zabbix, a newly created item of type 'Zabbix trapper'
  # will not accept data for some interval, typically a minute or so,
  # after being created.  This means that when writing a series of values
  # for some non-existent item 'foo.bar.baz', the first write will cause
  # the item to be created (auto-vivified), the next several writes will
  # fail as the Zabbix server is not accepting writes for this item yet,
  # and then all writes will begin to succeed as the Zabbix server catches
  # up.  If it is absolutely essential for all writes to succeed,
  # including the first, then +zabbix_pipe+ needs to go to sleep for a
  # while after creating a new item in order to give the Zabbix server
  # time to catch up.  This can be configured with the
  # <tt>--create_item_sleep</tt> option.  By default this is set to 0.
  #
  # ==== Skipping auto-vivification
  #
  # Attempting to auto-vivify keys on every single write is expensive and
  # does not scale.  It's recommended, therefore, to run +zabbix_pipe+
  # with the <tt>--fast</tt> flag in production settings.  In this mode,
  # +zabbix_pipe+ will not attempt to auto-vivify anything -- if items do
  # not exist, writes will just fail, as they do with +zabbix_sender+
  # itself.
  #
  # A good pattern is to set up a production pipe (in <tt>--fast</tt>)
  # mode at <tt>/dev/zabbix</tt> and to do all development/deployment with
  # a separate instance of +zabbix_pipe+.  Once development/deployment is
  # complete and all hosts, groups, templates, applications, and items
  # have been created, switch to writing all data in "production mode"
  # using the <tt>--fast</tt> pipe at <tt>/dev/zabbix</tt>.
  class AutoSender
    include Logs

    # @return [Hash] settings
    attr_accessor :settings

    # @return [Rubix::Host] the host the Sender will send data for
    attr_accessor :host

    # @return [Array<Rubix::HostGroup>] the hostgroups used to create this host
    attr_accessor :host_groups

    # @return [Array<Rubix::Template>] the templates used to create this host
    attr_accessor :templates

    # @return [Array<Rubix::Application>] The applications used to create items
    attr_accessor :applications

    #
    # == Initialization ==
    #

    # Create a new sender with the given +settings+.
    #
    # @param [Hash, Configliere::Param] settings
    # @param settings [String] host the name of the Zabbix host to write data for
    # @param settings [String] host_groups comma-separated names of Zabbix host groups the host should belong to
    # @param settings [String] templates comma-separated names of Zabbix templates the host should belong to
    # @param settings [String] applications comma-separated names of applications created items should be scoped under
    # @param settings [String] server URL for the Zabbix server -- *not* the URL for the Zabbix API
    # @param settings [String] configuration_file path to a local Zabbix configuration file as used by the +zabbix_sender+ utility
    # @param settings [true, false] verbose be verbose during execution
    # @param settings [true, false] fast auto-vivify (slow) or not (fast)
    # @param settings [String] pipe path to a named pipe to be read from
    # @param settings [Fixnum] pipe_read_sleep seconds to sleep after an empty read from the a named pipe
    # @param settings [Fixnum] create_item_sleep seconds to sleep after creating a new item
    def initialize settings
      @settings = settings
      confirm_settings
      if fast?
        info("Forwarding for #{settings['host']}...") if settings['verbose']
      else
        initialize_host_groups
        initialize_templates
        initialize_host
        initialize_applications
        info("Forwarding for #{host.name}...") if settings['verbose']
      end
    end

    # Is this sender running in 'fast' mode?  If so, it will *not*
    # auto-vivify any hosts, groups, items, &c.
    #
    # @return [true, false]
    def fast?
      settings['fast']
    end

    # Will this sender auto-vivify hosts, groups, items, &c.?
    #
    # @return [true, false]
    def auto_vivify?
      !fast?
    end

    protected

    # Find or create necessary host groups.
    #
    # @return [Array<Rubix::HostGroup>]
    def initialize_host_groups
      self.host_groups = settings['host_groups'].split(',').flatten.compact.map(&:strip).uniq.map { |group_name | HostGroup.find_or_create(:name => group_name.strip) }
    end

    # Find necessary templates.
    #
    # @return [Array<Rubix::Template>]
    def initialize_templates
      self.templates = (settings['templates'] || '').split(',').flatten.compact.map(&:strip).uniq.map { |template_name | Template.find(:name => template_name.strip) }.compact
    end

    # Find or create the host for this data.  Host groups and
    # templates will automatically be attached.
    #
    # @return [Rubix::Host]
    def initialize_host
      self.host = (Host.find(:name => settings['host']) || Host.new(:name => settings['host']))

      current_host_group_names = (host.host_groups || []).map(&:name)
      current_template_names   = (host.templates || []).map(&:name)

      host_groups_to_add, templates_to_add = [], []

      (self.host_groups || []).each do |hg|
        host_groups_to_add << hg unless current_host_group_names.include?(hg.name)
      end

      (self.templates || []).each do |t|
        templates_to_add << t unless current_template_names.include?(t.name)
      end

      host.host_groups = ((host.host_groups || []) + host_groups_to_add).flatten.compact.uniq
      host.templates   = ((host.templates || []) + templates_to_add).flatten.compact.uniq
      host.save
      host
    end

    # Find or create the applications for this data.
    #
    # @return [Array<Rubix::Application>]
    def initialize_applications
      application_names = (settings['applications'] || '').split(',').flatten.compact.map(&:strip).uniq
      self.applications = []
      application_names.each do |app_name|
        app = Application.find(:name => app_name, :host_id => host.id)
        if app
          self.applications << app
        else
          app = Application.new(:name => app_name, :host_id => host.id)
          if app.save
            self.applications << app
          else
            warn("Could not create application '#{app_name}' for host #{host.name}")
          end
        end
      end
      self.applications
    end

    # Check that all settings are correct in order to be able to
    # successfully write data to Zabbix.
    def confirm_settings
      raise ConnectionError.new("Must specify a Zabbix server to send data to.")     unless settings['server']
      raise Error.new("Must specify the path to a local configuraiton file")         unless settings['configuration_file'] && File.file?(settings['configuration_file'])
      raise ConnectionError.new("Must specify the name of a host to send data for.") unless settings['host']
      raise ValidationError.new("Must define at least one host group.")              if auto_vivify? && (settings['host_groups'].nil? || settings['host_groups'].empty?)
    end

    public

    #
    # == Sending Data ==
    #

    # Run this sender.
    #
    # Will read from the correct source of data and exit the Ruby
    # process once the source is consumed.
    def run
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

    protected

    # Process each line of a file.
    #
    # @param [String] path the path to the file to process
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
    #
    # The pipe will be opened in a non-blocking read mode.  This
    # sender will wait 'pipe_read_sleep' seconds between successive
    # empty reads.
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

    # Process each line of a given file handle.
    #
    # @param [File] f the file to process
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

    public

    # Process a single line of text.
    #
    # @param [String] line
    def process_line line
      if looks_like_json?(line)
        process_line_of_json_in_new_pipe(line)
      else
        process_line_of_tsv_in_this_pipe(line)
      end
    end

    protected

    # Parse and send a single +line+ of TSV input to the Zabbix server.
    # The line will be split at tabs and expects either
    #
    #   a) two columns: an item key and a value
    #   b) three columns: an item key, a value, and a timestamp
    #
    # Unexpected input will cause an error to be logged.
    #
    # @param [String] line a line of TSV data
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
      send_data(key, value, timestamp)
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
    #     'host': 'shazaam',
    #     'applications': 'silly',
    #     'data': [
    #       {'key': 'foo.bar.baz',      'value': 10},
    #       {'key': 'snap.crackle.pop', 'value': 8 }
    #     ]
    #   }
    #
    # @param [String] line a line of JSON data
    def process_line_of_json_in_new_pipe line
      begin
        json = MultiJson.load(line)
      rescue MultiJson::DecodeError => e
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

    # Does the +line+ look like it might be JSON?
    #
    # @param [String] line
    # @return [true, false]
    def looks_like_json? line
      !!(line =~ /^\s*\{/)
    end

    # Send the +value+ for +key+ at the given +timestamp+ to the Zabbix
    # server.
    #
    # If the +key+ doesn't exist for this local agent's host, it will be
    # added.
    #
    # FIXME passing +timestamp+ has no effect at present...
    #
    # @param [String] key
    # @param [String, Fixnum, Float] value
    # @param [Time] timestamp
    def send_data key, value, timestamp
      ensure_item_exists(key, value) unless fast?
      command = "#{settings['sender']} --config #{settings['configuration_file']} --zabbix-server #{settings['server']} --host #{settings['host']} --key #{key} --value '#{value}'"
      process_zabbix_sender_output(key, `#{command}`)

      # command = "zabbix_sender --config #{configuration_file} --zabbix-server #{server} --input-file - --with-timestamps"
      # open(command, 'w') do |zabbix_sender|
      #   zabbix_sender.write([settings['host'], key, timestamp.to_i, value].map(&:to_s).join("\t"))
      #   zabbix_sender.close_write
      #   process_zabbix_sender_output(zabbix_sender.read)
      # end
    end

    # Create an item for the given +key+ if necessary.
    #
    # @param [String] key
    # @param [String, Fixnum, Float] value
    def ensure_item_exists key, value
      item = Item.find(:key => key, :host_id => host.id)
      unless item
        Item.new(:key => key, :host_id => host.id, :applications => applications, :value_type => Item.value_type_from_value(value)).save

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
    end

    # Parse the +text+ output by +zabbix_sender+.
    #
    # @param [String] key
    # @param [String] text the output from +zabbix_sender+
    # @return [Fixnum] the number of data points processed
    def process_zabbix_sender_output key, text
      return unless settings['verbose']
      lines = text.strip.split("\n")
      return if lines.size < 1
      status_line = lines.first
      status_line =~ /Processed +(\d+) +Failed +(\d+) +Total +(\d+)/
      processed, failed, total = $1, $2, $3
      warn("Failed to write #{failed} values to key '#{key}'") if failed.to_i != 0
      processed
    end

  end
end
