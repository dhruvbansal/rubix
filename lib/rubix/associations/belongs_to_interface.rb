module Rubix
  module Associations

    module BelongsToInterface

      def interface= i
        return unless i
        @interface    = i
        @interface_id = i.id
      end

      def interface
        return @interface if @host
        return unless @interface_id
        @interface = Interface.find(:id => @host_id)
      end

      def interface_id= hid
        return unless hid
        @interface_id = hid
      end

      def interface_id
        return @interface_id if @host_id
        return unless @interface
        @interface_id = @host.id
      end

    end
  end
end

