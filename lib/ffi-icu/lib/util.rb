module ICU
  module Lib
    module Util
      def self.read_null_terminated_array_of_strings(pointer)
        offset = 0
        result = []

        until (ptr = pointer.get_pointer(offset)).null?
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

      def self.read_uchar_buffer(length, &blk)
        buf, len = read_uchar_buffer_as_ptr_impl(length, &blk)
        buf.string(len)
      end

      def self.read_uchar_buffer_as_ptr(length, &blk)
        buf, _ = read_uchar_buffer_as_ptr_impl(length, &blk)
        buf
      end

      private

      def self.read_uchar_buffer_as_ptr_impl(length)
        attempts = 0

        begin
          result = UCharPointer.new(length)
          Lib.check_error { |status| length = yield result, status }
        rescue BufferOverflowError
          attempts += 1
          retry if attempts < 2
          raise BufferOverflowError, "needed: #{length}"
        end

        [result, length]
      end
    end
  end
end
