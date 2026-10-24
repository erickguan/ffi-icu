require 'test_helper'

module ICU
  class MessageFormattingTest < Minitest::Test
    PLURAL = '{0, plural, one {# item} other {# items}}'.freeze
    SELECT = '{0, select, male {He} female {She} other {They}}'.freeze

    # .validate

    def test_validate_accepts_a_valid_numbered_message_pattern
      assert_same true, MessageFormatting.validate(PLURAL, locale: 'en-US')
    end

    def test_validate_raises_an_error_with_parse_details_for_an_invalid_pattern
      error = assert_raises(MessageFormatting::InvalidPatternError) do
        MessageFormatting.validate('{0, plural, one {# item}', locale: 'en-US')
      end

      assert_equal 'en-US', error.locale
      assert_equal '{0, plural, one {# item}', error.pattern
      assert_operator error.offset, :>=, 0
    end

    # .valid?

    def test_valid_returns_true_for_a_valid_numbered_message_pattern
      assert_same true, MessageFormatting.valid?(PLURAL, locale: 'en-US')
    end

    def test_valid_returns_false_for_an_invalid_pattern
      assert_same false, MessageFormatting.valid?('{0, plural, one {# item}', locale: 'en-US')
    end

    # .format

    def test_formats_a_numbered_string_argument
      assert_equal 'Hello, Ada!', MessageFormatting.format('Hello, {0}!', locale: 'en-US', arguments: ['Ada'])
    end

    def test_formats_multiple_string_arguments
      assert_equal 'Ada and Grace',
                   MessageFormatting.format('{0} and {1}', locale: 'en-US', arguments: ['Ada', 'Grace'])
    end

    def test_formats_plural_arguments_using_the_locale
      assert_equal '1 item', MessageFormatting.format(PLURAL, locale: 'en-US', arguments: [1])
      assert_equal '2 items', MessageFormatting.format(PLURAL, locale: 'en-US', arguments: [2])
    end

    def test_formats_select_arguments
      assert_equal 'She', MessageFormatting.format(SELECT, locale: 'en-US', arguments: ['female'])
      assert_equal 'They', MessageFormatting.format(SELECT, locale: 'en-US', arguments: ['unknown'])
    end

    def test_supports_reusable_formatter_instances
      formatter = MessageFormatting.create(PLURAL, locale: 'en-US')

      assert_equal '1 item', formatter.format([1])
      assert_equal '3 items', formatter.format([3])
    end

    def test_supports_decimal_arguments
      assert_equal '1.5', MessageFormatting.format('{0, number}', locale: 'en-US', arguments: [1.5])
    end

    def test_supports_unicode_arguments
      assert_equal 'Hello, 😀!', MessageFormatting.format('Hello, {0}!', locale: 'en-US', arguments: ['😀'])
    end

    def test_rejects_unsupported_argument_types
      formatter = MessageFormatting.create('{0}', locale: 'en-US')

      error = assert_raises(ArgumentError) { formatter.format([Object.new]) }

      assert_match(/unsupported/, error.message)
    end

    def test_requires_an_array_of_numbered_arguments
      formatter = MessageFormatting.create('{0}', locale: 'en-US')

      error = assert_raises(ArgumentError) { formatter.format(name: 'Ada') }

      assert_match(/Array of numbered values/, error.message)
    end

    def test_rejects_too_few_numbered_arguments_before_calling_icu
      formatter = MessageFormatting.create('{1}', locale: 'en-US')

      error = assert_raises(ArgumentError) { formatter.format(['Ada']) }

      assert_match(/at least 2 numbered arguments/, error.message)
    end

    def test_does_not_treat_quoted_argument_syntax_as_an_argument
      assert_equal '{0}', MessageFormatting.format("'{0}'", locale: 'en-US', arguments: [])
    end

    def test_rejects_a_string_passed_to_a_numeric_argument_slot
      formatter = MessageFormatting.create(PLURAL, locale: 'en-US')

      error = assert_raises(ArgumentError) { formatter.format(['two']) }

      assert_match(/argument 0 expects a numeric value, got String/, error.message)
    end

    def test_rejects_a_number_passed_to_a_select_argument_slot
      formatter = MessageFormatting.create(SELECT, locale: 'en-US')

      error = assert_raises(ArgumentError) { formatter.format([1]) }

      assert_match(/argument 0 expects a String, got Integer/, error.message)
    end

    def test_rejects_a_number_passed_to_a_simple_argument_slot
      formatter = MessageFormatting.create('Hello, {0}!', locale: 'en-US')

      error = assert_raises(ArgumentError) { formatter.format([42]) }

      assert_match(/argument 0 expects a String, got Integer/, error.message)
    end

    def test_accepts_a_numeric_argument_for_a_date_slot
      formatter = MessageFormatting.create('{0, date, full}', locale: 'en-US')

      assert_kind_of String, formatter.format([0])
    end
  end
end
