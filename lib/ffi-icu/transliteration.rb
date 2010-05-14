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
          @tr = Lib.utrans_open(id, direction, nil, -1, @parse_error, status)
        end
      end

      def transliterate(from)
        capacity = from.bytesize + 1
        limit    = FFI::MemoryPointer.new :int32_t

        text_length = FFI::MemoryPointer.new :int32_t
        text_length.put_int32(0, from.length)

        buf = UCharPointer.from_string(from)

        Lib.check_error do |error|
          Lib.utrans_transUChars(@tr, buf, text_length, capacity, 0, limit, error)
        end

        # TODO: clean up UCharPointer
        buf.string
      end

      def close
        Lib.utrans_close @tr
      end
    end # Transliterator

  end # Translit
end # ICU

