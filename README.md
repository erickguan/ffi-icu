ffi-icu [![Build Status](https://app.travis-ci.com/erickguan/ffi-icu.svg?branch=master)](https://app.travis-ci.com/erickguan/ffi-icu)
=======

Simple FFI wrappers for ICU. Checkout the renovated [ICU gem](https://github.com/fantasticfears/icu4r) instead which supports various of encoding and distributed with packaged source. FFI-ICU needs some love with ICU gem's transcoding method.

Gem
---

[Rubygem](http://rubygems.org/gems/ffi-icu "ffi-icu")

    gem install ffi-icu

Dependencies
------------

ICU.

If you get messages that the library or functions are not found, you can
set some environment variables to tell ffi-icu where to find it, e.g.:

```sh
$ export FFI_ICU_LIB="icui18n.so"
$ export FFI_ICU_VERSION_SUFFIX="_3_8"
$ ruby -r ffi-icu program.rb
```

Features
========

Character Encoding Detection
----------------------------

Examples:

```ruby
match = ICU::CharDet.detect(str)
match.name       # => "UTF-8"
match.confidence # => 80
```

or

```ruby
detector = ICU::CharDet::Detector.new
detector.detect(str) => #<struct ICU::CharDet::Detector::Match ...>
```

Why not just use rchardet?

* speed

Locale Sensitive Collation
--------------------------

Examples:

```ruby
ICU::Collation.collate("nb", %w[å æ ø]) == %w[æ ø å] #=> true
```

or

```ruby
collator = ICU::Collation::Collator.new("nb")
collator.compare("a", "b")  #=> -1
collator.greater?("z", "a") #=> true
collator.collate(%w[å æ ø]) #=> ["æ", "ø", "å"]
```

Text Boundary Analysis
----------------------

Examples:

```ruby
iterator = ICU::BreakIterator.new(:word, "en_US")
iterator.text = "This is a sentence."
iterator.to_a  #=> [0, 4, 5, 7, 8, 9, 10, 18, 19]
```

Number/Currency Formatting
--------------------------

Examples:

```ruby
# class method interface
ICU::NumberFormatting.format_number("en", 1_000) #=> "1,000"
ICU::NumberFormatting.format_number("de-DE", 1234.56) #=> "1.234,56"
ICU::NumberFormatting.format_currency("en", 123.45, 'USD') #=> "$123.45"
ICU::NumberFormatting.format_percent("en", 0.53, 'USD') #=> "53%"
ICU::NumberFormatting.spell("en_US", 1_000) #=> "one thousand"

# reusable formatting objects
numf = ICU::NumberFormatting.create('fr-CA')
numf.format(1000) #=> "1 000"

curf = ICU::NumberFormatting.create('en-US', :currency)
curf.format(1234.56, 'USD') #=> "$1,234.56"
```

Time Formatting/Parsing
-----------------------

Examples:

```ruby
# class method interface
f = ICU::TimeFormatting.format(Time.mktime(2015, 11, 12, 15, 21, 16), {:locale => 'cs_CZ', :zone => 'Europe/Prague', :date => :short, :time => :short})
f #=> "12.11.15 15:21"

# reusable formatting objects
formatter = ICU::TimeFormatting.create(:locale => 'cs_CZ', :zone => 'Europe/Prague', :date => :long, :time => :none)
formatter.format(Time.now)  #=> "25. února 2015"
```

```ruby
# reusable formatting objects
formatter = ICU::TimeFormatting.create(:locale => 'cs_CZ', :zone => 'Europe/Prague', :date => :long, :time => :none)
formatter.parse("25. února 2015") #=> Wed Feb 25 00:00:00 +0100 2015
```

For skeleton formatting, visit the [Unicode date field symbol table](https://unicode-org.github.io/icu/userguide/format_parse/datetime/#date-field-symbol-table) page to help find the pattern characters to use.

```ruby
formatter = ICU::TimeFormatting.create(:locale => 'cs_CZ', :date => :pattern, :time => :pattern, :skeleton => 'MMMMY')
formatter.format(Time.now)  #=> "únor 2015"

formatter = ICU::TimeFormatting.create(:locale => 'cs_CZ', :date => :pattern, :time => :pattern, :skeleton => 'Y')
formatter.format(Time.now)  #=> "2015"
```

Duration Formatting
-------------------

```ruby
# What the various styles look like
formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'en-AU', style: :long)
formatter.format({hours: 8, minutes: 40, seconds: 35})  #=> "8 hours, 40 minutes, 35 seconds"

formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'en-AU', style: :short)
formatter.format({hours: 8, minutes: 40, seconds: 35})  #=> "8 hrs, 40 mins, 35 secs"

formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'en-AU', style: :narrow)
formatter.format({hours: 8, minutes: 40, seconds: 35})  #=> "8h 40min. 35s."
formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'en-AU', style: :digital)
formatter.format({hours: 8, minutes: 40, seconds: 35})  #=> "8:40:35"

# How digital & non-digital formats deal with units > hours
formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'en-AU', style: :narrow)
formatter.format({days: 2, hours: 8, minutes: 40, seconds: 35})  #=> "2d 8h 40min. 35s."
formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'en-AU', style: :digital)
formatter.format({days: 2, hours: 8, minutes: 40, seconds: 35})  #=> "2d 8:40:35"

# Missing or zero parts are omitted
formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'en-AU', style: :long)
formatter.format({days: 2, minutes: 40, seconds:0})  #=> "2 days, 40 minutes"

formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'en-AU', style: :digital)
formatter.format({hours: 2, minutes: 40})  #=> "2:40"

formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'en-AU', style: :digital)
formatter.format({minutes: 40, seconds: 7})  #=> "40:07"

# Sub-second parts are folded into seconds for digital display
formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'en-AU', style: :digital)
formatter.format({hours: 5, minutes: 7, seconds: 23, milliseconds: 98, microseconds: 997})  #=> "5:07:23.098997"

# Zero-extension of sub-second parts in digital style
formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'en-AU', style: :digital)
formatter.format({hours: 5, minutes: 7, seconds: 23, milliseconds: 400})  #=> "5:07:23.400"
formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'en-AU', style: :digital)
formatter.format({hours: 5, minutes: 7, seconds: 23, milliseconds: 400, microseconds: 700})  #=> "5:07:23.400700"

# All fractional parts except the last are truncated
formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'en-AU', style: :long)
formatter.format({days: 2, hours: 7.3, minutes: 40.9, seconds:0.43})  #=> "2 days, 7 hours, 40 minutes, 0.43 seconds"

# With RU locale
formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'ru', style: :long)
formatter.format({hours: 1, minutes: 2, seconds: 3})  #=> "1 час 2 минуты 3 секунды"
formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'ru', style: :long)
formatter.format({hours: 10, minutes: 20, seconds: 30})  #=> "10 часов 20 минут 30 секунд"
formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'ru', style: :narrow)
formatter.format({hours: 1, minutes: 2, seconds: 3})  #=> "1 ч 2 мин 3 с"
formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'ru', style: :narrow)
formatter.format({hours: 10, minutes: 20, seconds: 30})  #=> "10 ч 20 мин 30 с"
```

Transliteration
---------------

Example:

```ruby
ICU::Transliteration.transliterate('Traditional-Simplified', '沈從文') # => "沈从文"
```

Locale
------

Examples:

```ruby
locale = ICU::Locale.new('en-US')
locale.display_country('en-US') #=> "United States"
locale.display_language('es') #=> "inglés"
locale.display_name('es') #=> "inglés (Estados Unidos)"
locale.display_name_with_context('en-US', [:length_short]) #=> "English (US)"
locale.display_name_with_context('en-US', [:length_long])  #=> "English (United States)"
```

TODO:
=====

* Any other useful part of ICU?
* Windows?!

Note on Patches/Pull Requests
=============================

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

Copyright
=========

Copyright (c) 2010-2015 Jari Bakken. See LICENSE for details.
