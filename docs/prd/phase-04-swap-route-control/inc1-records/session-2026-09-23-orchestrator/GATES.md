# GATES — session 2026-09-23 (bd `test_C_libtooling-fn1q` increment 2)

Every row is hash-keyed to the binary it was measured on. Nothing copied forward.

```
ORACLE   cq-opt       1b396ed08b01b8ecac7b268ba1d11ec3a90200e945ed091a43bf34ff23ad1c9e
         libCQPass.so f3a372fc275bcf15f2b3632b1fe3b586da086d6cc2040f0147675abe6cdcbe75   (main 2c08fa62)
SUBJECT-v1  cq-opt    a179aba6192dbe963c7b1bd0bc794b32cfb3b9eb64cfa1b5d96d38078a05d17e   (⚠ carries the round-1 P1)
SUBJECT     cq-opt    a0e31e0316496f71a6843cf8c31aebb81bcfbdc6fea162b5d34c0d32cc4d000b   (+ the round-1 fixes)
```
⚠ **EVERY ROW BELOW THAT SAYS "SUBJECT" WAS RE-MEASURED ON `a0e31e03…`.** The
`a179aba6…` figures are kept only where the table says SUBJECT-v1, because a gate
result measured on a binary that carries a P1 is a measurement of the wrong program.
⚠ **REPRODUCIBILITY.** The ORACLE was rebuilt from the pristine tree during this
session and came out **BIT-IDENTICAL** to the hashes recorded at the 2026-09-22
close. The build is reproducible; a hash mismatch is a real difference.

| gate | result |
|---|---|
| `lit ir-pass/test`, SUBJECT-v1 | **2126 discovered**, all pass (1 XFAIL), 60.23 s |
| `lit ir-pass/test`, **SUBJECT** | **2130 discovered · 2129 passed · 1 XFAIL**, 100.54 s |
| ⚠ **zero pre-existing fixtures moved** | the fixture delta IS the whole change |
| corpus A/B **null control** (ORACLE vs ORACLE), run **BEFORE** each real sweep | **0 movers of 2126** (v1) · **0 movers of 2130** (SUBJECT) |
| corpus A/B, SUBJECT-v1, 2126 fixtures | 0 A→D · 2 D→A · 0 string · 0 stream |
| corpus A/B, **SUBJECT**, all 2130 fixtures, exit + diagnostic + lowered-IR sha | **0 A→D · 4 D→A · 0 decline-string moves · 0 stream moves** — ⚠ **all four movers are the increment's own new accept fixtures**, which doubles as the positive control (the harness can see a move it is known to have) |
| full `ctest -j6`, SUBJECT-v1 | 474/474 in 593.47 s, load 26 → 77 |
| full `ctest -j6`, **SUBJECT** | **474/474 in 618.59 s**, load **~77** ⚠ heavy concurrent agent load throughout; NOT comparable with a quiet-box figure, and quoted with its load per Rule 19 |
| new accept fixtures' non-vacuity | both **DECLINE on the ORACLE** (`cq controlled lowering: control flow under quantum control`); the e2e slice's source likewise |
| decline fixtures | all three decline on **BOTH** binaries — they pin a decline that must SURVIVE |
| stage 2b on the new slice, STRICT | `17 rail mint(s) of which 13 left allocated, 0 template rail mint(s) of which 0 left dirty, 4 cqrt_free site(s): **4 verified, 0 violation(s), 0 unproven**` |
| e2e slice | `e2e-slice-control-predmux-rail-leaf` **Passed** 1.70 s |

## Mutation validation — both halves are load-bearing, MEASURED

| mutant | effect on `control_predmux_accept_rail_leaf_negation.ll` |
|---|---|
| **A** — `buildNegation`'s rail arm deleted | ⚠ **ABORTS** (full LLVM crash dump; the unchecked `cast<BinaryOperator>`) where the ORACLE declined cleanly at exit 1 — the bd `11qv` round-4 (P4) failure verbatim |
| **B** — the `select(¬c,T,F) == select(c,F,T)` fold deleted | **DECLINES** (`control flow`); the POSITIVE-polarity fixture is unaffected, so the two edits are independently pinned |

