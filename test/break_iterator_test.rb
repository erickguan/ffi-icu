require 'test_helper'

module ICU
  class BreakIteratorTest < ActiveSupport::TestCase
    test 'returns available locales' do
      locales = ICU::BreakIterator.available_locales
      assert locales.is_a?(Array), "Expected locales to be an Array"
      assert !locales.empty?, "Expected locales not to be empty"
      assert locales.include?("en_US"), "Expected locales to include 'en_US'"
    end

    test 'finds all word boundaries in an English string' do
      iterator = ICU::BreakIterator.new(:word, "en_US")
      iterator.text = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, " \
                      "sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
      expected_indices = [0, 5, 6, 11, 12, 17, 18, 21, 22, 26, 27, 28, 39, 40, 51, 52, 56, 57, 58, 61, 62, 64, 65, 72,
                          73, 79, 80, 90, 91, 93, 94, 100, 101, 103, 104, 110, 111, 116, 117, 123, 124]
      assert_equal expected_indices, iterator.to_a, "Word boundaries did not match expected indices"
    end

    test 'returns each substring' do
      iterator = ICU::BreakIterator.new(:word, "en_US")
      iterator.text = "Lorem ipsum dolor sit amet."
      expected_substrings = ["Lorem", " ", "ipsum", " ", "dolor", " ", "sit", " ", "amet", "."]
      assert_equal expected_substrings, iterator.substrings, "Substrings did not match expected"
    end

    test 'returns the substrings of a non-ASCII string' do
      iterator = ICU::BreakIterator.new(:word, "th_TH")
      iterator.text = "รู้อะไรไม่สู้รู้วิชา รู้รักษาตัวรอดเป็นยอดดี"
      expected_substrings = ["รู้", "อะไร", "ไม่สู้", "รู้", "วิชา", " ", "รู้", "รักษา", "ตัว", "รอด", "เป็น", "ยอดดี"]
      assert_equal expected_substrings, iterator.substrings, "Non-ASCII substrings did not match expected"
    end

    test 'finds all word boundaries in a non-ASCII string' do
      iterator = ICU::BreakIterator.new(:word, "th_TH")
      iterator.text = "การทดลอง"
      expected_indices = [0, 3, 8]
      assert_equal expected_indices, iterator.to_a, "Non-ASCII word boundaries did not match expected"
    end

    test 'finds all sentence boundaries in an English string' do
      iterator = ICU::BreakIterator.new(:sentence, "en_US")
      iterator.text = "This is a sentence. This is another sentence, with a comma in it."
      expected_indices = [0, 20, 65]
      assert_equal expected_indices, iterator.to_a, "Sentence boundaries did not match expected"
    end

    test 'can navigate back and forward' do
      iterator = ICU::BreakIterator.new(:word, "en_US")
      iterator.text = "Lorem ipsum dolor sit amet."
      assert_equal 0, iterator.first, "First boundary was not 0"
      iterator.next
      assert_equal 5, iterator.current, "Next boundary was not 5"
      assert_equal 27, iterator.last, "Last boundary was not 27"
    end

    test 'fetches info about given offset' do
      iterator = ICU::BreakIterator.new(:word, "en_US")
      iterator.text = "Lorem ipsum dolor sit amet."
      assert_equal 5, iterator.following(3), "Following boundary did not match expected"
      assert_equal 5, iterator.preceding(6), "Preceding boundary did not match expected"
      assert iterator.boundary?(5), "Expected to be a boundary"
      assert !iterator.boundary
    end

    test 'returns an Enumerator if no block was given' do
      iterator = ICU::BreakIterator.new(:word, "nb")
      assert_kind_of Enumerator, iterator.each, "Expected to return an Enumerator"
    end
  end
end
