# encoding: UTF-8

module ICU
  module Lib
    describe VersionInfo do
      describe '.to_a' do
        subject { described_class.new.to_a }

        it { is_expected.to be_an(Array) }
      end

      describe '.to_s' do
        subject { described_class.new.to_s }

        it { is_expected.to be_a(String) }
        it { is_expected.to match(/^[0-9.]+$/) }
      end
    end
  end
end
