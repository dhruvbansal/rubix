module Rubix
  module IntegrationHelper

    def integration_test
      pending("A live Zabbix API to test against") unless $RUBIX_INTEGRATION_TEST
    end

    def ensure_save(obj)
      begin
        raise Rubix::Error.new(Rubix.connection.last_response.error_message) unless obj.save
      rescue => e
        puts "#{e.class} -- #{e.message}"
        puts e.backtrace
        raise e
      end
    end

    def ensure_destroy *objs, &block
      begin
        if block_given?
          yield
        else
          errors = []
          objs.each do |obj|
            errors << Rubix.connection.last_response.error_message unless obj.destroy
          end
          raise Rubix::Error.new(errors.join("\n")) if errors.size > 0
        end
      rescue => e
        puts "#{e.class} -- #{e.message}"
        puts e.backtrace
        objs.each do |obj|
          begin
            puts "COULD NOT DESTROY #{obj.resource_name}" unless obj.destroy
          rescue => f
            puts "COULD NOT DESTROY #{obj.resource_name}"
            puts "#{e.class} -- #{e.message}"
            puts e.backtrace
          end
        end
        raise e
      end
    end
    
  end
end
