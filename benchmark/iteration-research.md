# Benchmark iteration counts

I kept `ITERATIONS.times` inside each `Benchmark.bmbm` report block because
`benchmark` 0.5.0 has no iteration-count parameter. Its own
[README uses `n.times` inside report blocks](https://github.com/ruby/benchmark/blob/v0.5.0/README.md#L40-L116).

## What the parameters control

| API | Parameters |
|---|---|
| `Benchmark.bmbm(width = 0)` | Minimum label-column width |
| `Benchmark::Job#report(label = "", &blk)` | Label and block to measure; `report` aliases `item` |
| `Benchmark.bm(label_width = 0, *labels, &blk)` | Label-column width and labels for additional result rows |
| `Benchmark.benchmark(caption = "", label_width = nil, format = nil, *labels)` | Output caption, width, format, and labels for additional result rows |

None of these parameters sets an iteration count. `bmbm` registers the blocks
through `Benchmark::Job` and runs each block once per pass. Passing a number
to `bmbm` changes the output width; it does not repeat the operation.
See the [version 0.5.0 implementation](https://github.com/ruby/benchmark/blob/v0.5.0/lib/benchmark.rb#L171-L284)
and [job registration](https://github.com/ruby/benchmark/blob/v0.5.0/lib/benchmark.rb#L353-L372).

## What the measurements include

- `bmbm` runs every block once during rehearsal and once during measurement.
  A block containing `N.times` therefore performs N operations per pass.
- The rehearsal warms up the code. It does not select an iteration count or
  calculate an average across samples.
- Before each final measurement, `bmbm` calls `GC.start` outside the timed
  block. It does not disable garbage collection during the measurement.
- The returned timing objects contain the final measurements.

These behaviors come from the
[`bmbm` documentation and implementation](https://github.com/ruby/benchmark/blob/v0.5.0/lib/benchmark.rb#L221-L284).

[`Benchmark.measure`](https://github.com/ruby/benchmark/blob/v0.5.0/lib/benchmark.rb#L303-L313)
takes timing snapshots around the whole block. The result includes the
`times` loop and all operations inside it; the implementation neither
subtracts loop overhead nor divides by N. Loop overhead can affect ratios
for very fast operations.

## Decision

I kept the same iteration count and loop structure for all libraries within
each comparison. The reported seconds measure the whole batch. If we add
per-operation timings later, we can divide each final `tms.real` by the
corresponding iteration count.

This conclusion is based on the installed `benchmark` 0.5.0 source and README;
the links above point to the matching upstream version.
