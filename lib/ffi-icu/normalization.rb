module ICU
  module Normalization

    def self.normalize(input, mode = :default)
      input_length  = input.jlength
      needed_length = out_length = options = 0
      in_ptr        = UCharPointer.from_string(input)
      out_ptr       = UCharPointer.new(out_length)

      retried = false

      begin
        Lib.check_error do |error|
          needed_length = Lib.unorm_normalize(in_ptr, input_length, mode, options, out_ptr, out_length, error)
        end
      rescue BufferOverflowError
        raise BufferOverflowError, "needed: #{needed_length}" if retried

        out_ptr       = out_ptr.resized_to needed_length
        out_length    = needed_length + 1

        retried = true
        retry
      end

      out_ptr.string
    end

  end # Normalization
end # ICU
