module Rubix
  module Associations
    module HasManyScreenItems

      def screen_items= hs
        return unless hs
        @screen_items    = hs
        @screen_item_ids = hs.map(&:id)
      end

      def screen_items
        return @screen_items if @screen_items
        return [] unless @screen_item_ids
        @screen_items = @screen_item_ids.map { |hid| screen_item.find(:id => hid) }
      end

      def screen_item_ids= hids
        return unless hids
        @screen_item_ids = hids
      end

      def screen_item_ids
        return @screen_item_ids if @screen_item_ids
        return unless @screen_items
        @screen_item_ids = @screen_items.map(&:id)
      end
    end
  end
end

