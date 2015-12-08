# encoding: UTF-8

require 'spec_helper'

module ICU
  describe UChar32Pointer do
    it 'allocates enough memory for 32-bit characters' do
      UChar32Pointer.new(5).size.should == 20
    end

    it 'builds a buffer from a string' do
      ptr = UChar32Pointer.from_string('𝔭𝒶ỿ𝕡𝕒ℓ')
      ptr.should be_a UChar32Pointer
      ptr.size.should == 24
      ptr.read_array_of_uint32(6).should == [0x1D52D, 0x1D4B6, 0x1EFF, 0x1D561, 0x1D552, 0x2113]
    end

    it 'takes an optional capacity' do
      ptr = UChar32Pointer.from_string('𝔭𝒶ỿ𝕡𝕒ℓ', 10)
      ptr.size.should == 40
    end

    describe 'converting to string' do
      let(:ptr) { UChar32Pointer.new(3).write_array_of_uint32 [0x1D52D, 0x0, 0x2113] }

      it 'returns the the entire buffer by default' do
        ptr.string.should == "𝔭\0ℓ"
      end

      it 'returns strings of the specified length' do
        ptr.string(0).should == ""
        ptr.string(2).should == "𝔭\0"
      end
    end
  end
end
