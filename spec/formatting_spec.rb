# encoding: UTF-8

require 'spec_helper'

module ICU
  module NumberFormatting
    describe "NumberFormatting" do
      it "should format a simple integer" do
        NumberFormatting.format_number("en", 1).should == "1"
        NumberFormatting.format_number("en", 1_000).should == "1,000"
        NumberFormatting.format_number("en", 1_000_000).should == "1,000,000"
      end

      it "should format a float" do
        NumberFormatting.format_number("en", 1.0).should == "1"
        NumberFormatting.format_number("en", 1.123).should == "1.123"
        NumberFormatting.format_number("en", 1_000.1238).should == "1,000.124"
        NumberFormatting.format_number("en", 1_000.1238, max_fraction_digits: 4).should == "1,000.1238"
        NumberFormatting.set_default_options(fraction_digits: 5)
        NumberFormatting.format_number("en", 1_000.1238).should == "1,000.12380"
        NumberFormatting.clear_default_options
      end

      it "should format a decimal" do
        NumberFormatting.format_number("en", BigDecimal.new("10000.123")).should == "10,000.123"
      end

      it 'should format a currency' do
        NumberFormatting.format_currency("en", 123.45, 'USD').should == "$123.45"
        NumberFormatting.format_currency("en", 123_123.45, 'USD').should == "$123,123.45"
        NumberFormatting.format_currency("es", 123_123.45, 'USD').should == "123.123,45\u{A0}US$"
        NumberFormatting.format_currency("ja", 123_123.45, 'USD').should == "$123,123.45"
        NumberFormatting.format_currency("sv", 123_123.45, 'SEK').should == "123\u{A0}123,45\u{A0}kr"
      end
    end
  end
end # ICU
