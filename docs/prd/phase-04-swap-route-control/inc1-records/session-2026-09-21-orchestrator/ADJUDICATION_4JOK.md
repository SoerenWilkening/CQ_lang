# bd `test_C_libtooling-4jok` — ADJUDICATION of the composed accept surface

**Owner ruling at open (2026-09-21, Q1):** *adjudicate, then land if clear.* Reproduce
the composed binary, adjudicate the nine AS A FAMILY analytically, then run an
INDEPENDENT Rule-13 round aimed at them. If the round clears them, bd `tu9q` P0+P3
lands WITH the nine as its Rule-12 red-green fixtures and e2e goldens, on top of
bd `6n1s` and never below it. If the round finds a wrong unitary, the offending
shapes get a fence instead. **The outcome is decided by the evidence, not up front.**

## 0. Binaries — re-measured, never quoted

```
MAIN      cq-opt 8280ea8d86bcaf4ed82cae92f65733fe8ae601086dfb721d58feeda55d8d9da2
          libCQPass.so 01fbe0c125ead5b40a77178e78278df8a43e1b0133f903c9f2d5bdd81a8d575f
          (main 78b6bf64 — the SHIPPED compiler)
COMPOSED  cq-opt 3368af1262695d7e4c573d3958f0a9aa48e604bf5248e1b85a52362ac76f69dc
          libCQPass.so 48b8b4db61777082e98bf9f15da7d50ebe386a7d5342b1292c9f05b72260ffaf
          (main 78b6bf64 + bd tu9q P0+P3 `30b80d7f`, merge c24fa34f,
           worktree /private/tmp/claude-501/cq-composed)
```

⚠ **THIS IS NOT ROUND 3's COMPOSED BINARY AND THE DIFFERENCE IS NOT COSMETIC.**
Round 3 merged onto `main` at `00c36e93`; this merge is onto `78b6bf64`, which
additionally carries Rule-13 round 4's **(P4) crash fence** in
`promoteLoopCarriedHandleSeeds` — a clause that aborts-vs-declines on plain C.
The composition adjudicated here is therefore a different one, and every row below
was re-run rather than carried. The merge conflicts in exactly one place
(`ir-pass/include/LoopPlan.h`, two declaration blocks at one anchor), was resolved
ADDITIVELY, and both postconditions keep their call sites
(`declineUndischargedMarkedBodyRails` at `CQLoweringPass.cpp:958/1372`,
`declineUndischargedExitObligations` at `Uncomputation.cpp:2082`).

## 1. BOUNDARY CONTROLS FIRST, BEFORE THE FIRST REAL MEASUREMENT (protocol item 1)

| control | expectation | result |
|---|---|---|
| NULL — `example/grover/grover_oracle_uncompute.c` rolled cascade | must be IDENTICAL on both binaries | **85 lowered lines, 50 trace lines, 2b `2 verified, 0 violation(s), 0 unproven` on BOTH** |
| POSITIVE — `tu9q_ht_rolled.c`, the parked branch's own intended customer | must MOVE D→A | **MAIN declines at the `s82e`/`6n1s` string; COMPOSED accepts at 67 lowered / 40 trace lines** |

Neither the harness nor the merge is lying about the direction of the effect.

## 2. THE NINE REPRODUCE EXACTLY, on a binary round 3 never built

All nine DECLINE on MAIN and ACCEPT on COMPOSED, at the lowered-line counts round 3
recorded (107 · 106 · 84 · 101 · 116 · 103 · 110 · 154 · 111 — every one matches).
On COMPOSED, all nine: `opt` exit 0, **stderr 0 bytes** (no warning either), stage-2b
STRICT **`0 violation(s), 0 unproven`**, link and run clean.

`d3_phasearm_only` is a composed-only STREAM move (80→83 lowered, 34→40 trace) and
`j2_licm_cond_hoisted_rail` a composed-only DECLINE-STRING move onto
`kMsgExitObligation` — which is the (ii-d) postcondition **firing**, so it is not
vacuous on this binary either.

