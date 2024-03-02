module ICU
  describe Locale do
    describe 'the available locales' do
      subject { described_class.available }

      it { is_expected.to(be_an(Array)) }
      it { is_expected.not_to(be_empty) }

      it 'is an array of available Locales' do
        expect(subject.first).to(be_a(described_class))
      end
    end

    describe 'the available ISO 639 country codes' do
      subject { described_class.iso_countries }

      it { is_expected.to(be_an(Array)) }
      it { is_expected.not_to(be_empty) }

      it 'is an array of Strings' do
        expect(subject.first).to(be_a(String))
      end
    end

    describe 'the available ISO 639 language codes' do
      subject { described_class.iso_languages }

      it { is_expected.to(be_an(Array)) }
      it { is_expected.not_to(be_empty) }

      it 'is an array of Strings' do
        expect(subject.first).to(be_a(String))
      end
    end

    describe 'the default' do
      subject { described_class.default }

      let(:locale) do
        locales = described_class.available
        locales.delete(described_class.default)
        locales.respond_to?(:sample) ? locales.sample : locales.choice
      end

      it { is_expected.to(be_a(described_class)) }

      it 'can be assigned using Locale' do
        expect(described_class.default = locale).to(eq(locale))
        expect(described_class.default).to(eq(locale))
      end

      it 'can be assigned using string' do
        string = locale.to_s

        expect(described_class.default = string).to(eq(string))
        expect(described_class.default).to(eq(described_class.new(string)))
      end

      it 'can be assigned using symbol' do
        symbol = locale.to_s.to_sym

        expect(described_class.default = symbol).to(eq(symbol))
        expect(described_class.default).to(eq(described_class.new(symbol)))
      end
    end

    if Gem::Version.new('4.2') <= Gem::Version.new(Lib.version)
      describe 'BCP 47 language tags' do
        it 'converts a language tag to a locale' do
          expect(described_class.for_language_tag('en-us')).to(eq(described_class.new('en_US')))
          expect(described_class.for_language_tag('nan-Hant-tw')).to(eq(described_class.new('nan_Hant_TW')))
        end

        it 'returns a language tag for a locale' do
          if Gem::Version.new('4.4') <= Gem::Version.new(Lib.version)
            expect(described_class.new('en_US').to_language_tag).to(eq('en-US'))
            expect(described_class.new('zh_TW').to_language_tag).to(eq('zh-TW'))
            # Support for this "magic" transform was dropped with
            # https://unicode-org.atlassian.net/browse/ICU-20187, so don't test it
            if Gem::Version.new(Lib.version) < Gem::Version.new('64')
              expect(described_class.new('zh_Hans_CH_PINYIN').to_language_tag).to(eq('zh-Hans-CH-u-co-pinyin'))
            else
              expect(described_class.new('zh_Hans_CH@collation=pinyin').to_language_tag).to(
                eq('zh-Hans-CH-u-co-pinyin')
              )
            end
          else
            expect(described_class.new('en_US').to_language_tag).to(eq('en-us'))
            expect(described_class.new('zh_TW').to_language_tag).to(eq('zh-tw'))
            expect(described_class.new('zh_Hans_CH_PINYIN').to_language_tag).to(eq('zh-hans-ch-u-co-pinyin'))
          end
        end
      end
    end

    describe 'Win32 locale IDs' do
      it 'converts an LCID to a locale' do
        expect(described_class.for_lcid(1033)).to(eq(described_class.new('en_US')))
        expect(described_class.for_lcid(1036)).to(eq(described_class.new('fr_FR')))
      end

      it 'returns an LCID for a locale' do
        expect(described_class.new('en_US').lcid).to(eq(1033))
        expect(described_class.new('es_US').lcid).to(eq(21_514))
      end
    end

    describe 'display' do
      let(:locale_ids) { described_class.available.map(&:id) }

      context 'in a specific locale' do
        it 'returns the country' do
          expect(described_class.new('de_DE').display_country('en')).to(eq('Germany'))
          expect(described_class.new('en_US').display_country('fr')).to(eq('États-Unis'))
        end

        it 'returns the language' do
          expect(described_class.new('fr_FR').display_language('de')).to(eq('Französisch'))
          expect(described_class.new('zh_CH').display_language('en')).to(eq('Chinese'))
        end

        it 'returns the name' do
          expect(described_class.new('en_US').display_name('de')).to(eq('Englisch (Vereinigte Staaten)'))
          expect(described_class.new('zh_CH').display_name('fr')).to(eq('chinois (Suisse)'))
        end

        it 'returns the name using display context' do
          expect(described_class.new('en_HK').display_name_with_context('en_US',
                                                                        [:length_full])).to(
                                                                          eq('English (Hong Kong SAR China)')
                                                                        )
          expect(described_class.new('en_HK').display_name_with_context('en_US',
                                                                        [:length_short])).to(eq('English (Hong Kong)'))
        end

        it 'returns the script' do
          expect(described_class.new('ja_Hira_JP').display_script('en')).to(eq('Hiragana'))
          expect(described_class.new('ja_Hira_JP').display_script('ru')).to(eq('хирагана'))
        end

        it 'returns the variant' do
          expect(described_class.new('be_BY_TARASK').display_variant('de')).to(eq('Taraskievica-Orthographie'))
          expect(described_class.new('zh_CH_POSIX').display_variant('en')).to(eq('Computer'))
        end

        # If memory set for 'read_uchar_buffer' is set too low it will throw an out
        # of bounds memory error, which results in a Segmentation fault error.
        it 'insures memory sizes is set correctly' do
          # Currently, testing the longest known locales. May need to be update in the future.
          expect(described_class.new('en_VI').display_country('ccp')).not_to(be_nil)
          expect(described_class.new('yue_Hant').display_language('ccp')).not_to(be_nil)
          expect(described_class.new('en_VI').display_name('ccp')).not_to(be_nil)
          expect(described_class.new('en_VI').display_name_with_context('ccp')).not_to(be_nil)
          expect(described_class.new('yue_Hant').display_script('ccp')).not_to(be_nil)
          expect(described_class.new('en_US_POSIX').display_variant('sl')).not_to(be_nil)
        end
      end

      context 'in the default locale' do
        let(:locale) { described_class.new('de_DE') }

        it 'returns the country' do
          expect(locale.display_country).to(eq(locale.display_country(described_class.default)))
        end

        it 'returns the language' do
          expect(locale.display_language).to(eq(locale.display_language(described_class.default)))
        end

        it 'returns the name' do
          expect(locale.display_name).to(eq(locale.display_name(described_class.default)))
        end

        it 'returns the script' do
          expect(locale.display_script).to(eq(locale.display_script(described_class.default)))
        end

        it 'returns the variant' do
          expect(locale.display_variant).to(eq(locale.display_variant(described_class.default)))
        end
      end
    end

    describe 'formatting' do
      let(:locale) { described_class.new('de-de.utf8@collation = phonebook') }

      it('is formatted') { expect(locale.name).to(eq('de_DE.utf8@collation=phonebook')) }
      it('is formatted without keywords') { expect(locale.base_name).to(eq('de_DE.utf8')) }
      it('is formatted for ICU') { expect(locale.canonical).to(eq('de_DE@collation=phonebook')) }
    end

    it 'truncates a properly formatted locale, returning the "parent"' do
      expect(described_class.new('es-mx').parent).to(eq(''))
      expect(described_class.new('es_MX').parent).to(eq('es'))
      expect(described_class.new('zh_Hans_CH_PINYIN').parent).to(eq('zh_Hans_CH'))
    end

    describe 'ISO codes' do
      it 'returns the ISO 3166 alpha-3 country code' do
        expect(described_class.new('en_US').iso_country).to(eq('USA'))
        expect(described_class.new('zh_CN').iso_country).to(eq('CHN'))
      end

      it 'returns the ISO 639 three-letter language code' do
        expect(described_class.new('en_US').iso_language).to(eq('eng'))
        expect(described_class.new('zh_CN').iso_language).to(eq('zho'))
      end
    end

    describe 'keywords' do
      context 'when improperly formatted' do
        let(:locale) { described_class.new('de_DE@euro') }

        it 'raises an error' do
          expect { locale.keywords }.to(raise_error(ICU::Error))
        end
      end

      context 'when properly formatted' do
        let(:locale) { described_class.new('de_DE@currency=EUR') }

        it 'returns the list of keywords' do
          expect(locale.keywords).to(eq(['currency']))
        end
      end

      it 'can be read' do
        expect(described_class.new('en_US@calendar=chinese').keyword('calendar')).to(eq('chinese'))
        expect(described_class.new('en_US@calendar=chinese').keyword(:calendar)).to(eq('chinese'))
        expect(described_class.new('en_US@some=thing').keyword('missing')).to(eq(''))
      end

      it 'can be added' do
        expect(described_class.new('de_DE').with_keyword('currency',
                                                         'EUR')).to(eq(described_class.new('de_DE@currency=EUR')))
        expect(described_class.new('de_DE').with_keyword(:currency,
                                                         :EUR)).to(eq(described_class.new('de_DE@currency=EUR')))
      end

      it 'can be added using hash' do
        expect(described_class.new('fr').with_keywords(a: :b, c: :d)).to(eq(described_class.new('fr@a=b;c=d')))
      end

      it 'can be removed' do
        expect(described_class.new('en_US@some=thing').with_keyword(:some, nil)).to(eq(described_class.new('en_US')))
        expect(described_class.new('en_US@some=thing').with_keyword(:some, '')).to(eq(described_class.new('en_US')))
      end
    end

    describe 'orientation' do
      it 'returns the character orientation' do
        expect(described_class.new('ar').character_orientation).to(eq(:rtl))
        expect(described_class.new('en').character_orientation).to(eq(:ltr))
        expect(described_class.new('fa').character_orientation).to(eq(:rtl))
      end

      it 'returns the line orientation' do
        expect(described_class.new('ar').line_orientation).to(eq(:ttb))
        expect(described_class.new('en').line_orientation).to(eq(:ttb))
        expect(described_class.new('fa').line_orientation).to(eq(:ttb))
      end
    end

    describe 'subtags' do
      let(:locale) { described_class.new('zh-hans-ch-pinyin') }

      it('returns the country code')  { expect(locale.country).to(eq('CH')) }
      it('returns the language code') { expect(locale.language).to(eq('zh')) }
      it('returns the script code')   { expect(locale.script).to(eq('Hans')) }
      it('returns the variant code')  { expect(locale.variant).to(eq('PINYIN')) }

      describe 'likely subtags according to UTS #35' do
        it 'adds likely subtags' do
          expect(described_class.new('en').with_likely_subtags).to(eq(described_class.new('en_Latn_US')))
          expect(described_class.new('sr').with_likely_subtags).to(eq(described_class.new('sr_Cyrl_RS')))
          expect(described_class.new('zh_TW').with_likely_subtags).to(eq(described_class.new('zh_Hant_TW')))
        end

        it 'removes likely subtags' do
          expect(described_class.new('en_US').with_minimized_subtags).to(eq(described_class.new('en')))
          expect(described_class.new('sr_RS').with_minimized_subtags).to(eq(described_class.new('sr')))
          expect(described_class.new('zh_Hant_TW').with_minimized_subtags).to(eq(described_class.new('zh_TW')))
        end
      end
    end
  end
end
