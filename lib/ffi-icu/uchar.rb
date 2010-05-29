module ICU
  class UCharPointer < FFI::MemoryPointer

    UCHAR_TYPE = :uint16 # not sure how platform-dependent this is..
    TYPE_SIZE  = FFI.type_size(UCHAR_TYPE)

    def self.from_string(str)
      str   = str.encode("UTF-8") if str.respond_to? :encode
      bytes = str.unpack("U*")

      ptr = new UCHAR_TYPE, bytes.size
      ptr.put_array_of_uint16 0, bytes

      ptr
    end

    def resized_to(new_size)
      raise "new_size must be larger than current size" if new_size < size
      resized = self.class.new UCHAR_TYPE, new_size
      resized.put_bytes(0, get_bytes(0, size))

      resized
    end

    def string(length = nil)
      length ||= size / TYPE_SIZE

      wstring = get_array_of_uint16(0, length)
      wstring.pack("U*")
    end


  end # UCharPointer
end # ICU
