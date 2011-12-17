module Rubix
  module Associations

    module BelongsToTemplate

      def template= h
        return unless h
        @template    = h
        @template_id = h.id
      end

      def template
        return @template if @template
        return unless @template_id
        @template = Template.find(:id => @template_id)
      end

      def template_id= tid
        return unless tid
        @template_id = tid
      end

      def template_id
        return @template_id if @template_id
        return unless @template
        @template_id = @template.id
      end

    end
  end
end


