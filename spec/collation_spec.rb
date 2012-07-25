# encoding: UTF-8

require 'spec_helper'

module ICU
  module Collation
    describe "Collation" do
      it "should collate an array of strings" do
        Collation.collate("nb", %w[æ å ø]).should == %w[æ ø å]
      end
    end

    describe Collator do
      let(:collator) { Collator.new("nb") }

      it "should collate an array of strings" do
        collator.collate(%w[å ø æ]).should == %w[æ ø å]
      end

      it "raises an error if argument does not respond to :sort" do
        lambda { collator.collate(1) }.should raise_error(ArgumentError)
      end

      it "should return available locales" do
        locales = ICU::Collation.available_locales
        locales.should be_kind_of(Array)
        locales.should_not be_empty
        locales.should include("nb")
      end

      it "should return the locale of the collator" do
        l = collator.locale
        l.should == "nb"
      end

      it "should compare two strings" do
        collator.compare("blåbærsyltetøy", "blah").should == 1
        collator.compare("blah", "blah").should == 0
        collator.compare("ba", "bl").should == -1
      end

      it "should know if a string is greater than another" do
        collator.should be_greater("z", "a")
        collator.should_not be_greater("a", "z")
      end

      it "should know if a string is greater or equal to another" do
        collator.should be_greater_or_equal("z", "a")
        collator.should be_greater_or_equal("z", "z")
        collator.should_not be_greater_or_equal("a", "z")
      end

      it "should know if a string is equal to another" do
        collator.should be_equal("a", "a")
        collator.should_not be_equal("a", "b")
      end

    end
  end # Collate
end # ICU
