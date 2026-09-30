# frozen_string_literal: true

module ICU
  class UCharPointer < FFI::MemoryPointer
    UCHAR_TYPE = :uint16 # not sure how platform-dependent this is..
    TYPE_SIZE  = FFI.type_size(UCHAR_TYPE)

    def self.from_string(str, capacity = nil)
      str   = str.encode('UTF-8') if str.respond_to?(:encode)
      chars = str.unpack('U*')
      chars = str.encode('UTF-16LE').unpack('v*') if chars.any? { |char| char > 0xFFFF }

      if capacity
        raise(ArgumentError, "capacity is too small for string of #{chars.size} UChars") if capacity < chars.size

        ptr = new(capacity)
      else
        ptr = new(chars.size)
      end

      ptr.write_array_of_uint16(chars)

      ptr
    end

    def self.from_utf8(str, capacity = nil)
      chars = str.encode(Encoding::UTF_16LE).unpack('v*')

      if capacity
        raise(ArgumentError, "capacity is too small for string of #{chars.size} UChars") if capacity < chars.size

        ptr = new(capacity)
      else
        ptr = new(chars.size)
      end

      ptr.write_array_of_uint16(chars)

      ptr
    end

    def initialize(size)
      super(UCHAR_TYPE, size)
    end

    def resized_to(new_size)
      raise('new_size must be larger than current size') if new_size < length_in_uchars

      resized = self.class.new(new_size)
      resized.put_bytes(0, get_bytes(0, size))

      resized
    end

    def string(length = nil)
      length ||= size / TYPE_SIZE

      chars = read_array_of_uint16(length)
      if chars.any? { |char| char.between?(0xD800, 0xDFFF) }
        chars.pack('v*').force_encoding('UTF-16LE').encode('UTF-8')
      else
        chars.pack('U*')
      end
    end

    def utf8_string(length = nil)
      length ||= size / TYPE_SIZE

      wstring = read_array_of_uint16(length).pack('v*')
      wstring.force_encoding(Encoding::UTF_16LE).encode(Encoding::UTF_8)
    end

    def length_in_uchars
      size / type_size
    end
  end
end
