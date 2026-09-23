# frozen_string_literal: true

require 'fileutils'
require 'rake/testtask'
require 'rbconfig'

EXTENSION_DIR = File.join(__dir__, 'lib', 'offi_icu')
EXTENSION = File.join(EXTENSION_DIR, "offi_icu.#{RbConfig::CONFIG.fetch('DLEXT')}")

file EXTENSION => Dir['src/**/*.rs', 'Cargo.toml'] do
  sh 'cargo', 'build'
  FileUtils.mkdir_p(EXTENSION_DIR)

  artifact = if Gem.win_platform?
               File.join(__dir__, 'target', 'debug', 'offi_icu.dll')
             elsif RbConfig::CONFIG.fetch('host_os').include?('darwin')
               File.join(__dir__, 'target', 'debug', 'liboffi_icu.dylib')
             else
               File.join(__dir__, 'target', 'debug', 'liboffi_icu.so')
             end
  FileUtils.cp(artifact, EXTENSION)
end

task compile: EXTENSION

Rake::TestTask.new(:test => :compile) do |test|
  test.libs << 'lib'
  test.pattern = 'test/**/*_test.rb'
end

desc 'Run formatter benchmarks with YJIT disabled and enabled'
task :benchmark do
  sh File.join(__dir__, 'benchmark', 'run.sh')
end

task default: :test
