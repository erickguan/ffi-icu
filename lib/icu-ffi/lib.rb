module ICU
  module Lib
    extend FFI::Library

    # FIXME: this is incredibly ugly, figure out some better way
    lib = ffi_lib([ "libicui18n.so.42",
                    "libicui18n.so.44",
                    "icucore" # os x
                  ]).first

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
    
  end # Functions
end # ICU