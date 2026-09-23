# Formatter benchmarks

Compares reusable number and currency formatters from:

- `offi-icu`
- `ffi-icu`
- `twitter_cldr`

Each process performs three warmup rounds before measurement. The runner starts
separate Ruby processes with YJIT disabled and enabled.

```sh
gem install twitter_cldr
benchmark/run.sh
```

Configuration:

```sh
WARMUP_ROUNDS=3 \
WARMUP_ITERATIONS=10000 \
ITERATIONS=100000 \
FFI_ICU_PATH=../ffi-icu \
benchmark/run.sh
```

Results are written to `benchmark/results/` and are intentionally ignored by
git because they are machine-specific.
