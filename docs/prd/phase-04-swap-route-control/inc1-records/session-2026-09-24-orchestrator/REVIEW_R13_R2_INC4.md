# bd `fn1q` increment 4 — Rule-13 ROUND 2 (independent agent, on the ROUND-1 FIXES)

**VERDICT: `CLEAR-WITH-ITEMS` — 0 P1, 2 P2, 6 P3.** No wrong accept. Its mutant-tree
baseline rebuilt BIT-IDENTICAL to the subject, and it ran TWO whole-corpus null controls
(subject vs mutant-baseline, and subject vs env-gated mutant with no env set) returning
**0 movers of 2149** before trusting any mutant delta.

⚠ **ROUND 2 EARNED ITS COST FOR THE SECOND INCREMENT RUNNING, AND THE HEADLINE IS THE
ROUND-1 FIX ITSELF.**

| # | sev | finding | disposition |
|---|---|---|---|
| R4R2-1 | P2 | **the round-1 laundering fence is STRUCTURALLY VACUOUS INSIDE A LOOP.** `qromShapedReadTaintsIndexAfterFlatten` goes through `matchQramAccess`, which returns `nullopt` UNCONDITIONALLY for any memop in a loop — so for every in-loop load (exactly the half of E4's surface increment 3 opened) the fence answered `false` at its first `if`. `QramLowering.h` said it "must refuse EVERY such load"; it refused none in a loop. The programs still declined — but by `kMsgQramLoop` + U2b, a **CONTINGENT closure** (bd `xt20`'s class), and only AFTER the region was CLAIMED AND FLATTENED | **FIXED PROPERLY, not just documented.** A direct `valueWillTaintAfterFlatten` on the pointer operand — same predicate, no QROM matcher, hence no loop gate. Verified: the three in-loop probes now refuse at `gate=E4-gep` **pre-claim**, and the diagnostic moves back from `cq QRAM access: tainted-index memory access inside a loop` to the ordinary control-flow decline. Pinned by `…_reject_classical_table_inloop_willtaint.ll`, whose `DBG:` line is the load-bearing assertion — without it the fixture would pass on the DEFECTIVE binary too, which also declined, just later and for someone else's reason. Round 1's disposition "R4-P2-1 is SUBSUMED" was true for the flat family and **false for the in-loop family it never probed**. |
| R4R2-2 | P2 | **a SIXTH copy of the §5.2 claim**, at the width gate, 92 lines below round 1's correction of the other five — and it is the LOAD-BEARING one. *"This value is never muxed and never an angle"*: measured FALSE on both halves (a table value as a merge arm IS muxed, emitting `cqrt_alloc_f64(double %z)`; and a loaded `double` CAN reach `cq_theta`'s arg-1, saved by a different fence) | **FIXED.** The width gate's reason is now "the templates must carry this width", full stop. ⚠ Round 1's *"CORRECTED IN ALL FIVE"* was measurably incomplete — two comments in ONE function contradicting each other, the class §4i records from one increment ago. |
| R4R2-3 | P3 | **arm (1c) has ZERO fixtures** — deleting it moves 0 of 2149, yet it is the SOLE admitter of three shapes round 1 used only to correct a comment | **RECORDED** at the predicate with its three shapes named. Not fixtured: round 2 could not reach arm (1c) from `clang -O1` C (`-O1` speculates exactly the loads it proves), so its C-level reachability is undetermined and a fixture would pin an IR-only shape. bd `e1gr`'s class, filed rather than faked. |
| R4R2-4 | P3 | the round-1 `R.InRegion.count(...)` guard is **provably dead** — E3 runs first and makes the shape its comment names unreachable; dropping it moves 0 of 2149 | **RECORDED AS DEAD**, kept as defence in depth with the reason corrected and a retirement trigger. Not deleted (L3: a closure table is worth its most-missing row). |
| R4R2-5 | P3 | **9 of 14 gate injections MISSED by BOTH accept fixtures**, including injected `cqrt_ry` (Rule 7), `cqrt_measure` (Rule 5) and `cqrt_free` (Rule 6). Round 1's closure was scoped to the five injections it happened to try | **FIXED, and the instrument matters more than the fix.** A broad negative list CANNOT close these — these shapes legitimately emit `cqrt_ry`/`cqrt_x`/`cqrt_free`/`cqrt_measure`, and a first attempt at one went red against the fixtures' own output. What closes them is an EXACT COUNT per family. Re-validated with an injection matrix carrying a NULL CONTROL: all four accept fixtures (both increments') now catch all 8 injections. |
| R4R2-6 | P3 | **the increment's own headline shape, as written in the source comment, still declines**: the ONE-accumulator `if (cond) { Z -= z[i]; }` leaves at `gate=W-witness` identically on both binaries. The increment widened E4, not the CLAIM WITNESS | **CORRECTED** at the comment, with the residual named as a real over-decline and the reason W cannot be widened as a side edit (a mutant measured `D->A=35, stream-moves=11` for bypassing it). ⚠ Every fixture and the e2e slice use the TWO-assignment form, so **nothing in the tree can see this residual**. |
| R4R2-7 | P3 | `MEASUREMENT_INC4.md`'s "run of record" named a different binary and a 2147-fixture corpus; round 1 ran no suite at all, so **no gate of record existed for the binary under review** | **RE-MEASURED** — see §6 of that file, now keyed to the shipping binary. |
| R4R2-8 | P3 | `LazyLoadAnalyses`' lifetime comment is false: the bundle is alive through `RegionFlattener::run()`, `foldConstantCones…` and `simplifyFlattenResidues…`, all of which erase | **FIXED.** The real ground is "nothing queries it after a mutation", not "it is discarded first". Benign today; a future caller that queries it post-flatten reads a stale SCEV. |

## ⚠ MY OWN INSTRUMENT LIED TO ME FIRST, AND THE NULL CONTROL IS WHY I KNOW

Re-running R4R2-5's matrix, my harness reported **NULL CONTROL = CAUGHT** — a no-op
mutation "detected". That is the harness failing, not the fixtures, and every CAUGHT
below it was meaningless. TWO separate bugs: the LLVM tools were not on `PATH` (so `count`
never ran), and a `\&\&` escaped into a command substitution broke the `%S` expansion.
Only after both were fixed did the null control read MISSED and the results become
evidence. **CLAUDE.md's standing lesson, paid again in this session: a mutation harness
that has not been run against a no-op mutant is measuring itself, not the code.** The
harness is committed at `probes/inc4/injection_matrix.sh` with its null control wired in.

## What round 2 attacked and did NOT break

Round 1's four un-measured QROM `No` reasons, now MEASURED (narrow index, alloca origin,
`!widthHasQramCell`, matcher-nullopt): all decline identically on both binaries, and it
derived the structural reason the flat family is closed (every route that defeats
`matchQramAccess` leaves only (1b) — which goes through it — and (1c), which needs a
constant offset, and a constant index can never become tainted). Obligation (1) bites in
both directions across ~12 shapes including a NEST (an outer-loop index read inside an
inner-loop region declines, because arm (1a) asks about the inner loop only — falls safe).
Obligation (2): no counterexample, with the call routes closed too. The P1 fix is surgical
(witness declines on both; the `cq_measure` control accepts on both).

## ⚠ ROUND 2's OWN BOUNDARY

No simulation. It did **not** reach the `ClaimAll`/Bennett-clone path with a classical
table read — **the same hole round 1 declared, still open**. It did not confirm
`kMsgQramLoop` + U2b were the ONLY things closing R4R2-1. Its A/B compares exit code,
stderr and emitted IR and **does not evaluate any fixture's FileCheck directives** except
for the 7 classical-table fixtures. Untouched: `invoke`; multi-function modules (**bd
`1yeu` stands**); `-O2`/`-O3`; `llvm.assume` (argued, not measured); increment 3's E2
admission itself. Its full `ctest` ran as two batches under decaying load, not one
invocation.

⚠ **Side observation, pre-existing and uninvestigated**: a duplicate-body scan (sha-256 of
non-comment lines, L8) over all 2149 fixtures found **5 identical-body pairs**, none from
this increment — one of them, `control_inplace_ry_reject_stale_diag_alias_{backward,forward}.ll`,
being two fixtures whose names assert OPPOSITE directions over byte-identical IR. Worth a
bead.
