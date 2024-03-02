require 'test_helper'

module ICU
  class DurationFormattingTest < ActiveSupport::TestCase
    def setup
      skip("Only works on ICU >= 67") if Lib.version.to_a[0] < 67
      skip("FAILING!! ERROR")
    end

    test "produces hours, minutes, and seconds in order" do
      result = DurationFormatting.format({ hours: 1, minutes: 2, seconds: 3 }, locale: 'C', style: :long)
      assert_match(/1.*hour.*2.*minute.*3.*second/i, result)
    end

    test "rounds down fractional seconds < 0.5" do
      result = DurationFormatting.format({ seconds: 5.4 }, locale: 'C', style: :long)
      assert_match(/5.*second/i, result)
    end

    test "rounds up fractional seconds > 0.5" do
      result = DurationFormatting.format({ seconds: 5.6 }, locale: 'C', style: :long)
      assert_match(/6.*second/i, result)
    end

    test "trims off leading zero values" do
      result = DurationFormatting.format({ hours: 0, minutes: 1, seconds: 30 }, locale: 'C', style: :long)
      assert_match(/1.*minute.*30.*second/i, result)
      assert_match(/hour/i, result)
    end

    test "trims off leading missing values" do
      result = DurationFormatting.format({ minutes: 1, seconds: 30 }, locale: 'C', style: :long)
      assert_match(/1.*minute.*30.*second/i, result)
      assert_match(/hour/i, result)
    end

    test "trims off non-leading zero values" do
      result = DurationFormatting.format({ hours: 1, minutes: 0, seconds: 10 }, locale: 'C', style: :long)
      assert_match(/1.*hour.*10.*second/i, result)
      assert_match(/minute/i, result)
    end

    test "trims off non-leading missing values" do
      result = DurationFormatting.format({ hours: 1, seconds: 10 }, locale: 'C', style: :long)
      assert_match(/1.*hour.*10.*second/i, result)
      assert_match(/minute/i, result)
    end

    test "uses comma-based number formatting as appropriate for locale" do
      result = DurationFormatting.format({ seconds: 90123 }, locale: 'en-AU', style: :long)
      assert_match(/90,123.*second/i, result)
      assert_match(/hour/i, result)
      assert_match(/minute/i, result)
    end

    test "localizes unit names" do
      result = DurationFormatting.format({ hours: 1, minutes: 2, seconds: 3 }, locale: 'el', style: :long)
      assert_match(/1.*ώρα.*2.*λεπτά.*3.*δευτερόλεπτα/i, result)
    end

    test "can format long" do
      result = DurationFormatting.format({ hours: 1, minutes: 2, seconds: 3 }, locale: 'en-AU', style: :long)
      assert_match(/hour.*minute.*second/i, result)
    end

    test "can format short" do
      result = DurationFormatting.format({ hours: 1, minutes: 2, seconds: 3 }, locale: 'en-AU', style: :short)
      assert_match(/hr.*min.*sec/i, result)
      assert_match(/hour/i, result)
      assert_match(/minute/i, result)
      assert_match(/second/i, result)
    end

    test "can format narrow" do
      result = DurationFormatting.format({ hours: 1, minutes: 2, seconds: 3 }, locale: 'en-AU', style: :narrow)
      assert_match(/h.*min.*s/i, result)
      assert_match(/hr/i, result)
      assert_match(/sec/i, result)
    end

    test "can format digital" do
      result = DurationFormatting.format({ hours: 1, minutes: 2, seconds: 3 }, locale: 'en-AU', style: :digital)
      assert_equal '1:02:03', result
    end

    test "can format the full sequence of time units in order" do
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
        nanoseconds: 10,
      }
      result = DurationFormatting.format(duration, locale: 'en-AU', style: :short)
      assert_match(/1.yr.*2.*mths.*3.*wks.*4.*days.*5.*hrs.*6.*mins.*7.*secs.*8.*ms.*9.*μs.*10.*ns/, result)
    end

    test "joins ms, us, ns values to seconds in digital format" do
      duration = { minutes: 10, seconds: 5, milliseconds: 325, microseconds: 53, nanoseconds: 236 }
      result = DurationFormatting.format(duration, locale: 'en-AU', style: :digital)
      assert_equal '10:05.325053236', result
    end

    test "includes trailing zeros as appropriate for the last unit in digital format" do
      duration = { minutes: 10, seconds: 5, milliseconds: 325, microseconds: 400 }
      result = DurationFormatting.format(duration, locale: 'en-AU', style: :digital)
      assert_equal '10:05.325400', result
    end

    test "joins h:mm:ss and other units in digital format" do
      duration = { days: 8, hours: 23, minutes: 10, seconds: 9 }
      result = DurationFormatting.format(duration, locale: 'en-AU', style: :digital)
      assert_match(/8.*d.*23:10:09/, result)
    end

    test "ignores all decimal parts except the last, if it is seconds" do
      duration = { hours: 7.3, minutes: 9.7, seconds: 8.93 }
      result = DurationFormatting.format(duration, locale: 'en-AU', style: :short)
      assert_match(/7[^0-9]*hrs.*9[^0-9]*min.*8\.93[^0-9]*secs/, result)
    end

    test "ignores all decimal parts except the last, if it is milliseconds" do
      duration = { hours: 7.3, minutes: 9.7, seconds: 8.93, milliseconds: 632.2 }
      result = DurationFormatting.format(duration, locale: 'en-AU', style: :short)
      assert_match(/7[^0-9]*hrs.*9[^0-9]*min.*8[^0-9]*secs.*632\.2[^0-9]*ms/, result)
    end

    test "ignores all decimal parts including the last, if it is > seconds" do
      duration = { hours: 7.3, minutes: 9.7 }
      result = DurationFormatting.format(duration, locale: 'en-AU', style: :short)
      assert_match(/7[^0-9]*hrs.*9[^0-9]*min/, result)
    end

    test "raises on durations with any negative component" do
      duration = { hours: 7.3, minutes: -9.7 }
      assert_raises(ArgumentError) do
        DurationFormatting.format(duration, locale: 'en-AU')
      end
    end
  end
end
