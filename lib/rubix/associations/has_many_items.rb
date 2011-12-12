module Rubix
  module Associations
    module HasManyItems
      
      def items= is
        return unless is
        @items    = is
        @item_ids = is.map(&:id)
      end
      
      def items
        return @items if @items
        return unless @item_ids
        @items = @item_ids.map { |iid| Item.find(:id => iid, :host_id => (host_id || template_id)) }
      end

      def item_ids= iids
        return unless iids
        @item_ids = iids
      end
      
      def item_ids
        return @item_ids if @item_ids
        return unless @items
        @item_ids = @items.map(&:id)
      end
      
    end
  end
end
