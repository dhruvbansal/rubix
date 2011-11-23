require 'tempfile'
require 'rspec'

RUBIX_ROOT = File.expand_path(__FILE__, '../../lib')
$: << RUBIX_ROOT unless $:.include?(RUBIX_ROOT)
require 'rubix'

Rubix.logger = false unless ENV["RUBIX_LOG_LEVEL"] || ENV["RUBIX_LOG_PATH"]

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |path| require path }

RSpec.configure do |config|
  config.mock_with :rspec
  config.include Rubix::ResponseSpecs
  config.include Rubix::IntegrationHelper
  config.include Rubix::ConfigliereHelper

  test_yml_path = File.expand_path('../test.yml', __FILE__)
  if File.exist?(test_yml_path)
    require 'yaml'
    test_data = YAML.load(open(test_yml_path))
    if test_data['disable_integration_tests']
      $RUBIX_INTEGRATION_TEST = false
    else
      Rubix.connect(test_data['url'], test_data['username'], test_data['password'])
      $RUBIX_INTEGRATION_TEST = true
    end
  else
    $RUBIX_INTEGRATION_TEST = false
  end
end
