require 'test_helper'

module ICU
  # http://bugs.icu-project.org/trac/browser/icu/trunk/source/test/cintltst/cnormtst.c
  class NormalizationTest < Minitest::Test
    def test_normalizes_a_string_decomposed
      assert_equal [65, 778], Normalization.normalize('Å', :nfd).unpack('U*')
    end

    def test_normalizes_a_string_composed
      assert_equal [197], Normalization.normalize('Å', :nfc).unpack('U*')
    end

    def test_handles_supplementary_characters
      assert_equal '😀', Normalization.normalize('😀', :nfc)
    end

    def test_handles_empty_input
      assert_equal '', Normalization.normalize('', :nfc)
    end

    def test_returns_the_expanded_decomposed_output_without_a_trailing_nul
      result = Normalization.normalize('Å', :nfd)

      assert_equal "A\u030A", result
      refute_includes result, "\0"
    end

    def test_composes_combining_marks
      assert_equal 'Å', Normalization.normalize("A\u030A", :nfc)
    end

    # TODO: add more normalization tests
  end
end
