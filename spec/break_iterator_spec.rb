# encoding: utf-8

module ICU
  describe BreakIterator do

    it "should return available locales" do
      locales = ICU::BreakIterator.available_locales
      expect(locales).to be_an(Array)
      expect(locales).to_not be_empty
      expect(locales).to include("en_US")
    end

    it "finds all word boundaries in an English string" do
      iterator = BreakIterator.new :word, "en_US"
      iterator.text = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
      expect(iterator.to_a).to eq(
        [0, 5, 6, 11, 12, 17, 18, 21, 22, 26, 27, 28, 39, 40, 51, 52, 56, 57, 58, 61, 62, 64, 65, 72, 73, 79, 80, 90, 91, 93, 94, 100, 101, 103, 104, 110, 111, 116, 117, 123, 124]
      )
    end

    it "returns each substring" do
      iterator = BreakIterator.new :word, "en_US"
      iterator.text = "Lorem ipsum dolor sit amet."

      expect(iterator.substrings).to eq(["Lorem", " ", "ipsum", " ", "dolor", " ", "sit", " ", "amet", "."])
    end

    it "returns the substrings of a non-ASCII string" do
      iterator = BreakIterator.new :word, "th_TH"
      iterator.text = "รู้อะไรไม่สู้รู้วิชา รู้รักษาตัวรอดเป็นยอดดี"

      expect(iterator.substrings).to eq(
        ["รู้", "อะไร", "ไม่สู้", "รู้", "วิชา", " ", "รู้", "รักษา", "ตัว", "รอด", "เป็น", "ยอดดี"]
      )
    end

    it "finds all word boundaries in a non-ASCII string" do
      iterator = BreakIterator.new :word, "th_TH"
      iterator.text = "การทดลอง"
      expect(iterator.to_a).to eq([0, 3, 8])
    end

    it "finds all sentence boundaries in an English string" do
      iterator = BreakIterator.new :sentence, "en_US"
      iterator.text = "This is a sentence. This is another sentence, with a comma in it."
      expect(iterator.to_a).to eq([0, 20, 65])
    end

    it "can navigate back and forward" do
      iterator = BreakIterator.new :word, "en_US"
      iterator.text = "Lorem ipsum dolor sit amet."

      expect(iterator.first).to eq(0)
      iterator.next
      expect(iterator.current).to eq(5)
      expect(iterator.last).to eq(27)
    end

    it "fetches info about given offset" do
      iterator = BreakIterator.new :word, "en_US"
      iterator.text = "Lorem ipsum dolor sit amet."

      expect(iterator.following(3)).to eq(5)
      expect(iterator.preceding(6)).to eq(5)

      expect(iterator).to be_boundary(5)
      expect(iterator).to_not be_boundary(10)
    end

    it "returns an Enumerator if no block was given" do
      iterator = BreakIterator.new :word, "nb"

      expect(iterator.each).to be_kind_of(Enumerator)
    end

  end # BreakIterator
end # ICU
