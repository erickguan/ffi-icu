# encoding: utf-8

require "spec_helper"

module ICU
  describe Transliteration::Transliterator do

    def transliterator(*args)
      @t = Transliteration::Transliterator.new(*args)
    end

    [
     { :id => "Any-Hex",     :input => "abcde",  :output => "\\u0061\\u0062\\u0063\\u0064\\u0065"  },
     { :id => "Lower",       :input => "ABC",    :output => "abc"                                  },
    ].each do |test|

      it "should transliterate #{test[:id]}" do
        transliterator(test[:id]).transliterate(test[:input]).should == test[:output]
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
