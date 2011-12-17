module Rubix
  module Associations
    module HasManyApplications

      def applications= hs
        return unless hs
        @applications    = hs
        @application_ids = hs.map(&:id)
      end

      def applications
        return @applications if @applications
        return unless @application_ids
        @applications = @application_ids.map { |aid| Application.find(:id => aid, :host_id => host_id) }
      end

      def application_ids= aids
        return unless aids
        @application_ids = aids
      end

      def application_ids
        return @application_ids if @application_ids
        return unless @applications
        @application_ids = @applications.map(&:id)
      end

    end
  end
end


