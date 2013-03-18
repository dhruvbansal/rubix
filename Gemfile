source "http://rubygems.org"

gemspec

# --------------------------------------------------------------------------

# Only gems that you want listed as development dependencies in the gemspec
group :development do
  gem 'bundler',     "~> 1.1"
  gem 'rake',                    :require => false
end

group :docs do
  gem 'yard',        ">= 0.7",   :require => false  
  gem 'redcarpet',   ">= 2.1",   :platform => [:ruby]
  gem 'kramdown',                :platform => [:jruby]
end

# Gems for testing and coverage
group :test do
  gem 'rspec'
  gem 'simplecov',   ">= 0.5",   :platform => [:ruby_19],   :require => false
end

# Split out database access gems because some devs only work on one or
# the other.
group(:mysql) { gem 'mysql2' }
group(:pg)    { gem 'pg'     }

# Gems you would use if hacking on this gem (rather than with it)
group :support do
  gem 'pry'
  gem 'guard',       ">= 1.0",   :platform => [:ruby_19]
  gem 'guard-rspec', ">= 0.6",   :platform => [:ruby_19]
  gem 'guard-yard',              :platform => [:ruby_19]
end
