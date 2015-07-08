$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require "rubygems"
require 'ffi-icu'
require 'rspec'

RSpec.configure do |config|

  if ENV['TRAVIS']
    config.filter_run_excluding :broken => true
  end
end

if RUBY_VERSION < '1.9'
require 'iconv'
class String
    def encode(charset)
	Iconv.iconv('UTF-8', charset, self)
    end
    def force_encoding(charset)
	self
    end
end
end
