module Rubix
  module Associations
    module HasManyUsers
      
      def users= us
        return unless us
        @users    = us
        @user_ids = us.map(&:id)
      end
      
      def users
        return @users if @users
        return unless @user_ids
        @users = @user_ids.map { |uid| User.find(:id => uid) }
      end

      def user_ids= uids
        return unless uids
        @user_ids = uids
      end
      
      def user_ids
        return @user_ids if @user_ids
        return unless @users
        @user_ids = @users.map(&:id)
      end
      
    end
  end
end

      
