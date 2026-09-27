# Rule-13 round r3B — bd vsfp round 3 (`671390fe`): re-propagation, `declineStaleTaintSet`, the global fold's arm fold

**Verdict: NOT-CLEAR.** One P1 (a compiler crash, reachable from C, on a program the oracle compiles), one P3.

| binary | `cq-opt` sha-256[:16] | location |
|---|---|---|
| SUBJECT (round 3) | `3cb890ef25187b4b` | `<worktree>/build/ir-pass/cq-opt` (hash re-checked before the crash runs) |
| ROUND 2 | `d17c95e8353711b1` | `scratchpad/vsfp/bin/cq-opt.r2g` |
| ORACLE `main` `aee8f4f8` | `69250feaf68bbe49` | `scratchpad/vsfp/bin/cq-opt.base` (same hash as `frozen/cq-opt.main_aee8`) |

Scope, per the owner's efficiency request: no corpus sweeps, no allocator sweeps, no mutation matrix, and no private build.
The UAF witness is macOS Guard Malloc (`DYLD_INSERT_LIBRARIES=/usr/lib/libgmalloc.dylib`) on the shipped binaries.
The probes are in `probes/src/`, the runner is `probes/run.sh`, and the verdict table, trace identities and Guard Malloc rows are in `probes/results/verdicts.txt`.

---

## F-XB-1 — P1, INTRODUCED (bd vsfp; round 2 created it, round 3 widened it): `deleteDeadCones` reads a freed φ, and `cq-opt` segfaults (bd `test_C_libtooling-1xp9`)

**Mechanism.** Step 4 of `deleteDeadCones` (`DeadValueLiveness.cpp`) folds each empty-arm branch in one loop. For every fold it pushes the branch condition into `CondSeeds`, a `SmallVector<Value *>` of raw pointers. Only after the loop does it call `MergeBlockIntoPredecessor(S)` for every merge. It then recurses on `CondSeeds`.

Take two cascaded diamonds where the second branch's condition is an `i1` φ living in the first diamond's merge `S1`:
1. Fold 1 leaves that φ single-entry.
2. `MergeBlockIntoPredecessor(S1)` runs `FoldSingleEntryPHINodes`, which RAUWs the φ and **erases** it.
3. The recursive `deleteDeadCones(F, CondSeeds)` then calls `visit(<freed φ>)`, which does `dyn_cast<Instruction>` and `I->getFunction()` on freed memory.

Stack on SUBJECT, plain Release: `deleteDeadCones(...)::$_0::operator()` ← `deleteDeadCones` ← `deleteDeadCones` ← `foldVolatileConstGlobalLoads` / `eraseDeadVolatileScalarStores` (`probes/results/u{1,3}_subject_segv_stack.txt`).

**The C repro**, `u5.c`. It has classical conditions only, one `cq_theta` and one `cq_measure`:

```c
int m = atoi(v[1]); _Bool a = m > 5, b = m < 2; int q = cq_theta(m & 7, .5); _Bool p;
if (m > 3) { volatile int z = 1; p = a; } else { p = b; }
if (p) { volatile int w = 2; }
return cq_measure(q) + a + b;
```

`-O1` produces exactly this shape: `%15 = phi i1 [%8, %13], [%9, %2]; br i1 %15, …`. The fenv store erasure empties both arms, and that triggers the cascade.

