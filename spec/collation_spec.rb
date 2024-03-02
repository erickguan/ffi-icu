module ICU
  module Collation
    describe 'Collation' do
      it 'collates an array of strings' do
        expect(Collation.collate('nb', ['æ', 'å', 'ø'])).to(eq(['æ', 'ø', 'å']))
      end
    end

    describe Collator do
      let(:collator) { described_class.new('nb') }

      it 'collates an array of strings' do
        expect(collator.collate(['å', 'ø', 'æ'])).to(eq(['æ', 'ø', 'å']))
      end

      it 'raises an error if argument does not respond to :sort' do
        expect { collator.collate(1) }.to(raise_error(ArgumentError))
      end

      it 'returns available locales' do
        locales = ICU::Collation.available_locales
        expect(locales).to(be_an(Array))
        expect(locales).not_to(be_empty)
        expect(locales).to(include('nb'))
      end

      it 'returns the locale of the collator' do
        expect(collator.locale).to(eq('nb'))
      end

      it 'compares two strings' do
        expect(collator.compare('blåbærsyltetøy', 'blah')).to(eq(1))
        expect(collator.compare('blah', 'blah')).to(eq(0))
        expect(collator.compare('ba', 'bl')).to(eq(-1))
      end

      it 'knows if a string is greater than another' do
        expect(collator.greater?('z', 'a')).to(be_truthy)
        expect(collator.greater?('a', 'z')).to(be_falsy)
      end

      it 'knows if a string is greater or equal to another' do
        expect(collator.greater_or_equal?('z', 'a')).to(be_truthy)
        expect(collator.greater_or_equal?('z', 'z')).to(be_truthy)
        expect(collator.greater_or_equal?('a', 'z')).to(be_falsy)
      end

      it 'knows if a string is equal to another' do
        expect(collator.equal?('a', 'a')).to(be_truthy)
        expect(collator.equal?('a', 'b')).to(be_falsy)
      end

      it 'returns rules' do
        expect(collator.rules).not_to(be_empty)
        # ö sorts before Ö
        expect(collator.rules).to(include('ö<<<Ö'))
      end

      it 'returns usable collation keys' do
        collator.collation_key('abc').should(be < collator.collation_key('xyz'))
      end

      context 'attributes' do
        it 'can set and get normalization_mode' do
          collator.normalization_mode = true
          collator.normalization_mode.should(be(true))

          collator[:normalization_mode].should(be(true))
          collator[:normalization_mode] = false
          collator.normalization_mode.should(be(false))

          collator.case_first.should(be(false))
          collator.case_first = :lower_first
          collator.case_first.should

          collator.strength = :tertiary
          collator.strength.should == :tertiary
        end
      end
    end
  end
end
