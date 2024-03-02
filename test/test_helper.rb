require 'active_support'

require 'minitest/autorun'
require 'minitest/reporters'
require_relative '../lib/ffi-icu'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
