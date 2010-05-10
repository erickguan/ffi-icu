# encoding: UTF-8

require 'spec_helper'

module ICU
  module Collation
    describe Collator do
    
      before { @d = Collator.new("no") }
      after { @d.close }

      it "should collate an array of strings" do
        @d.collate(%w[å ø æ]).should == %w[æ ø å]
      end
    
      it "should return available locales" do
        locales = ICU::Collation.available_locales
        locales.should be_kind_of(Array)
        locales.should_not be_empty
      end

    end
  end # Collate
end # ICU