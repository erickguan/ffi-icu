# encoding: utf-8

require "benchmark"

$LOAD_PATH.unshift "lib"
require "ffi-icu"
require "rchardet"

TESTS = 1000

Benchmark.bmbm do |results|
  results.report("rchardet:") { TESTS.times { CharDet.detect("æåø") } }
  results.report("ffi-icu:") { TESTS.times { ICU::CharDet.detect("æåø") } }
end