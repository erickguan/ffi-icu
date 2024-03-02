require 'test_helper'
require 'bigdecimal'

module ICU
  class NumberFormattingTest < ActiveSupport::TestCase
    test "formats a simple integer" do
      assert_equal "1", NumberFormatting.format_number("en", 1)
      assert_equal "1,000", NumberFormatting.format_number("en", 1_000)
      assert_equal "1.000.000", NumberFormatting.format_number("de-DE", 1_000_000)
    end

    test "formats a float" do
      assert_equal "1", NumberFormatting.format_number("en", 1.0)
      assert_equal "1.123", NumberFormatting.format_number("en", 1.123)
      assert_equal "1,000.124", NumberFormatting.format_number("en", 1_000.1238)
    end

    test "formats a float with max fraction digits" do
      assert_equal "1,000.1238", NumberFormatting.format_number("en", 1_000.1238, max_fraction_digits: 4)
    end

    test "formats a float with fraction digits" do
      NumberFormatting.set_default_options(fraction_digits: 5)
      assert_equal "1,000.12380", NumberFormatting.format_number("en", 1_000.1238)
      NumberFormatting.clear_default_options
    end

    test "formats a decimal" do
      assert_equal "10,000.123", NumberFormatting.format_number("en", BigDecimal("10000.123"))
    end

    test "formats a currency" do
      assert_equal "$123.45", NumberFormatting.format_currency("en", 123.45, 'USD')
      assert_equal "$123,123.45", NumberFormatting.format_currency("en", 123_123.45, 'USD')
      assert_equal "123.123,45\u{A0}€", NumberFormatting.format_currency("de-DE", 123_123.45, 'EUR')
    end

    test "formats a percent" do
      assert_equal "110%", NumberFormatting.format_percent("en", 1.1)
      assert_equal "15\u{A0}%", NumberFormatting.format_percent("da", 0.15)
    end

    test "formats a percent with max fraction digits" do
      assert_equal "-15,45\u{A0}%", NumberFormatting.format_percent("da", -0.1545, max_fraction_digits: 10)
    end

    test "spells numbers" do
      assert_equal 'one thousand', NumberFormatting.spell("en_US", 1_000)
      assert_equal "ein\u{AD}hundert\u{AD}drei\u{AD}und\u{AD}zwanzig Komma vier fünf sechs",
                   NumberFormatting.spell("de-DE", 123.456)
    end

    test "re-uses number formatter objects" do
      numf = NumberFormatting.create('fr-CA')
      assert_equal "1\u{A0}000", numf.format(1_000)
      assert_equal "1\u{A0}000,123", numf.format(1_000.123)
    end

    test "re-uses currency formatter objects" do
      curf = NumberFormatting.create('en-US', :currency)
      assert_equal "$1,000.12", curf.format(1_000.12, 'USD')
    end

    test "allows for various styles of currency formatting for newer ICU" do
      if ICU::Lib.version.to_a.first >= 53
        curf = NumberFormatting.create('en-US', :currency, style: :iso)

        expected = if ICU::Lib.version.to_a.first >= 62
                     "USD\u00A01,000.12"
                   else
                     "USD1,000.12"
                   end

        assert_equal expected, curf.format(1_000.12, 'USD')

        curf = NumberFormatting.create('en-US', :currency, style: :plural)
        assert_equal "1,000.12 US dollars", curf.format(1_000.12, 'USD')
        assert_raises(StandardError) { NumberFormatting.create('en-US', :currency, style: :fake) }
      else
        curf = NumberFormatting.create('en-US', :currency, style: :default)
        assert_equal '$1,000.12', curf.format(1_000.12, 'USD')
        assert_raises(StandardError) { NumberFormatting.create('en-US', :currency, style: :iso) }
      end
    end

    test "formats a bignum" do
      str = NumberFormatting.format_number("en", 1_000_000_000_000_000_000_000_000_000_000_000_000_000)
      assert_equal '1,000,000,000,000,000,000,000,000,000,000,000,000,000', str
    end
  end
end
