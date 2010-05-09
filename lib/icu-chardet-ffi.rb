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

    attach_function "ucsdet_open#{suffix}", [:pointer], :pointer
    attach_function "ucsdet_close#{suffix}", [:pointer], :void
    attach_function "ucsdet_setText#{suffix}", [:pointer, :string, :int, :pointer], :void
    attach_function "ucsdet_detect#{suffix}", [:pointer, :pointer], :pointer
    attach_function "ucsdet_getName#{suffix}", [:pointer, :pointer], :string
    attach_function "ucsdet_getConfidence#{suffix}", [:pointer, :pointer], :int
    attach_function "ucsdet_getAllDetectableCharsets#{suffix}", [:pointer, :pointer], :pointer
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
        alias_method :u_errorName, "u_errorName#{suffix}"
      end
    end

    def self.detect(string)
      detector = Detector.new
      res = detector.detect string
      detector.close

      res
    end

    class Detector
      Match = Struct.new(:name, :confidence)

      def initialize
        check_status do |ptr|
          @detector = CharDet.ucsdet_open(ptr)
        end
      end

      def close
        CharDet.ucsdet_close @detector
      end

      def detect(str)
        check_status do |ptr|
          CharDet.ucsdet_setText(@detector, str, str.bytesize, ptr)
        end

        match_ptr = nil

        check_status do |ptr|
          match_ptr = CharDet.ucsdet_detect(@detector, ptr)
        end

        result = Match.new
        check_status do |ptr|
          result.name = CharDet.ucsdet_getName(match_ptr, ptr)
        end

        check_status do |ptr|
          result.confidence = CharDet.ucsdet_getConfidence(match_ptr, ptr)
        end

        result
      end

      def detectable_charsets
        enum_ptr = nil

        check_status do |ptr|
          enum_ptr = CharDet.ucsdet_getAllDetectableCharsets(@detector, ptr)
        end

        result = enumeration_to_array(enum_ptr)
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

      def enumeration_to_array(ptr)
        length = 0
        check_status do |status|
          length = CharDet.uenum_count(ptr, status)
        end

        result = []
        0.upto(length - 1) do |idx|
          check_status { |st| result << CharDet.uenum_next(ptr, nil, st) }
        end

        result
      end

    end # Detector
  end # CharDet
end # ICU

