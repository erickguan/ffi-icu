module ICU
  class Error < StandardError
  end

  module Lib
    extend FFI::Library

    VERSIONS = {
      "42" => "_4_2",
      "44" => "_44"
    }

    # FIXME: this is incredibly ugly, figure out some better way
    def self.find_icu
      suffix = ''

      case ICU.platform
      when :osx
        ffi_lib "icucore"
      when :linux
        versions = VERSIONS.keys
        libs = ffi_lib versions.map { |v| "libicui18n.so.#{v}"},
                       versions.map { |v| "libicutu.so.#{v}"}

        VERSIONS.find do |so_version, func_version|
          if libs.first.name =~ /#{so_version}$/
            suffix = func_version
          end
        end
      else
        raise "no idea how to load ICU on #{ICU.platform}, patches appreciated!"
      end

      suffix
    end

    def self.check_error
      ptr = FFI::MemoryPointer.new(:int)
      ret = yield(ptr)
      error_code = ptr.read_int

      if error_code > 0
        raise Error, "#{Lib.u_errorName error_code}"
      elsif error_code < 0
        warn "ffi-icu: #{Lib.u_errorName error_code}"
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

    def self.not_available(func_name)
      self.class.send :define_method, func_name do |*args|
        raise Error, "#{func_name} not available on platform #{ICU.platform.inspect}"
      end
    end


    suffix = find_icu()

    attach_function :u_errorName, "u_errorName#{suffix}", [:int], :string
    attach_function :uenum_count, "uenum_count#{suffix}", [:pointer, :pointer], :int
    attach_function :uenum_close, "uenum_close#{suffix}",  [:pointer], :void
    attach_function :uenum_next, "uenum_next#{suffix}",  [:pointer, :pointer, :pointer], :string


    # CharDet
    #
    # http://icu-project.org/apiref/icu4c/ucsdet_8h.html
    #

    attach_function :ucsdet_open, "ucsdet_open#{suffix}",  [:pointer], :pointer
    attach_function :ucsdet_close, "ucsdet_close#{suffix}",  [:pointer], :void
    attach_function :ucsdet_setText, "ucsdet_setText#{suffix}",  [:pointer, :string, :int32, :pointer], :void
    attach_function :ucsdet_setDeclaredEncoding, "ucsdet_setDeclaredEncoding#{suffix}",  [:pointer, :string, :int32, :pointer], :void
    attach_function :ucsdet_detect, "ucsdet_detect#{suffix}",  [:pointer, :pointer], :pointer
    attach_function :ucsdet_detectAll, "ucsdet_detectAll#{suffix}",  [:pointer, :pointer, :pointer], :pointer
    attach_function :ucsdet_getName, "ucsdet_getName#{suffix}",  [:pointer, :pointer], :string
    attach_function :ucsdet_getConfidence, "ucsdet_getConfidence#{suffix}",  [:pointer, :pointer], :int32
    attach_function :ucsdet_getLanguage, "ucsdet_getLanguage#{suffix}",  [:pointer, :pointer], :string
    attach_function :ucsdet_getAllDetectableCharsets, "ucsdet_getAllDetectableCharsets#{suffix}",  [:pointer, :pointer], :pointer
    attach_function :ucsdet_isInputFilterEnabled, "ucsdet_isInputFilterEnabled#{suffix}",  [:pointer], :bool
    attach_function :ucsdet_enableInputFilter, "ucsdet_enableInputFilter#{suffix}",  [:pointer, :bool], :bool

    # Collation
    #
    # http://icu-project.org/apiref/icu4c/ucol_8h.html
    #

    attach_function :ucol_open, "ucol_open#{suffix}",  [:string, :pointer], :pointer
    attach_function :ucol_close, "ucol_close#{suffix}",  [:pointer], :void
    attach_function :ucol_strcoll, "ucol_strcoll#{suffix}",  [:pointer, :pointer, :int32, :pointer, :int32], :int
    attach_function :ucol_strcollIter, "ucol_strcollIter#{suffix}",  [:pointer, :pointer, :pointer], :int
    attach_function :ucol_getKeywords, "ucol_getKeywords#{suffix}",  [:pointer], :pointer
    attach_function :ucol_getKeywords, "ucol_getKeywordValues#{suffix}",  [:string, :pointer], :pointer
    attach_function :ucol_getAvailable, "ucol_getAvailable#{suffix}", [:int32], :string
    attach_function :ucol_countAvailable, "ucol_countAvailable#{suffix}", [], :int32

    attach_function :uiter_setUTF8, "uiter_setUTF8#{suffix}",  [:pointer, :string, :int32], :void

  end # Lib
end # ICU
