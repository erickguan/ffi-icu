# encoding: utf-8

require "benchmark"

require "#{File.dirname(__FILE__)}/../lib/icu-chardet-ffi"
require "rchardet"

TESTS = 1000

$rchardet = CharDet::UniversalDetector.new
$icu = ICUCharDet::Detector.new

Benchmark.bmbm do |results|
  results.report("rchardet instance:") { TESTS.times { $rchardet.reset; $rchardet.feed("æåø"); $rchardet.result } }
  results.report("icu-chardet-ffi instance:") { TESTS.times { $icu.detect("æåø")  } }
end