# bd `fn1q` increment 4 — E4's CLASSICAL CONST-TABLE READ (measured)

```
ORACLE   main 4db66534  cq-opt a0e31e03…   (predates increments 3 AND 4)
INC-3    main 76d2949b  (landed this session)
```

## 1. THE SHAPE, AND WHY QROM IS NOT THE WAY IN

`if (q > 2) { Z -= z[i]; P += p[i]; }` with `i` the CLASSICAL loop counter.
`classifyQromReadUnderControl` refuses it at its **index-TAINT** gate, and that is
correct rather than an obstacle: QROM is a QUANTUM-indexed table read that lowers to
`cqrt_qram_load_<W>`. Measured by the previous session: a power-of-two table still
declines, so the refusal was never about table size.

Here the index is classical, the value is classical, and it STAYS classical — it
occupies the sanctioned `_hl` LITERAL slot and is never promoted to a qubit handle
(§5.2). **Visible in the committed golden**: `cq_template_sub_i32_hl(h0, 1)`, where
`1` is `g_z[0]`.

## 2. THREE PROOF ARMS, AND WHICH ONE COVERS WHAT — MEASURED PER ARM

The owner ruled (2026-09-23) that the load is admitted **only with a PROOF** of
in-bounds-ness; failure to prove keeps today's decline, so increment 1's
`flat_qc_load` ruling stands unchanged.

| shape | arm | verdict |
|---|---|---|
| **MUTABLE** global, loop-counter index, in-loop | (1a) `isDereferenceableAndAlignedInLoop` | **ACCEPT** |
| **CONSTANT** global, masked index (`i & 3` into `[4 x i32]`), loop-free | (1b) `classicalTableIndexKnownInBounds` | **ACCEPT** |
| MUTABLE global, masked index, loop-free | — | DECLINE |
| unbounded parameter index | — | DECLINE (genuinely unprovable) |

⚠ **THE IMMUTABILITY ASYMMETRY IS INHERITED, NOT DESIGNED, AND THE FIRST DRAFT OF THE
SOURCE COMMENT DENIED IT EXISTED.** Arm (1a) asks LLVM directly and does not care
whether the object is mutable. Arm (1b) reaches the proof through
`matchQramAccess`, which requires `Origin.GV->isConstant()` because it is QROM's
matcher. Corrected at the source and pinned by
`control_predmux_reject_classical_table_mutable_masked.ll`. It is an OVER-DECLINE by
the owner's 2026-09-11 ruling; widening it means giving `matchQramAccess` the option,
which is a change to QROM's shared matcher with its own round — NOT a second bounds
proof inside PredMux (Rule 14, the drbq Inc-3 (b′) defect).

⚠ **ARM (1c) IS WEAKER THAN ITS NAME.** `isDereferenceableAndAlignedPointer` walks a
gep by ACCUMULATING A CONSTANT OFFSET, so any VARIABLE index defeats it — measured:
the masked index returns FALSE from (1c) and is admitted by (1b). Without (1b) the
loop-free arm would never have fired at all, which is the dead-clause defect
increment 3's round 2 flagged twice.

## 3. ⚠ THE BOUNDARY IS AT THE TABLE SIZE, AND THAT IS THE EVIDENCE THE PROOF IS REAL

Same module, one character changed:

```
trip == 3  (table size)  ->  ACCEPT
trip == 4                ->  DECLINE, gate=E4-gep
trip == 10               ->  DECLINE, gate=E4-gep
```

Pinned by `control_predmux_reject_classical_table_trip_exceeds_table.ll`, which is the
accept fixture with the trip count bumped. A real dereferenceability proof looks
exactly like this from the outside; if that fixture ever flips to an accept, E4 has
stopped proving anything and the speculated fault is reachable.

**Two further fault-shapes, both DECLINING at `E4-gep`** (`probes/inc4/`): an index
bounded only by a CLASSICAL GUARD (`if (i < 3 && q > 2)`) inside a RUNTIME-trip loop,
and the same bound written as a `select` (`j = i < 3 ? i : 0`) in a 100-trip loop. In
both the bound is real in the source and invisible to a per-iteration proof; in both
the safe direction is taken.

