module ICU
  module Normalization

    def self.normalize(str, mode = :default)
      needed  = 0
      options = 0
      retried = false
      ptr     = nil

      begin
        Lib.check_error do |error|
          needed = Lib.unorm_normalize(UCharPointer.from_string(str), str.length, mode, options, ptr, needed, error)
        end
      rescue BufferOverflowError
        raise if retried

        ptr     = UCharPointer.from_string(' '*needed)
        retried = true
        retry
      end

      ptr.string
    end

  end # Normalization
end # ICU