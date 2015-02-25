require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = './spec/{break_iterator,collation,chardet,lib,locale,normalization,number_formatting,time,uchar}_spec.rb'
end

task :default => :spec
