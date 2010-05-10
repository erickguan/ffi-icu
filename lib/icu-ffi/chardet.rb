module ICU
  module CharDet

    def self.detect(string)
      detector = Detector.new
      res = detector.detect string
      detector.close

      res
    end

    class Detector
      Match = Struct.new(:name, :confidence, :language)

      def initialize
        check_error do |ptr|
          @detector = Lib.ucsdet_open(ptr)
        end
      end

      def input_filter_enabled?
        Lib.ucsdet_isInputFilterEnabled @detector
      end

      def input_filter_enabled=(bool)
        Lib.ucsdet_enableInputFilter(@detector, !!bool)
      end

      def declared_encoding=(str)
        check_error do |ptr|
          Lib.ucsdet_setDeclaredEncoding(@detector, str, str.bytesize, ptr)
        end
      end

      def close
        Lib.ucsdet_close @detector
      end

      def detect(str)
        set_text(str)

        match_ptr = nil
        check_error do |ptr|
          match_ptr = Lib.ucsdet_detect(@detector, ptr)
        end

        match_ptr_to_ruby(match_ptr) unless match_ptr.null?
      end

      def detect_all(str)
        set_text(str)

        matches_found_ptr = FFI::MemoryPointer.new :int
        array_ptr = nil

        check_error do |status|
          array_ptr = Lib.ucsdet_detectAll(@detector, matches_found_ptr, status)
        end

        length = matches_found_ptr.read_int

        array_ptr.read_array_of_pointer(length).map do |match|
          match_ptr_to_ruby(match)
        end
      end

      def detectable_charsets
        enum_ptr = nil

        check_error do |ptr|
          enum_ptr = Lib.ucsdet_getAllDetectableCharsets(@detector, ptr)
        end

        result = enum_ptr_to_array(enum_ptr)
        Lib.uenum_close(enum_ptr)

        result
      end

      private

      def check_error
        yield ptr = FFI::MemoryPointer.new :int
        error_code = ptr.read_int

        if error_code != 0
          raise "error #{Lib.u_errorName error_code}"
        end
      end

      def enum_ptr_to_array(enum_ptr)
        length = 0
        check_error do |status|
          length = Lib.uenum_count(enum_ptr, status)
        end

        result = []
        0.upto(length - 1) do |idx|
          check_error { |st| result << Lib.uenum_next(enum_ptr, nil, st) }
        end

        result
      end

      def match_ptr_to_ruby(match_ptr)
        result = Match.new

        check_error do |ptr|
          result.name = Lib.ucsdet_getName(match_ptr, ptr)
        end

        check_error do |ptr|
          result.confidence = Lib.ucsdet_getConfidence(match_ptr, ptr)
        end

        check_error do |ptr|
          result.language = Lib.ucsdet_getLanguage(match_ptr, ptr)
        end

        result
      end

      def set_text(text)
        check_error do |status|
          Lib.ucsdet_setText(@detector, text, text.bytesize, status)
        end
      end

    end # Detector
  end # CharDet
end # ICU

