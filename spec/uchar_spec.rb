module ICU
  describe UCharPointer do
    it 'allocates enough memory for 16-bit characters' do
      expect(described_class.new(5).size).to(eq(10))
    end

    it 'builds a buffer from a string' do
      ptr = described_class.from_string('abc')
      expect(ptr).to(be_a(described_class))
      expect(ptr.size).to(eq(6))
      expect(ptr.read_array_of_uint16(3)).to(eq([0x61, 0x62, 0x63]))
    end

    it 'transcodes strings with a non-UTF-8 encoding' do
      value = 'café'.encode(Encoding::ISO_8859_1)
      ptr = described_class.from_string(value)

      expect(ptr.utf8_string).to(eq('café'))
    end

    it 'encodes non-BMP characters as UTF-16 code units' do
      ptr = described_class.from_utf8('😀')

      expect(ptr.read_array_of_uint16(2)).to(eq([0xD83D, 0xDE00]))
      expect(ptr.utf8_string).to(eq('😀'))
    end

    it 'stores UTF-16 code units for BMP and supplementary characters' do
      ptr = described_class.from_string('é東京😀🚀')

      expect(ptr.read_array_of_uint16(7)).to(eq([0x00e9, 0x6771, 0x4eac, 0xd83d, 0xde00, 0xd83d, 0xde80]))
    end

    it 'reports the UTF-16 code-unit length' do
      expect(described_class.from_string('abc').length_in_uchars).to(eq(3))
      expect(described_class.from_string('😀').length_in_uchars).to(eq(2))
      expect(described_class.from_string('a😀b').length_in_uchars).to(eq(4))
    end

    it 'takes an optional capacity' do
      ptr = described_class.from_string('abc', 5)
      expect(ptr.size).to(eq(10))
    end

    it 'resizes using UChar capacity' do
      ptr = described_class.from_string('abc')

      resized = ptr.resized_to(4)

      expect(resized.size).to(eq(8))
      expect(resized.string(3)).to(eq('abc'))
    end

    describe 'converting to string' do
      let(:ptr) { described_class.new(3).write_array_of_uint16([0x78, 0x0, 0x79]) }

      it 'returns the the entire buffer by default' do
        expect(ptr.string).to(eq("x\0y"))
      end

      it 'returns strings of the specified length' do
        expect(ptr.string(0)).to(eq(''))
        expect(ptr.string(2)).to(eq("x\0"))
      end

      it 'round-trips supplementary characters' do
        value = '😀🚀'

        expect(described_class.from_string(value).string).to(eq(value))
      end

      it 'round-trips an empty string' do
        expect(described_class.from_string('').string).to(eq(''))
      end
    end
  end
end
