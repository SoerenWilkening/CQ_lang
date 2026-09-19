# NEXT SESSION — bd `test_C_libtooling-fn1q`: round 2 on increment 5a, then 5b

Read, in this order:
```
CLAUDE.md
docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-24-orchestrator/
    NEXT_SESSION_PROMPT.md   <- this file
    MEASUREMENT_INC5A.md     <- the increment under review, and the owner ruling that drove it
    REVIEW_R13_R1_INC5A.md   <- round 1: BLOCKED, a P1 COMPILER CRASH. Read it whole.
    MEASUREMENT_INC3.md · REVIEW_R13_R1_INC3.md · REVIEW_R13_R2_INC3.md
    MEASUREMENT_INC4.md · REVIEW_R13_R1_INC4.md · REVIEW_R13_R2_INC4.md
    probes/inc3/ · probes/inc4/ (incl. injection_matrix.sh)
```
Then `bd prime`, `bd show test_C_libtooling-fn1q`, and the four beads filed this session.

---

## 0. ⚠ THE ONE THING THAT MATTERS MOST

**INCREMENT 5a HAS HAD ONE RULE-13 ROUND, AND THAT ROUND RETURNED `BLOCKED` WITH A P1
COMPILER CRASH (SIGSEGV, exit 139, reachable from plain C at the `-O1` floor). The P1 is
fixed. ROUND 2 HAS NOT RUN. THAT IS YOUR FIRST TASK.**

Do not treat 5a as landed. On **every** increment this session — 3, 4 and bd `cfmv` —
**round 2's headline finding was a defect in round 1's FIX, not in the original change**:

| increment | round 1 | round 2 |
|---|---|---|
| 3 (E2 in-loop) | 0 P1; falsified 5 shipped-source premises | 0 P1; **round 1's fixes added 2 new false mechanism claims** |
| 4 (E4 classical table) | **BLOCKED, 1 P1** (a wrong accept) | 0 P1; **round 1's fix was structurally vacuous inside a loop** |
| 5a (rail φ) | **BLOCKED, 1 P1** (a crash) | **NOT RUN** |

The operative rule, and it is now in three commit messages: **A FIX IS A CHANGE AND
INHERITS THE FULL BURDEN OF ONE.**

---

## 1. STATE

```
HEAD            <FILL: git log --oneline -1>
cq-opt          5fd7183282ee0d380265c10a9bf01a6c7cdaba212dced7ecf82c286c27ab5b61
ORACLE (4db66534, pre-session)
                a0e31e0316496f71a6843cf8c31aebb81bcfbdc6fea162b5d34c0d32cc4d000b
                built at .../scratchpad/oracle/build/ir-pass/cq-opt — REBUILD IT, the
                scratchpad is session-scoped and will be gone.
fixtures 2154 · goldens 412 · ctest 479
LLVM = /usr/local/opt/llvm@19/bin (NOT on PATH; `lit` is)
```
⚠ `shasum -a 256 build/ir-pass/cq-opt` before believing any decline you see by hand. A
stale binary has cost this project a session before.

**LANDED THIS SESSION** (all with two Rule-13 rounds):
* `76d2949b` increment 3 — PredMux E2 admits a region STRICTLY INSIDE one loop body.
* `6df6f906` increment 4 — E4 admits a PROOF-GATED classical const-table read.
* `a9a227e4` bd `cfmv` — guard PredMux's SECOND eraser (a vanishing user gate).

**UNCOMMITTED / COMMITTED-BUT-UNCLEARED: increment 5a** — the rail φ at E6.

## 2. ⚠⚠ THE HEADLINE: THE OWNER'S PROGRAM COMPILES

`example/grover/grover_oracle_uncompute.c`, verbatim, `bool b0[n]`, no workaround:
```
opt exit 0 · stderr 0 BYTES · 128 lowered lines · loop still ROLLED
stage 2b STRICT  3 verified, 0 violation(s), 0 unproven
run              88 trace lines
K-INDEPENDENT    117 lowered lines at n = 3, 8, 64, 1000
```
At session start it sat behind THREE PredMux gates (E2-cycle, E4-gep, E6-condtree).

