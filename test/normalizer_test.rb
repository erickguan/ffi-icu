require 'test_helper'

module ICU
  class NormalizerNfdTest < Minitest::Test
    def setup
      @normalizer = Normalizer.new(nil, 'nfc', :decompose)
    end

    def test_normalizes_a_string
      assert_equal [65, 778], @normalizer.normalize('Å').unpack('U*')
      assert_equal [111, 770], @normalizer.normalize('ô').unpack('U*')
      assert_equal [97], @normalizer.normalize('a').unpack('U*')
      assert_equal [20_013, 25_991], @normalizer.normalize('中文').unpack('U*')
      assert_equal [65, 776, 102, 102, 105, 110], @normalizer.normalize('Äffin').unpack('U*')
      assert_equal [65, 776, 64_259, 110], @normalizer.normalize('Äﬃn').unpack('U*')
      assert_equal [72, 101, 110, 114, 121, 32, 73, 86], @normalizer.normalize('Henry IV').unpack('U*')
      assert_equal [72, 101, 110, 114, 121, 32, 8547], @normalizer.normalize('Henry Ⅳ').unpack('U*')
    end

    def test_handles_supplementary_characters_empty_input_and_expanded_output
      assert_equal '😀', @normalizer.normalize('😀')
      assert_equal '', @normalizer.normalize('')
      assert_equal "A\u030A", @normalizer.normalize('Å')
      refute_includes @normalizer.normalize('Å'), "\0"
    end
  end

  class NormalizerNfcTest < Minitest::Test
    def setup
      @normalizer = Normalizer.new(nil, 'nfc', :compose)
    end

    def test_normalizes_a_string
      assert_equal [197], @normalizer.normalize('Å').unpack('U*')
      assert_equal [244], @normalizer.normalize('ô').unpack('U*')
      assert_equal [97], @normalizer.normalize('a').unpack('U*')
      assert_equal [20_013, 25_991], @normalizer.normalize('中文').unpack('U*')
      assert_equal [196, 102, 102, 105, 110], @normalizer.normalize('Äffin').unpack('U*')
      assert_equal [196, 64_259, 110], @normalizer.normalize('Äﬃn').unpack('U*')
      assert_equal [72, 101, 110, 114, 121, 32, 73, 86], @normalizer.normalize('Henry IV').unpack('U*')
      assert_equal [72, 101, 110, 114, 121, 32, 8547], @normalizer.normalize('Henry Ⅳ').unpack('U*')
    end

    def test_composes_combining_marks_without_a_trailing_nul
      result = @normalizer.normalize("A\u030A")

      assert_equal 'Å', result
      refute_includes result, "\0"
    end

    def test_checks_normalization_predicates_for_supplementary_characters
      assert_same true, @normalizer.normalized?('😀')
      assert_same true, @normalizer.is_normalized?('😀')
      assert_same true, @normalizer.normailzed?('😀')
    end
  end

  class NormalizerNfkdTest < Minitest::Test
    def setup
      @normalizer = Normalizer.new(nil, 'nfkc', :decompose)
    end

    def test_normalizes_a_string
      assert_equal [65, 776, 102, 102, 105, 110], @normalizer.normalize('Äffin').unpack('U*')
      assert_equal [65, 776, 102, 102, 105, 110], @normalizer.normalize('Äﬃn').unpack('U*')
      assert_equal [72, 101, 110, 114, 121, 32, 73, 86], @normalizer.normalize('Henry IV').unpack('U*')
      assert_equal [72, 101, 110, 114, 121, 32, 73, 86], @normalizer.normalize('Henry Ⅳ').unpack('U*')
    end
  end

  class NormalizerNfkcTest < Minitest::Test
    def setup
      @normalizer = Normalizer.new(nil, 'nfkc', :compose)
    end

    def test_normalizes_a_string
      assert_equal [196, 102, 102, 105, 110], @normalizer.normalize('Äffin').unpack('U*')
      assert_equal [196, 102, 102, 105, 110], @normalizer.normalize('Äﬃn').unpack('U*')
      assert_equal [72, 101, 110, 114, 121, 32, 73, 86], @normalizer.normalize('Henry IV').unpack('U*')
      assert_equal [72, 101, 110, 114, 121, 32, 73, 86], @normalizer.normalize('Henry Ⅳ').unpack('U*')
    end
  end
end
