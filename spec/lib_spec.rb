module ICU
  describe Lib do
    describe '.search_paths' do
      around do |example|
        search_paths_defined = described_class.instance_variable_defined?(:@search_paths)
        original_icu_lib = ENV.delete('FFI_ICU_LIB')
        original_paths = described_class.instance_variable_get(:@search_paths) if search_paths_defined
        described_class.remove_instance_variable(:@search_paths) if search_paths_defined
        example.run
      ensure
        if described_class.instance_variable_defined?(:@search_paths)
          described_class.remove_instance_variable(:@search_paths)
        end
        described_class.instance_variable_set(:@search_paths, original_paths) if search_paths_defined
        ENV['FFI_ICU_LIB'] = original_icu_lib if original_icu_lib
      end

      let(:multiarch_paths) do
        [
          '/usr/lib/i386-linux-gnu',
          '/usr/lib/x86_64-linux-gnu'
        ]
      end

      before do
        stub_const('FFI::Platform::IS_WINDOWS', false)
        stub_const('FFI::Platform::ARCH', 'x86_64')
        allow(Dir).to(receive(:[]).with('/usr/lib/*-linux-gnu').and_return(multiarch_paths))
      end

      it 'prioritizes the native Debian multiarch directory' do
        expected_paths = [
          '/usr/lib/x86_64-linux-gnu',
          '/usr/lib/i386-linux-gnu'
        ]

        expect(described_class.search_paths.last(2)).to(eq(expected_paths))
      end

      context 'when no native Debian multiarch directory is available' do
        let(:multiarch_paths) do
          [
            '/usr/lib/aarch64-linux-gnu',
            '/usr/lib/i386-linux-gnu'
          ]
        end

        it 'keeps the existing paths as fallbacks' do
          expect(described_class.search_paths.last(2)).to(eq(multiarch_paths))
        end
      end
    end

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

      # rubocop:disable-next RSpec/InstanceVariable
      context 'upon warning' do
        before { @verbose = $VERBOSE }
        after { $VERBOSE = @verbose }

        # rubocop:disable-next RSpec/ExpectOutput
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
