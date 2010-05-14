# encoding: utf-8

module ICU
  module Transliteration

    describe Transliterator do

      def transliterator(*args)
        @t = Transliterator.new(*args)
      end
      after { @t.close if @t }

      it "should transliterate Greek-Latin" do
        transliterator("Greek-Latin").transliterate("Hello World").should == "Χελλο Ωορλδ"
      end

      it "should transliterate Lower" do
        transliterator("Lower").transliterate("ABC").should == "abc"
      end

    end

  end
end
