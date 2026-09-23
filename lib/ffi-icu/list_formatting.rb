# frozen_string_literal: true

module ICU
  module ListFormatting
    VALID_STYLES = [:and, :or, :unit].freeze

    STYLES_TO_TYPES = {
      and: :and,
      or: :or,
      unit: :units
    }.freeze

    def self.format(items, locale:, style: :and)
      raise(ArgumentError, "Unknown style #{style}") unless VALID_STYLES.include?(style)
      raise(ArgumentError, 'items must be strings') unless items.all?(String)

      return '' if items.empty?

      unless Lib.respond_to?(:ulistfmt_openForType) &&
             Lib.respond_to?(:ulistfmt_close) &&
             Lib.respond_to?(:ulistfmt_format)
        raise('ICU::ListFormatting requires ICU >= 67')
      end

      formatter = Lib.check_error do |error|
        Lib.ulistfmt_openForType(locale, STYLES_TO_TYPES.fetch(style), :wide, error)
      end

      begin
        value_uchars = items.map(&UCharPointer.method(:from_string))
        value_uchars_array = FFI::MemoryPointer.new(:pointer, value_uchars.size)
        value_uchars_array.put_array_of_pointer(0, value_uchars)
        value_lengths_array = FFI::MemoryPointer.new(:int32_t, value_uchars.size)
        value_lengths_array.put_array_of_int32(0, value_uchars.map(&:length_in_uchars))

        Lib::Util.read_uchar_buffer(0) do |buffer, error|
          Lib.ulistfmt_format(
            formatter,
            value_uchars_array,
            value_lengths_array,
            value_uchars.size,
            buffer,
            buffer.length_in_uchars,
            error
          )
        end
      ensure
        Lib.ulistfmt_close(formatter)
      end
    end
  end
end
