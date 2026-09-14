# Track U — FIX brief for review round 1 (bd `z9t1`)

Worktree `/Users/sorenwilkening/Desktop/CQ_undef`, branch `undef-seed-zero`, currently at tip
`8865f7d55104c52644080c41ed8ee02b17e1c89f`. `$SES` =
`docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/`.

**READ FIRST:** `$SES/trackU/REVIEW_U_R1.md` (the round-1 verdict, CLEAR-WITH-ITEMS, 24 probes in
`review_r1_probes/`), `$SES/trackU/IMPL_U.md` (the implementation record you are correcting),
`$SES/trackU/BRIEF_U.md` (the original brief and the five ruled clauses), `$SES/PROTOCOL.md` (the gate
matrix — you are the FIX agent: rebuild, the finding's probes, `ir-pass-lit` once iff pass source changed,
corpus once).

## F-U1-1 — the over-ACCEPT. Fix this first; it is the only safety-direction item.

**The defect.** `z9t1` moves modules through a **third** diagnostic the record never names:
`cq literal integrity: undef/poison literal reaches two emitted gate operands` (`LiteralIntegrity.cpp`
GUARD 1). At CQ type `double` the **seed and the angle share the LLVM type**, so one uniqued `double undef`
filled **two** emitted slots and GUARD 1's threshold of 2 fired. Normalizing the seed drops the count to 1
and **the guard goes silent**. Reviewer's probe `r14`: ORACLE **exit 1**; SUBJECT **exit 0, 0 bytes of
stderr**, emitting `call void @cqrt_ry_f64(i32 %h, double undef)` — linked and run, it prints the garbage
angle `0x1.100000002p-1038`.

The 1-slot accept itself is **pre-existing and deliberately blessed**
(`lowering_accept_undef_literal_single_slot.ll`, controls `r17`/`r03`), so this is **population widening of a
known hole**, not a new wrong unitary — but `IMPL_U.md` §2(f) says arg-1 is *"unchanged, pinned"*, and in
this composition that is **false**. Under the Prime Directive a widened silent-accept population is not
acceptable, whatever its ancestry.

**The fix (the reviewer's, ~3 lines):** refuse the rewrite when the same `UndefValue` also occupies arg-1
(the ANGLE) of the same call, so the module keeps declining exactly as it did on the ORACLE. Add the decline
fixture, mirroring GUARD 1's string character-for-character, and a positive control at the same width where
the angle is a real constant (which must still accept and normalize).

⚠ **Do not "fix" this by declining an undef ANGLE in general.** That is a broader, separate question about a
blessed ruling and it is the owner's to make — it is filed as its own bd issue. Your change restores the
ORACLE's verdict on this composition and nothing more. Say in your record that the underlying 1-slot hole is
untouched and still blessed.

⚠ **Your fix is itself a lowering-core edit and owes review** — the round-2 reviewer is told to start here.

## F-U1-2, F-U1-3, F-U1-4 — record corrections (L7: an unruled agent justification hardens into a ruling)

Correct `IMPL_U.md` (and any source comment that repeats them):

* **F-U1-2.** "ONE OBJECT, READ TWICE" is **not** what the code implements — probe `r08` (two *different*
  uninitialized objects) lowers to a gate stream identical to the one-object spelling. Soundness holds on the
  **per-`undef` refinement** argument, not on the stated scope. State the real scope. Also record the
  property the reviewer derived and the record should claim: **an `undef` seed is a `Constant`, so the rule
  can only ever produce a FRESH prep**, which rules out the F2 α reading.
* **F-U1-3.** The `specialize` argument holds, but `Sets.Rotations` is built from `taint.ThetaCalls` **by
  exact pointer**, so R2 must be stated as *"a theta that `propagate` collected"*. Replace it with the
  stronger ground the reviewer found: `propagate` is the **first statement of both entry points** and
  `collectAndSeed` normalizes **every** theta in **every** function **unconditionally**, so the invariant
  holds before any stage and is **taint-independent** — and `ir-pass/src` contains **zero**
  `UndefValue::get` / `PoisonValue::get`. Verify both of those yourself before writing them down.
* **F-U1-4.** `GATES.md` says "grep, not a sweep" and `IMPL_U.md` §6 says "parsing, not grep" — one is wrong;
  fix it. The e2e scan silently skipped 22 `*_lib.c` (21 containing `cq_theta`); the reviewer closed that
  hole (every occurrence is an `#ifdef` tripwire, not a call) — record that closure rather than re-running
  the scan. And record honestly that *"carries the trigger token"* is **not literally a closure** (a
  `ConstantExpr` folding to poison at parse), noting that neither agent could construct one in LLVM 19.

## F-U1-5 — file, do not fix

One intervening instruction between the theta and the merge (`b1 = !cq_theta(b1,.5)`) and the φ half does not
fire; identical decline on both binaries. That is an over-decline **residual**, not a regression. Write it up
in your record; the orchestrator files it beside bd `bwsh`.

## Gates you own (PROTOCOL matrix — FIX agent row)

`cmake --build build -j8` (**never `--target CQPass` alone**), record the new `shasum -a 256
build/ir-pass/cq-opt` in `$SES/trackU/GATES.md`. Re-run: the finding's probes (`r14` and its controls `r17`,
`r03`, plus your new fixture), every fixture you touched, **`ctest -R ir-pass-lit` ONCE** (pass source
changed), and **one corpus sweep** on the new binary. **NEVER** the full suite, `^e2e-`, or the equivalence
sweep.

⚠ The box is under heavy concurrent load; contention causes false FAILURES, never false passes. Re-run any
`-j` failure serially before calling it a regression, and never relink under a running measurement.
⚠ The previous corpus sweep was PARTIAL (stopped by exact PID under load, closed by a tail argument). If you
cannot complete a full sweep either, say so in the same explicit terms and state what is unaudited.

## Deliverable

Update `$SES/trackU/{IMPL_U.md, GATES.md}` in the worktree, add `FIX_U_R1.md` recording each finding's
disposition, and commit on the same branch with the two `CLAUDE.md` trailers. Report: new tip, new binary
hash, the `r14` before/after verdicts, the new fixture, every gate line as `ran:`/`cited:`, and the corpus
result.
