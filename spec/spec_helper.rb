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

  Rubix::IntegrationHelper.setup_integration_tests(File.expand_path('../test.yml', __FILE__))
end
