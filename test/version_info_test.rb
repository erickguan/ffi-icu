require 'test_helper'

module ICU
  module Lib
    class VersionInfoTest < ActiveSupport::TestCase
      test ".to_a returns an Array" do
        version_info_array = VersionInfo.new.to_a
        assert version_info_array.is_a?(Array)
      end

      test ".to_s returns a String that matches version format" do
        version_info_string = VersionInfo.new.to_s
        assert version_info_string.is_a?(String)
        assert_match(/^[0-9.]+$/, version_info_string)
      end
    end
  end
end
