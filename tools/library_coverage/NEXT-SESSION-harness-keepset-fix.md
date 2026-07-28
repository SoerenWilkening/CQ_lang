# NEXT-SESSION PROMPT — bd `3c6m.60`: the census keep-set harness fix

> ## ✅ DONE 2026-07-26 — commit `92d96df`. This prompt has been executed; do not re-run it.
> **Outcome: injection-covered 68 → 80/123 (65%), `REGRESSIONS: NONE`, verified 68 → 79.**
> Every prediction in §2/§4 held: the same 12 cells flipped, `fmod.f64` still declines, and the
> 7-cell `loop-carried` → `L6 nested control` re-attribution is confirmed (so bd `q2wk` owns 15
> cells and bd `8h7d` owns 7). Three corrections to what is written below, kept because they cost
> real time to find:
> 1. **§3's fix (b) is right, but only HALF of the ticket's framing is.** The blanket
>    `-fno-builtin` on `wprobe.probe`'s **probe scaffold** must **STAY** — measured A/B: LLVM only
>    inlines a `"no-builtins"` callee (every corpus body is one) into a `"no-builtins"` caller, so
>    dropping it left `@acos` **outlined** and broke 10 baseline-COMPILES cells. The keep-set
>    correction belongs at the **defmap** (`keep_shims()`), never at the probe flag. The corpus's
>    blanket flag must stay too (a libm source built with builtins ON self-recurses).
> 2. **§4's honesty gate earned its keep.** `hypotl.f80` census-COMPILED and **DECLINED** at the
>    plain -O1 ship floor — the one census-pipeline-only cell, so the two numbers went 1 apart
>    again. *Resolved 2026-07-28 by bd `3c6m.61`:* the vendoring moved from
>    `tests/e2e/slice_libm_real_hypotl.c.DECLINED` to a wired
>    `tests/e2e/slice_libm_real_hypotl.c` + golden, and the gap is 0. The decline text quoted
>    here (`nested control flow under quantum control`) was MISLEADING about the cause —
>    PredMux's root region reduced the funnel all along; the real gate was an arm-resident
>    `icmp eq i80` (the fp80 Inf/NaN mantissa test). The honesty gate still earned its keep:
>    without it the cell would have been quoted as verified for three days.
> 3. Two probe-convention scope notes surfaced and are now recorded (bd `3c6m.62`): `pow`/`powf`'s
>    numeric core is const-folded away by the `arg1 = 0.5` convention, and `lgamma`/`lgammaf`'s
>    `signgam` side effect is dead-stripped.
>
> Live sources: `full_surface/README.md` (top banner + **CENSUS METHODOLOGY**) and bd memories
> `libm-keepset-census-fix-3c6m60` / `libm-next-steps-harness-then-q2wk`. **Next step: bd `q2wk`.**

> **Paste the block in §0 to start the session.** Everything else here is the briefing it refers to.
> Written 2026-07-25 at the end of the `3c6m.58` / scoping session, branch `3c6m.14-control-l6`.

---

## 0. The prompt

```
Implement bd 3c6m.60 — the census keep-set harness fix.

Read first: bd memory `libm-next-steps-harness-then-q2wk` (the plan of record), then
`bd show test_C_libtooling-3c6m.60`, then
tools/library_coverage/NEXT-SESSION-harness-keepset-fix.md (this file) for the briefing.

The bug: tools/library_coverage/full_surface/README.md:309/317/334 builds every openlibm .c
with a blanket -fno-builtin, and wprobe.py:241 passes it again on the probe. That defeats
Rule 18's hardware keep-set for INNER calls — a body calling sqrt/floor gets openlibm's
SOFTWARE implementation closure-linked in, instead of the @llvm.<keep> intrinsic clang -O1
emits at the real ship floor. So the census measures a program the ship floor never compiles,
and ~12 cells are under-reported.

This is HARNESS-ONLY. Do not change the compiler. If you find yourself editing ir-pass/,
stop and re-read the ticket — that is out of scope and means something is wrong.

Deliver, in this order:
  1. The harness fix + a full 123-cell re-census asserting 0 regressions among the current 68.
  2. Real-openlibm e2e goldens for every newly-compiling cell (bd memory
     `libm-real-slice-recipe`), because census-COMPILES != verified — bd 3c6m.58 just spent a
     whole session enforcing exactly that distinction.
  3. Docs + scoreboard updated to the new honest numbers, and the methodology deviation
     written down in the README so it cannot silently return.

Work to the project's normal gates: full ctest green before commit, and push at session end.
```

---

## 1. Why this is the next step (one paragraph)

The published taxonomy said bounded loops were the biggest lever at 24 cells. Measurement
inverted that: 17 of the 24 never blocked on a loop in their own body. `e_acos.c`, `e_asin.c`
and `e_hypot.c` contain **zero loops**. Their decline came from openlibm's *software*
`__ieee754_sqrt`, whose subnormal normalize loop (`src/e_sqrt.c:118`) got injected only because
the corpus build passes a blanket `-fno-builtin`. Fixing the harness — not the compiler — moves
**+12 cells** and re-ranks every remaining lever. Full analysis: bd `3c6m.60`, and the correction
banners in `NEXT-SESSION-libm-compileability-discussion.md` §2/§3.

## 2. The measured A/B you are reproducing and then generalising

Same source, same pass, same inline pipeline; **only the builtin flag differs**.

| build | `sqrt` becomes | `cq-lowering` on `acos.f64` |
|---|---|---|
| census (blanket `-fno-builtin`) | software `__ieee754_sqrt` inlined | **DECLINES** — `loop under quantum control` at `e_sqrt.c:118` |
| true ship floor (builtins on, `-fno-builtin-acos` on the caller only) | `@llvm.sqrt.f64` → `cq_template_sqrt` | **EXIT 0** — 23 `cqrt_alloc`, 0 residual `@cq_*`, 0 non-`cq` callees |

