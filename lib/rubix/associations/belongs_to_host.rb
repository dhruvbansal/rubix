module Rubix
  module Associations

    module BelongsToHost

      def host= h
        return unless h
        @host    = h
        @host_id = h.id
      end

      def host
        return @host if @host
        return unless @host_id
        @host = Host.find(:id => @host_id)
      end

      def host_id= hid
        return unless hid
        @host_id = hid
      end

      def host_id
        return @host_id if @host_id
        return unless @host
        @host_id = @host.id
      end

    end
  end
end


