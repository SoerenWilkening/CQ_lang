# NEXT SESSION — bd `fn1q`: the conjunct's two P2s, then increment 5b

Read, in this order:
```
CLAUDE.md
docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-orchestrator/
    NEXT_SESSION_PROMPT.md    <- this file
    MEASUREMENT_M4_LANDING.md <- what landed, what was verified, and §5/§7 (the instrument lessons)
    REVIEW_R13_R2_INC5A.md    <- the P1 in full. READ IT WHOLE; it is the best worked example
                                 of this project's defining hazard in the tree.
    REVIEW_R13_R3_M4.md       <- the round on the FIX. Its F-R3-1 is your task 1.
    MEASUREMENT_INC5B_SCOPE.md <- task 2, already scoped and route-proved
    probes/r13r2/ · probes/5b/
docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-24-orchestrator/
    REVIEW_R13_R1_INC5A.md    <- round 1 (the crash), for the history of the same admission
```
Then `bd prime`, `bd show test_C_libtooling-fn1q`, and the three beads this session filed:
`41g3`, `woa0`, `0fly`.

---

## 0. ⚠ WHAT IS DIFFERENT FROM LAST SESSION'S BRIEF

**Increment 5a IS LANDED AND IS CLEARED.** `84ba04ab`, round 2 `BLOCKED` → fixed → round 3
`CLEAR-WITH-ITEMS` with **0 P1**, full `ctest` 479/479. You are *not* inheriting an uncleared
increment this time. What you inherit is **the ground it was built on, unrecorded** — two P2s
against the same four-line conjunct.

⚠ **AND ONE STREAK BROKE.** On increments 3, 4 and bd `cfmv`, round 2's headline finding was a
defect in round 1's FIX — three for three, and last session's brief told you to expect a fourth.
**It was not.** Round 2's P1 was in the ORIGINAL admission (hunk 2); both halves of round 1's
fix were independently mutant-validated as load-bearing and correct. The rule that survives is
*a fix is a change and inherits the full burden of one*. The rule that did **not** survive is
*the fix is where the next defect lives*. Do not let the second one steer your search.

---

## 1. STATE

```
HEAD      077f65de   (fix 84ba04ab + sealed labreport 017)
cq-opt    fe5805a41df2e173      build/ir-pass/cq-opt
ORACLE for 5a (pre-fix history, rebuild if you need it): git a9a227e4 -> 9b9664170fb33f95
fixtures 2155 · goldens 412 · ctest 479
full ctest -j6: 479/479 in 663.85 s, load 48.9 -> 6.8
LLVM = /usr/local/opt/llvm@19/bin (NOT on PATH; `lit` is)
```
⚠ `shasum -a 256 build/ir-pass/cq-opt` before believing any decline you see by hand.
⚠ `git worktree list` shows one worktree belonging to a DEAD session
(`…/0f0bbbb6-…/scratchpad/oracle`, at 4db66534). It is not yours; `git worktree prune` it only
after checking the directory is actually gone.

---

## 2. YOUR TASKS, IN ORDER

### (1) bd `test_C_libtooling-woa0` — P2, and it is the ground the P1 stood on

M4's conjunct is a **POINT-IN-TIME** property. Its own source comment says it admits a rail φ
*"ONLY where this flatten will NOT convert it"* — true of the current region, **false of the
pipeline**. Measured on the shipping binary (`probes/` of the round-3 records):

1. an outer region is correctly refused at E6 for its interior rail φ;
2. the INNER region then claims — its φ is at its own entry, which M4 admits — and flattens,
   making that block's terminator **UNCONDITIONAL**;
3. on the next fixpoint pass the outer region's E6 loop walks only CONDITIONAL terminators, so
   it no longer sees the rail φ, claims, and `convertPhis` converts the very φ the inner
   region's already-emitted predicate tree was built from.

It lands on a loud decline today **only** because `collectCondTree` refuses the resulting
`xor`-of-select — which round 2 named *"a downstream accident, not a fence"*, verbatim, before
round 3 found this. Round 3 argues analytically it cannot produce a wrong unitary (RAUW is
value-preserving; the unsound `buildNegation` select path is intra-region only) and both
constructed instances decline — **but it did not prove it exhaustively, and an argument plus an
absence of a probe is not a proof.**

