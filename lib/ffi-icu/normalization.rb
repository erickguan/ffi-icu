module ICU
  module Normalization

    def self.normalize(input, mode = :default)
      input_length = ICU.ruby19? ? input.length : input.jlength
      needed_length  = 0
      result_length = 0

      retried = false
      ptr     = nil

      begin
        Lib.check_error do |error|
          needed_length = Lib.unorm_normalize(UCharPointer.from_string(input), input_length, mode, 0, ptr, result_length, error)
        end
      rescue BufferOverflowError
        raise if retried
        ptr     = UCharPointer.from_string("\0" * needed_length)
        result_length = needed_length + 1

        retried = true
        retry
      end

      ptr.string if ptr
    end

  end # Normalization
end # ICU
