# encoding: utf-8

require "spec_helper"

module ICU
  describe Transliteration::Transliterator do

    def transliterator_for(*args)
      Transliteration::Transliterator.new(*args)
    end

    [
      ["Any-Hex", "abcde", "\\u0061\\u0062\\u0063\\u0064\\u0065"],
      ["Lower", "ABC", "abc"]
    ].each do |id, input, output|
      it "should transliterate #{id}" do
        tl = transliterator_for(id)
        tl.transliterate(input).should == output
      end

    end
  end # Transliterator

  describe Transliteration do
    it "should provide a list of available ids" do
      ids = ICU::Transliteration.available_ids
      ids.should be_kind_of(Array)
      ids.should_not be_empty
    end

   it "should transliterate custom rules" do
     ICU::Transliteration.translit("NFD; [:Nonspacing Mark:] Remove; NFC", "âêîôû").should == "aeiou"
   end

  end # Transliteration
end # ICU
