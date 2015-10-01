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
    when /bsd/
      :bsd
    when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
      :windows
    else
      os
    end
  end

  def self.ruby19?
    RUBY_VERSION >= '1.9'
  end
end

unless ICU.ruby19?
  require 'jcode'
  $KCODE = 'u'
end

require "ffi-icu/core_ext/string"
require "ffi-icu/lib"
require "ffi-icu/lib/util"
require "ffi-icu/uchar"
require "ffi-icu/chardet"
require "ffi-icu/collation"
require "ffi-icu/locale"
require "ffi-icu/transliteration"
require "ffi-icu/normalization"
require "ffi-icu/normalizer"
require "ffi-icu/break_iterator"
require "ffi-icu/number_formatting"
require "ffi-icu/time_formatting"
