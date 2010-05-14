# encoding: utf-8

module ICU
  module Transliteration

    describe Transliterator do

      before { @t = Transliterator.new("Greek-Latin", :reverse) }
      after { @t.close }

      it "should transliterate a string" do
        @t.transliterate("Hello World").should == "Χελλο Ωορλδ"
      end

    end

  end
end
