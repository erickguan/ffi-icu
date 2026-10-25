# frozen_string_literal: true

require 'benchmark'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'ffi-icu'
require 'ffi-icu/version'
require 'icu4x'
require 'icu4x/data/recommended'
require 'twitter_cldr'

LOCALE_ITERATIONS = Integer(ENV.fetch('LOCALE_ITERATIONS', '6000'))
LOCALE_DISPLAY_LOCALE = 'en'
LOCALE_LANGUAGE_CODE = 'es'
LOCALE_PATTERN = 'Spanish'

ffi_locale = ICU::Locale.new(LOCALE_LANGUAGE_CODE)
icu4x_display = ICU4X::DisplayNames.new(ICU4X::Locale.parse(LOCALE_DISPLAY_LOCALE), type: :language)

abort('ffi-icu locale display failed') unless ffi_locale.display_language(LOCALE_DISPLAY_LOCALE) == LOCALE_PATTERN
abort('icu4x locale display failed') unless icu4x_display.of(LOCALE_LANGUAGE_CODE) == LOCALE_PATTERN
abort('twitter_cldr locale display failed') unless TwitterCldr::Shared::Languages.from_code_for_locale(
  LOCALE_LANGUAGE_CODE, :en
) == LOCALE_PATTERN

puts 'ffi-icu locale display benchmarks'
puts "Ruby: #{RUBY_DESCRIPTION}"
puts "ffi-icu: #{ICU::VERSION}"
puts "ICU: #{ICU::Lib.version} (#{ICU::Lib.version.to_a.join('.')})"
puts "icu4x: #{ICU4X::VERSION}"
puts "twitter_cldr: #{TwitterCldr::VERSION}"
puts "Display locale: #{LOCALE_DISPLAY_LOCALE}"
puts "Language code: #{LOCALE_LANGUAGE_CODE}"
puts "Iterations: #{LOCALE_ITERATIONS} per library"
puts

puts 'Locale display names (language names in English)'
results = Benchmark.bmbm do |x|
  x.report('ffi-icu') { LOCALE_ITERATIONS.times { ffi_locale.display_language(LOCALE_DISPLAY_LOCALE) } }
  x.report('icu4x') { LOCALE_ITERATIONS.times { icu4x_display.of(LOCALE_LANGUAGE_CODE) } }
  x.report('twitter_cldr') do
    LOCALE_ITERATIONS.times do
      TwitterCldr::Shared::Languages.from_code_for_locale(LOCALE_LANGUAGE_CODE, :en)
    end
  end
end
fastest = results.map(&:real).min
puts 'Relative real time (lower is better):'
results.each do |tms|
  puts format('  %-12<label>s %6<factor>.2fx', label: tms.label, factor: tms.real / fastest)
end
