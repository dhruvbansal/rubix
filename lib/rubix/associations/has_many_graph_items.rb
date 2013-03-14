module Rubix
  module Associations
    module HasManyGraphItems

      def graph_items= sis
        @graph_items    = sis
      end

      def graph_items
        @graph_items || []
      end
    end
  end
end

