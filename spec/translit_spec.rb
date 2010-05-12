# encoding: utf-8

module ICU
  module Translit

    describe Transliterator do

      before { @t = Transliterator.new("Any-FCC") }
      after { @t.close }

      it "should transliterate a string" do
        @t.transliterate("æåø").should == "aeao"
      end

    end

  end
end
