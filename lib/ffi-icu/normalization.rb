# frozen_string_literal: true

module ICU
  module Normalization
    def self.normalize(input, mode = :default)
      needed_length = out_length = options = 0
      input_pointer = UCharPointer.from_utf8(input)
      input_length  = input_pointer.length_in_uchars
      out_ptr       = UCharPointer.new(out_length)

      retried = false

      begin
        Lib.check_error do |error|
          needed_length = Lib.unorm_normalize(input_pointer, input_length, mode, options, out_ptr, out_length, error)
        end
      rescue BufferOverflowError
        raise(BufferOverflowError, "needed: #{needed_length}") if retried

        out_length    = needed_length + 1
        out_ptr       = out_ptr.resized_to(out_length)

        retried = true
        retry
      end

      out_ptr.utf8_string(needed_length)
    end
  end
end
