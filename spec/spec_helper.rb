$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require "rubygems"
require 'icu-chardet-ffi'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|

end

