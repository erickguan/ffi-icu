module ICU
  class Locale
    class << self
      def available
        (0...Lib.uloc_countAvailable).map do |idx|
          Locale.new(Lib.uloc_getAvailable(idx))
        end
      end

      def default
        Locale.new(Lib.uloc_getDefault)
      end

      def default=(locale)
        Lib.check_error { |status| Lib.uloc_setDefault(locale.to_s, status) }
      end

      def for_language_tag(tag)
        result = Lib::Util.read_string_buffer(64) do |buffer, status|
          Lib.uloc_forLanguageTag(tag, buffer, buffer.size, nil, status)
        end

        Locale.new(result)
      end

      def for_lcid(id)
        result = Lib::Util.read_string_buffer(64) do |buffer, status|
          Lib.uloc_getLocaleForLCID(id, buffer, buffer.size, status)
        end

        Locale.new(result)
      end

      def iso_countries
        Lib::Util.read_null_terminated_array_of_strings(Lib.uloc_getISOCountries)
      end

      def iso_languages
        Lib::Util.read_null_terminated_array_of_strings(Lib.uloc_getISOLanguages)
      end
    end

    attr_reader :id

    DISPLAY_CONTEXT = {
      length_full:  512, # UDISPCTX_LENGTH_FULL  = (UDISPCTX_TYPE_DISPLAY_LENGTH<<8) + 0
      length_short: 513  # UDISPCTX_LENGTH_SHORT = (UDISPCTX_TYPE_DISPLAY_LENGTH<<8) + 1
    }

    def initialize(id)
      @id = id.to_s
    end

    def ==(other)
      other.is_a?(self.class) && other.id == self.id
    end

    def base_name
      Lib::Util.read_string_buffer(64) do |buffer, status|
        Lib.uloc_getBaseName(@id, buffer, buffer.size, status)
      end
    end

    def canonical
      Lib::Util.read_string_buffer(64) do |buffer, status|
        Lib.uloc_canonicalize(@id, buffer, buffer.size, status)
      end
    end

    def character_orientation
      Lib.check_error { |status| Lib.uloc_getCharacterOrientation(@id, status) }
    end

    def country
      Lib::Util.read_string_buffer(64) do |buffer, status|
        Lib.uloc_getCountry(@id, buffer, buffer.size, status)
      end
    end

    def display_country(locale = nil)
      locale = locale.to_s unless locale.nil?

      Lib::Util.read_uchar_buffer(256) do |buffer, status|
        Lib.uloc_getDisplayCountry(@id, locale, buffer, buffer.size, status)
      end
    end

    def display_language(locale = nil)
      locale = locale.to_s unless locale.nil?

      Lib::Util.read_uchar_buffer(192) do |buffer, status|
        Lib.uloc_getDisplayLanguage(@id, locale, buffer, buffer.size, status)
      end
    end

    def display_name(locale = nil)
      locale = locale.to_s unless locale.nil?

      Lib::Util.read_uchar_buffer(256) do |buffer, status|
        Lib.uloc_getDisplayName(@id, locale, buffer, buffer.size, status)
      end
    end

    def display_name_with_context(locale, contexts = [])
      contexts = DISPLAY_CONTEXT.select { |context| contexts.include?(context) }.values

      with_locale_display_name(@id, contexts) do |locale_display_names|
        Lib::Util.read_uchar_buffer(256) do |buffer, status|
          Lib.uldn_localeDisplayName(locale_display_names, locale, buffer, buffer.size, status)
        end
      end
    end

    def display_script(locale = nil)
      locale = locale.to_s unless locale.nil?

      Lib::Util.read_uchar_buffer(128) do |buffer, status|
        Lib.uloc_getDisplayScript(@id, locale, buffer, buffer.size, status)
      end
    end

    def display_variant(locale = nil)
      locale = locale.to_s unless locale.nil?

      Lib::Util.read_uchar_buffer(64) do |buffer, status|
        Lib.uloc_getDisplayVariant(@id, locale, buffer, buffer.size, status)
      end
    end

    def iso_country
      Lib.uloc_getISO3Country(@id)
    end

    def iso_language
      Lib.uloc_getISO3Language(@id)
    end

    def keyword(keyword)
      Lib::Util.read_string_buffer(64) do |buffer, status|
        Lib.uloc_getKeywordValue(@id, keyword.to_s, buffer, buffer.size, status)
      end
    end

    def keywords
      enum_ptr = Lib.check_error { |status| Lib.uloc_openKeywords(@id, status) }

      begin
        Lib.enum_ptr_to_array(enum_ptr)
      ensure
        Lib.uenum_close(enum_ptr)
      end
    end

    def language
      Lib::Util.read_string_buffer(64) do |buffer, status|
        Lib.uloc_getLanguage(@id, buffer, buffer.size, status)
      end
    end

    def lcid
      Lib.uloc_getLCID(@id)
    end

    def line_orientation
      Lib.check_error { |status| Lib.uloc_getLineOrientation(@id, status) }
    end

    def name
      Lib::Util.read_string_buffer(64) do |buffer, status|
        Lib.uloc_getName(@id, buffer, buffer.size, status)
      end
    end

    def parent
      Lib::Util.read_string_buffer(64) do |buffer, status|
        Lib.uloc_getParent(@id, buffer, buffer.size, status)
      end
    end

    def script
      Lib::Util.read_string_buffer(64) do |buffer, status|
        Lib.uloc_getScript(@id, buffer, buffer.size, status)
      end
    end

    def to_language_tag(strict = false)
      Lib::Util.read_string_buffer(64) do |buffer, status|
        Lib.uloc_toLanguageTag(@id, buffer, buffer.size, strict ? 1 : 0, status)
      end
    end

    alias_method :to_s, :id

    def variant
      Lib::Util.read_string_buffer(64) do |buffer, status|
        Lib.uloc_getVariant(@id, buffer, buffer.size, status)
      end
    end

    def with_keyword(keyword, value)
      keyword = keyword.to_s
      length = @id.length + keyword.length + 64

      unless value.nil?
        value = value.to_s
        length += value.length
      end

      result = Lib::Util.read_string_buffer(length) do |buffer, status|
        buffer.write_string(@id)
        Lib.uloc_setKeywordValue(keyword, value, buffer, buffer.size, status)
      end

      Locale.new(result)
    end

    def with_keywords(hash)
      hash.reduce(self) do |locale, (keyword, value)|
        locale.with_keyword(keyword, value)
      end
    end

    def with_likely_subtags
      result = Lib::Util.read_string_buffer(64) do |buffer, status|
        Lib.uloc_addLikelySubtags(@id, buffer, buffer.size, status)
      end

      Locale.new(result)
    end

    def with_minimized_subtags
      result = Lib::Util.read_string_buffer(64) do |buffer, status|
        Lib.uloc_minimizeSubtags(@id, buffer, buffer.size, status)
      end

      Locale.new(result)
    end

    def with_locale_display_name(locale, contexts)
      pointer = FFI::MemoryPointer.new(:int, contexts.length).write_array_of_int(contexts)
      locale_display_names = ICU::Lib.check_error { |status| ICU::Lib.uldn_openForContext(locale, pointer, contexts.length, status) }

      yield locale_display_names
    ensure
      Lib.uldn_close(locale_display_names) if locale_display_names
    end
  end
end
