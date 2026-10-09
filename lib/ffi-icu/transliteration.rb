# frozen_string_literal: true

module ICU
  module Transliteration
    class << self
      def transliterate(translit_id, str, rules = nil)
        t = Transliterator.new(translit_id, rules)
        t.transliterate(str)
      end
      alias translit transliterate

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
        rules_length = 0

        if rules
          rules = UCharPointer.from_utf8(rules)
          rules_length = rules.length_in_uchars
        end

        id = UCharPointer.from_utf8(id)

        parse_error = Lib::UParseError.new
        begin
          Lib.check_error do |status|
            ptr = Lib.utrans_openU(id, id.length_in_uchars, direction, rules, rules_length,
                                   parse_error, status)
            @tr = FFI::AutoPointer.new(ptr, Lib.method(:utrans_close))
          end
        rescue ICU::Error => e
          raise(e, "#{e.message} (#{parse_error})")
        end
      end

      def transliterate(from)
        # this is a bit unpleasant

        input = UCharPointer.from_utf8(from)
        input_length_in_uchars = input.length_in_uchars
        capacity               = input_length_in_uchars + 1
        buf = UCharPointer.new(capacity)
        buf.put_bytes(0, input.get_bytes(0, input.size))
        limit        = FFI::MemoryPointer.new(:int32)
        text_length  = FFI::MemoryPointer.new(:int32)

        retried = false

        begin
          # resets to original size on retry
          [limit, text_length].each do |ptr|
            ptr.put_int32(0, input_length_in_uchars)
          end

          Lib.check_error do |error|
            Lib.utrans_transUChars(@tr, buf, text_length, capacity, 0, limit, error)
          end
        rescue BufferOverflowError
          new_size = text_length.get_int32(0)
          warn("BufferOverflowError, needs: #{new_size}") if $DEBUG

          raise(BufferOverflowError, "needed #{new_size}") if retried

          capacity = new_size + 1

          # create a new buffer with more capacity instead of resizing,
          # since the old buffer now has result data
          buf.free
          buf = UCharPointer.from_utf8(from, capacity)

          retried = true
          retry
        end

        buf.utf8_string(text_length.get_int32(0))
      end
    end
  end
end
