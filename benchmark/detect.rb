# encoding: utf-8

require "benchmark"

require "#{File.dirname(__FILE__)}/../lib/icu-chardet-ffi"
require "rchardet"

TESTS = 1000

Benchmark.bmbm do |results|
  results.report("rchardet:") { TESTS.times { CharDet.detect("æåø") } }
  results.report("icu-chardet-ffi:") { TESTS.times { ICUCharDet.detect("æåø") } }
end