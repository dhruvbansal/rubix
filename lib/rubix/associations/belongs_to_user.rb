module Rubix
  module Associations

    module BelongsToUser

      def user= u
        return unless u
        @user    = u
        @user_id = u.id
      end

      def user
        return @user if @user
        return unless @user_id
        @user = User.find(:id => @user_id)
      end

      def user_id= uid
        return unless uid
        @user_id = uid
      end

      def user_id
        return @user_id if @user_id
        return unless @user
        @user_id = @user.id
      end

    end
  end
end

      
