# frozen_string_literal: true

require_relative 'test_helper'

class NumberFormattingTest < Minitest::Test
  def test_formats_numbers
    english = ICU::NumberFormatter.new('en')
    german = ICU::NumberFormatter.new('de-DE')

    assert_equal('1', english.format(1))
    assert_equal('1,000', english.format(1_000))
    assert_equal('1,000.124', english.format(1_000.1238))
    assert_equal('1.000.000', german.format(1_000_000))
  end

  def test_formats_currency
    english = ICU::CurrencyFormatter.new('en', 'standard')
    german = ICU::CurrencyFormatter.new('de-DE', 'standard')

    assert_equal('$123.45', english.format(123.45, 'USD'))
    assert_equal('$123,123.45', english.format(123_123.45, 'USD'))
    assert_equal("123.123,45\u00A0€", german.format(123_123.45, 'EUR'))
  end

  def test_currency_styles
    iso = ICU::CurrencyFormatter.new('en-US', 'iso')
    plural = ICU::CurrencyFormatter.new('en-US', 'plural')

    assert_equal("USD\u00A01,000.12", iso.format(1_000.12, 'USD'))
    assert_equal('1,000.12 US dollars', plural.format(1_000.12, 'USD'))
  end

  def test_unknown_currency_style
    assert_raises(ArgumentError) { ICU::CurrencyFormatter.new('en', 'fake') }
  end
end
