# encoding: UTF-8

require 'spec_helper'

module ICU
  module Lib
    describe VersionInfo do
      its(:to_a) { should be_an Array }
      its(:to_s) do
        should be_a String
        should match /^[0-9.]+$/
      end
    end
  end
end
