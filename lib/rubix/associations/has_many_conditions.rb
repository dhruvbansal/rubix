module Rubix
  module Associations
    module HasManyConditions

      def self.included klass
        klass.send(:zabbix_attr, :condition_operator, :default => :and_or, :required => true)
      end

      def conditions
        @conditions ||= []
      end

      def conditions= cs
        @conditions = cs.map do |c|
          c.kind_of?(Condition) ? c : Condition.new(c)
        end
      end
      
    end
  end
end

      
