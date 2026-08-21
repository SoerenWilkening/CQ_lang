# Loop-bound measurement tooling (libm campaign)

Measures, per loop in a census cell, whether a **quantum-independent upper bound
on the trip count** is derivable from the IR at compile time.

Built for bd `8zj2` (8 cells) and committed at owner direction 2026-08-21 so bd
`19v3` (all 120 cells) measures with the **same instrument** rather than a
re-authored one that can silently diverge.

> **This is not product.** It is deliberately not wired into the top-level CMake
> build and not registered with ctest, so it cannot affect `cmake --build build`
> or the suite. That separation is the reason it is safe to keep in-tree.

Findings of record: `docs/prd/phase-07-expressiveness/SPIKE-8zj2-ilogb-logb-loop-bounds.md`
and bd memory `spike-8zj2-ilogb-loop-bounds`.

---

## Build

```bash
cd tools/library_coverage/loop_bounds
cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm \
      -DCMAKE_BUILD_TYPE=Release
cmake --build build -j8          # -> build/LoopBoundProbe.so
```

`find_package(LLVM 19 ...)` fails — `LLVMConfig.cmake` reports 19.1.7 and rejects
a bare `19`. The unversioned form plus `LLVM_DIR` is what works, same as the
top-level build.

## Use

```bash
LLVM=/usr/local/opt/llvm@19/bin        # NOT on PATH on this machine

# 1. dump a cell's PRE-LOWERING module at the -O1 ship floor
BC=/private/tmp/bc OPENLIBM=/private/tmp/openlibm \
  python3 dump_cell.py ilogb.f64 ilogbf.f32 ilogbl.f80 logbl.f80

# 2. per-loop SCEV report, straight off the LLVM 19 API
$LLVM/opt -load-pass-plugin build/LoopBoundProbe.so \
    -passes='cq-spike-scev' -disable-output <cell>/inl.ll

# 2b. the SAME report using the ScalarEvolution the PASS builds
#     (hand-constructed, conservative TLI — not the pass manager's)
$LLVM/opt -load-pass-plugin build/LoopBoundProbe.so \
    -passes='cq-spike-scev-passstyle' -disable-output <cell>/inl.ll
```

`dump_cell.py` reproduces `wprobe.probe()` (`full_surface/wprobe.py:497-536`)
with `CENSUS_OPTLEVEL=O1`. **Nothing mechanical keeps the two in sync** — re-read
`wprobe.probe()` before trusting a dump after any census-harness change.

## Five traps this tooling exists to stop you falling into

1. **`isa<SCEVConstant>` is not a soundness test.** The reporter's
   `VERDICT bound-kind = CONSTANT` line fires for `fmod.f64`'s vacuous `-2` =
   4294967294 bound. A usable bound needs **five** conditions: constant **and**
   non-negative **and** small **and** reachability-total **and**
   `1 <= shift-amount <= width-1`. The tool measures; it does not adjudicate.

2. **`getSmallConstantMaxTripCount` does not return 0 on a vacuous bound** — it
   returns 4294967295. So `non-zero ⇒ usable` accepts a 4-billion-trip roll.
   `LoopUnrollPrepass.cpp:199-202` survives only because it *also* demands an
   exact trip count and `Trip <= 8`.

3. **Never `getSignedRange(...).getSignedMax()`** (TRAP-1, cost a design phase).
   It reads an unsigned quantity as signed *and* returns a backedge count where a
   peel needs a trip count. The reporter prints it **beside** the sound answer so
   the trap is measured per cell, not assumed.

4. **`inl.ll` is not the module the pass analyses, for ld80 cells.**
   `CQLoweringPass.cpp:170` runs `promoteFp80Union` to fixpoint first. Use
   `CQ_FP80_DBG=1`. (8zj2 checked; the f80 answers happened to be unchanged —
   that is a measurement, not a guarantee.)

5. **A bound that holds only under an enclosing guard is not a bound.** PredMux
   removes every guard — measured `br i1` 5→0, 4→0 and `switch` 1→0 — so a
   guard-conditional bound is the R1-class silent miscompile
   `QramLowering.cpp:703-708` exists to prevent.

## `cq-spike-excise` is a KNOWN-FALSE-NEGATIVE probe — bd `66rz`

It is retained **only** so the spike memo's §3a refutation stays reproducible.
It prints an unsilenceable banner on every run. Do not use it to decide whether
anything lies behind a loop.

Excision deletes the loop's exit branch, which makes the whole tainted loop-body
recurrence dead; `cq-lowering`'s own DCE then removes it — so the "rest" that
gets lowered **contains no instruction from the loop**. Measured: inject a real
blocker (`trunc i32 -> i7`) into `ilogb.f64`'s loop body and it *still* reports
LOWERS CLEAN, while the identical blocker under a genuine static-K peel declines.
It reported CLEAN on **6 of 6** looping cells, including two already ruled
permanently out.

**Use a genuine static-K peel instead** — body live, exit branches preserved.

There is deliberately **no `peel_test.sh` in this directory.** The 8zj2 script of
that name drove the discredited probe, and committing it would invite exactly the
re-run bd `66rz` warns against.

## `probes/`

Standalone witnesses for the memo's mechanism claims. Each is self-contained;
compile with `$LLVM/clang -O2` (`.c`) or feed to `$LLVM/opt` (`.ll`).

| file | establishes |
|---|---|
| `width_probe.ll` | the bound is a **bit-width fact** — tracks i16/i32/i64, survives deleting the counter and dropping `nsw`/`nuw`; a data-dependent shift amount goes Unpredictable |
| `trip_exhaustive.c` | true worst-case trips over the **guard-admitted** domain: 31 / 20 / 23 vs the 33 ceiling |
| `rotated_ir.c` | **totality in the rotated form the pass sees** — the `shl` body terminates on all 2³²; the f80 mask body diverges on `{0, 0x80000000}` (source semantics say one input; the rotated body says two — measure the rotated one) |
| `f80_termination.c` | source-semantics twin of the above; kept because the 1-vs-2 discrepancy is the correction itself |
| `f80_mechanism.ll` | the f80 `CouldNotCompute` is caused by the **opaque** AND-operand, not the compare shape — a constant operand bounds at 23 |
| `f80_assume.ll` | `llvm.assume` does **not** recover the f80 bound; adding a mask-exhaustion exit **does** (`i32 31`) |
| `norm_loop.c` | `SCOPING-L3` §6 item 1's normalize loop is **non-terminating** on the guard-excluded input — its bound is guard-conditional (bd `k02s`) |
| `ctlz_probe.c` | CQ lowers a tainted `llvm.ctlz` end to end (`cq_template_ctlz_i32`, exit 0) |
| `idiom_probe.c` | LLVM's `LoopIdiomRecognize` fires on `while (x != 0) x >>= 1` and on **neither** openlibm spelling, at -O1/-O2/-O3 (bd `ww4c`) |
