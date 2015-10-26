module ICU
  class Error < StandardError
  end

  class BufferOverflowError < StandardError
  end

  module Lib
    extend FFI::Library

    def self.search_paths
      @search_paths ||= begin
        if ENV['FFI_ICU_LIB']
          [ ENV['FFI_ICU_LIB'] ]
        elsif FFI::Platform::IS_WINDOWS
          ENV['PATH'].split(File::PATH_SEPARATOR)
        else
          [
            '/usr/local/{lib64,lib}',
            '/opt/local/{lib64,lib}',
            '/usr/{lib64,lib}',
            '/usr/lib/x86_64-linux-gnu', # for Debian Multiarch http://wiki.debian.org/Multiarch
            '/usr/lib/i386-linux-gnu',   # for Debian Multiarch
          ]
        end
      end
    end

    def self.find_lib(lib)
      Dir.glob(search_paths.map { |path|
        File.expand_path(File.join(path, lib))
      }).first
    end

    def self.load_icu
      # First find the library
      lib_names = case ICU.platform
                  when :bsd
                    [find_lib("libicui18n.#{FFI::Platform::LIBSUFFIX}.??"),
                     find_lib("libicutu.#{FFI::Platform::LIBSUFFIX}.??")]
                  when :osx
                    [find_lib("libicucore.#{FFI::Platform::LIBSUFFIX}")]
                  when :linux
                    [find_lib("libicui18n.#{FFI::Platform::LIBSUFFIX}.??"),
                     find_lib("libicutu.#{FFI::Platform::LIBSUFFIX}.??")]
                  when :windows
                    [find_lib("icuuc??.#{FFI::Platform::LIBSUFFIX}"),
                     find_lib("icuin??.#{FFI::Platform::LIBSUFFIX}")]
                  end

      lib_names.compact! if lib_names

      if not lib_names or lib_names.length == 0
        raise LoadError, "Could not find ICU on #{ICU.platform.inspect}. Patches welcome, or you can add the containing directory yourself: #{self}.search_paths << '/path/to/lib'"
      end

      # And now try to load the library
      begin
        libs = ffi_lib(*lib_names)
      rescue LoadError => ex
        raise LoadError, "no idea how to load ICU on #{ICU.platform.inspect}, patches appreciated! (#{ex.message})"
      end

      icu_version(libs)
    end

    def self.icu_version(libs)
      version = nil

      libs.find do |lib|
        # Get the version - sure would be nice if libicu exported this in a function
        # we could just call cause this is super fugly!
        match = lib.name.match(/(\d\d)\.#{FFI::Platform::LIBSUFFIX}/) ||
                lib.name.match(/#{FFI::Platform::LIBSUFFIX}\.(\d\d)/)
        if match
          version = match[1]
        end
      end

      # Note this may return nil, like on OSX
      version
    end

    def self.figure_suffix(version)
      # For some reason libicu prepends its exported functions with version information,
      # which differs across all platforms.  Some examples:
      #
      # OSX:
      #   u_errorName
      #
      # CentOS 5
      #   u_errorName_3_6
      #
      # Fedora 14 and Windows (using mingw)
      #   u_errorName_44
      #
      # So we need to figure out which one it is.

      # Here are the possible suffixes
      suffixes = [""]
      if version
        suffixes << "_#{version}" << "_#{version[0].chr}_#{version[1].chr}" << "_#{version.split('.')[0]}"
      end

      # Try to find the u_errorName function using the possible suffixes
      suffixes.find do |suffix|
        function_name = "u_errorName#{suffix}"
        function_names(function_name, nil).find do |fname|
          ffi_libraries.find do |lib|
            lib.find_function(fname)
          end
        end
      end
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
        $stderr.puts "ffi-icu: #{Lib.u_errorName error_code}" if $DEBUG || $VERBOSE
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

    class VersionInfo < FFI::MemoryPointer
      extend FFI::DataConverter

      MaxLength = 4
      MaxStringLength = 20

      def self.native_type
        FFI::Type::POINTER
      end

      def initialize
        super :uint8, MaxLength
      end

      def to_a
        read_array_of_uint8(MaxLength)
      end

      def to_s
        buffer = FFI::MemoryPointer.new(:char, MaxStringLength)
        Lib.u_versionToString(self, buffer)
        buffer.read_string_to_null
      end
    end

    def self.cldr_version
      @cldr_version ||= VersionInfo.new.tap do |version|
        check_error { |status| ulocdata_getCLDRVersion(version, status) }
      end
    end

    def self.version
      @version ||= VersionInfo.new.tap { |version| u_getVersion(version) }
    end

    version = load_icu
    suffix = figure_suffix(version)

    typedef VersionInfo, :version

    attach_function :u_errorName,     "u_errorName#{suffix}",     [:int],      :string
    attach_function :uenum_count,     "uenum_count#{suffix}",     [:pointer,   :pointer], :int
    attach_function :uenum_close,     "uenum_close#{suffix}",     [:pointer], :void
    attach_function :uenum_next,      "uenum_next#{suffix}",      [:pointer,  :pointer,  :pointer], :string
    attach_function :u_charsToUChars, "u_charsToUChars#{suffix}", [:string,    :pointer,  :int32_t], :void
    attach_function :u_UCharsToChars, "u_UCharsToChars#{suffix}", [:pointer,   :string,   :int32_t], :void

    attach_function :u_getVersion,      "u_getVersion#{suffix}",      [:version], :void
    attach_function :u_versionToString, "u_versionToString#{suffix}", [:version, :pointer], :void

    #
    # Locale
    #
    # http://icu-project.org/apiref/icu4c/uloc_8h.html
    #

    enum :layout_type, [:ltr, :rtl, :ttb, :btt, :unknown]

    attach_function :uloc_canonicalize,     "uloc_canonicalize#{suffix}",     [:string, :pointer, :int32_t, :pointer], :int32_t
    attach_function :uloc_countAvailable,   "uloc_countAvailable#{suffix}",   [], :int32_t
    attach_function :uloc_getAvailable,     "uloc_getAvailable#{suffix}",     [:int32_t], :string
    attach_function :uloc_getBaseName,      "uloc_getBaseName#{suffix}",      [:string, :pointer, :int32_t, :pointer], :int32_t
    attach_function :uloc_getCountry,       "uloc_getCountry#{suffix}",       [:string, :pointer, :int32_t, :pointer], :int32_t
    attach_function :uloc_getDefault,       "uloc_getDefault#{suffix}",       [], :string
    attach_function :uloc_getISO3Country,   "uloc_getISO3Country#{suffix}",   [:string], :string
    attach_function :uloc_getISO3Language,  "uloc_getISO3Language#{suffix}",  [:string], :string
    attach_function :uloc_getISOCountries,  "uloc_getISOCountries#{suffix}",  [], :pointer
    attach_function :uloc_getISOLanguages,  "uloc_getISOLanguages#{suffix}",  [], :pointer
    attach_function :uloc_getKeywordValue,  "uloc_getKeywordValue#{suffix}",  [:string, :string, :pointer, :int32_t, :pointer], :int32_t
    attach_function :uloc_getLanguage,      "uloc_getLanguage#{suffix}",      [:string, :pointer, :int32_t, :pointer], :int32_t
    attach_function :uloc_getLCID,          "uloc_getLCID#{suffix}",          [:string], :uint32
    attach_function :uloc_getName,          "uloc_getName#{suffix}",          [:string, :pointer, :int32_t, :pointer], :int32_t
    attach_function :uloc_getParent,        "uloc_getParent#{suffix}",        [:string, :pointer, :int32_t, :pointer], :int32_t
    attach_function :uloc_getScript,        "uloc_getScript#{suffix}",        [:string, :pointer, :int32_t, :pointer], :int32_t
    attach_function :uloc_getVariant,       "uloc_getVariant#{suffix}",       [:string, :pointer, :int32_t, :pointer], :int32_t
    attach_function :uloc_openKeywords,     "uloc_openKeywords#{suffix}",     [:string, :pointer], :pointer
    attach_function :uloc_setDefault,       "uloc_setDefault#{suffix}",       [:string, :pointer], :void
    attach_function :uloc_setKeywordValue,  "uloc_setKeywordValue#{suffix}",  [:string, :string, :pointer, :int32_t, :pointer], :int32_t

    attach_function :uloc_getDisplayCountry,        "uloc_getDisplayCountry#{suffix}",        [:string, :string, :pointer, :int32_t, :pointer], :int32_t
    attach_function :uloc_getDisplayKeyword,        "uloc_getDisplayKeyword#{suffix}",        [:string, :string, :pointer, :int32_t, :pointer], :int32_t
    attach_function :uloc_getDisplayKeywordValue,   "uloc_getDisplayKeywordValue#{suffix}",   [:string, :string, :string, :pointer, :int32_t, :pointer], :int32_t
    attach_function :uloc_getDisplayLanguage,       "uloc_getDisplayLanguage#{suffix}",       [:string, :string, :pointer, :int32_t, :pointer], :int32_t
    attach_function :uloc_getDisplayName,           "uloc_getDisplayName#{suffix}",           [:string, :string, :pointer, :int32_t, :pointer], :int32_t
    attach_function :uloc_getDisplayScript,         "uloc_getDisplayScript#{suffix}",         [:string, :string, :pointer, :int32_t, :pointer], :int32_t
    attach_function :uloc_getDisplayVariant,        "uloc_getDisplayVariant#{suffix}",        [:string, :string, :pointer, :int32_t, :pointer], :int32_t

    if Gem::Version.new('3.8') <= Gem::Version.new(self.version)
      attach_function :uloc_getLocaleForLCID, "uloc_getLocaleForLCID#{suffix}", [:uint32, :pointer, :int32_t, :pointer], :int32_t
    end

    if Gem::Version.new('4.0') <= Gem::Version.new(self.version)
      attach_function :uloc_addLikelySubtags, "uloc_addLikelySubtags#{suffix}", [:string, :pointer, :int32_t, :pointer], :int32_t
      attach_function :uloc_minimizeSubtags,  "uloc_minimizeSubtags#{suffix}",  [:string, :pointer, :int32_t, :pointer], :int32_t
      attach_function :uloc_getCharacterOrientation,  "uloc_getCharacterOrientation#{suffix}",  [:string, :pointer], :layout_type
      attach_function :uloc_getLineOrientation,       "uloc_getLineOrientation#{suffix}",       [:string, :pointer], :layout_type
    end

    if Gem::Version.new('4.2') <= Gem::Version.new(self.version)
      attach_function :uloc_forLanguageTag, "uloc_forLanguageTag#{suffix}", [:string, :pointer, :int32_t, :pointer, :pointer], :int32_t
      attach_function :uloc_toLanguageTag,  "uloc_toLanguageTag#{suffix}",  [:string, :pointer, :int32_t, :int8_t, :pointer], :int32_t

      attach_function :ulocdata_getCLDRVersion, "ulocdata_getCLDRVersion#{suffix}", [:version, :pointer], :void
    end

    # CharDet
    #
    # http://icu-project.org/apiref/icu4c/ucsdet_8h.html
    #

    attach_function :ucsdet_open,                     "ucsdet_open#{suffix}",                      [:pointer], :pointer
    attach_function :ucsdet_close,                    "ucsdet_close#{suffix}",                     [:pointer], :void
    attach_function :ucsdet_setText,                  "ucsdet_setText#{suffix}",                   [:pointer,  :pointer,  :int32_t,  :pointer], :void
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

    attach_function :ucol_open,             "ucol_open#{suffix}",             [:string,    :pointer], :pointer
    attach_function :ucol_close,            "ucol_close#{suffix}",            [:pointer],  :void
    attach_function :ucol_strcoll,          "ucol_strcoll#{suffix}",          [:pointer,   :pointer,  :int32_t,  :pointer, :int32_t], :int
    attach_function :ucol_getKeywords,      "ucol_getKeywords#{suffix}",      [:pointer],  :pointer
    attach_function :ucol_getKeywordValues, "ucol_getKeywordValues#{suffix}", [:string,    :pointer], :pointer
    attach_function :ucol_getAvailable,     "ucol_getAvailable#{suffix}",     [:int32_t],  :string
    attach_function :ucol_countAvailable,   "ucol_countAvailable#{suffix}",   [],          :int32_t
    attach_function :ucol_getLocale,        "ucol_getLocale#{suffix}",        [:pointer,   :int,      :pointer], :string
    attach_function :ucol_greater,          "ucol_greater#{suffix}",          [:pointer,   :pointer,  :int32_t,  :pointer, :int32_t], :bool
    attach_function :ucol_greaterOrEqual,   "ucol_greaterOrEqual#{suffix}",   [:pointer,   :pointer,  :int32_t,  :pointer, :int32_t], :bool
    attach_function :ucol_equal,            "ucol_equal#{suffix}",            [:pointer,   :pointer,  :int32_t,  :pointer, :int32_t], :bool
    attach_function :ucol_getRules,         "ucol_getRules#{suffix}",         [:pointer,   :pointer], :pointer

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

    # http://icu-project.org/apiref/icu4c/unorm2_8h.html

    if Gem::Version.new('4.4') <= Gem::Version.new(self.version)
      enum :normalization2_mode, [ :compose, :decompose, :fcd, :compose_contiguous ]
      attach_function :unorm2_getInstance, "unorm2_getInstance#{suffix}", [:pointer, :pointer, :normalization2_mode, :pointer], :pointer
      attach_function :unorm2_normalize, "unorm2_normalize#{suffix}", [:pointer, :pointer, :int32_t, :pointer, :int32_t, :pointer], :int32_t
      attach_function :unorm2_isNormalized, "unorm2_isNormalized#{suffix}", [:pointer, :pointer, :int32_t, :pointer], :bool
    end

    #
    # Text Boundary Analysis
    #
    # http://icu-project.org/apiref/icu4c/ubrk_8h.html
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

    enum :number_format_style, [
      :pattern_decimal,
      :decimal,
      :currency,
      :percent,
      :scientific,
      :spellout,
      :ordinal,
      :duration,
      :numbering_system,
      :pattern_rule_based,
      :currency_iso,
      :currency_plural,
      :format_style_count,
      :default,
      :ignore
    ]
    enum :number_format_attribute, [
       :parse_int_only, :grouping_used, :decimal_always_show, :max_integer_digits,
       :min_integer_digits, :integer_digits, :max_fraction_digits, :min_fraction_digits,
       :fraction_digits, :multiplier, :grouping_size, :rounding_mode,
       :rounding_increment, :format_width, :padding_position, :secondary_grouping_size,
       :significant_digits_used, :min_significant_digits, :max_significant_digits, :lenient_parse
    ]
    attach_function :unum_open, "unum_open#{suffix}", [:number_format_style, :pointer, :int32_t, :string, :pointer, :pointer ], :pointer
    attach_function :unum_close, "unum_close#{suffix}", [:pointer], :void
    attach_function :unum_format_int32, "unum_format#{suffix}", [:pointer, :int32_t, :pointer, :int32_t, :pointer, :pointer], :int32_t
    attach_function :unum_format_int64, "unum_formatInt64#{suffix}", [:pointer, :int64_t, :pointer, :int32_t, :pointer, :pointer], :int32_t
    attach_function :unum_format_double, "unum_formatDouble#{suffix}", [:pointer, :double, :pointer, :int32_t, :pointer, :pointer], :int32_t
    begin
      attach_function :unum_format_decimal, "unum_formatDecimal#{suffix}", [:pointer, :string, :int32_t, :pointer, :int32_t, :pointer, :pointer], :int32_t
    rescue FFI::NotFoundError
    end
    attach_function :unum_format_currency, "unum_formatDoubleCurrency#{suffix}", [:pointer, :double, :pointer, :pointer, :int32_t, :pointer, :pointer], :int32_t
    attach_function :unum_set_attribute, "unum_setAttribute#{suffix}", [:pointer, :number_format_attribute, :int32_t], :void
    # date
    enum :date_format_style, [
      :none,  -1,
      :full,   0,
      :long,   1,
      :medium, 2,
      :short,  3,
    ]
    attach_function :udat_open, "udat_open#{suffix}", [:date_format_style, :date_format_style, :string, :pointer, :int32_t, :pointer, :int32_t, :pointer ], :pointer
    attach_function :udat_close, "unum_close#{suffix}", [:pointer], :void
    attach_function :udat_format, "udat_format#{suffix}", [:pointer, :double, :pointer, :int32_t, :pointer, :pointer], :int32_t
    attach_function :udat_parse, "udat_parse#{suffix}", [:pointer, :pointer, :int32_t,  :pointer, :pointer], :double
    attach_function :udat_toPattern, "udat_toPattern#{suffix}", [:pointer, :bool    , :pointer, :int32_t    , :pointer], :int32_t
    attach_function :udat_applyPattern, "udat_applyPattern#{suffix}", [:pointer, :bool    , :pointer, :int32_t     ], :void
    # tz
    attach_function :ucal_setDefaultTimeZone, "ucal_setDefaultTimeZone#{suffix}", [:pointer, :pointer], :int32_t
    attach_function :ucal_getDefaultTimeZone, "ucal_getDefaultTimeZone#{suffix}", [:pointer, :int32_t, :pointer], :int32_t

  end # Lib
end # ICU
