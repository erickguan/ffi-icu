module ICU
  module Transliteration

    def self.translit(translit_id, str)
      t = Transliterator.new translit_id
      res = t.transliterate str
      t.close

      res
    end

    def self.available_ids
      enum_ptr = Lib.check_error do |error|
        Lib.utrans_openIDs(error)
      end

      result = Lib.enum_ptr_to_array(enum_ptr)
      Lib.uenum_close(enum_ptr)

      result
    end

    class Transliterator

      def initialize(id, direction = :forward)
        @parse_error = Lib::UParseError.new
        Lib.check_error do |status|
          # couldn't get utrans_openU to work properly, so using deprecated utrans_open for now
          @tr = Lib.utrans_open(id, direction, nil, 0, @parse_error, status)
        end
      end

      def transliterate(from)
        unicode_size = from.unpack("U*").size
        capacity = from.bytesize + 1
        buf = UCharPointer.from_string(from)

        limit = FFI::MemoryPointer.new :int32
        text_length = FFI::MemoryPointer.new :int32


        [limit, text_length].each do |ptr|
          ptr.put_int32(0, unicode_size)
        end

        retried = false

        begin
          Lib.check_error do |error|
            Lib.utrans_transUChars(@tr, buf, text_length, capacity, 0, limit, error)
          end
        rescue BufferOverflowError
          new_size = text_length.get_int32(0)
          raise BufferOverflowError, "needed: #{new_size}" if retried

          buf = buf.resized_to(new_size)
          limit.put_int32(0, new_size)
          capacity = new_size

          # reset to original size
          text_length.put_int32 0, unicode_size

          retried = true
          retry
        end

        buf.string text_length.get_int32(0)
      end

      def close
        Lib.utrans_close @tr
      end
    end # Transliterator

  end # Translit
end # ICU

