require 'test_helper'
require 'minitest/mock'

module ICU
  module CharDet
    class DetectorTest < Minitest::Test
      def setup
        @detector = Detector.new
      end

      def test_recognizes_utf8
        match = @detector.detect('æåø')

        assert_equal 'UTF-8', match.name
        assert_kind_of String, match.language
      end

      def test_has_a_list_of_detectable_charsets
        charsets = @detector.detectable_charsets

        assert_kind_of Array, charsets
        refute_empty charsets
        assert_kind_of String, charsets.first
      end

      def test_disables_and_enables_the_input_filter
        refute_predicate @detector, :input_filter_enabled?
        @detector.input_filter_enabled = true

        assert_predicate @detector, :input_filter_enabled?
      end

      def test_sets_declared_encoding
        calls = []
        set_declared_encoding = Lib.method(:ucsdet_setDeclaredEncoding)
        record_encoding = lambda do |detector, encoding, length, status|
          calls << [encoding, length]
          set_declared_encoding.call(detector, encoding, length, status)
        end

        Lib.stub(:ucsdet_setDeclaredEncoding, record_encoding) do
          @detector.declared_encoding = 'UTF-8'
        end

        assert_equal [['UTF-8', 5]], calls
        assert_equal 'UTF-8', @detector.detect('æåø').name
      end

      def test_detects_several_matching_encodings
        assert_kind_of Array, @detector.detect_all('foo bar')
      end

      def test_supports_null_bytes
        # Create a utf-16 string and then force it to binary (ascii) to mimic data from net/http
        string = 'foo'.encode('UTF-16').force_encoding('binary')
        match = @detector.detect(string)

        assert_equal 'UTF-16BE', match.name
        assert_kind_of String, match.language
      end
    end
  end
end
