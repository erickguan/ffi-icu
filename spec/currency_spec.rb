module ICU
  describe Currency do
    describe '.for_locale' do
      it 'returns the ISO 4217 currency code for a locale' do
        expect(described_class.for_locale('en_US')).to eq('USD')
        expect(described_class.for_locale('de_DE')).to eq('EUR')
      end
    end

    describe '.available' do
      it 'returns an array of ISO 4217 currency codes' do
        codes = described_class.available
        expect(codes).to be_an(Array)
        expect(codes).to include('USD', 'EUR', 'GBP', 'JPY')
      end

      it 'returns fewer currencies when filtering to :common' do
        expect(described_class.available(:common).size).to be < described_class.available.size
      end

      it 'returns only non-deprecated currencies for :non_deprecated' do
        all        = described_class.available
        current    = described_class.available(:non_deprecated)
        deprecated = described_class.available(:deprecated)
        expect(current.size + deprecated.size).to be <= all.size
        expect(deprecated).not_to include('USD')
      end
    end

    describe '.symbol (convenience)' do
      it 'delegates to instance #symbol' do
        expect(described_class.symbol('USD', 'en_US')).to eq('$')
      end
    end

    describe '.name (convenience)' do
      it 'delegates to instance #name' do
        expect(described_class.name('USD', 'en')).to eq('US Dollar')
      end
    end

    describe '#symbol' do
      it 'returns the currency symbol for a locale' do
        expect(described_class.new('USD').symbol('en_US')).to eq('$')
        expect(described_class.new('EUR').symbol('en_US')).to eq('€')
      end

      it 'returns a locale-specific symbol' do
        expect(described_class.new('USD').symbol('zh_CN')).not_to be_empty
      end
    end

    describe '#narrow_symbol' do
      it 'returns the narrow symbol' do
        skip('Requires ICU >= 61') if Lib.version.to_a.first < 61

        expect(described_class.new('USD').narrow_symbol('en_US')).to eq('$')
      end

      it 'raises on old ICU' do
        skip('Only tests the error path on ICU < 61') if Lib.version.to_a.first >= 61

        expect { described_class.new('USD').narrow_symbol('en_US') }.to raise_error(ICU::Error, /ICU >= 61/)
      end
    end

    describe '#name' do
      it 'returns the long display name for a locale' do
        expect(described_class.new('USD').name('en')).to eq('US Dollar')
        expect(described_class.new('EUR').name('en')).to eq('Euro')
      end

      it 'returns a localised name' do
        expect(described_class.new('USD').name('de')).to eq('US-Dollar')
      end
    end

    describe '#plural_name' do
      it 'returns the plural form of the name' do
        skip('Requires ICU >= 4.2') unless Lib.respond_to?(:ucurr_getPluralName)

        usd = described_class.new('USD')
        expect(usd.plural_name('en', 'one')).to   eq('US dollar')
        expect(usd.plural_name('en', 'other')).to eq('US dollars')
      end

      it 'defaults plural_count to "other"' do
        skip('Requires ICU >= 4.2') unless Lib.respond_to?(:ucurr_getPluralName)

        expect(described_class.new('USD').plural_name('en')).to eq('US dollars')
      end
    end

    describe '#fraction_digits' do
      it 'returns 2 for USD' do
        expect(described_class.new('USD').fraction_digits).to eq(2)
      end

      it 'returns 0 for JPY (no decimal places)' do
        expect(described_class.new('JPY').fraction_digits).to eq(0)
      end

      it 'returns 3 for BHD (Bahraini Dinar)' do
        expect(described_class.new('BHD').fraction_digits).to eq(3)
      end

      it 'accepts :cash usage' do
        skip('Requires ICU >= 54') unless Lib.respond_to?(:ucurr_getDefaultFractionDigitsForUsage)

        expect(described_class.new('USD').fraction_digits(:cash)).to eq(2)
      end

      it 'falls back to standard digits for :cash on old ICU' do
        skip('Only tests fallback on ICU < 54') if Lib.respond_to?(:ucurr_getDefaultFractionDigitsForUsage)

        expect(described_class.new('USD').fraction_digits(:cash)).to eq(2)
      end
    end

    describe '#numeric_code' do
      it 'returns the ISO 4217 numeric code' do
        skip('Requires ICU >= 49') unless Lib.respond_to?(:ucurr_getNumericCode)

        expect(described_class.new('USD').numeric_code).to eq(840)
        expect(described_class.new('EUR').numeric_code).to eq(978)
        expect(described_class.new('JPY').numeric_code).to eq(392)
      end
    end

    describe '#to_s' do
      it 'returns the uppercased ISO code' do
        expect(described_class.new('usd').to_s).to eq('USD')
        expect(described_class.new('EUR').to_s).to eq('EUR')
      end
    end

    describe '#code' do
      it 'exposes the currency code as an attribute' do
        expect(described_class.new('GBP').code).to eq('GBP')
      end
    end
  end
end
