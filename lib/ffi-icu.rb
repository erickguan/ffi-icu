require "rbconfig"
require "ffi"

module ICU
  def self.platform
    os = RbConfig::CONFIG["host_os"]

    case os
    when /darwin/
      :osx
    when /linux/
      :linux
    else
      os
    end
  end
end

require "ffi-icu/lib"
require "ffi-icu/uchar"
require "ffi-icu/chardet"
require "ffi-icu/collation"
require "ffi-icu/transliteration"
require "ffi-icu/normalization"

