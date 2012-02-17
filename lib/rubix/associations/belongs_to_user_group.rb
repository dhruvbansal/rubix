module Rubix
  module Associations
    module BelongsToUserGroup

      def user_group= ug
        return unless ug
        @user_group    = ug
        @user_group_id = ug.id
      end

      def user_group
        return @user_group if @user_group
        return unless @user_group_id
        @user_group = UserGroup.find(:id => @user_group_id)
      end

      def user_group_id= ugid
        return unless ugid
        @user_group_id = ugid
      end

      def user_group_id
        return @user_group_id if @user_group_id
        return unless @user_group
        @user_group_id = @user_group.id
      end

    end
  end
end

      
