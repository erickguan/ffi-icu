# ffi-icu

Ruby FFI wrappers for [International Components for Unicode (ICU)][icu].
ICU provides Unicode text processing, character encoding detection, and
locale-aware formatting. Its locale data comes from the
[Common Locale Data Repository (CLDR)][cldr].

## Installation

ffi-icu requires Ruby 3.2 or newer and the ICU shared libraries.
On Linux, use the ICU packages supplied by a major distribution, such as Debian,
Ubuntu, or Fedora. Install ICU from your distribution's supported repositories
before installing the gem.

### Debian and Ubuntu

```sh
sudo apt update
sudo apt install libicu-dev
```

The `libicu-dev` package installs the matching ICU runtime libraries as dependencies.
See the official [Debian package][debian-icu] and [Ubuntu package][ubuntu-icu] pages.

### Fedora

```sh
sudo dnf install libicu
```

See the official [Fedora libicu package][fedora-icu] page.

### Install the gem

```sh
gem install ffi-icu
```

The gem is published on [RubyGems][rubygems]. Load it before running the examples:

```ruby
require('ffi-icu')
```

### ICU in a custom directory

ffi-icu normally discovers the distribution's ICU libraries automatically.
If you need to override discovery, set `FFI_ICU_LIB` to the directory containing
the shared libraries before loading the gem:

```sh
export FFI_ICU_LIB=/opt/icu/lib
ruby my_script.rb
```

The library detects ICU's versioned function names automatically.

## Features

Localized output, including punctuation and spaces, can vary with the installed
ICU and CLDR versions. Duration and list formatting require ICU 67 or newer.

### Character Encoding Detection

Detect an encoding and inspect the confidence score:

```ruby
match = ICU::CharDet.detect('æåø')
match.name       # => "UTF-8"
match.confidence # => 80
```

Reuse a detector for multiple inputs:

```ruby
detector = ICU::CharDet::Detector.new
detector.detect('æåø').name # => "UTF-8"
detector.detect_all('foo bar').is_a?(Array) # => true
```

### Locale-Aware Collation

Sort strings using a locale's collation rules:

```ruby
ICU::Collation.collate('nb', ['å', 'æ', 'ø']) # => ["æ", "ø", "å"]
```

Reuse a collator to compare and sort strings:

```ruby
collator = ICU::Collation::Collator.new('nb')
collator.compare('a', 'b')  # => -1
collator.greater?('z', 'a') # => true
collator.collate(['å', 'æ', 'ø']) # => ["æ", "ø", "å"]
```

### Text Boundary Analysis

Find word boundaries or extract the substrings between them:

```ruby
iterator = ICU::BreakIterator.new(:word, 'en_US')
iterator.text = 'This is a sentence.'
iterator.to_a # => [0, 4, 5, 7, 8, 9, 10, 18, 19]
iterator.substrings # => ["This", " ", "is", " ", "a", " ", "sentence", "."]
```

Boundary offsets use UTF-16 code units. Use `substrings` to extract text without
converting those offsets to Ruby string indexes.

### Number and Currency Formatting

Format numbers, percentages, and currency amounts:

```ruby
ICU::NumberFormatting.format_number('en', 1_000) # => "1,000"
ICU::NumberFormatting.format_number('de-DE', 1_234.56) # => "1.234,56"
ICU::NumberFormatting.format_currency('en', 123.45, 'USD') # => "$123.45"
ICU::NumberFormatting.format_percent('en', 0.53) # => "53%"
ICU::NumberFormatting.spell('en_US', 1_000) # => "one thousand"
ICU::NumberFormatting.format_number('en', BigDecimal('10000.123')) # => "10,000.123"
```

Reuse a formatter for repeated calls. The French Canadian example uses a
non-breaking space (`\u00A0`) as its thousands separator:

```ruby
number_formatter = ICU::NumberFormatting.create('fr-CA')
number_formatter.format(1_000) # => "1\u00A0000"
number_formatter.format(1_000.123) # => "1\u00A0000,123"

currency_formatter = ICU::NumberFormatting.create('en-US', :currency)
currency_formatter.format(1_234.56, 'USD') # => "$1,234.56"
```

### Currency Metadata

Look up ISO 4217 codes, localized names, symbols, and decimal digits:

```ruby
ICU::Currency.for_locale('en_US') # => "USD"
ICU::Currency.for_locale('de_DE') # => "EUR"
ICU::Currency.available(:common).include?('USD') # => true

usd = ICU::Currency.new('usd')
usd.code # => "USD"
usd.symbol('en_US') # => "$"
usd.name('en') # => "US Dollar"
usd.plural_name('en', 'other') # => "US dollars"
usd.fraction_digits # => 2
usd.fraction_digits(:cash) # => 2
usd.numeric_code # => 840

ICU::Currency.new('JPY').fraction_digits # => 0
ICU::Currency.symbol('EUR', 'en_US') # => "€"
```

