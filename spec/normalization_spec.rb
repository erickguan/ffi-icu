module ICU
  module Normalization
    #  http://bugs.icu-project.org/trac/browser/icu/trunk/source/test/cintltst/cnormtst.c

    describe 'Normalization' do
      it 'normalizes a string - decomposed' do
        expect(ICU::Normalization.normalize('Å', :nfd).unpack('U*')).to(eq([65, 778]))
      end

      it 'normalizes a string - composed' do
        expect(ICU::Normalization.normalize('Å', :nfc).unpack('U*')).to(eq([197]))
      end

      it 'handles supplementary characters' do
        expect(ICU::Normalization.normalize('😀', :nfc)).to(eq('😀'))
      end

      it 'handles empty input' do
        expect(ICU::Normalization.normalize('', :nfc)).to(eq(''))
      end

      it 'returns the expanded decomposed output without a trailing NUL' do
        result = ICU::Normalization.normalize('Å', :nfd)

        expect(result).to(eq("A\u030A"))
        expect(result).not_to(include("\0"))
      end

      it 'composes combining marks' do
        expect(ICU::Normalization.normalize("A\u030A", :nfc)).to(eq('Å'))
      end

      # TODO: add more normalization tests
    end
  end
end
