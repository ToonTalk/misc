# Unseen robot performance audit

Tested 19 September 2026 against the local working copy of `C:\Users\toont\dev\tt3d\toontalk-3d.html`, SHA-256 `f2c29b6dcb7ea2afcfca2d193df165e0715a178e21f4aa7d3ebe26fe23a6348a`. This includes uncommitted work; it is not a claim about the currently published GitHub version. No application files were changed.

## Results

There are substantial opportunities to improve active unseen robots. Sleeping robots were inexpensive in these tests. The most useful fixes are **defer unnecessary number graphics** and **give all houses fair turns within one short, shared frame budget**.

| Workload | Median CPU time per simulated frame | Other observations |
|---|---:|---|
| One active counter in a solid house, existing code | 87.7–130.4 ms | Three fresh-page runs; p95 154.3–226.8 ms; 3,200 increments per run |
| Same counter, experimental deferred number graphics | 7.2–8.8 ms | Three fresh-page runs; p95 10.7–14.5 ms; same 3,200 increments |
| Ten active solid houses | 651.9 ms | Ten measured frames; maximum 662.0 ms |
| Fifty active solid houses | 678.8 ms | Ten measured frames; maximum 712.6 ms; 40 houses never incremented |
| Ten robots waiting on empty nests | 0.2 ms | Forty measured frames; all ten confirmed waiting; no rounds executed |
| Fifty robots waiting on empty nests | 0.2 ms | Forty measured frames; all fifty confirmed waiting; no rounds executed |

For the single-counter comparison, aggregate measured CPU time fell from **13,496.5 ms to 965.5 ms**, approximately **14× faster**. These are isolated final runs; an earlier overlapping exploratory comparison was excluded. This is a microbenchmark result, not a promised 14× improvement for every program.

The sleeping tests had occasional outliers: 41.4 ms maximum for ten robots and 15.2 ms for fifty. The samples are too short to assign those spikes to a particular cause. Their p95 values were 0.7 and 0.3 ms respectively.

## Findings and suggested changes

### 1. Expensive graphics are created for transient unseen numbers — high priority

[makeNumber](/C:/Users/toont/dev/tt3d/toontalk-3d.html:4083) normally allocates five 256×256 canvases, textures and materials, builds meshes, and paints the number. A counter creates a number, adds it to its existing value, and consumes it. Its temporary operand does not need those graphics while inside a solid house.

Number construction alone accounted for approximately **43–49%** of measured frame time in the single-counter baseline and **63–65%** in the short scaling tests. Matching, layout and sidebar updates were much smaller contributors for this workload.

The experimental change only replaced `if (!lite) g.__materialize();` with `if (!lite && !offstage()) g.__materialize();` in the HTML served by the benchmark. It preserved the counter's answer and produced the large improvement above.

**Do not apply that one-line experiment as a finished fix.** `offstage()` also covers glass houses, and existing materialization is not guaranteed on every route by which a number becomes visible. A production change needs explicit deferred-visual state, materialization when a number enters view or a house is opened, and tests for transfers, copies, labels, number faces and picking. Start with transient arithmetic operands in opaque houses; expand only after those tests pass.

### 2. Unseen work blocks the main thread for hundreds of milliseconds — high priority

[runRoomWork](/C:/Users/toont/dev/tt3d/toontalk-3d.html:9749) uses a **300 ms** room-work slice in the tested snapshot. It can process batches of 40 rounds, recursively visit other rooms, and only checks some budgets between batches/rooms. The panel scheduler's 8 ms check is also after a room returns. These are soft limits, not a guarantee that the browser gets control back promptly.

The ordinary counter measured **80 rounds per simulated frame**: the scheduler can be reached more than once within a frame. The house gate uses `roomFrame`, which advances with scheduler calls, while panels additionally use `renderFrameNo`. Consequently a per-call budget can be spent repeatedly in a frame.

Use one deadline shared by every scheduler entry during the same render frame. Check it **between complete rounds**, preserving the app's round-as-quantum rule, and continue the next runnable room on the following frame. A small configurable CPU allowance, initially around 4–8 ms, is a better starting point than hundreds of milliseconds. Benchmark input latency as well as throughput when tuning it.

