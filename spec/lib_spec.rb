module ICU
  describe Lib do
    describe 'error checking' do
      let(:return_value) { double }

      context 'upon success' do
        it 'returns the block result' do
          expect(described_class.check_error { |_status| return_value }).to(eq(return_value))
          expect(described_class.check_error do |status|
                   status.write_int(0)
                   return_value
                 end).to(eq(return_value))
        end
      end

      context 'upon failure' do
        it 'raises an error' do
          expect do
            described_class.check_error do |status|
              status.write_int(1)
            end
          end.to(raise_error(ICU::Error, /U_.*_ERROR/))
        end
      end

      # rubocop:disable RSpec/InstanceVariable
      context 'upon warning' do
        before { @verbose = $VERBOSE }
        after { $VERBOSE = @verbose }

        # rubocop:disable RSpec/ExpectOutput
        context 'when warnings are enabled' do
          before do
            @original_stderr = $stderr
            $stderr = StringIO.new
            $VERBOSE = true
          end

          after do
            $stderr = @original_stderr
          end

          it 'prints to STDERR and returns the block result' do
            error_check = described_class.check_error do |status|
              status.write_int(-127)
              return_value
            end

            $stderr.rewind
            expect($stderr.read).to(match(/U_.*_WARNING/))
            expect(error_check).to(eq(return_value))
          end
        end
        # rubocop:enable RSpec/ExpectOutput

        context 'when warnings are disabled' do
          before { $VERBOSE = false }

          it 'returns the block result' do
            expect($stderr).not_to(receive(:puts))
            error_check = described_class.check_error do |status|
              status.write_int(-127)
              return_value
            end
            expect(error_check).to(eq(return_value))
          end
        end
      end
      # rubocop:enable RSpec/InstanceVariable
    end

    if Gem::Version.new('4.2') <= Gem::Version.new(described_class.version)
      describe 'CLDR version' do
        subject { described_class.cldr_version }

        it { is_expected.to(be_a(described_class::VersionInfo)) }
        it('is populated') { expect(subject.to_a).not_to(eq([0, 0, 0, 0])) }
      end
    end

    describe 'ICU version' do
      subject { described_class.version }

      it { is_expected.to(be_a(described_class::VersionInfo)) }
      it('is populated') { expect(subject.to_a).not_to(eq([0, 0, 0, 0])) }
    end
  end
end
