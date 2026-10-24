require 'test_helper'
require 'minitest/mock'

module ICU
  class CollatorTest < Minitest::Test
    def setup
      @collator = Collation::Collator.new('nb')
    end

    def test_collates_an_array_of_strings
      assert_equal ['æ', 'ø', 'å'], @collator.collate(['å', 'ø', 'æ'])
    end

    def test_raises_an_error_if_argument_does_not_respond_to_sort
      assert_raises(ArgumentError) { @collator.collate(1) }
    end

    def test_returns_the_locale_of_the_collator
      assert_equal 'nb', @collator.locale
    end

    def test_compares_two_strings
      assert_equal 1, @collator.compare('blåbærsyltetøy', 'blah')
      assert_equal 0, @collator.compare('blah', 'blah')
      assert_equal(-1, @collator.compare('ba', 'bl'))
    end

    def test_knows_if_a_string_is_greater_than_another
      assert @collator.greater?('z', 'a')
      refute @collator.greater?('a', 'z')
    end

    def test_knows_if_a_string_is_greater_or_equal_to_another
      assert @collator.greater_or_equal?('z', 'a')
      assert @collator.greater_or_equal?('z', 'z')
      refute @collator.greater_or_equal?('a', 'z')
    end

    def test_knows_if_a_string_is_equal_to_another
      assert @collator.equal?('a', 'a')
      refute @collator.equal?('a', 'b')
    end

    def test_compares_strings_containing_supplementary_characters
      comparison = @collator.compare('a😀', 'a😀b')

      refute_equal 0, comparison
      assert_equal comparison.negative?, @collator.greater?('a😀b', 'a😀')
      assert_same true, @collator.greater_or_equal?('a😀', 'a😀')
    end

    def test_checks_equality_for_strings_containing_supplementary_characters
      assert_same true, @collator.equal?('a😀', 'a😀')
      assert_same false, @collator.equal?('a😀', 'a😀b')
    end

    def test_returns_rules
      refute_empty @collator.rules
      # ö sorts before Ö
      assert_includes @collator.rules, 'ö<<<Ö'
    end

    def test_decodes_supplementary_characters_in_rules
      rules_pointer = FFI::MemoryPointer.new(:uint16, 2)
      rules_pointer.write_array_of_uint16([0xD83D, 0xDE00])
      stub = lambda do |_collator, length|
        length.write_int(2)
        rules_pointer
      end

      Lib.stub(:ucol_getRules, stub) do
        assert_equal '😀', @collator.rules
      end
    end

    def test_returns_usable_collation_keys
      assert_operator @collator.collation_key('abc'), :<, @collator.collation_key('xyz')
    end

    def test_returns_collation_keys_for_supplementary_characters
      refute_equal @collator.collation_key('a😀'), @collator.collation_key('a😀b')
    end

    def test_can_set_and_get_normalization_mode
      @collator.normalization_mode = true

      assert_same true, @collator.normalization_mode
      assert_same true, @collator[:normalization_mode]

      @collator[:normalization_mode] = false

      assert_same false, @collator.normalization_mode
    end

    def test_can_set_and_get_case_first
      assert_same false, @collator.case_first

      @collator.case_first = :lower_first

      assert_equal :lower_first, @collator.case_first
    end

    def test_can_set_and_get_strength
      @collator.strength = :tertiary

      assert_equal :tertiary, @collator.strength
    end
  end
end
