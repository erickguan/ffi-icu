require 'test_helper'

module ICU
  class TransliteratorTest < ActiveSupport::TestCase
    def transliterator_for(*args)
      Transliteration::Transliterator.new(*args)
    end

    test "transliterates" do
      [
        ["Any-Hex", "abcde", "\\u0061\\u0062\\u0063\\u0064\\u0065"],
        ["Lower", "ABC", "abc"],
        ["Han-Latin", "雙屬性集合之空間分群演算法-應用於地理資料",
         "shuāng shǔ xìng jí hé zhī kōng jiān fēn qún yǎn suàn fǎ-yīng yòng yú de lǐ zī liào"],
        ["Devanagari-Latin", "दौलत", "daulata"]
      ].each do |id, input, expected|
        tl = transliterator_for(id)
        assert_equal expected, tl.transliterate(input)
      end
    end
  end
end
