require 'test_helper'

module ICU
  class TransliterationTest < Minitest::Test
    def test_provides_a_list_of_available_ids
      ids = Transliteration.available_ids

      assert_kind_of Array, ids
      refute_empty ids
    end

    def test_transliterates_custom_rules
      assert_equal 'aeiou', Transliteration.translit('NFD; [:Nonspacing Mark:] Remove; NFC', 'âêîôû')
    end
  end
end
