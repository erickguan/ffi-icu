require 'test_helper'

module ICU
  class UCharPointerTest < Minitest::Test
    def test_allocates_enough_memory_for_16_bit_characters
      assert_equal 10, UCharPointer.new(5).size
    end

    def test_builds_a_buffer_from_a_string
      ptr = UCharPointer.from_utf8('abc')

      assert_kind_of UCharPointer, ptr
      assert_equal 6, ptr.size
      assert_equal [0x61, 0x62, 0x63], ptr.read_array_of_uint16(3)
    end

    def test_transcodes_strings_with_a_non_utf_8_encoding
      ptr = UCharPointer.from_utf8('café'.encode(Encoding::ISO_8859_1))

      assert_equal 'café', ptr.utf8_string
    end

    def test_encodes_non_bmp_characters_as_utf_16_code_units
      ptr = UCharPointer.from_utf8('😀')

      assert_equal [0xD83D, 0xDE00], ptr.read_array_of_uint16(2)
      assert_equal '😀', ptr.utf8_string
    end

    def test_takes_an_optional_capacity
      assert_equal 10, UCharPointer.from_utf8('abc', 5).size
    end

    def test_preserves_contents_when_growing_a_buffer
      resized = UCharPointer.from_utf8('abc').resized_to(6)

      assert_equal 12, resized.size
      assert_equal 'abc', resized.utf8_string(3)
    end
  end

  class UCharPointerConversionTest < Minitest::Test
    def setup
      @ptr = UCharPointer.new(3).write_array_of_uint16([0x78, 0x0, 0x79])
    end

    def test_returns_the_entire_buffer_by_default
      assert_equal "x\0y", @ptr.utf8_string
    end

    def test_returns_strings_of_the_specified_length
      assert_equal '', @ptr.utf8_string(0)
      assert_equal "x\0", @ptr.utf8_string(2)
    end

    def test_round_trips_supplementary_characters
      value = '😀🚀'

      assert_equal value, UCharPointer.from_utf8(value).utf8_string
    end

    def test_round_trips_an_empty_string
      assert_equal '', UCharPointer.from_utf8('').utf8_string
    end
  end
end
