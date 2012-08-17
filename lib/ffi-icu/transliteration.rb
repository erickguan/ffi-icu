module ICU
  module Transliteration

    class << self
      def transliterate(translit_id, str, rules = nil)
        t = Transliterator.new translit_id, rules
        t.transliterate str
      end
      alias_method :translit, :transliterate

      def available_ids
        Lib.check_error { |error| Lib.utrans_openIDs(error).to_a }
      end
    end

    class Transliterator

      def initialize(id, rules = nil, direction = :forward)
        rules_length = 0

        if rules
          rules_length = rules.jlength + 1
          rules = UCharPointer.from_string(rules)
        end

        parse_error = Lib::UParseError.new
        begin
          Lib.check_error do |status|
            # couldn't get utrans_openU to work properly, so using deprecated utrans_open for now
            ptr = Lib.utrans_openU(UCharPointer.from_string(id), id.jlength, direction, rules, rules_length, @parse_error, status)
            @tr = FFI::AutoPointer.new(ptr, Lib.method(:utrans_close))
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

    end # Transliterator
  end # Translit
end # ICU

