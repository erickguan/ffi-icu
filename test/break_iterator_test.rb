require 'test_helper'

module ICU
  class BreakIteratorTest < Minitest::Test
    def test_returns_available_locales
      locales = BreakIterator.available_locales

      assert_kind_of Array, locales
      refute_empty locales
      assert_includes locales, 'en_US'
    end

    def test_finds_all_word_boundaries_in_an_english_string
      iterator = BreakIterator.new(:word, 'en_US')
      iterator.text = 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, ' \
                      'sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'

      assert_equal [0, 5, 6, 11, 12, 17, 18, 21, 22, 26, 27, 28, 39, 40, 51, 52,
                    56, 57, 58, 61, 62, 64, 65, 72, 73, 79, 80, 90, 91, 93, 94, 100,
                    101, 103, 104, 110, 111, 116, 117, 123, 124], iterator.to_a
    end

    def test_returns_each_substring
      iterator = BreakIterator.new(:word, 'en_US')
      iterator.text = 'Lorem ipsum dolor sit amet.'

      assert_equal ['Lorem', ' ', 'ipsum', ' ', 'dolor', ' ', 'sit', ' ', 'amet', '.'], iterator.substrings
    end

    def test_returns_the_substrings_of_a_non_ascii_string
      iterator = BreakIterator.new(:word, 'th_TH')
      iterator.text = 'รู้อะไรไม่สู้รู้วิชา รู้รักษาตัวรอดเป็นยอดดี'

      assert_equal ['รู้', 'อะไร', 'ไม่สู้', 'รู้', 'วิชา', ' ', 'รู้', 'รักษา', 'ตัว', 'รอด', 'เป็น', 'ยอดดี'],
                   iterator.substrings
    end

    def test_returns_correct_substrings_when_the_text_contains_an_emoji
      iterator = BreakIterator.new(:word, 'en_US')
      iterator.text = 'a😀b c'
      GC.start
      Array.new(1000) { 'temporary allocation' }

      assert_equal [0, 1, 3, 4, 5, 6], iterator.to_a
      assert_equal ['a', '😀', 'b', ' ', 'c'], iterator.substrings
      assert_equal 3, iterator.following(1)
      assert_equal 1, iterator.preceding(3)
      assert iterator.boundary?(3)
      refute iterator.boundary?(2)
    end

    def test_preserves_substrings_and_their_encoding_for_gb18030_input
      iterator = BreakIterator.new(:character, 'en')
      text = "a\u0080😀b".encode(Encoding::GB18030)
      iterator.text = text

      assert_equal [0, 1, 2, 4, 5], iterator.to_a
      assert_equal text.each_char.to_a, iterator.substrings
      assert(iterator.substrings.all? { |substring| substring.encoding == Encoding::GB18030 })
    end

    def test_finds_all_word_boundaries_in_a_non_ascii_string
      iterator = BreakIterator.new(:word, 'th_TH')
      iterator.text = 'การทดลอง'

      assert_equal [0, 3, 8], iterator.to_a
    end

    def test_finds_all_sentence_boundaries_in_an_english_string
      iterator = BreakIterator.new(:sentence, 'en_US')
      iterator.text = 'This is a sentence. This is another sentence, with a comma in it.'

      assert_equal [0, 20, 65], iterator.to_a
    end

    def test_can_navigate_back_and_forward
      iterator = BreakIterator.new(:word, 'en_US')
      iterator.text = 'Lorem ipsum dolor sit amet.'

      assert_equal 0, iterator.first
      iterator.next

      assert_equal 5, iterator.current
      assert_equal 0, iterator.previous
      assert_equal 27, iterator.last
    end

    def test_fetches_info_about_given_offset
      iterator = BreakIterator.new(:word, 'en_US')
      iterator.text = 'Lorem ipsum dolor sit amet.'

      assert_equal 5, iterator.following(3)
      assert_equal 5, iterator.preceding(6)
      assert iterator.boundary?(5)
      refute iterator.boundary?(10)
    end

    def test_returns_an_enumerator_if_no_block_was_given
      iterator = BreakIterator.new(:word, 'nb')

      assert_kind_of Enumerator, iterator.each
    end
  end
end
