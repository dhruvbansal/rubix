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
    severity = Logger::INFO
    file     = $stdout
    
    if defined?(Settings) && Settings[:log_level]
      begin
        severity_name = Settings[:log_level].to_s.upcase
        severity      = Logger.const_get(severity_name)
      rescue NameError => e
      end
    end

    if defined?(Settings) && Settings[:log]
      begin
        file = Settings[:log]
      rescue NameError => e
      end
    end
    
    @logger       = Logger.new(file)
    @logger.level = severity
    @logger
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
