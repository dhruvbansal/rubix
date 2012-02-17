module Rubix
  module Associations

    module BelongsToAction

      def action= a
        return unless a
        @action    = a
        @action_id = a.id
      end

      def action
        @action
      end

      def action_id= aid
        return unless aid
        @action_id = aid
      end

      def action_id
        return @action_id if @action_id
        return unless @action
        @action_id = @action.id
      end

    end
  end
end

      
