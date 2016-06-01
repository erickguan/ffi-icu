# encoding: UTF-8

require 'spec_helper'

module ICU
  module Lib
    describe VersionInfo do
      it 'should be an array'do
        version = ICU::Lib.version
        expect(version.to_a).to be_a(Array)
        expect(version.to_s).to be_a(String)
        expect(version.to_s).to match(/^[0-9.]+$/)
      end
    end
  end
end
