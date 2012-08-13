root = File.expand_path('../', __FILE__)

lib  = File.join(root, 'lib')
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |gem|
  gem.name         = 'rubix'
  gem.homepage     = 'http://github.com/dhruvbansal/rubix'
  gem.licenses     = ["Apache 2.0"]
  gem.email        = ['dhruv@infochimps.com', 'coders@infochimps.org']
  gem.authors      = ['Dhruv Bansal', 'Infochimps']
  gem.version      = File.read(File.join(root, 'VERSION')).strip

  gem.platform     = Gem::Platform::RUBY
  gem.summary      = "A Ruby client for configuring and writing data to Zabbix"
  gem.description  =  "Rubix provides abstractions for connecting to Zabbix's API, an ORM for wrapping Zabbix resources, a set of scripts for writing data to Zabbix, and a collection of Monitor classes for building periodic monitors."

  gem.files        = Dir["{bin,lib,spec}/**/*"] + %w[LICENSE.md README.rdoc VERSION CHANGELOG.md Rakefile Gemfile]
  gem.executables  = ['zabbix_api', 'zabbix_pipe']
  gem.require_path = 'lib'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'mysql2'
  gem.add_development_dependency 'oj'    unless RUBY_PLATFORM =~ /java/

  gem.add_dependency 'chef'
  gem.add_dependency 'multi_json'
  gem.add_dependency 'configliere',   '>= 0.4.16'
  gem.add_dependency 'multipart-post'
end
