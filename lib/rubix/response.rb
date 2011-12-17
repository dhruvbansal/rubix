require 'json'

module Rubix

  # A class used to wrap Net::HTTP::Response objects to make it easier
  # to inspect them for various cases.
  class Response

    # @return [Net::HTTP::Response] the raw HTTP response from the Zabbix API
    attr_reader :http_response

    # @return [Fixnum] the raw HTTP response code
    attr_reader :code

    # @return [String] the raw HTTP response body
    attr_reader :body

    # Wrap a <tt>Net::HTTP::Response</tt>.
    #
    # @param [Net::HTTP::Response] http_response
    def initialize(http_response)
      @http_response = http_response
      @body          = http_response.body
      @code          = http_response.code.to_i
    end

    #
    # == Parsing ==
    #

    # The parsed JSON body.
    #
    # @return [Hash]
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
    # == Error Handling ==
    #

    # Was the response *not* a 200?
    #
    # @return [true,false]
    def non_200?
      code != 200
    end

    # Was the response an error?  This will return +true+ if
    #
    # - the response was not a 200
    # - the response was a 200 and contains an +error+ key
    #
    # @return [true, false]
    def error?
      non_200? || (parsed.is_a?(Hash) && parsed['error'])
    end

    # Was this response successful?  Successful responses must
    #
    # - have a 200 response code
    # - *not* have an +error+ key in the response
    #
    # @return [true, false]
    def success?
      !error?
    end

    # Was the response a *Zabbix* error, implying a 200 with an
    # +error+ key.
    #
    # @return [true, false]
    def zabbix_error?
      code == 200 && error?
    end

    # Returns the error code of a Zabbix error or +nil+ if this wasn't
    # an error.
    #
    # @return [nil, Fixnum]
    def error_code
      return unless error?
      (non_200? ? code : parsed['error']['code'].to_i) rescue 0
    end

    # Returns the Zabbix type of the error or +nil+ if this wasn't an error.
    #
    # @return [nil, String]
    def error_type
      return unless error?
      (non_200? ? "Non-200 Error" : parsed['error']['message']) rescue 'Unknown Error'
    end

    # Return an error message or +nil+ if this wasn't an error.
    #
    # @return [String, nil]
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

    #
    # == Inspecting contents ==
    #

    # The contents of the +result+ key.  Returns +nil+ if an error.
    def result
      return if error?
      parsed['result']
    end

    # Return the contents of +key+ *within* the +result+ key or +nil+
    # if an error.
    def [] key
      return if error?
      result[key]
    end

    # Return the +first+ element of the +result+ key or +nil+ if an
    # error.
    def first
      return if error?
      result.first
    end

    # Is the +result+ key empty?
    #
    # @return [true, false]
    def empty?
      return true unless result
      result.empty?
    end

    # Does this response "have data" in the sense that
    #
    # - it is a successful response (see <tt>Rubix::Response#success?</tt>)
    # - it has a +result+ key which is not empty
    def has_data?
      success? && (!empty?)
    end

    # Is the contents of the *first* element of the +result+ key a
    # Hash?
    #
    # @return [true, false]
    def hash?
      return false if error?
      result.is_a?(Hash) && result.size > 0 && result.first.last
    end

    # Is the contents of the *first* element of the +result+ key an
    # Array?
    #
    # @return [true, false]
    def array?
      return false if error?
      result.is_a?(Array) && result.size > 0 && result.first
    end

    # Is the contents of the +result+ key a String?
    #
    # @return [true, false]
    def string?
      return false if error?
      result.is_a?(String) && result.size > 0
    end

    # Is the contents of the +result+ key either +true+ or +false+?
    #
    # @return [true, false]
    def boolean?
      return false if error?
      result == true || result == false
    end

  end
end
