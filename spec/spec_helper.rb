$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'icu-chardet-ffi'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
  
end

def convert(to, str)
  if RUBY_VERSION < '1.9'
    require "iconv"
    IConv.conv()
  else
  end
end
