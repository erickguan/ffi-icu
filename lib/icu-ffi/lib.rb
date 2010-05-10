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

    attach_function "u_errorName#{suffix}", :u_errorName, [:int], :string
    attach_function "uenum_count#{suffix}", :uenum_count, [:pointer, :pointer], :int
    attach_function "uenum_close#{suffix}", :uenum_close, [:pointer], :void
    attach_function "uenum_next#{suffix}", :uenum_next, [:pointer, :pointer, :pointer], :string


    # CharDet
    #
    # http://icu-project.org/apiref/icu4c/ucsdet_8h.html
    #

    attach_function "ucsdet_open#{suffix}", :ucsdet_open, [:pointer], :pointer
    attach_function "ucsdet_close#{suffix}", :ucsdet_close, [:pointer], :void
    attach_function "ucsdet_setText#{suffix}", :ucsdet_setText, [:pointer, :string, :int, :pointer], :void
    attach_function "ucsdet_setDeclaredEncoding#{suffix}", :ucsdet_setDeclaredEncoding, [:pointer, :string, :int, :pointer], :void
    attach_function "ucsdet_detect#{suffix}", :ucsdet_detect, [:pointer, :pointer], :pointer
    attach_function "ucsdet_detectAll#{suffix}", :ucsdet_detectAll, [:pointer, :pointer, :pointer], :pointer
    attach_function "ucsdet_getName#{suffix}", :ucsdet_getName, [:pointer, :pointer], :string
    attach_function "ucsdet_getConfidence#{suffix}", :ucsdet_getConfidence, [:pointer, :pointer], :int
    attach_function "ucsdet_getLanguage#{suffix}", :ucsdet_getLanguage, [:pointer, :pointer], :string
    attach_function "ucsdet_getAllDetectableCharsets#{suffix}", :ucsdet_getAllDetectableCharsets, [:pointer, :pointer], :pointer
    attach_function "ucsdet_isInputFilterEnabled#{suffix}", :ucsdet_isInputFilterEnabled, [:pointer], :bool
    attach_function "ucsdet_enableInputFilter#{suffix}", :ucsdet_enableInputFilter, [:pointer, :bool], :bool

    # Collation
    #
    # http://icu-project.org/apiref/icu4c/ucol_8h.html
    #

    attach_function "ucol_open#{suffix}", :ucol_open, [:string, :pointer], :pointer
    attach_function "ucol_close#{suffix}", :ucol_close, [:pointer], :void



    def self.check_error
      ptr = FFI::MemoryPointer.new(:int)
      ret = yield(ptr)
      error_code = ptr.read_int

      if error_code != 0
        raise "error #{Lib.u_errorName error_code}"
      end

      ret
    end

    def self.enum_ptr_to_array(enum_ptr)
      length = Lib.check_error do |status|
        Lib.uenum_count(enum_ptr, status)
      end

      (0...length).map do |idx|
        Lib.check_error { |st| Lib.uenum_next(enum_ptr, nil, st) }
      end
    end


  end # Functions
end # ICU