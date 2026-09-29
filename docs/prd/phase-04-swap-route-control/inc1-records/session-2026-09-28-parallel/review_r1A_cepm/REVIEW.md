# Rule-13 review r1A — bd `test_C_libtooling-cepm` + bd `test_C_libtooling-3zr4` (Surface A: the PREDICTION)

- **Subject:** branch `worktree-agent-a3c46257bc3bd028d`, commits `3a2d690e` + `7f0be42f`, diff
  `9a230646..7f0be42f`. `cq-opt` sha-256 `02522b6a4fdb8911eafe965ec6e3586370bee0f0a5df54f170738edd24af13d1`,
  `libCQPass.so` `49e7c01f5c0ba2417e287ddc…` — both verified against the brief.
- **Oracle:** `scratchpad/frozen/cq-opt.main_9a230646` (`3f6db37f5cf937b4…`, verified).
- **Private build:** worktree `scratchpad/rev_r1A_cepm` at `7f0be42f`. **Build-null control:** rebuilt `cq-opt`
  = `02522b6a…`, bit-identical to the subject. The worktree was removed after the round.
- **Time:** about 95 minutes.
- **Ran, literally:**
  - `probes/twincmp.sh` (the implementer's harness, pointed at my own probe dir) over 26 C pairs on the oracle
    and the subject: 2b STRICT, link, traces with argv `5 7` and `2 9`.
  - One hand-written IR probe (`probes/ir_fwdC.ll`).
  - Three mutants plus a null mutant, each over the implementer's 486-fixture subset (`cepm_probes/subset.py`
    and `fixrun.py`) and over my probes.
  - One composed binary (subject + bd z0re `369c61b9`) over 8 composition pairs. z0re alone
    (`8441d60d…`, the z0re worktree's `cq-opt`) was also run over those pairs.
- **Did NOT run:** the full lit suite, full ctest, corpus A/B, `cq-opt-equivalence-full`, `+Asserts`, Guard
  Malloc, `taintset-scrub-guard` (I read the implementer's 8/8; my build included `cq-scrub-selftest` but I did
  not run it). I did not build rhk5 or a composition with it. I did not build the indirect-call-seed mutant.
- **Spot-check of the implementer's sweeps:** R6 "MISSED" is reproduced (my MA: 0 of 486). Their battery
  members also reproduce: `br` ACC-SAME; `r2b`/`r2d` DECLINE `control flow`; `r2g` has the same lowered sha
  on the oracle and the subject; `z3` accepts (verdict only — I did not twin-compare it).

## Verdict: **CLEAR-WITH-ITEMS** — 0 P1, 1 P2, 3 P3

## The soundness argument, restated, and the step that is asserted

1. **The predictor over-approximates the clone.** If `predictReturnTainted(h, M)` is false, then the clone
   built with mask `M` returns a classical value.
   - `seedClone` computes the same forward closure as the predictor.
   - `scanBody` admits no store, no load other than a QROM load (a user of its tainted GEP), no recursion,
     no inline asm, and no invoke or switch.
   - The inner-call drain only scrubs.
   - `lowerCloneControl` only fires on a tainted terminator, and any tainted terminator already makes the
     predictor answer true.

   I checked each step in the source. It holds for a FIXED mask.
2. **The mask is the asserted step.** A prediction is made with the mask seen by the drain that recorded
   it, but the clone is built with `Cand.Mask` at `specialize()` time. They differ exactly when a later round
   grows the mask. Round 1b's answer has three parts:
   - the settle step taints the site in the recording drain when `LaterTaintOracle` foresees the growth;
   - the sticky rule keeps it classical when the oracle does not foresee it;
   - `specialize()`'s check declines when the replanned clone returns a register.

   That argument is total for `Pending` sites **iff** every grown sticky site is replanned. I verified that:
   the grown argument is in `reseed = UntaintedMergeRails ∪ (Tainted − beforeTaint)`, which is computed after
   the onward fixpoint. The round-1 peel path uses `adjudicateTaintDelta`'s delta instead. Probe `st2` shows
   it end to end: the mask grows `01 → 11`, the site stays sticky, the clone stays classical, and the result
   ACC-SAME with the twin, 2b STRICT clean. The oracle declines `st2` (`control flow`).
3. **What is left as argument, not measurement:** `LaterTaintOracle` is complete for the growth channels
   that exist today. Those channels are:
   - the 6.5, 4.5 data-mux and IO-sink merge `%out` rails, and the peel select. Each replaces a φ whose
     decider is tainted.
   - the 3jru return crossing, which is always refused by `declineQuantumReturnCalls` (F-r1A-1).

   I found no other channel. Growth through memory declines at the escape guard, and rail-bank loads are
   already seeded in `collectAndSeed`. Every miss ends at the check, so the worst case is an over-decline.

## Findings

### F-r1A-1 — P2 · INTRODUCED conjunct (verdict equals the oracle's) · bd `test_C_libtooling-we38` (filed)

**The problem.** `LaterTaintOracle`'s callee seed (`calleeMayYieldQuantum`: "a call to a defined callee that
holds a `cq_theta`, transitively") answers a semantic question syntactically (L5). The question is whether
this call's RESULT can become tainted in a later round. The seed's only protective purpose is the 3jru return
crossing, and that growth is refused by `declineQuantumReturnCalls` at the post-fixpoint slot, before
`specialize()`, regardless of the seed. Its only measured effect is an over-decline.

**Measurements:**

| probe | shape | oracle | subject | MA (seed deleted) |
|---|---|---|---|---|
| `r6a` | F's ret is a 6.5 `%out` (3jru growth in round 2) | DECLINE `quantum value returned across a function boundary` | same | **same string** |
| `r6b` | `F(n){r=cq_theta(n,.3); return n+cq_measure(r);}`: F's ret is classical forever; `t=h(q,F(n)); if(t>3) q2=cq_theta(q2,.2)` | DECLINE `classical call result used as a quantum register`; twin ACCEPTS | same (VERDICT-DIFF) | **ACC-SAME with the twin**, 40 lines, 2b `7 verified, 0 violation(s), 0 unproven` |

**Pinning:** MA moves 0 of 486 lit fixtures, so the seed is unpinned in both directions.

**INTRODUCED vs PRE-EXISTING:** the oracle declines `r6b` too, so this is not a regression. It is a recovery
that bd cepm set out to make and forfeits.

**Fix direction:** either narrow the seed to "some `ret` of F `mayGain`s", walking F's return slice with the
same oracle, or delete the seed with a comment citing `declineQuantumReturnCalls`. Pin it with `r6b` (accept)
and `r6a` (decline). The indirect-call seed rests on the same ground. That is argued, not constructed: I did
not build MC.

**Repro:**
```
cd …/review_r1A_cepm/probes
bash gen.sh r6bC r6bT
bash twincmp.sh <subject cq-opt> r6b     # VERDICT-DIFF
```
With the MA mutant, the same run is ACC-SAME.

### F-r1A-2 — P3 · INTRODUCED · the φ-decider "walk up to the idom" is unpinned, and unreachable today

**The mutant.** MB keeps only M's own terminator and its direct predecessors' terminators. It moves 0 of 486
lit fixtures and 0 of my probes.

**Reachability.** Every shape I built where the tainted decider is NOT a direct predecessor of the merge
declines in round 1, on the oracle and the subject alike, and on the twin where one exists:

| probe | shape | first decline |
|---|---|---|
| `gie` | if/else with two classical-call arms | `value-arm swap-route` |
| `gsw` | switch with a non-empty default | `control flow` |
| `ir_fwdC.ll` | hand-written IR: r2g's diamond with an empty forwarding block on the straight-through edge | `value-arm swap-route`, on oracle, subject and MB alike |

So no growth channel passes through the walk today. Rule 12 cannot supply a fixture for it. The same holds
for the check's own diagnostic `kMsgPredictedClassicalQuantum`: it has no reachable fixture and is pinned only
by the implementer's M6/M7 (and R1/R4/R5).

**Ask:** write the retirement trigger into the source: "the day 6.5 / 4.5 / the IO mux / the peel admits a
merge whose tainted branch is not a direct pred, add the `ir_fwdC` / `gie` fixture here".

### F-r1A-3 — P3 · INTRODUCED · L7 — the check's comment in `Specialization.cpp` is stale after round 1b

The comment says:
> "The predictor is argued a sound over-approximation … and nothing between propagation and here is known
> to change a callee body, so this is argued UNREACHABLE"

After round 1b the check is the designated backstop for the sticky rule. It is reached by a REPLANNED MASK,
not by a changed body: the implementer's own R1/R4/R5 reach it with the callee body untouched.

`SpecializeClone.h` was updated to say so; `Specialization.cpp` (and TRACK §3 item 3 and §6 M5, "argued
unreachable") were not. The mechanism named at the source is the wrong one — L7's shape. Fix the comment in
the same change.

### F-r1A-4 — P3 · INTRODUCED · L7 — `TaintSet::SpecPredictGeneration`'s stated reason is false as written

The comment says:
> "0 for every drain `propagate()` runs (nothing reads taint between them)"

At least five stages read and act on the taint set between successive `propagate()` calls:
`dropDeadCallArguments`, `promoteFp80Union`, `flattenPredMuxRegions`, `unrollConstTripLoops` and
`recognizeCtlzIdiomLoops`.

The conclusion holds for a different reason. Every `taint = propagate(M, wd)` builds a FRESH `TaintSet`,
which contains exactly one generation-0 drain. No record outlives the set a stage read.
`propagateWorklist` has four call sites; the other three (the round-2 first drain, the onward drain and
`propagateFromSeeds`) are all `skipRuntimeCalls=true` growth drains. That also answers the implementer's
§10 item 5: no pair of generation-0 drains of the same set has a reader between them. Fix the comment.

## Standing-lesson questions

- **L1.** The premise "this site's result is classical" is recorded in `SpecPredictedClassical` and re-asked
  at `specialize()` (`ResultWasTainted` against the clone's `ReturnTainted`). Both entry points call
  `specialize()`.
  - Round-2 growth is refused by the sticky rule, so no round-2 re-taint can contradict round-1 consumers.
    `st2` measures this.
  - The round-1 settle depends only on the current IR and taint, and is re-run by every fresh `propagate()`.
    `declineStaleTaintSet` compares only `Tainted`, and the fresh and carried sets agree (both are generation
    0).
- **L2.** The record is kept consistent with `Tainted`: it is erased on an in-drain re-taint and on settle.
  - One harmless asymmetry: a 3jru direct insert can leave a stale record on a now-tainted call. The settle
    skips tainted calls and the check reads `Tainted`, so it is harmless. In any case it is unreachable: a
    pure callee's `ret` is never module-tainted.
- **L3.** 6.5 now asks the inputs directly (implementer M8 pins it). I checked the other readers of "the
  call's taint":
  - (K5) rejects every non-intrinsic call.
  - The loop layer's `Tainted.count(&I)` scans skip an untainted clone call. A classical-verdict clone is
    Bennett-wrapped, so it is the identity on its handle arguments, and treating its loop or arm as classical
    is unitary-correct.
  - Measured: `lq2` (a per-trip rail read by the site in a rolled runtime-trip loop) is ACC-SAME, 286 lines,
    2b clean. `lr`, `lz` and `lk` are DECL-SAME with the twin's strings; the oracle gave DECL-DIFF. `an`
    (in-place Ry arm), `pq` (phase arm) and `sq` (switch arm) are unchanged from the oracle.
  - I grepped for post-detection duplicators of user calls (`->clone()`) and found only template chains
    (`BreakReversePlay`), `cq_theta` (`SwapRouteEmit`), compares (`MergePhiPeel`) and a GEP (`RailBankPromote`).
    `RegionFlatten` moves instructions rather than copying them. No `Pending` site can be duplicated out of
    `Pending`.
- **L4.** Not applicable: no wire walker is added.
- **L5.** See F-r1A-1.
- **L7.** See F-r1A-3 and F-r1A-4.
- **Rule 14.** `predictReturnTainted` is reused, and `readsTaintedValue` is exported rather than re-spelled.
  `mayGain` is new, and I found no prior owner of the question it asks.
- **Rule 12.**
  - The eight new decline fixtures are pure (`not … | FileCheck`, no CHECK-COUNT), and each subject exists.
  - The settle step is pinned by the round-2 mask-growth pair.
  - Unpinned: the sticky rule (R2; dead in practice, because the settle step catches every growth), the R6
    seed (F-r1A-1), the idom walk and the check string (F-r1A-2).

## Composition

- **bd z0re.** Composed binary `6a77a6c9…`:
  - `cp` (z0re's `comp2.c` with a READING callee), `zl12`, `zl17`, `za01`, `za02`, `xf` and `st2` all ACC-SAME
    with their twins, 2b STRICT clean. `r6b` still declines (F-r1A-1).
  - On the subject alone, the four side-door programs and `cp` are DECL-SAME, as the implementer's §9 says.
  - z0re alone also accepts `cp` and the four side-door programs twin-identically.
  - No case of F1 allocating a rail from a wrongly-classical result: every result the change leaves classical
    is classical in the twin.
- **bd rhk5.** Named composition program: `probes/src/ryC.c`. A template rail `p = q*3` is read only by a
  classical-verdict clone call, and then a non-diagonal `cq_theta(q,.7)` follows. On the subject, C and its
  twin both warn `live derived record` and leave `p` dirty, with traces identical. rhk5's read-only proof is
  what decides whether `p` is discharged before the Ry. **Not run:** I had no rhk5 build.

## What I tested and did not break

| probe | shape | oracle | subject |
|---|---|---|---|
| `xf`, `xg` | Cross-function (bd 1yeu): the site lives in a `cq_theta`-holding F, whose classical result returns to `main`, which branches on it (`xf`) or passes it to another Phase-6 site (`xg`) | DECLINE `quantum value returned across a function boundary` | **ACC-SAME** (37/45 lines), 2b STRICT clean |
| `ry` | Template rail into the site, then an Ry | DECLINE | ACC-SAME; both sides warn |
| `lq2` | Rolled loop | DECLINE `loop-carried tainted value` | ACC-SAME |
| `st2` | Sticky mask growth whose grown clone stays classical | DECLINE | ACC-SAME |
| `ie` | if/else folded by `-O1` to `ext_f(select)` | ACC-DIFF | identical lowered IR to the oracle |

- `ie` is a quantum-returning callee: the copy-out class, bd `ffir`, and not mine to rule.
- **Totality of the check over `Pending`.** A site erased or rebuilt before `specialize()` would carry a stale
  pointer. I found no stage that duplicates or replaces a user call after detection. `retargetSite` updates
  `Cand.Site` by reference, so the post-`resolveSite` diagnose reads a live call.
- **Predictor edge cases.**
  - Recursion is refused by `scanBody`.
  - Memory: only QROM loads are admitted, and those are in the closure.
  - A declaration, a varargs callee, an interposable callee, arity above 64 and a front-end or reserved-name
    callee are all excluded. The exclusion keeps the oracle's taint.
  - A `musttail` call to a predicted-classical callee keeps its prototype (argued, not run).
