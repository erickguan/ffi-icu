# frozen_string_literal: true

require 'benchmark'

ROOT = File.expand_path('..', __dir__)
$LOAD_PATH.unshift(File.join(ROOT, 'lib'))

require 'ffi-icu'
require 'ffi-icu/version'

VALUE = 1_234_567.89

# Tuned so the whole benchmark runs in around 300ms: fast enough for quick
# feedback, slow enough to be meaningful. Override with ITERATIONS=...
ITERATIONS = Integer(ENV.fetch('ITERATIONS', '30_000'))
WARMUP_ITERATIONS = Integer(ENV.fetch('WARMUP_ITERATIONS', '5_000'))

number = ICU::NumberFormatting.create('en-US')
currency = ICU::NumberFormatting.create('en-US', :currency)

# Sanity-check output before benchmarking.
expected_number = '1,234,567.89'
expected_currency = '$1,234,567.89'
actual_number = number.format(VALUE)
actual_currency = currency.format(VALUE, 'USD')
unless actual_number == expected_number
  abort("number formatting returned #{actual_number.inspect}, expected #{expected_number.inspect}")
end
unless actual_currency == expected_currency
  abort("currency formatting returned #{actual_currency.inspect}, expected #{expected_currency.inspect}")
end

# Warm up ICU and FFI call sites before measuring.
WARMUP_ITERATIONS.times { number.format(VALUE) }
WARMUP_ITERATIONS.times { currency.format(VALUE, 'USD') }

puts "Ruby: #{RUBY_DESCRIPTION}"
puts "ffi-icu: #{ICU::VERSION}"
puts "ICU: #{ICU::Lib.version} (#{ICU::Lib.version.to_a.join('.')})"
puts "Warmup: #{WARMUP_ITERATIONS} iterations"
puts "Measurement: #{ITERATIONS} iterations"
puts

benchmarks = [
  ['number formatting', -> { number.format(VALUE) }],
  ['currency formatting', -> { currency.format(VALUE, 'USD') }]
].freeze

benchmarks.each do |label, call|
  GC.start
  elapsed = Benchmark.realtime { ITERATIONS.times { call.call } }
  iterations_per_second = ITERATIONS / elapsed
  puts format('%-20<label>s %<elapsed>9.4fs %<iterations_per_second>12.0f iterations/s',
              label:, elapsed:, iterations_per_second:)
end
