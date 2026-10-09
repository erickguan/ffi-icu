module ICU
  describe UCharPointer do
    it 'allocates enough memory for 16-bit characters' do
      expect(described_class.new(5).size).to(eq(10))
    end

    it 'builds a buffer from a string' do
      ptr = described_class.from_utf8('abc')
      expect(ptr).to(be_a(described_class))
      expect(ptr.size).to(eq(6))
      expect(ptr.read_array_of_uint16(3)).to(eq([0x61, 0x62, 0x63]))
    end

    it 'transcodes strings with a non-UTF-8 encoding' do
      value = 'café'.encode(Encoding::ISO_8859_1)
      ptr = described_class.from_utf8(value)

      expect(ptr.utf8_string).to(eq('café'))
    end

    it 'encodes non-BMP characters as UTF-16 code units' do
      ptr = described_class.from_utf8('😀')

      expect(ptr.read_array_of_uint16(2)).to(eq([0xD83D, 0xDE00]))
      expect(ptr.utf8_string).to(eq('😀'))
    end

    it 'takes an optional capacity' do
      ptr = described_class.from_utf8('abc', 5)
      expect(ptr.size).to(eq(10))
    end

    it 'preserves contents when growing a buffer' do
      ptr = described_class.from_utf8('abc')

      resized = ptr.resized_to(6)

      expect(resized.size).to(eq(12))
      expect(resized.utf8_string(3)).to(eq('abc'))
    end

    describe 'converting to string' do
      let(:ptr) { described_class.new(3).write_array_of_uint16([0x78, 0x0, 0x79]) }

      it 'returns the the entire buffer by default' do
        expect(ptr.utf8_string).to(eq("x\0y"))
      end

      it 'returns strings of the specified length' do
        expect(ptr.utf8_string(0)).to(eq(''))
        expect(ptr.utf8_string(2)).to(eq("x\0"))
      end

      it 'round-trips supplementary characters' do
        value = '😀🚀'

        expect(described_class.from_utf8(value).utf8_string).to(eq(value))
      end

      it 'round-trips an empty string' do
        expect(described_class.from_utf8('').utf8_string).to(eq(''))
      end
    end
  end
end
