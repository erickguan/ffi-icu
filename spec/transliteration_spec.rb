module ICU
  describe Transliteration::Transliterator do
    def transliterator_for(*args)
      Transliteration::Transliterator.new(*args)
    end

    [
      ['Any-Hex', 'abcde', '\\u0061\\u0062\\u0063\\u0064\\u0065'],
      ['Lower', 'ABC', 'abc'],
      ['Han-Latin', '雙屬性集合之空間分群演算法-應用於地理資料',
       'shuāng shǔ xìng jí hé zhī kōng jiān fēn qún yǎn suàn fǎ-yīng yòng yú de lǐ zī liào'],
      ['Devanagari-Latin', 'दौलत', 'daulata']
    ].each do |id, input, output|
      it "transliterates #{id}" do
        tl = transliterator_for(id)
        expect(tl.transliterate(input)).to(eq(output))
      end
    end

    it 'handles supplementary characters' do
      expect(transliterator_for('Lower').transliterate('😀')).to(eq('😀'))
    end

    it 'applies custom rules containing supplementary characters' do
      transliterator = transliterator_for('Any-Latin', '😀 > X;')

      expect(transliterator.transliterate('😀')).to(eq('X'))
    end

    it 'reports malformed custom rules' do
      error = nil
      expect { transliterator_for('NFD', '[') }.
        to(raise_error(ICU::Error) { |raised_error| error = raised_error })
      expect(error.message).to(match(/\AU_[A-Z_]+/))
      expect(error.message).to(include('line:', 'offset:'))
    end
  end

  describe Transliteration do
    it 'provides a list of available ids' do
      ids = described_class.available_ids

      expect(ids).to(be_an(Array))
      expect(ids).not_to(be_empty)
    end

    it 'transliterates custom rules' do
      expect(described_class.translit('NFD; [:Nonspacing Mark:] Remove; NFC', 'âêîôû')).to(eq('aeiou'))
    end
  end
end
