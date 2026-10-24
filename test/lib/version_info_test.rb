require 'test_helper'

module ICU
  module Lib
    class VersionInfoTest < Minitest::Test
      def test_to_a_returns_an_array
        assert_kind_of Array, VersionInfo.new.to_a
      end

      def test_to_s_returns_a_string
        assert_kind_of String, VersionInfo.new.to_s
      end

      def test_to_s_matches_the_version_format
        assert_match(/^[0-9.]+$/, VersionInfo.new.to_s)
      end
    end
  end
end
