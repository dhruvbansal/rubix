require 'rubygems' unless defined?(Gem)
require 'bundler/setup'
Bundler.setup(:default, :development)
require 'rake'

task :default => :rspec
task :spec    => :rspec

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:rspec) do |spec|
  Bundler.setup(:default, :development, :test)
  spec.pattern = 'spec/**/*_spec.rb'
end

desc "Run RSpec with code coverage"
task :cov do
  ENV['GORILLIB_COV'] = "yep"
  Rake::Task[:rspec].execute
end

require 'yard'
YARD::Rake::YardocTask.new do
  Bundler.setup(:default, :development, :docs)
end

desc "Build rubix"
task :build do
  system "gem build rubix.gemspec"
end

version = File.read(File.expand_path('../VERSION', __FILE__)).strip
desc "Release rubix-#{version}"
task :release => :build do
  system "gem push rubix-#{version}.gem"
end
