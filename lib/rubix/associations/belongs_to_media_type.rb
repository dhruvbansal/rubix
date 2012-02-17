module Rubix
  module Associations

    module BelongsToMediaType

      def media_type= mt
        return unless mt
        @media_type    = mt
        @media_type_id = mt.id
      end

      def media_type
        return @media_type if @media_type
        return unless @media_type_id
        @media_type = MediaType.find(:id => @media_type_id)
      end

      def media_type_id= mtid
        return unless mtid
        @media_type_id = mtid
      end

      def media_type_id
        return @media_type_id if @media_type_id
        return unless @media_type
        @media_type_id = @media_type.id
      end

    end
  end
end

      
