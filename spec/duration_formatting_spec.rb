module ICU
    module DurationFormatting
        describe 'DurationFormatting::format' do
            before(:each) do
                skip("Only works on ICU >= 67") if Lib.version.to_a[0] < 67
              end

            it 'produces hours, minutes, and seconds in order' do
                result = DurationFormatting.format({hours: 1, minutes: 2, seconds: 3}, locale: 'C', style: :long)
                expect(result).to match(/1.*hour.*2.*minute.*3.*second/i)
            end

            it 'rounds down fractional seconds < 0.5' do
                result = DurationFormatting.format({seconds: 5.4}, locale: 'C', style: :long)
                expect(result).to match(/5.*second/i)
            end

            it 'rounds up fractional seconds > 0.5' do
                result = DurationFormatting.format({seconds: 5.6}, locale: 'C', style: :long)
                expect(result).to match(/6.*second/i)
            end

            it 'trims off leading zero values' do
                result = DurationFormatting.format({hours: 0, minutes: 1, seconds: 30}, locale: 'C', style: :long)
                expect(result).to match(/1.*minute.*30.*second/i)
                expect(result).to_not match(/hour/i)
            end

            it 'trims off leading missing values' do
                result = DurationFormatting.format({minutes: 1, seconds: 30}, locale: 'C', style: :long)
                expect(result).to match(/1.*minute.*30.*second/i)
                expect(result).to_not match(/hour/i)
            end

            it 'trims off non-leading zero values' do
                result = DurationFormatting.format({hours: 1, minutes: 0, seconds: 10}, locale: 'C', style: :long)
                expect(result).to match(/1.*hour.*10.*second/i)
                expect(result).to_not match(/minute/i)
            end

            it 'trims off non-leading missing values' do
                result = DurationFormatting.format({hours: 1, seconds: 10}, locale: 'C', style: :long)
                expect(result).to match(/1.*hour.*10.*second/i)
                expect(result).to_not match(/minute/i)
            end

            it 'uses comma-based number formatting as appropriate for locale' do
                result = DurationFormatting.format({seconds: 90123}, locale: 'en-AU', style: :long)
                expect(result).to match(/90,123.*second/i)
                expect(result).to_not match(/hour/i)
                expect(result).to_not match(/minute/i)
            end

            it 'localizes unit names' do
                result = DurationFormatting.format({hours: 1, minutes: 2, seconds: 3}, locale: 'el', style: :long)
                expect(result).to match(/1.*ώρα.*2.*λεπτά.*3.*δευτερόλεπτα/i)
            end

            it 'can format long' do
                result = DurationFormatting.format({hours: 1, minutes: 2, seconds: 3}, locale: 'en-AU', style: :long)
                expect(result).to match(/hour.*minute.*second/i)
            end

            it 'can format short' do
                result = DurationFormatting.format({hours: 1, minutes: 2, seconds: 3}, locale: 'en-AU', style: :short)
                expect(result).to match(/hr.*min.*sec/i)
                expect(result).to_not match(/hour/i)
                expect(result).to_not match(/minute/i)
                expect(result).to_not match(/second/i)
            end

            it 'can format narrow' do
                result = DurationFormatting.format({hours: 1, minutes: 2, seconds: 3}, locale: 'en-AU', style: :narrow)
                expect(result).to match(/h.*min.*s/i)
                expect(result).to_not match(/hr/i)
                expect(result).to_not match(/sec/i)
            end

            it 'can format digital' do
                result = DurationFormatting.format({hours: 1, minutes: 2, seconds: 3}, locale: 'en-AU', style: :digital)
                expect(result).to eql('1:02:03')
            end

            it 'can format the full sequence of time units in order' do
                duration = {
                    years: 1,
                    months: 2,
                    weeks: 3,
                    days: 4,
                    hours: 5,
                    minutes: 6,
                    seconds: 7,
                    milliseconds: 8,
                    microseconds: 9,
                    nanoseconds: 10,
                }
                result = DurationFormatting.format(duration, locale: 'en-AU', style: :short)
                expect(result).to match(/1.yr.*2.*mths.*3.*wks.*4.*days.*5.*hrs.*6.*mins.*7.*secs.*8.*ms.*9.*μs.*10.*ns/)
            end

            it 'joins ms, us, ns values to seconds in digital format' do
                duration = {minutes: 10, seconds: 5, milliseconds: 325, microseconds: 53, nanoseconds: 236}
                result = DurationFormatting.format(duration, locale: 'en-AU', style: :digital)
                expect(result).to eql('10:05.325053236')
            end

            it 'includes trailing zeros as appropriate for the last unit in digital format' do
                duration = {minutes: 10, seconds: 5, milliseconds: 325, microseconds: 400}
                result = DurationFormatting.format(duration, locale: 'en-AU', style: :digital)
                expect(result).to eql('10:05.325400')
            end

            it 'joins h:mm:ss and other units in digital format' do
                duration = {days: 8, hours: 23, minutes: 10, seconds: 9}
                result = DurationFormatting.format(duration, locale: 'en-AU', style: :digital)
                expect(result).to match(/8.*d.*23:10:09/  )
            end

            it 'ignores all decimal parts except the last, if it is seconds' do
                duration = {hours: 7.3, minutes: 9.7, seconds: 8.93}
                result = DurationFormatting.format(duration, locale: 'en-AU', style: :short)
                expect(result).to match(/7[^0-9]*hrs.*9[^0-9]*min.*8\.93[^0-9]*secs/)
            end

            it 'ignores all decimal parts except the last, if it is milliseconds' do
                duration = {hours: 7.3, minutes: 9.7, seconds: 8.93, milliseconds: 632.2}
                result = DurationFormatting.format(duration, locale: 'en-AU', style: :short)
                expect(result).to match(/7[^0-9]*hrs.*9[^0-9]*min.*8[^0-9]*secs.*632\.2[^0-9]*ms/)
            end

            it 'ignores all decimal parts including the last, if it is > seconds' do
                duration = {hours: 7.3, minutes: 9.7}
                result = DurationFormatting.format(duration, locale: 'en-AU', style: :short)
                expect(result).to match(/7[^0-9]*hrs.*9[^0-9]*min/)
            end

            it 'raises on durations with any negative component' do
                duration = {hours: 7.3, minutes: -9.7}
                expect { DurationFormatting.format(duration, locale: 'en-AU') }.to raise_error(ArgumentError)
            end
        end
    end
end