## 3. THE LOAD-BEARING QUESTION: the multiplicity trigger

`railLocalQualifies`' final clause carries a written retirement trigger:

> *"a recovered gate in the PREHEADER (does not repeat) with `At` in a body marked
> here (repeats K times) would emit K adjoints against ONE forward gate … Widening
> it — even 'just' to admit a hoisted loop-invariant temp — makes it reachable, and
> **no shipped test would go red**. Re-derive the multiplicity there first."*

bd `tu9q` (ii-d) is exactly that widening. Its claimed discharge is **PLACEMENT**:
`Uncomputation::anchorForConsumer` (P2) discharges such a rail ONCE at the loop's
unique exit, and `multiplicityAgrees` (P1) refuses every other pairing; the clause
also requires `loopExitDischargePoint(L)` non-null and `allUsersInside(V, L)`.

**MEASURED on COMPOSED, and the nested case is the one that matters.**
`m4_nested_outer_carried` puts the hoisted `mul` rail outside BOTH loops, read by
the INNER loop's condition, with the OUTER loop running K times — the exact
K-adjoints-against-one-forward-gate shape. Its trace:

```
line   3   cq_template_mul_i32_hl(h0, 3) -> h1      <- ONE mint
line 122   cq_template_mul_i32_hl_unc(h1, h0, 3)    <- ONE adjoint
line 123   cqrt_free(h1)
line 124   cqrt_ry_i32(h0, 0x1.ccccccccccccdp-1)    <- the interference, AFTER
line 125   cqrt_measure_i32(h0)
```

`anchorForConsumer`'s walk reached the OUTERMOST loop's exit. **1 mint, 1 `_unc`,
discharged before the trailing non-diagonal gate.** The hazard the trigger names is
refuted by construction on this binary, not taken on report.

## 4. THE INSTRUMENT, AND THE FACT THAT IT LIED TO ME FIRST

`probes/dephase.py` asks the two questions the golden byte-diff cannot and that
stage 2b is **structurally blind to for a template-minted rail** (there is no
`cqrt_alloc` to count):

