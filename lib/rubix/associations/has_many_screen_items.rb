module Rubix
  module Associations
    module HasManyScreenItems

      def screen_items= sis
        @screen_items    = sis
      end

      def screen_items
        @screen_items || []
      end
    end
  end
end

