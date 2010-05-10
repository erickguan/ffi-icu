module ICU
  class UCharPointer < FFI::MemoryPointer
    def self.from_string(str)
      bytes = str.bytes.to_a
    
      ptr = new(:uint16, bytes.size)
      ptr.put_array_of_uint16(0, bytes)
    
      ptr
    end
  end
  
  # class UCharIteratorPointer < FFI::MemoryPointer
  #   def self.from_string(str)
  #     ptr = new(:pointer, 4)
  #     Lib.uiter_setUTF8(ptr, str, str.length)
  #     ptr
  #   end
  # end
  
end