# encoding: utf-8

require "spec_helper"

module ICU
  module Transliteration

    describe Transliterator do

      def transliterator(*args)
        @t = Transliterator.new(*args)
      end

#      after { @t.close if @t }

      it "should transliterate Greek-Latin" do
        transliterator("Greek-Latin").transliterate("Χελλο Ωορλδ").should == "Hello World"
      end

      it "should transliterate Lower" do
        transliterator("Lower").transliterate("ABC").should == "abc"
      end

    end

  end
end
