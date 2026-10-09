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
  cases = ['pure-glob-array', 'pure-glob-first', 'pure-entries', 'full-discovery-first',
           'full-discovery-entries', 'suite-discovery-first', 'suite-discovery-entries', 'full-trace']
  failed = false
  cases.each do |probe|
    failures = 0
    repetitions = 50
    repetitions.times do |index|
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
    puts "[native-probe] RESULT case=#{probe} failures=#{failures}/#{repetitions}"
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
if mode.start_with?('pure-')
  paths = ENV.fetch('PATH').split(File::PATH_SEPARATOR)
  if mode.start_with?('pure-path-')
    paths = [paths.fetch(mode.split('-').last.to_i)]
    puts "[native-probe] directory=#{paths.first}"
  end
  patterns = paths.map { |path| File.expand_path(File.join(path, '{lib,}icuuc??.dll')) }
  50.times do
    if mode == 'pure-glob-first'
      patterns.each { |pattern| break unless Dir.glob(pattern).empty? }
    elsif mode == 'pure-entries'
      patterns.each do |pattern|
        directory = File.dirname(pattern)
        begin
          names = Dir.children(directory)
        rescue SystemCallError
          next
        end
        break if names.any? { |name| File.fnmatch?(File.basename(pattern), name, File::FNM_EXTGLOB) }
      end
    elsif mode == 'pure-glob-filtered'
      Dir.glob(patterns.select { |pattern| File.directory?(File.dirname(pattern)) })
    elsif mode == 'pure-glob-each' || mode.start_with?('pure-path-')
      patterns.each { |pattern| Dir.glob(pattern) }
    else
      Dir.glob(patterns)
    end
    Array.new(100) { Object.new }
    GC.start
  end
  puts "[native-probe] complete case=#{mode}"
  exit
end
require 'ffi'
puts "[native-probe] FFI=#{Gem.loaded_specs.fetch('ffi').full_name}"

if mode.start_with?('discover-')
  paths = ENV.fetch('PATH').split(File::PATH_SEPARATOR)
  directory = File.dirname(RbConfig.ruby)
  puts "[native-probe] paths=#{paths.length}"
  patterns = paths.map { |path| File.expand_path(File.join(path, 'icuuc??.dll')) } unless mode == 'discover-paths'
  case mode
  when 'discover-glob-one'
    Dir.glob(File.join(directory, 'icuuc??.dll'))
  when 'discover-glob-array'
    Dir.glob(patterns)
  when 'discover-brace-one'
    Dir.glob(File.join(directory, '{lib,}icuuc??.dll'))
  when 'discover-brace-array'
    Dir.glob(paths.map { |path| File.expand_path(File.join(path, '{lib,}icuuc??.dll')) })
  when 'discover-find-both'
    ['{lib,}icuuc??.dll', '{lib,}icuin??.dll'].each do |name|
      Dir.glob(paths.map { |path| File.expand_path(File.join(path, name)) }).first
    end
  end
  mod = Module.new { extend FFI::Library }
  puts '[native-probe] discovery complete; before enum exercise'
  100.times do
    mod.enum :layout_type, [:ltr, :rtl, :ttb, :btt, :unknown]
    GC.start
  end
  puts "[native-probe] complete case=#{mode}"
elsif mode.start_with?('load-') || mode == 'fiddle-both'
  directory = File.dirname(RbConfig.ruby)
  libraries = case mode
              when 'load-none' then []
              when 'load-uc' then ['icuuc78.dll']
              when 'load-in' then ['icuin78.dll']
              else ['icuuc78.dll', 'icuin78.dll']
              end
  mod = Module.new { extend FFI::Library }
  if mode == 'fiddle-both'
    require 'fiddle'
    handles = libraries.map { |name| Fiddle.dlopen(File.join(directory, name)) }
  elsif !libraries.empty?
    handles = mod.ffi_lib(*libraries.map { |name| File.join(directory, name) })
  end
  if mode == 'load-both-retained'
    $probe_handles = handles
  end
  if mode == 'load-both-version'
    version = nil
    handles.find do |library|
      match = library.name.match(/(\d\d)\.dll/)
      version = match[1] if match
    end
    puts "[native-probe] version=#{version}"
  end
  puts '[native-probe] DLL loading complete; before enum exercise'
  100.times do
    mod.enum :layout_type, [:ltr, :rtl, :ttb, :btt, :unknown]
    GC.start
  end
  puts "[native-probe] complete case=#{mode}"
elsif mode == 'ffi-only'
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
elsif mode.start_with?('bootstrap') || mode == 'prefix-only'
  source = File.read(File.join(__dir__, '..', 'lib', 'ffi-icu', 'lib.rb'))
  prefix = source.split('    version = load_icu', 2).first
  module ICU
    def self.platform
      :windows
    end
  end
  eval(prefix + "\n  end\nend\n", TOPLEVEL_BINDING, 'lib/ffi-icu/lib.rb')
  puts '[native-probe] before load_icu'
  version = mode == 'prefix-only' ? '78' : ICU::Lib.load_icu
  puts "[native-probe] after load_icu version=#{version}"
  unless ['bootstrap-load', 'prefix-only'].include?(mode)
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
  if mode.include?('discovery')
    singleton = class << Dir; self; end
    singleton.prepend(Module.new do
      define_method(:glob) do |patterns, **options|
        if patterns.is_a?(Array)
          patterns = patterns.select { |pattern| File.directory?(File.dirname(pattern)) } if mode.end_with?('filtered')
          if mode.end_with?('first') || mode.end_with?('entries')
            patterns.each do |pattern|
              if mode.end_with?('entries')
                directory = File.dirname(pattern)
                begin
                  names = Dir.children(directory)
                rescue SystemCallError
                  next
                end
                matches = names.select do |name|
                  File.fnmatch?(File.basename(pattern), name, File::FNM_EXTGLOB)
                end.sort.map { |name| File.join(directory, name) }
              else
                matches = super(pattern, **options)
              end
              return matches unless matches.empty?
            end
            []
          else
            mode.end_with?('each') ? patterns.flat_map { |pattern| super(pattern, **options) } : super(patterns, **options)
          end
        else
          super(patterns, **options)
        end
      end
    end)
  end
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
