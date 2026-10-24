require 'test_helper'

module ICU
  class ListFormattingTest < Minitest::Test
    def setup
      functions = [:ulistfmt_openForType, :ulistfmt_close, :ulistfmt_format]
      skip('Only works on ICU >= 67') unless functions.all? { |function| Lib.respond_to?(function) }
    end

    def test_formats_two_item_and_three_item_lists
      assert_equal 'Alice and Bob', ListFormatting.format(['Alice', 'Bob'], locale: 'en')
      assert_equal 'Alice, Bob, and Jane',
                   ListFormatting.format(['Alice', 'Bob', 'Jane'], locale: 'en', style: :and)
    end

    def test_formats_an_and_list_using_the_explicit_style
      assert_equal 'Alice, Bob et Jane',
                   ListFormatting.format(['Alice', 'Bob', 'Jane'], locale: 'fr', style: :and)
    end

    def test_formats_an_or_list
      assert_equal 'Alice, Bob, or Jane',
                   ListFormatting.format(['Alice', 'Bob', 'Jane'], locale: 'en', style: :or)
    end

    def test_formats_a_unit_list_without_a_conjunction
      assert_equal 'Alice, Bob, Jane',
                   ListFormatting.format(['Alice', 'Bob', 'Jane'], locale: 'en', style: :unit)
    end

    def test_handles_empty_and_single_item_lists
      assert_equal '', ListFormatting.format([], locale: 'en')
      assert_equal 'Alice', ListFormatting.format(['Alice'], locale: 'en')
    end

    def test_preserves_bmp_and_supplementary_unicode_item_contents
      assert_equal 'José, 東京, and 😀🚀', ListFormatting.format(['José', '東京', '😀🚀'], locale: 'en')
    end

    def test_grows_the_output_buffer_for_long_item_contents
      items = ['A' * 256, 'B' * 256, 'C' * 256]

      assert_equal "#{items[0]}, #{items[1]}, and #{items[2]}", ListFormatting.format(items, locale: 'en')
    end

    def test_rejects_unknown_styles
      error = assert_raises(ArgumentError) do
        ListFormatting.format(['Alice', 'Bob'], locale: 'en', style: :standard)
      end

      assert_equal 'Unknown style standard', error.message
    end

    def test_requires_symbol_styles
      error = assert_raises(ArgumentError) do
        ListFormatting.format(['Alice', 'Bob'], locale: 'en', style: 'and')
      end

      assert_equal 'Unknown style and', error.message
    end

    def test_rejects_non_string_items_explicitly
      error = assert_raises(ArgumentError) { ListFormatting.format(['Alice', 2], locale: 'en') }

      assert_equal 'items must be strings', error.message
    end

    def test_uses_locale_specific_conjunction_rules
      assert_equal 'uno, due e tre',
                   ListFormatting.format(['uno', 'due', 'tre'], locale: 'it', style: :and)
    end
  end
end
