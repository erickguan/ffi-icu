require 'rubygems'
require 'rake'

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'
Rake::TestTask.new(:test) do |t|
  t.libs << 'test' << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.warning = false
end

task default: :test

begin
  require('yard')
  YARD::Rake::YardocTask.new
rescue LoadError
  task(:yardoc) do
    abort('YARD is not available. In order to run yardoc, you must: sudo gem install yard')
  end
end
