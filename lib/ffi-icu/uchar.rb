require 'iconv'

module ICU

  class UCharPointer < FFI::MemoryPointer
    def self.from_string(str)
      super Iconv.conv("wchar_t", "utf-8", str.encode("UTF-8"))
    end
  end

end
