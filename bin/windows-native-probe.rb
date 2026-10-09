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
  cases = ['ruby-only', 'ffi-only', 'icu-minimal', 'bootstrap-load', 'bootstrap-suffix',
           'bootstrap-mapped', 'bootstrap-attach', 'full-trace', 'full-trace-no-gc']
  failed = false
  cases.each do |probe|
    failures = 0
    30.times do |index|
      output, status = Open3.capture2e(RbConfig.ruby, '-Ilib', __FILE__, probe, chdir: root)
      File.write(File.join(logs, "#{probe}-#{index + 1}.log"), output)
      failures += 1 unless status.success?
      puts "[native-probe] case=#{probe} iteration=#{index + 1} exit=#{status.exitstatus} signal=#{status.termsig}"
      if status.success?
        puts output.lines.grep(/\[native-probe\].*(start|complete|FFI=|ICU=)/)
      else
        puts output.lines.grep(/\[native-probe\]|\[BUG\]|Segmentation|LoadError|examples,|Failure\/Error/).last(18)
      end
    end
    puts "[native-probe] RESULT case=#{probe} failures=#{failures}/30"
    failed ||= failures.positive?
  end
  exit(failed ? 1 : 0)
end

puts "[native-probe] start case=#{mode} Ruby=#{RUBY_DESCRIPTION}"
GC.disable if mode.end_with?('-no-gc')
if mode == 'ruby-only'
  100.times do
    Array.new
    Hash.new
    Object.new
    GC.start
  end
  puts "[native-probe] complete case=#{mode}"
  exit
end
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
elsif mode.start_with?('bootstrap')
  source = File.read(File.join(__dir__, '..', 'lib', 'ffi-icu', 'lib.rb'))
  prefix = source.split('    version = load_icu', 2).first
  module ICU
    def self.platform
      :windows
    end
  end
  eval(prefix + "\n  end\nend\n", TOPLEVEL_BINDING, 'lib/ffi-icu/lib.rb')
  puts '[native-probe] before load_icu'
  version = ICU::Lib.load_icu
  puts "[native-probe] after load_icu version=#{version}"
  unless mode == 'bootstrap-load'
    puts '[native-probe] before figure_suffix'
    suffix = ICU::Lib.figure_suffix(version)
    puts "[native-probe] after figure_suffix suffix=#{suffix}"
    unless mode == 'bootstrap-suffix'
      ICU::Lib.typedef ICU::Lib::VersionInfo, :version
      ICU::Lib.attach_function :u_getVersion, "u_getVersion#{suffix}", [:version], :void
      ICU::Lib.attach_function :u_versionToString, "u_versionToString#{suffix}", [:version, :pointer], :void
      if mode == 'bootstrap-attach'
        tail = source.split('    attach_function :u_errorName,', 2).last.split('    enum :layout_type,', 2).first
        ICU::Lib.module_eval('attach_function :u_errorName,' + tail, 'bootstrap-attach')
      end
    end
  end
  100.times do
    ICU::Lib.enum :layout_type, [:ltr, :rtl, :ttb, :btt, :unknown]
    GC.start
  end
  puts "[native-probe] complete case=#{mode}"
else
  if mode.start_with?('full-trace')
    FFI::Library.prepend(Module.new do
      def attach_function(*args)
        puts "[native-probe] before attach #{args.first}"
        result = super
        puts "[native-probe] after attach #{args.first}"
        result
      end

      def enum(*args)
        puts "[native-probe] before enum #{args.first}"
        result = super
        puts "[native-probe] after enum #{args.first}"
        result
      end
    end)
  end
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