⚠ Mutant A's run also reproduced the standing trap in the harness itself: `$?`
captured after a pipe reports **`head`'s** status (0), not the compiler's. The crash
dump was the evidence, not the exit code. `rc=$?` on the line AFTER the command.

## Protocol item 5 — rolled vs unrolled vs flat, TRAILING non-diagonal gate on the condition's register

| form | ORACLE | SUBJECT |
|---|---|---|
| flat, 4 variables | DECLINE `control flow` | ⚠ **ACCEPT** |
| flat, **2 variables** (the already-shipped sibling) | **ACCEPT**, silently | ACCEPT |
| rolled | DECLINE | DECLINE — **identical** |
| unrolled, 3 sequential regions | DECLINE `nested control flow` | DECLINE `control flow` — ⚠ **a STRING MOVE** |

⚠ **The flat row is an accept-direction move in exactly the presence this probe
polices, and the two-variable row is the whole argument for it**: the class is
pre-existing and shipped, the gate KINDS are the same and the `cqrt_ry_i1` count is
IDENTICAL (3 on both), the four-variable multiset being the two-variable one plus
two more merges. **"Pre-existing" is true of the defect and FALSE of its
population** — this increment adds customers to bd `s82e` / Q-R1-1. Read
`IMPL_INC2.md` §4, not this cell alone.

⚠ **The string move is a MUTATE-then-decline**: on the SUBJECT PredMux claims and
flattens all three regions and `SelectClassify` then refuses a CHAINED select, where
the ORACLE declined pre-claim at `E6-condtree`. Both loud, both non-zero, nothing
consumed — but it is the bd `3c6m.67` self-operand pattern and it is filed, not
argued away.

⚠ **A PROBE THAT REACHES THE WRONG FENCE FIRST MEASURES THE WRONG FENCE, and it
happened here.** The first rolled probe wrote `bb[i]` twice per trip and died at
`cq rail bank: array is written from more than one store site` — a rail-bank fence,
nothing to do with control. The row above is the RE-AIMED probe (one store per
trip). Do not quote the first one.

## Counts at close (re-measured, not quoted)

| quantity | value | was (2026-09-22) |
|---|---|---|
| ctest entries | **474** | 473 |
| `^e2e-` | **464** | 463 |
| `^e2e-slice-` | **406** | 405 |
| `ls ir-pass/test/*.ll` | **2126** | 2121 |
| `ls tests/e2e/*.expected.log` | **408** | 407 |

---

## Rule-13 round 1 — verdict **BLOCKED**, and it was right to be

An independent agent that wrote none of this code. **1 P1, 2 P2, 3 P3.** The P1 is the
finding this increment is defined by, and it is the increment-1 **(K5) lesson repeating
verbatim one stage over.**

