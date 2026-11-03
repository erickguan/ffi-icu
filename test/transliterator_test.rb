require 'test_helper'

module ICU
  class TransliteratorTest < Minitest::Test
    def test_transliterates_any_hex
      assert_equal('\\u0061\\u0062\\u0063\\u0064\\u0065', transliterator_for('Any-Hex').transliterate('abcde'))
    end

    def test_transliterates_lower
      assert_equal('abc', transliterator_for('Lower').transliterate('ABC'))
    end

    def test_transliterates_han_latin
      assert_equal('shuāng shǔ xìng jí hé zhī kōng jiān fēn qún yǎn suàn fǎ-yīng yòng yú de lǐ zī liào',
                   transliterator_for('Han-Latin').transliterate('雙屬性集合之空間分群演算法-應用於地理資料'))
    end

    def test_transliterates_devanagari_latin
      assert_equal('daulata', transliterator_for('Devanagari-Latin').transliterate('दौलत'))
    end

    def test_handles_supplementary_characters
      assert_equal('😀', transliterator_for('Lower').transliterate('😀'))
    end

    def test_applies_custom_rules_containing_supplementary_characters
      transliterator = transliterator_for('Any-Latin', '😀 > X;')

      assert_equal('X', transliterator.transliterate('😀'))
    end

    def test_reports_malformed_custom_rules
      error = assert_raises(ICU::Error) { transliterator_for('NFD', '[') }

      assert_match(/\AU_[A-Z_]+/, error.message)
      assert_includes(error.message, 'line:')
      assert_includes(error.message, 'offset:')
    end

    private

    def transliterator_for(*)
      Transliteration::Transliterator.new(*)
    end
  end
end
