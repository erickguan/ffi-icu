# encoding: utf-8

require "spec_helper"

module ICU
  describe Transliteration::Transliterator do
    def transliterator_for(*args)
      Transliteration::Transliterator.new(*args)
    end

    [
      ["Any-Hex", "abcde", "\\u0061\\u0062\\u0063\\u0064\\u0065"],
      ["Lower", "ABC", "abc"],
      ["en", "雙屬性集合之空間分群演算法-應用於地理資料", "shuāng shǔ xìng jí hé zhī kōng jiān fēn qún yǎn suàn fǎ-yīng yòng yú de lǐ zī liào"],
      ["Devanagari-Latin", "दौलत", "daulata"]
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
