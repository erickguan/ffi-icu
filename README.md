# offi-icu

A small proof of concept that rebuilds the calendar part of ICU bindings as a
Magnus Ruby extension.

The extension:

- generates ICU C types from the installed headers with `bindgen`;
- keeps generated/unsafe bindings separate in `src/bindings.rs`;
- loads ICU dynamically with `libloading` instead of linking to one ICU major;
- detects unversioned symbols or major-suffixed symbols such as `ucal_open_78`;
- exposes one feature, `ICU::Calendar`, to Ruby through Magnus.

## Build and test

ICU development headers, Ruby development headers, libclang, and Rust are
required.

```sh
LIBCLANG_PATH=/usr/lib/llvm-21/lib rake test
```

For a non-standard ICU install, set `ICU_INCLUDE_DIR` while building. At
runtime, `OFFI_ICU_UC_LIB` and `OFFI_ICU_I18N_LIB` can point to exact library
files.

## Ruby API

```ruby
require 'offi-icu'

calendar = ICU::Calendar.new('America/New_York', 'en-US')
calendar.set_date_time(2020, 4, 7, 21, 0, 0) # month is zero-based

calendar.millis
calendar.field('day')
calendar.zone_offset
calendar.dst_offset
calendar.in_daylight_time?

ICU.version        # => "78.2.0.0"
ICU.symbol_version # => "major-suffixed (78)"
```
