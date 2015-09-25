module ICU
  class Normalizer
    # support for newer ICU normalization API

    def initialize(package_name = nil, name = 'nfc', mode = :decompose)
      Lib.check_error do |error|
        @instance = Lib.unorm2_getInstance(package_name, name, mode, error)
      end
    end

    def normalize(input)
      input_length  = input.jlength
      in_ptr        = UCharPointer.from_string(input)
      needed_length = capacity = 0
      out_ptr       = UCharPointer.new(needed_length)

      retried = false
      begin
        Lib.check_error do |error|
          needed_length = Lib.unorm2_normalize(@instance, in_ptr, input_length, out_ptr, capacity, error)
        end
      rescue BufferOverflowError
        raise BufferOverflowError, "needed: #{needed_length}" if retried

        capacity = needed_length
        out_ptr = out_ptr.resized_to needed_length

        retried = true
        retry
      end

      out_ptr.string
    end

    def is_normailzed?(input)
      input_length  = input.jlength
      in_ptr        = UCharPointer.from_string(input)

      Lib.check_error do |error|
        result = Lib.unorm2_isNormalized(@instance, in_ptr, input_length, error)
      end

      result
    end

  end # Normalizer
end # ICU
