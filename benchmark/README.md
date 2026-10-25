# Benchmarks

Compares `ffi-icu` with other Ruby libraries using Ruby's standard
[`benchmark`](https://github.com/ruby/benchmark) library:

- **Character detection** — `ffi-icu` against [`rchardet`](https://rubygems.org/gems/rchardet)
- **Number and currency formatting** — `ffi-icu` against [`icu4x`](https://rubygems.org/gems/icu4x) and [`twitter_cldr`](https://rubygems.org/gems/twitter_cldr)
- **Transliteration** — `ffi-icu` against `twitter_cldr`. The `icu4x` 0.11.2 Ruby binding has no transliteration API, so no timing is available for it.
- **Locale display names** — `ffi-icu` against `icu4x` and `twitter_cldr`

Each group runs `Benchmark.bmbm`, which makes a rehearsal pass and then a
measured pass. Each report block uses `Integer#times` because `bmbm` has no
iteration-count parameter; its argument controls label width. See the
[iteration API research](iteration-research.md) for sources and measurement details.

## Run

The benchmarks have their own Gemfile to keep their dependencies separate.

```sh
cd benchmark
bundle install
./run.sh
```

`icu4x` requires Ruby 3.3 or newer.

Run one suite at a time:

```sh
cd benchmark
bundle exec ruby detect.rb
bundle exec ruby formatters.rb
bundle exec ruby transliteration.rb
bundle exec ruby locale.rb
```

## Recorded output

The following output comes from a run of `./benchmark/run.sh` with the default
iteration counts.

- Operating system: WSL2 Linux, x86_64.
- Processor: AMD Ryzen 9 7950X, as reported by `lscpu`.
- Memory: 45.94 GiB of RAM visible to WSL, from `/proc/meminfo`.
- Ruby: 4.0.5.
- `ffi-icu`: 0.7.0.
- ICU: 78.2.
- `rchardet`: 1.10.2.
- `icu4x`: 0.11.2.
- `twitter_cldr`: 6.14.0.

Measured passes and relative timings from that run (rehearsal output omitted):

```text
Character detection (class helper)
               user     system      total        real
ffi-icu    0.003286   0.000003   0.003289 (  0.003287)
rchardet   0.026833   0.000000   0.026833 (  0.026835)
Relative real time (lower is better):
  ffi-icu        1.00x
  rchardet       8.16x

Character detection (reusable detector)
               user     system      total        real
ffi-icu    0.003275   0.000000   0.003275 (  0.003275)
rchardet   0.027931   0.000000   0.027931 (  0.027933)
Relative real time (lower is better):
  ffi-icu        1.00x
  rchardet       8.53x

Number formatting
                   user     system      total        real
ffi-icu        0.002031   0.000000   0.002031 (  0.002029)
icu4x          0.000117   0.000000   0.000117 (  0.000116)
twitter_cldr   0.019097   0.000000   0.019097 (  0.019098)
Relative real time (lower is better):
  ffi-icu       17.50x
  icu4x          1.00x
  twitter_cldr 164.79x

Currency formatting
                   user     system      total        real
ffi-icu        0.002970   0.000000   0.002970 (  0.002969)
icu4x          0.000125   0.000034   0.000159 (  0.000157)
twitter_cldr   0.019952   0.000039   0.019991 (  0.019992)
Relative real time (lower is better):
  ffi-icu       18.96x
  icu4x          1.00x
  twitter_cldr 127.64x

Transliteration (Greek to Latin)
                   user     system      total        real
ffi-icu        0.006334   0.000041   0.006375 (  0.006373)
twitter_cldr   0.015077   0.000232   0.015309 (  0.015308)
Relative real time (lower is better):
  ffi-icu        1.00x
  twitter_cldr   2.40x

Locale display names (language names in English)
                   user     system      total        real
ffi-icu        0.012283   0.000000   0.012283 (  0.012284)
icu4x          0.000661   0.000000   0.000661 (  0.000660)
twitter_cldr   0.014420   0.000000   0.014420 (  0.014421)
Relative real time (lower is better):
  ffi-icu       18.60x
  icu4x          1.00x
  twitter_cldr  21.84x
```

`1.00x` is the fastest library in that group. Higher numbers are slower.

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `DETECT_ITERATIONS` | `5` | Character-detection iterations per library |
| `FORMATTER_ITERATIONS` | `500` | Number/currency iterations per library |
| `TRANSLITERATION_ITERATIONS` | `120` | Transliteration iterations per library |
| `LOCALE_ITERATIONS` | `6000` | Locale-display iterations per library |
| `DETECT_TEXT_PATH` | `benchmark/fixtures/detect.txt` | Input file for detection |

## Reading the results

`Benchmark.bmbm` reports `user`, `system`, `total`, and `real` seconds. The
same iteration count is used within a group, so the real-time columns are
directly comparable there. Iteration counts differ between groups, so compare
only within a group.

Results are machine-specific. Compare libraries within one run, not across
machines or Ruby versions.
