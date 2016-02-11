module ICU
  # http://userguide.icu-project.org/strings
  class UCharPointer < FFI::MemoryPointer

    UCHAR_TYPE = :uint16 # not sure how platform-dependent this is..
    TYPE_SIZE  = FFI.type_size(UCHAR_TYPE)

    def self.from_string(str, capacity = nil)
      str = str.encode('UTF-8') if str.respond_to? :encode

      # We uses the byte sequences as it's internal string representation
      ruby_string_ptr = FFI::MemoryPointer.from_string str
      ruby_string_bytes = ruby_string_ptr.size - 1 # Don't including the terminated NULL

      if capacity
        if capacity < ruby_string_bytes
          raise ArgumentError, "capacity is too small for string of #{ruby_string_bytes} UChars"
        end
      else
        capacity = ruby_string_bytes
      end

      uchar_ptr = new capacity
      uchar_length = FFI::MemoryPointer.new(:int32_t)

      Lib.check_error do |error|
        Lib.u_strFromUTF8Lenient(uchar_ptr, capacity, uchar_length, str, ruby_string_bytes, error)
      end

      uchar_ptr#.resized_to(uchar_length.read_int32 + 1, true)
    end

    def initialize(size)
      super UCHAR_TYPE, size
    end

    def resized_to(new_size, force = false)
      raise "new_size must be larger than current size" if new_size < size && !force

      resized = self.class.new new_size
      resized.put_bytes(0, get_bytes(0, force ? new_size : size))

      resized
    end

    def string(length = nil)
      # str_ptr = FFI::MemoryPointer.new(:uint16, length || self.size)
      #
      # needed_length = FFI::MemoryPointer.new(:int32_t)
      #
      # retried = false
      # begin
      #   Lib.check_error do |error|
      #     Lib.u_strToUTF8(str_ptr, str_ptr.size, needed_length, self, self.size, error)
      #   end
      # rescue BufferOverflowError
      #   raise BufferOverflowError, "needed: #{needed_length.read_int32}" if retried
      #
      #   str_ptr  = FFI::MemoryPointer.new(:uint16, needed_length.read_int32 + 1)
      #   needed_length = FFI::MemoryPointer.new(:int32_t)
      #
      #   retried = true
      #   retry
      # end
      # p "string #{self.read_pointer} #{str_ptr} #{self.size}, #{needed_length.read_int32}"
      #
      # str_ptr.read_array_of_uint16(needed_length.read_int32).pack("U*")
      length ||= size / TYPE_SIZE

      wstring = read_array_of_uint16(length)
      wstring.pack("U*")
    end


  end # UCharPointer
end # ICU
