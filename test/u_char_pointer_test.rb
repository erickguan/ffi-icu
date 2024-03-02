require 'test_helper'

module ICU
  class UCharPointerTest < ActiveSupport::TestCase
    test "allocates enough memory for 16-bit characters" do
      assert_equal 10, UCharPointer.new(5).size
    end

    test "builds a buffer from a string" do
      ptr = UCharPointer.from_string('abc')
      assert_kind_of UCharPointer, ptr
      assert_equal 6, ptr.size
      assert_equal [0x61, 0x62, 0x63], ptr.read_array_of_uint16(3)
    end

    test "takes an optional capacity" do
      ptr = UCharPointer.from_string('abc', 5)
      assert_equal 10, ptr.size
    end

    test "returns the entire buffer by default when converting to string" do
      ptr = UCharPointer.new(3).write_array_of_uint16([0x78, 0x0, 0x79])
      assert_equal "x\0y", ptr.string
    end

    test "returns strings of the specified length when converting to string" do
      ptr = UCharPointer.new(3).write_array_of_uint16([0x78, 0x0, 0x79])
      assert_equal "", ptr.string(0)
      assert_equal "x\0", ptr.string(2)
    end
  end
end
