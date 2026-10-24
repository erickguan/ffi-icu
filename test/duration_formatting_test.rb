require 'test_helper'

module ICU
  class DurationFormattingTest < Minitest::Test
    def setup
      skip('Only works on ICU >= 67') if Lib.version.to_a[0] < 67
    end

    def test_produces_hours_minutes_and_seconds_in_order
      result = DurationFormatting.format({ hours: 1, minutes: 2, seconds: 3 }, locale: 'C', style: :long)

      assert_match(/1.*hour.*2.*minute.*3.*second/i, result)
    end

    def test_rounds_down_fractional_seconds_less_than_half
      result = DurationFormatting.format({ seconds: 5.4 }, locale: 'C', style: :long)

      assert_match(/5.*second/i, result)
    end

    def test_rounds_up_fractional_seconds_greater_than_half
      result = DurationFormatting.format({ seconds: 5.6 }, locale: 'C', style: :long)

      assert_match(/6.*second/i, result)
    end

    def test_trims_off_leading_zero_values
      result = DurationFormatting.format({ hours: 0, minutes: 1, seconds: 30 }, locale: 'C', style: :long)

      assert_match(/1.*minute.*30.*second/i, result)
      refute_match(/hour/i, result)
    end

    def test_trims_off_leading_missing_values
      result = DurationFormatting.format({ minutes: 1, seconds: 30 }, locale: 'C', style: :long)

      assert_match(/1.*minute.*30.*second/i, result)
      refute_match(/hour/i, result)
    end

    def test_trims_off_non_leading_zero_values
      result = DurationFormatting.format({ hours: 1, minutes: 0, seconds: 10 }, locale: 'C', style: :long)

      assert_match(/1.*hour.*10.*second/i, result)
      refute_match(/minute/i, result)
    end

    def test_trims_off_non_leading_missing_values
      result = DurationFormatting.format({ hours: 1, seconds: 10 }, locale: 'C', style: :long)

      assert_match(/1.*hour.*10.*second/i, result)
      refute_match(/minute/i, result)
    end

    def test_uses_comma_based_number_formatting_as_appropriate_for_locale
      result = DurationFormatting.format({ seconds: 90_123 }, locale: 'en-AU', style: :long)

      assert_match(/90,123.*second/i, result)
      refute_match(/hour/i, result)
      refute_match(/minute/i, result)
    end

    def test_localizes_unit_names
      result = DurationFormatting.format({ hours: 1, minutes: 2, seconds: 3 }, locale: 'el', style: :long)

      assert_match(/1.*ώρα.*2.*λεπτά.*3.*δευτερόλεπτα/i, result)
    end

    def test_can_format_long
      result = DurationFormatting.format({ hours: 1, minutes: 2, seconds: 3 }, locale: 'en-AU', style: :long)

      assert_match(/hour.*minute.*second/i, result)
    end

    def test_can_format_short
      result = DurationFormatting.format({ hours: 1, minutes: 2, seconds: 3 }, locale: 'en-AU', style: :short)

      assert_match(/hr.*min.*sec/i, result)
      refute_match(/hour/i, result)
      refute_match(/minute/i, result)
      refute_match(/second/i, result)
    end

    def test_can_format_narrow
      result = DurationFormatting.format({ hours: 1, minutes: 2, seconds: 3 }, locale: 'en-AU', style: :narrow)

      expected_pattern = if Lib.version.to_a[0] >= 70
                           /h.*m.*s/i # "1h 2m 3s"
                         else
                           /h.*min.*s/i # "1h 2min 3s"
                         end

      assert_match(expected_pattern, result)
      refute_match(/hr/i, result)
      refute_match(/sec/i, result)
    end

    def test_can_format_digital
      result = DurationFormatting.format({ hours: 1, minutes: 2, seconds: 3 }, locale: 'en-AU', style: :digital)

      assert_equal '1:02:03', result
    end

    def test_can_format_the_full_sequence_of_time_units_in_order
      duration = {
        years: 1,
        months: 2,
        weeks: 3,
        days: 4,
        hours: 5,
        minutes: 6,
        seconds: 7,
        milliseconds: 8,
        microseconds: 9,
        nanoseconds: 10
      }
      result = DurationFormatting.format(duration, locale: 'en-AU', style: :short)

      assert_match(/1.yr.*2.*mths.*3.*wks.*4.*days.*5.*hrs.*6.*mins.*7.*secs.*8.*ms.*9.*μs.*10.*ns/, result)
    end

    def test_joins_ms_us_ns_values_to_seconds_in_digital_format
      duration = { minutes: 10, seconds: 5, milliseconds: 325, microseconds: 53, nanoseconds: 236 }
      result = DurationFormatting.format(duration, locale: 'en-AU', style: :digital)

      assert_equal '10:05.325053236', result
    end

    def test_includes_trailing_zeros_as_appropriate_for_the_last_unit_in_digital_format
      duration = { minutes: 10, seconds: 5, milliseconds: 325, microseconds: 400 }
      result = DurationFormatting.format(duration, locale: 'en-AU', style: :digital)

      assert_equal '10:05.325400', result
    end

    def test_joins_h_mm_ss_and_other_units_in_digital_format
      duration = { days: 8, hours: 23, minutes: 10, seconds: 9 }
      result = DurationFormatting.format(duration, locale: 'en-AU', style: :digital)

      assert_match(/8.*d.*23:10:09/, result)
    end

    def test_ignores_all_decimal_parts_except_the_last_if_it_is_seconds
      duration = { hours: 7.3, minutes: 9.7, seconds: 8.93 }
      result = DurationFormatting.format(duration, locale: 'en-AU', style: :short)

      assert_match(/7[^0-9]*hrs.*9[^0-9]*min.*8\.93[^0-9]*secs/, result)
    end

    def test_ignores_all_decimal_parts_except_the_last_if_it_is_milliseconds
      duration = { hours: 7.3, minutes: 9.7, seconds: 8.93, milliseconds: 632.2 }
      result = DurationFormatting.format(duration, locale: 'en-AU', style: :short)

      assert_match(/7[^0-9]*hrs.*9[^0-9]*min.*8[^0-9]*secs.*632\.2[^0-9]*ms/, result)
    end

    def test_ignores_all_decimal_parts_including_the_last_if_it_is_larger_than_seconds
      duration = { hours: 7.3, minutes: 9.7 }
      result = DurationFormatting.format(duration, locale: 'en-AU', style: :short)

      assert_match(/7[^0-9]*hrs.*9[^0-9]*min/, result)
    end

    def test_raises_on_durations_with_any_negative_component
      duration = { hours: 7.3, minutes: -9.7 }

      assert_raises(ArgumentError) { DurationFormatting.format(duration, locale: 'en-AU') }
    end
  end
end
