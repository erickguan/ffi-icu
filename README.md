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

Tested on:
==========

Platforms:

* OS X 10.6
* Arch Linux

Rubies:

* MRI 1.9.1
* MRI 1.8.7

TODO:
=====

* Useful ICU stuff:
  - number formatting (decimal points, thousand separators, currency)
  - date formatting
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

Copyright (c) 2010-2012 Jari Bakken. See LICENSE for details.
