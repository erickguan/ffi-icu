# offi-icu

A Magnus proof of concept for selected ICU4C features:

- `ICU::Calendar`
- `ICU::NumberFormatter`
- `ICU::CurrencyFormatter`

The extension loads ICU dynamically with `libloading`. It detects unversioned
symbols or major-suffixed symbols such as `ucal_open_78`, so the gem does not
link to one ICU major version at build time. Raw ICU handles, function pointers,
symbol resolution, and all `unsafe` calls are confined to the internal ICU
module; the calendar, number, and Magnus layers use safe Rust interfaces.

This tests concept whether I could build an ffi layer with icu4c enabled.
Some Rust upstreamt might not want to do this and there is also icu4x.

## Build and test

Normal gem builds do not require separately installed ICU development headers
or `pkg-config`. The ICU headers used to generate the raw bindings and the
generated Rust file are checked into the repository.

Ruby development headers, Rust, and an ICU runtime library are required.
Magnus currently uses `rb-sys`, which runs bindgen for Ruby's own C API during a
source build, so libclang is still a Magnus build requirement. ICU binding
generation is no longer part of the normal build.

```sh
rake test
```

At runtime, `OFFI_ICU_UC_LIB` and `OFFI_ICU_I18N_LIB` can point to exact ICU
library files.

## Ruby API

```ruby
require 'offi-icu'

calendar = ICU::Calendar.new('America/New_York', 'en-US')
calendar.set_date_time(2020, 4, 7, 21, 0, 0) # month is zero-based
calendar.field('day')
calendar.zone_offset
calendar.dst_offset
calendar.in_daylight_time?

numbers = ICU::NumberFormatter.new('en-US')
numbers.format(1_000.123) # => "1,000.123"

currency = ICU::CurrencyFormatter.new('en-US', 'standard')
currency.format(1_000.12, 'USD') # => "$1,000.12"

iso_currency = ICU::CurrencyFormatter.new('en-US', 'iso')
plural_currency = ICU::CurrencyFormatter.new('en-US', 'plural')

ICU.version
ICU.symbol_version
```

## Updating ICU headers and bindings

Headers are vendored under `vendor/icu`. To update them:

```sh
ICU_VERSION=78.2 scripts/download-icu-headers.sh
```

Binding regeneration is a maintainer-only operation. It requires the bindgen
CLI and libclang:

```sh
cargo install bindgen-cli --version 0.72.1
scripts/generate-bindings.sh
```

The generated bindings stay isolated in `src/bindings/generated.rs`; normal
users do not run bindgen.

## Benchmarks

The formatter benchmark compares `offi-icu`, `ffi-icu`, and `twitter_cldr`
after three warmup rounds. It records throughput and Ruby heap allocations,
running once with YJIT disabled and once with YJIT enabled:

```sh
benchmark/run.sh
```

See `benchmark/README.md` for iteration and path configuration.
