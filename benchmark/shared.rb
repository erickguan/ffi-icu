require 'benchmark'

$LOAD_PATH.unshift('lib')
require 'ffi-icu'
require 'rchardet'

TESTS = 1000

rchardet = CharDet::UniversalDetector.new
icu = ICU::CharDet::Detector.new

Benchmark.bmbm do |results|
  results.report('rchardet instance:') do
    TESTS.times do
      rchardet.reset
      rchardet.feed('æåø')
      rchardet.result
    end
  end
  results.report('ffi-icu instance:') { TESTS.times { icu.detect('æåø') } }
end
