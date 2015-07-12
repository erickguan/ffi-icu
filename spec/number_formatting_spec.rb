# encoding: UTF-8

require 'spec_helper'

module ICU
  if RUBY_VERSION < '1.9'
     A0char = "\xC2\xA0"
     ADchar = "\xC2\xAD"
  else
     A0char = "\u{A0}"
     ADchar = "\u{AD}"
  end
  module NumberFormatting
    describe 'NumberFormatting' do
      it 'should format a simple integer' do
        NumberFormatting.format_number("en", 1).should == "1"
        NumberFormatting.format_number("en", 1_000).should == "1,000"
        NumberFormatting.format_number("de-DE", 1_000_000).should == "1.000.000"
      end

      it 'should format a float' do
        NumberFormatting.format_number("en", 1.0).should == "1"
        NumberFormatting.format_number("en", 1.123).should == "1.123"
        NumberFormatting.format_number("en", 1_000.1238).should == "1,000.124"
        NumberFormatting.format_number("en", 1_000.1238, :max_fraction_digits => 4).should == "1,000.1238"
        NumberFormatting.set_default_options(:fraction_digits => 5)
        NumberFormatting.format_number("en", 1_000.1238).should == "1,000.12380"
        NumberFormatting.clear_default_options
      end

      it 'should format a decimal' do
        NumberFormatting.format_number("en", BigDecimal.new("10000.123")).should == "10,000.123"
      end

      it 'should format a currency' do
        NumberFormatting.format_currency("en", 123.45, 'USD').should == "$123.45"
        NumberFormatting.format_currency("en", 123_123.45, 'USD').should == "$123,123.45"
        NumberFormatting.format_currency("de-DE", 123_123.45, 'EUR').should == "123.123,45#{A0char}€"
      end

      it 'should format a percent' do
        NumberFormatting.format_percent("en", 1.1).should == "110%"
        NumberFormatting.format_percent("da", 0.15).should == "15#{A0char}%"
        NumberFormatting.format_percent("da", -0.1545, :max_fraction_digits => 10).should == "-15,45#{A0char}%"
      end

      it 'should spell numbers' do
        NumberFormatting.spell("en_US", 1_000).should == 'one thousand'
        NumberFormatting.spell("de-DE", 123.456).should == "ein#{ADchar}hundert#{ADchar}drei#{ADchar}und#{ADchar}zwanzig Komma vier fünf sechs"
      end

      it 'should be able to re-use number formatter objects' do
        numf = NumberFormatting.create('fr-CA')
        numf.format(1_000).should == "1#{A0char}000"
        numf.format(1_000.123).should == "1#{A0char}000,123"
      end

      it 'should be able to re-use currency formatter objects' do
        curf = NumberFormatting.create('en-US', :currency)
        curf.format(1_000.12, 'USD').should == "$1,000.12"
      end

      it 'should allow for various styles of currency formatting if the version is new enough' do
        if ICU::Lib.version.to_a.first >= 53
          curf = NumberFormatting.create('en-US', :currency, :style => :iso)
          curf.format(1_000.12, 'USD').should == "USD1,000.12"
          curf = NumberFormatting.create('en-US', :currency, :style => :plural)
          curf.format(1_000.12, 'USD').should == "1,000.12 US dollars"
          expect { NumberFormatting.create('en-US', :currency, :style => :fake) }.to raise_error(StandardError)
        else
          curf = NumberFormatting.create('en-US', :currency, :style => :default)
          curf.format(1_000.12, 'USD').should == '$1,000.12'
          expect { NumberFormatting.create('en-US', :currency, :style => :iso) }.to raise_error(StandardError)
        end
      end
    end
  end # NumberFormatting
end # ICU
