require 'rspec'

RUBIX_ROOT = File.expand_path(__FILE__, '../../lib')
$: << RUBIX_ROOT unless $:.include?(RUBIX_ROOT)
require 'rubix'

Rubix.logger = false

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |path| require path }

RSpec.configure do |config|
  config.mock_with :rspec
  config.include Rubix::ResponseSpecs
end
