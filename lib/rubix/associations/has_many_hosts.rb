module Rubix
  module Associations
    module HasManyHosts

      def hosts= hs
        return unless hs
        @hosts    = hs
        @host_ids = hs.map(&:id)
      end

      def hosts
        return @hosts if @hosts
        return unless @host_ids
        @hosts = @host_ids.map { |hid| Host.find(:id => hid) }
      end

      def host_ids= hids
        return unless hids
        @host_ids = hids
      end

      def host_ids
        return @host_ids if @host_ids
        return unless @hosts
        @host_ids = @hosts.map(&:id)
      end

    end
  end
end


