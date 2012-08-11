require "rspec/core/rake_task"

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

desc "Build rubix"
task :build do
  system "gem build rubix.gemspec"
end

version = File.read(File.expand_path('../VERSION', __FILE__)).strip
desc "Release rubix-#{version}"
task :release => :build do
  system "gem push rubix-#{version}.gem"
end

RSpec::Core::RakeTask.new(:spec)

task :default => :spec