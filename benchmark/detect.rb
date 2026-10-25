# frozen_string_literal: true

require 'benchmark'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'ffi-icu'
require 'ffi-icu/version'
require 'rchardet'

DETECT_ITERATIONS = Integer(ENV.fetch('DETECT_ITERATIONS', '5'))
DETECT_TEXT_PATH = ENV.fetch('DETECT_TEXT_PATH', File.join(__dir__, 'fixtures', 'detect.txt'))
DETECT_TEXT = File.read(DETECT_TEXT_PATH, encoding: 'UTF-8').freeze
# rchardet expects raw bytes; precompute them so detection is what gets timed.
DETECT_TEXT_BINARY = DETECT_TEXT.b.freeze

detector = ICU::CharDet::Detector.new
rchardet_detector = CharDet::UniversalDetector.new

ffi_match = ICU::CharDet.detect(DETECT_TEXT)
rchardet_match = CharDet.detect(DETECT_TEXT)
abort("ffi-icu returned #{ffi_match.name.inspect}") unless ffi_match.name.downcase == 'utf-8'
abort("rchardet returned #{rchardet_match.inspect}") unless rchardet_match['encoding'] == 'utf-8'

abort('ffi-icu reusable detector failed') unless detector.detect(DETECT_TEXT).name.downcase == 'utf-8'
rchardet_detector.reset
rchardet_detector.feed(DETECT_TEXT_BINARY)
rchardet_detector.close
abort('rchardet reusable detector failed') unless rchardet_detector.result['encoding'] == 'utf-8'

puts 'ffi-icu character detection benchmarks'
puts "Ruby: #{RUBY_DESCRIPTION}"
puts "ffi-icu: #{ICU::VERSION}"
puts "ICU: #{ICU::Lib.version} (#{ICU::Lib.version.to_a.join('.')})"
puts "rchardet: #{CharDet::VERSION}"
puts "Text: #{DETECT_TEXT_PATH} (#{DETECT_TEXT.bytesize} bytes)"
puts "Iterations: #{DETECT_ITERATIONS} per library"
puts

puts 'Character detection (class helper)'
results = Benchmark.bmbm do |x|
  x.report('ffi-icu') { DETECT_ITERATIONS.times { ICU::CharDet.detect(DETECT_TEXT) } }
  x.report('rchardet') { DETECT_ITERATIONS.times { CharDet.detect(DETECT_TEXT) } }
end
fastest = results.map(&:real).min
puts 'Relative real time (lower is better):'
results.each do |tms|
  puts format('  %-12<label>s %6<factor>.2fx', label: tms.label, factor: tms.real / fastest)
end
puts

puts 'Character detection (reusable detector)'
results = Benchmark.bmbm do |x|
  x.report('ffi-icu') { DETECT_ITERATIONS.times { detector.detect(DETECT_TEXT) } }
  x.report('rchardet') do
    DETECT_ITERATIONS.times do
      rchardet_detector.reset
      rchardet_detector.feed(DETECT_TEXT_BINARY)
      rchardet_detector.close
      rchardet_detector.result
    end
  end
end
fastest = results.map(&:real).min
puts 'Relative real time (lower is better):'
results.each do |tms|
  puts format('  %-12<label>s %6<factor>.2fx', label: tms.label, factor: tms.real / fastest)
end
