require 'test_helper'

module ICU
  class LocaleTest < ActiveSupport::TestCase
    test "the available locales should be an array of available Locales" do
      available_locales = Locale.available
      assert available_locales.is_a?(Array)
      assert !available_locales.empty?
      assert available_locales.first.is_a?(Locale)
    end

    test "the available ISO 639 country codes should be an array of Strings" do
      iso_countries = Locale.iso_countries
      assert iso_countries.is_a?(Array)
      assert !iso_countries.empty?
      assert iso_countries.first.is_a?(String)
    end

    test "the available ISO 639 language codes should be an array of Strings" do
      iso_languages = Locale.iso_languages
      assert iso_languages.is_a?(Array)
      assert !iso_languages.empty?
      assert iso_languages.first.is_a?(String)
    end

    test "the default should be a Locale and can be assigned using Locale" do
      locale = Locale.available.reject { |l| l == Locale.default }.sample

      Locale.default = locale

      assert_equal locale, Locale.default
    end

    test "the default should be a Locale and can be assigned using string" do
      locale = Locale.available.reject { |l| l == Locale.default }.sample

      Locale.default = locale.to_s

      assert_equal Locale.new(string), Locale.default
    end

    test "the default should be a Locale and can be assigned using symbol" do
      locale = Locale.available.reject { |l| l == Locale.default }.sample

      Locale.default = locale.to_s.to_sym

      assert_equal Locale.new(symbol), Locale.default
    end

    test 'BCP 47 language tags returns a language tag for a locale' do
      if Gem::Version.new('4.2') <= Gem::Version.new(Lib.version)
        assert_equal Locale.new('en_US'), Locale.for_language_tag('en-us')
        assert_equal Locale.new('nan_Hant_TW'), Locale.for_language_tag('nan-Hant-tw')
      elsif Gem::Version.new('4.4') <= Gem::Version.new(Lib.version)
        assert_equal 'en-US', Locale.new('en_US').to_language_tag
        assert_equal 'zh-TW', Locale.new('zh_TW').to_language_tag
      else
        assert_equal 'en-us', Locale.new('en_US').to_language_tag
        assert_equal 'zh-tw', Locale.new('zh_TW').to_language_tag
        assert_equal 'zh-hans-ch-u-co-pinyin', Locale.new('zh_Hans_CH_PINYIN').to_language_tag
        assert_equal 'zh-Hans-CH-u-co-pinyin', Locale.new('zh_Hans_CH@collation=pinyin').to_language_tag
      end
    end

    test "Win32 locale IDs converts an LCID to a locale and returns an LCID for a locale" do
      assert_equal Locale.new('en_US'), Locale.for_lcid(1033)
      assert_equal Locale.new('fr_FR'), Locale.for_lcid(1036)

      assert_equal 1033, Locale.new('en_US').lcid
      assert_equal 21514, Locale.new('es_US').lcid
    end

    test "display country in a specific locale" do
      assert_equal 'Germany', Locale.new('de_DE').display_country('en')
      assert_equal 'États-Unis', Locale.new('en_US').display_country('fr')
    end

    test "display language in a specific locale" do
      assert_equal 'Französisch', Locale.new('fr_FR').display_language('de')
      assert_equal 'Chinese', Locale.new('zh_CH').display_language('en')
    end

    test "display locale name in a specific locale" do
      assert_equal 'Englisch (Vereinigte Staaten)', Locale.new('en_US').display_name('de')
      assert_equal 'chinois (Suisse)', Locale.new('zh_CH').display_name('fr')
    end

    test "display locale name with context in a specific locale" do
      assert_equal 'English (Hong Kong SAR China)',
                   Locale.new('en_HK').display_name_with_context('en_US', [:length_full])
      assert_equal 'English (Hong Kong)', Locale.new('en_HK').display_name_with_context('en_US', [:length_short])
    end

    test "display script in a specific locale" do
      assert_equal 'Hiragana', Locale.new('ja_Hira_JP').display_script('en')
      assert_equal 'хирагана', Locale.new('ja_Hira_JP').display_script('ru')
    end

    test "display variant in a specific locale" do
      assert_equal 'Taraskievica-Orthographie', Locale.new('be_BY_TARASK').display_variant('de')
      assert_equal 'Computer', Locale.new('zh_CH_POSIX').display_variant('en')
    end

    # If memory set for 'read_uchar_buffer' is set too low it will throw an out
    # of bounds memory error, which results in a Segmentation fault error.
    test "displays should have correct memory size" do
      # Currently, testing the longest known locales. May need to be update in the future.
      assert !Locale.new('en_VI').display_country('ccp').nil?
      assert !Locale.new('yue_Hant').display_language('ccp').nil?
      assert !Locale.new('en_VI').display_name('ccp').nil?
      assert !Locale.new('en_VI').display_name_with_context('ccp').nil?
      assert !Locale.new('yue_Hant').display_script('ccp').nil?
      assert !Locale.new('en_US_POSIX').display_variant('sl').nil?
    end

    test "display country in the default locale" do
      locale = Locale.new('de_DE')
      assert locale.display_country, locale.display_country(Locale.default)
    end

    test "display language in the default locale" do
      locale = Locale.new('de_DE')
      assert locale.display_language, locale.display_language(Locale.default)
    end

    test "display name in the default locale" do
      locale = Locale.new('de_DE')
      assert locale.display_name, locale.display_name(Locale.default)
    end

    test "display script in the default locale" do
      locale = Locale.new('de_DE')
      assert locale.display_script, locale.display_script(Locale.default)
    end

    test "display variant in the default locale" do
      locale = Locale.new('de_DE')
      assert locale.display_variant, locale.display_variant(Locale.default)
    end

    test "format correctly in various locale representations" do
      locale = Locale.new('de-de.utf8@collation = phonebook')

      assert_equal 'de_DE.utf8@collation=phonebook', locale.name
      assert_equal 'de_DE.utf8', locale.base_name
      assert_equal 'de_DE@collation=phonebook', locale.canonical
    end

    test "truncates a properly formatted locale, returning the 'parent'" do
      assert_equal '', Locale.new('es-mx').parent
      assert_equal 'es', Locale.new('es_MX').parent
      assert_equal 'zh_Hans_CH', Locale.new('zh_Hans_CH_PINYIN').parent
    end

    test "returns ISO 3166 alpha-3 country code" do
      assert_equal 'USA', Locale.new('en_US').iso_country
      assert_equal 'CHN', Locale.new('zh_CN').iso_country
    end

    test "returns ISO 639 three-letter language code" do
      assert_equal 'eng', Locale.new('en_US').iso_language
      assert_equal 'zho', Locale.new('zh_CN').iso_language
    end

    test "#keywords raises an error when improperly formatted" do
      improperly_formatted_locale = Locale.new('de_DE@euro')
      assert_raises(ICU::Error) { improperly_formatted_locale.keywords }
    end

    test "#keywords returns the list of keywords when properly formatted" do
      locale = Locale.new('de_DE@currency=EUR')
      assert_equal ['currency'], locale.keywords
    end

    test '#keyword can be read' do
      assert_equal 'chinese', Locale.new('en_US@calendar=chinese').keyword('calendar')
      assert_equal 'chinese', Locale.new('en_US@calendar=chinese').keyword(:calendar)
      assert_equal '', Locale.new('en_US@some=thing').keyword('missing')
    end

    test '#keyword can be added' do
      assert_equal Locale.new('de_DE@currency=EUR'), Locale.new('de_DE').with_keyword('currency', 'EUR')
      assert_equal Locale.new('de_DE@currency=EUR'), Locale.new('de_DE').with_keyword(:currency, :EUR)
    end

    test '#keyword can be added using hash' do
      assert_equal Locale.new('fr@a=b;c=d'), Locale.new('fr').with_keywords(:a => :b, :c => :d)
    end

    test '#keyword can be removed' do
      assert_equal Locale.new('en_US'), Locale.new('en_US@some=thing').with_keyword(:some, nil)
      assert_equal Locale.new('en_US'), Locale.new('en_US@some=thing').with_keyword(:some, '')
    end

    test "orientation returns the character orientation" do
      assert_equal :rtl, Locale.new('ar').character_orientation
      assert_equal :ltr, Locale.new('en').character_orientation
      assert_equal :rtl, Locale.new('fa').character_orientation
    end

    test "orientation returns the line orientation" do
      assert_equal :ttb, Locale.new('ar').line_orientation
      assert_equal :ttb, Locale.new('en').line_orientation
      assert_equal :ttb, Locale.new('fa').line_orientation
    end

    test "subtags returns country tag" do
      assert_equal 'CH', Locale.new('zh-hans-ch-pinyin').country
    end

    test "subtags returns language tag" do
      assert_equal 'zh', Locale.new('zh-hans-ch-pinyin').language
    end

    test "subtags returns script tag" do
      assert_equal 'Hans', Locale.new('zh-hans-ch-pinyin').script
    end

    test "subtags returns variant tag" do
      assert_equal 'PINYIN', Locale.new('zh-hans-ch-pinyin').variant
    end

    test "returns likely subtags according to UTS #35" do
      assert_equal Locale.new('en_Latn_US'), Locale.new('en').with_likely_subtags
      assert_equal Locale.new('sr_Cyrl_RS'), Locale.new('sr').with_likely_subtags
      assert_equal Locale.new('zh_Hant_TW'), Locale.new('zh_TW').with_likely_subtags
    end

    test "removes likely subtags according to UTS #35" do
      assert_equal Locale.new('en'), Locale.new('en_US').with_minimized_subtags
      assert_equal Locale.new('sr'), Locale.new('sr_RS').with_minimized_subtags
      assert_equal Locale.new('zh_TW'), Locale.new('zh_Hant_TW').with_minimized_subtags
    end
  end
end
