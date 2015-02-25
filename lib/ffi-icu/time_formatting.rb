
module ICU
  module TimeFormatting
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

      def make_formatter(timeStyle, dateStyle, locale, timeZoneStr)
        timeZone = nil
        d_len = 0
        if timeZoneStr
            timeZone = UCharPointer.from_string(timeZoneStr)
            d_len = timeZoneStr.size
        else
            Lib.check_error { | error| 
                i_len  = 150
                timeZone = UCharPointer.new(i_len)
                d_len = Lib.ucal_getDefaultTimeZone(timeZone, i_len, error) 
            }
        end
        ptr = Lib.check_error { | error| Lib.udat_open(timeStyle, dateStyle, locale, timeZone, d_len, FFI::MemoryPointer.new(4), -1, error) }
        FFI::AutoPointer.new(ptr, Lib.method(:udat_close))
      end
    end

    class DateTimeFormatter < BaseFormatter
      def initialize(options={})
        timeStyle = options[:time]   || :short
        dateStyle = options[:date]   || :short
        locale    = options[:locale] || 'C'
        timeZone  = options[:zone]
        @f = make_formatter(timeStyle, dateStyle, locale, timeZone)
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
    end # DateTimeFormatter
  end # Formatting
end # ICU
