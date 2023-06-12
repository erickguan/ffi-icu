require 'date'

module ICU
  module TimeFormatting
    TZ_MAP = {
      :generic_location =>   'VVVV',# The generic location format.
                                    #   Where that is unavailable, falls back to the long localized GMT format ("OOOO";
                                    #   Note: Fallback is only necessary with a GMT-style Time Zone ID, like Etc/GMT-830.),
                                    #   This is especially useful when presenting possible timezone choices for user selection,
                                    #   since the naming is more uniform than the "v" format.
                                    #   such as "United States Time (New York)", "Italy Time"
      :generic_long     =>  'vvvv', # The long generic non-location format.
                                    #   Where that is unavailable, falls back to generic location format ("VVVV")., such as "Eastern Time".
      :generic_short    =>     'v', # The short generic non-location format.
                                    #   Where that is unavailable, falls back to the generic location format ("VVVV"),
                                    #   then the short localized GMT format as the final fallback., such as "ET".
      :specific_long    =>  'zzzz', # The long specific non-location format.
                                    #   Where that is unavailable, falls back to the long localized GMT format ("OOOO").
      :specific_short   =>     'z', # The short specific non-location format.
                                    #   Where that is unavailable, falls back to the short localized GMT format ("O").
      :basic            =>     'Z', # The ISO8601 basic format with hours, minutes and optional seconds fields.
                                    #   The format is equivalent to RFC 822 zone format (when optional seconds field is absent).
                                    #   This is equivalent to the "xxxx" specifier.
      :localized_long   =>  'ZZZZ', # The long localized GMT format. This is equivalent to the "OOOO" specifier, such as GMT-8:00
      :extended         => 'ZZZZZ', # The ISO8601 extended format with hours, minutes and optional seconds fields.
                                    #   The ISO8601 UTC indicator "Z" is used when local time offset is 0.
                                    #   This is equivalent to the "XXXXX" specifier, such as -08:00 -07:52:58
      :localized_short  =>    'O',  # The short localized GMT format, such as GMT-8
      :localized_longO  => 'OOOO',  # The long localized GMT format, such as GMT-08:00
      :tz_id_short      =>    'V',  # The short time zone ID. Where that is unavailable,
                                    #   the special short time zone ID unk (Unknown Zone) is used.
                                    #   Note: This specifier was originally used for a variant of the short specific non-location format,
                                    #   but it was deprecated in the later version of this specification. In CLDR 23, the definition
                                    #   of the specifier was changed to designate a short time zone ID, such as uslax
      :tz_id_long       =>   'VV',  # The long time zone ID, such as America/Los_Angeles
      :city_location    =>  'VVV',  # The exemplar city (location) for the time zone. Where that is unavailable,
                                    #   the localized exemplar city name for the special zone Etc/Unknown is used as the fallback
                                    #   (for example, "Unknown City"), such as Los Angeles
      # see: http://unicode.org/reports/tr35/tr35-dates.html#Date_Format_Patterns
    }

    HOUR_CYCLE_SYMS = {
      'h11' => 'K',
      'h12' => 'h',
      'h23' => 'H',
      'h24' => 'k',
      :locale => 'j',
    }
    @default_options = {}
    
    def self.create(options = {})
      DateTimeFormatter.new(@default_options.merge(options))
    end

    def self.clear_default_options
      @default_options.clear
    end

    def self.set_default_options(options)
      @default_options.merge!(options)
    end

    def self.format(dt, options = {})
      create(@default_options.merge(options)).format(dt)
    end

    class BaseFormatter

      def set_attributes(options)
        options.each { |key, value| Lib.unum_set_attribute(@f, key, value) }
        self
      end

      private

      def make_formatter(time_style, date_style, locale, time_zone_str, skeleton)
        time_zone   = nil
        tz_len      = 0
        pattern_len = -1
        pattern_ptr = FFI::MemoryPointer.new(4)

        if time_zone_str
          time_zone = UCharPointer.from_string(time_zone_str)
          tz_len = time_zone_str.size
        else
          Lib.check_error { | error| 
            i_len  = 150
            time_zone = UCharPointer.new(i_len)
            tz_len = Lib.ucal_getDefaultTimeZone(time_zone, i_len, error) 
          }
        end

        if skeleton
          date_style = :pattern
          time_style = :pattern

          pattern_len, pattern_ptr = skeleton_format(skeleton, locale)
        end

        ptr = Lib.check_error { | error| Lib.udat_open(time_style, date_style, locale, time_zone, tz_len, pattern_ptr, pattern_len, error) }
        FFI::AutoPointer.new(ptr, Lib.method(:udat_close))
      end
    end

    class DateTimeFormatter < BaseFormatter
      def initialize(options={})
        time_style  = options[:time]   || :short
        date_style  = options[:date]   || :short
        @locale     = options[:locale] || 'C'
        tz_style    = options[:tz_style]
        time_zone   = options[:zone]
        skeleton    = options[:skeleton]
        @hour_cycle = options[:hour_cycle]

        if @hour_cycle && !HOUR_CYCLE_SYMS.keys.include?(@hour_cycle)
          raise ICU::Error.new("Unknown hour cycle #{@hour_cycle}")
        end

        @f = make_formatter(time_style, date_style, @locale, time_zone, skeleton)
        if tz_style
          f0 = date_format(true)
          f1 = update_tz_format(f0, tz_style)    
          if f1 != f0
            set_date_format(true, f1)
          end
        end

        replace_hour_symbol!
      end

      def parse(str)
          str_u = UCharPointer.from_string(str)
          str_l = str.size
          Lib.check_error do |error|
            ret = Lib.udat_parse(@f, str_u, str_l, nil, error)
            Time.at(ret / 1000.0)
          end
      end

      def format(dt)
        needed_length = 0
        out_ptr = UCharPointer.new(needed_length)

        retried = false

        begin
          Lib.check_error do |error|
            case dt
            when Date
              needed_length = Lib.udat_format(@f, Time.mktime( dt.year, dt.month, dt.day, 0, 0, 0, 0 ).to_f * 1000.0, out_ptr, needed_length, nil, error)
            when Time
              needed_length = Lib.udat_format(@f, dt.to_f * 1000.0, out_ptr, needed_length, nil, error)
            end
          end

          out_ptr.string
        rescue BufferOverflowError
          raise BufferOverflowError, "needed: #{needed_length}" if retried
          out_ptr = out_ptr.resized_to needed_length
          retried = true
          retry
        end
      end

      # time-zone formating
      def update_tz_format(format, tz_style)
        return format if format !~ /(.*?)(\s*(?:[zZOVV]+\s*))(.*?)/
        pre, tz, suff = $1, $2, $3
        if tz_style == :none
          tz = ((tz =~ /\s/) && !pre.empty? && !suff.empty?) ? ' ' : ''
        else
          repl = TZ_MAP[tz_style]
          raise 'no such tz_style' unless repl
          tz.gsub!(/^(\s*)(.*?)(\s*)$/, '\1'+repl+'\3')
        end
        pre + tz + suff
      end

      def date_format(localized=true)
        needed_length = 0
        out_ptr = UCharPointer.new(needed_length)

        retried = false

        begin
          Lib.check_error do |error|
            needed_length = Lib.udat_toPattern(@f, localized, out_ptr, needed_length, error)
          end

          out_ptr.string
        rescue BufferOverflowError
          raise BufferOverflowError, "needed: #{needed_length}" if retried
          out_ptr = out_ptr.resized_to needed_length
          retried = true
          retry
        end
      end

      def set_date_format(localized, pattern_str)
        set_date_format_impl(localized, pattern_str)

        # After setting the date format string, we need to ensure that any hour
        # symbols were properly localised according to @hour_cycle.
        replace_hour_symbol!
      end

      def skeleton_format(skeleton_pattern_str, locale)
          skeleton_pattern_ptr = UCharPointer.from_string(skeleton_pattern_str)
          skeleton_pattern_len = skeleton_pattern_str.size

          needed_length = 0
          pattern_ptr = UCharPointer.new(needed_length)

          udatpg_ptr = Lib.check_error { |error| Lib.udatpg_open(locale, error) }
          generator = FFI::AutoPointer.new(udatpg_ptr, Lib.method(:udatpg_close))

          retried = false

        begin
          Lib.check_error do |error|
            needed_length = Lib.udatpg_getBestPattern(generator, skeleton_pattern_ptr, skeleton_pattern_len, pattern_ptr, needed_length, error)
          end

          return needed_length, pattern_ptr
        rescue BufferOverflowError
          raise BufferOverflowError, "needed: #{needed_length}" if retried
          pattern_ptr = pattern_ptr.resized_to needed_length
          retried = true
          retry
        end
      end

      private

      # Converts the current pattern to a pattern that takes the desired hour cycle
      # into account. This is needed because most of the standard patterns in ICU
      # contain either h (12 hour) or H (23 hour) in them, instead of j (locale-
      # specified hour cycle). This means if you use a locale with an @hours=h12
      # keyword in it, for example, it would normally be totally ignored by ICU.
      #
      # This is the same fixup done by Firefox:
      # https://github.com/tc39/ecma402/issues/665#issuecomment-1084833809
      # https://searchfox.org/mozilla-central/rev/625c3d0c8ae46502aed83f33bd530cb93e926e9f/intl/components/src/DateTimeFormat.cpp#282-323
      def replace_hour_symbol!
        # Short circuit this case - nil means "use whatever is in the pattern already", so
        # no need to actually run any of this implementation.
        return unless @hour_cycle

        # Get the current pattern and convert to a skeleton
        skeleton_str = pattern_to_skeleton_uchar(current_pattern_as_uchar).string

        # Manipulate the skeleton to make it work with the correct hour cycle.
        skeleton_str.gsub!(/[hHkKjJ]/, HOUR_CYCLE_SYMS[@hour_cycle])

        # Either ensure the skeleton has, or does not have, am/pm, as appropriate
        if ['h11', 'h12'].include?(@hour_cycle)
          # Only actually append 'am/pm' if there is an hour in the format string
          if skeleton_str =~ /[hHkKjJ]/ && !skeleton_str.include?('a')
            skeleton_str << 'a'
          end
        else
          skeleton_str.gsub!('a', '')
        end

        # Convert the skeleton back to a pattern
        new_pattern_str = skeleton_to_pattern_uchar(UCharPointer.from_string(skeleton_str)).string

        # We also need to manipulate the _pattern_, a little bit, because (according to Firefox source):
        #
        #     Input skeletons don't differentiate between "K" and "h" resp. "k" and "H".
        #
        # https://searchfox.org/mozilla-central/rev/625c3d0c8ae46502aed83f33bd530cb93e926e9f/intl/components/src/DateTimeFormat.cpp#183
        # So, if we put a skeleton with a k in it into getBestPattern, it comes out with a H (and a
        # skeleton with a K in it comes out with a h). Need to fix this in the generated pattern.
        resolved_hour_cycle = @hour_cycle == :locale ? Locale.new(@locale).keyword('hours') : @hour_cycle

        if HOUR_CYCLE_SYMS.keys.include?(resolved_hour_cycle)
          new_pattern_str.gsub!(/[hHkK](?=(?:[^\']|\'[^\']*\')*$)/, HOUR_CYCLE_SYMS[resolved_hour_cycle])
        end

        # Finally, set the new pattern onto the date time formatter
        set_date_format_impl(false, new_pattern_str)
      end

      # Load up the date formatter locale and make a generator
      # Note that we _MUST_ actually use @locale as passed to us, rather than calling
      # udat_getLocaleByType to look it up from @f, because the latter will throw away
      # any @hours specifier in the locale, and we need it.
      def datetime_pattern_generator
        @datetime_pattern_generator ||= FFI::AutoPointer.new(
          Lib.check_error { |error| Lib.udatpg_open(@locale, error) },
          Lib.method(:udatpg_close)
        )
      end

      def current_pattern_as_uchar
        Lib::Util.read_uchar_buffer_as_ptr(0) do |buf, error|
          Lib.udat_toPattern(@f, false, buf, buf.length_in_uchars, error)
        end
      end

      def pattern_to_skeleton_uchar(pattern_uchar)
        Lib::Util.read_uchar_buffer_as_ptr(0) do |buf, error|
          Lib.udatpg_getSkeleton(
            datetime_pattern_generator,
            pattern_uchar, pattern_uchar.length_in_uchars,
            buf, buf.length_in_uchars,
            error
          )
        end
      end

      def skeleton_to_pattern_uchar(skeleton_uchar)
        Lib::Util.read_uchar_buffer_as_ptr(0) do |buf, error|
          Lib.udatpg_getBestPattern(
            datetime_pattern_generator,
            skeleton_uchar, skeleton_uchar.length_in_uchars,
            buf, buf.length_in_uchars,
            error
          )
        end
      end

      def set_date_format_impl(localized, pattern_str)
        pattern     = UCharPointer.from_string(pattern_str)
        pattern_len = pattern_str.size

        Lib.check_error do |error|
          needed_length = Lib.udat_applyPattern(@f, localized, pattern, pattern_len)
        end
      end
    end # DateTimeFormatter
  end # Formatting
end # ICU
