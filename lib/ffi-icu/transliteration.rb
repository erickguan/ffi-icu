module ICU
  module Transliteration

    class << self
      def transliterate(translit_id, str, rules = nil)
        t = Transliterator.new translit_id, rules
        res = t.transliterate str
        t.close

        res
      end
      alias_method :translit, :transliterate

      def available_ids
        enum_ptr = Lib.check_error do |error|
          Lib.utrans_openIDs(error)
        end

        result = Lib.enum_ptr_to_array(enum_ptr)
        Lib.uenum_close(enum_ptr)

        result
      end
    end

    class Transliterator

      def initialize(id, rules = nil, direction = :forward)
        if rules
          rules_length = rules.length + 1
          rules = UCharPointer.from_string(rules)
        else
          rules_length = 0
        end

        parse_error = Lib::UParseError.new
        begin
          Lib.check_error do |status|
            # couldn't get utrans_openU to work properly, so using deprecated utrans_open for now
            @tr = Lib.utrans_open(id, direction, rules, rules_length, @parse_error, status)
          end
        rescue ICU::Error => ex
          raise ex, "#{ex.message} (#{parse_error})"
        end
      end

      def transliterate(from)
        # this is a bit unpleasant

        unicode_size = from.unpack("U*").size
        capacity     = from.bytesize + 1
        buf          = UCharPointer.from_string(from)
        limit        = FFI::MemoryPointer.new :int32
        text_length  = FFI::MemoryPointer.new :int32

        retried = false

        begin
          # resets to original size on retry
          [limit, text_length].each do |ptr|
            ptr.put_int32(0, unicode_size)
          end

          Lib.check_error do |error|
            Lib.utrans_transUChars(@tr, buf, text_length, capacity, 0, limit, error)
          end
        rescue BufferOverflowError
          new_size = text_length.get_int32(0)
          $stderr.puts "BufferOverflowError, needs: #{new_size}" if $DEBUG

          raise BufferOverflowError, "needed #{new_size}" if retried

          capacity = new_size + 1
          buf      = buf.resized_to capacity
          retried  = true

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

