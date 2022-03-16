require 'bigdecimal'

module ICU
  module NumberFormatting
    @default_options = {}
    
    def self.create(locale, type = :decimal, options = {})
      case type
      when :currency
        CurrencyFormatter.new(locale, options.delete(:style)).set_attributes(@default_options.merge(options))
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
            when Integer
              begin
                # Try doing it fast, for integers that can be marshaled into an int64_t
                needed_length = Lib.unum_format_int64(@f, number, out_ptr, needed_length, nil, error)
              rescue RangeError
                # Fall back to stringifying in Ruby and passing that to ICU
                unless defined? Lib.unum_format_decimal
                  raise RangeError,"Number #{number} is too big to fit in int64_t and your "\
                                    "ICU version is too old to have unum_format_decimal"
                end
                string_version = number.to_s
                needed_length = Lib.unum_format_decimal(@f, string_version, string_version.bytesize, out_ptr, needed_length, nil, error)
              end
            when BigDecimal
              string_version = number.to_s('F')
              if Lib.respond_to? :unum_format_decimal
                needed_length = Lib.unum_format_decimal(@f, string_version, string_version.bytesize, out_ptr, needed_length, nil, error)
              else
                needed_length = Lib.unum_format_double(@f, number.to_f, out_ptr, needed_length, nil, error)
              end
            end
          end
          out_ptr.string needed_length
        rescue BufferOverflowError
          raise BufferOverflowError, "needed: #{needed_length}" if retried
          out_ptr = out_ptr.resized_to needed_length
          retried = true
          retry
        end
      end
    end # NumberFormatter

    class CurrencyFormatter < BaseFormatter
      def initialize(locale, style = :default)
        if %w(iso plural).include?((style || '').to_s)
          if Lib.version.to_a.first >= 53
            style = "currency_#{style}".to_sym
          else
            fail "Your version of ICU (#{Lib.version.to_a.join('.')}) does not support #{style} currency formatting (supported only in version >= 53)"
          end
        elsif style && style.to_sym != :default
          fail "The ffi-icu ruby gem does not support :#{default} currency formatting (only :default, :iso, and :plural)"
        else
          style = :currency
        end
        @f = make_formatter(style, locale)
      end

      def format(number, currency)
        needed_length = 0
        out_ptr = UCharPointer.new(needed_length)

        retried = false

        begin
          Lib.check_error do |error|
            needed_length = Lib.unum_format_currency(@f, number, UCharPointer.from_string(currency, 4), out_ptr, needed_length, nil, error)
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
