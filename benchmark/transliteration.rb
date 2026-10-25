# frozen_string_literal: true

require 'benchmark'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'ffi-icu'
require 'ffi-icu/version'
require 'twitter_cldr'
require 'icu4x'

TRANSLITERATION_ITERATIONS = Integer(ENV.fetch('TRANSLITERATION_ITERATIONS', '120'))
TRANSLITERATION_TRANSFORM = 'Greek-Latin'
TRANSLITERATION_TEXT = 'Ελληνικά'
TRANSLITERATION_PATTERN = 'Ellēniká'

twitter_transformer = TwitterCldr::Transforms::Transformer.get(TRANSLITERATION_TRANSFORM)

abort('ffi-icu transliteration failed') unless ICU::Transliteration.transliterate(
  TRANSLITERATION_TRANSFORM, TRANSLITERATION_TEXT
) == TRANSLITERATION_PATTERN
abort('twitter_cldr transliteration failed') unless twitter_transformer.transform(
  TRANSLITERATION_TEXT
) == TRANSLITERATION_PATTERN

puts 'ffi-icu transliteration benchmarks'
puts "Ruby: #{RUBY_DESCRIPTION}"
puts "ffi-icu: #{ICU::VERSION}"
puts "ICU: #{ICU::Lib.version} (#{ICU::Lib.version.to_a.join('.')})"
puts "twitter_cldr: #{TwitterCldr::VERSION}"
puts "icu4x: #{ICU4X::VERSION} (transliteration unavailable in this Ruby binding)"
puts "Transform: #{TRANSLITERATION_TRANSFORM}"
puts "Text: #{TRANSLITERATION_TEXT}"
puts "Iterations: #{TRANSLITERATION_ITERATIONS} per library"
puts

puts 'Transliteration (Greek to Latin)'
results = Benchmark.bmbm do |x|
  x.report('ffi-icu') do
    TRANSLITERATION_ITERATIONS.times do
      ICU::Transliteration.transliterate(TRANSLITERATION_TRANSFORM, TRANSLITERATION_TEXT)
    end
  end
  x.report('twitter_cldr') do
    TRANSLITERATION_ITERATIONS.times { twitter_transformer.transform(TRANSLITERATION_TEXT) }
  end
end
fastest = results.map(&:real).min
puts 'Relative real time (lower is better):'
results.each do |tms|
  puts format('  %-12<label>s %6<factor>.2fx', label: tms.label, factor: tms.real / fastest)
end
