require 'json'

module Rubix

  class Response

    attr_reader :http_response, :code, :body

    def initialize(http_response)
      @http_response = http_response
      @body          = http_response.body
      @code          = http_response.code.to_i
    end

    #
    # Parsing
    #
    
    def parsed
      return @parsed if @parsed
      if non_200?
        @parsed = {}
      else
        begin
          @parsed = JSON.parse(@body) if @code == 200
        rescue JSON::ParserError => e
          @parsed = {}
        end
      end
    end

    #
    # Error Handling
    #

    def non_200?
      code != 200
    end
    
    def error?
      non_200? || (parsed.is_a?(Hash) && parsed['error'])
    end

    def zabbix_error?
      code == 200 && error?
    end

    def error_code
      return unless error?
      (non_200? ? code : parsed['error']['code'].to_i) rescue 0
    end
    
    def error_type
      return unless error?
      (non_200? ? "Non-200 Error" : parsed['error']['message']) rescue 'Unknown Error'
    end

    def error_message
      return unless error?
      begin
        if non_200?
          "Could not get a 200 response from the Zabbix API.  Further details are unavailable."
        else
          stripped_message = (parsed['error']['message'] || '').gsub(/\.$/, '')
          stripped_data = (parsed['error']['data'] || '').gsub(/^\[.*?\] /, '')
          [stripped_message, stripped_data].map(&:strip).reject(&:empty?).join(', ')
        end
      rescue => e
        "No details available."
      end
    end

    def success?
      !error?
    end

    #
    # Inspecting contents
    #

    def result
      parsed['result']
    end
    
    def [] key
      return if error?
      result[key]
    end

    def first
      return if error?
      result.first
    end

    def empty?
      result.empty?
    end

    def has_data?
      success? && (!empty?)
    end
    
    def hash?
      return false if error?
      result.is_a?(Hash) && result.size > 0 && result.first.last
    end

    def array?
      return false if error?
      result.is_a?(Array) && result.size > 0 && result.first
    end

    def string?
      return false if error?
      result.is_a?(String) && result.size > 0
    end

    def boolean?
      return false if error?
      result == true || result == false
    end
    
  end
end
