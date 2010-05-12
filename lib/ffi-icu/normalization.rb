module ICU
  module Normalization
    
    def self.normalize(str, mode = :ndf)
      result_size = 0
      options     = 0
      retried     = false
      ptr         = nil
      
      begin
        Lib.check_error do |error|
          result_size = Lib.unorm_normalize(UCharPointer.from_string(str), str.length, mode, options, ptr, result_size, error) 
        end
      rescue BufferOverflowError
        unless retried
          ptr = FFI::MemoryPointer.new(:uint16, result_size)
          retried = true
          retry 
        end
      end        
      
      if ptr
        p :ptr => ptr
        data = ptr.get_array_of_uint16(0, 4) 
      end
    end
    
  end # Normalization
end # ICU