[drainQueue](/C:/Users/toont/dev/tt3d/toontalk-3d.html:9728) also calls `fastForward(100000, Infinity)`, disabling the inner time limits. Its eight-second watchdog is checked only after that call returns. A pathological round can therefore exceed the stated watchdog before the check runs. This is a source-inspection finding, not a deliberately reproduced eight-second freeze. Long-round handling needs a resumable safe boundary or an explicit failure mechanism; simply discarding queued steps risks leaving work unfinished.

### 3. Houses later in the table order can be starved — high priority

[findDirtyRoom](/C:/Users/toont/dev/tt3d/toontalk-3d.html:10044) searches from the beginning, and recursive room work can spend the shared time before later houses are reached. The panel scheduler has least-recently-run ordering, but ordinary houses do not receive the same treatment.

After four warm-up frames and ten measured frames with fifty independent, always-runnable counters, the first four counters each reached **1,120**. The next six reached **1,040, 840, 760, 480, 240 and 80**. The remaining **40 counters stayed at zero**. This demonstrates starvation over the measured interval, not proof that those houses could never eventually run.

Use a persistent round-robin runnable queue for houses as well as panels. Carry its cursor across frames, and make recursive discovery enqueue eligible work instead of repeatedly favouring earlier siblings. Add a regression test that bounds the wait until every continuously runnable independent house receives a turn.

### 4. Visibility checks and the profiling helper deserve follow-up

[advanceLOD](/C:/Users/toont/dev/tt3d/toontalk-3d.html:23669) checks a number's own `visible` flag, not whether an ancestor is invisible. It may therefore calculate world positions and repaint numbers inside hidden groups. Extend the existing effective-visibility logic to this path and invalidate it when containers open or close. The incremental saving was not benchmarked separately.

[profileFrames](/C:/Users/toont/dev/tt3d/toontalk-3d.html:27070) does not advance `renderFrameNo` in its Instant branch, unlike `frame()`. Once a panel is marked as having run in that frame, this can make an Instant profile undercount subsequent panel execution. Use one shared simulation-step implementation for the animation loop and both test helpers. These benchmarks deliberately used `frame()`, not `profileFrames()`.

## Method and limits

- Chrome 149.0.7827.55, Node 24.16.0, Intel Xeon W-2223 @ 3.60 GHz; headless Chromium, audio muted, isolated browser storage.
- A temporary server served the local app and inserted timing wrappers in memory. The arithmetic program uses normal robot steps: take a new number, set it to one, and put it on the counter in hole zero. All houses were hydrated before timing.
- Each controlled sample used a fresh page, four warm-up frames, and the app's `__nano.frame()` helper. Actual renderer drawing and the automatic animation loop were disabled. Normal simulated clocks, room scheduling and LOD cleanup remained enabled. Browser control was yielded between frames.
- Times measure synchronous simulation CPU work, excluding inter-frame waits and GPU rendering. They demonstrate long main-thread occupations but are **not measured display FPS or click-to-response latency**. They omit other work performed by the full animation loop.
- Counter values and executed-round totals were checked. Every single-counter run ended at 3,520: 320 warm-up increments plus 3,200 measured increments. Sleeping cases checked that all robots actually entered waiting state.
- Source wrappers record inclusive timings; recursive `runRoomWork` totals overlap and must not be summed as separate CPU costs.
- High temporary-number registry counts in the short active tests do not establish a memory leak: pruning is periodic. The initial scheduler-only exploratory run omitted normal LOD cleanup and is not evidence of a production leak.
- Browser-tab hiding/throttling is separate from robots being unseen inside the world. These tests cover the latter. Simulation currently relies on the animation loop; background-tab progress would need its own visibility-controlled test and product decision.

## Reproduction

Run from this directory's parent workspace:

```powershell
node performance-audit/single.cjs
$env:LAZY_NUMBERS='1'
node performance-audit/lazy.cjs
Remove-Item Env:LAZY_NUMBERS
node performance-audit/scaling.cjs
node performance-audit/sleeping.cjs
```

Run these sequentially. Scripts contain local paths for the app, Playwright package and Chromium executable; adapt those on another machine. Each has an external timeout. They write `controlled-results.json`, `lazy-results.json`, `scaling-results.json` and `sleeping-results.json`. The earlier `bench.cjs`, `controlled.cjs` and exploratory data are development probes; use the four commands above for the final measurements.
