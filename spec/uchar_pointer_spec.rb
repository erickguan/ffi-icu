# encoding: UTF-8

require 'spec_helper'

module ICU
  describe UCharPointer do
    it 'allocates enough memory for 16-bit characters' do
      UCharPointer.new(5).size.should == 10
    end

    it 'builds a buffer from a string' do
      ptr = UCharPointer.from_string('abc')
      ptr.should be_a UCharPointer
      ptr.size.should == 6
      ptr.read_array_of_uint16(3).should == [0x61, 0x62, 0x63]
    end

    it 'takes an optional capacity' do
      ptr = UCharPointer.from_string('abc', 5)
      ptr.size.should == 10
    end

    describe 'converting to string' do
      it 'returns the the entire buffer by default' do
        UCharPointer.from_string("x举𝔭𝒶ỿ𝕡𝕒ℓ").string.should == "x举𝔭𝒶ỿ𝕡𝕒ℓ"
      end
    end
  end
end
