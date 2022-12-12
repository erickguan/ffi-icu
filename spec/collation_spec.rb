# encoding: UTF-8

module ICU
  module Collation
    describe "Collation" do
      it "should collate an array of strings" do
        expect(Collation.collate("nb", %w[æ å ø])).to eq(%w[æ ø å])
      end
    end

    describe Collator do
      let(:collator) { Collator.new("nb") }

      it "should collate an array of strings" do
        expect(collator.collate(%w[å ø æ])).to eq(%w[æ ø å])
      end

      it "raises an error if argument does not respond to :sort" do
        expect { collator.collate(1) }.to raise_error(ArgumentError)
      end

      it "should return available locales" do
        locales = ICU::Collation.available_locales
        expect(locales).to be_an(Array)
        expect(locales).to_not be_empty
        expect(locales).to include("nb")
      end

      it "should return the locale of the collator" do
        expect(collator.locale).to eq('nb')
      end

      it "should compare two strings" do
        expect(collator.compare("blåbærsyltetøy", "blah")).to eq(1)
        expect(collator.compare("blah", "blah")).to eq(0)
        expect(collator.compare("ba", "bl")).to eq(-1)
      end

      it "should know if a string is greater than another" do
        expect(collator).to be_greater("z", "a")
        expect(collator).to_not be_greater("a", "z")
      end

      it "should know if a string is greater or equal to another" do
        expect(collator).to be_greater_or_equal("z", "a")
        expect(collator).to be_greater_or_equal("z", "z")
        expect(collator).to_not be_greater_or_equal("a", "z")
      end

      it "should know if a string is equal to another" do
        expect(collator).to be_equal("a", "a")
        expect(collator).to_not be_equal("a", "b")
      end

      it "should return rules" do
        expect(collator.rules).to_not be_empty
        # ö sorts before Ö
        expect(collator.rules).to include('ö<<<Ö')
      end

      it "returns usable collation keys" do
        collator.collation_key("abc").should be < collator.collation_key("xyz")
      end

      context "attributes" do
        it "can set and get normalization_mode" do
          collator.normalization_mode = true
          collator.normalization_mode.should be true

          collator[:normalization_mode].should be true
          collator[:normalization_mode] = false
          collator.normalization_mode.should be false

          collator.case_first.should be false
          collator.case_first = :lower_first
          collator.case_first.should == :lower_first

          collator.strength = :tertiary
          collator.strength.should == :tertiary
        end
      end
    end
  end # Collate
end # ICU
