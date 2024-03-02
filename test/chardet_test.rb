require 'test_helper'

module ICU
  class CharDetDetectorTest < ActiveSupport::TestCase
    def setup
      @charset_detector = ICU::CharDet::Detector.new
    end

    test 'recognizes UTF-8 encoding correctly' do
      detection_result = @charset_detector.detect("æåø")
      assert_equal "UTF-8", detection_result.name
      assert detection_result.language.is_a?(String)
    end

    test 'has a non-empty list of detectable charsets' do
      detectable_charsets = @charset_detector.detectable_charsets
      assert detectable_charsets.is_a?(Array)
      assert !detectable_charsets.empty?
      assert detectable_charsets.first.is_a?(String)
    end

    test 'enables and disables the input filter as expected' do
      assert_equal false, @charset_detector.input_filter_enabled?
      @charset_detector.input_filter_enabled = true
      assert_equal true, @charset_detector.input_filter_enabled?
    end

    test 'sets declared encoding correctly' do
      @charset_detector.declared_encoding = "UTF-8"

      assert_equal 'utf-8', @charset_detector.declared_encoding
    end

    test 'detects several matching encodings for a given string' do
      detection_results = @charset_detector.detect_all("foo bar")
      assert detection_results.is_a?(Array)
    end

    test 'supports detection of null byte strings' do
      utf16_string_with_null_bytes = "foo".encode("UTF-16").force_encoding("binary")
      detection_result = @charset_detector.detect(utf16_string_with_null_bytes)
      assert_equal "UTF-16BE", detection_result.name
      assert detection_result.language.is_a?(String)
    end
  end
end