| probe | what it adds | SUBJECT | ROUND 2 | ORACLE |
|---|---|---|---|---|
| `u5.c` | classical conditions | **SIGSEGV 139** | SIGSEGV 139 | **ACCEPT**, 3 trace lines |
| `u3.c` | tainted first condition (`q > 3`) | **SIGSEGV 139** | SIGSEGV 139 | declines (`value-arm swap-route`) |
| `u4.c` | the second merge has a φ | **SIGSEGV 139** | abort 134 (the verifier, round 2's otam `select i32 %out`) | declines |
| `u1.ll` | global-fold path: `i1` volatile global and a second merge φ | **SIGSEGV 139** | declines | declines |
| `u2.ll` | alloca-fold path, second merge has no φ | exit 0, **silent UB**; SIGSEGV 139 under Guard Malloc | exit 0; SIGSEGV 139 under Guard Malloc | declines |
| `e1T.ll` | Guard Malloc null control | exit 1, a clean decline under Guard Malloc | same | same |

**Attribution.**
- The cascade exists since round 2 for a second fold with **no** merge φ, because round 2 seeded the condition only when `NewIn.empty()`.
- Round 3 makes the condition seed unconditional and gives the global fold the arm fold. That adds `u4` and `u1`, which reach the UAF only on round 3.
- Relative to `main` the defect is introduced: `DeadValueLiveness.cpp` does not exist there.
- `u5` is a **program the oracle compiles correctly that now crashes the compiler.**
- The round-2 reviews' "the empty-arm fold's CFG surgery held" is falsified.
- `MergeBlockIntoPredecessor` erases only φs, so the class is exactly "a seed that is a φ in a merged block".

**Fix direction.**
- Hold `CondSeeds` as `WeakTrackingVH`, not `WeakVH`, and skip nulls. `WeakTrackingVH` follows `FoldSingleEntryPHINodes`' RAUW to the fold's `select`. A null-skip alone drops that seed: `u5` survives only because fold 1's condition is also seeded and dead, and it would leave a dead tainted `select` alive whenever that condition is live for another reason. That dead select is a qjoc-class dirty which-path rail.
- Alternatively, run the recursion **before** the merge loop.
- Pin `u5` as an ACCEPT fixture, and pin `u2` under a UAF-detecting allocator. Release does not crash on `u2`.

---

## F-XB-2 — P3, PRE-EXISTING class, round 3 adds a customer: the L1 table re-asks only consumers BELOW the growing stages (bd `test_C_libtooling-g84t`)

§R3.7 and the header of `declineStaleTaintSet` discharge the volatile folds' taint growth with `propagate` on a true return. That repairs the set for the stages that run **after** them. Stages **before** them have already consumed the old set, and nothing re-asks them:

- **`foldIdentityBitcasts`.** It folds only *tainted* identity bitcasts. Its own comment names this exact hazard ("a bitcast a LATER stage makes tainted would be left standing"), and the only backstop is `adjudicateTaintDelta` CALL 1, after the peel.
- **`lowerByRefInline`.** Its `underTaintedControl` and `AnyTaintedUsed` checks read the old set.
- **The rail-bank promoter and `markRailBankAllocas`.**

The global fold's arm fold (round 3), the alloca fold and store erasure (round 2), slot B, zco4 and PredMux all grow taint after these stages.

This is the blind spot the implementer asked for: `declineStaleTaintSet` cannot see a set that later stages have already re-propagated.

**The measured consequence is LOUD.** `e1.ll` is a global-fold `select` read through `bitcast i32 → i32` after a chained Ry.
- It declines with `no template for opcode 'bitcast i32' in tainted context`.
- Its select-form twin `e1T.ll` declines at the stale-reader fence.
- This is IR-only: `-O1` never leaves an identity int bitcast.

The by-ref inliner's stale read proved harmless: inlining is the same semantics either way. The C route to it (`d1.c`) is blocked by bd `50ho`.

No silent consequence was constructed. The ask is to state, in R3.7 or the header, which upstream consumers are safe on a stale-classical answer and why, or to re-run `foldIdentityBitcasts` at the end of the window.

---

## Attacked and held

**1. Re-propagation completeness.**
- I enumerated the window in both entry points: slot A, the by-ref inliner, the rail-bank promoter and mint, `foldIdentityBitcasts`, the global fold, the alloca fold, the store erasure, zco4, slot B, fp80, PredMux, unroll, ctlz and the rail-φ re-ask.
- Every IR-changing stage now re-propagates on a true return. `Changed` is set whenever `deleteDeadCones` is reached.
- Inside a stage, only membership lists and alloca/load taint are read after a fold, and a fold cannot change either.
- The per-stage `taint = propagate` wipes no side-table records. No stage in the window writes one, and `foldIdentityBitcasts` only erases from `Tainted`.

**2. `declineStaleTaintSet`.**
- It compares both directions.
- The set's iteration skips dead keys (`ScrubOnDelete` `const_iterator::skip`), so no null key can end the second loop early.
- Nothing in the window inserts into `Tainted` except `propagate`. The 8e5r containers, `ControlOwnedRails`, `HandleWidth`, the IO-sink rail, `liftOneRegisterMergePhi` and 9bhg's provisional taint are all written later. 9bhg changes `propagateWorklist` itself, so both sides of the comparison move together.
- `propagate` emits only `DS_Error`s, so the extra call duplicates no warning.
- It is placed right before `detectSpecializations`, ahead of every guard, in both entry points.

**3. The fold on tainted branches.**
- An arm must be literally empty apart from debug intrinsics, so the fold never fires with a `cq_phi` in an arm.
- `cq_phi` is a liveness root, by membership and by the reserved prefix. `CQ.h` gives it no attributes, and a body that calls it is never "pure".
- A φ becomes `select Cond, v(E0), v(E1)` with the correct polarity, in the triangle case and in both orderings.
- The fold rejects: `B0 == B1` (`getSinglePredecessor` counts edges), self-loops, an arm back to P, a loop header with a third predecessor (`OnlyOurs`), a switch, and a three-predecessor merge (`c4`, where SUBJECT = ORACLE).
- Cascaded folds that empty P itself are handled correctly. P is empty only if no select was placed in it.
- **Twins run on SUBJECT, TRACE-IDENT:**
  - `a1`: the condition is also measured.
  - `a2`: the condition also drives a `cq_phi` branch.
  - `b1`: in a loop.
  - `b2`: an fp φ feeding an Ry angle, lowered through `AngleSelectEmit`.
  - `b4`: an equal-incoming fp φ feeding `cq_phi`, which becomes a global phase and is deleted, as in the twin.
  - `c1`: the tainted latch condition folds to a constant.
- **The same decline on both sides:** `a3`/`a3T` (different strings), `b3`, `c2`, `d1`.
- **Over-declines against the twin, pre-existing and identical on the oracle:** `b5` (bd `50ho`: the `trunc` of the folded load is left behind) and `c3` (switch).
- The accepted `eqphi` and T-twin streams (`k1T`–`k5T`) are the no-branch program. Under the premise that a volatile read of an internal, never-stored, never-escaped global is unobservable, that premise is the whole content of the change. See the note below.

**4. Condition deletion.** Liveness is recomputed at the recursive call. A condition read by a live select, a `cq_measure`, a `cq_theta` operand, `llvm.assume`, a store or a `ret` is a root, or is read by a live instruction, and stays. A condition read only by dead instructions takes them with it through the forward closure. `a1` and `a2` confirm this. The one defect in this step is F-XB-1.

**Note for the owner (not a finding).** The global fold's licence reads *"fenv is out of scope project-wide"*. The owner's fenv ruling says *"a volatile access to a non-escaping function-LOCAL object"*. Round 3 now lets the global fold decide tainted-branch verdicts: `if (q > 3) (void)K;` accepts by deletion where it used to decline. That rests on the internal-global extension of the ruling, which CLAUDE.md says the owner re-affirmed knowing about the two stages involved.

## What I did NOT attack

- `resolvePhantomCloneArgReads` and `userProgramReads` (the other reviewer's scope).
- The drop's slot A/B and the zco4 route to F-XB-1. The same `deleteDeadCones` step is reached from every caller, but I built repros only through the store erasure, the alloca fold and the global fold.
- Any corpus, allocator or mutation sweep, and any full lit/ctest run.
- Whether the Release-silent UAF (`u2`) can ever delete a live instruction. It deletes only what its fresh liveness calls dead, but a reused address is UB, not a proof.
- The 9bhg composition.
- `runOnFunction`, which has zero callers.
- Multi-TU spellings of F-XB-1.

## L10 note on my own instrument

The first spelling of the Guard Malloc block in `verdicts.txt` printed `rc=0` for all three binaries. It read `$?` after a `$(basename …)` command substitution in the same `echo`. The stack-trace grep in the same row contradicted it, which is how I caught it. The block was re-measured with `rc` captured on its own line, and the record keeps a note of the miss.
