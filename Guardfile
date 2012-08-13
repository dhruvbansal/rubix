# -*- ruby -*-

format  = "progress"      # '--format doc'     for more verbose, --format progress for less
tags    = %w[   ]         # '--tag record_spec' to only run tests tagged :record_spec

guard('rspec', version: 2, all_after_pass: false, all_on_start: false,
  cli: "--format #{format} #{ tags.map{|tag| "--tag #{tag}"}.join(" ")  }") do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^(examples/.+)\.rb}){|m|      "spec/#{m[1]}_spec.rb"  }
  watch(%r{^lib/(.+)\.rb$}){|m|         ["spec/#{m[1]}_spec.rb"] }
  watch('spec/spec_helper.rb'){           "spec" }
  watch(/spec\/support\/(.+)\.rb/){       "spec" }
end

if ENV['YARD']
  guard 'yard', use_cache: true, server: false, stdout: '/dev/null' do
    watch(%r{lib/.+\.rb})
    watch(%r{notes/.+\.(md|txt)}){ "notes" }
  end
end
