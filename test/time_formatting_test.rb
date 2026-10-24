require 'test_helper'

module ICU
  class TimeFormattingTest < Minitest::Test
    T0 = Time.at(1_226_499_676) # in TZ=Europe/Prague Time.mktime(2008, 11, 12, 15, 21, 16)
    T1 = Time.at(1_224_890_117) # in TZ=Europe/Prague Time.mktime(2008, 10, 25, 01, 15, 17)
    T2 = Time.at(1_224_893_778) # in TZ=Europe/Prague Time.mktime(2008, 10, 25, 02, 16, 18)
    T3 = Time.at(1_224_897_439) # in TZ=Europe/Prague Time.mktime(2008, 10, 25, 03, 17, 19)
    T4 = Time.at(1_224_901_100) # in TZ=Europe/Prague Time.mktime(2008, 10, 25, 04, 18, 20)
    T5 = Time.at(1_206_750_921) # in TZ=Europe/Prague Time.mktime(2008, 03, 29, 01, 35, 21)
    T6 = Time.at(1_206_754_582) # in TZ=Europe/Prague Time.mktime(2008, 03, 29, 02, 36, 22)
    T7 = Time.at(1_206_758_243) # in TZ=Europe/Prague Time.mktime(2008, 03, 29, 03, 37, 23)
    T8 = Time.at(1_206_761_904) # in TZ=Europe/Prague Time.mktime(2008, 03, 29, 04, 38, 24)

    def icu_major
      Lib.version.to_a[0]
    end

    def cldr_version
      Lib.cldr_version.to_s
    end

    # lang=cs_CZ zone=Europe/Prague

    def cs_formatter
      TimeFormatting.create(locale: 'cs_CZ', zone: 'Europe/Prague', date: :long, time: :long,
                            tz_style: :localized_long)
    end

    def test_check_date_format_for_lang_cs_cz
      expected = icu_major >= 73 ? "d. MMMM y 'v' H:mm:ss ZZZZ" : 'd. MMMM y H:mm:ss ZZZZ'
      formatter = cs_formatter

      assert_equal expected, formatter.date_format(true)
      assert_equal expected, formatter.date_format(false)
    end

    def test_for_lang_cs_cz_zone_europe_prague
      formatter = cs_formatter
      at = icu_major >= 73 ? ' v ' : ' '

      assert_equal "12. listopadu 2008#{at}15:21:16 GMT+01:00", formatter.format(T0)
      assert_equal "25. října 2008#{at}1:15:17 GMT+02:00", formatter.format(T1)
      assert_equal "25. října 2008#{at}2:16:18 GMT+02:00", formatter.format(T2)
      assert_equal "25. října 2008#{at}3:17:19 GMT+02:00", formatter.format(T3)
      assert_equal "25. října 2008#{at}4:18:20 GMT+02:00", formatter.format(T4)
      assert_equal "29. března 2008#{at}1:35:21 GMT+01:00", formatter.format(T5)
      assert_equal "29. března 2008#{at}2:36:22 GMT+01:00", formatter.format(T6)
      assert_equal "29. března 2008#{at}3:37:23 GMT+01:00", formatter.format(T7)
      assert_equal "29. března 2008#{at}4:38:24 GMT+01:00", formatter.format(T8)
    end

    # lang=en_US zone=Europe/Moscow

    def en_formatter
      TimeFormatting.create(locale: 'en_US', zone: 'Europe/Moscow', date: :short, time: :long,
                            tz_style: :generic_location)
    end

    def en_tz
      cldr_version <= '2.0.1' ? 'Russia Time (Moscow)' : 'Moscow Time'
    end

    def en_sep
      cldr_version <= '2.0.1' ? '' : ','
    end

    def test_check_date_format_for_lang_en_us
      expected = if icu_major >= 73
                   "M/d/yy#{en_sep} h:mm:ss\u202Fa VVVV"
                 else
                   "M/d/yy#{en_sep} h:mm:ss a VVVV"
                 end
      formatter = en_formatter

      assert_equal expected, formatter.date_format(true)
      assert_equal expected, formatter.date_format(false)
    end

    def test_lang_en_us_zone_europe_moscow
      formatter = en_formatter
      space = icu_major >= 73 ? "\u202F" : ' '

      assert_equal "11/12/08, 5:21:16#{space}PM #{en_tz}", formatter.format(T0)
      assert_equal "10/25/08, 3:15:17#{space}AM #{en_tz}", formatter.format(T1)
      assert_equal "10/25/08, 4:16:18#{space}AM #{en_tz}", formatter.format(T2)
      assert_equal "10/25/08, 5:17:19#{space}AM #{en_tz}", formatter.format(T3)
      assert_equal "10/25/08, 6:18:20#{space}AM #{en_tz}", formatter.format(T4)
      assert_equal "3/29/08, 3:35:21#{space}AM #{en_tz}", formatter.format(T5)
      assert_equal "3/29/08, 4:36:22#{space}AM #{en_tz}", formatter.format(T6)
      assert_equal "3/29/08, 5:37:23#{space}AM #{en_tz}", formatter.format(T7)
      assert_equal "3/29/08, 6:38:24#{space}AM #{en_tz}", formatter.format(T8)
    end

    # lang=de_DE zone=Africa/Dakar

    def de_formatter
      TimeFormatting.create(locale: 'de_DE', zone: 'Africa/Dakar', date: :short, time: :long)
    end

    def ge_sep
      cldr_version >= '27.0.1' ? ',' : ''
    end

    def test_check_date_format_for_lang_de_de
      expected = "dd.MM.yy#{ge_sep} HH:mm:ss z"
      formatter = de_formatter

      assert_equal expected, formatter.date_format(true)
      assert_equal expected, formatter.date_format(false)
    end

    def test_lang_de_de_zone_africa_dakar
      formatter = de_formatter
      suffix = icu_major >= 73 ? 'GMT+0' : 'GMT'

      assert_equal "12.11.08#{ge_sep} 14:21:16 #{suffix}", formatter.format(T0)
      assert_equal "24.10.08#{ge_sep} 23:15:17 #{suffix}", formatter.format(T1)
      assert_equal "25.10.08#{ge_sep} 00:16:18 #{suffix}", formatter.format(T2)
      assert_equal "25.10.08#{ge_sep} 01:17:19 #{suffix}", formatter.format(T3)
      assert_equal "25.10.08#{ge_sep} 02:18:20 #{suffix}", formatter.format(T4)
      assert_equal "29.03.08#{ge_sep} 00:35:21 #{suffix}", formatter.format(T5)
      assert_equal "29.03.08#{ge_sep} 01:36:22 #{suffix}", formatter.format(T6)
      assert_equal "29.03.08#{ge_sep} 02:37:23 #{suffix}", formatter.format(T7)
      assert_equal "29.03.08#{ge_sep} 03:38:24 #{suffix}", formatter.format(T8)
    end

    # skeleton pattern

    def test_skeleton_pattern_check_format
      formatter = TimeFormatting.create(locale: 'fr_FR', date: :pattern, time: :pattern, skeleton: 'MMMy')

      assert_equal 'nov. 2008', formatter.format(T0)
      assert_equal 'oct. 2008', formatter.format(T1)
    end

    def test_skeleton_pattern_check_date_format
      formatter = TimeFormatting.create(locale: 'fr_FR', date: :pattern, time: :pattern, skeleton: 'MMMy')

      assert_equal 'MMM y', formatter.date_format(true)
    end

    # supplementary characters in patterns

    def test_parses_a_date_pattern_containing_a_supplementary_character
      formatter = TimeFormatting.create(locale: 'en_US', zone: 'UTC', date: :pattern, time: :pattern)
      formatter.set_date_format(false, "'😀' yyyy-MM-dd")

      assert_equal Time.utc(2020, 1, 2), formatter.parse('😀 2020-01-02')
    end

    def test_applies_a_date_pattern_containing_a_supplementary_character
      formatter = TimeFormatting.create(locale: 'en_US', zone: 'UTC', date: :pattern, time: :pattern)
      formatter.set_date_format(false, "'😀' yyyy-MM-dd")

      assert_equal '😀 2020-01-02', formatter.format(Time.utc(2020, 1, 2))
    end

    def test_applies_a_supplementary_character_pattern_with_a_valid_time_zone_identifier
      formatter = TimeFormatting.create(locale: 'en_US', zone: 'America/Los_Angeles', date: :pattern,
                                        time: :pattern)
      formatter.set_date_format(false, "'😀' VV")

      assert_equal '😀 America/Los_Angeles', formatter.format(Time.utc(2020, 1, 2))
    end
  end

  class TimeFormattingHourCycleTest < Minitest::Test
    # en_AU normally is 12 hours, fr_FR is normally 23 hours
    ['en_AU', 'fr_FR', 'zh_CN'].each do |locale_name|
      define_method("test_#{locale_name}_works_with_hour_cycle_h11") do
        t = Time.new(2021, 0o4, 0o1, 12, 0o5, 0, '+00:00')
        str = TimeFormatting.format(t, time: :short, date: :none, locale: locale_name, zone: 'UTC',
                                       hour_cycle: 'h11')

        assert_match(/0:05/i, str)
        assert_match(/(pm|下午)/i, str)
      end

      define_method("test_#{locale_name}_works_with_hour_cycle_h12") do
        t = Time.new(2021, 0o4, 0o1, 12, 0o5, 0, '+00:00')
        str = TimeFormatting.format(t, time: :short, date: :none, locale: locale_name, zone: 'UTC',
                                       hour_cycle: 'h12')

        assert_match(/12:05/i, str)
        assert_match(/(pm|下午)/i, str)
      end

      define_method("test_#{locale_name}_works_with_hour_cycle_h23") do
        t = Time.new(2021, 0o4, 0o1, 0o0, 0o5, 0, '+00:00')
        str = TimeFormatting.format(t, time: :short, date: :none, locale: locale_name, zone: 'UTC',
                                       hour_cycle: 'h23')

        assert_match(/0:05/i, str)
        refute_match(/(am|pm)/i, str)
      end

      define_method("test_#{locale_name}_works_with_hour_cycle_h24") do
        t = Time.new(2021, 0o4, 0o1, 0o0, 0o5, 0, '+00:00')
        str = TimeFormatting.format(t, time: :short, date: :none, locale: locale_name, zone: 'UTC',
                                       hour_cycle: 'h24')

        assert_match(/24:05/i, str)
        refute_match(/(am|pm)/i, str)
      end

      define_method("test_#{locale_name}_does_not_include_am_pm_if_time_is_not_requested") do
        t = Time.new(2021, 0o4, 0o1, 0o0, 0o5, 0, '+00:00')
        str = TimeFormatting.format(t, time: :none, date: :short, locale: locale_name, zone: 'UTC',
                                       hour_cycle: 'h12')

        refute_match(/(am|pm|下午|上午)/i, str)
      end

      # @hours keyword

      define_method("test_#{locale_name}_works_with_hours_h11_keyword") do
        skip('Only works on ICU >= 67') if Lib.version.to_a[0] < 67

        t = Time.new(2021, 0o4, 0o1, 12, 0o5, 0, '+00:00')
        locale = Locale.new(locale_name).with_keyword('hours', 'h11').to_s
        str = TimeFormatting.format(t, time: :short, date: :none, locale: locale, zone: 'UTC',
                                       hour_cycle: :locale)

        assert_match(/0:05/i, str)
        assert_match(/(pm|下午)/i, str)
      end

      define_method("test_#{locale_name}_works_with_hours_h12_keyword") do
        skip('Only works on ICU >= 67') if Lib.version.to_a[0] < 67

        t = Time.new(2021, 0o4, 0o1, 12, 0o5, 0, '+00:00')
        locale = Locale.new(locale_name).with_keyword('hours', 'h12').to_s
        str = TimeFormatting.format(t, time: :short, date: :none, locale: locale, zone: 'UTC',
                                       hour_cycle: :locale)

        assert_match(/12:05/i, str)
        assert_match(/(pm|下午)/i, str)
      end

      define_method("test_#{locale_name}_works_with_hours_h23_keyword") do
        skip('Only works on ICU >= 67') if Lib.version.to_a[0] < 67

        t = Time.new(2021, 0o4, 0o1, 0o0, 0o5, 0, '+00:00')
        locale = Locale.new(locale_name).with_keyword('hours', 'h23').to_s
        str = TimeFormatting.format(t, time: :short, date: :none, locale: locale, zone: 'UTC',
                                       hour_cycle: :locale)

        assert_match(/0:05/i, str)
        refute_match(/(am|pm)/i, str)
      end

      define_method("test_#{locale_name}_works_with_hours_h24_keyword") do
        skip('Only works on ICU >= 67') if Lib.version.to_a[0] < 67

        t = Time.new(2021, 0o4, 0o1, 0o0, 0o5, 0, '+00:00')
        locale = Locale.new(locale_name).with_keyword('hours', 'h24').to_s
        str = TimeFormatting.format(t, time: :short, date: :none, locale: locale, zone: 'UTC',
                                       hour_cycle: :locale)

        assert_match(/24:05/i, str)
        refute_match(/(am|pm)/i, str)
      end
    end

    def test_for_lang_fi_hour_cycle_h12
      t = Time.new(2021, 0o4, 0o1, 13, 0o5, 0, '+00:00')
      str = TimeFormatting.format(t, locale: 'fi', zone: 'America/Los_Angeles', date: :long, time: :short,
                                     hour_cycle: 'h12')

      assert_match(/\sklo\s/, str)
    end

    def test_works_with_defaults_on_a_h12_locale
      t = Time.new(2021, 0o4, 0o1, 13, 0o5, 0, '+00:00')
      str = TimeFormatting.format(t, time: :short, date: :none, locale: 'en_AU', zone: 'UTC', hour_cycle: :locale)

      assert_match(/1:05/i, str)
      assert_match(/pm/i, str)
    end

    def test_works_with_defaults_on_a_h23_locale
      t = Time.new(2021, 0o4, 0o1, 0, 0o5, 0, '+00:00')
      str = TimeFormatting.format(t, time: :short, date: :none, locale: 'fr_FR', zone: 'UTC', hour_cycle: :locale)

      assert_match(/0:05/i, str)
      refute_match(/(am|pm)/i, str)
    end
  end
end
