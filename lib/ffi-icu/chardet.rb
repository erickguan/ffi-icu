module ICU
  module CharDet

    def self.detect(string)
      Detector.new.detect string
    end

    class Detector
      Match = Struct.new(:name, :confidence, :language)

      def initialize
        ptr = Lib.check_error { |err| Lib.ucsdet_open err }
        @detector = FFI::AutoPointer.new(ptr, Lib.method(:ucsdet_close))
      end

      def input_filter_enabled?
        Lib.ucsdet_isInputFilterEnabled @detector
      end

      def input_filter_enabled=(bool)
        Lib.ucsdet_enableInputFilter(@detector, !!bool)
      end

      def declared_encoding=(str)
        Lib.check_error do |ptr|
          Lib.ucsdet_setDeclaredEncoding(@detector, str, str.bytesize, ptr)
        end
      end

      def detect(str)
        set_text(str)

        match_ptr = Lib.check_error { |ptr| Lib.ucsdet_detect(@detector, ptr) }
        match_ptr_to_ruby(match_ptr) unless match_ptr.null?
      end

      def detect_all(str)
        set_text(str)

        matches_found_ptr = FFI::MemoryPointer.new :int32_t
        array_ptr = Lib.check_error do |status|
          Lib.ucsdet_detectAll(@detector, matches_found_ptr, status)
        end

        length = matches_found_ptr.read_int
        array_ptr.read_array_of_pointer(length).map do |match|
          match_ptr_to_ruby(match)
        end
      end

      def detectable_charsets
        enum_ptr = Lib.check_error do |ptr|
          Lib.ucsdet_getAllDetectableCharsets(@detector, ptr)
        end

        result = Lib.enum_ptr_to_array(enum_ptr)
        Lib.uenum_close(enum_ptr)

        result
      end

      private

      def match_ptr_to_ruby(match_ptr)
        result = Match.new

        result.name       = Lib.check_error { |ptr| Lib.ucsdet_getName(match_ptr, ptr) }
        result.confidence = Lib.check_error { |ptr| Lib.ucsdet_getConfidence(match_ptr, ptr) }
        result.language   = Lib.check_error { |ptr| Lib.ucsdet_getLanguage(match_ptr, ptr) }

        result
      end

      def set_text(text)
        Lib.check_error do |status|
          data = FFI::MemoryPointer.from_string(text)
          Lib.ucsdet_setText(@detector, data, text.bytesize, status)
        end
      end

    end # Detector
  end # CharDet
end # ICU

