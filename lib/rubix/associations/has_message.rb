module Rubix
  module Associations
    module HasMessage

      def message
        @message
      end

      def message= m
        @message = m.kind_of?(Message) ? m : Message.new(m)
      end
    end
  end
end