⚠ **THIS IS CLAUDE.md's L1 ONE STAGE OVER, AND THE STANDING CURE IS NOT APPLIED.** The cure is
written in the file and is a pattern, not a prediction: **RECORD the question at the site that
asks it, and RE-ASK it after the fixpoint, in BOTH entry points, declining loudly.** Do that.

### (2) Increment 5b — the route is PROVED, the predicate is UNDESIGNED

`MEASUREMENT_INC5B_SCOPE.md` has the whole thing measured. The short form:

* 5b is **TWO customers**, split by `clang -O1` on whether the user also measures the `bool`.
  The record before this session described only the second.
* **5b-i** (`b` not measured) — clang itself sinks the select into the prep block, giving an
  already-supported bare rail leaf; what remains is `phi i32 [%sel, %prep], [5, %entry]` dying
  at `declineClassicalMuxes`. **Barest subject is FIVE LINES of C.** Do this one first.
* **5b-ii** (`b` also measured) — the `i1` rail φ survives and dies at `SelectClassify.cpp`'s
  `preppedRailPhiRegionIdx == kNoParent`. Needs a new admission rung in BOTH consumers.
* **ROUTE PROVED, NOT PROPOSED** (§6): an env-gated prototype compiles 5b-i's sunk-select shape
  at exit 0 with stage 2b STRICT `2 verified, 0 violation(s), 0 unproven`, and the emitted
  stream is **entirely shipped idiom** — `cqrt_alloc_i32(5)` for the promoted incoming, the
  rail-root CNOT copy, two X-bracketed controlled copies, a proven-`|0⟩` free, and a HANDLE mux
  under a classical condition (bd `zujr`'s argument, out of a loop). No new symbol.
* ⚠ **A SECOND WALL** (§6): the barest shape promotes fine and then dies at
  `cq uncompute: tainted handle reaches an unrecognized user` — the Phase-5 spine does not
  recognise the promoted φ as a handle user. **"5b-i is one promotion" is FALSE**, and §1–§5
  alone would have supported it. Size of that work: unmeasured.
* ⚠ **THE PROMOTED VALUE MUST BE A FRESH `cqrt_alloc`, NEVER THE LITERAL 0.**
  `RailBankPromote.cpp:688` records this as a latent P1 with a retirement trigger your increment
  FIRES: *"handle `0` IS A LIVE RAIL in this runtime (`cqrt_alloc_i1(0) -> h0`)"*. It also names
  a third obligation of the same landing. Re-derive that claim; do not cite it.
* ⚠ **THE MOST IMPORTANT QUESTION 5b-i HAS TO ANSWER** (§7): the prototype turns
  `lowering_reject_classical_mux_phi_measured.ll` — the canonical decline for this guard —
  into an ACCEPT. My first reading was "it must keep declining"; **the fixture's own header
  refutes that**: its subject IS the 5b-i shape, and it declines because pre-guard this was a
  confirmed silent miscompile where `cqrt_measure_i32(%p)` measured *"handle-or-5"*. The
  promotion removes that pun at its root. So this is plausibly its RETIREMENT TRIGGER firing,
  not a boundary violation — **undetermined, and you must settle it deliberately**, by showing
  every consumer of the promoted φ reads it as a handle (the spine already does not).
* ⚠ The prototype is **deliberately far too permissive** and is a route proof, nothing more: no
  width record, no (P0) dead-φ clause, no (P4) user-rewrite proof, no re-ask after the fixpoint.
  Its blast radius shows a permissive predicate reaches deep into unrelated machinery.

### (3) bd `test_C_libtooling-0fly` — P2, same conjunct, cheaper

It over-admits exactly `{R.Merge}`, which `run()` **does** convert, held closed only by an
**unwritten** E3-derived dominance argument — L7's exact shape. Measured: the conjunct fires
22× in 18 modules and exactly one takes the `!InRegion` branch (a W6-witness scope, provably
symmetric there). No reachable customer in the corpus today — which is **not** the same as
unreachable. Write the argument down or fence it.

### (4) The W claim-witness over-decline (P2, still untouched)

The ONE-accumulator form of increment 4's own headline shape still declines at
`gate=W-witness`; the increment widened E4, not the claim witness. ⚠ A mutant that bypassed W
measured `D→A=35, stream-moves=11`, so this is **not** a side edit. Nothing in the tree can see
the residual today: every fixture and the e2e slice use the TWO-assignment form.

### (5) Worth doing at some point: bd-worthy, structural

**The tree has NEVER had a `+Asserts` `cq-opt`**, because building one aborts on **four
committed ACCEPT fixtures**, all pre-existing (round 2, P3). That is the structural reason this
whole unchecked-`cast<>` family has no gate — and this session's P1 was in that family. A
`+Asserts` build that ran in CI-equivalent would have caught it at round 1.

---

## 3. HOW TO LAND ANYTHING — not negotiable

Rule-12 red-green (the fixture FIRST, watched failing) + a mutation check in **both**
directions · **its own Rule-13 round by an agent that did not write it, and BUDGET TWO** · the
standing rolled-vs-unrolled probe with a trailing non-diagonal gate on every register the
condition reads · corpus A/B with a **null control AND a positive control** · full `ctest -j6`
reported **with its load** · a tracked fixture AND an e2e slice.

---

## 4. LESSONS THIS SESSION PAID FOR — the instrument ones are the expensive ones

1. ⚠ **A MEASUREMENT'S INPUTS ARE MUTABLE AND SOMETHING ELSE OWNS THEM.** CLAUDE.md Rule 19's
   *"never relink a binary under a running measurement"* is a SPECIAL CASE of this. Three
   instances in one session, all mine or my reviewers': a reviewer built a mutant over its own
   ORACLE baseline (caught only because a hash had been recorded); I ran two corpus sweeps over
   shared `/tmp` scratch (260 phantom movers); I renamed a worktree with `git worktree move` and
   its CMake build dir kept ABSOLUTE paths, so the sources round 3 was READING were never the
   ones COMPILED. Give every sweep its own `mktemp -d`; build every mutant into a tree whose
   NAME says what it is; record a baseline binary's sha at the moment you build it.
2. ⚠ **AN INSTRUMENT WHOSE FAILURE OUTPUT CANNOT DISTINGUISH TWO CAUSES IS NOT REPORTING, IT IS
   GUESSING.** The acceptance criterion for fixing such a guard is not *"it stops failing"* but
   *"the two failure modes say DIFFERENT things"*. This is why the new fixture pins the **gate**
   and not just the error string: the same string is printed when a later owner refuses the
   module for an unrelated reason, so a string-only pin goes green on a binary that still
   miscompiles.
3. **A predicted crash that turns out to be a silent miscompile is the worse of the two**, and
   the difference was invisible to reading. Only the `+Asserts` build and the emitted stream
   separated them.
4. **Contention causes false FAILURES, never false passes** — and I proved it on myself by
   starting `ctest` under a running sweep and manufacturing an `A→D` that a serial re-run
   cleared 3/3. Corollary worth keeping: a verdict flip is read from an EXIT CODE (corruptible
   by starvation) while a PASS is not — so a concurrent run's green rows need no re-run and its
   red rows do.
5. **Naming a FileCheck directive in prose creates one.** Paid for the THIRD time in three
   sessions, this time in the header of a fixture whose subject is a silent miscompile.
6. **Three of four boundary probes did not contain the shape their names claimed** — `-O1`
   folded or if-converted them first (bd `46oo`'s class). Check what the compiler actually
   emitted before believing a probe is a probe.
7. **Hand-written IR could not construct the P1's shape at all** — every interior-φ probe, the
   reviewer's and mine, died at `gate=W-witness` because a φ with two in-region predecessors is
   a JOIN and tends to BE the region's merge. The exhibit had to come from `clang -O1`.
   **Provenance can be load-bearing.**
8. **A correction not applied to the SOURCE is not a correction** — the increment's
   "no decline becomes silence" claim was corrected in a review record and left standing in two
   source comments. Both now carry their own refutation.