`hypot.f64` behaves the same (145 allocs at the ship floor). **Counter-check that must keep
holding:** `fmod.f64` still declines — its loop is genuine (SCEV reports `Unpredictable` for
backedge-taken, constant-max and symbolic-max). If your fix makes `fmod` compile, you have
broken something.

## 3. The fix — two options, (b) recommended

- **(a)** Replace the blanket `-fno-builtin` in the corpus recipe with per-file
  `-fno-builtin-<definedfn>` (only the function that TU defines).
- **(b) recommended** — register keep-set **forwarding shims** in `wprobe.build_defmap`:
  `T sqrt(T x){ return __builtin_sqrt(x); }` compiled *without* `-fno-builtin`, hard-overriding
  the soft bodies. ~30 lines. Cheaper, reclone-proof, and the **same mechanism as the vuy6
  `.set`-alias shims** already in that function — so it follows an in-tree precedent rather than
  inventing one. A prototype of (b) was measured and works.

Keep-set to shim (Rule 18, `probe.py:68` `HARDWARE_KEEP_SET`):
`sqrt fabs copysign floor ceil trunc round rint nearbyint fmin fmax fma/fmuladd lrint llrint`
— at every width (`f`, none, `l`).

## 4. Expected result — and the honesty gate

**12 cells flip, 0 regressions** (measured; treat as the expectation to *verify*, not a target
to hit):

```
acos.f64  acosf.f32  acosl.f80  asin.f64  asinf.f32  asinl.f80
hypot.f64 hypotl.f80 pow.f64    powf.f32  lgamma.f64 lgammaf.f32
```

`lgamma`/`lgammaf` blocked on the *software* `floor` body (`cq specialization: callee contains
tainted control flow under quantum lift`) — same artifact, different keep.

Injection-covered **68/123 → 80/123 (65%)**.

> ⚠ **Do NOT publish 80/123 as the headline until the goldens exist.** Injection-covered and
> verified are separate numbers (Rule 2, bd `libm-scoreboard-two-numbers`), and they currently
> **coincide at 68** — that property was expensive to establish and should not be broken by a
> census-only bump. Mint the 12 `slice_libm_real_*` goldens, then quote 80/80.

Ship-floor lowering is already proved for the 10 non-`lgamma` cells (see §2), so the goldens are
the link+run+diff layer on top, not new risk.

## 5. Gates

Rule 12 / Rule 13 **do not apply** — this is a measurement harness, not the compiler. The gates are:

1. Full 123-cell re-census; **assert 0 regressions among the current 68**. The change must be
   strictly monotone.
2. `slice_libm_real_*` golden per newly-compiling cell, wired into `tests/e2e/CMakeLists.txt`.
   Follow bd memory `libm-real-slice-recipe`.
3. Full `ctest` green (currently **210/210**).
4. Update: `full_surface/README.md` (new dated banner at the top + a **CENSUS METHODOLOGY**
   section explaining why the corpus must not use a blanket `-fno-builtin`),
   `NEXT-SESSION-libm-compileability-discussion.md` §2 counts, and re-run
   `python3 tools/library_coverage/probe.py render` (COVERAGE.md / mathh.md / the README badge
   are **generated** — never hand-edit them).
5. Push at session end.

## 6. Gotchas that will cost you an hour each

- **Corpus location is reboot-transient.** `/private/tmp/openlibm` had its `src/` and `ld80/`
  **wiped**; the intact clone is `/private/tmp/openlibm_reclone` @`82e90ae` (the commit
  `libm-real-slice-recipe` pins). `/private/tmp/bc` holds 245 prebuilt `.bc`. Check both before
  concluding a cell has a corpus gap.
- **`peel_census.py` HARDCODES `default<O2>`** and ignores `CENSUS_OPTLEVEL`. Use
  `full_census.py` for a true O1 measurement. `peel_census_merged.json` /
  `first_blocker_refreshed.json` were last written 2026-07-14 and are ~10 compiler landings
  stale — do not quote them.
- **Verify the plugin is actually current** before trusting any measurement: `PredMuxFlatten.cpp`
  and `libCQPass.so` share an mtime, so CMake's incremental skip is ambiguous. `touch
  ir-pass/src/*.cpp`, rebuild, and byte-compare. (Checked 2026-07-25: it *was* current.)
- **Census probe spelling matters.** `wprobe.W` uses `cq_theta_f64`/`cq_measure_f64` (suffixed).
  An unsuffixed `cq_theta` silently produces a no-op passthrough: `opt` exits 0 with **0 allocs**
  and residual `@cq_*` calls. Always assert `allocs > 0` and `residual @cq_* == 0` before
  believing a COMPILES.
- **`e_acos.c` defines `@acos`, not `@__ieee754_acos`.** Probing the wrong symbol yields the same
  silent no-op-passthrough false positive.

## 7. After this lands

**bd `q2wk`** — PredMux -O1 nested-control widening, **15 cells**, the largest remaining lever.
Its payoff grew 8 → 15 *because of* this fix's re-attribution, which is why this one goes first.
Its blocker chain is already cleared (`3c6m.50` closed 2026-07-25). Its title/description framing
is stale (it describes log1p/atanh as an O1/O2 metric gap; in the committed O1 baseline all four
are plain `L6 nested control` declines) — retitle when picking it up.

**Do not** start `8h7d` (the loop lever). It owns 7 cells, not 24, and 6 of those are the
roadmap-scale fmod/remainder/remquo family that re-opens the whole-DAG uncompute spine.
