module Rubix
  module Associations
    module HasManyHostGroups

      def host_groups= hs
        return unless hs
        @host_groups    = hs
        @host_group_ids = hs.map(&:id)
      end

      def host_groups
        return @host_groups if @host_groups
        return unless @host_group_ids
        @host_groups = @host_group_ids.map { |hgid| HostGroup.find(:id => hgid) }
      end

      def host_group_ids= hgids
        return unless hgids
        @host_group_ids = hgids
      end

      def host_group_ids
        return @host_group_ids if @host_group_ids
        return unless @host_groups
        @host_group_ids = @host_groups.map(&:id)
      end

      def host_group_params
        return [] unless host_group_ids
        host_group_ids.map { |hid| { 'groupid' => hid } }
      end

    end
  end
end


