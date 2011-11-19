module Rubix
  module IntegrationHelper

    def integration_test
      pending("A live Zabbix API to test against") unless $RUBIX_INTEGRATION_TEST
    end
    
  end
end
