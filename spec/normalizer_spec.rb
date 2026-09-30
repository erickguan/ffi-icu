module ICU
  describe Normalizer do
    describe 'NFD: nfc decompose' do
      let(:normalizer) { described_class.new(nil, 'nfc', :decompose) }

      it 'normalizes a string' do
        expect(normalizer.normalize('Å').unpack('U*')).to(eq([65, 778]))
        expect(normalizer.normalize('ô').unpack('U*')).to(eq([111, 770]))
        expect(normalizer.normalize('a').unpack('U*')).to(eq([97]))
        expect(normalizer.normalize('中文').unpack('U*')).to(eq([20_013, 25_991]))
        expect(normalizer.normalize('Äffin').unpack('U*')).to(eq([65, 776, 102, 102, 105, 110]))
        expect(normalizer.normalize('Äﬃn').unpack('U*')).to(eq([65, 776, 64_259, 110]))
        expect(normalizer.normalize('Henry IV').unpack('U*')).to(eq([72, 101, 110, 114, 121, 32, 73, 86]))
        expect(normalizer.normalize('Henry Ⅳ').unpack('U*')).to(eq([72, 101, 110, 114, 121, 32, 8547]))
      end

      it 'handles supplementary characters, empty input, and expanded output' do
        expect(normalizer.normalize('😀')).to(eq('😀'))
        expect(normalizer.normalize('')).to(eq(''))
        expect(normalizer.normalize('Å')).to(eq("A\u030A"))
        expect(normalizer.normalize('Å')).not_to(include("\0"))
      end
    end

    describe 'NFC: nfc compose' do
      let(:normalizer) { described_class.new(nil, 'nfc', :compose) }

      it 'normalizes a string' do
        expect(normalizer.normalize('Å').unpack('U*')).to(eq([197]))
        expect(normalizer.normalize('ô').unpack('U*')).to(eq([244]))
        expect(normalizer.normalize('a').unpack('U*')).to(eq([97]))
        expect(normalizer.normalize('中文').unpack('U*')).to(eq([20_013, 25_991]))
        expect(normalizer.normalize('Äffin').unpack('U*')).to(eq([196, 102, 102, 105, 110]))
        expect(normalizer.normalize('Äﬃn').unpack('U*')).to(eq([196, 64_259, 110]))
        expect(normalizer.normalize('Henry IV').unpack('U*')).to(eq([72, 101, 110, 114, 121, 32, 73, 86]))
        expect(normalizer.normalize('Henry Ⅳ').unpack('U*')).to(eq([72, 101, 110, 114, 121, 32, 8547]))
      end

      it 'composes combining marks without a trailing NUL' do
        result = normalizer.normalize("A\u030A")

        expect(result).to(eq('Å'))
        expect(result).not_to(include("\0"))
      end

      it 'checks normalization predicates for supplementary characters' do
        expect(normalizer.normalized?('😀')).to(be(true))
        expect(normalizer.is_normalized?('😀')).to(be(true))
        expect(normalizer.normailzed?('😀')).to(be(true))
      end
    end

    describe 'NFKD: nfkc decompose' do
      let(:normalizer) { described_class.new(nil, 'nfkc', :decompose) }

      it 'normalizes a string' do
        expect(normalizer.normalize('Äffin').unpack('U*')).to(eq([65, 776, 102, 102, 105, 110]))
        expect(normalizer.normalize('Äﬃn').unpack('U*')).to(eq([65, 776, 102, 102, 105, 110]))
        expect(normalizer.normalize('Henry IV').unpack('U*')).to(eq([72, 101, 110, 114, 121, 32, 73, 86]))
        expect(normalizer.normalize('Henry Ⅳ').unpack('U*')).to(eq([72, 101, 110, 114, 121, 32, 73, 86]))
      end
    end

    describe 'NFKC: nfkc compose' do
      let(:normalizer) { described_class.new(nil, 'nfkc', :compose) }

      it 'normalizes a string' do
        expect(normalizer.normalize('Äffin').unpack('U*')).to(eq([196, 102, 102, 105, 110]))
        expect(normalizer.normalize('Äﬃn').unpack('U*')).to(eq([196, 102, 102, 105, 110]))
        expect(normalizer.normalize('Henry IV').unpack('U*')).to(eq([72, 101, 110, 114, 121, 32, 73, 86]))
        expect(normalizer.normalize('Henry Ⅳ').unpack('U*')).to(eq([72, 101, 110, 114, 121, 32, 73, 86]))
      end
    end
  end
end