`narrow_symbol(locale)` requires ICU 61 or newer. `numeric_code` requires ICU 49 or newer.

### Message Formatting

Use numbered arguments for ICU MessageFormat patterns, including plurals and selects:

```ruby
formatter = ICU::MessageFormatting.create(
  '{0, plural, one {# item} other {# items}}',
  locale: 'en-US'
)
formatter.format([1]) # => "1 item"
formatter.format([2]) # => "2 items"

ICU::MessageFormatting.format('Hello, {0}!', locale: 'en-US', arguments: ['Ada'])
# => "Hello, Ada!"
```

Validate a pattern before formatting:

```ruby
pattern = '{0, select, male {He} female {She} other {They}}'
ICU::MessageFormatting.validate(pattern, locale: 'en-US') # => true
ICU::MessageFormatting.valid?('{0, plural', locale: 'en-US') # => false
```

`validate` raises `ICU::MessageFormatting::InvalidPatternError` for an invalid
pattern. The error exposes the pattern, locale, line, and offset. Use `valid?`
when you want a boolean result.

Arguments must be an array of numbered values. Supported types are `String`,
`Integer`, `Float`, and `BigDecimal`. Use strings for simple and select arguments,
and numbers for numeric arguments. Named arguments and rich-text tags are not supported.

### Time Formatting and Parsing

Set the time zone explicitly for predictable output:

```ruby
time = Time.utc(2015, 11, 12, 14, 21)
ICU::TimeFormatting.format(
  time,
  locale: 'cs_CZ', zone: 'Europe/Prague', date: :short, time: :short
)
# => "12.11.15 15:21"
```

Reuse a formatter for formatting and parsing:

```ruby
formatter = ICU::TimeFormatting.create(
  locale: 'cs_CZ', zone: 'Europe/Prague', date: :long, time: :none
)
formatter.format(Time.utc(2015, 2, 25)) # => "25. února 2015"
formatter.parse('25. února 2015').utc.to_s # => "2015-02-24 23:00:00 UTC"
```

Use a skeleton to request date fields and let ICU choose the locale's pattern.
See the [Unicode date field symbol table][date-fields] for supported symbols:

```ruby
formatter = ICU::TimeFormatting.create(
  locale: 'cs_CZ', zone: 'UTC', date: :pattern, time: :pattern, skeleton: 'MMMMy'
)
formatter.format(Time.utc(2015, 2, 25)) # => "únor 2015"
```

Choose an hour cycle with `h11`, `h12`, `h23`, or `h24`, or use `:locale` for the
locale's default:

```ruby
ICU::TimeFormatting.format(
  Time.utc(2021, 4, 1, 12, 5),
  locale: 'en_AU', zone: 'UTC', date: :none, time: :short, hour_cycle: 'h23'
)
# => "12:05"
```

### Duration Formatting

Duration formatting requires ICU 67 or newer. Choose `:long`, `:short`, `:narrow`,
or `:digital`:

```ruby
fields = { hours: 8, minutes: 40, seconds: 35 }
ICU::DurationFormatting.format(fields, locale: 'en-AU', style: :long)
# => "8 hours, 40 minutes, 35 seconds"
ICU::DurationFormatting.format(fields, locale: 'en-AU', style: :short)
# => "8 hrs, 40 mins, 35 secs"
ICU::DurationFormatting.format(fields, locale: 'en-AU', style: :narrow)
# => "8h 40m 35s"
ICU::DurationFormatting.format(fields, locale: 'en-AU', style: :digital)
# => "8:40:35"
```

Reuse a formatter when the locale and style stay the same. Larger units remain
outside the digital clock, and missing or zero fields are omitted:

```ruby
formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'en-AU', style: :digital)
formatter.format({ days: 2, hours: 8, minutes: 40, seconds: 35 }) # => "2d 8:40:35"
formatter.format({ hours: 2, minutes: 40 }) # => "2:40"
formatter.format({ minutes: 40, seconds: 7 }) # => "40:07"

formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'en-AU', style: :long)
formatter.format({ days: 2, minutes: 40, seconds: 0 }) # => "2 days, 40 minutes"
```

Digital formatting folds milliseconds, microseconds, and nanoseconds into seconds.
Supplying a smaller unit preserves its trailing zeros:

```ruby
formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'en-AU', style: :digital)
formatter.format({ hours: 5, minutes: 7, seconds: 23, milliseconds: 98, microseconds: 997 })
# => "5:07:23.098997"
formatter.format({ hours: 5, minutes: 7, seconds: 23, milliseconds: 400 })
# => "5:07:23.400"
formatter.format({ hours: 5, minutes: 7, seconds: 23, milliseconds: 400, microseconds: 700 })
# => "5:07:23.400700"
```

