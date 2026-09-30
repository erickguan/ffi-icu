# frozen_string_literal: true

module ICU
  module MessageFormatting
    describe 'MessageFormatting' do
      describe '.validate' do
        it 'accepts a valid numbered message pattern' do
          expect(MessageFormatting.validate('{0, plural, one {# item} other {# items}}', locale: 'en-US')).to(be(true))
        end

        it 'raises an error with parse details for an invalid pattern' do
          expect do
            MessageFormatting.validate('{0, plural, one {# item}', locale: 'en-US')
          end.to(raise_error(InvalidPatternError) do |error|
            expect(error.locale).to(eq('en-US'))
            expect(error.pattern).to(eq('{0, plural, one {# item}'))
            expect(error.offset).to(be >= 0)
          end)
        end
      end

      describe '.valid?' do
        it 'returns true for a valid numbered message pattern' do
          expect(MessageFormatting.valid?('{0, plural, one {# item} other {# items}}', locale: 'en-US')).to(be(true))
        end

        it 'returns false for an invalid pattern' do
          expect(MessageFormatting.valid?('{0, plural, one {# item}', locale: 'en-US')).to(be(false))
        end
      end

      describe '.format' do
        it 'formats a numbered string argument' do
          pattern = 'Hello, {0}!'

          expect(MessageFormatting.format(pattern, locale: 'en-US', arguments: ['Ada'])).to(eq('Hello, Ada!'))
        end

        it 'formats multiple string arguments' do
          pattern = '{0} and {1}'

          expect(MessageFormatting.format(pattern, locale: 'en-US',
                                                   arguments: ['Ada', 'Grace'])).to(eq('Ada and Grace'))
        end

        it 'formats plural arguments using the locale' do
          pattern = '{0, plural, one {# item} other {# items}}'

          expect(MessageFormatting.format(pattern, locale: 'en-US', arguments: [1])).to(eq('1 item'))
          expect(MessageFormatting.format(pattern, locale: 'en-US', arguments: [2])).to(eq('2 items'))
        end

        it 'formats select arguments' do
          pattern = '{0, select, male {He} female {She} other {They}}'

          expect(MessageFormatting.format(pattern, locale: 'en-US', arguments: ['female'])).to(eq('She'))
          expect(MessageFormatting.format(pattern, locale: 'en-US', arguments: ['unknown'])).to(eq('They'))
        end

        it 'supports reusable formatter instances' do
          formatter = MessageFormatting.create('{0, plural, one {# item} other {# items}}', locale: 'en-US')

          expect(formatter.format([1])).to(eq('1 item'))
          expect(formatter.format([3])).to(eq('3 items'))
        end

        it 'supports decimal arguments' do
          pattern = '{0, number}'

          expect(MessageFormatting.format(pattern, locale: 'en-US', arguments: [1.5])).to(eq('1.5'))
        end

        it 'supports Unicode arguments' do
          expect(MessageFormatting.format('Hello, {0}!', locale: 'en-US', arguments: ['😀'])).to(eq('Hello, 😀!'))
        end

        it 'rejects unsupported argument types' do
          formatter = MessageFormatting.create('{0}', locale: 'en-US')

          expect { formatter.format([Object.new]) }.to(raise_error(ArgumentError, /unsupported/))
        end

        it 'requires an Array of numbered arguments' do
          formatter = MessageFormatting.create('{0}', locale: 'en-US')

          expect { formatter.format(name: 'Ada') }.to(
            raise_error(ArgumentError, /Array of numbered values/)
          )
        end

        it 'rejects too few numbered arguments before calling ICU' do
          formatter = MessageFormatting.create('{1}', locale: 'en-US')

          expect { formatter.format(['Ada']) }.to(
            raise_error(ArgumentError, /at least 2 numbered arguments/)
          )
        end

        it 'does not treat quoted argument syntax as an argument' do
          expect(MessageFormatting.format("'{0}'", locale: 'en-US', arguments: [])).to(eq('{0}'))
        end

        it 'rejects a String passed to a numeric argument slot' do
          formatter = MessageFormatting.create('{0, plural, one {# item} other {# items}}', locale: 'en-US')

          expect { formatter.format(['two']) }.to(
            raise_error(ArgumentError, /argument 0 expects a numeric value, got String/)
          )
        end

        it 'rejects a number passed to a select argument slot' do
          formatter = MessageFormatting.create('{0, select, male {He} female {She} other {They}}', locale: 'en-US')

          expect { formatter.format([1]) }.to(
            raise_error(ArgumentError, /argument 0 expects a String, got Integer/)
          )
        end

        it 'rejects a number passed to a simple argument slot' do
          formatter = MessageFormatting.create('Hello, {0}!', locale: 'en-US')

          expect { formatter.format([42]) }.to(
            raise_error(ArgumentError, /argument 0 expects a String, got Integer/)
          )
        end

        it 'accepts a numeric argument for a date slot' do
          formatter = MessageFormatting.create('{0, date, full}', locale: 'en-US')

          expect(formatter.format([0])).to(be_a(String))
        end
      end
    end
  end
end
