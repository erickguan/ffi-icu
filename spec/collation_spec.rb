# encoding: UTF-8

require 'spec_helper'

module ICU
  module Collation
    describe Collator do

      before { @c = Collator.new("no") }
      after { @c.close }

      it "should collate an array of strings" do
        @c.collate(%w[å ø æ]).should == %w[æ ø å]
      end

      it "should return available locales" do
        locales = ICU::Collation.available_locales
        locales.should be_kind_of(Array)
        locales.should_not be_empty
      end

      it "should return the locale of the collator" do
        l = @c.locale
        l.should be_kind_of(String)
        l.should == "nb"
      end

    end
  end # Collate
end # ICU