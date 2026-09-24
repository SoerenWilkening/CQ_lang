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
match operand for operand, but each use of `undef` may read differently (pinned, mutant M4). The
at-most-once half is argued redundant. Every operand's definition dominates the compare that reads
it. So re-running a definition after a fact edge was taken sends the path back through that
dominating fact edge before the read. Re-running one after the walk's last pruned edge would
revisit a walk-reachable block, and by construction the rest of that path does not. It is kept as
a margin that can only decline, and it is unpinned (M2/M3/M11 MISSED). Its cost is an over-decline
when a guard's operand is computed inside a preceding classical cycle.

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
