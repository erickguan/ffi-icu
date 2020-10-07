# encoding: UTF-8

module ICU
  describe UCharPointer do
    it 'allocates enough memory for 16-bit characters' do
      expect(UCharPointer.new(5).size).to eq(10)
    end

    it 'builds a buffer from a string' do
      ptr = UCharPointer.from_string('abc')
      expect(ptr).to be_a UCharPointer
      expect(ptr.size).to eq(6)
      expect(ptr.read_array_of_uint16(3)).to eq([0x61, 0x62, 0x63])
    end

    it 'takes an optional capacity' do
      ptr = UCharPointer.from_string('abc', 5)
      expect(ptr.size).to eq(10)
    end

    describe 'converting to string' do
      let(:ptr) { UCharPointer.new(3).write_array_of_uint16 [0x78, 0x0, 0x79] }

      it 'returns the the entire buffer by default' do
        expect(ptr.string).to eq("x\0y")
      end

      it 'returns strings of the specified length' do
        expect(ptr.string(0)).to eq("")
        expect(ptr.string(2)).to eq("x\0")
      end
    end
  end
end
