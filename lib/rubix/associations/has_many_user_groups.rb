module Rubix
  module Associations
    module HasManyUserGroups
      
      def user_groups= ugs
        return unless ugs
        @user_groups    = ugs
        @user_group_ids = ugs.map(&:id)
      end
      
      def user_groups
        return @user_groups if @user_groups
        return unless @user_group_ids
        @user_groups = @user_group_ids.map { |ugid| UserGroup.find(:id => ugid) }
      end

      def user_group_ids= ugids
        return unless ugids
        @user_group_ids = ugids
      end
      
      def user_group_ids
        return @user_group_ids if @user_group_ids
        return unless @user_groups
        @user_group_ids = @user_groups.map(&:id)
      end
      
    end
  end
end

      
