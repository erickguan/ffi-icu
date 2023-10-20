# encoding: UTF-8

module ICU
  describe Locale do
    describe 'the available locales' do
      subject { Locale.available }

      it { is_expected.to be_an Array }
      it { is_expected.to_not be_empty }

      it 'should be an array of available Locales' do
        expect(subject.first).to be_a(Locale)
      end
    end

    describe 'the available ISO 639 country codes' do
      subject { Locale.iso_countries }

      it { is_expected.to be_an Array }
      it { is_expected.to_not be_empty }

      it 'should be an array of Strings' do
        expect(subject.first).to be_a(String)
      end
    end

    describe 'the available ISO 639 language codes' do
      subject { Locale.iso_languages }

      it { is_expected.to be_an Array }
      it { is_expected.to_not be_empty }

      it 'should be an array of Strings' do
        expect(subject.first).to be_a(String)
      end
    end

    describe 'the default' do
      subject { Locale.default }

      let(:locale) do
        locales = Locale.available
        locales.delete(Locale.default)
        locales.respond_to?(:sample) ? locales.sample : locales.choice
      end

      it { is_expected.to be_a Locale }

      it 'can be assigned using Locale' do
        expect(Locale.default = locale).to eq(locale)
        expect(Locale.default).to eq(locale)
      end

      it 'can be assigned using string' do
        string = locale.to_s

        expect(Locale.default = string).to eq(string)
        expect(Locale.default).to eq(Locale.new(string))
      end

      it 'can be assigned using symbol' do
        symbol = locale.to_s.to_sym

        expect(Locale.default = symbol).to eq(symbol)
        expect(Locale.default).to eq(Locale.new(symbol))
      end
    end

    if Gem::Version.new('4.2') <= Gem::Version.new(Lib.version)
      describe 'BCP 47 language tags' do
        it 'converts a language tag to a locale' do
          expect(Locale.for_language_tag('en-us')).to eq(Locale.new('en_US'))
          expect(Locale.for_language_tag('nan-Hant-tw')).to eq(Locale.new('nan_Hant_TW'))
        end

        it 'returns a language tag for a locale' do
          if Gem::Version.new('4.4') <= Gem::Version.new(Lib.version)
            expect(Locale.new('en_US').to_language_tag).to eq('en-US')
            expect(Locale.new('zh_TW').to_language_tag).to eq('zh-TW')
            # Support for this "magic" transform was dropped with https://unicode-org.atlassian.net/browse/ICU-20187, so don't test it
            if Gem::Version.new(Lib.version) < Gem::Version.new('64')
              expect(Locale.new('zh_Hans_CH_PINYIN').to_language_tag).to eq('zh-Hans-CH-u-co-pinyin')
            else
              expect(Locale.new('zh_Hans_CH@collation=pinyin').to_language_tag).to eq('zh-Hans-CH-u-co-pinyin')
            end
          else
            expect(Locale.new('en_US').to_language_tag).to eq('en-us')
            expect(Locale.new('zh_TW').to_language_tag).to eq('zh-tw')
            expect(Locale.new('zh_Hans_CH_PINYIN').to_language_tag).to eq('zh-hans-ch-u-co-pinyin')
          end
        end
      end
    end

    describe 'Win32 locale IDs' do
      it 'converts an LCID to a locale' do
        expect(Locale.for_lcid(1033)).to eq(Locale.new('en_US'))
        expect(Locale.for_lcid(1036)).to eq(Locale.new('fr_FR'))
      end

      it 'returns an LCID for a locale' do
        expect(Locale.new('en_US').lcid).to eq(1033)
        expect(Locale.new('es_US').lcid).to eq(21514)
      end
    end

    describe 'display' do
      let(:locale_ids) { Locale.available.map(&:id) }

      context 'in a specific locale' do
        it 'returns the country' do
          expect(Locale.new('de_DE').display_country('en')).to eq('Germany')
          expect(Locale.new('en_US').display_country('fr')).to eq('États-Unis')
        end

        it 'returns the language' do
          expect(Locale.new('fr_FR').display_language('de')).to eq('Französisch')
          expect(Locale.new('zh_CH').display_language('en')).to eq('Chinese')
        end

        it 'returns the name' do
          expect(Locale.new('en_US').display_name('de')).to eq('Englisch (Vereinigte Staaten)')
          expect(Locale.new('zh_CH').display_name('fr')).to eq('chinois (Suisse)')
        end

        it 'returns the name using display context' do
          expect(Locale.new('en_US').display_name_with_context('en_HK', [:length_full])).to eq('English (Hong Kong SAR China)')
          expect(Locale.new('en_US').display_name_with_context('en_HK', [:length_short])).to eq('English (Hong Kong)')
        end

        it 'returns the script' do
          expect(Locale.new('ja_Hira_JP').display_script('en')).to eq('Hiragana')
          expect(Locale.new('ja_Hira_JP').display_script('ru')).to eq('хирагана')
        end

        it 'returns the variant' do
          expect(Locale.new('be_BY_TARASK').display_variant('de')).to eq('Taraskievica-Orthographie')
          expect(Locale.new('zh_CH_POSIX').display_variant('en')).to eq('Computer')
        end

        # If memory set for 'read_uchar_buffer' is set too low it will throw an out
        # of bounds memory error, which results in a Segmentation fault error.
        it 'insures memory sizes is set correctly' do
          # Currently, testing the longest known locales. May need to be update in the future.
          expect(Locale.new('en_VI').display_country('ccp')).to_not be_nil
          expect(Locale.new('yue_Hant').display_language('ccp')).to_not be_nil
          expect(Locale.new('en_VI').display_name('ccp')).to_not be_nil
          expect(Locale.new('ccp').display_name_with_context('en_VI')).to_not be_nil
          expect(Locale.new('yue_Hant').display_script('ccp')).to_not be_nil
          expect(Locale.new('en_US_POSIX').display_variant('sl')).to_not be_nil
        end
      end

      context 'in the default locale' do
        let(:locale) { Locale.new('de_DE') }

        it 'returns the country' do
          expect(locale.display_country).to eq(locale.display_country(Locale.default))
        end

        it 'returns the language' do
          expect(locale.display_language).to eq(locale.display_language(Locale.default))
        end

        it 'returns the name' do
          expect(locale.display_name).to eq(locale.display_name(Locale.default))
        end

        it 'returns the script' do
          expect(locale.display_script).to eq(locale.display_script(Locale.default))
        end

        it 'returns the variant' do
          expect(locale.display_variant).to eq(locale.display_variant(Locale.default))
        end
      end
    end

    describe 'formatting' do
      let(:locale) { Locale.new('de-de.utf8@collation = phonebook') }

      it('is formatted') { expect(locale.name).to eq('de_DE.utf8@collation=phonebook') }
      it('is formatted without keywords') { expect(locale.base_name).to eq('de_DE.utf8') }
      it('is formatted for ICU') { expect(locale.canonical).to eq('de_DE@collation=phonebook') }
    end

    it 'truncates a properly formatted locale, returning the "parent"' do
      expect(Locale.new('es-mx').parent).to eq('')
      expect(Locale.new('es_MX').parent).to eq('es')
      expect(Locale.new('zh_Hans_CH_PINYIN').parent).to eq('zh_Hans_CH')
    end

    describe 'ISO codes' do
      it 'returns the ISO 3166 alpha-3 country code' do
        expect(Locale.new('en_US').iso_country).to eq('USA')
        expect(Locale.new('zh_CN').iso_country).to eq('CHN')
      end

      it 'returns the ISO 639 three-letter language code' do
        expect(Locale.new('en_US').iso_language).to eq('eng')
        expect(Locale.new('zh_CN').iso_language).to eq('zho')
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
          expect(locale.keywords).to eq(['currency'])
        end
      end

      it 'can be read' do
        expect(Locale.new('en_US@calendar=chinese').keyword('calendar')).to eq('chinese')
        expect(Locale.new('en_US@calendar=chinese').keyword(:calendar)).to eq('chinese')
        expect(Locale.new('en_US@some=thing').keyword('missing')).to eq('')
      end

      it 'can be added' do
        expect(Locale.new('de_DE').with_keyword('currency', 'EUR')).to eq(Locale.new('de_DE@currency=EUR'))
        expect(Locale.new('de_DE').with_keyword(:currency, :EUR)).to eq(Locale.new('de_DE@currency=EUR'))
      end

      it 'can be added using hash' do
        expect(Locale.new('fr').with_keywords(:a => :b, :c => :d)).to eq(Locale.new('fr@a=b;c=d'))
      end

      it 'can be removed' do
        expect(Locale.new('en_US@some=thing').with_keyword(:some, nil)).to eq(Locale.new('en_US'))
        expect(Locale.new('en_US@some=thing').with_keyword(:some, '')).to eq(Locale.new('en_US'))
      end
    end

    describe 'orientation' do
      it 'returns the character orientation' do
        expect(Locale.new('ar').character_orientation).to eq(:rtl)
        expect(Locale.new('en').character_orientation).to eq(:ltr)
        expect(Locale.new('fa').character_orientation).to eq(:rtl)
      end

      it 'returns the line orientation' do
        expect(Locale.new('ar').line_orientation).to eq(:ttb)
        expect(Locale.new('en').line_orientation).to eq(:ttb)
        expect(Locale.new('fa').line_orientation).to eq(:ttb)
      end
    end

    describe 'subtags' do
      let(:locale) { Locale.new('zh-hans-ch-pinyin') }

      it('returns the country code')  { expect(locale.country).to eq('CH') }
      it('returns the language code') { expect(locale.language).to eq('zh') }
      it('returns the script code')   { expect(locale.script).to eq('Hans') }
      it('returns the variant code')  { expect(locale.variant).to eq('PINYIN') }

      describe 'likely subtags according to UTS #35' do
        it 'adds likely subtags' do
          expect(Locale.new('en').with_likely_subtags).to eq(Locale.new('en_Latn_US'))
          expect(Locale.new('sr').with_likely_subtags).to eq(Locale.new('sr_Cyrl_RS'))
          expect(Locale.new('zh_TW').with_likely_subtags).to eq(Locale.new('zh_Hant_TW'))
        end

        it 'removes likely subtags' do
          expect(Locale.new('en_US').with_minimized_subtags).to eq(Locale.new('en'))
          expect(Locale.new('sr_RS').with_minimized_subtags).to eq(Locale.new('sr'))
          expect(Locale.new('zh_Hant_TW').with_minimized_subtags).to eq(Locale.new('zh_TW'))
        end
      end
    end
  end
end