| # | finding | disposition |
|---|---|---|
| **P1-1** | ⚠ **A VANISHING USER GATE.** The rail leaf makes a `@cq_theta_i1` call a cond-tree node; three `track()` sites then put it in `MaybeDead` and **`sweepDead` ERASED it**. Measured: `opt` exit **0**, **0 bytes of stderr**, **no `cqrt_alloc_i1` and no `cqrt_ry_i1`** in the stream, where the ORACLE declined loudly. `opt -verify` clean; `free_pairing_check.py` `0 violation(s), 0 unproven` — structurally blind, there was no rail left to count. ⚠ **`RegionFlatten.cpp:107` ALREADY CARRIED THE RULING** (bd `3qlq.4`: *"never this stage's to erase, WHATEVER ITS USE COUNT"*) and it had not been carried across. | **FIXED** — `sweepDead` now skips `isCondRailLeaf`/`isCondRailPhiShape`, guarded **at the single eraser** rather than at the three trackers (a per-site fence is only as complete as its most-forgotten site). Pinned by `control_predmux_accept_rail_leaf_dead_rail_survives.ll`. |
| **P2-1** | ⚠ **THE FOLD'S "SCOPE BY CONSTRUCTION" WAS FALSE.** `canonicalizePred` is a second producer of `xor X, true` at that site (it has no xor arm and returns such a condition unchanged), so a module with **no rail anywhere** went ORACLE exit 1 → SUBJECT exit 0. Semantically correct, and still an unfenced accept widening outside the increment's scope. ⚠ The corpus was **structurally blind**: of 2130 fixtures exactly ONE carries an `xor i1 …, true` feeding a `br`, and the reviewer measured that it appears only on `CHECK:` lines — i.e. **no input module in the tree can reach the fold that way** (L10). | **FIXED** — the fold now requires the xor's operand to be a rail leaf. Pinned by `control_predmux_reject_notcond_no_rail.ll`. |
| **P2-2** | The **BoolAlg** path is a real new accept surface the increment shipped with no fixture. The reviewer verified it is SOUND and **gate-stream-identical** to the hand-if-converted twin the ORACLE already accepts. | **FIXED** — `control_predmux_accept_rail_leaf_boolalg{,_twin}.ll`, with the identity asserted **mechanically** by a `grep \| diff` RUN line. Re-verified independently: 52 gates each, `diff` empty, twin accepts on the ORACLE. |
| **P2-2a** | edit (3)'s claim that the fold keeps the widening a pre-claim decline **"everywhere"** is false; three claim-then-decline shapes survive. | **FIXED at the source** (L7): narrowed to *"at this site"*, with the three named. |
| **P3-1** | ⚠ The counts were **"at least N"**, not "exactly N": an injected **ninth** `cqrt_copy_i32_controlled` was **MISSED by all four prefixes**. The Rule-6 rail negatives *were* non-vacuous (an injected `cqrt_x`/`cqrt_free` on the user's rail is caught). | **FIXED** — every count closed by a whole-file `-NOT`. Re-validated: the same M3 injection is now **CAUGHT**, null control passes all four prefixes. |
| **P3-2** | All three decline fixtures pin the boundary they claim, verified by discriminator mutants. | no action |
| **P3-3** | Protocol item 5 holds as recorded, with a nuance: `entangle.py` flags the same Rule-8 interference **on BOTH binaries** (the user's own A/B/C/D entangled with `b`, all measured) — *not* the Q-R1-1 shape, every ancilla CNOT-restored and freed at a proven `\|0⟩`. The increment's own e2e golden runs **clean**. | recorded — say *"flagged identically on both binaries"*, never *"no findings"* |

⚠ **AND ONE FINDING THE ORCHESTRATOR MADE AGAINST ITS OWN FIXTURE, not the reviewer's:**
`control_predmux_reject_rail_phi_cond.ll`'s retirement trigger said *"when the rail-phi
increment lands this becomes an ACCEPT."* **Measured false** — its prep sits under a
CLASSICAL condition, so it will keep declining for a SECOND, independent reason (the
downstream proves a rail φ through `preppedRailPhiRegionIdx`, which needs a claimed
state-prep region). Corrected at the source in the same change, with the measurement
(L7: a record correction not applied to the source is not a correction).

## The standing lesson this increment paid for, again

**WHEN YOU REPLACE A STRUCTURAL CONTAINMENT WITH A PREDICATE, ENUMERATE WHAT THE
STRUCTURE WAS HOLDING.** Increment 1 learned it from `valueArmIsPureChain`'s (K5): four
conjuncts replaced *"any non-chain arm op declines"* and none named CQ's own front-end
calls, so a `speculatable`-marked `cq_phi` was hoisted and DELETED. Increment 2 repeated
it one stage over: E6's grammar admitted **no `CallInst` at all**, so no CQ intrinsic
could reach `sweepDead`; the rail leaf made one, and the user's Ry was deleted. **Same
class, same consequence, one increment apart — and both were found by the independent
round, not by the implementer, not by the corpus, and not by any gate in the tree.**

---

## Rule-13 round 2 — verdict **CLEAR-WITH-ITEMS**, **0 P1**, 2 P2, 4 P3

A SECOND independent agent (neither the implementer nor round 1), reviewing the
round-1 FIXES — which are NEW CODE, and Rule 13's measured budget lesson says the
first round on new code finds something. It did.

| # | finding | disposition |
|---|---|---|
| **P2-1** | ⚠ **"There is exactly ONE place this pass erases" is FALSE**, and the eraser it overlooks REPRODUCES THE ROUND-1 P1. `simplifyFlattenResiduesInFunction`'s `RecursivelyDeleteTriviallyDeadInstructions` deletes a rail whose only surviving use after the flatten is a folded residue: exit 0, **0 bytes stderr**, no `cqrt_alloc_i1`, no `cqrt_ry_i1`. FIX A does not reach it. Capped at P2 by two MEASUREMENTS: it needs a `memory(none)` attribute `CQ.h` cannot emit, and it is **PRE-EXISTING** (the ORACLE deletes the rail too for a compare-conditioned region). | comment **corrected at the source**; hole **filed as bd `test_C_libtooling-cfmv` (P1)** with its four probes. ⚠ *"Pre-existing" is true of the defect and FALSE of its population* — the rail leaf adds customers. |
| **P2-2** | ⚠ **Two comments in the SAME change contradicted each other**, and the false one justified the `buildNegation` arm: it claimed `collectCondTree` accepts `xor(rail, i1 const)` "since bd `3qlq.4`". `SelectClassify` refuses an `xor` with a constant operand, and bd `3qlq.4`'s shape is `xor %b, %c` — two NON-constants. Code safe; **the arm-swap fold is what makes it safe, and a reader of the old sentence would have concluded the fold is removable.** | **FIXED at the source**, with the fold re-labelled load-bearing |
| **P3-1** | ⚠ The `RAIL` prefix claimed *"read ONLY as a control"* but pinned only `cqrt_x`/`cqrt_free`: an injected `cqrt_ry_i1` / `cqrt_rz_i1` **ON THE USER'S REGISTER** was **MISSED** — the Rule-7 class the prose claims to cover. | **FIXED** — anchored at the rail's own preparation, negatives for both rotations; `dead_rail_survives` gets exact whole-file negatives. **Re-validated: all 3 injections CAUGHT on all 3 fixtures.** |
| **P3-2** | The "no `CallInst` at all" claim is true of the CONDITION TREE but `run()` also tracks a SWITCH SCRUTINEE with no grammar check — a `@cq_theta_si32` call can reach `track()` without being a cond-tree node, and `isCondRailLeaf` is `cq_theta_i1`-only. Round 2 could not build a module where it dies. | comment now says **UNPROVEN IN BOTH DIRECTIONS** |
| **P3-3** | `entangle.py` over-reports `DIRTY FREE` on the boolalg fixture (toffoli modelled by UNION); appears IDENTICALLY on the ORACLE-accepted twin. | recorded, so round 3 does not re-raise it |
| **P3-4** | The twin `diff` compared symbol names only, and both its sides run under the SUBJECT — "the ORACLE accepts the twin" was prose, not a gate. | **STRENGTHENED**: operands now compared (measured identical, 52/52) + a `test -s` vacuity guard; the same-binary limit is written into the fixture as a limit |

⚠ **AND MY OWN RE-VALIDATION HARNESS WAS BROKEN ON ITS FIRST WRITING, caught by its
own null control.** It derived FileCheck prefixes by scanning comment lines instead of
the RUN lines, so the UNMUTATED output "failed" every fixture (`null=1`). A harness
that runs a different command than lit measures itself, not the fixtures — CLAUDE.md
already carries that exact lesson, and it cost a measurement here. Every CAUGHT above
is from the corrected harness with `NULL=0`.

⚠ **AND A FIXTURE-HYGIENE TRAP WORTH CARRYING: NAMING A DIRECTIVE IN PROSE CREATES
ONE.** A comment line in `dead_rail_survives` referred to its own count directive by
its literal token inside backticks; FileCheck parsed it as a directive with an invalid
count and failed the fixture. Refer to a directive by description, never by its token,
anywhere in a check file.
