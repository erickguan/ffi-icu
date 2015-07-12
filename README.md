ffi-icu
=======

Simple FFI wrappers for things I need from ICU. For the full thing, check out [ICU4R](http://icu4r.rubyforge.org/) instead.

[![Build Status](https://secure.travis-ci.org/jarib/ffi-icu.png)](http://travis-ci.org/jarib/ffi-icu)

Gem
---

[Rubygem](http://rubygems.org/gems/ffi-icu "ffi-icu")

    gem install ffi-icu

Dependencies
------------

ICU.

If you get messages that the library or functions are not found, you can
set some environment varibles to tell ffi-icu where to find it, e.g.:

    $ export FFI_ICU_LIB="icui18n.so"
    $ export FFI_ICU_VERSION_SUFFIX="_3_8"
    $ ruby -r ffi-icu program.rb

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
* 1.9 support

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
--------------------------

Examples:

```ruby
    # class method interface
    f = ICU::TimeFormatting.format(Time.mktime(2015, 11, 12, 15, 21, 16), {:locale => 'cs_CZ', :zone => 'Europe/Prague', :date => :short, :time => :short})
    f #=> "12.11.15 15:21"

    # reusable formatting objects
    formater = ICU::TimeFormatting.create(:locale => 'cs_CZ', :zone => 'Europe/Prague', :date => :long , :time => :none)
    formater.format(Time.now)  #=> "25. února 2015"
```

```ruby
    # reusable formatting objects
    formater = ICU::TimeFormatting.create(:locale => 'cs_CZ', :zone => 'Europe/Prague', :date => :long , :time => :none)
    formater.parse("25. února 2015") #=> Wed Feb 25 00:00:00 +0100 2015
```

Tested on:
==========

Platforms:

* OS X 10.6 - 10.10
* Travis' Linux

Rubies:

* 1.9.3
* 2.0.0
* 2.1.0
* ruby-head

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
