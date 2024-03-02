require 'test_helper'

module ICU
  class TransliterationTest < ActiveSupport::TestCase
    test "provides a list of available ids" do
      ids = Transliteration.available_ids
      assert ids.is_a?(Array)
      assert !ids.empty?
    end

    test "transliterates custom rules" do
      result = Transliteration.translit("NFD; [:Nonspacing Mark:] Remove; NFC", "âêîôû")
      assert_equal "aeiou", result
    end
  end
end
