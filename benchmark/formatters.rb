# frozen_string_literal: true

require 'benchmark'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'ffi-icu'
require 'ffi-icu/version'
require 'icu4x'
require 'icu4x/data/recommended'
require 'twitter_cldr'

FORMATTER_ITERATIONS = Integer(ENV.fetch('FORMATTER_ITERATIONS', '500'))
FORMATTER_VALUE = 1_234_567.89
NUMBER_PATTERN = '1,234,567.89'
CURRENCY_PATTERN = '$1,234,567.89'

number_formatter = ICU::NumberFormatting.create('en-US')
currency_formatter = ICU::NumberFormatting.create('en-US', :currency)
icu4x_locale = ICU4X::Locale.parse('en-US')
icu4x_number = ICU4X::NumberFormat.new(icu4x_locale, style: :decimal)
icu4x_currency = ICU4X::NumberFormat.new(icu4x_locale, style: :currency, currency: 'USD')
twitter_number = TwitterCldr::DataReaders::NumberDataReader.new(:en, type: :decimal)
twitter_currency = TwitterCldr::DataReaders::NumberDataReader.new(:en, type: :currency, currency: 'USD')

abort('ffi-icu number formatting failed') unless number_formatter.format(FORMATTER_VALUE) == NUMBER_PATTERN
abort('icu4x number formatting failed') unless icu4x_number.format(FORMATTER_VALUE) == NUMBER_PATTERN
abort('twitter_cldr number formatting failed') unless twitter_number.format_number(FORMATTER_VALUE) == NUMBER_PATTERN
abort('ffi-icu currency formatting failed') unless currency_formatter.format(FORMATTER_VALUE, 'USD') == CURRENCY_PATTERN
abort('icu4x currency formatting failed') unless icu4x_currency.format(FORMATTER_VALUE) == CURRENCY_PATTERN
unless twitter_currency.format_number(FORMATTER_VALUE) == CURRENCY_PATTERN
  abort('twitter_cldr currency formatting failed')
end

puts 'ffi-icu formatter benchmarks'
puts "Ruby: #{RUBY_DESCRIPTION}"
puts "ffi-icu: #{ICU::VERSION}"
puts "ICU: #{ICU::Lib.version} (#{ICU::Lib.version.to_a.join('.')})"
puts "icu4x: #{ICU4X::VERSION}"
puts "twitter_cldr: #{TwitterCldr::VERSION}"
puts "Iterations: #{FORMATTER_ITERATIONS} per library"
puts

puts 'Number formatting'
results = Benchmark.bmbm do |x|
  x.report('ffi-icu') { FORMATTER_ITERATIONS.times { number_formatter.format(FORMATTER_VALUE) } }
  x.report('icu4x') { FORMATTER_ITERATIONS.times { icu4x_number.format(FORMATTER_VALUE) } }
  x.report('twitter_cldr') { FORMATTER_ITERATIONS.times { twitter_number.format_number(FORMATTER_VALUE) } }
end
fastest = results.map(&:real).min
puts 'Relative real time (lower is better):'
results.each do |tms|
  puts format('  %-12<label>s %6<factor>.2fx', label: tms.label, factor: tms.real / fastest)
end
puts

puts 'Currency formatting'
results = Benchmark.bmbm do |x|
  x.report('ffi-icu') { FORMATTER_ITERATIONS.times { currency_formatter.format(FORMATTER_VALUE, 'USD') } }
  x.report('icu4x') { FORMATTER_ITERATIONS.times { icu4x_currency.format(FORMATTER_VALUE) } }
  x.report('twitter_cldr') { FORMATTER_ITERATIONS.times { twitter_currency.format_number(FORMATTER_VALUE) } }
end
fastest = results.map(&:real).min
puts 'Relative real time (lower is better):'
results.each do |tms|
  puts format('  %-12<label>s %6<factor>.2fx', label: tms.label, factor: tms.real / fastest)
end
