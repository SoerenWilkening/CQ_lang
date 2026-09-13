# Rule-13 review brief, round 1 — Track C, bd `21mg`: `cq_measure` of a value that never became quantum lowers to the CLASSICAL VALUE (no gate)

Written 2026-09-13 by the orchestrator. Model: opus. Worktree `/Users/sorenwilkening/Desktop/CQ_21mg`, branch
`classical-measure` (base `main` 01c89b5), `build/` current (`cq-opt` sha256 `c662bd0ca0e7d8a4…` per
`GATES.md` — your ONE build-side obligation is `shasum -a 256 build/ir-pass/cq-opt` and confirming it
matches; a mismatch is a FINDING, not something to re-run). Protocol: `../PROTOCOL.md`, row "review": **NO
build, NO suite** — you take `GATES.md` as fact for that hash, spend your budget on adversarial probes and
analytic reasoning, and may re-run at most ONE fixture to test a claim you doubt. ORACLE:
`/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` (`fbbe0820…`, read-only). Do not edit
`ir-pass/`, `include/`, `tests/`, `tools/` anywhere. Read in order: `BRIEF_C.md`, `IMPL_C.md` (all sections;
§2 (a)–(e), §7 O-2/F-3/F-4/F-5/Q-1), `GATES.md`, `probes/README.md`, `bd show 21mg`, `CLAUDE.md` (Prime
Directive; Rules 1, 3, 5, 12, 13; CORRECTNESS RISK §3 L1; Rule 19's "report only what you ran").

## What changed (from IMPL_C.md — verify against the diff)

`ir-pass/src/MeasureLowering.cpp` only (+ a comment-only `MeasureLowering.h` contract fix): in
`lowerMeasures`, the operand is asked ONE question, taint. Untainted → (a) `undef`/`poison` → a NEW loud
decline `cq_measure_<sfx> operand is an undef/poison literal; a classical measurement needs a defined value`
(with `!dbg`); a type-mismatch guard (claimed unreachable at HEAD, kept loud on the retained string);
otherwise `Measure->replaceAllUsesWith(operand)` + erase — no symbol, no gate, no rail, no trace line.
Tainted → the quantum path, with the runtime-symbol resolution MOVED inside that branch (because
`measureRtFn` lazily declares `@cqrt_measure_<W>`). The retained string `cq_measure_<sfx> operand not
recognized; expected a tainted i32 handle` is byte-identical. 6 fixtures, 3 slices (owner file 15 lines
byte-identical to its `cq_measure(b1)`-less twin), injection 29 mutations 0 MISSED, corpus 3021 rows 1
mover (a Track-L probe, DECLINE→ACCEPT on the 21mg string), `ir-pass-lit` 1899/0.

## Where to look (over-ACCEPT is the unforgivable bug; the owner also grades over-DECLINE)

1. **Rule 5 / Rule 3 at the sole sink.** "Not tainted" is asked at FINAL taint — verify by reading the
   pipeline that NOTHING taints a value after `lowerMeasures` runs in EITHER entry point (`run` and the
   `runOnFunction` shim), and that no stage between `repropagateControlMerges` and `lowerMeasures` can
   UNtaint a value (a RAUW that replaces a tainted SSA name by an untainted one — `MergePhiPeel`, M-α/M-β,
   `lowerRotations`' handle RAUW, `collapseFlattenedLoopRails`: does `taint.Tainted` follow each RAUW, or
   is `Handle` after RAUW a name the set no longer contains while the state IS quantum? THAT is the silent
   miscompile shape here — a quantum register measured as "classical" returns a handle integer as data and
   emits NO measurement). Construct it: a measure whose operand is a merge φ / a peeled select out-rail / a
   collapsed loop rail / a `%out` of a 6.5 arm / a value RAUW'd by `emitInPlaceRotationRegion`'s M-β; on
   each, does the emitted stream contain `cqrt_measure_<W>`?
2. **The i32-handle world.** After `lowerRotations`/`lowerOps` every tainted value is an `i32` handle. A
   CLASSICAL `int` that happens to be `i32` and a HANDLE that is `i32` are distinguished only by the set —
   probe a classical `i32` that is data-dependent on a measure RESULT (`int m = cq_measure(q); int n = m +
   1; cq_measure(n)`): a measure result is a sink and untainted, so `cq_measure(n)` is classical — correct?
   And `cq_measure(cq_measure(q))`? And a classical value that is the OPERAND of a `cq_theta` elsewhere
   (`cq_theta(seed, θ)` with `seed` also measured) — `seed` stays classical (arg-0 of a source theta) and
   its measure is the value: correct, and pinned?
3. **(a) the undef decline**: is `valueCarriesUndef` the right predicate (a `phi` with one `undef` incoming?
   a `select` with an undef arm? a struct/vector operand?) — over-decline is fine, but state it; and does
   the new string exist anywhere else / is the fixture's mirror exact?
4. **(c) the in-arm classical measure** — measure the neighbourhood: a classical measure inside a tainted
   region's arm, in a 6.5 arm, in a `switch` case, in a loop body under quantum control, and as a `select`
   operand. Every one must be a LOUD decline (which string?) or a correct lowering; grade any over-decline.
5. **(d) the round-2 window (L1)**: the implementer discharges it by ORDER and pins with three fixtures —
   construct the 9pum two-TU window through a measure (a `%out`-derived value measured), and a classical
   measure of a value that BECOMES tainted only through `MergePhiPeel`'s clone/select (round 1) — both must
   emit `cqrt_measure`.
6. **(e) the 10 `MeasureCalls` readers** the implementer enumerated: for each, does a NOW-ERASED classical
   measure (erased at `lowerMeasures`, which runs LAST-ish) leave a dangling entry that a later stage
   dereferences? (`uncompute` runs after `lowerMeasures` — does `FreePoint`'s Measured set or `ChainWalk`
   iterate `taint.MeasureCalls` AFTER the erase? a freed `CallInst *` in a `SmallPtrSet` is a UAF that
   Release will not catch.) Read the order; construct a program with a classical measure AND a quantum
   chain that is uncomputed after it.
7. **Trace / output contract (Q-1)**: a classical measure prints nothing. The golden of the owner's file is
   byte-identical to the twin's — good — but is there any fixture/slice in the tree whose golden
   COUNTED `cqrt_measure` lines for a measure that is now classical (the corpus says 1 mover — confirm it
   is the only one and that no committed `.expected.log` changed).
8. **F-5**: the implementer claims `LLVMContext::diagnose` exits on the first `DS_Error` — verify against
   the diagnostic handler in `Plugin.cpp`/`cq_opt_main.cpp` and say whether that changes any Rule-12
   fixture's evidentiary value (a fixture pinning "two declines" pins one).
9. **Over-declines met in passing** (§7 F-3/F-4, O-2's `<unknown>:0:0`): confirm each on the ORACLE and
   grade OVER-DECLINE / DOC.

## Method

Scratch `/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/ddf48412-8498-4d8b-9bac-51279fb090c0/scratchpad/trackC_review/`;
plain C `-O1` first, hand IR second; SUBJECT vs ORACLE per probe (`../PROTOCOL.md` pipeline with `BUILD` =
the worktree's `build/`); state-vector / trace reasoning; grade CONFIRMED-MISCOMPILE / OVER-ACCEPT-ARGUED /
OVER-DECLINE / LEAK / DOC; verdict BLOCK / CLEAR-WITH-ITEMS / CLEAR. Report `review_C_r1.md` beside this
file, probes in `review_C_r1_probes/` with a runner. Final message ≤30 lines: verdict, findings one line
each with grade + reproducer path, item 1's answer (which RAUWs the taint set follows) and item 6's answer
(the erase order) explicitly.
