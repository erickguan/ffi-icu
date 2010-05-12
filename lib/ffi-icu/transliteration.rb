module ICU
  module Translit

    def self.transliterate(translit_id, str)
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
          @tr = Lib.utrans_open(id, direction, nil, 0,
                                      nil, status)
        end
      end

      def transliterate(string)
        capacity = string.length + 1

        text_length = FFI::MemoryPointer.new :int32
        text_length.put_int32(0, string.length)

        limit = FFI::MemoryPointer.new :int32

        uchar_ptr = UCharPointer.from_string(string)
        # pos = Lib::UTransPosition.new
        # pos[:context_start] = pos[:start] = 0
        # pos[:context_limit] = pos[:end]   = length

        Lib.check_error do |error|
          Lib.utrans_transUChars(@tr, uchar_ptr, text_length, capacity, 0, limit, error)
        end

        # TODO: clean up UCharPointer
        uchar_ptr.string
      end

      def close

      end
    end # Transliterator

  end # Translit
end # ICU

