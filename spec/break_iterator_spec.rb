module ICU
  describe BreakIterator do
    it 'returns available locales' do
      locales = described_class.available_locales
      expect(locales).to(be_an(Array))
      expect(locales).not_to(be_empty)
      expect(locales).to(include('en_US'))
    end

    it 'finds all word boundaries in an English string' do
      iterator = described_class.new(:word, 'en_US')
      iterator.text = 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, ' \
                      'sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'
      expect(iterator.to_a).to(eq(
                                 [0, 5, 6, 11, 12, 17, 18, 21, 22, 26, 27, 28, 39, 40, 51, 52,
                                  56, 57, 58, 61, 62, 64, 65, 72, 73, 79, 80, 90, 91, 93, 94, 100,
                                  101, 103, 104, 110, 111, 116, 117, 123, 124]
                               ))
    end

    it 'returns each substring' do
      iterator = described_class.new(:word, 'en_US')
      iterator.text = 'Lorem ipsum dolor sit amet.'

      expect(iterator.substrings).to(eq(['Lorem', ' ', 'ipsum', ' ', 'dolor', ' ', 'sit', ' ', 'amet', '.']))
    end

    it 'returns the substrings of a non-ASCII string' do
      iterator = described_class.new(:word, 'th_TH')
      iterator.text = 'รู้อะไรไม่สู้รู้วิชา รู้รักษาตัวรอดเป็นยอดดี'
      expect(iterator.substrings).to(eq(
                                       ['รู้', 'อะไร', 'ไม่สู้', 'รู้', 'วิชา', ' ', 'รู้', 'รักษา', 'ตัว', 'รอด',
                                        'เป็น', 'ยอดดี']
                                     ))
    end

    it 'returns correct substrings when the text contains an emoji' do
      iterator = described_class.new(:word, 'en_US')
      iterator.text = 'a😀b c'
      GC.start
      Array.new(1000) { 'temporary allocation' }

      expect(iterator.to_a).to(eq([0, 1, 3, 4, 5, 6]))
      expect(iterator.substrings).to(eq(['a', '😀', 'b', ' ', 'c']))
      expect(iterator.following(1)).to(eq(3))
      expect(iterator.preceding(3)).to(eq(1))
      expect(iterator).to(be_boundary(3))
      expect(iterator).not_to(be_boundary(2))
    end

    it 'preserves substrings and their encoding for GB18030 input' do
      iterator = described_class.new(:character, 'en')
      text = "a\u0080😀b".encode(Encoding::GB18030)
      iterator.text = text

      expect(iterator.to_a).to(eq([0, 1, 2, 4, 5]))
      expect(iterator.substrings).to(eq(text.each_char.to_a))
      expect(iterator.substrings.map(&:encoding)).to(all(eq(Encoding::GB18030)))
    end

    it 'finds all word boundaries in a non-ASCII string' do
      iterator = described_class.new(:word, 'th_TH')
      iterator.text = 'การทดลอง'
      expect(iterator.to_a).to(eq([0, 3, 8]))
    end

    it 'finds all sentence boundaries in an English string' do
      iterator = described_class.new(:sentence, 'en_US')
      iterator.text = 'This is a sentence. This is another sentence, with a comma in it.'
      expect(iterator.to_a).to(eq([0, 20, 65]))
    end

    it 'can navigate back and forward' do
      iterator = described_class.new(:word, 'en_US')
      iterator.text = 'Lorem ipsum dolor sit amet.'

      expect(iterator.first).to(eq(0))
      iterator.next
      expect(iterator.current).to(eq(5))
      expect(iterator.previous).to(eq(0))
      expect(iterator.last).to(eq(27))
    end

    it 'fetches info about given offset' do
      iterator = described_class.new(:word, 'en_US')
      iterator.text = 'Lorem ipsum dolor sit amet.'

      expect(iterator.following(3)).to(eq(5))
      expect(iterator.preceding(6)).to(eq(5))

      expect(iterator).to(be_boundary(5))
      expect(iterator).not_to(be_boundary(10))
    end

    it 'returns an Enumerator if no block was given' do
      iterator = described_class.new(:word, 'nb')

      expect(iterator.each).to(be_a(Enumerator))
    end
  end
end