## 4. OBLIGATION (2) — THE STORE — NEEDS NO PROOF, AND HERE IS WHY

Hoisting a load is safe only if no store changes its value in between. This needs no
proof **today** because: E4 already refuses any `StoreInst` in the region
(`isSpeculatableDataflow` → `E4-dataflow`); the hoist target is before `R.Entry`'s
terminator, so nothing already in `R.Entry` is crossed; and E3 makes the region
single-entry/single-exit, so no out-of-region block lies between. A store elsewhere in
the loop body runs wholly before or wholly after the region each trip.
⚠ **RETIREMENT TRIGGER: the day E4 admits a store, this obligation becomes real and the
predicate must grow a memory-dependence proof.** Written at the predicate, not only here.

## 5. GATES

| gate | result |
|---|---|
| `lit ir-pass/test` | 2147 fixtures; green (see §6 for the run of record) |
| corpus A/B, oracle vs subject, 2146 fixtures | **A→D = 0**, D→A = 7, decline-string = 1, **stream-moves = 0** — every mover is one of this session's own new fixtures, across BOTH increments |
| stage 2b STRICT on the new slice | `2 verified, 0 violation(s), 0 unproven` |

⚠ The A/B oracle predates BOTH increments, so `stream-moves = 0` is the stronger
statement it looks like: neither increment 3 nor increment 4 changed any existing
accept's emitted stream by a single call.

## 6. GATES — THE RUN OF RECORD

⚠ **THIS SECTION WAS RE-MEASURED AFTER THE RULE-13 ROUNDS** (round 2, R4R2-7): its first
version named a binary that is not the one shipping and a corpus three fixtures short,
and round 1 ran no suite at all — so for a while **no gate of record existed for the
binary under review**. The figures below are the shipping binary's.

```
SUBJECT cq-opt 1bc989bc94a80e4a…
```

| gate | result |
|---|---|
| full `ctest -j6` | **478/478 in 572.60 s** — load **2.15 → 8.19** (a quiet box; NOT comparable with increment 3's 549 s at load 31, Rule 19) |
| `lit ir-pass/test` | **2147 discovered**, all green bar the 1 standing XFAIL |
| corpus A/B (2146) | A→D = 0 · D→A = 7 · decline-string = 1 · **stream-moves = 0** |

Count chain, re-measured (not copied):

| quantity | at inc-3 close | now |
|---|---|---|
| ctest | 477 | **478** |
| `^e2e-` | 467 | **468** |
| `^e2e-slice-` | 408 | **409** |
| `twin-identical` | 45 | **45** |
| `ls ir-pass/test/*.ll` | 2142 | **2147** |
| `ls tests/e2e/*.expected.log` | 410 | **411** |

⚠ **WHAT IS NOT ESTABLISHED (Rule 2).** Exit codes, gate streams, stage-2b rail
identities, emitted traces, a measured admission boundary, and analytic reasoning.
**There is no simulator.** The independent opinion is the Rule-13 round's, and its own
"WHAT I DID NOT DO" section is the boundary of this clearance.

### 6b. FINAL, post-round-2 (the shipping binary)

```
cq-opt 1bc989bc94a80e4ab53fc26774ddb15a…
```

| gate | result |
|---|---|
| full `ctest -j6` | **478/478 in 472.65 s**, load **1.98 → 4.58** (quiet box) |
| `lit ir-pass/test` | **2150 discovered, 2149 passed, 1 XFAIL** |
| corpus A/B vs the pre-increment-3 oracle, all 2150 | **A→D = 0** · D→A = 7 · decline-string = 1 · **stream-moves = 0** |
| injection matrix, 4 accept fixtures × 8 gate families, **null control MISSED** | **32/32 CAUGHT** |

Counts: ctest **478** · fixtures **2150** · goldens **411**.
