module Rubix
  module Associations
    module HasManyUserMacros
      
      def user_macros= hs
        return unless hs
        @user_macros    = hs
        @user_macro_ids = hs.map(&:id)
      end
      
      def user_macros
        return @user_macros if @user_macros
        return unless @user_macro_ids
        @user_macros = @user_macro_ids.map { |umid| UserMacro.find(:id => umid) }
      end

      def user_macro_ids= umids
        return unless umids
        @user_macro_ids = umids
      end
      
      def user_macro_ids
        return @user_macro_ids if @user_macro_ids
        return unless @user_macros
        @user_macro_ids = @user_macros.map(&:id)
      end

      def user_macro_params
        return [] unless user_macro_ids
        user_macro_ids.map { |umid| { 'usermacroid' => umid } }
      end
      
    end
  end
end

      
