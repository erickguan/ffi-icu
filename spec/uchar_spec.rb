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

    describe 'converting to string' do
      let(:ptr) { UCharPointer.new(3).write_array_of_uint16 [0x78, 0x0, 0x79] }

      it 'returns the the entire buffer by default' do
        ptr.string.should == "x\0y"
      end

      it 'returns strings of the specified length' do
        ptr.string(0).should == ""
        ptr.string(2).should == "x\0"
      end
    end
  end
end
