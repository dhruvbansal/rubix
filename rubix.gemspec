root = File.expand_path('../', __FILE__)

lib  = File.join(root, 'lib')
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name         = 'rubix'
  s.version      = File.read(File.join(root, 'VERSION')).strip
  s.platform     = Gem::Platform::RUBY
  s.authors      = ['Dhruv Bansal']
  s.email        = ['dhruv@infochimps.com']
  s.homepage     = 'http://github.com/dhruvbansal/rubix'
  s.summary      = "A Ruby client for configuring and writing data to Zabbix"
  s.description  =  "Rubix provides abstractions for connecting to Zabbix's API, an ORM for wrapping Zabbix resources, a set of scripts for writing data to Zabbix, and a collection of Monitor classes for building periodic monitors."
  s.files        = Dir["{bin,lib,spec}/**/*"] + %w[LICENSE README.rdoc VERSION]
  s.executables  = ['zabbix_api', 'zabbix_pipe']
  s.require_path = 'lib'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'mysql2'
  
  s.add_dependency 'json',          '<= 1.6.1' # to match Chef
  s.add_dependency 'chef'
  s.add_dependency 'configliere',   '>= 0.4.8'
  s.add_dependency 'multipart-post'
end
