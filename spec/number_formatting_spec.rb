# encoding: UTF-8

module ICU
  module NumberFormatting
    describe 'NumberFormatting' do
      it 'should format a simple integer' do
        expect(NumberFormatting.format_number("en", 1)).to eq("1")
        expect(NumberFormatting.format_number("en", 1_000)).to eq("1,000")
        expect(NumberFormatting.format_number("de-DE", 1_000_000)).to eq("1.000.000")
      end

      it 'should format a float' do
        expect(NumberFormatting.format_number("en", 1.0)).to eq("1")
        expect(NumberFormatting.format_number("en", 1.123)).to eq("1.123")
        expect(NumberFormatting.format_number("en", 1_000.1238)).to eq("1,000.124")
        expect(NumberFormatting.format_number("en", 1_000.1238, max_fraction_digits: 4)).to eq("1,000.1238")
        NumberFormatting.set_default_options(fraction_digits: 5)
        expect(NumberFormatting.format_number("en", 1_000.1238)).to eq("1,000.12380")
        NumberFormatting.clear_default_options
      end

      it 'should format a decimal' do
        expect(NumberFormatting.format_number("en", BigDecimal("10000.123"))).to eq("10,000.123")
      end

      it 'should format a currency' do
        expect(NumberFormatting.format_currency("en", 123.45, 'USD')).to eq("$123.45")
        expect(NumberFormatting.format_currency("en", 123_123.45, 'USD')).to eq("$123,123.45")
        expect(NumberFormatting.format_currency("de-DE", 123_123.45, 'EUR')).to eq("123.123,45\u{A0}€")
      end

      it 'should format a percent' do
        expect(NumberFormatting.format_percent("en", 1.1)).to eq("110%")
        expect(NumberFormatting.format_percent("da", 0.15)).to eq("15\u{A0}%")
        expect(NumberFormatting.format_percent("da", -0.1545, max_fraction_digits: 10)).to eq("-15,45\u{A0}%")
      end

      it 'should spell numbers' do
        expect(NumberFormatting.spell("en_US", 1_000)).to eq('one thousand')
        expect(NumberFormatting.spell("de-DE", 123.456)).to eq("ein\u{AD}hundert\u{AD}drei\u{AD}und\u{AD}zwanzig Komma vier fünf sechs")
      end

      it 'should be able to re-use number formatter objects' do
        numf = NumberFormatting.create('fr-CA')
        expect(numf.format(1_000)).to eq("1\u{A0}000")
        expect(numf.format(1_000.123)).to eq("1\u{A0}000,123")
      end

      it 'should be able to re-use currency formatter objects' do
        curf = NumberFormatting.create('en-US', :currency)
        expect(curf.format(1_000.12, 'USD')).to eq("$1,000.12")
      end

      it 'should allow for various styles of currency formatting if the version is new enough' do
        if ICU::Lib.version.to_a.first >= 53
          curf = NumberFormatting.create('en-US', :currency, style: :iso)
          expected = if ICU::Lib.version.to_a.first >= 62
            "USD\u00A01,000.12"
          else
            "USD1,000.12"
          end
          expect(curf.format(1_000.12, 'USD')).to eq(expected)
          curf = NumberFormatting.create('en-US', :currency, style: :plural)
          expect(curf.format(1_000.12, 'USD')).to eq("1,000.12 US dollars")
          expect { NumberFormatting.create('en-US', :currency, style: :fake) }.to raise_error(StandardError)
        else
          curf = NumberFormatting.create('en-US', :currency, style: :default)
          expect(curf.format(1_000.12, 'USD')).to eq('$1,000.12')
          expect { NumberFormatting.create('en-US', :currency, style: :iso) }.to raise_error(StandardError)
        end
      end

      it 'should format a bignum' do
        str = NumberFormatting.format_number("en", 1_000_000_000_000_000_000_000_000_000_000_000_000_000)
        expect(str).to eq('1,000,000,000,000,000,000,000,000,000,000,000,000,000')
      end
    end
  end # NumberFormatting
end # ICU
