$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require "rubygems"
require 'ffi-icu'
require 'rspec'

RSpec.configure do |config|

  if ENV['TRAVIS']
    config.filter_run_excluding broken: true
  end
end
