# bd `fn1q` increment 4 — Rule-13 ROUND 1 (independent agent)

**VERDICT: `BLOCKED` — 1 P1 (a wrong ACCEPT; verify-clean silent miscompile), 2 P2, 4 P3.**

The reviewer built an ISOLATING MUTANT (one line: `recoverRegion(…, &Loads)` → `…, nullptr`)
so its A/B measured increment 4 ALONE rather than 3+4, verified the mutant baseline
bit-identical to the subject, and ran a subject-vs-subject null control over 2147
fixtures first (four zeros).

⚠ **ITS ISOLATED CORPUS A/B WAS CLEAN — `A→D=0 D→A=2 stream-moves=0` — AND THAT CLEAN
SWEEP WAS THE PROBLEM, NOT THE CLEARANCE.** The corpus contained no instance of the P1
shape, because until this increment the shape declined. A sweep can only find a
regression in a population it already has.

## P1 — `R4-P1-1`: the classical arm LAUNDERED a QROM read past QROM's own no-cloning fence

**CONFIRMED INDEPENDENTLY before fixing.** A plain-`CQ.h` C program (`probes/inc4/WITNESS_P1.c`):

| binary | result |
|---|---|
| ORACLE | exit 1 — `cq controlled lowering: nested control flow under quantum control` |
| SUBJECT (defective) | **exit 0, 0 BYTES of stderr**, links and runs |

and the emitted stream carried two `cqrt_copy_i64_controlled` under the tainted flag
building a **superposed index rail**, then `cqrt_qram_load_i32` on it, then the value to
`ret` with **no `cq_measure`** — the index rail never uncomputed, never freed.
`opt -verify` clean; `free_pairing_check.py` `0 violation(s)` because it is structurally
blind to a leaked template-minted rail.

**THE CAUSE, AND IT IS A SENTENCE I WROTE.** The predicate's comment claimed its taint
test made the classical and QROM admissions *"disjoint by construction"*. QROM returns
`No` for **six** reasons, not one. For `coherentlyEscapesToReturn` the load IS a genuine
QROM read, refused because its value escapes coherently — and such a read's index is
UNTAINTED at round-1 taint, becoming tainted only once the flatten rewrites a
region-internal phi into a select. **CLAUDE.md L1's "PREDICATE species" verbatim**: a
fence asked at round-1 taint while the lowering decides at final taint. Also L3's mirror:
a caller was added to `matchQramAccess(allowUntaintedIndex=true)` without asking what its
existing caller was holding.

⚠ **THE EMITTER-SIDE BACKSTOP DOES NOT COVER IT.** By `lowerQramReads` the merge is
already `cqrt_copy_*_controlled` VOID calls, so `coherentlyEscapesToReturn`'s forward SSA
walk stops at the merge and never reaches the `ret`. Claim time is the only effective fence.

**FIXED** by `qromShapedReadTaintsIndexAfterFlatten` (exported from `QramLowering.cpp`,
calling QROM's own `matchQramAccess` + `indexWillTaintAfterFlatten` — Rule 14, not a
re-derivation). Verified: the witness now declines with the ORACLE's exact message; the
**control** — the same program with `cq_measure` on the results — still ACCEPTS on all
binaries, so the fix is surgical rather than a blanket refusal. Pinned by
`control_predmux_reject_classical_table_qrom_laundering.ll`, whose NON-VACUITY was
measured by MUTATION: with the fence disabled and the tree rebuilt the fixture **exits
0**; restored, it declines.

## The rest, with dispositions

| # | sev | finding | disposition |
|---|---|---|---|
| R4-P2-1 | P2 | the width gate uses `abiWidthFromType` (non-empty for i80/i128) where a qram cell is needed, so an `i128` table was CLAIMED and FLATTENED and only then declined — the detect-before-mutate class | **SUBSUMED by the P1 fix**, measured: the probe's index is a region-internal phi, so it will-taint and is now refused at `E4-gep` BEFORE the claim, with the pre-mutation message restored. |
| R4-P2-2 | P2 | the increment's central §5.2 claim — *"the loaded value is NEVER promoted to a qubit handle"* — is **measurably false**, repeated in FIVE places as the safety ground | **CORRECTED IN ALL FIVE.** Verified independently: `cqrt_alloc_i32(i32 %z)` is emitted when the table value is an ARM OF THE MERGE. The mechanism is sound and pre-existing (the ORACLE does it for a classical ARGUMENT in the same slot) — §5.2 governs the OPERAND SLOT of a mixed op, and the sentence now says that. L7's shape. |
| R4-P3-1 | P3 | *"a loop-free mutable table has no arm that can prove it"* is false — arm (1c) admits a mutable table at a constant index, a bare global load, an uninitialised alloca | **CORRECTED** at the predicate and in the fixture. The fixture declines because its INDEX is variable, never because its table is mutable. |
| R4-P3-2 | P3 | injection matrix: the flat accept fixture **MISSED 3 of 5** mutations, including an injected `cqrt_alloc_i32(i32 %z)` — the one property its header says it exists to pin | **FIXED**: closed `grep \| count` lines and the §5.2 negatives. Re-validated by mutation in both directions. |
| R4-P3-3 | P3 | `gate=E4-load` was reachable and had **no** fixture — all three rejects pinned `E4-gep` | **FIXTURED** (`…_reject_classical_table_load_arm_unprovable.ll`). |
| R4-P3-4 | P3 | the gep arm asked the hoist-point proof about a load that need not be in the region | **FIXED**: `R.InRegion.count(LU->getParent())` guards the call. |

## What round 1 attacked and did NOT break

Obligation (2), the store: no counterexample, and it verified the argument clause by
clause. Obligation (1): the admission boundary is real and at the table size (trip 3
accept / trip 4, 10 decline; runtime-trip decline; stride-2 into `[6 x i32]` accept,
into `[5 x i32]` decline — the over-approximation falling safe). `LazyLoadAnalyses`:
clean, including destruction order and the `foldConstantConesInFunction` ordering. The
QramLowering export: additive, changes no QROM behaviour.

## ⚠ ROUND 1's OWN BOUNDARY

No full `ctest`, no whole `ir-pass-lit`, no twin matrices; its A/B compares exit codes,
stderr and emitted IR and **does not evaluate any fixture's FileCheck directives**. No
simulation. It did **not** attack the `ClaimAll`/Bennett-clone path, the remaining four
QROM-`No` reasons (argued analytically, not measured), the L1 window increment 3's commit
message names as its largest hole, or the increment-3 × increment-4 composition beyond
the shipped fixtures. It mutation-tested only the two accept fixtures, against five
injections.
