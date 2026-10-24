# Formatter benchmarks

Benchmarks number and currency formatting throughput in `ffi-icu` only.

## Run

```sh
bundle install
ruby benchmark/formatters.rb
```

Example output:

```text
Ruby: ruby 4.0.5 (...) +PRISM [x86_64-linux]
ffi-icu: 0.7.0
ICU: 78.2 (78.2.0.0)
Warmup: 5000 iterations
Measurement: 30000 iterations

number formatting   0.1096s    273,723 iterations/s
currency formatting 0.1684s    178,147 iterations/s
```

The whole benchmark runs in around 300ms — sub-second, but long enough to be
meaningful feedback after a change.

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `ITERATIONS` | `30_000` | Measurement iterations per case |
| `WARMUP_ITERATIONS` | `5_000` | Warmup iterations before measuring |

```sh
ITERATIONS=100_000 WARMUP_ITERATIONS=20_000 ruby benchmark/formatters.rb
```

## What it measures

- `number formatting` — `ICU::NumberFormatting.create('en-US').format(1_234_567.89)`
- `currency formatting` — `ICU::NumberFormatting.create('en-US', :currency).format(1_234_567.89, 'USD')`

Each case is sanity-checked against expected output before timing, and the
default iteration count keeps the run sub-second (~300ms).
