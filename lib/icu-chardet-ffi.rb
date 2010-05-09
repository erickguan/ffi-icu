require "ffi"

module ICU
  module CharDet
    extend FFI::Library

    lib = ffi_lib([ "libicui18n.so.42",
                    "libicui18n.so.44",
                    "icucore" # os x
                  ]).first

    # find a better way to do this!
    suffix = ''
    if lib.find_function("ucsdet_open_4_2")
      suffix = '_4_2'
    elsif lib.find_function("ucsdet_open_44")
      suffix = '_44'
    end

    #
    # http://icu-project.org/apiref/icu4c/ucsdet_8h.html
    #

    attach_function "ucsdet_open#{suffix}", [:pointer], :pointer
    attach_function "ucsdet_close#{suffix}", [:pointer], :void
    attach_function "ucsdet_setText#{suffix}", [:pointer, :string, :int, :pointer], :void
    attach_function "ucsdet_setDeclaredEncoding#{suffix}", [:pointer, :string, :int, :pointer], :void
    attach_function "ucsdet_detect#{suffix}", [:pointer, :pointer], :pointer
    attach_function "ucsdet_detectAll#{suffix}", [:pointer, :pointer, :pointer], :pointer
    attach_function "ucsdet_getName#{suffix}", [:pointer, :pointer], :string
    attach_function "ucsdet_getConfidence#{suffix}", [:pointer, :pointer], :int
    attach_function "ucsdet_getLanguage#{suffix}", [:pointer, :pointer], :string
    attach_function "ucsdet_getAllDetectableCharsets#{suffix}", [:pointer, :pointer], :pointer
    attach_function "ucsdet_isInputFilterEnabled#{suffix}", [:pointer], :bool
    attach_function "ucsdet_enableInputFilter#{suffix}", [:pointer, :bool], :bool
    attach_function "u_errorName#{suffix}", [:int], :string
    attach_function "uenum_count#{suffix}", [:pointer, :pointer], :int
    attach_function "uenum_close#{suffix}", [:pointer], :void
    attach_function "uenum_next#{suffix}", [:pointer, :pointer, :pointer], :string


    unless suffix.empty?
      class << self; self end.instance_eval do
        alias_method :ucsdet_open, "ucsdet_open#{suffix}"
        alias_method :ucsdet_close, "ucsdet_close#{suffix}"
        alias_method :ucsdet_setText, "ucsdet_setText#{suffix}"
        alias_method :ucsdet_detect, "ucsdet_detect#{suffix}"
        alias_method :ucsdet_getName, "ucsdet_getName#{suffix}"
        alias_method :ucsdet_getConfidence, "ucsdet_getConfidence#{suffix}"
        alias_method :ucsdet_getLanguage, "ucsdet_getLanguage#{suffix}"
        alias_method :ucsdet_isInputFilterEnabled, "ucsdet_isInputFilterEnabled#{suffix}"
        alias_method :ucsdet_enableInputFilter, "ucsdet_enableInputFilter#{suffix}"
        alias_method :ucsdet_setDeclaredEncoding, "ucsdet_setDeclaredEncoding#{suffix}"
        alias_method :u_errorName, "u_errorName#{suffix}"
        alias_method :uenum_count, "uenum_count#{suffix}"
        alias_method :uenum_count, "uenum_close#{suffix}"
        alias_method :uenum_count, "uenum_next#{suffix}"
      end
    end

    def self.detect(string)
      detector = Detector.new
      res = detector.detect string
      detector.close

      res
    end

    class Detector
      Match = Struct.new(:name, :confidence, :language)

      def initialize
        check_status do |ptr|
          @detector = CharDet.ucsdet_open(ptr)
        end
      end

      def input_filter_enabled?
        CharDet.ucsdet_isInputFilterEnabled @detector
      end

      def input_filter_enabled=(bool)
        CharDet.ucsdet_enableInputFilter(@detector, !!bool)
      end

      def declared_encoding=(str)
        check_status do |ptr|
          CharDet.ucsdet_setDeclaredEncoding(@detector, str, str.bytesize, ptr)
        end
      end

      def close
        CharDet.ucsdet_close @detector
      end

      def detect(str)
        set_text(str)

        match_ptr = nil
        check_status do |ptr|
          match_ptr = CharDet.ucsdet_detect(@detector, ptr)
        end

        match_ptr_to_ruby(match_ptr) unless match_ptr.null?
      end

      def detect_all(str)
        set_text(str)

        matches_found_ptr = FFI::MemoryPointer.new :int
        array_ptr = nil

        check_status do |status|
          array_ptr = CharDet.ucsdet_detectAll(@detector, matches_found_ptr, status)
        end

        length = matches_found_ptr.read_int

        array_ptr.read_array_of_pointer(length).map do |match|
          match_ptr_to_ruby(match)
        end
      end

      def detectable_charsets
        enum_ptr = nil

        check_status do |ptr|
          enum_ptr = CharDet.ucsdet_getAllDetectableCharsets(@detector, ptr)
        end

        result = enum_ptr_to_array(enum_ptr)
        CharDet.uenum_close(enum_ptr)

        result
      end

      private

      def check_status
        ptr = FFI::MemoryPointer.new :int

        yield ptr

        error_code = ptr.read_int
        if error_code != 0
          raise "error #{CharDet.u_errorName error_code}"
        end
      end

      def enum_ptr_to_array(enum_ptr)
        length = 0
        check_status do |status|
          length = CharDet.uenum_count(enum_ptr, status)
        end

        result = []
        0.upto(length - 1) do |idx|
          check_status { |st| result << CharDet.uenum_next(enum_ptr, nil, st) }
        end

        result
      end

      def match_ptr_to_ruby(match_ptr)
        result = Match.new

        check_status do |ptr|
          result.name = CharDet.ucsdet_getName(match_ptr, ptr)
        end

        check_status do |ptr|
          result.confidence = CharDet.ucsdet_getConfidence(match_ptr, ptr)
        end

        check_status do |ptr|
          result.language = CharDet.ucsdet_getLanguage(match_ptr, ptr)
        end

        result
      end

      def set_text(text)
        check_status do |status|
          CharDet.ucsdet_setText(@detector, text, text.bytesize, status)
        end
      end

    end # Detector
  end # CharDet
end # ICU

