module ICU
  class UChar32Pointer < FFI::MemoryPointer
    UChar32_TYPE = :uint32
    TYPE_SIZE    = FFI.type_size(UChar32_TYPE)

    def self.from_string(str, capacity = nil)
      chars = str.unpack("U*")

      if capacity
        if capacity < chars.size
          raise ArgumentError, "capacity is too small for string of #{chars.size} UChar32"
        end

        ptr = new capacity
      else
        ptr = new chars.size
      end

      ptr.write_array_of_uint32 chars

      ptr
    end

    def initialize(size)
      super UChar32_TYPE, size
    end

    def resized_to(new_size)
      raise "new_size must be larger than current size" if new_size < size

      resized = self.class.new new_size
      resized.put_bytes(0, get_bytes(0, size))

      resized
    end

    def string(length = nil)
      length ||= size / TYPE_SIZE

      wstring = read_array_of_uint32(length)
      wstring.pack("U*")
    end


  end # UChar32Pointer
end # ICU
