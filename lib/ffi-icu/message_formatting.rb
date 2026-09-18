# frozen_string_literal: true

require 'bigdecimal'

module ICU
  module MessageFormatting
    class MessageFormatError < ICU::Error
    end

    class InvalidPatternError < MessageFormatError
      attr_reader :locale, :pattern, :parse_error

      def initialize(message, locale:, pattern:, parse_error:)
        super(message)
        @locale = locale
        @pattern = pattern
        @parse_error = parse_error
      end

      def offset
        parse_error[:offset]
      end

      def line
        parse_error[:line]
      end
    end

    def self.create(pattern, locale:)
      Formatter.new(pattern, locale:)
    end

    def self.format(pattern, locale:, arguments:)
      create(pattern, locale:).format(arguments)
    end

    # rubocop:disable-next Naming/PredicateMethod
    def self.validate(pattern, locale:)
      create(pattern, locale:)
      true
    end

    def self.valid?(pattern, locale:)
      validate(pattern, locale:)
    rescue InvalidPatternError
      false
    end

    class Formatter
      attr_reader :locale, :pattern

      def initialize(pattern, locale:)
        @pattern = String(pattern)
        @locale = String(locale)
        @pattern_pointer = UCharPointer.from_utf8(@pattern)
        @formatter = open_formatter
      end

      def format(arguments = [])
        validate_argument_count!(arguments)
        typed_arguments = typed_arguments_for(arguments)
        validate_argument_types!(arguments)

        result = Lib::Util.read_uchar_buffer_as_ptr(0) do |result, status|
          Lib.umsg_format(
            @formatter,
            result,
            result.length_in_uchars,
            status,
            *typed_arguments
          )
        end
        result.utf8_string
      rescue ICU::Error => e
        raise MessageFormatError, "could not format message: #{e.message}"
      end

      private

      def open_formatter
        parse_error = Lib::UParseError.new
        status = FFI::MemoryPointer.new(:int32_t)
        status.write_int32(0)
        pointer = Lib.umsg_open(
          @pattern_pointer,
          @pattern_pointer.length_in_uchars,
          @locale,
          parse_error,
          status
        )

        error_code = status.read_int32
        return FFI::AutoPointer.new(pointer, Lib.method(:umsg_close)) unless error_code.positive?

        raise InvalidPatternError.new(
          "invalid message pattern: #{Lib.u_errorName(error_code)} " \
          "at line #{parse_error[:line]}, offset #{parse_error[:offset]}",
          locale: @locale,
          pattern: @pattern,
          parse_error: parse_error
        )
      end

      def typed_arguments_for(arguments)
        unless arguments.is_a?(Array)
          raise ArgumentError, 'MessageFormat arguments must be provided as an Array of numbered values'
        end

        arguments.flat_map do |argument|
          case argument
          when String
            [:pointer, null_terminated_uchar_pointer(argument)]
          when Integer, Float, BigDecimal
            [:double, argument.to_f]
          else
            raise ArgumentError, "unsupported MessageFormat argument type: #{argument.class}"
          end
        end
      end

      def validate_argument_count!(arguments)
        unless arguments.is_a?(Array)
          raise ArgumentError, 'MessageFormat arguments must be provided as an Array of numbered values'
        end

        highest_argument = argument_types.keys.max
        required_count = highest_argument ? highest_argument + 1 : 0
        return if arguments.length >= required_count

        raise ArgumentError, "MessageFormat pattern requires at least #{required_count} numbered arguments"
      end

      # Maps each numbered argument in the pattern to its ICU type keyword
      # (e.g. "plural", "select", "number") or nil for a simple argument.
      def argument_types
        types = {}
        quoted = false
        chars = @pattern.each_char.to_a
        index = 0

        while index < chars.length
          if chars[index] == "'"
            if chars[index + 1] == "'"
              index += 2
              next
            elsif quoted
              quoted = false
            elsif ['{', '}', '#'].include?(chars[index + 1])
              quoted = true
            end
          elsif chars[index] == '{' && !quoted
            index += 1
            index += 1 while index < chars.length && chars[index].match?(/\s/)
            start = index
            index += 1 while index < chars.length && chars[index].match?(/\d/)
            next if index == start

            arg_number = chars[start...index].join.to_i
            index += 1 while index < chars.length && chars[index].match?(/\s/)

            if chars[index] == '}'
              types[arg_number] = nil unless types.key?(arg_number)
            elsif chars[index] == ','
              index += 1
              index += 1 while index < chars.length && chars[index].match?(/\s/)
              type_start = index
              index += 1 while index < chars.length && chars[index].match?(/[A-Za-z]/)
              type = chars[type_start...index].join.downcase
              types[arg_number] = (type.empty? ? nil : type) unless types.key?(arg_number)
            end
          end
          index += 1
        end

        types
      end

      def validate_argument_types!(arguments)
        types = argument_types
        arguments.each_with_index do |argument, index|
          next unless types.key?(index)

          case expected_kind_for(types[index])
          when :string
            unless argument.is_a?(String)
              raise ArgumentError,
                    "MessageFormat argument #{index} expects a String, got #{argument.class}"
            end
          when :number
            unless [Integer, Float, BigDecimal].any? { |klass| argument.is_a?(klass) }
              raise ArgumentError,
                    "MessageFormat argument #{index} expects a numeric value, got #{argument.class}"
            end
          end
        end
      end

      # ICU reads each argument slot from the vararg list according to the
      # pattern: simple and select arguments read a UChar*, while number,
      # date, time, choice, plural, and selectordinal read a double.
      def expected_kind_for(type)
        case type
        when 'number', 'date', 'time', 'choice', 'plural', 'selectordinal' then :number
        else :string
        end
      end

      def null_terminated_uchar_pointer(string)
        pointer = UCharPointer.from_utf8(string)
        terminated = UCharPointer.new(pointer.length_in_uchars + 1)
        terminated.put_bytes(0, pointer.get_bytes(0, pointer.size))
        terminated.put_uint16(pointer.size, 0)
        terminated
      end
    end
  end
end