* **(A) multiplicity / lifetime** — per-rail mint vs `_unc` vs free; double-free;
  free-of-a-never-alive rail; and a **dirty free** (a rail freed while neither
  `_unc`'d, returned by a paired CNOT, nor returned by Ry additivity).
* **(B) the Rule-8 question** — at EVERY `cqrt_ry_*` and EVERY `cqrt_measure_*`, is
  any rail whose ancestry reaches that target still ALIVE? A non-empty set is a
  which-path record left standing across an interference on the register it records.
  `cqrt_rz`/`cqrt_x` are deliberately not asked: diagonal-or-permutation on the flag.

⚠ **ITS FIRST SPELLING MISSED A REAL MUTANT, IN THE MISSED DIRECTION, AND THAT IS
THE ENTRY THAT EARNS THE REST OF THIS SECTION** (L10). Mutant **M3** — delete one
per-trip `and`-rail `_unc` from `o1`'s trace, leaving its `cqrt_free` — scored
**CLEAN**. The cause was a guard I had written to permit deliberate Rule-6 leaks
(`unc != 0`) which silently also permitted *freed but never uncomputed*, i.e. the
Rule-6 dirty free itself. A second miss followed in the other direction: the flat
twin `d3ru` was flagged for two rails the spine discharges by **Ry ADDITIVITY**
(`ry(+0.5) … ry(−0.5)` then free) rather than by a `_unc` symbol — a FALSE POSITIVE
that would have been filed as a defect had I not read the trace.

The checker now ships **nine boundary controls** run on every invocation
(`--selftest`): null, leak, clean, multiplicity, dirty-free, CNOT-return,
Ry-additivity-return, Ry-dirty-free, double-free. Against REAL traces it kills
M1 (delete the hoisted rail's `_unc`+free → 2 findings), M2 (move the trailing Ry
before that discharge → 1), M3 (→ 1, after the fix) and leaves the null mutant M4
clean.

**With that instrument: all nine composed accepts and all four hand-unrolled twins
are clean — no multiplicity disagreement, no double-free, no dirty free, and no
live record of any register across any Ry or any measure on it.**

## 5. K-INDEPENDENCE — these are rolled, not unrolled

| probe | K=3 | K=64 | K=1000 |
|---|---|---|---|
| `d3r_phasearm_only_rot` | 84 | 84 | 84 |
| `m4_nested_outer_carried` | 103 | 103 | 103 |
| `o1_owner_plus_hoisted` | 111 | 111 | 111 |

Lowered-IR line counts, measured without `-g`. The IR size is independent of the
trip count, so the accept is a LOOP lowering and not an unroll.

## 6. ROLLED vs UNROLLED — including round 3's UNADJUDICATED F-4

Round 3 filed the `d3r` vs `d3ru` divergence as *"benign by analysis; unadjudicated
in writing"*, with the note that no twin-matrix cell and no quarantine entry covers
it. Adjudicated here, with the mechanism named, for all four twin pairs:

| pair | rolled | flat | delta | cause |
|---|---|---|---|---|
| `d3r`/`d3ru` | 41 | 45 | `cqrt_free` 7 vs 9, `cqrt_ry_i1` 3 vs 5 | the FLAT form pairs two unmeasured prep rails' `Ry(0.5)` with `Ry(−0.5)` and frees them; the rolled form leaves them allocated |
| `e3`/`e3u` | 73 | 73 | `add_i32_hl` 3 vs 2, `alloc_i32` 5 vs 6 | `-O1` folds the flat form's `5-3` to `cqrt_alloc_i32(2)` |
| `d1`/`d1u` | 82 | 77 | + `icmp_sgt` 3 vs 1, `ry_i1_controlled` 3 vs 2 plus 2 bare `ry_i1` | `-O1` folds the flat trip-1 compare to TRUE, so a CONTROLLED Ry becomes an UNCONTROLLED one |
| `i3`/`i3u` | 109 | 100 | + `ashr_i32_hl` 3 vs 0 | `-O1` const-folds the flat form's `(q>>i)` shifts |

**Every row is the `-O1` trip-1 const-fold class that `CLAUDE.md` §4e ruling 2
already blesses**, and not one is a rail-discharge divergence. **LEAK PARITY is
exact in three of the four pairs** (11 rails left allocated in each form for `e3`,
`d1`, `i3`). The fourth, `d3r`, diverges in the SAFE direction: the flat form
discharges two MORE rails than the rolled one, so the rolled form is strictly more
conservative — which is also why it is not a Rule-6 concern. Both halves of all
four pairs are clean under §4's check.

## 7. THE SECOND GATE ON THE LANDING — CLOSED BY CONSTRUCTION

The brief's second gate: *bd `tu9q` P0+P3 alone over-accepts the bd `6n1s` g8
shape and must never land below bd `6n1s`.*

`git merge-base --is-ancestor 22a0ab11 main` → **true**: bd `6n1s`'s fix is already
an ancestor of `main`, so any merge of `30b80d7f` onto current `main` carries
`declineUndischargedMarkedBodyRails` by construction. **Measured:**
`i1_g8_carried.c` DECLINES on MAIN *and* on COMPOSED at the `s82e`/`6n1s` string.
The over-accept exists only on the parked branch's own base and is not reachable by
this landing path. ⚠ It remains a REBASE hazard, not a merge one: the branch must
never be rebased below `22a0ab11`.

## 8. WHAT THIS SECTION DOES *NOT* ESTABLISH

Rule 2, in the words it has to be said in. Everything above is `opt` exit codes,
stage-2b rail identities, emitted traces and analytic reasoning. There is no
simulator (owner decision 2026-06-10) and the golden byte-diff proves that every
symbol resolves and signature-matches, **not** that the unitary is right — the
project's own history records every shipped Grover golden having been the identity
under exactly that kind of evidence. `dephase.py` is MY instrument, written by the
same agent that wants the answer to come out clean; its nine controls and four
real-trace mutants bound how wrong it can be, they do not make it a proof.

**That is why the owner's ruling routes this through an independent Rule-13 round
before anything lands, and why §9 is written by someone who did not write §1–§8.**

## 9. CORPUS A/B — 2109 fixtures, and the two movers that are NOT mechanical

`probes/corpus.py`, MAIN vs COMPOSED, recording exit code, first diagnostic AND a
sha-256 of the lowered stdout (so a STREAM move on an accepting module is visible;
a sweep with `-o /dev/null` cannot see one). **Boundary controls ran first, on this
invocation, before the first real measurement**: MAIN-vs-MAIN over 120 fixtures =
**0 movers**; the branch's own declared mover moves = **1**. Both required, both met.

```
2109 fixtures: 8 movers | A->D 0 · D->A 4 · D->D(string) 1 · A->A(stream) 3
```

**Zero A→D**, and the 8 are exactly the 8 the branch declares — measured here on a
base the branch never saw. Six are mechanical (three intended DECLINE→ACCEPT
conversions plus three stream re-derivations). **Two are not, and the branch says so
itself — *"retiring another owner's Rule-13 fence is not an implementer's call"*.**

### 9a. `loop_pairing_reject_round2_falsified.ll` — DECLINE → exit 0

Its header states the decline's ground: *"`%m2`'s forward gate is in the loop
PREHEADER and runs ONCE, while a marked body's discharge point runs K times …
leaving the grant standing is **K adjoints against ONE forward gate** — an
over-reversed rail, a wrong unitary, not a leak."*

**The stated hazard does not occur on COMPOSED.** Read off the lowered IR:

```
entry:  %h_op = call i32 @cq_template_mul_i32_hl(i32 %out1, i32 2)     <- ONE mint
loop:   … per trip: lshr rail minted, _unc'd and freed …
out:    call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %out1, i32 2)  <- ONE adjoint
        call void @cqrt_free(i32 %h_op)
```

One mint in the preheader, one adjoint in the loop-EXIT block — which is P1
(`multiplicityAgrees`) and P2 (the loop-exit anchor) doing exactly what (ii-d)'s
licence claims. Stage-2b: `4 template rail mint(s) of which 0 left dirty`.

⚠ **BUT THE FIXTURE IS THE ONLY PIN OF A FENCE THAT IS STILL LIVE.** Measured:
`grep -rl 'round-1 iteration-local marking falsified by round-2 taint' ir-pass/test/`
returns **exactly one file — this one** — and
`declineRound2FalsifiedRailGrants` is still called at BOTH entry points on COMPOSED
(`CQLoweringPass.cpp:829` and `:1313`). Landing as-is leaves a live L1 fence with
**zero fixtures**, and loses the fixture's other stated job: *"it PROVES THE WINDOW
IS REACHABLE. A fence written for an L1 window nobody can construct is a
prediction, not a test (L10)."*

**A REPLACEMENT WITNESS EXISTS AND IS MEASURED.** (ii-d) requires
`allUsersInside(V, L)` — a conjunct its own comment calls *"not conservatism, it is
the clause's subject"*. Adding ONE post-loop read of `%m2` violates it, the root is
refused, the round-1 grant stays falsified, and the fence fires:

```
out:
  %after = and i32 %m2, 1            ; <- the only edit
…
MAIN:     exit=1 :: cq loop lowering: round-1 iteration-local marking falsified by round-2 taint
COMPOSED: exit=1 :: cq loop lowering: round-1 iteration-local marking falsified by round-2 taint
```

Same string, both binaries. **So the cost is recoverable rather than paid**: the
landing converts the old fixture to an accept and adds this one as the fence's new
pin, and the L1 window stays demonstrably reachable. The sibling the old header
names as the "refusal is not indiscriminate" control
(`trackT/probes/adv/l1_round2_grow_65arm.ll`) still ACCEPTS at exit 0 on both.

### 9b. `control_inplace_ry_reject_rail_inloop_carried_invariant_read.ll` — string move

Still a DECLINE on both (the safe direction); the owner of the diagnostic changes
from `ControlDetect`'s `control flow inside a loop body under quantum control` to
the (ii-d) postcondition. Its `CHECK` line therefore goes red and the fixture owes a
re-derivation, not a deletion (L8). The string it pinned has **28** other pins in
the corpus, so nothing is unpinned here — but per CLAUDE.md L6 the conjuncts now
decide **which owner speaks**, and the re-derived header must say so rather than
silently swapping a string.

## 10. WHERE THIS LEAVES THE LANDING

Everything the bead asked for as a precondition is measured and holds:

| gate | result |
|---|---|
| the nine reproduce on a CURRENT-main composition | **yes**, exact line counts |
| Rule-8 / multiplicity / lifetime on all nine + 4 twins | **clean**, instrument validated by 9 controls + 4 real-trace mutants |
| the `railLocalQualifies` multiplicity trigger | **refuted by construction** (nested `m4`: 1 mint, 1 adjoint, before the interference) |
| K-independence | **yes** (84/103/111 at K=3/64/1000) |
| rolled-vs-unrolled | all deltas are the blessed `-O1` trip-1 fold class; leak parity exact 3/4, safe-direction 1/4 |
| corpus A/B, 2109 fixtures | **0 A→D**, 8 movers = the branch's declared 8 |
| the bd `6n1s` merge-order gate | **closed by construction** (`22a0ab11` is an ancestor of `main`) |
| the only unpinned fence | **replacement witness constructed and measured on both binaries** |

**What is NOT yet established is the only thing that matters under Rule 2: an
independent adversarial opinion.** §11 is it.

## 11. THE INDEPENDENT OPINION — Rule-13 round 5

`round5/REVIEW.md` (independent agent, wrote neither increment, no suite run, 35
probes + 2 harnesses). **`CLEAR-WITH-ITEMS`. P1 count: 0.** 1 × P2, 6 × P3.

### What it found that §1–§10 did not

**F-1 (P2) — the code's stated reason for being safe is the wrong reason.** Clause
(ii-d)'s comment claimed its own conjunct establishes the placement licence: *"if
there is no once-per-mint point, there is no licence, and the root is refused."*
**In a NEST that is false.** The clause asks `loopExitDischargePoint(L)` of the
loop it is MARKING; `anchorForConsumer` asks it of `LOut`, the OUTERMOST loop
enclosing the consumer that does not contain the mint. Same predicate (Rule 14 is
satisfied), **different loop** (CLAUDE.md L2 is not). Built: a nest whose inner
loop has a unique exit and whose outer loop does not — the root IS granted, the
anchor returns `nullptr`, and the only member between that and a leak with the
dephasing fence already disarmed is `declineUndischargedExitObligations`. **It
fires.** Safety is real; the argument was pointing at the wrong member.

⚠ This is the THIRD quantifier mismatch in this increment. The file states the
other two at both their sites (`markedHeaderOf`'s innermost `LI.getLoopFor`
against the anchor's outermost `Loop::contains`, bd `emkg`); *"which loop's exit"*
was stated at neither. **Corrected at the source in the landing commit**, with the
two fixtures (`loop_pairing_reject_nest_multiexit_hoisted.ll` and its
one-conjunct-different accept control), which are also the multi-exit fixture bd
`tu9q`'s own `trackT2/IMPL_T3.md` §3 F-R2-1 records as *"owed and has none …
a PREDICTION rather than a test."*

⚠ And read that fixture's MAIN column before filing anything against the
composition: on the **pre-landing** compiler it ACCEPTS at exit 0 with the rail
live across the trailing `cqrt_ry`, carrying only the ruled `lyyf` warning. **On
this shape the landing is strictly stricter.**

**F-2 (P3) — §4's instrument is unsound on the entanglement axis, and the round
re-established the clearance without it.** `dephase.py` builds ancestry only from
`cq_template_*` mint operands, so `cqrt_cnot`, `cqrt_toffoli`, `cqrt_cswap` and
`cqrt_copy_<W>[_controlled]` create **no edge** — and those are exactly how every
value-merge rail in these accepts is built (in `o1`, rails `h9`/`h16`/`h23` and
flags `h8`/`h15`/`h22` all have EMPTY ancestry). It reports "OK" on all three
canonical Rule-8 violations **and** on `y3_rot_merged_unrolled.c`, a real
compiled program about which **the compiler itself emits** `cq rotation lowering:
non-diagonal gate over a live derived record`.

⚠ **So §4's nine boundary controls and four real-trace mutants were not enough,
and the reason generalises: every one of them was written by the agent that
wanted the answer to come out clean.** Two misses in one day on one instrument,
both in the MISSED direction. `dephase.py` is kept, marked SUPERSEDED, with the
misses in its header so it cannot be cited later.

The round rebuilt it as `entangle.py` — edge-complete over the permutation gates,
XOR for linear gates so a paired CNOT bracket cancels, union for non-linear,
measurement as projection, an adjoint-operand-identity axis, an
UNCLASSIFIED-symbol refusal, **18 boundary controls including two null controls**
— and re-ran the family: **26 composed traces, ONE Rule-8 finding, and it is the
loop-free program that is byte-identical on MAIN and carries the ruled warning.
MAIN has a second which COMPOSED declines. No Rule-8 finding is attributable to
the composition.** The clearance stands, on that instrument.

**F-7 — the surface is TEN, not nine.** `g3_bank_mixed_one_loop` is a
MAIN→COMPOSED accept on this pair, where round 3 tabulated it as declining on all
four of its binaries. Shipped as `slice_4jok_bank_cell_from_hoisted.c`. The
related item — (L3)'s trigger is held closed on COMPOSED by
`rewriteRailBankCellTypes`, **not** by the (I1) ground its comment gives — is
filed as bd `a945` (L7's shape, the second instance in this area).

**F-4 independently reproduced §9a's replacement witness**, character-for-character
on both binaries. One file ships, not two.

**F-5 confirms §9's reading of the three `*_leak_control` movers**: `3/3` rolled
against CLAUDE.md §5's recorded `3/0`, i.e. **a fix, not a restoration** — and
flags the re-derivation as the easiest thing to get backwards at this landing.

**F-3 (positive)** — the postcondition is non-vacuous on four shapes round 3 never
reached (a guarded runtime-trip loop, an in-loop parent mutation, a non-foldable
mutation, the multi-exit nest). Round 3 had one witness.

**F-6** — the merge left a comment 2800 lines from the code contradicting it
(*"it is UNCHANGED here and still leaks"*, of the very rail (ii-d) now admits).
Corrected at the source in the landing commit, per L7's twist.

### The round's own two caveats, carried because they bound the result

* **It had only two binaries, so it cannot certify anything "composition-only".**
  The four-way attribution remains round 3's, on round 3's base.
* ⚠ **A probe-design trap that also exposes round 3.** Every round-3 probe ends
  `main(){ return slice(4); }`, so `-O1` const-propagates the argument and a
  `break` or guard written in terms of it is DELETED before the pass sees it —
  the round's own first break probe measured a loop with no break. **Round 3's
  §3 row "multi-exit … all decline on all four, at earlier walls" is therefore
  unevidenced for any probe whose exit test reads the parameter** — not known
  wrong, not known right. And multi-exit is precisely where round 5 then found
  its P2, by hand-writing the IR instead. Filed as bd `46oo`.
