# encoding: UTF-8

require 'spec_helper'

module ICU
  describe Lib do
    describe 'error checking' do
      let(:return_value) { double }

      context 'upon success' do
        it 'returns the block result' do
          Lib.check_error { |status| return_value }.should == return_value
          Lib.check_error { |status| status.write_int(0); return_value }.should == return_value
        end
      end

      context 'upon failure' do
        it 'raises an error' do
          expect { Lib.check_error { |status| status.write_int(1) } }.to raise_error ICU::Error, /U_.*_ERROR/
        end
      end

      context 'upon warning' do
        before(:each) { @verbose = $VERBOSE }
        after(:each) { $VERBOSE = @verbose }

        context 'when warnings are enabled' do
          before(:each) { $VERBOSE = true }

          it 'prints to STDERR and returns the block result' do
            $stderr.should_receive(:puts) { |message| message.should match /U_.*_WARNING/ }
            Lib.check_error { |status| status.write_int(-127); return_value }.should == return_value
          end
        end

        context 'when warnings are disabled' do
          before(:each) { $VERBOSE = false }

          it 'returns the block result' do
            $stderr.should_not_receive(:puts)
            Lib.check_error { |status| status.write_int(-127); return_value }.should == return_value
          end
        end
      end
    end
  end
end
