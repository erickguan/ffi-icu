## [Unreleased](https://github.com/erickguan/ffi-icu/compare/v0.7.0...master)

### Added

### Changed

### Fixed

### Removed

## [v0.7.0](https://github.com/erickguan/ffi-icu/compare/v0.6.1...v0.7.0)

### Added

- Add locale-aware list formatting with `ICU::ListFormatting`.
- Add `ICU::Currency` API.
- Add the `:dialect_names` locale display context.
- Add ICU MessageFormat validation and formatting for numbered arguments.

### Changed

### Fixed

- Handle UTF-16 lengths consistently across ICU APIs, including strings containing supplementary Unicode characters.
- Prefer native-architecture Debian multiarch library directories.
- Stop ICU library discovery at the first matching directory to avoid intermittent Windows crashes during PATH scanning.

### Removed

## [v0.6.1](https://github.com/erickguan/ffi-icu/compare/v0.6.0...v0.6.1)

### Changed

- Loosen bigdecimal constraint `'bigdecimal', '>= 3.1'`

## [v0.6.0](https://github.com/erickguan/ffi-icu/compare/v0.5.3...v0.6.0)

### Added

- Add `ICU::Normalizer#normalized?`.

### Changed

- Required Ruby 3.2 and up.
- `ICU::Normalizer#is_normalized?` is deprecated and will be removed after v0.7.

### Fixed


### Removed

- Stop monkeypatching `String#bytesize` or `String#jlength`.
