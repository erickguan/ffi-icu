# encoding: UTF-8

module ICU
  describe TimeFormatting do
    describe 'the TimeFormatting ' do
      t0 = Time.at(1226499676) # in TZ=Europe/Prague Time.mktime(2008, 11, 12, 15, 21, 16)
      t1 = Time.at(1224890117) # in TZ=Europe/Prague Time.mktime(2008, 10, 25, 01, 15, 17)
      t2 = Time.at(1224893778) # in TZ=Europe/Prague Time.mktime(2008, 10, 25, 02, 16, 18)
      t3 = Time.at(1224897439) # in TZ=Europe/Prague Time.mktime(2008, 10, 25, 03, 17, 19)
      t4 = Time.at(1224901100) # in TZ=Europe/Prague Time.mktime(2008, 10, 25, 04, 18, 20)
      t5 = Time.at(1206750921) # in TZ=Europe/Prague Time.mktime(2008, 03, 29, 01, 35, 21)
      t6 = Time.at(1206754582) # in TZ=Europe/Prague Time.mktime(2008, 03, 29, 02, 36, 22)
      t7 = Time.at(1206758243) # in TZ=Europe/Prague Time.mktime(2008, 03, 29, 03, 37, 23)
      t8 = Time.at(1206761904) # in TZ=Europe/Prague Time.mktime(2008, 03, 29, 04, 38, 24)

      f1 = TimeFormatting.create(:locale => 'cs_CZ', :zone => 'Europe/Prague', :date => :long , :time => :long, :tz_style => :localized_long)
      it 'check date_format for lang=cs_CZ' do
        expect(f1.date_format(true)).to eq("d. MMMM y H:mm:ss ZZZZ")
        expect(f1.date_format(false)).to eq("d. MMMM y H:mm:ss ZZZZ")
      end

      it "for lang=cs_CZ zone=Europe/Prague" do
        expect(f1).to be_an_instance_of TimeFormatting::DateTimeFormatter
        expect(f1.format(t0)).to eq("12. listopadu 2008 15:21:16 GMT+01:00")
        expect(f1.format(t1)).to eq("25. října 2008 1:15:17 GMT+02:00")
        expect(f1.format(t2)).to eq("25. října 2008 2:16:18 GMT+02:00")
        expect(f1.format(t3)).to eq("25. října 2008 3:17:19 GMT+02:00")
        expect(f1.format(t4)).to eq("25. října 2008 4:18:20 GMT+02:00")
        expect(f1.format(t5)).to eq("29. března 2008 1:35:21 GMT+01:00")
        expect(f1.format(t6)).to eq("29. března 2008 2:36:22 GMT+01:00")
        expect(f1.format(t7)).to eq("29. března 2008 3:37:23 GMT+01:00")
        expect(f1.format(t8)).to eq("29. března 2008 4:38:24 GMT+01:00")
      end

      f2 = TimeFormatting.create(:locale => 'en_US', :zone => 'Europe/Moscow', :date => :short , :time => :long, :tz_style => :generic_location)
      cldr_version = Lib.cldr_version.to_s
      en_tz  = "Moscow Time"
      en_sep = ","
      if cldr_version <= "2.0.1"
        en_tz  = "Russia Time (Moscow)"
        en_sep = ""
      end

      en_exp = "M/d/yy#{en_sep} h:mm:ss a VVVV"
      it 'check date_format for lang=en_US' do
        expect(f2.date_format(true)).to eq(en_exp)
        expect(f2.date_format(false)).to eq(en_exp)
      end

      it "lang=en_US zone=Europe/Moscow" do
        expect(f2.format(t0)).to eq("11/12/08#{en_sep} 5:21:16 PM #{en_tz}")
        expect(f2.format(t1)).to eq("10/25/08#{en_sep} 3:15:17 AM #{en_tz}")
        expect(f2.format(t2)).to eq("10/25/08#{en_sep} 4:16:18 AM #{en_tz}")
        expect(f2.format(t3)).to eq("10/25/08#{en_sep} 5:17:19 AM #{en_tz}")
        expect(f2.format(t4)).to eq("10/25/08#{en_sep} 6:18:20 AM #{en_tz}")
        expect(f2.format(t5)).to eq("3/29/08#{en_sep} 3:35:21 AM #{en_tz}")
        expect(f2.format(t6)).to eq("3/29/08#{en_sep} 4:36:22 AM #{en_tz}")
        expect(f2.format(t7)).to eq("3/29/08#{en_sep} 5:37:23 AM #{en_tz}")
        expect(f2.format(t8)).to eq("3/29/08#{en_sep} 6:38:24 AM #{en_tz}")
      end

      f3 = TimeFormatting.create(:locale => 'de_DE', :zone => 'Africa/Dakar', :date => :short , :time => :long)
      ge_sep = ""
      if cldr_version >= "27.0.1"
        ge_sep = ","
      end

      ge_exp = "dd.MM.yy#{ge_sep} HH:mm:ss z"
      it 'check date_format for lang=de_DE' do
        expect(f3.date_format(true)).to eq(ge_exp)
        expect(f3.date_format(false)).to eq(ge_exp)
      end

      it "lang=de_DE zone=Africa/Dakar" do
        expect(f3.format(t0)).to eq("12.11.08#{ge_sep} 14:21:16 GMT")
        expect(f3.format(t1)).to eq("24.10.08#{ge_sep} 23:15:17 GMT")
        expect(f3.format(t2)).to eq("25.10.08#{ge_sep} 00:16:18 GMT")
        expect(f3.format(t3)).to eq("25.10.08#{ge_sep} 01:17:19 GMT")
        expect(f3.format(t4)).to eq("25.10.08#{ge_sep} 02:18:20 GMT")
        expect(f3.format(t5)).to eq("29.03.08#{ge_sep} 00:35:21 GMT")
        expect(f3.format(t6)).to eq("29.03.08#{ge_sep} 01:36:22 GMT")
        expect(f3.format(t7)).to eq("29.03.08#{ge_sep} 02:37:23 GMT")
        expect(f3.format(t8)).to eq("29.03.08#{ge_sep} 03:38:24 GMT")
      end

      context 'skeleton pattern' do
        f4 = TimeFormatting.create(:locale => 'fr_FR', :date => :pattern, :time => :pattern, :skeleton => 'MMMy')

        it 'check format' do
          expect(f4.format(t0)).to eq("nov. 2008")
          expect(f4.format(t1)).to eq("oct. 2008")
        end

        it 'check date_format' do
          expect(f4.date_format(true)).to eq("MMM y")
        end
      end

      context 'using skeleton patterns to manipulate 12/24 hour time' do
        it 'can faithfully round-trip 12-hour time patterns' do
          locale = ICU::Locale.new("en_AU@hours=h12")
          formatter = ICU::TimeFormatting::DateTimeFormatter.new(
            time: :long, date: :long, locale: locale.to_s, zone: 'UTC'
          )
          
          sk = formatter.as_skeleton
          sk.gsub!('a', '')
          sk.gsub!(/[hHkK]/, 'j')
          formatter.set_date_format_from_skeleton sk

          formatted_t0 = formatter.format t0
          expect(formatted_t0).to match(/[^0]2\:21/)
          expect(formatted_t0).to match(/pm/i)
        end
        it 'can convert 12-hour patterns to 24 hour time' do
          locale = ICU::Locale.new("en_AU@hours=h23")
          formatter = ICU::TimeFormatting::DateTimeFormatter.new(
            time: :long, date: :long, locale: locale.to_s, zone: 'UTC'
          )
          
          sk = formatter.as_skeleton
          sk.gsub!('a', '')
          sk.gsub!(/[hHkK]/, 'j')
          formatter.set_date_format_from_skeleton sk

          formatted_t0 = formatter.format t0
          expect(formatted_t0).to match(/14\:21/)
          expect(formatted_t0).to_not match(/pm/i)
        end
        it 'can faithfully round-trip 24 hour time patterns' do
          locale = ICU::Locale.new("en_FR@hours=h23")
          formatter = ICU::TimeFormatting::DateTimeFormatter.new(
            time: :long, date: :long, locale: locale.to_s, zone: 'UTC'
          )
          
          sk = formatter.as_skeleton
          sk.gsub!('a', '')
          sk.gsub!(/[hHkK]/, 'j')
          formatter.set_date_format_from_skeleton sk

          formatted_t0 = formatter.format t0
          expect(formatted_t0).to match(/14\:21/)
          expect(formatted_t0).to_not match(/pm/i)
        end
        it 'can convert 24-hour patterns to 12 hour time' do
          locale = ICU::Locale.new("en_FR@hours=h12")
          formatter = ICU::TimeFormatting::DateTimeFormatter.new(
            time: :long, date: :long, locale: locale.to_s, zone: 'UTC'
          )
          
          sk = formatter.as_skeleton
          sk.gsub!('a', '')
          sk.gsub!(/[hHkK]/, 'j')
          formatter.set_date_format_from_skeleton sk

          formatted_t0 = formatter.format t0
          expect(formatted_t0).to match(/[^0]2\:21/)
          expect(formatted_t0).to match(/pm/i)
        end
      end
    end
  end
end
