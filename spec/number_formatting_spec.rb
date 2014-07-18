# encoding: UTF-8

require 'spec_helper'

module ICU
  module NumberFormatting
    describe 'NumberFormatting' do
      it 'should format a simple integer' do
        NumberFormatting.format_number("en", 1).should == "1"
        NumberFormatting.format_number("en", 1_000).should == "1,000"
        NumberFormatting.format_number("en", 1_000_000).should == "1,000,000"
        NumberFormatting.format_number("de-CH", 1_000_000).should == "1'000'000"
        NumberFormatting.format_number("en-IN", 1_000_000).should == "10,00,000"
        NumberFormatting.format_number("en_GB", 1_000_000).should == "1,000,000"
        NumberFormatting.format_number("hi-IN", 1_000_000_000).should == "१,००,००,००,०००"
      end

      it 'should format a float' do
        NumberFormatting.format_number("en", 1.0).should == "1"
        NumberFormatting.format_number("en", 1.123).should == "1.123"
        NumberFormatting.format_number("en", 1_000.1238).should == "1,000.124"
        NumberFormatting.format_number("en", 1_000.1238, max_fraction_digits: 4).should == "1,000.1238"
        NumberFormatting.set_default_options(fraction_digits: 5)
        NumberFormatting.format_number("en", 1_000.1238).should == "1,000.12380"
        NumberFormatting.clear_default_options
      end

      it 'should format a decimal' do
        NumberFormatting.format_number("en", BigDecimal.new("10000.123")).should == "10,000.123"
      end

      it 'should format a currency' do
        NumberFormatting.format_currency("en", 123.45, 'USD').should == "$123.45"
        NumberFormatting.format_currency("en", 123_123.45, 'USD').should == "$123,123.45"
        NumberFormatting.format_currency("en-IN", 123_456.78, 'USD').should == "$\u{A0}1,23,456.78"
        NumberFormatting.format_currency("es", 123_123.45, 'USD').should == "123.123,45\u{A0}US$"
        NumberFormatting.format_currency("es-mx", 123_123.45, 'USD').should == "US$123,123.45"
        NumberFormatting.format_currency("ja", 123_123.45, 'USD').should == "$123,123.45"
        NumberFormatting.format_currency("ja", 123_123.45, 'JPY').should == "￥123,123"
        NumberFormatting.format_currency("sv", 123_123.45, 'SEK').should == "123\u{A0}123,45\u{A0}kr"
      end

      it 'should format a percent' do
        NumberFormatting.format_percent("en", 1.1).should == "110%"
        NumberFormatting.format_percent("da", 0.15).should == "15\u{A0}%"
        NumberFormatting.format_percent("da", -0.1545, max_fraction_digits: 10).should == "-15,45\u{A0}%"
      end

      it 'should spell numbers' do
        NumberFormatting.spell("en_US", 1_000).should == 'one thousand'
        NumberFormatting.spell("de-CH", 1_000_000_000).should == 'eine Milliarde'
        NumberFormatting.spell("de-DE", 123.456).should == "ein\u{AD}hundert\u{AD}drei\u{AD}und\u{AD}zwanzig Komma vier fünf sechs"
        NumberFormatting.spell("th-TH", 123.456).should == "หนึ่ง\u{200b}ร้อย\u{200b}ยี่\u{200b}สิบ\u{200b}สาม\u{200b}จุด\u{200b}สี่ห้าหก"
      end

			it 'should be able to re-use number formatter objects' do
				numf = NumberFormatting.create('fr-CA') 
				numf.format(1_000).should == "1\u{A0}000"
				numf.format(1_000.123).should == "1\u{A0}000,123"
			end

			it 'should be able to re-use currency formatter objects' do
				curf = NumberFormatting.create('fr-CA', :currency)
				curf.format(1_000.12, 'USD').should == "1\u{A0}000,12\u{A0}$US"
			end
    end
  end # NumberFormatting
end # ICU