⚠ **IT IS NOW A TRACKED CTEST ENTRY** — `e2e-slice-grover-oracle-uncompute`, with a
committed 88-line golden. bd `5zwz` records that `example/` is excluded via
`.git/info/exclude`, so until now **NO GATE HAD EVER COMPILED IT**, which is how it came
to be reported three times as "the script fails again" while no suite could see it. **If
that test goes red, the owner's file has stopped compiling.** Treat it as the most
important regression signal in the tree.

⚠ A round-1 reviewer walked all 88 trace lines analytically and found the circuit CORRECT
(controlled prep; chain hoisted out-of-place with classical table values in the `_hl`
literal slot; two value merges; rails read ONLY as `cqrt_ry_*_controlled` targets and
`cqrt_cnot` CONTROLS, never bracketed, never freed; every leaked rail a deterministic
function of a measured register). **That is analytic, not simulated — Rule 2. There is no
simulator.**

## 3. THE OWNER RULING THAT GOVERNS THIS BEAD

> **"Does it have to be declined by physics? if not we HAVE to make it compile!!"**

⚠ **THE PRECEDING AGENT ASKED THE WRONG QUESTION AND THE OWNER CORRECTED IT.** It framed
increment 5 as *"which cost do we carry — claim-then-decline, or a pre-claim test that
over-declines?"* That PRESUPPOSES declining is on the table. For a realizable circuit it
is not. **Ask "is there a physics reason?" FIRST.** If no, the decline is compiler
structure and it is a defect (the 2026-09-11 ruling).

## 4. YOUR TASKS, IN ORDER

### (1) RULE-13 ROUND 2 ON INCREMENT 5a — an agent that did not write it

Give it `REVIEW_R13_R1_INC5A.md` and tell it to attack **what round 1 did not**. Round 1's
own "WHAT I DID NOT DO" names these, and they are your highest-value targets:

* ⚠ **The open half of the P1's severity, which round 1 could NOT settle.** It established
  the value reaching `cast<BinaryOperator>` is not a `BinaryOperator` and that the
  recursive call received NULL — but **did not bound whether a different input or
  allocator state yields a garbage `Value*` that builds a WRONG PREDICATE instead of
  crashing.** That is a P1-vs-worse question and it is still open. A `+Asserts` build of
  `cq-opt` would settle part of it; nobody has built one.
* It did NOT exercise **round-2 `repropagateControlMerges`** beyond one two-region probe.
  The L1 question — does any stage between the two detection rounds compute something over
  a premise the rail-φ admission falsifies? — **is unanswered by all five rounds this
  session.**
* It did NOT probe erasers (3) and (4) (`foldConstantConeAndBranches`' own
  `eraseFromParent`, `removeUnreachableBlocksChecked`) with a rail φ. bd `cfmv` guarded
  eraser (2) only and SAYS SO; 5a widens the population reaching them.
* It tested **only `-O1`**, and notes the C-reachability of the crash depended on a
  clang-`-O1` coupling between merge-phi incoming order and branch polarity that **Rule 9
  says must not be relied on** — and that CQ's own earlier stages (`MergePhiPeel`,
  `promoteRailBankCells`, `RegionFlatten`, the PredMux fixpoint) rewrite the CFG before
  PredMux sees it, so it is not even a pure clang property.
* It did not run the full `ctest`, the twin matrix, or `free_pairing_check_test.py`.

**Also attack the FIX itself** (this is where rounds 2 have paid every time):
`buildNegation` now takes `isCondRailLeaf(V) || isStructuralRailPhi(V)`, and the arm-swap
fold takes the same disjunction. Verify BY MUTANT that both halves are load-bearing, and
look for a THIRD consumer of the grammar that a rail φ now reaches unrecorded — round 1's
F4 warned the fix owes two halves and it was right; assume a third.

