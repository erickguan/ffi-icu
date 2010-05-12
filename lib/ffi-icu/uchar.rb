module ICU
  class UCharPointer < FFI::MemoryPointer

    def self.from_string(str)
      # not sure how this will work with other encodings
      str = str.encode("UTF-8") if str.respond_to? :encode
      super str.unpack("U*").pack("L*")
    end

    def string
      wstring = read_string(size)
      wstring.unpack("L*").pack("U*")
    end
  end # UCharPointer
end # ICU
