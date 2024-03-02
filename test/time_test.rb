require 'test_helper'

module ICU
  class TimeFormattingTest < ActiveSupport::TestCase
    TEST_LOCALE_HOUR_FORMATTING = ['en_AU', 'fr_FR', 'zh_CN']

    def setup
      @time_0 = Time.at(1226499676) # in TZ=Europe/Prague Time.mktime(2008, 11, 12, 15, 21, 16)
      @time_1 = Time.at(1224890117) # in TZ=Europe/Prague Time.mktime(2008, 10, 25, 01, 15, 17)
      @time_2 = Time.at(1206761904) # in TZ=Europe/Prague Time.mktime(2008, 03, 29, 04, 38, 24)
    end

    test "check date_format for lang=cs_CZ" do
      time_format = TimeFormatting.create(locale: 'cs_CZ', zone: 'Europe/Prague', date: :long, time: :long,
                                          tz_style: :localized_long)

      assert_equal("d. MMMM y 'v' H:mm:ss ZZZZ", time_format.date_format(true))
      assert_equal("d. MMMM y 'v' H:mm:ss ZZZZ", time_format.date_format(false))
    end

    test "for lang=cs_CZ zone=Europe/Prague" do
      time_format = TimeFormatting.create(locale: 'cs_CZ', zone: 'Europe/Prague', date: :long, time: :long,
                                          tz_style: :localized_long)

      assert_instance_of(TimeFormatting::DateTimeFormatter, time_format)
      assert_equal("12. listopadu 2008 v 15:21:16 GMT+01:00", time_format.format(@time_0))
      assert_equal("25. října 2008 v 1:15:17 GMT+02:00", time_format.format(@time_1))
      assert_equal("29. března 2008 v 4:38:24 GMT+01:00", time_format.format(@time_2))
    end

    test "show date_format for lang=en_US" do
      time_format = TimeFormatting.create(locale: 'en_US', zone: 'Europe/Moscow', date: :short, time: :long,
                                          tz_style: :generic_location)

      expected = if Lib.version.to_a.first >= 72
                   "M/d/yy, h:mm:ss a VVVV"
                 else
                   "M/d/yy, h:mm:ss a VVVV"
                 end
      assert_equal(expected, time_format.date_format(true))
      assert_equal(expected, time_format.date_format(false))
    end

    test "format for lang=en_US in Moscow" do
      time_format = TimeFormatting.create(locale: 'en_US', zone: 'Europe/Moscow', date: :short, time: :long,
                                          tz_style: :generic_location)

      if Lib.version.to_a.first >= 72
        assert_equal("11/12/08, 5:21:16 PM Moscow Time",
                     time_format.format(@time_0))
        assert_equal("10/25/08, 3:15:17 AM Moscow Time",
                     time_format.format(@time_1))
        assert_equal("3/29/08, 6:38:24 AM Moscow Time", time_format.format(@time_2))
      else

        assert_equal("11/12/08, 5:21:16 PM Moscow Time",
                     time_format.format(@time_0))
        assert_equal("10/25/08, 3:15:17 AM Moscow Time",
                     time_format.format(@time_1))
        assert_equal("3/29/08, 6:38:24 AM Moscow Time", time_format.format(@time_2))
      end
    end

    test "format for lang=de_DE" do
      time_format = TimeFormatting.create(locale: 'de_DE', zone: 'Africa/Dakar', date: :short, time: :long)

      expected = "dd.MM.yy, HH:mm:ss z"
      assert_equal(expected, time_format.date_format(true))
      assert_equal(expected, time_format.date_format(false))
    end

    test "format for lang=de_DE in Dakar" do
      time_format = TimeFormatting.create(locale: 'de_DE', zone: 'Africa/Dakar', date: :short, time: :long)

      assert_equal("12.11.08, 14:21:16 GMT", time_format.format(@time_0))
      assert_equal("24.10.08, 23:15:17 GMT", time_format.format(@time_1))
      assert_equal("29.03.08, 03:38:24 GMT", time_format.format(@time_2))
    end

    test 'show date_format in skeleton pattern' do
      time_format = TimeFormatting.create(locale: 'fr_FR', date: :pattern, time: :pattern, skeleton: 'MMMy')

      assert_equal("MMM y", time_format.date_format(true))
    end

    test 'format in skeleton pattern' do
      time_format = TimeFormatting.create(locale: 'fr_FR', date: :pattern, time: :pattern, skeleton: 'MMMy')

      assert_equal("nov. 2008", time_format.format(@time_0))
      assert_equal("oct. 2008", time_format.format(@time_1))
    end

    # en_AU normally is 12 hours, fr_FR is normally 23 hours
    test 'works with hour_cycle: h11' do
      time = Time.new(2021, 04, 01, 12, 05, 0, "+00:00")
      TEST_LOCALE_HOUR_FORMATTING.each do |locale_name|
        formatted_time = TimeFormatting.format(time, time: :short, date: :none, locale: locale_name, zone: 'UTC',
                                                     hour_cycle: 'h11')

        assert_match(/0:05/i, formatted_time)
        assert_match(/(pm|下午)/i, formatted_time)
      end
    end

    test 'works with hour_cycle: h12' do
      time = Time.new(2021, 04, 01, 12, 05, 0, "+00:00")
      TEST_LOCALE_HOUR_FORMATTING.each do |locale_name|
        p 'start'

        formatted_time = TimeFormatting.format(time, time: :short, date: :none, locale: locale_name, zone: 'UTC',
                                                     hour_cycle: 'h12')

        assert_match(/12:05/i, formatted_time)
        assert_match(/(pm|下午)/i, formatted_time)
      end
    end

    test 'works with hour_cycle: h23' do
      time = Time.new(2021, 04, 01, 00, 05, 0, "+00:00")
      TEST_LOCALE_HOUR_FORMATTING.each do |locale_name|
        formatted_time = TimeFormatting.format(time, time: :short, date: :none, locale: locale_name, zone: 'UTC',
                                                     hour_cycle: 'h23')

        assert_match(/0:05/i, formatted_time)
        assert formatted_time !~ /(am|pm)/i
      end
    end

    test 'works with hour_cycle: h24' do
      time = Time.new(2021, 04, 01, 00, 05, 0, "+00:00")
      TEST_LOCALE_HOUR_FORMATTING.each do |locale_name|
        formatted_time = TimeFormatting.format(time, time: :short, date: :none, locale: locale_name, zone: 'UTC',
                                                     hour_cycle: 'h24')

        assert_match(/24:05/i, formatted_time)
        assert formatted_time !~ /(am|pm)/i
      end
    end

    test 'does not include am/pm if time is not requested' do
      time = Time.new(2021, 04, 01, 00, 05, 0, "+00:00")
      TEST_LOCALE_HOUR_FORMATTING.each do |locale_name|
        formatted_time = TimeFormatting.format(time, time: :none, date: :short, locale: locale_name, zone: 'UTC',
                                                     hour_cycle: 'h12')

        assert formatted_time !~ /(am|pm|下午|上午)/i
      end
    end

    test 'for lang=fi hour_cycle=h12' do
      time = Time.new(2021, 04, 01, 13, 05, 0, "+00:00")
      TEST_LOCALE_HOUR_FORMATTING.each do |locale_name|
        formatted_time = TimeFormatting.format(time, locale: 'fi', zone: 'America/Los_Angeles', date: :long,
                                                     time: :short, hour_cycle: 'h12')

        assert_match(/\sklo\s/, formatted_time)
      end
    end

    test 'works with defaults on a h12 locale' do
      time = Time.new(2021, 04, 01, 13, 05, 0, "+00:00")
      TEST_LOCALE_HOUR_FORMATTING.each do |locale_name|
        formatted_time = TimeFormatting.format(time, time: :short, date: :none, locale: 'en_AU', zone: 'UTC',
                                                     hour_cycle: :locale)

        assert_match(/1:05/i, formatted_time)
        assert_match(/pm/i, formatted_time)
      end
    end

    test 'works with defaults on a h23 locale' do
      time = Time.new(2021, 04, 01, 0, 05, 0, "+00:00")
      TEST_LOCALE_HOUR_FORMATTING.each do |locale_name|
        formatted_time = TimeFormatting.format(time, time: :short, date: :none, locale: 'fr_FR', zone: 'UTC',
                                                     hour_cycle: :locale)

        assert_match(/0:05/i, formatted_time)
        assert formatted_time !~ /(am|pm)/i
      end
    end

    if Lib.version.to_a[0] < 67 # Only works on ICU >= 67
      test 'works with @hours=h11 keyword' do
        time = Time.new(2021, 04, 01, 12, 05, 0, "+00:00")

        TEST_LOCALE_HOUR_FORMATTING.each do |locale_name|
          locale = Locale.new(locale_name).with_keyword('hours', 'h11').to_s

          formatted_time = TimeFormatting.format(time, time: :short, date: :none, locale: locale, zone: 'UTC',
                                                       hour_cycle: :locale)

          assert_match(/0:05/i, formatted_time)
          assert_match(/(pm|下午)/i, formatted_time)
        end
      end

      test 'works with @hours=h12 keyword' do
        time = Time.new(2021, 04, 01, 12, 05, 0, "+00:00")

        TEST_LOCALE_HOUR_FORMATTING.each do |locale_name|
          locale = Locale.new(locale_name).with_keyword('hours', 'h12').to_s

          formatted_time = TimeFormatting.format(time, time: :short, date: :none, locale: locale, zone: 'UTC',
                                                       hour_cycle: :locale)

          assert_match(/12:05/i, formatted_time)
          assert_match(/(pm|下午)/i, formatted_time)
        end
      end

      test 'works with @hours=h23 keyword' do
        time = Time.new(2021, 04, 01, 00, 05, 0, "+00:00")
        TEST_LOCALE_HOUR_FORMATTING.each do |locale_name|
          locale = Locale.new(locale_name).with_keyword('hours', 'h23').to_s
          formatted_time = TimeFormatting.format(time, time: :short, date: :none, locale: locale, zone: 'UTC',
                                                       hour_cycle: :locale)

          assert_match(/0:05/i, formatted_time)
          assert_match(/(am|pm)/i, formatted_time)
        end
      end

      test 'works with @hours=h24 keyword' do
        time = Time.new(2021, 04, 01, 00, 05, 0, "+00:00")
        TEST_LOCALE_HOUR_FORMATTING.each do |locale_name|
          locale = Locale.new(locale_name).with_keyword('hours', 'h24').to_s
          formatted_time = TimeFormatting.format(time, time: :short, date: :none, locale: locale, zone: 'UTC',
                                                       hour_cycle: :locale)

          assert_match(/24:05/i, formatted_time)
          assert_match(/(am|pm)/i, formatted_time)
        end
      end
    end
  end
end