Fractional parts are truncated except on the smallest supplied unit, which must
be seconds or smaller to retain a fraction:

```ruby
formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'en-AU', style: :long)
formatter.format({ days: 2, hours: 7.3, minutes: 40.9, seconds: 0.43 })
# => "2 days, 7 hours, 40 minutes, 0.43 seconds"
```

Unit names and separators follow the requested locale:

```ruby
formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'ru', style: :long)
formatter.format({ hours: 1, minutes: 2, seconds: 3 }) # => "1 час 2 минуты 3 секунды"
formatter.format({ hours: 10, minutes: 20, seconds: 30 }) # => "10 часов 20 минут 30 секунд"

formatter = ICU::DurationFormatting::DurationFormatter.new(locale: 'ru', style: :narrow)
formatter.format({ hours: 1, minutes: 2, seconds: 3 }) # => "1 ч 2 мин 3 с"
```

### Transliteration

Convert between scripts or reuse a transliterator for multiple inputs:

```ruby
ICU::Transliteration.transliterate('Traditional-Simplified', '沈從文') # => "沈从文"

transliterator = ICU::Transliteration::Transliterator.new('Latin-ASCII')
transliterator.transliterate('café') # => "cafe"
```

Apply a sequence of custom transliteration rules:

```ruby
ICU::Transliteration.translit('NFD; [:Nonspacing Mark:] Remove; NFC', 'âêîôû') # => "aeiou"
```

### Unicode Normalization

Compose canonically equivalent text into NFC, or check whether it is already normalized:

```ruby
normalizer = ICU::Normalizer.new(nil, 'nfc', :compose)
normalizer.normalize("A\u030A") # => "Å"
normalizer.normalized?('Å') # => true
normalizer.normalized?("A\u030A") # => false
```

Use `:decompose` with `'nfc'` for NFD. Use `'nfkc'` with `:compose` or `:decompose`
for compatibility normalization (NFKC or NFKD):

```ruby
normalizer = ICU::Normalizer.new(nil, 'nfkc', :compose)
normalizer.normalize('ﬃ') # => "ffi"
```

A convenience method also supports one-off normalization:

```ruby
ICU::Normalization.normalize('Å', :nfd) # => "A\u030A"
ICU::Normalization.normalize("A\u030A", :nfc) # => "Å"
```

### List Formatting

List formatting requires ICU 67 or newer. Join strings with locale-aware
separators and conjunctions:

```ruby
ICU::ListFormatting.format(['Alice', 'Bob', 'Jane'], locale: 'en') # => "Alice, Bob, and Jane"
ICU::ListFormatting.format(['Alice', 'Bob', 'Jane'], locale: 'fr', style: :and) # => "Alice, Bob et Jane"
ICU::ListFormatting.format(['Alice', 'Bob', 'Jane'], locale: 'en', style: :or) # => "Alice, Bob, or Jane"
ICU::ListFormatting.format(['Alice', 'Bob', 'Jane'], locale: 'en', style: :unit) # => "Alice, Bob, Jane"
```

The default style is `:and`. Styles must be symbols, and all items must be strings.
The formatter uses ICU's wide list width.

### Locale

Look up localized names and choose display-name contexts:

```ruby
locale = ICU::Locale.new('en-US')
locale.display_country('en-US') # => "United States"
locale.display_language('es') # => "inglés"
locale.display_name('es') # => "inglés (Estados Unidos)"
locale.display_name_with_context('en-US', [:length_short]) # => "English (US)"
locale.display_name_with_context('en-US', [:length_full]) # => "English (United States)"

ICU::Locale.new('fa-AF').display_name_with_context('en', [:dialect_names]) # => "Dari"
```

Convert BCP 47 language tags to ICU locale IDs or add likely subtags:

```ruby
locale = ICU::Locale.for_language_tag('en-US')
locale.id # => "en_US"
locale.to_language_tag # => "en-US"
ICU::Locale.new('en').with_likely_subtags.to_s # => "en_Latn_US"
```

## Benchmarks

Benchmarks live in [`benchmark/`](benchmark/README.md) with a separate Gemfile.

[icu]: https://github.com/unicode-org/icu
[cldr]: https://cldr.unicode.org/
[rubygems]: https://rubygems.org/gems/ffi-icu
[debian-icu]: https://packages.debian.org/stable/libicu-dev
[ubuntu-icu]: https://packages.ubuntu.com/search?keywords=libicu-dev
[fedora-icu]: https://packages.fedoraproject.org/pkgs/icu/libicu/
[date-fields]: https://unicode-org.github.io/icu/userguide/format_parse/datetime/#date-field-symbol-table
