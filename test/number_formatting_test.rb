require 'test_helper'

module ICU
  class NumberFormattingTest < Minitest::Test
    def test_formats_a_simple_integer
      assert_equal('1', NumberFormatting.format_number('en', 1))
      assert_equal('1,000', NumberFormatting.format_number('en', 1_000))
      assert_equal('1.000.000', NumberFormatting.format_number('de-DE', 1_000_000))
    end

    def test_formats_a_float
      assert_equal('1', NumberFormatting.format_number('en', 1.0))
      assert_equal('1.123', NumberFormatting.format_number('en', 1.123))
      assert_equal('1,000.124', NumberFormatting.format_number('en', 1_000.1238))
      assert_equal('1,000.1238', NumberFormatting.format_number('en', 1_000.1238, max_fraction_digits: 4))
      NumberFormatting.set_default_options(fraction_digits: 5)

      assert_equal('1,000.12380', NumberFormatting.format_number('en', 1_000.1238))
    ensure
      NumberFormatting.clear_default_options
    end

    def test_formats_a_decimal
      assert_equal('10,000.123', NumberFormatting.format_number('en', BigDecimal('10000.123')))
    end

    def test_formats_a_currency
      assert_equal('$123.45', NumberFormatting.format_currency('en', 123.45, 'USD'))
      assert_equal('$123,123.45', NumberFormatting.format_currency('en', 123_123.45, 'USD'))
      assert_equal("123.123,45\u{A0}€", NumberFormatting.format_currency('de-DE', 123_123.45, 'EUR'))
    end

    def test_formats_a_percent
      assert_equal('110%', NumberFormatting.format_percent('en', 1.1))
      assert_equal("15\u{A0}%", NumberFormatting.format_percent('da', 0.15))
      assert_equal("-15,45\u{A0}%", NumberFormatting.format_percent('da', -0.1545, max_fraction_digits: 10))
    end

    def test_spells_numbers
      assert_equal('one thousand', NumberFormatting.spell('en_US', 1_000))
      assert_equal("ein\u{AD}hundert\u{AD}drei\u{AD}und\u{AD}zwanzig Komma vier fünf sechs",
                   NumberFormatting.spell('de-DE', 123.456))
    end

    def test_is_able_to_re_use_number_formatter_objects
      numf = NumberFormatting.create('fr-CA')

      assert_equal("1\u{A0}000", numf.format(1_000))
      assert_equal("1\u{A0}000,123", numf.format(1_000.123))
    end

    def test_is_able_to_re_use_currency_formatter_objects
      curf = NumberFormatting.create('en-US', :currency)

      assert_equal('$1,000.12', curf.format(1_000.12, 'USD'))
    end

    def test_allows_for_various_styles_of_currency_formatting_if_the_version_is_new_enough
      icu_major = Lib.version.to_a.first
      if icu_major >= 53
        curf = NumberFormatting.create('en-US', :currency, style: :iso)
        expected = icu_major >= 62 ? "USD\u00A01,000.12" : 'USD1,000.12'

        assert_equal(expected, curf.format(1_000.12, 'USD'))

        curf = NumberFormatting.create('en-US', :currency, style: :plural)

        assert_equal('1,000.12 US dollars', curf.format(1_000.12, 'USD'))
        assert_raises(StandardError) { NumberFormatting.create('en-US', :currency, style: :fake) }
      else
        curf = NumberFormatting.create('en-US', :currency, style: :default)

        assert_equal('$1,000.12', curf.format(1_000.12, 'USD'))
        assert_raises(StandardError) { NumberFormatting.create('en-US', :currency, style: :iso) }
      end
    end

    def test_formats_with_a_skeleton
      assert_equal("1\u{202F}234,50\u{A0}€",
                   NumberFormatting.format_with_skeleton('fr', 1_234.5, 'currency/EUR precision-currency-standard'))
      assert_equal('1.2K', NumberFormatting.format_with_skeleton('en', 1_234, 'compact-short'))
      assert_equal('12.35%', NumberFormatting.format_with_skeleton('en', BigDecimal('12.3456'), 'percent .00'))
      assert_equal('1,000,000,000,000,000,000,000',
                   NumberFormatting.format_with_skeleton('en', 10**21, 'group-auto'))
    end

    def test_is_able_to_re_use_skeleton_formatter_objects
      formatter = NumberFormatting.create_with_skeleton('en', 'precision-integer')

      assert_equal('1,000', formatter.format(999.6))
      assert_equal('-3', formatter.format(-3.1))
    end

    def test_rejects_an_invalid_skeleton
      assert_raises(Error) { NumberFormatting.create_with_skeleton('en', 'not-a-stem') }
    end

    def test_rejects_the_rule_based_style_that_needs_custom_rules
      error = assert_raises(ArgumentError) { NumberFormatting.create('en', :pattern_rule_based) }

      assert_match(/create_with_skeleton/, error.message)
    end

    def test_formats_a_bignum
      str = NumberFormatting.format_number('en', 1_000_000_000_000_000_000_000_000_000_000_000_000_000)

      assert_equal('1,000,000,000,000,000,000,000,000,000,000,000,000,000', str)
    end

    def test_maps_style_aliases_to_their_icu_values
      assert_equal(NumberFormatting.create('en', :decimal).format(1_234.5),
                   NumberFormatting.create('en', :default).format(1_234.5))
      assert_equal(NumberFormatting.create('en', :pattern_decimal).format(1_234.5),
                   NumberFormatting.create('en', :ignore).format(1_234.5))
    end

    def test_formats_compact_and_accounting_styles
      skip('Compact styles require ICU >= 56') if Lib.version.to_a.first < 56

      assert_equal('1.2K', NumberFormatting.create('en', :decimal_compact_short).format(1_234))
      assert_equal('1.2 thousand', NumberFormatting.create('en', :decimal_compact_long).format(1_234))
      assert_equal('($1,234.50)', NumberFormatting.create('en-US', :currency_accounting).format(-1_234.5))
    end
  end
end
