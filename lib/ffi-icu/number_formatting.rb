require 'bigdecimal'

module ICU
  module NumberFormatting
    @default_options = {}
    
    def self.create(locale, type = :decimal, options = {})
      case type
      when :currency
        CurrencyFormatter.new(locale).set_attributes(@default_options.merge(options))
      else
        NumberFormatter.new(locale, type).set_attributes(@default_options.merge(options))
      end
    end

    def self.clear_default_options
      @default_options.clear
    end

    def self.set_default_options(options)
      @default_options.merge!(options)
    end

    def self.format_number(locale, number, options = {})
      create(locale, :decimal, options).format(number)
    end

    def self.format_percent(locale, number, options = {})
      create(locale, :percent, options).format(number)
    end

    def self.format_currency(locale, number, currency, options = {})
      create(locale, :currency, options).format(number, currency)
    end

    def self.spell(locale, number, options = {})
      create(locale, :spellout, options).format(number)
    end

    class BaseFormatter

      def set_attributes(options)
        options.each { |key, value| Lib.unum_set_attribute(@f, key, value) }
        self
      end

      private

      def make_formatter(type, locale)
        ptr = Lib.check_error { | error| Lib.unum_open(type, FFI::MemoryPointer.new(4), 0, locale, FFI::MemoryPointer.new(4), error) }
        FFI::AutoPointer.new(ptr, Lib.method(:unum_close))
      end
    end

    class NumberFormatter < BaseFormatter
      def initialize(locale, type = :decimal)
        @f = make_formatter(type, locale)
      end

      def format(number)
        needed_length = 0
        out_ptr = UCharPointer.new(needed_length)

        retried = false

        begin
          Lib.check_error do |error|
            case number
            when Float
              needed_length = Lib.unum_format_double(@f, number, out_ptr, needed_length, nil, error)
            when Fixnum
              needed_length = Lib.unum_format_int32(@f, number, out_ptr, needed_length, nil, error)
            when BigDecimal
              string_version = number.to_s('F')
              needed_length = Lib.unum_format_decimal(@f, string_version, string_version.bytesize, out_ptr, needed_length, nil, error)
            when Bignum
              needed_length = Lib.unum_format_int64(@f, number, out_ptr, needed_length, nil, error)
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
    end # NumberFormatter

    class CurrencyFormatter < BaseFormatter
      def initialize(locale)
        @f = make_formatter(:currency, locale)
      end

      def format(number, currency)
        needed_length = 0
        out_ptr = UCharPointer.new(needed_length)

        retried = false

        begin
          Lib.check_error do |error|
            needed_length = Lib.unum_format_currency(@f, number, UCharPointer.from_string(currency, 3), out_ptr, needed_length, nil, error)
          end
          out_ptr.string
        rescue BufferOverflowError
          raise BufferOverflowError, "needed: #{needed_length}" if retried
          out_ptr = out_ptr.resized_to needed_length
          retried = true
          retry
        end
      end
    end # CurrencyFormatter
  end # Formatting
end # ICU
