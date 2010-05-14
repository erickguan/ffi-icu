module ICU
  class UCharPointer < FFI::MemoryPointer

    UCHAR_TYPE = :uint16 # not sure how platform-dependent this is..

    def self.from_string(str)
      str = str.encode("UTF-8") if str.respond_to? :encode
      bytes = str.unpack("U*")

      ptr = new UCHAR_TYPE, bytes.size
      ptr.put_array_of_uint16 0, bytes

      ptr
    end

    def string
      wstring = get_array_of_uint16(0, size / FFI.type_size(UCHAR_TYPE))
      wstring.pack("U*")
    end

  end # UCharPointer
end # ICU
