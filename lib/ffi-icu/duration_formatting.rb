# frozen_string_literal: true

require 'stringio'

module ICU
  module DurationFormatting
    VALID_FIELDS = [
      :years,
      :months,
      :weeks,
      :days,
      :hours,
      :minutes,
      :seconds,
      :milliseconds,
      :microseconds,
      :nanoseconds
    ].freeze

    HMS_FIELDS = [
      :hours,
      :minutes,
      :seconds,
      :milliseconds,
      :microseconds,
      :nanoseconds
    ].freeze

    ROUNDABLE_FIELDS = [
      :seconds,
      :milliseconds,
      :microseconds,
      :nanoseconds
    ].freeze

    VALID_STYLES = [:long, :short, :narrow, :digital].freeze

    STYLES_TO_LIST_JOIN_FORMAT = {
      :long => :wide,
      :short => :short,
      :narrow => :narrow,
      :digital => :narrow
    }.freeze

    UNIT_FORMAT_STRINGS = {
      :years => 'measure-unit/duration-year',
      :months => 'measure-unit/duration-month',
      :weeks => 'measure-unit/duration-week',
      :days => 'measure-unit/duration-day',
      :hours => 'measure-unit/duration-hour',
      :minutes => 'measure-unit/duration-minute',
      :seconds => 'measure-unit/duration-second',
      :milliseconds => 'measure-unit/duration-millisecond',
      :microseconds => 'measure-unit/duration-microsecond',
      :nanoseconds => 'measure-unit/duration-nanosecond'
    }.freeze

    STYLES_TO_NUMBER_FORMAT_WIDTH = {
      :long => 'unit-width-full-name',
      :short => 'unit-width-short',
      :narrow => 'unit-width-narrow',
      # digital for hours:minutes:seconds has some special casing.
      :digital => 'unit-width-narrow'
    }.freeze

    def self.format(fields, locale:, style: :long)
      DurationFormatter.new(locale: locale, style: style).format(fields)
    end

    class DurationFormatter
      def initialize(locale:, style: :long)
        if !Lib.respond_to?(:unumf_openForSkeletonAndLocale) || !Lib.respond_to?(:ulistfmt_openForType)
          raise('ICU::DurationFormatting requires ICU >= 67')
        end

        raise(ArgumentError, "Unknown style #{style}") unless VALID_STYLES.include?(style)

        @locale = locale
        @style = style
        # These are created lazily based on what parts are actually included
        @number_formatters = {}

        list_join_format = STYLES_TO_LIST_JOIN_FORMAT.fetch(style)
        @list_formatter = FFI::AutoPointer.new(
          Lib.check_error do |error|
            Lib.ulistfmt_openForType(@locale, :units, list_join_format, error)
          end,
          Lib.method(:ulistfmt_close)
        )
      end

      def format(fields)
        fields.each_key do |field|
          raise("Unknown field #{field}") unless VALID_FIELDS.include?(field)
        end
        fields = fields.dup # we might modify this argument.

        # Intl.js spec says that rounding options affect only the smallest unit, and only
        # if that unit is sub-second. All other fields therefore need to be truncated.
        smallest_unit = VALID_FIELDS[fields.keys.map { |k| VALID_FIELDS.index(k) }.max]
        fields.each_key do |k|
          raise(ArgumentError, 'Negative durations are not yet supported') if (fields[k]).negative?

          fields[k] = fields[k].to_i unless k == smallest_unit && ROUNDABLE_FIELDS.include?(smallest_unit)
        end

        formatted_hms = nil
        if @style == :digital
          # icu::MeasureFormat contains special casing for hours/minutes/seconds formatted
          # at numeric width, to render it as h:mm:s, essentially. This involves using
          # a pattern called durationUnits defined in the ICU data for the locale.
          # If we have data for this combination of hours/mins/seconds in this locale,
          # use that and emulate ICU's special casing.
          formatted_hms = format_hms(fields)
          if formatted_hms
            # We've taken care of all these fields now.
            HMS_FIELDS.each do |f|
              fields.delete(f)
            end
          end
        end

        formatted_fields = VALID_FIELDS.map do |f|
          next unless fields.key?(f)
          next unless fields[f] != 0

          format_number(fields[f], [
            UNIT_FORMAT_STRINGS[f], STYLES_TO_NUMBER_FORMAT_WIDTH[@style],
            ('.#########' if f == smallest_unit)
          ].compact.join(' '))
        end
        formatted_fields << formatted_hms
        formatted_fields.compact!

        format_list(formatted_fields)
      end

      private

      def hms_duration_units_pattern(fields)
        return nil unless HMS_FIELDS.any? { |k| fields.key?(k) }

        @unit_res_bundle ||= FFI::AutoPointer.new(
          Lib.check_error { |error| Lib.ures_open(Lib.resource_bundle_name(:unit), @locale, error) },
          Lib.method(:ures_close)
        )

        resource_key_builder = StringIO.new
        resource_key_builder.write('durationUnits/')
        resource_key_builder.putc('h') if fields.key?(:hours)
        resource_key_builder.putc('m') if fields.key?(:minutes)
        if [:seconds, :milliseconds, :microseconds, :nanoseconds].any? { |f| fields.key?(f) }
          resource_key_builder.putc('s')
        end

        resource_key = resource_key_builder.string

        begin
          pattern_resource = FFI::AutoPointer.new(
            Lib.check_error do |error|
              Lib.ures_getBykeyWithFallback(@unit_res_bundle, resource_key, nil, error)
            end,
            Lib.method(:ures_close)
          )
        rescue MissingResourceError
          # This combination of h,m,s not present for this locale.
          return nil
        end
        # Read the resource as a UChar (whose memory we _do not own_ - it's static data) and
        # convert it to a Ruby string.
        pattern_uchar_len = FFI::MemoryPointer.new(:int32_t)
        pattern_uchar = Lib.check_error do |error|
          Lib.ures_getString(pattern_resource, pattern_uchar_len, error)
        end
        pattern_str = pattern_uchar.read_array_of_uint16(pattern_uchar_len.read_int32).pack('U*')

        # For some reason I can't comprehend, loadNumericDateFormatterPattern in ICU wants to turn
        # h's into H's here. I guess we have to do it too because the pattern data could in theory
        # now contain either.
        pattern_str.gsub('h', 'H')
      end

      def format_hms(fields)
        pattern = hms_duration_units_pattern(fields)
        return nil if pattern.nil?

        # According to the Intl.js spec, when formatting in digital, everything < seconds
        # should be coalesced into decimal seconds
        seconds_incl_fractional = fields.fetch(:seconds, 0)
        second_precision = 0
        if fields.key?(:milliseconds)
          seconds_incl_fractional += fields[:milliseconds] / 1e3
          second_precision = 3
        end
        if fields.key?(:microseconds)
          seconds_incl_fractional += fields[:microseconds] / 1e6
          second_precision = 6
        end
        if fields.key?(:nanoseconds)
          seconds_incl_fractional += fields[:nanoseconds] / 1e9
          second_precision = 9
        end

        # Follow the rules in ICU measfmt.cpp formatNumeric to fill in the patterns here with
        # the appropriate values.
        enum = pattern.each_char
        protect = false
        result = StringIO.new
        loop do
          char = enum.next
          next_char = begin
            enum.peek
          rescue StandardError
            nil
          end

          if protect
            # In literal mode
            if char == "'"
              protect = false
              next
            end
            result.write(char)
            next
          end

          value = case char
                  when 'H' then fields[:hours]
                  when 'm' then fields[:minutes]
                  when 's' then seconds_incl_fractional
                  end

          case char
          when 'H', 'm', 's'
            skeleton_builder = StringIO.new
            skeleton_builder.write('.')
            if char == 's' && second_precision.positive?
              skeleton_builder.write('0' * second_precision)
            else
              skeleton_builder.write('#' * 9)
            end
            if char == next_char
              # It's doubled - means format it at zero fill
              skeleton_builder.write(' integer-width/00')
              enum.next
            end
            skeleton = skeleton_builder.string
            result.write(format_number(value, skeleton))
          when "'"
            if next_char == char
              # double-apostrophe, means literal '
              result.write("'")
              enum.next
            else
              protect = true
            end
          else
            result.write(char)
          end
        end

        result.string
      end

      def number_formatter(skeleton)
        @number_formatters[skeleton] ||= begin
          skeleton_uchar = UCharPointer.from_string(skeleton)
          FFI::AutoPointer.new(
            Lib.check_error do |error|
              Lib.unumf_openForSkeletonAndLocale(skeleton_uchar, skeleton_uchar.length_in_uchars,
                                                 @locale, error)
            end,
            Lib.method(:unumf_close)
          )
        end
      end

      def format_number(value, skeleton)
        formatter = number_formatter(skeleton)
        result = FFI::AutoPointer.new(
          Lib.check_error { |error| Lib.unumf_openResult(error) },
          Lib.method(:unumf_closeResult)
        )
        value_str = value.to_s
        Lib.check_error do |error|
          Lib.unumf_formatDecimal(formatter, value_str, value_str.size, result, error)
        end
        Lib::Util.read_uchar_buffer(0) do |buf, error|
          Lib.unumf_resultToString(result, buf, buf.length_in_uchars, error)
        end
      end

      def format_list(values)
        value_uchars = values.map(&UCharPointer.method(:from_string))
        value_uchars_array = FFI::MemoryPointer.new(:pointer, value_uchars.size)
        value_uchars_array.put_array_of_pointer(0, value_uchars)
        value_lengths_array = FFI::MemoryPointer.new(:int32_t, value_uchars.size)
        value_lengths_array.put_array_of_int32(0, value_uchars.map(&:length_in_uchars))
        Lib::Util.read_uchar_buffer(0) do |buf, error|
          Lib.ulistfmt_format(
            @list_formatter, value_uchars_array, value_lengths_array,
            value_uchars.size, buf, buf.length_in_uchars, error
          )
        end
      end
    end
  end
end
