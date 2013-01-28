module Rubix
  module Associations
    module HasManyTemplates

      def templates= hs
        return unless hs
        @templates    = hs
        @template_ids = hs.map(&:id)
      end

      def templates
        return @templates if @templates
        return unless @template_ids
        @templates = @template_ids.map { |tid| Template.find(:id => tid) }
      end

      def template_ids= tids
        return unless tids
        @template_ids = tids
      end

      def template_ids
        return @template_ids if @template_ids
        return unless @templates
        @template_ids = @templates.map(&:id)
      end

      def template_params
        return [] unless template_ids
        template_ids.uniq.map { |tid| { 'templateid' => tid } }
      end
    end
  end
end
