require 'test_helper'

module ICU
  class CurrencyTest < Minitest::Test
    def test_for_locale_returns_the_iso_4217_currency_code_for_a_locale
      assert_equal 'USD', Currency.for_locale('en_US')
      assert_equal 'EUR', Currency.for_locale('de_DE')
    end

    def test_available_returns_an_array_of_iso_4217_currency_codes
      codes = Currency.available

      assert_kind_of Array, codes
      assert_includes codes, 'USD'
      assert_includes codes, 'EUR'
      assert_includes codes, 'GBP'
      assert_includes codes, 'JPY'
    end

    def test_available_returns_fewer_currencies_when_filtering_to_common
      assert_operator Currency.available(:common).size, :<, Currency.available.size
    end

    def test_available_returns_only_non_deprecated_currencies_for_non_deprecated
      all = Currency.available
      current = Currency.available(:non_deprecated)
      deprecated = Currency.available(:deprecated)

      assert_operator current.size + deprecated.size, :<=, all.size
      refute_includes deprecated, 'USD'
    end

    def test_symbol_convenience_delegates_to_instance_symbol
      assert_equal '$', Currency.symbol('USD', 'en_US')
    end

    def test_name_convenience_delegates_to_instance_name
      assert_equal 'US Dollar', Currency.name('USD', 'en')
    end

    def test_symbol_returns_the_currency_symbol_for_a_locale
      assert_equal '$', Currency.new('USD').symbol('en_US')
      assert_equal '€', Currency.new('EUR').symbol('en_US')
    end

    def test_symbol_returns_a_locale_specific_symbol
      refute_empty Currency.new('USD').symbol('zh_CN')
    end

    def test_narrow_symbol_returns_the_narrow_symbol
      skip('Requires ICU >= 61') if Lib.version.to_a.first < 61

      assert_equal '$', Currency.new('USD').narrow_symbol('en_US')
    end

    def test_narrow_symbol_raises_on_old_icu
      skip('Only tests the error path on ICU < 61') if Lib.version.to_a.first >= 61

      error = assert_raises(RuntimeError) { Currency.new('USD').narrow_symbol('en_US') }

      assert_match(/ICU >= 61/, error.message)
    end

    def test_name_returns_the_long_display_name_for_a_locale
      assert_equal 'US Dollar', Currency.new('USD').name('en')
      assert_equal 'Euro', Currency.new('EUR').name('en')
    end

    def test_name_returns_a_localised_name
      assert_equal 'US-Dollar', Currency.new('USD').name('de')
    end

    def test_plural_name_returns_the_plural_form_of_the_name
      skip('Requires ICU >= 4.2') unless Lib.respond_to?(:ucurr_getPluralName)

      usd = Currency.new('USD')

      assert_equal 'US dollar', usd.plural_name('en', 'one')
      assert_equal 'US dollars', usd.plural_name('en', 'other')
    end

    def test_plural_name_defaults_plural_count_to_other
      skip('Requires ICU >= 4.2') unless Lib.respond_to?(:ucurr_getPluralName)

      assert_equal 'US dollars', Currency.new('USD').plural_name('en')
    end

    def test_fraction_digits_returns_2_for_usd
      assert_equal 2, Currency.new('USD').fraction_digits
    end

    def test_fraction_digits_returns_0_for_jpy
      assert_equal 0, Currency.new('JPY').fraction_digits
    end

    def test_fraction_digits_returns_3_for_bhd
      assert_equal 3, Currency.new('BHD').fraction_digits
    end

    def test_fraction_digits_accepts_cash_usage
      skip('Requires ICU >= 54') unless Lib.respond_to?(:ucurr_getDefaultFractionDigitsForUsage)

      assert_equal 2, Currency.new('USD').fraction_digits(:cash)
    end

    def test_fraction_digits_falls_back_to_standard_digits_for_cash_on_old_icu
      skip('Only tests fallback on ICU < 54') if Lib.respond_to?(:ucurr_getDefaultFractionDigitsForUsage)

      assert_equal 2, Currency.new('USD').fraction_digits(:cash)
    end

    def test_numeric_code_returns_the_iso_4217_numeric_code
      skip('Requires ICU >= 49') unless Lib.respond_to?(:ucurr_getNumericCode)

      assert_equal 840, Currency.new('USD').numeric_code
      assert_equal 978, Currency.new('EUR').numeric_code
      assert_equal 392, Currency.new('JPY').numeric_code
    end

    def test_to_s_returns_the_uppercased_iso_code
      assert_equal 'USD', Currency.new('usd').to_s
      assert_equal 'EUR', Currency.new('EUR').to_s
    end

    def test_code_exposes_the_currency_code_as_an_attribute
      assert_equal 'GBP', Currency.new('GBP').code
    end
  end
end
