module Rubix
  module Associations

    module BelongsToItem

      def item= i
        return unless i
        @item    = i
        @item_id = i.id
      end

      def item
        return @item if @item
        return unless @item_id
        @item = Item.find(:id => @item_id)
      end

      def item_id= iid
        puts "I AM TRYING TO SET ITEM_ID=#{iid}"
        return unless iid
        @item_id = iid
      end

      def item_id
        return @item_id if @item_id
        return unless @item
        @item_id = @item.id
      end

    end
  end
end

      
