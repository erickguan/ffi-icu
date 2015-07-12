
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

      def make_formatter(time_style, date_style, locale, time_zone_str)
        time_zone = nil
        d_len = 0
        if time_zone_str
          time_zone = UCharPointer.from_string(time_zone_str)
          d_len = time_zone_str.size
        else
          Lib.check_error { | error| 
            i_len  = 150
            time_zone = UCharPointer.new(i_len)
            d_len = Lib.ucal_getDefaultTimeZone(time_zone, i_len, error) 
          }
        end

        ptr = Lib.check_error { | error| Lib.udat_open(time_style, date_style, locale, time_zone, d_len, FFI::MemoryPointer.new(4), -1, error) }
        FFI::AutoPointer.new(ptr, Lib.method(:udat_close))
      end
    end

    class DateTimeFormatter < BaseFormatter
      def initialize(options={})
        time_style = options[:time]   || :short
        date_style = options[:date]   || :short
        locale     = options[:locale] || 'C'
        tz_style   = options[:tz_style]
        time_zone  = options[:zone]
        @f = make_formatter(time_style, date_style, locale, time_zone)
        if tz_style
          f0 = date_format(true)
          f1 = update_tz_format(f0, tz_style)    
          if f1 != f0
            set_date_format(true, f1)
          end
        end
      end

      def parse(str)
          str_u = UCharPointer.from_string(str)
          str_l = str_u.size
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
        pattern     = UCharPointer.from_string(pattern_str)
        pattern_len = pattern_str.size

        Lib.check_error do |error|
          needed_length = Lib.udat_applyPattern(@f, localized, pattern, pattern_len)
        end
      end
    end # DateTimeFormatter
  end # Formatting
end # ICU
