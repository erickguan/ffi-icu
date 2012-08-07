# encoding: UTF-8

require 'spec_helper'

module ICU
  describe Locale do
    describe 'the available locales' do
      subject { Locale.available }

      it { should be_an Array }
      it { should_not be_empty }
      its(:first) { should be_a Locale }
    end

    describe 'the available ISO 639 country codes' do
      subject { Locale.iso_countries }

      it { should be_an Array }
      it { should_not be_empty }
      its(:first) { should be_a String }
    end

    describe 'the available ISO 639 language codes' do
      subject { Locale.iso_languages }

      it { should be_an Array }
      it { should_not be_empty }
      its(:first) { should be_a String }
    end

    describe 'the default' do
      subject { Locale.default }

      let(:locale) do
        locales = Locale.available
        locales.delete(Locale.default)
        locales.respond_to?(:sample) ? locales.sample : locales.choice
      end

      it { should be_a Locale }

      it 'can be assigned using Locale' do
        (Locale.default = locale).should == locale
        Locale.default.should == locale
      end

      it 'can be assigned using string' do
        string = locale.to_s

        (Locale.default = string).should == string
        Locale.default.should == Locale.new(string)
      end

      it 'can be assigned using symbol' do
        symbol = locale.to_s.to_sym

        (Locale.default = symbol).should == symbol
        Locale.default.should == Locale.new(symbol)
      end
    end

    describe 'BCP 47 language tags' do
      it 'converts a language tag to a locale' do
        Locale.for_language_tag('en-us').should == Locale.new('en_US')
        Locale.for_language_tag('nan-Hant-tw').should == Locale.new('nan_Hant_TW')
      end

      it 'returns a language tag for a locale' do
        if Gem::Version.new(Lib.cldr_version) < Gem::Version.new('1.8')
          Locale.new('en_US').to_language_tag.should == 'en-us'
          Locale.new('zh_TW').to_language_tag.should == 'zh-tw'
          Locale.new('zh_Hans_CH_PINYIN').to_language_tag.should == 'zh-hans-ch-u-co-pinyin'
        else
          Locale.new('en_US').to_language_tag.should == 'en-US'
          Locale.new('zh_TW').to_language_tag.should == 'zh-TW'
          Locale.new('zh_Hans_CH_PINYIN').to_language_tag.should == 'zh-Hans-CH-u-co-pinyin'
        end
      end
    end

    describe 'Win32 locale IDs' do
      it 'converts an LCID to a locale' do
        Locale.for_lcid(1033).should == Locale.new('en_US')
        Locale.for_lcid(1036).should == Locale.new('fr_FR')
      end

      it 'returns an LCID for a locale' do
        Locale.new('en_US').lcid.should == 1033
        Locale.new('es_US').lcid.should == 21514
      end
    end

    describe 'display' do
      context 'in a specific locale' do
        it 'returns the country' do
          Locale.new('de_DE').display_country('en').should == 'Germany'
          Locale.new('en_US').display_country('fr').should == 'États-Unis'
        end

        it 'returns the language' do
          Locale.new('fr_FR').display_language('de').should == 'Französisch'
          Locale.new('zh_CH').display_language('en').should == 'Chinese'
        end

        it 'returns the name' do
          Locale.new('en_US').display_name('de').should == 'Englisch (Vereinigte Staaten)'
          Locale.new('zh_CH').display_name('fr').should == 'chinois (Suisse)'
        end

        it 'returns the script' do
          Locale.new('ja_Hira_JP').display_script('en').should == 'Hiragana'
          Locale.new('ja_Hira_JP').display_script('ru').should == 'Хирагана'
        end

        it 'returns the variant' do
          Locale.new('zh_Hans_CH_PINYIN').display_variant('en').should == 'Pinyin Romanization'

          if Gem::Version.new(Lib.cldr_version) > Gem::Version.new('1.8')
            Locale.new('zh_Hans_CH_PINYIN').display_variant('es').should == 'Romanización pinyin'
          end
        end
      end

      context 'in the default locale' do
        let(:locale) { Locale.new('de_DE') }

        it 'returns the country' do
          locale.display_country.should == locale.display_country(Locale.default)
        end

        it 'returns the language' do
          locale.display_language.should == locale.display_language(Locale.default)
        end

        it 'returns the name' do
          locale.display_name.should == locale.display_name(Locale.default)
        end

        it 'returns the script' do
          locale.display_script.should == locale.display_script(Locale.default)
        end

        it 'returns the variant' do
          locale.display_variant.should == locale.display_variant(Locale.default)
        end
      end
    end

    describe 'formatting' do
      let(:locale) { Locale.new('de-de.utf8@collation = phonebook') }

      it('is formatted') { locale.name.should == 'de_DE.utf8@collation=phonebook' }
      it('is formatted without keywords') { locale.base_name.should == 'de_DE.utf8' }
      it('is formatted for ICU') { locale.canonical.should == 'de_DE@collation=phonebook' }
    end

    it 'truncates a properly formatted locale, returning the "parent"' do
      Locale.new('es-mx').parent.should == ''
      Locale.new('es_MX').parent.should == 'es'
      Locale.new('zh_Hans_CH_PINYIN').parent.should == 'zh_Hans_CH'
    end

    describe 'ISO codes' do
      it 'returns the ISO 3166 alpha-3 country code' do
        Locale.new('en_US').iso_country.should == 'USA'
        Locale.new('zh_CN').iso_country.should == 'CHN'
      end

      it 'returns the ISO 639 three-letter language code' do
        Locale.new('en_US').iso_language.should == 'eng'
        Locale.new('zh_CN').iso_language.should == 'zho'
      end
    end

    describe 'keywords' do
      context 'when improperly formatted' do
        let(:locale) { Locale.new('de_DE@euro') }

        it 'raises an error' do
          expect { locale.keywords }.to raise_error(ICU::Error)
        end
      end

      context 'when properly formatted' do
        let(:locale) { Locale.new('de_DE@currency=EUR') }

        it 'returns the list of keywords' do
          locale.keywords.should == ['currency']
        end
      end

      it 'can be read' do
        Locale.new('en_US@calendar=chinese').keyword('calendar').should == 'chinese'
        Locale.new('en_US@calendar=chinese').keyword(:calendar).should == 'chinese'
        Locale.new('en_US@some=thing').keyword('missing').should == ''
      end

      it 'can be added' do
        Locale.new('de_DE').with_keyword('currency', 'EUR').should == Locale.new('de_DE@currency=EUR')
        Locale.new('de_DE').with_keyword(:currency, :EUR).should == Locale.new('de_DE@currency=EUR')
      end

      it 'can be added using hash' do
        Locale.new('fr').with_keywords(:a => :b, :c => :d).should == Locale.new('fr@a=b;c=d')
      end

      it 'can be removed' do
        Locale.new('en_US@some=thing').with_keyword(:some, nil).should == Locale.new('en_US')
        Locale.new('en_US@some=thing').with_keyword(:some, '').should == Locale.new('en_US')
      end
    end

    describe 'orientation' do
      it 'returns the character orientation' do
        Locale.new('ar').character_orientation.should == :rtl
        Locale.new('en').character_orientation.should == :ltr
        Locale.new('fa').character_orientation.should == :rtl
      end

      it 'returns the line orientation' do
        Locale.new('ar').line_orientation.should == :ttb
        Locale.new('en').line_orientation.should == :ttb
        Locale.new('fa').line_orientation.should == :ttb
      end
    end

    describe 'subtags' do
      let(:locale) { Locale.new('zh-hans-ch-pinyin') }

      it('returns the country code')  { locale.country.should == 'CH' }
      it('returns the language code') { locale.language.should == 'zh' }
      it('returns the script code')   { locale.script.should == 'Hans' }
      it('returns the variant code')  { locale.variant.should == 'PINYIN' }

      describe 'likely subtags according to UTS #35' do
        it 'adds likely subtags' do
          Locale.new('en').with_likely_subtags.should == Locale.new('en_Latn_US')
          Locale.new('sr').with_likely_subtags.should == Locale.new('sr_Cyrl_RS')
          Locale.new('zh_TW').with_likely_subtags.should == Locale.new('zh_Hant_TW')
        end

        it 'removes likely subtags' do
          Locale.new('en_US').with_minimized_subtags.should == Locale.new('en')
          Locale.new('sr_RS').with_minimized_subtags.should == Locale.new('sr')
          Locale.new('zh_Hant_TW').with_minimized_subtags.should == Locale.new('zh_TW')
        end
      end
    end
  end
end
