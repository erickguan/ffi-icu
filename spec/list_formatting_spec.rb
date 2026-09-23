module ICU
  module ListFormatting
    describe 'ListFormatting' do
      before do
        functions = [:ulistfmt_openForType, :ulistfmt_close, :ulistfmt_format]
        skip('Only works on ICU >= 67') unless functions.all? { |function| Lib.respond_to?(function) }
      end

      it 'formats two-item and three-item standard lists' do
        expect(ListFormatting.format(['Alice', 'Bob'], locale: 'en')).to(eq('Alice and Bob'))
        expect(ListFormatting.format(['Alice', 'Bob', 'Jane'], locale: 'en', style: :standard)).
          to(eq('Alice, Bob, and Jane'))
      end

      it 'formats an and list using the explicit style' do
        expect(ListFormatting.format(['Alice', 'Bob', 'Jane'], locale: 'fr', style: :and)).
          to(eq('Alice, Bob et Jane'))
      end

      it 'formats an or list' do
        expect(ListFormatting.format(['Alice', 'Bob', 'Jane'], locale: 'en', style: :or)).
          to(eq('Alice, Bob, or Jane'))
      end

      it 'formats a unit list without a conjunction' do
        expect(ListFormatting.format(['Alice', 'Bob', 'Jane'], locale: 'en', style: :unit)).
          to(eq('Alice, Bob, Jane'))
      end

      it 'handles empty and single-item lists' do
        expect(ListFormatting.format([], locale: 'en')).to(eq(''))
        expect(ListFormatting.format(['Alice'], locale: 'en')).to(eq('Alice'))
      end

      it 'preserves BMP and supplementary Unicode item contents' do
        expect(ListFormatting.format(['José', '東京', '😀🚀'], locale: 'en')).to(eq('José, 東京, and 😀🚀'))
      end

      it 'grows the output buffer for long item contents' do
        items = ['A' * 256, 'B' * 256, 'C' * 256]

        expect(ListFormatting.format(items, locale: 'en')).to(eq("#{items[0]}, #{items[1]}, and #{items[2]}"))
      end

      it 'rejects unknown styles' do
        expect { ListFormatting.format(['Alice', 'Bob'], locale: 'en', style: :unknown) }.
          to(raise_error(ArgumentError, 'Unknown style unknown'))
      end

      it 'requires symbol styles' do
        expect { ListFormatting.format(['Alice', 'Bob'], locale: 'en', style: 'and') }.
          to(raise_error(ArgumentError, 'Unknown style and'))
      end

      it 'rejects non-string items explicitly' do
        expect { ListFormatting.format(['Alice', 2], locale: 'en') }.
          to(raise_error(ArgumentError, 'items must be strings'))
      end

      it 'uses locale-specific conjunction rules' do
        expect(ListFormatting.format(['uno', 'due', 'tre'], locale: 'it', style: :and)).to(eq('uno, due e tre'))
      end
    end
  end
end
