require 'logger'

module Rubix

  def self.logger= l
    @logger = l
  end

  def self.logger
    return @logger unless @logger.nil?
    @logger = default_logger
  end

  def self.default_logger
    @logger       = Logger.new(default_log_path)
    @logger.level = default_log_severity
    p default_log_severity
    @logger
  end

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
      
  module Logs

    def log_name
      @log_name
    end
    
    def debug *args
      return unless Rubix.logger
      Rubix.logger.log(Logger::DEBUG, args.join(' '), log_name)
    end

    def info *args
      return unless Rubix.logger
      Rubix.logger.log(Logger::INFO, args.join(' '), log_name)
    end

    def warn *args
      return unless Rubix.logger
      Rubix.logger.log(Logger::WARN, args.join(' '), log_name)
    end

    def error *args
      return unless Rubix.logger
      Rubix.logger.log(Logger::ERROR, args.join(' '), log_name)
    end

    def fatal *args
      return unless Rubix.logger
      Rubix.logger.log(Logger::FATAL, args.join(' '), log_name)
    end
    
  end
end
