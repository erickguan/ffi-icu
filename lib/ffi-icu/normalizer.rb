# frozen_string_literal: true

module ICU
  class Normalizer
    # support for newer ICU normalization API

    def initialize(package_name = nil, name = 'nfc', mode = :decompose)
      Lib.check_error do |error|
        @instance = Lib.unorm2_getInstance(package_name, name, mode, error)
      end
    end

    def normalize(input)
      input_pointer = UCharPointer.from_string(input)
      input_length  = input_pointer.length_in_uchars
      needed_length = capacity = 0
      out_ptr       = UCharPointer.new(needed_length)

      retried = false
      begin
        Lib.check_error do |error|
          needed_length = Lib.unorm2_normalize(@instance, input_pointer, input_length, out_ptr, capacity, error)
        end
      rescue BufferOverflowError
        raise(BufferOverflowError, "needed: #{needed_length}") if retried

        capacity = needed_length + 1
        out_ptr = out_ptr.resized_to(capacity)

        retried = true
        retry
      end

      out_ptr.string(needed_length)
    end

    def normalized?(input)
      input_pointer = UCharPointer.from_string(input)
      input_length  = input_pointer.length_in_uchars

      Lib.check_error do |error|
        Lib.unorm2_isNormalized(@instance, input_pointer, input_length, error)
      end
    end
    alias normailzed? normalized?

    def is_normalized?(input) # rubocop:disable Naming/PredicatePrefix
      Warning.warn('is_normalized? is deprecated and will be removed after v0.7. Please use normalized? instead.')
      normalized?(input)
    end
  end
end
