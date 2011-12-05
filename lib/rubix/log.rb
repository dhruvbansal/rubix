require 'logger'

module Rubix

  # Set the Rubix logger.  Set to +nil+ to disable all logging.
  #
  # @param [Logger] l the logger to use
  def self.logger= l
    @logger = l
  end

  # The current Rubix logger.
  #
  # @return [Logger, nil]
  def self.logger
    return @logger unless @logger.nil?
    @logger = default_logger
  end

  # The default logger.
  #
  # @return [Logger]
  def self.default_logger
    @logger       = Logger.new(default_log_path)
    @logger.level = default_log_severity
    @logger
  end

  # The default logger's severity.
  #
  # Will attempt to read from
  #
  # - <tt>Settings[:log_level]</tt> if <tt>Settings</tt> is defined (see Configliere[http://github.com/infochimps/configliere])
  # - the <tt>RUBIX_LOG_LEVEL</tt> environment variable if defined
  #
  # The default is 'info'.
  #
  # @return [Fixnum]
  def self.default_log_severity
    case
    when defined?(Settings) && Settings[:log_level]
      Logger.const_get(Settings[:log_level].to_s.strip)
    when ENV["RUBIX_LOG_LEVEL"]
      severity_name = ENV["RUBIX_LOG_LEVEL"].to_s.strip
    else
      severity_name = 'info'
    end
    
    begin
      return Logger.const_get(severity_name.upcase)
    rescue NameError => e
      return Logger::INFO
    end
  end

  # The default logger's path.
  #
  # Will attempt to read from
  #
  # - <tt>Settings[:log]</tt> if <tt>Settings</tt> is defined (see Configliere[http://github.com/infochimps/configliere])
  # - the <tt>RUBIX_LOG_PATH</tt> environment variable if defined
  #
  # Defaults to writing <tt>stdout</tt>.
  def self.default_log_path
    case
    when defined?(Settings) && Settings[:log]
      Settings[:log]
    when ENV["RUBIX_LOG_PATH"] == '-'
      $stdout
    when ENV["RUBIX_LOG_PATH"]
      ENV["RUBIX_LOG_PATH"]
    else
      $stdout
    end
  end

  # This module can be included by any class to enable logging to the
  # <tt>Rubix.logger</tt>.
  module Logs

    # Write a log message with severity +debug+.
    #
    # @param [Array<String>] args
    def debug *args
      return unless Rubix.logger
      Rubix.logger.log(Logger::DEBUG, args.join(' '))
    end

    # Write a log message with severity +info+.
    #
    # @param [Array<String>] args
    def info *args
      return unless Rubix.logger
      Rubix.logger.log(Logger::INFO, args.join(' '))
    end

    # Write a log message with severity +warn+.
    #
    # @param [Array<String>] args
    def warn *args
      return unless Rubix.logger
      Rubix.logger.log(Logger::WARN, args.join(' '))
    end

    # Write a log message with severity +error+.
    #
    # @param [Array<String>] args
    def error *args
      return unless Rubix.logger
      Rubix.logger.log(Logger::ERROR, args.join(' '))
    end

    # Write a log message with severity +fatal+.
    #
    # @param [Array<String>] args
    def fatal *args
      return unless Rubix.logger
      Rubix.logger.log(Logger::FATAL, args.join(' '))
    end
    
  end
end