### (2) INCREMENT 5b — bd `test_C_libtooling-5b` (filed P2, an OVER-DECLINE)

A rail φ whose prep sits under a **CLASSICAL** condition still declines. **There is no
physics reason** — it is a classical branch choosing between two circuits — so by the
ruling above it is a defect. Route, with precedent: promote the constant incoming to a
`|0⟩` rail handle so the φ becomes a HANDLE mux under a classical condition, the
`RailBankPromote` idiom bd `zujr` already uses, where a `|0⟩` control correctly means
"this arm never fires". Probe:
`.../session-2026-09-23-orchestrator/probes/inc2/railphi_classical_prep.ll`.

### (3) THE OTHER BEADS FILED THIS SESSION

* **W claim witness over-decline (P2)** — the ONE-accumulator form of increment 4's own
  headline shape still declines at `gate=W-witness`. E4 was widened; the CLAIM WITNESS was
  not. ⚠ A mutant that bypassed W measured `D→A=35, stream-moves=11`, so this is NOT a
  side edit.
* **arm (1c) has ZERO fixtures (P3)** — deleting it moves 0 of 2154, yet it is the sole
  admitter of three measured shapes. Unreachable from `clang -O1` C, so a fixture would
  pin an IR-only shape. bd `e1gr`'s class.
* **5 identical-body fixture pairs (P3)** — one pair asserts OPPOSITE directions over
  byte-identical IR. Pre-existing; L8's recipe found it.

## 5. HOW TO LAND ANYTHING — not negotiable

Rule-12 red-green (decline fixture FIRST, watched failing) + a mutation check that it is
non-vacuous · **its own Rule-13 round by an agent that did not write it, and BUDGET TWO** ·
the standing rolled-vs-unrolled probe with a TRAILING non-diagonal gate on every register
the condition reads · corpus A/B **with the NULL CONTROL RUN FIRST** · a full `ctest -j6`
reported **WITH ITS LOAD** · a tracked fixture AND an e2e slice.

## 6. NINE LESSONS THIS SESSION PAID FOR — the instrument ones are the expensive ones

1. **A FIX IS A CHANGE AND INHERITS THE FULL BURDEN OF ONE.** Three for three.
2. **Ask "is there a physics reason?" before offering the owner a trade-off.**
3. **A clean corpus A/B on a WIDENING is weak evidence by construction** — a sweep only
   finds regressions in a population it already has, and the population you just admitted
   is not in it. Increment 4's P1 sat behind a 2147-fixture A/B reading four zeros.
4. **A negative cannot close a gate family the shape legitimately emits.** Use EXACT
   COUNTS. A `cqrt_ry_i1` pin missed an injected `cqrt_ry_i32`; a whole-family count
   caught it.
5. **`grep … | count 0` cannot work** — `grep` exits 1 with no match and lit fails the
   pipeline before `count` runs.
6. **Naming a FileCheck directive in prose CREATES one.** Paid again this session, in a
   note whose whole subject was vacuous directives.
7. **Run every mutation harness against a NULL CONTROL first.** Mine reported
   `NULL CONTROL = CAUGHT` from two separate bugs (LLVM not on `PATH`; a `\&\&` escaped
   into a command substitution). Every "CAUGHT" below it was meaningless.
8. **A compound shell command can manufacture a false red.** One of mine produced a 289 KB
   lit FAIL list by mis-resolving a path; re-run correctly it was green. And a round-1
   reviewer retracted a `rc=127` row that was contention **under load it had created
   itself** — it caught that only because the number was implausible.
9. **Retirement triggers work.** `control_predmux_reject_rail_phi_cond.ll`'s trigger was
   character-for-character correct about a binary that did not exist yet, including WHICH
   sibling would accept and WHY this one would not. Write them.
