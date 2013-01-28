module Rubix
  module Associations
    module HasManyInterfaces
      
      def interfaces= is
        return unless is
        @interfaces = is.map do |i|
          i.kind_of?(Interface) ? i : Interface.build(i)
        end
      end
      
      def interfaces
        return @interfaces if @interfaces
        return [] unless @interface_ids
        @interfaces = @interface_ids.map { |iid| Interface.find(:id => iid) }
      end

      def interface_ids= iids
        return unless iids
        @interface_ids = iids
      end
      
      def interface_ids
        return @interface_ids if @interface_ids
        return [] unless @interfaces
        @interface_ids = @interfaces.map(&:id)
      end

      def interface_params
        return [] unless interfaces
        interfaces.map(&:create_params)
      end

    end
  end
end
