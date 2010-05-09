require "rubygems"
require "ffi"

module ICUCharDet
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
  attach_function "u_errorName#{suffix}", [:int], :string

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
        @detector = ICUCharDet.ucsdet_open(ptr)
      end
    end

    def close
      ICUCharDet.ucsdet_close @detector
    end

    def detect(str)
      check_status do |ptr|
        ICUCharDet.ucsdet_setText(@detector, str, str.bytesize, ptr)
      end

      match_ptr = nil

      check_status do |ptr|
        match_ptr = ICUCharDet.ucsdet_detect(@detector, ptr)
      end

      result = Match.new
      check_status do |ptr|
        result.name = ICUCharDet.ucsdet_getName(match_ptr, ptr)
      end

      check_status do |ptr|
        result.confidence = ICUCharDet.ucsdet_getConfidence(match_ptr, ptr)
      end

      result
    end

    private

    def check_status
      ptr = FFI::MemoryPointer.new :int

      yield ptr

      error_code = ptr.read_int
      if error_code != 0
        raise "error #{ICUCharDet.u_errorName error_code}"
      end
    end

  end # Detector
end # ICUCharDet

