module Rubix
  module Associations
    module HasInventory
      
      def inventory= i
        return unless i
        @inventory = i
      end
      
      def inventory
        @inventory
      end

      def inventory_params
        return {} unless inventory
        inventory.create_params
      end
      
    end
  end
end

      
