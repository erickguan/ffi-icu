# Temporary diagnostic harness for PR #89.
require 'fileutils'
require 'open3'
require 'rbconfig'

$stdout.sync = true
mode = ARGV.first
if mode == 'driver'
  root = File.expand_path('..', __dir__)
  logs = File.join(root, 'tmp', 'windows-native-probe')
  FileUtils.mkdir_p(logs)
  cases = ['ffi-only', 'icu-minimal', 'full-load', 'full-load-no-gc', 'suite', 'suite-no-gc', 'suite-date-close']
  failed = false
  cases.each do |probe|
    failures = 0
    15.times do |index|
      output, status = Open3.capture2e(RbConfig.ruby, '-Ilib', __FILE__, probe, chdir: root)
      File.write(File.join(logs, "#{probe}-#{index + 1}.log"), output)
      failures += 1 unless status.success?
      puts "[native-probe] case=#{probe} iteration=#{index + 1} exit=#{status.exitstatus} signal=#{status.termsig}"
      puts output.lines.grep(/\[native-probe\]|\[BUG\]|Segmentation|LoadError|examples,|Failure\/Error/).first(12)
    end
    puts "[native-probe] RESULT case=#{probe} failures=#{failures}/15"
    failed ||= failures.positive?
  end
  exit(failed ? 1 : 0)
end

puts "[native-probe] start case=#{mode} Ruby=#{RUBY_DESCRIPTION}"
GC.disable if ['full-load-no-gc', 'suite-no-gc'].include?(mode)
require 'ffi'
puts "[native-probe] FFI=#{Gem.loaded_specs.fetch('ffi').full_name}"

if mode == 'ffi-only'
  mod = Module.new do
    extend FFI::Library
    ffi_lib 'ucrtbase'
    attach_function :strlen, [:string], :size_t
  end
  100.times do
    raise 'strlen mismatch' unless mod.strlen('probe') == 5
    mod.enum([:first, 0, :second, 1])
    FFI::MemoryPointer.new(:uint8, 4).write_array_of_uint8([1, 2, 3, 4])
    GC.start
  end
elsif mode == 'icu-minimal'
  directory = File.dirname(RbConfig.ruby)
  mod = Module.new do
    extend FFI::Library
    ffi_lib File.join(directory, 'icuuc78.dll')
    attach_function :u_getVersion, :u_getVersion_78, [:pointer], :void
    attach_function :u_errorName, :u_errorName_78, [:int], :string
  end
  100.times do
    pointer = FFI::MemoryPointer.new(:uint8, 4)
    mod.u_getVersion(pointer)
    raise 'version mismatch' unless pointer.read_array_of_uint8(4).first == 78
    raise 'error name mismatch' unless mod.u_errorName(0) == 'U_ZERO_ERROR'
    GC.start
  end
else
  require 'ffi-icu'
  puts "[native-probe] ICU=#{ICU::Lib.version} libraries=#{ICU::Lib.ffi_libraries.map(&:name).join(',')}"
  if mode.start_with?('suite')
    if mode == 'suite-date-close'
      ICU::Lib.attach_function :udat_close, :udat_close_78, [:pointer], :void
    end
    require 'rspec/core'
    exit RSpec::Core::Runner.run(['--format', 'progress', 'spec'])
  end
  25.times do
    raise 'ICU version mismatch' unless ICU::Lib.version.to_a.first == 78
    GC.start unless mode == 'full-load-no-gc'
  end
end
puts "[native-probe] complete case=#{mode}"
