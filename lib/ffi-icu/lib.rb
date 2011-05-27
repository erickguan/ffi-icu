module ICU
  class Error < StandardError
  end

  class BufferOverflowError < StandardError
  end

  module Lib
    extend FFI::Library

    VERSIONS = {
      "42" => "_4_2",
      "44" => "_44",
      "45" => "_45",
      "46" => "_46"
    }

    # FIXME: this is incredibly ugly, figure out some better way
    def self.find_icu
      suffix = ''

      # let the user tell us where the lib is
      if ENV['FFI_ICU_LIB']
        libs = ENV['FFI_ICU_LIB'].split(",")
        ffi_lib(*libs)

        if ENV['FFI_ICU_VERSION_SUFFIX']
          return ENV['FFI_ICU_VERSION_SUFFIX']
        elsif num = libs.first[/\d+$/]
          return num.split(//).join("_")
        else
          return suffix
        end
      end

      # ok, try to find it
      case ICU.platform
      when :osx
        ffi_lib "icucore"
      when :linux
        versions = VERSIONS.keys
        libs = ffi_lib versions.map { |v| "libicui18n.so.#{v}" },
                       versions.map { |v| "libicutu.so.#{v}"   }

        VERSIONS.find do |so_version, func_version|
          if libs.first.name =~ /#{so_version}$/
            suffix = func_version
          end
        end
      else
        raise LoadError
      end

      suffix
    rescue LoadError => ex
      raise LoadError, "no idea how to load ICU on #{ICU.platform}, patches appreciated! (#{ex.message})"
    end

    def self.check_error
      ptr = FFI::MemoryPointer.new(:int)
      ret = yield(ptr)
      error_code = ptr.read_int

      if error_code > 0
        name = Lib.u_errorName error_code
        if name == "U_BUFFER_OVERFLOW_ERROR"
          raise BufferOverflowError
        else
          raise Error, name
        end
      elsif error_code < 0
        warn "ffi-icu: #{Lib.u_errorName error_code}"
      end

      ret
    end

    def self.enum_ptr_to_array(enum_ptr)
      length = check_error do |status|
        uenum_count(enum_ptr, status)
      end

      len = FFI::MemoryPointer.new(:int)

      (0...length).map do |idx|
        check_error { |st| uenum_next(enum_ptr, len, st) }
      end
    end

    def self.not_available(func_name)
      self.class.send :define_method, func_name do |*args|
        raise Error, "#{func_name} not available on platform #{ICU.platform.inspect}"
      end
    end


    suffix = find_icu()

    attach_function :u_errorName,     "u_errorName#{suffix}",     [:int],      :string
    attach_function :uenum_count,     "uenum_count#{suffix}",     [:pointer,   :pointer], :int
    attach_function :uenum_close,     "uenum_close#{suffix}",      [:pointer], :void
    attach_function :uenum_next,      "uenum_next#{suffix}",       [:pointer,  :pointer,  :pointer], :string
    attach_function :u_charsToUChars, "u_charsToUChars#{suffix}", [:string,    :pointer,  :int32_t], :void
    attach_function :u_UCharsToChars, "u_UCharsToChars#{suffix}", [:pointer,   :string,   :int32_t], :void

    # CharDet
    #
    # http://icu-project.org/apiref/icu4c/ucsdet_8h.html
    #

    attach_function :ucsdet_open,                     "ucsdet_open#{suffix}",                      [:pointer], :pointer
    attach_function :ucsdet_close,                    "ucsdet_close#{suffix}",                     [:pointer], :void
    attach_function :ucsdet_setText,                  "ucsdet_setText#{suffix}",                   [:pointer,  :string,   :int32_t,  :pointer], :void
    attach_function :ucsdet_setDeclaredEncoding,      "ucsdet_setDeclaredEncoding#{suffix}",       [:pointer,  :string,   :int32_t,  :pointer], :void
    attach_function :ucsdet_detect,                   "ucsdet_detect#{suffix}",                    [:pointer,  :pointer], :pointer
    attach_function :ucsdet_detectAll,                "ucsdet_detectAll#{suffix}",                 [:pointer,  :pointer,  :pointer], :pointer
    attach_function :ucsdet_getName,                  "ucsdet_getName#{suffix}",                   [:pointer,  :pointer], :string
    attach_function :ucsdet_getConfidence,            "ucsdet_getConfidence#{suffix}",             [:pointer,  :pointer], :int32_t
    attach_function :ucsdet_getLanguage,              "ucsdet_getLanguage#{suffix}",               [:pointer,  :pointer], :string
    attach_function :ucsdet_getAllDetectableCharsets, "ucsdet_getAllDetectableCharsets#{suffix}",  [:pointer,  :pointer], :pointer
    attach_function :ucsdet_isInputFilterEnabled,     "ucsdet_isInputFilterEnabled#{suffix}",      [:pointer], :bool
    attach_function :ucsdet_enableInputFilter,        "ucsdet_enableInputFilter#{suffix}",         [:pointer,  :bool],    :bool

    # Collation
    #
    # http://icu-project.org/apiref/icu4c/ucol_8h.html
    #

    attach_function :ucol_open,             "ucol_open#{suffix}",              [:string,   :pointer], :pointer
    attach_function :ucol_close,            "ucol_close#{suffix}",             [:pointer], :void
    attach_function :ucol_strcoll,          "ucol_strcoll#{suffix}",           [:pointer,  :pointer,  :int32_t,  :pointer, :int32_t], :int
    attach_function :ucol_getKeywords,      "ucol_getKeywords#{suffix}",       [:pointer], :pointer
    attach_function :ucol_getKeywordValues, "ucol_getKeywordValues#{suffix}",  [:string,   :pointer], :pointer
    attach_function :ucol_getAvailable,     "ucol_getAvailable#{suffix}",     [:int32_t],  :string
    attach_function :ucol_countAvailable,   "ucol_countAvailable#{suffix}",   [],          :int32_t
    attach_function :ucol_getLocale,        "ucol_getLocale#{suffix}",        [:pointer,   :int,      :pointer], :string
    attach_function :ucol_greater,          "ucol_greater#{suffix}",          [:pointer,   :pointer,  :int32_t,  :pointer, :int32_t], :bool
    attach_function :ucol_greaterOrEqual,   "ucol_greaterOrEqual#{suffix}",   [:pointer,   :pointer,  :int32_t,  :pointer, :int32_t], :bool
    attach_function :ucol_equal,            "ucol_equal#{suffix}",            [:pointer,   :pointer,  :int32_t,  :pointer, :int32_t], :bool

    # Transliteration
    #
    # http://icu-project.org/apiref/icu4c/utrans_8h.html
    #

    class UParseError < FFI::Struct
      layout :line,         :int32_t,
             :offset,       :int32_t,
             :pre_context,  :pointer,
             :post_context, :pointer

      def to_s
        "#<%s:%x line: %d offset: %d" % [self.class, hash*2, self[:line], self[:offset]]
      end
    end

    class UTransPosition < FFI::Struct
      layout :context_start, :int32_t,
             :context_limit, :int32_t,
             :start,         :int32_t,
             :end,           :int32_t

    end

    enum :trans_direction, [:forward, :reverse]

    attach_function :utrans_openIDs,     "utrans_openIDs#{suffix}",     [:pointer], :pointer
    attach_function :utrans_openU,       "utrans_openU#{suffix}",       [:pointer,  :int32_t,         :trans_direction, :pointer, :int32_t, :pointer,  :pointer], :pointer
    attach_function :utrans_open,        "utrans_open#{suffix}",        [:string,   :trans_direction, :pointer,         :int32_t, :pointer, :pointer], :pointer
    attach_function :utrans_close,       "utrans_close#{suffix}",       [:pointer], :void
    attach_function :utrans_transUChars, "utrans_transUChars#{suffix}", [:pointer,  :pointer,         :pointer,         :int32_t, :int32_t, :pointer,  :pointer], :void

    # Normalization
    #
    # http://icu-project.org/apiref/icu4c/unorm_8h.html
    #

    enum :normalization_mode, [ :none,    1,
                                :nfd,     2,
                                :nfkd,    3,
                                :nfc,     4,
                                :default, 4,
                                :nfkc,    5,
                                :fcd,     6
                              ]

    attach_function :unorm_normalize, "unorm_normalize#{suffix}", [:pointer, :int32_t, :normalization_mode, :int32_t, :pointer, :int32_t, :pointer], :int32_t

    #
    # Text Boundary Analysis
    #

    enum :iterator_type, [ :character, :word, :line, :sentence, :title]
    enum :word_break, [ :none,         0,
                        :none_limit,   100,
                        :number,       100,
                        :number_limit, 200,
                        :letter,       200,
                        :letter_limit, 300,
                        :kana,         300,
                        :kana_limit,   400,
                        :ideo,         400,
                        :ideo_limit,   400
                      ]

    attach_function :ubrk_countAvailable, "ubrk_countAvailable#{suffix}", [],              :int32_t
    attach_function :ubrk_getAvailable,   "ubrk_getAvailable#{suffix}",   [:int32_t],      :string

    attach_function :ubrk_open,           "ubrk_open#{suffix}",           [:iterator_type, :string,   :pointer, :int32_t,  :pointer], :pointer
    attach_function :ubrk_close,          "ubrk_close#{suffix}",          [:pointer],      :void
    attach_function :ubrk_setText,        "ubrk_setText#{suffix}",        [:pointer,       :pointer,  :int32_t, :pointer], :void
    attach_function :ubrk_current,        "ubrk_current#{suffix}",        [:pointer],      :int32_t
    attach_function :ubrk_next,           "ubrk_next#{suffix}",           [:pointer],      :int32_t
    attach_function :ubrk_previous,       "ubrk_previous#{suffix}",       [:pointer],      :int32_t
    attach_function :ubrk_first,          "ubrk_first#{suffix}",          [:pointer],      :int32_t
    attach_function :ubrk_last,           "ubrk_last#{suffix}",           [:pointer],      :int32_t

    attach_function :ubrk_preceding,      "ubrk_preceding#{suffix}",      [:pointer,       :int32_t], :int32_t
    attach_function :ubrk_following,      "ubrk_following#{suffix}",      [:pointer,       :int32_t], :int32_t
    attach_function :ubrk_isBoundary,     "ubrk_isBoundary#{suffix}",     [:pointer,       :int32_t], :int32_t

  end # Lib
end # ICU
