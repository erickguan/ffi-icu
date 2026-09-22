module ICU
  class Currency
    CURRENCY_TYPE_COMMON         = 1
    CURRENCY_TYPE_UNCOMMON       = 2
    CURRENCY_TYPE_DEPRECATED     = 4
    CURRENCY_TYPE_NON_DEPRECATED = 8
    CURRENCY_TYPE_ALL = (2**31) - 1

    class << self
      # Returns the default currency code for a locale, e.g. "USD" for "en_US"
      def for_locale(locale)
        ptr = UCharPointer.new(4)
        length = Lib.check_error do |status|
          Lib.ucurr_forLocale(locale.to_s, ptr, 4, status)
        end
        ptr.string(length)
      end

      # Returns an array of ISO 4217 currency code strings.
      # currency_type: :all (default), :common, :uncommon, :deprecated, :non_deprecated
      def available(currency_type = :all)
        flag = case currency_type
               when :common         then CURRENCY_TYPE_COMMON
               when :uncommon       then CURRENCY_TYPE_UNCOMMON
               when :deprecated     then CURRENCY_TYPE_DEPRECATED
               when :non_deprecated then CURRENCY_TYPE_NON_DEPRECATED
               else CURRENCY_TYPE_ALL
               end

        enum_ptr = Lib.check_error { |status| Lib.ucurr_openISOCurrencies(flag, status) }
        begin
          Lib.enum_ptr_to_array(enum_ptr)
        ensure
          Lib.uenum_close(enum_ptr)
        end
      end

      # Convenience: ICU::Currency.symbol('USD', 'en_US') => "$"
      def symbol(code, locale)
        new(code).symbol(locale)
      end

      # Convenience: ICU::Currency.name('USD', 'en') => "US Dollar"
      def name(code, locale)
        new(code).name(locale)
      end
    end

    attr_reader :code

    def initialize(code)
      @code = code.to_s.upcase
    end

    # Currency symbol for the given locale, e.g. "$", "€"
    def symbol(locale)
      get_name(locale, :symbol_name)
    end

    # Narrow (shortest unambiguous) symbol. Requires ICU >= 61.
    def narrow_symbol(locale)
      raise(Error, 'narrow_symbol requires ICU >= 61') if Lib.version.to_a.first < 61

      get_name(locale, :narrow_symbol_name)
    end

    # Long display name for the given locale, e.g. "US Dollar"
    def name(locale)
      get_name(locale, :long_name)
    end

    # Plural form of the currency name.
    # plural_count: "zero", "one", "two", "few", "many", "other"
    def plural_name(locale, plural_count = 'other')
      raise(Error, 'plural_name requires ICU >= 4.2') unless Lib.respond_to?(:ucurr_getPluralName)

      is_choice = FFI::MemoryPointer.new(:uint8)
      len       = FFI::MemoryPointer.new(:int32_t)

      ptr = Lib.check_error do |status|
        Lib.ucurr_getPluralName(currency_uchar, locale.to_s, is_choice, plural_count.to_s, len, status)
      end
      ptr.read_array_of_uint16(len.read_int32).pack('U*')
    end

    # Number of decimal digits used when displaying this currency.
    # usage: :standard (default) or :cash
    def fraction_digits(usage = :standard)
      if usage == :cash && Lib.respond_to?(:ucurr_getDefaultFractionDigitsForUsage)
        Lib.check_error { |status| Lib.ucurr_getDefaultFractionDigitsForUsage(currency_uchar, :cash, status) }
      else
        Lib.check_error { |status| Lib.ucurr_getDefaultFractionDigits(currency_uchar, status) }
      end
    end

    # ISO 4217 numeric code, e.g. 840 for USD. Requires ICU >= 49.
    def numeric_code
      raise(Error, 'numeric_code requires ICU >= 49') unless Lib.respond_to?(:ucurr_getNumericCode)

      Lib.ucurr_getNumericCode(currency_uchar)
    end

    def to_s
      @code
    end

    private

    def currency_uchar
      UCharPointer.from_string(@code, 4)
    end

    def get_name(locale, style)
      is_choice = FFI::MemoryPointer.new(:uint8)
      len       = FFI::MemoryPointer.new(:int32_t)

      ptr = Lib.check_error do |status|
        Lib.ucurr_getName(currency_uchar, locale.to_s, style, is_choice, len, status)
      end
      ptr.read_array_of_uint16(len.read_int32).pack('U*')
    end
  end
end
