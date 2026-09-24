# Track A — bd `test_C_libtooling-xdu2.10` (P2 over-decline): C6's read order, asked semantically

Session 2026-09-24 railbank-parallel. Worktree branch `worktree-agent-ad7529377cdc1d2dc`,
based on `d0720cb1`. **Not Rule-13 reviewed yet** — this is the implementer's record.

## The defect (measured)

`int b[n]; for (i<n) b[i] = cq_theta(b[i], .5); for (i<n) s += cq_measure(b[i]);` with no
explicit `if (n <= 0) return` declined with `cq rail bank: array has cells no iteration writes`.
At `clang -O1` each loop gets its **own** `icmp sgt i32 %n, 0` guard (two distinct, identical
compares). The read guard block is reached from the write guard's FALSE edge and from the write
loop's exit, so the write-loop header does not dominate the read. C6 in
`railBankCarveVerdictImpl` asked `DT.dominates(L->getHeader(), LD->getParent())`, a syntactic
answer to a semantic question (L5).

## The change

`ir-pass/src/QramLowering.cpp`, carve/C6 only (Track C's `classicalRuntimeAllocaReadIsInBounds`
is untouched):

- `readFollowsLoopOnEveryPath(Read, L, DT, DL)` replaces the dominance test at the one C6 site.
  Dominance by the header remains its first line, as a special case.
  1. **Facts.** Every conditional-branch edge that dominates the read's block
     (`DT.dominates(BasicBlockEdge, RB)`) gives a `(condition, polarity)` fact that holds whenever
     the read executes.
  2. **Pruned walk.** A forward CFG walk from the entry block that never enters `L`'s header. It
     drops an edge whose condition at that polarity implies the **negation** of a fact
     (`isImpliedCondition`, LLVM's own machinery). Every other edge is followed, including all
     `switch` edges and any condition that fails the closure test.
  3. If the read's block is not reached, every feasible path to the read passes the header.
     The caller has already proven one exiting block (the latch) and an exact BTC, so passing the
     header and then leaving `L` is a complete activation. The old dominance test licensed exactly
     this conclusion and no more.
- `singleValuedClosure(V)` is the closure test. It refuses a condition whose operand closure
  reaches `undef`/`poison`, or an instruction that a CFG cycle re-executes, or has more than 64
  values.
- The C6 comments were corrected in the same change (L7): the call site, the "(ii) after the
  loop" block (which now also says VISITED, with written being C7(b)'s), and the `QramLowering.h`
  C6 clause.

What it does NOT change: the per-read SCEV trip-equality clause, C7(b) totality-per-trip, the
exits-reach-header / `returns_twice` / lifetime / stackrestore / literal-cell fences (the four
xdu2.4 P3 fences are untouched and were not weakened).

## Why it is sound, and the one conjunct that is argued rather than pinned

The walk over-approximates the feasible paths, so "reached" means decline. It cannot turn a read
that a real path reaches around `L` into an accept, as long as each pruned edge is really
infeasible together with the facts. An edge is pruned only when its condition, as an SSA-level
fact, implies ¬fact. The `undef` half of the closure test is load-bearing: two `icmp ne undef, 0`
match operand for operand, but each use of `undef` may read differently (pinned, mutant M4).

### The at-most-once half ("at-most-once" — corrected after Rule-13 round 1, P3-3)

⚠ **The first version of this paragraph was flawed and is withdrawn.** It argued that re-running a
definition "after the walk's last pruned edge would revisit a walk-reachable block". The source of
the LAST pruned edge on a path need not be walk-reachable (the walk stops at the first pruned edge),
so that step did not hold. The corrected argument, as the reviewer framed it (argued, not
machine-checked):

Let π be an execution from entry to the read that never passes `L`'s header. Let `X` be the set of
definitions in the closures of the fact `F` and of the pruned-edge conditions, and let τ be the
point on π just after the last re-execution of any member of `X`.
1. **F is re-evaluated after τ, with the final values.** Take the prefix of π up to the first
   execution of the member of `X` that was re-executed last. It executes no `F` compare, because
   that definition dominates `F`'s compare. Splice it onto π's suffix after τ. The result is a CFG
   path from entry to the read, so it takes the dominating fact edge, and that edge lies in the
   suffix. So `F` is evaluated after τ, reads the final values, and holds with the fact's polarity
   when the read executes.
2. **The first pruned edge after τ refutes that.** π's suffix after τ still starts inside the walk's
   reachable set, or the spliced path would contradict "the walk never reached the read". The walk
   set is closed under unpruned edges and excludes the header, so the suffix leaves it through a
   pruned edge `B→S`. Take the FIRST such edge. Its source `B` is walk-reachable, and its condition
   `C_B` reads only final values, because no member of `X` re-executes after τ. So
   `C_B ⇒ ¬F` holds for these same values, which contradicts step 1.

So no stale name can separate the two compares, and the SSA-level implication applies. Only the
`undef` hazard remains. The at-most-once check is therefore kept as a margin that can only decline.
It is unpinned (M2/M3/M11/M17 MISSED by construction). Its cost is an over-decline when a guard's
operand is computed inside a preceding classical cycle. ⚠ Step 2's "starts inside the walk set"
sub-step is the least mechanical part of the argument, and a round-2 reviewer should attack it.

## Red → green (measured)

Oracle = this worktree's `cq-opt` rebuilt from unmodified `d0720cb1` source, sha256 `c6f61f80…`.
Subject sha256 `2b7c4779…` (post comment edits).

| C matrix `railbank_readorder_matrix.c` row | oracle | subject |
|---|---|---|
| 1 unguarded `int b[n]` (bead exhibit), twin-rolled | DECLINE C6 | **ACCEPT** `[Bank]` |
| 2 `if (n<=0 \|\| m<=0) return;` | ACCEPT | ACCEPT (row predates; `-O1` emits no per-loop guard here) |
| 3 unguarded + 22 diamonds between the loops (large body) | DECLINE C6 | **ACCEPT** |
| 4 hand-unrolled n=3 twin of row 1 | ACCEPT | ACCEPT, rolled trace **byte-identical** (argv `a b`, 0 dropped lines) |
| 5 read bound `n-1` (copy of shared row 3) | DECLINE C6 | DECLINE C6 |
| 6 partial write (copy of shared row 4) | DECLINE C6 | DECLINE `tainted value muxed by a classical-condition phi` — **see below** |
| 7 early exit | DECLINE C6 | DECLINE C6 |
| 8 write under unrelated `k` | DECLINE C6 | DECLINE C6 |
| 9 write guard `n>2`, read guard `n>0` (guard-false path reaches a read) | DECLINE C6 | DECLINE C6 |
| 10 read bound `m` ≠ extent `n` | DECLINE C6 | DECLINE C6 |
| 11 read under `n > 1` (implies, not equals, the write guard) | DECLINE C6 | **ACCEPT** |
| 12 early return on `m` only | DECLINE C6 | **ACCEPT** |
| 13 explicit `goto` around the write when `n<=0` | DECLINE C6 | **ACCEPT** |
| 14 read bound `(unsigned)n` (guard `n != 0` not refuted by `n <= 0`) | DECLINE C6 | DECLINE C6 |

Runner summary on the subject: `railbank_readorder_matrix: 14 case(s): 7 accept, 7 decline; 1
twin(s); 0 failure(s)`. On the oracle: `7 failure(s)` (rows 1, 3, 6, 11, 12, 13 and the twin link).
Stage 2b on rows 1/3/11: `1 rail mint(s) of which 1 left allocated … 0 violation(s), 0 unproven`
(the bank rail is frozen, which is correct).

**Row 6 moved strings, and that is intended.** A partial write is the promoter's (C7) business,
not C6's. Its explicit-guard twin (`if (n<=0) return;` + the same partial write) already gives
`[Bank]` and then `cq taint escape: tainted value muxed by a classical-condition phi` on the
**oracle**. The unguarded form now reaches the same wall. The shared matrix's row 4 still
declines C6, but for a different reason: `n = argc + 2` has no `nsw`, so the write loop's
`smax(n,1)` trip count cannot be proven equal to the extent. It is not the read order.

**Shared matrix `railbank_dynamic_matrix.c`, all 27 rows, probed by hand (not its ctest):
0 verdict moves, 0 string moves between oracle and subject.** Rows 3, 4 and 12 are unchanged.
Nothing in that file or its sidecar was edited.

Extra adversarial C probes, which are not in the matrix: read under `if (flag)` gives ACCEPT. A
classical diamond between the loops gives ACCEPT. A straight-line `b[0]` read after the read loop
gives DECLINE C6, a pre-existing restriction: runtime-bank reads must be exact loop walks.

## Owned tests (quoted)

- `lit ir-pass/test --filter 'railbank_readorder|lowering_reject_railbank_dynamic'`: `Passed : 12`
  (6 new: 1 accept, 5 declines; 6 pre-existing `lowering_reject_railbank_dynamic_*`).
- `ctest -R '^e2e-slice-railbank-dynamic-int$|^e2e-railbank-readorder-matrix$'`: `100% tests
  passed, 0 tests failed out of 2`.
- `railbank_readorder_accept_unguarded.ll` is RED on the oracle (`array has cells no iteration
  writes`, rc=1). On the oracle the five decline fixtures are green, but only by the old
  over-decline. Their value is the mutation column.

## Mutation matrix (owned tests only, null control first; denominator 12 lit + 12-row matrix at the time)

| mutant | verdict | killed by |
|---|---|---|
| M0 null (`(void)0;`) | not detected (correct) | — |
| M1 `return true` after the dominance line | DETECTED | 5 lit declines + matrix 8, 9 |
| M2 drop closure test on walk edges | **MISSED** | argued redundant (above) |
| M3 drop closure test on facts | **MISSED** | argued redundant |
| M4 drop `undef` refusal | DETECTED | `…_reject_undef_condition.ll` |
| M5 walk enters the header | DETECTED | accept fixture + matrix 1, 3, 6, 11, 12 |
| M6 prune on any implication | DETECTED | 4 lit + matrix 8, 9 |
| M7 facts from non-dominating edges | DETECTED | 5 lit + matrix 8, 9 |
| M8 fact polarity flipped | DETECTED | 4 lit + matrix 8, 9 |
| M9 empty fact set ⇒ accept | DETECTED | `…_reject_no_fact.ll` |
| M10 edge polarity flipped | DETECTED | 4 lit + matrix 8, 9 |
| M11 drop the in-cycle half of the closure | **MISSED** | argued redundant |
| M12 drop the closure budget | **MISSED** | termination/cost guard only (closure is finite with the visited set) |
| M13 drop walk's same-successor guard | **MISSED** | equivalent mutant: pruning both edges of `br c, S, S` needs contradictory facts, so the read would be unreachable anyway |
| M14 "reached" ⇒ continue | DETECTED | 4 lit + matrix 8, 9 |

15 mutants: 1 null, 9 DETECTED, 5 MISSED (each with its reason). Harness:
`scratchpad/mutate.py` (session-local). It rebuilt both targets for every mutant and restored the
source afterwards; the git diff was checked afterwards.

## Rule-13 round 1 (CLEAR-WITH-ITEMS, 0 P1, 0 P2): the P3 fixes

- **P3-1 (perf, L7): the first spelling was QUADRATIC.** `singleValuedClosure` called the
  per-instruction reachability walk `instReaches(I, I)` for every closure value of every walked
  branch and every dominator. The reviewer measured 0.27 s / 0.84 s / 7.72 s at 250 / 1000 / 3000
  diamonds between the loops, against about 0.2 s on the oracle.
  - **Fix:** `ReadOrderCtx` computes the in-cycle block set ONCE per query, from `scc_iterator`
    (`hasCycle()`). It also marks unreached blocks, and memoises the closure verdict per condition.
    Edge dominance is asked before the closure, so dominators whose edges do not dominate the read
    (every diamond head) cost no closure walk.
  - **Measured on a loaded box, min of 3:** perf_3000 is 2.66 s with the predicate and 2.21 s with
    the predicate short-circuited to `return true` (a temporary mutant build, restored). The rest of
    that ~2.2 s is the downstream lowering of the ACCEPTED module. The oracle declines it, which is
    why it takes about 0.6 s there, so oracle time is not the comparable baseline.
  - No timing test was added. The complexity note on `ReadOrderCtx` is the only guard. The false
    comment "linear in the edges" in matrix row 3 is corrected.
  - **Side finding, pre-existing and not read order:** perf_3000 with an explicit
    `if (n <= 0) return 0;` DECLINES `array has cells no iteration writes` on BOTH the oracle and
    the subject, with no read-order anchor. So another C6 sub-clause fires, most likely the
    read-loop SCEV trip equality, whose guard sits 3000 blocks away. Not investigated; it should be
    filed.
- **P3-2 (L7):** step (3) of the header no longer says "(the latch)". C6 proves a SINGLE exiting
  block and an exact BTC. That the exiting block IS the latch is C7(b)'s `WriteIsTotalPerTrip`,
  which the comment now cites, and read order does not depend on it.
- **P3-3:** the at-most-once argument is corrected, in the section above and in the
  `singleValuedClosure` header. The check is kept.
- **P3-4 (fixture hygiene):** a `CQ_CTRL_DBG: railbank C6 read-order refused: <load>` anchor is added
  at the read-order decline. It uses the same env lever the carve's caller uses for
  `railbank [Bank]`, and is byte-neutral when unset.
  - All 5 `railbank_readorder_reject_*` fixtures CHECK the anchor before the shared string. The
    accept fixture adds `--implicit-check-not='C6 read-order refused'`.
  - Verified non-vacuous: the anchor appears 3× per fixture on the subject (the carve is asked 3×)
    and 0× on the oracle, where FileCheck fails.
  - ⚠ **L10, instance in this track:** my first run of that check reported `filecheck_rc=0` on the
    ORACLE too. The `$?` came after a `$(basename …)` substitution, so it was basename's status. The
    fix captured `rc` immediately, and after it the oracle correctly shows `rc=1`.
  - **Matrix rows**, using the anchor (each row's `pins` field in the sidecar, which the runner
    ignores):
    - 8, 9, 14 pin READ ORDER alone.
    - 10 is read order AND the SCEV trip clause (`m ≠ n`), doubly fenced, which is why M1 left it
      declining.
    - 5 is the SCEV trip clause (`n-1`); the read-order walk is never reached.
    - 7 is the early-exit write loop failing single-exiting-block/exact-BTC before any read is
      asked.
    - 6 is the promoter/C7 partial-write wall.
- **P3-5, not-reached over-declines, recorded, no code:**
  - `a21` (reviewer `rt/a21_writeread_mid.c`): write under `k > 0`, read under `k > 1`, fused by
    `-O1` into an `and i1`-style guard. The walk does not prune it; `isImpliedCondition` on that
    guard shape was not reached.
  - `a07` (`rt/a07_k_range.c`): write under `k > 3`, read under `k >= 5 && k < 9`, which `-O1`
    turns into an unsigned range check (`add` + `icmp ult`). `isImpliedCondition` does not relate
    the range check to `k > 3`.
  - Both are valid programs the walk declines. Both are over-declines, not hazards.

### Round-1 mutation matrix (owned tests only; denominator 12 lit + 14-row matrix + 1 twin)

19 mutants. The M0 null was MISSED (correct). 10 DETECTED, 8 MISSED, each with a reason:

| mutant | verdict | killed by / reason |
|---|---|---|
| M0 null | MISSED (correct) | — |
| M1 `return true` | DETECTED | 5 lit declines + matrix rows |
| M2 walk-edge closure dropped | MISSED | at-most-once half is argued redundant (§ above) |
| M3 fact closure dropped | MISSED | same |
| M4 `undef` refusal dropped | DETECTED | `…_reject_undef_condition.ll` |
| M5 walk enters header | DETECTED | accept fixture + matrix 1, 3, 6, 11, 12, 13 |
| M6 prune on any implication | DETECTED | 4 lit |
| M7 facts from non-dominating edges | DETECTED | 5 lit |
| M8 fact polarity | DETECTED | 4 lit |
| M9 empty facts ⇒ accept | DETECTED | `…_reject_no_fact.ll` |
| M10 edge polarity | DETECTED | 4 lit |
| M11 in-cycle test dropped | MISSED | same as M2 |
| M12 closure budget dropped | MISSED | cost guard only; the closure is finite with the visited set |
| M13 same-successor guard | MISSED | equivalent mutant |
| M14 "reached" ⇒ continue | DETECTED | 4 lit |
| **M15 memo hit ⇒ `true`** (new) | MISSED | Shadowed. A second query of one condition happens only when a dominating branch whose closure was REFUSED is also walked. To matter, its undef-carrying condition must `isImpliedCondition`-refute a different, single-valued fact. No such pair was constructed, and each fixture's refused condition relates to nothing |
| **M16 unreached-block def** (new) | MISSED | Only more conservative. A def in an unreachable block never executes, so no value from it flows |
| **M17 SCC never marks cycles** (new) | MISSED | equivalent to M11 |
| **M18 anchor dropped** (new) | DETECTED | all 5 decline fixtures (the P3-4 pin working as intended) |

Harness: `scratchpad/trackA/mutateA.py` (its own copy; the shared `scratchpad/mutate.py` was
overwritten by another track mid-session). It rebuilt both targets per mutant and restored the
source afterwards. The owned tests were re-run green on the restored binary, cq-opt sha256
`711b4fb1…`.

## Rule-13 round 2 (CLEAR-WITH-ITEMS): F-1 (P2) fixed, F-2 folded in

**F-1 (P2): the walk never looked at taint.** A branch on a TAINTED condition is FLATTENED by
control lowering. Both of its successors execute, and a value arm's chain, loads included, is
HOISTED into the predecessor. So a tainted "dominating edge" says nothing about whether the read
executes. The reviewer's reproducer (`reviewA_r2/q06_tvalue.c`) is
`if ((k > 0) & c) x = ((x + b[k&1]) * 3) ^ 5;`, with `c = cq_theta_i1`.
- `-O1` gives `br (and i1 %pos, %c)`, which implies `k > 0` and refuted the write guard's false
  edge. The carve printed `railbank [Bank]` and minted the record. The module then declined only at
  the D5 wall (`unsupported reader of a rail-bank cell`).
- So the decline was CONTINGENT: any D5 widening would have made it a P1 over-accept. The oracle
  had declined at C6.

**Fix, two conjuncts, both decline-direction:**
1. `singleValuedClosure` (now "classical single-valued") refuses any closure value that is in
   `taint.Tainted`. So a tainted condition is never a fact and never prunes an edge; its edges are
   FOLLOWED.
2. At the C6 call site, a read that `instUnderTaintedControl` flagged gets no semantic path, only
   header dominance. That existing 7.5 predicate is CALLED rather than re-derived (Rule 14).
   ⚠ **CORRECTED in round 3 (F-3, L7):** this said "control-dependent", but that predicate tests
   "dominated by a tainted branch AND does not post-dominate it", which is neither control
   dependence nor region membership. Round 3 replaced it at this call site with
   `readInsideTaintedRegion`; see below. This covers a CLASSICAL fact nested inside a
   tainted arm, where PredMux may predicate the inner classical branch too and speculate the load.

**Round-2 re-ask (L1), stated:** the carve's taint is the set it is handed. Growth after round 1 is
re-adjudicated by `adjudicateTaintDelta` → `declineTaintEscapes`, which re-runs the carve over every
tainted store with the GROWN set. This happens once inside `repropagateControlMerges` (after
`detectAndLowerOnwardControl`) and once per `MergePhiPeel` delta. At the round-2 point any tainted
region that round lowered is already flattened, so its branch no longer exists as a fact source.

**The function header's false claim is corrected.** The old wording was "taken on every path to the
read, so its condition has that edge's polarity whenever the read executes". It now reads as true
only of CLASSICAL control. A new step (0) states the premise (an execution path is an IR CFG path)
and its scope.

**Red → green, three decline fixtures.** The final verdict is a decline on both binaries, so each
fixture pins the difference through the debug trace: the read-order anchor must fire, and
`--implicit-check-not='railbank [Bank]'` must hold.
- `railbank_readorder_reject_tainted_fact.ll`: q06 verbatim. It also has
  `--implicit-check-not` on the D5 string. RED on the pre-fix binary, which gave D5, no anchor,
  and `[Bank]`. GREEN after.
- `railbank_readorder_reject_tainted_prune.ll`: hand IR in which the tainted branch does NOT
  dominate the read, so only conjunct 1 separates the binaries. RED on the pre-fix binary: `[Bank]`,
  then `control flow under quantum control`. GREEN after.
- `railbank_readorder_reject_classical_fact_under_tainted_arm.ll`: hand IR with the classical `k > 0`
  branch nested inside the tainted arm; `-O1` fuses the C spelling into the q06 shape. Only
  conjunct 2 separates the binaries (see the mutation rows).

**F-2 folded in (the reviewer's simplification of the at-most-once argument).** Given the
at-most-once check, step 1's "suffix after τ" machinery is unnecessary. Every name in every kept
condition is single-valued. So induct on the FIRST pruned edge on ANY header-avoiding path: its
source is walk-reachable, and both compares read the unique values of their names, so the
SSA-level implication applies directly.
- ⚠ **The hidden premise, now stated in the source (step (0)): an execution path IS an IR CFG
  path.** That is exactly what taint flattening breaks, and F-1 is that premise failing. The
  "argued redundant" status of the at-most-once half in the section above therefore holds only
  together with the taint conjuncts.

### Round-2 mutation matrix (owned tests only; denominator 15 lit + 14-row matrix + 1 twin)

21 mutants: 13 DETECTED, 8 MISSED; the M0 null was MISSED (correct). Deltas against round 1:
- **M2 (walk-edge closure dropped) MISSED → DETECTED** by `…_reject_tainted_prune.ll`. That
  closure now carries the taint conjunct.
- **M19 (new: closure taint check dropped) DETECTED**, by `…_reject_tainted_prune.ll` only.
- **M20 (new: the read-side conjunct, then `instUnderTaintedControl`, dropped) DETECTED**, by
  `…_reject_classical_fact_under_tainted_arm.ll` only.
- M1, M6, M7, M8, M10, M14 and M18 now also fail the new fixtures (for example M1 is 6/15 lit).
- ⚠ **`…_reject_tainted_fact.ll` (q06) is DOUBLY fenced.** Neither M19 alone nor M20 alone turns
  it red, because each conjunct catches it by itself (its only refuting fact is tainted, and its
  read is under tainted control). It pins the COMBINED fix, not one conjunct. The two hand-IR
  fixtures are what pin each conjunct individually.
- **Still MISSED:** M3 (the fact closure; the fact-side taint check is shadowed by the read-side
  conjunct), M11, M12, M13, M15, M16, M17. Their reasons are unchanged from round 1. On M3: a
  tainted edge that dominates the read puts the read in that branch's region (reachable from it
  before its merge), unless the read post-dominates that branch. With edge dominance, that is possible only if the other successor
  loops back, and no such shape was constructed.

Final cq-opt sha256 `28d1a2c5…`. Owned tests on it: lit filter `Passed : 15`; ctest `100% tests
passed, 0 tests failed out of 2`.

## Rule-13 round 3 (CLEAR-WITH-ITEMS, 0 P1): F-1 (P2), F-2 (P3), F-3 (L7)

**F-1 (P2, an over-decline of the Grover shape).** The round-2 read-side conjunct used
`instUnderTaintedControl`, which says yes whenever a tainted branch dominates the read and the read
does not post-dominate it. A tainted `if (c) cq_phi(pi);` diamond that FULLY MERGES before an
unguarded runtime bank counts under that rule. `-O1` gives every such bank loop its own classical
guard, so the read post-dominates nothing. The reviewer's `a03.c` declined at the read-order anchor
while its explicitly guarded twin compiled, and `a06_pre.c` / `a06_mid.c` (fixed bank) behaved the
same way.
- **Fix, at the CARVE only** (the shared 7.5 predicate is unchanged; its callers ask a different
  question): `readInsideTaintedRegion`. It asks whether the read is reachable from some dominating
  tainted `br`/`switch` WITHOUT passing that branch's immediate post-dominator (its merge). A
  branch with no immediate post-dominator (a tainted early return, an abort park) has no merge, so
  everything it reaches counts as inside.
- `…_classical_fact_under_tainted_arm.ll` still declines at the anchor (its read is inside the
  arm's region). q05, q06, q07 and q08 still decline at the anchor.

**F-2 (P3, a regression against the round-1 binary).** `singleValuedClosure` walked THROUGH a
`cq_measure` call into its tainted operand, so a guard built from a measurement result was never a
fact.
- **Fix:** membership of `taint.MeasureCalls` (the one owner of "is this a measure call") makes the
  result a classical LEAF of the closure. It is still asked the at-most-once question.

**F-3 (L7):** "control-dependent" is corrected at the source (step (0) of the header, the new
helper's header, and the call site), in the three fixture headers that used it, and in this record
above. Each now names what the code tests: region membership, meaning reachable from the tainted
branch before its immediate post-dominator.

**Red → green.** All of these were RED on `928eb206` (C6 decline).
- **lit accepts (3):** `railbank_readorder_accept_merged_tainted_diamond.ll` (a03, runtime bank),
  `…_accept_fixed_merged_tainted_diamond_pre.ll` (a06_pre) and `…_accept_measured_guard.ll` (d05).
  Each checks `railbank [Bank]` in the debug trace and forbids both the read-order anchor and every
  `cq rail bank:` string.
- **matrix rows 15-20, all ACCEPT:**
  - 15: a03.
  - 16: its hand-unrolled n=2 twin.
  - 17, 18: a06_pre, a06_mid.
  - 19: d05.
  - 20: the reviewer's round-1 p12, a guard mixing a measurement and an argument.
- **New twin 15/16:** LINKED and run; the rolled trace is byte-identical to the unrolled one
  (argv `a b`).
- **Traces run by hand:**
  - a03 at n=2: `ry,rz` on `c`, two cells prepared, three measures.
  - a06_pre at k=2: three cells prepared and measured.
  - a06_pre at k<=1: no cell read.
  - d05 at argc 1 and 5: the runtime's measure returns 0, so `r=0` and neither loop runs, which is
    correct for the trace runtime.
  - Stage 2b on each: `0 violation(s), 0 unproven`.

### Round-3 mutation matrix (owned tests only; denominator 18 lit + 20-row matrix + 2 twins)

25 mutants: 16 DETECTED, 9 MISSED; the M0 null was MISSED (correct). Deltas against round 2:
- **M20 (read-side region conjunct dropped) DETECTED**, by
  `…_reject_classical_fact_under_tainted_arm.ll` only, as in round 2.
- **M22 (new: the region walk ignores the merge) DETECTED** by both merged-diamond lit accepts and
  matrix rows 15-18.
- **M23 (new: the region conjunct reverted to `instUnderTaintedControl`, i.e. the round-2 binary's
  behaviour) DETECTED** by the same accepts and rows. This is the F-1 red-green in mutant form.
- **M24 (new: measure-leaf dropped, i.e. the round-2 closure) DETECTED** by
  `…_accept_measured_guard.ll` and matrix rows 19 and 20. This is F-2's red-green.
- **M25 (new: the measure leaf skips the at-most-once check) MISSED.** This is the same argued
  margin as M11/M17: redundant under the first-pruned-edge argument, kept because it can only
  decline.
- **Unchanged MISSED:** M3, M11, M12, M13, M15, M16, M17.
- **No mutant numbered M21.** The round-2 harness had none, and the numbering was kept.

Final cq-opt sha256 `82e4c9f5…`. Owned tests on it: lit filter `Passed : 18`; ctest `100% tests
passed, 0 tests failed out of 2`.

## Rule-13 round 4 (CLEAR-WITH-ITEMS, 0 P1/P2): P3 (L7), comments and record only

The round-3 wording implied FULL coverage of tainted control. Both "a read INSIDE a tainted
branch's region" here and "a read … may be hoisted/speculated by the flatten" at the source said
so, and neither is what the code does.
- **What it actually does:** `readInsideTaintedRegion` examines only tainted branches that
  DOMINATE the read.
- **Counter-example:** a NON-dominating tainted branch in a multi-entry shape
  (`reviewA_r4/h01.ll`) is not examined. The carve answers `[Bank]` there, and the module declines
  downstream at `control flow under quantum control`.

**The real, narrower load-bearing reason is now stated at the source and here:**
1. The facts the walk relies on must remain REAL classical branches in the lowered program. A
   classical fact nested in a dominating tainted branch's region may be predicated away by the
   flatten, and that is the case this check refuses.
2. The bank's surviving readers are only what D5 (`isAdmittedRailBankReader`) admits: measure
   readers and their storage `trunc`. A `cq_measure` is never speculated or hoisted out of its
   guard.

So the check guards the fact edges, and D5 guards the readers.

**Retirement trigger (source and record):** the day D5 admits a bank reader that is not a
measurement, the region question re-opens in the same change. That covers an arithmetic consumer,
a condition, a `cq_theta` arg-0, or anything PredMux may speculate or hoist, such as its E4
classical-table read. In that change, non-dominating tainted branches must be examined, and load
speculation must be refused at C6.

Where the round-2/round-3 sections above say "inside a tainted branch's region", read "inside a
DOMINATING tainted branch's region". The sections are left as written (record history), and this
section corrects them. No code changed: the diff is comments only, and the binary was rebuilt and
the owned tests re-run.

## What I did NOT test / owed

- No full `ctest`, no full `ir-pass-lit`, no `cq-opt-equivalence`, no corpus A/B, no
  `e2e-loop-twin-matrix`, and no `e2e-railbank-dynamic-admission-matrix` ctest (not owned). That
  matrix's 27 rows were probed by hand, see above. These are the orchestrator's merge-gate items.
- `example/grover/main.c` was not compiled. It has an explicit guard, so dominance still decides
  it (first line of the new predicate) and it should be unaffected. That is to be measured at the
  merge.
- **For Track B's reviewer (xdu2.1):** the stale-reader memory hop (`OpcodeLowering.cpp`
  `railBankParkedRails` + wire walk) now sees bank reads that the write-loop header does not
  dominate. Its "gate between STORE and READ ⇒ decline" legs are reachability- and
  dominance-based. A gate on an infeasible bypass path can only add a decline, but no one has
  checked that no leg assumed the old dominance to grant an accept.
- `CODE_MAP.md` was not regenerated (shared file; line numbers in `QramLowering.cpp` shift by
  ~150). `tools/update_code_map.py` is left for the merge gate.
- The at-most-once half of `singleValuedClosure` is unpinned by construction (see above). A
  Rule-13 reviewer should attack that dominance argument directly, especially with non-LCSSA uses
  of a loop-defined value in a guard.
- Rule 13: this is a C6 core-surface change and needs ≥2 independent review rounds before merge.
