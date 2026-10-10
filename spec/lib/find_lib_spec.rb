module ICU
  describe Lib do
    describe '.find_lib' do
      let(:pattern) { '{lib,}icuuc??.dll' }
      let(:first_dir) { File.expand_path('first') }
      let(:second_dir) { File.expand_path('second') }
      let(:first_pattern) { File.join(first_dir, pattern) }
      let(:second_pattern) { File.join(second_dir, pattern) }

      before do
        allow(described_class).to(receive(:search_paths).and_return([first_dir, second_dir]))
      end

      it 'stops discovery after the first matching directory' do
        library = File.join(first_dir, 'icuuc78.dll')
        allow(Dir).to(receive(:glob).with(first_pattern).and_return([library]))
        expect(Dir).not_to(receive(:glob).with(second_pattern))

        expect(described_class.find_lib(pattern)).to(eq(library))
      end

      it 'returns the first matching file within the first matching directory' do
        first_match = File.join(first_dir, 'icuuc77.dll')
        second_match = File.join(first_dir, 'icuuc78.dll')
        allow(Dir).to(receive(:glob).with(first_pattern).and_return([first_match, second_match]))
        expect(Dir).not_to(receive(:glob).with(second_pattern))

        expect(described_class.find_lib(pattern)).to(eq(first_match))
      end

      it 'continues to the next directory when no library matches' do
        library = File.join(second_dir, 'icuuc78.dll')
        expect(Dir).to(receive(:glob).with(first_pattern).ordered.and_return([]))
        expect(Dir).to(receive(:glob).with(second_pattern).ordered.and_return([library]))

        expect(described_class.find_lib(pattern)).to(eq(library))
      end

      it 'returns nil when no directory contains a matching library' do
        allow(Dir).to(receive(:glob).with(first_pattern).and_return([]))
        allow(Dir).to(receive(:glob).with(second_pattern).and_return([]))

        expect(described_class.find_lib(pattern)).to(be_nil)
      end
    end
  end
end
