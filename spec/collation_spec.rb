# encoding: UTF-8

require 'spec_helper'

module ICU
  module Collation
    describe Collator do

      before { @c = Collator.new("nb") }

      it "should collate an array of strings" do
        @c.collate(%w[å ø æ]).should == %w[æ ø å]
      end

      it "should return available locales" do
        locales = ICU::Collation.available_locales
        locales.should be_kind_of(Array)
        locales.should_not be_empty
        locales.should include("nb")
      end

      it "should return the locale of the collator" do
        l = @c.locale
        l.should be_kind_of(String)
        l.should == "nb"
      end

      it "should compare two strings" do
        @c.compare("blåbærsyltetøy", "blah").should == 1
        @c.compare("blah", "blah").should == 0
        @c.compare("baah", "blah").should == -1
      end

      it "should know if a string is greater than another" do
        @c.should be_greater("z", "a")
        @c.should_not be_greater("a", "z")
      end

      it "should know if a string is greater or equal to another" do
        @c.should be_greater_or_equal("z", "a")
        @c.should be_greater_or_equal("z", "z")
        @c.should_not be_greater_or_equal("a", "z")
      end

      it "should know if a string is equal to another" do
        @c.should be_equal("a", "a")
        @c.should_not be_equal("a", "b")
      end

    end
  end # Collate
end # ICU
