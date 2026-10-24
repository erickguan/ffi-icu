require 'test_helper'

module ICU
  class LocaleTest < Minitest::Test
    def icu_version
      Gem::Version.new(Lib.version)
    end

    def test_available_is_an_array
      assert_kind_of Array, Locale.available
    end

    def test_available_is_not_empty
      refute_empty Locale.available
    end

    def test_available_contains_locales
      assert_kind_of Locale, Locale.available.first
    end

    def test_iso_countries_is_an_array
      assert_kind_of Array, Locale.iso_countries
    end

    def test_iso_countries_is_not_empty
      refute_empty Locale.iso_countries
    end

    def test_iso_countries_contains_strings
      assert_kind_of String, Locale.iso_countries.first
    end

    def test_iso_languages_is_an_array
      assert_kind_of Array, Locale.iso_languages
    end

    def test_iso_languages_is_not_empty
      refute_empty Locale.iso_languages
    end

    def test_iso_languages_contains_strings
      assert_kind_of String, Locale.iso_languages.first
    end

    # BCP 47 language tags

    def test_converts_a_language_tag_to_a_locale
      skip('Requires ICU >= 4.2') if icu_version < Gem::Version.new('4.2')

      assert_equal Locale.new('en_US'), Locale.for_language_tag('en-us')
      assert_equal Locale.new('nan_Hant_TW'), Locale.for_language_tag('nan-Hant-tw')
    end

    def test_returns_a_language_tag_for_a_locale
      skip('Requires ICU >= 4.2') if icu_version < Gem::Version.new('4.2')

      if icu_version >= Gem::Version.new('4.4')
        assert_equal 'en-US', Locale.new('en_US').to_language_tag
        assert_equal 'zh-TW', Locale.new('zh_TW').to_language_tag
        # Support for this "magic" transform was dropped with
        # https://unicode-org.atlassian.net/browse/ICU-20187, so don't test it
        if icu_version < Gem::Version.new('64')
          assert_equal 'zh-Hans-CH-u-co-pinyin', Locale.new('zh_Hans_CH_PINYIN').to_language_tag
        else
          assert_equal 'zh-Hans-CH-u-co-pinyin', Locale.new('zh_Hans_CH@collation=pinyin').to_language_tag
        end
      else
        assert_equal 'en-us', Locale.new('en_US').to_language_tag
        assert_equal 'zh-tw', Locale.new('zh_TW').to_language_tag
        assert_equal 'zh-hans-ch-u-co-pinyin', Locale.new('zh_Hans_CH_PINYIN').to_language_tag
      end
    end

    # Win32 locale IDs

    def test_converts_an_lcid_to_a_locale
      assert_equal Locale.new('en_US'), Locale.for_lcid(1033)
      assert_equal Locale.new('fr_FR'), Locale.for_lcid(1036)
    end

    def test_returns_an_lcid_for_a_locale
      assert_equal 1033, Locale.new('en_US').lcid
      assert_equal 21_514, Locale.new('es_US').lcid
    end

    # formatting

    def test_is_formatted
      assert_equal 'de_DE.utf8@collation=phonebook', Locale.new('de-de.utf8@collation = phonebook').name
    end

    def test_is_formatted_without_keywords
      assert_equal 'de_DE.utf8', Locale.new('de-de.utf8@collation = phonebook').base_name
    end

    def test_is_formatted_for_icu
      assert_equal 'de_DE@collation=phonebook', Locale.new('de-de.utf8@collation = phonebook').canonical
    end

    def test_truncates_a_properly_formatted_locale_returning_the_parent
      assert_equal '', Locale.new('es-mx').parent
      assert_equal 'es', Locale.new('es_MX').parent
      assert_equal 'zh_Hans_CH', Locale.new('zh_Hans_CH_PINYIN').parent
    end

    # ISO codes

    def test_returns_the_iso_3166_alpha_3_country_code
      assert_equal 'USA', Locale.new('en_US').iso_country
      assert_equal 'CHN', Locale.new('zh_CN').iso_country
    end

    def test_returns_the_iso_639_three_letter_language_code
      assert_equal 'eng', Locale.new('en_US').iso_language
      assert_equal 'zho', Locale.new('zh_CN').iso_language
    end

    # orientation

    def test_returns_the_character_orientation
      assert_equal :rtl, Locale.new('ar').character_orientation
      assert_equal :ltr, Locale.new('en').character_orientation
      assert_equal :rtl, Locale.new('fa').character_orientation
    end

    def test_returns_the_line_orientation
      assert_equal :ttb, Locale.new('ar').line_orientation
      assert_equal :ttb, Locale.new('en').line_orientation
      assert_equal :ttb, Locale.new('fa').line_orientation
    end
  end

  class LocaleDefaultTest < Minitest::Test
    def setup
      @original_default = Locale.default
      locales = Locale.available
      locales.delete(Locale.default)
      @locale = locales.sample
    end

    def teardown
      Locale.default = @original_default
    end

    def test_default_is_a_locale
      assert_kind_of Locale, Locale.default
    end

    def test_can_be_assigned_using_locale
      Locale.default = @locale

      assert_equal @locale, Locale.default
    end

    def test_can_be_assigned_using_string
      string = @locale.to_s

      Locale.default = string

      assert_equal Locale.new(string), Locale.default
    end

    def test_can_be_assigned_using_symbol
      symbol = @locale.to_s.to_sym

      Locale.default = symbol

      assert_equal Locale.new(symbol), Locale.default
    end
  end

  class LocaleDisplayTest < Minitest::Test
    # in a specific locale

    def test_returns_the_country
      assert_equal 'Germany', Locale.new('de_DE').display_country('en')
      assert_equal 'États-Unis', Locale.new('en_US').display_country('fr')
    end

    def test_returns_the_language
      assert_equal 'Französisch', Locale.new('fr_FR').display_language('de')
      assert_equal 'Chinese', Locale.new('zh_CH').display_language('en')
    end

    def test_returns_the_name
      assert_equal 'Englisch (Vereinigte Staaten)', Locale.new('en_US').display_name('de')
      assert_equal 'chinois (Suisse)', Locale.new('zh_CH').display_name('fr')
    end

    def test_returns_the_name_using_display_context
      assert_equal 'Dari', Locale.new('fa-AF').display_name_with_context('en', [:dialect_names])
      assert_equal 'English (Hong Kong SAR China)',
                   Locale.new('en_HK').display_name_with_context('en_US', [:length_full])
      assert_equal 'English (Hong Kong)',
                   Locale.new('en_HK').display_name_with_context('en_US', [:length_short])
    end

    def test_returns_the_script
      assert_equal 'Hiragana', Locale.new('ja_Hira_JP').display_script('en')
      assert_equal 'хирагана', Locale.new('ja_Hira_JP').display_script('ru')
    end

    def test_returns_the_variant
      assert_equal 'Taraskievica-Orthographie', Locale.new('be_BY_TARASK').display_variant('de')
      assert_equal 'Computer', Locale.new('zh_CH_POSIX').display_variant('en')
    end

    # If memory set for 'read_uchar_buffer' is set too low it will throw an out
    # of bounds memory error, which results in a Segmentation fault error.
    def test_insures_memory_sizes_is_set_correctly
      # Currently, testing the longest known locales. May need to be update in the future.
      refute_nil Locale.new('en_VI').display_country('ccp')
      refute_nil Locale.new('yue_Hant').display_language('ccp')
      refute_nil Locale.new('en_VI').display_name('ccp')
      refute_nil Locale.new('en_VI').display_name_with_context('ccp')
      refute_nil Locale.new('yue_Hant').display_script('ccp')
      refute_nil Locale.new('en_US_POSIX').display_variant('sl')
    end

    # in the default locale

    def test_returns_the_country_in_the_default_locale
      locale = Locale.new('de_DE')

      assert_equal locale.display_country(Locale.default), locale.display_country
    end

    def test_returns_the_language_in_the_default_locale
      locale = Locale.new('de_DE')

      assert_equal locale.display_language(Locale.default), locale.display_language
    end

    def test_returns_the_name_in_the_default_locale
      locale = Locale.new('de_DE')

      assert_equal locale.display_name(Locale.default), locale.display_name
    end

    def test_returns_the_script_in_the_default_locale
      locale = Locale.new('de_DE')

      assert_equal locale.display_script(Locale.default), locale.display_script
    end

    def test_returns_the_variant_in_the_default_locale
      locale = Locale.new('de_DE')

      assert_equal locale.display_variant(Locale.default), locale.display_variant
    end
  end

  class LocaleKeywordsTest < Minitest::Test
    def test_raises_an_error_when_improperly_formatted
      assert_raises(ICU::Error) { Locale.new('de_DE@euro').keywords }
    end

    def test_returns_the_list_of_keywords_when_properly_formatted
      assert_equal ['currency'], Locale.new('de_DE@currency=EUR').keywords
    end

    def test_can_be_read
      assert_equal 'chinese', Locale.new('en_US@calendar=chinese').keyword('calendar')
      assert_equal 'chinese', Locale.new('en_US@calendar=chinese').keyword(:calendar)
      assert_equal '', Locale.new('en_US@some=thing').keyword('missing')
    end

    def test_can_be_added
      assert_equal Locale.new('de_DE@currency=EUR'), Locale.new('de_DE').with_keyword('currency', 'EUR')
      assert_equal Locale.new('de_DE@currency=EUR'), Locale.new('de_DE').with_keyword(:currency, :EUR)
    end

    def test_can_be_added_using_hash
      assert_equal Locale.new('fr@a=b;c=d'), Locale.new('fr').with_keywords(a: :b, c: :d)
    end

    def test_can_be_removed
      assert_equal Locale.new('en_US'), Locale.new('en_US@some=thing').with_keyword(:some, nil)
      assert_equal Locale.new('en_US'), Locale.new('en_US@some=thing').with_keyword(:some, '')
    end
  end

  class LocaleSubtagsTest < Minitest::Test
    def setup
      @locale = Locale.new('zh-hans-ch-pinyin')
    end

    def test_returns_the_country_code
      assert_equal 'CH', @locale.country
    end

    def test_returns_the_language_code
      assert_equal 'zh', @locale.language
    end

    def test_returns_the_script_code
      assert_equal 'Hans', @locale.script
    end

    def test_returns_the_variant_code
      assert_equal 'PINYIN', @locale.variant
    end

    def test_adds_likely_subtags
      assert_equal Locale.new('en_Latn_US'), Locale.new('en').with_likely_subtags
      assert_equal Locale.new('sr_Cyrl_RS'), Locale.new('sr').with_likely_subtags
      assert_equal Locale.new('zh_Hant_TW'), Locale.new('zh_TW').with_likely_subtags
    end

    def test_removes_likely_subtags
      assert_equal Locale.new('en'), Locale.new('en_US').with_minimized_subtags
      assert_equal Locale.new('sr'), Locale.new('sr_RS').with_minimized_subtags
      assert_equal Locale.new('zh_TW'), Locale.new('zh_Hant_TW').with_minimized_subtags
    end
  end
end
