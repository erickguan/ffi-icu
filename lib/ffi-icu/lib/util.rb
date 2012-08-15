module ICU
  module Lib
    module Util
      def self.read_null_terminated_array_of_strings(pointer)
        offset = 0
        result = []

        while (ptr = pointer.get_pointer(offset)) != FFI::Pointer::NULL do
          result << ptr.read_string
          offset += FFI::Pointer.size
        end

        result
      end

      def self.read_string_buffer(length)
        attempts = 0

        begin
          result = FFI::MemoryPointer.new(:char, length)
          Lib.check_error { |status| length = yield result, status }
        rescue BufferOverflowError
          attempts += 1
          retry if attempts < 2
          raise BufferOverflowError, "needed: #{length}"
        end

        result.read_string(length)
      end

      def self.read_uchar_buffer(length)
        attempts = 0

        begin
          result = UCharPointer.new(length)
          Lib.check_error { |status| length = yield result, status }
        rescue BufferOverflowError
          attempts += 1
          retry if attempts < 2
          raise BufferOverflowError, "needed: #{length}"
        end

        result.string(length)
      end
    end
  end
end
