# encoding: utf-8

require "spec_helper"

module ICU
  module Transliteration

    describe Transliterator do

      def transliterator(*args)
        @t = Transliterator.new(*args)
      end

#      after { @t.close if @t }

      it "should transliterate Latin-Greek" do
        transliterator("Latin-Greek").transliterate("Hello World").should == "Χελλο Ωορλδ"
      end

      it "should transliterate Lower" do
        transliterator("Lower").transliterate("ABC").should == "abc"
      end

    end

  end
end
