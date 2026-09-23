# frozen_string_literal: true

require 'benchmark'

ROOT = File.expand_path('..', __dir__)
FFI_ICU_ROOT = File.expand_path(ENV.fetch('FFI_ICU_PATH', '../ffi-icu'), ROOT)

$LOAD_PATH.unshift(File.join(ROOT, 'lib'))
$LOAD_PATH.unshift(File.join(FFI_ICU_ROOT, 'lib'))

require 'offi-icu'
require 'ffi-icu'
require 'ffi-icu/version'
require 'twitter_cldr'

WARMUP_ROUNDS = Integer(ENV.fetch('WARMUP_ROUNDS', 3))
WARMUP_ITERATIONS = Integer(ENV.fetch('WARMUP_ITERATIONS', 10_000))
ITERATIONS = Integer(ENV.fetch('ITERATIONS', 100_000))
VALUE = 1_234_567.89

Case = Data.define(:label, :call)

offi_number = ICU::NumberFormatter.new('en-US')
ffi_number = ICU::NumberFormatting.create('en-US')
twitter_number = TwitterCldr::DataReaders::NumberDataReader.new(:en, type: :decimal)

offi_currency = ICU::CurrencyFormatter.new('en-US', 'standard')
ffi_currency = ICU::NumberFormatting.create('en-US', :currency)
twitter_currency = TwitterCldr::DataReaders::NumberDataReader.new(
  :en,
  type: :currency,
  currency: 'USD'
)

benchmarks = {
  'number' => [
    Case.new('offi-icu', -> { offi_number.format(VALUE) }),
    Case.new('ffi-icu', -> { ffi_number.format(VALUE) }),
    Case.new('twitter_cldr', -> { twitter_number.format_number(VALUE) })
  ],
  'currency' => [
    Case.new('offi-icu', -> { offi_currency.format(VALUE, 'USD') }),
    Case.new('ffi-icu', -> { ffi_currency.format(VALUE, 'USD') }),
    Case.new('twitter_cldr', -> { twitter_currency.format_number(VALUE) })
  ]
}.freeze

expected = {
  'number' => '1,234,567.89',
  'currency' => '$1,234,567.89'
}.freeze

benchmarks.each do |group, cases|
  cases.each do |benchmark_case|
    actual = benchmark_case.call.call
    next if actual == expected.fetch(group)

    abort("#{group}/#{benchmark_case.label} returned #{actual.inspect}, expected #{expected.fetch(group).inspect}")
  end
end

jit = defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled? ? 'enabled' : 'disabled'
puts "Ruby: #{RUBY_DESCRIPTION}"
puts "YJIT: #{jit}"
puts "offi-icu: #{OffiIcu::VERSION}"
puts "ffi-icu: #{ICU::VERSION}"
puts "twitter_cldr: #{Gem.loaded_specs.fetch('twitter_cldr').version}"
puts "ICU: #{ICU.version} (#{ICU.symbol_version})"
puts "Warmup: #{WARMUP_ROUNDS} rounds x #{WARMUP_ITERATIONS} iterations"
puts "Measurement: #{ITERATIONS} iterations"

WARMUP_ROUNDS.times do |round|
  benchmarks.each_value do |cases|
    cases.each do |benchmark_case|
      WARMUP_ITERATIONS.times { benchmark_case.call.call }
    end
  end
  puts "Warmup round #{round + 1}/#{WARMUP_ROUNDS} complete"
end

benchmarks.each do |group, cases|
  puts "\n#{group.capitalize} formatting"
  results = cases.map do |benchmark_case|
    GC.start
    elapsed = Benchmark.realtime do
      ITERATIONS.times { benchmark_case.call.call }
    end
    [benchmark_case.label, elapsed, ITERATIONS / elapsed]
  end

  fastest = results.map(&:last).max
  puts format('%-14s %12s %15s %10s', 'library', 'seconds', 'iterations/s', 'relative')
  results.each do |label, elapsed, iterations_per_second|
    puts format(
      '%-14s %12.4f %15.0f %9.2fx',
      label,
      elapsed,
      iterations_per_second,
      iterations_per_second / fastest
    )
  end
end
