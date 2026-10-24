require 'test_helper'

module ICU
  class CollationTest < Minitest::Test
    def test_collates_an_array_of_strings
      assert_equal ['æ', 'ø', 'å'], Collation.collate('nb', ['æ', 'å', 'ø'])
    end

    def test_returns_available_locales
      locales = Collation.available_locales

      assert_kind_of Array, locales
      refute_empty locales
      assert_includes locales, 'nb'
    end
  end
end
