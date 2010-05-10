# encoding: UTF-8

require 'spec_helper'

module ICU::Collation
  describe Collator do

    before { @d = Collator.new("NO") }
    after { @d.close }

    it "should collate an array of strings" do
      @d.collate(%w[å ø æ]).should == %w[æ ø å]
    end

  end
end # ICU::Collate