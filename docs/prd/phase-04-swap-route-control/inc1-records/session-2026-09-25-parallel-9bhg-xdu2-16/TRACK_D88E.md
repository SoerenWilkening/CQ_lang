# Track d88e — the one-register merge-φ lift, re-asked after `specialize()`

Session 2026-09-25. Two tracks ran in parallel with this one:

- bd `9bhg`, on branch `worktree-agent-a50057998e957b90e`;
- a track fixing bd `8e5r`/`um24`/`j8sk` (dangling `taint.Tainted` keys).

This track touched neither `Specialization.cpp` nor any erase site.

- Worktree branch: `worktree-agent-acf961e52a2f9e440`, based on `main` at `def1b088`.

Binaries:

- **ORACLE:** `cq-opt` `b1603d237fc3a739` (main `def1b088`, frozen). A fresh build of
  the unmodified worktree hashed BIT-IDENTICAL to it before any edit (build null
  control).
- **SUBJECT (final):** `cq-opt` `e587c19152bf39e5`, `libCQPass.so` `66c1b68f250d5a30`.
  The comment-only edits made after it was frozen rebuilt to the same two hashes.
  - The first build of this change (v1, `57fa5f0cfc1f2d09`) did not yet move the bd
    2qyz re-sweep (§4).
  - Every measurement below is v2 unless it says v1.
- **COMPOSED with bd 9bhg:** `30529716`'s `ir-pass/{include,src}` and `ir-pass/test`
  diffs, applied on top of v2 with no conflict. Its `cq-opt` is `242f8b61530623e9`
  (§7).

Probes, twins, sweeps and the mutation harness are under `d88e_probes/`:

- the C sources are in `src/`;
- the scripts carry this session's scratchpad paths, and say so.

**Not self-cleared.** The orchestrator owes this change independent Rule-13 rounds. §10
says what to attack first.

## 1. Headline

- **bd d88e is closed as a silent miscompile.** Every lift-then-scrub reproducer from
  the r1A review now DECLINES with the hand-inlined twin's string, byte-identical stderr,
  measured pair by pair (§5). So do six more shapes found here:
  - an if/else and an N-way switch that rotate on EVERY edge;
  - a derived base;
  - the f64 register;
  - a nested lift;
  - a pure op over the lifted φ.
- **The fix is a RECORD and a RE-ASK** (CLAUDE.md L1's standing cure).
  - The lift records the premise it proved.
  - `declineFalsifiedMergePhiLifts` re-asks that premise at final taint, right after
    `specialize()`, in both entry points.
  - No predicate of the lift changed, and no accepted stream changed.
- **One stage moved: the bd 2qyz post-lift stale re-sweep** (`declineLiftedStaleRecordOps`).
  It moved from just after the lift to just after the re-ask.
  - It adjudicates CONSEQUENCES of a lift, so it must run only once the lift is
    confirmed.
  - At its old slot it declined the pure-consumer shape first, with a stale-record
    string for a staleness the false RAUW manufactured (`g01C`, §5).
  - Moving it produced no mover in the corpus (§8.2), and its true-lift decline still
    fires (a new fixture, §8.1).
- **Twin parity over the 42-pair battery went from 14 to 28 twin-identical.** With
  9bhg composed it is 30.
  - Every remaining divergence is one of three things: a safe-direction decline, a
    correct but out-of-scope accept, or a stage-1 IR difference.
  - Each one is classified and filed (§5, §9).
- **With bd 9bhg composed on top, `l09C`/`l10C` decline** with the twin's string.
  - 9bhg alone moves those two from DECLINE to a silent wrong ACCEPT.
  - So this change meets r1A's gate for landing 9bhg (§7).
- **Corpus A/B: every mover is one of this change's own fixtures.** Each sweep ran a
  null control first.
  - Lit corpus: denominator 2301, 9 A→D and 2 decline-string moves.
  - Multi-TU e2e modules: 0 movers of 22.
  - Probe battery: 14 movers of 112, all in the d88e family (§8.2).
- **This is not the population where the class is absent.** A census mutant shows
  that 20 SHIPPED fixtures carry a TRUE lift through the new re-ask, and it passes all
  of them (§8.4).

## 2. The defect, measured

`declineClassicalMuxes`' one-register lift (`liftOneRegisterMergePhi`) proves that a
classical-condition merge φ is a pure renaming of ONE register. Two of its conjuncts read
`taint.Tainted`:

- **(2):** every incoming is tainted;
- **(3):** every incoming resolves through in-place gates (`resolveWireBase`) to one
  base.

The lift runs BEFORE `specialize()`, so both conjuncts see pre-scrub taint.

`propagate` taints a Phase-6 call result `t = h(q, m)` CONSERVATIVELY, because it reads
the tainted `q`. When the clone later proves `h` classical, `scrubForwardCone` untaints
`t`. By then the lift has already RAUW'd `phi(t, cq_theta(t, a))` to `t` and erased the
φ. Two things follow:

- `lowerRotations` decides `Chained = taint.Tainted.count(arg0)` at FINAL taint, so the
  arm's `cq_theta(t, a)` lowers as a SOURCE on a fresh rail.
- The user's `cq_measure` of the erased φ reads classical `t` and takes the bd 21mg
  classical-measure path. The measurement is gone.

`l01C` on the oracle lowers to `ret i32 %6` (the clone's classical result). The lowered
module has 0 `cqrt_measure`; the source has 1. `opt` exits 0, and stage 2b STRICT
reports `0 violation(s)`.

bd l3oi's `declineScrubbedHandleReads` cannot see this. It asks about EMITTED
`cqrt_*`/`cq_template_*` calls and masked clone arguments that read a scrubbed value.
Here the premise was consumed by a REWRITE instead. This is L1's STAGE species on the
scrub side, as r1A diagnosed.

## 3. Route choice

**The twin decides the target.** In the twin, `h`'s classical return is written
directly: `int t = m + 1;`.

- For every d88e reproducer, measured on the oracle (§5), the twin DECLINES at
  `declineClassicalMuxes` with `cq taint escape: tainted value muxed by a
  classical-condition phi`.
- That decline is right: the twin's φ muxes a classical value with a quantum register,
  which is a real data mux, not a renaming.
- Accepting it would need a mixed handle/literal mux under classical control, which the
  tree does not have. That is an over-decline of the TWIN, filed as bd `8osk`.

So "fixed" means: decline, with the twin's string.

| route | verdict | why |
|---|---|---|
| (a) refuse the lift when its base is a potential Phase-6 result | rejected | It needs a PREDICTION of which values the scrub can reach. That is 9bhg's `collectScrubCone`, which is not on `main`, so adding it here would be a second spelling (Rule 14). It would also over-decline every spec-QUANTUM lift, whose base really is a register: `l01Q`, `b02Q` and `f01Q` all lift correctly today. |
| (b) RECORD the lift, RE-ASK after `specialize()` | **chosen** | L1's standard cure. It observes the scrub's OUTCOME rather than predicting it, so it cannot MISS a base that lost its taint. It is minimal: no predicate changes, and the only stage that moves is the lift's own consequence-checker (§4). |
| (c) move the lift after `specialize()` | rejected for this bead | The lift lives inside `declineClassicalMuxes`, and that slot is contracted with `promoteLoopCarriedHandleSeeds` ("immediately before the guard whose accept it grants", `LoopPlan.h`). Moving the lift means moving the bd zujr promotion across `specialize()`. The promotion's (P4) retype fence asks the callee's DECLARED parameter type, and `specialize()` changes that type by retargeting. (c) would also recover `l19C` (§5), but that is an ACCEPT-direction change of its own, filed with cepm rather than bundled here. |

## 4. The change

**The record.** `TaintSet::LiftedMergePhis` (`TaintPropagation.h`) is a vector of
`{F, DebugLoc, Base, Incomings}`. `Base` and `Incomings` are `WeakTrackingVH`s.

- It is written ONLY at `liftOneRegisterMergePhi`'s accept, before its RAUW.
- It is read ONLY by `declineFalsifiedMergePhiLifts`.

**The re-ask.** `declineFalsifiedMergePhiLifts` lives in `TaintPropagation.cpp` and is
declared in the header. For each record it does four things, in order:

1. It runs `declineClassicalMuxes`' own entry test first. If NO recorded incoming is
   still tainted, the φ would have been a classical φ the guard never asks about, so the
   re-ask skips it.
2. Otherwise it checks conjunct (2): every incoming is still tainted.
3. Then it checks conjunct (3): `resolveWireBase(incoming)` is the recorded (tracked)
   base. This CALLS the one owner with the same gate set. The gate-set seed is now a
   shared helper, `collectLiftGateCalls`, so the lift and the re-ask cannot resolve a
   wire differently (Rule 14).
4. A nulled handle declines. This is argued unreachable (§6.4).

A failure diagnoses `kMsgClassicalPhi` at the erased φ's function and `!dbg`. That is
`diagnoseEscape(Phi, kMsgClassicalPhi)`, spelled from the record.

**Slots, in both `run()` and the `runOnFunction` shim.** The order is:

1. `specialize()`
2. **the re-ask**
3. `declineLiftedStaleRecordOps` (**moved here**)
4. `declineScrubbedHandleReads` (l3oi)
5. the 3d8q stale-reader backstop

Three fixtures pin this order:

- `..._spec_scrubbed_base_owner.ll` pins the re-ask against the backstop;
- `..._spec_scrubbed_base_pure_consumer.ll` pins it against the moved re-sweep;
- `..._spec_scrubbed_base_l3oi_owner.ll` pins it against l3oi.

The re-sweep keeps its old order relative to l3oi. §8.4 gives the mutants that pin each
slot.

**Source comments corrected in the same change (L7).**

- The lift's block comment said "The only hazard is a RECORD mismatch". That is true of
  a FINAL-taint proof and was false of this one. The comment now carries the d88e
  paragraph.
- `declineClassicalMuxes`' header and the `run()` slot comment now call the lift's
  accept PROVISIONAL until the re-ask.
- The l3oi slot comment said "Loud, before anything else runs". That is no longer true.
- Every comment that named the re-sweep's old slot is repointed:
  - `TaintPropagation.h` `LiftedConsumers`;
  - the lift body;
  - `OpcodeLowering.cpp`'s list of sweep sites;
  - `Specialization.h`;
  - `SwapRouteEmit.cpp`'s stage list.

## 5. The twin battery

`d88e_probes/twincmp.sh` pairs each `<b>C` with its hand-inlined twin `<b>T`. `<b>C` is
2-TU, with lib `h(a,k) = k + 1`.

- If both variants decline, it compares their stderr byte for byte.
- If both accept, it links both and diffs the traces under arguments `5 7` and `2 9`.

The battery has 42 pairs, built from these sources:

- the reviewer's `l01`–`l25`;
- `a01`–`a04` (§6.5's audit claims);
- `b01`, `b02` (every edge rotates);
- `e01`, `e02` (argc spellings);
- `f01` (f64);
- `g01` (a pure consumer);
- `j01`–`j03` (the base is a keep root, mixed, or derived);
- `k01`–`k04`.

Results:

| binary | twin-identical |
|---|---|
| ORACLE | **14 of 42** |
| SUBJECT | **28 of 42** |
| COMPOSED | **30 of 42** |

| pairs | oracle | subject | reading |
|---|---|---|---|
| `l01 l07 l08 l13 l18 l22 b01 b02 k04 e01 j03 f01` | C accepts, with the measurement DELETED; T declines | **DECL-SAME** | The d88e population (see the list below the table). |
| `l25 g01` | DECL-DIFF | **DECL-SAME** | A decline manufactured by the false lift itself (see below). The re-ask now speaks first. |
| `e02 j01 l03 l15 l21` | ACC-SAME | ACC-SAME | Unchanged. `j01`/`e02` is a lift over a `cq_theta` keep root while `t` is scrubbed elsewhere; it is also an e2e twin gate (§8.3). |
| `k01 k02 k03 l02 l11 l14 l16 l23 l24` | DECL-SAME | DECL-SAME | Unchanged. |
| `l09 l10` | DECL-DIFF | DECL-DIFF | On `main`, bd 3jru's early refusal speaks first, as on the oracle. **DECL-SAME when 9bhg is composed** (§7). |
| `l04 l05 l06` | DECL-DIFF | DECL-DIFF | **Safe.** C declines at the EARLY `declineStaleRecordOps`, not at the lift (see below). |
| `l12 l17 a02` | C ACCEPTS, T declines | same | **Correct but out of scope, filed as bd `z0re` (owner question).** A runtime-seed state prep (see below). |
| `a01` | C ACCEPTS, T declines | same | **Correct but out of scope, bd `z0re`.** An untainted-base angle select (see below). |
| `l19 a03 a04` | C declines, T ACCEPTS | same | **Over-declines, appended to bd `cepm`** (see below). |
| `l20` | ACC-DIFF | ACC-DIFF | Stage-1 IR differs: `-O1` folds `t + (q2>3)` differently when `t` is `m+1`. Both compute the same value. |
| `j02` | ACC-DIFF | ACC-DIFF | **Filed as bd `hgwx`.** Same stage-1 IR, different lowering of the add (see below). |

Three more pairs were built after the battery, to pin the l3oi slot (§8.4, M8). They
are not in the 42:

- `h03`: ORACLE DECL-DIFF (C at l3oi), SUBJECT **DECL-SAME**.
- `h01`/`h02`: DECL-DIFF on both binaries. They reuse one `t` for the branch and the
  lift, so the condition-wire fence declines first on conservative taint; that is bd
  `cepm`'s class.

Notes on the rows:

- **The d88e population.** The members that go beyond the r1A reproducers:
  - `b01`/`b02` rotate on EVERY edge, so conjunct (3) is the only one that fires;
  - `j03` has a derived base, `u = t*3`;
  - `f01` is an f64 register;
  - `k04` is a nested lift.
- **`l25`/`g01`.** Before, C declined at a stale-reader or stale-record fence, over a
  staleness the false lift's RAUW created: `l25` at the 3d8q backstop, `g01` at the 2qyz
  re-sweep in its old slot.
- **`l04`/`l05`/`l06`.** C declines at the EARLY `declineStaleRecordOps`, which runs on
  conservative taint. The arm's `cq_theta(t, .2)` is a chained gate on `t`'s wire, and
  `t + s` reads `t` after it. `n04C`, a variant with no φ, declines with the identical
  string, so the lift is not needed for this decline. This belongs to bd `cepm`'s class,
  not to the lift.
- **`l12`/`l17`/`a02` (runtime-seed state prep).** At round 1 the arm is classified as
  an IN-PLACE Ry on the "register" `t`, so F1/F2 are never asked. After the scrub,
  `lowerRotations` emits `cqrt_alloc(t)` then `cqrt_ry_controlled`: a RUNTIME-seed state
  prep. The unitary is right. But F1's literal-only seed scope ships that shape DECLINED
  on the direct path (PRD §14.11 Q2, still open in bd `drbq.14`).
- **`a01` (angle select).** The Ry-stem angle select was proved on a tainted base.
  After the scrub it lowers to `alloc(t)`, Ry(B), then a controlled Ry(A−B), which is
  correct. The direct path declines an untainted base at `AngleSelectEmit`'s own guard.
- **`l19`/`a03`/`a04` (over-declines).**
  - `l19`: the lift's conjunct (6) fails, because a conservatively CHAINED theta sits
    outside the arm.
  - `a03`: the rail bank declines at run end in `declineNonHandleBankStores`. This is
    FRAGILE (§6.5).
  - `a04`: a loop-bounded `break` on `h(q, ·)` declines with `loop under quantum
    control`.
- **`j02` (`u = t + q`).** The stage-1 IR is the same in C and T.
  - C lowers the add OUT of place, then applies Ry to the copy while `q` still holds
    the record. The result is a DEPHASED circuit, with only the `live derived record`
    warning.
  - T lowers the add IN place (M-C) and stays coherent.
  - Measured: M-C runs at `lowerOps` on FINAL taint, so the scrub is not the cause.
  - Hypothesis, not bisected: the classical-verdict clone call `__cq_q_h_01(h_q, m)`
    counts as a reader of `q`.

## 6. Soundness argument

### 6.1 What is re-asked, and why only that

The lift's conjuncts split by what they read.

**Structural conjuncts: not re-asked.** These are (1) arity, (4) the dominator tree,
(6) block membership and (7a)/(7b) reachability. Between the lift and the re-ask the
only stage is `specialize()`, and it does not change the caller's CFG:

- it clones callees;
- it retargets call sites in place (`retargetSite` rebuilds a call with a RAUW);
- it scrubs taint.

**Conjunct (5), classical terminators: cannot flip either.** Module taint only SHRINKS
in the window. I enumerated every `Tainted.insert`/`.erase` that `specialize()` can reach
with MODULE taint. There are two:

- `Specialization.cpp:635`, the scrub (an erase);
- `:1218`, the re-mark of a ReturnTainted site (an insert).

Every other insert goes to `cloneTaint`/`ct`, or to a local set in
`predictReturnTainted`. The `:1218` insert re-marks either a site that was already
tainted at propagation, or the call rebuilt from one. A terminator reading such a value
was already tainted at the lift, so the lift's (5) already refused it.

**Conjuncts (2) and (3): the ones that move, and exactly what is re-run.** When the
base loses its taint, the wire walk ends at the arm's gate (now a SOURCE theta) instead
of at the base.

### 6.2 The entry test mirrors the guard, not the lift

If no recorded incoming is tainted, the twin's φ is classical and the guard skips it.
The only lift that can land there is the DEGENERATE `phi(t, t, …)`, where every chain is
empty. Any recorded gate is a `cq_theta` result, which is a never-scrub keep root
(`TaintedSources`). RAUW'ing a φ whose incomings are all `t` onto `t` is exact at any
taint.

`lowering_classical_mux_phi_onereg_spec_scrubbed_base_degenerate.ll` pins that branch
(M3, §8.4). It is hand-edited IR, because `-O1` folds the shape.

### 6.3 Every decline is the twin's decline (an ARGUMENT)

Suppose the re-ask fires. Then the base lost its taint and at least one chain has a
gate. In the twin, the base is classical from the start, so each chain's first gate on
the base is a SOURCE and becomes that chain's base.

**The twin's lift cannot succeed.** For it to succeed, every chain would need the same
source gate G. But round 1's conjunct (6) put G in EVERY edge's own block:

- for N ≥ 2 distinct incoming blocks, that is impossible;
- for a repeated incoming block, (7a) rules it out.

An incoming equal to the base is untainted in the twin, so the twin's (2) fails as well.

**So the twin reaches `diagnoseEscape(Phi, kMsgClassicalPhi)`.** It does not reach the
`PromotedCarriedHandlePhis` exemption: a lifted φ is never a loop-header φ, because
(7b) refuses the latch gate. The one exception would be an EARLIER owner declining the
twin first, and on the whole battery none did.

**The re-ask therefore never declines a program the twin compiles.** It declines
exactly the programs whose accept was the miscompile: the lift's RAUW made a consumer
read `t` where the program read the rotated register.

### 6.4 The nulled-handle branch (argued unreachable)

- The incomings are the base or `cq_theta` calls, and the theta calls stay alive until
  `lowerRotations`.
- The only erase in the window is `retargetSite`. It RAUWs the base; it never plainly
  erases it.
- `WeakTrackingVH` follows the RAUW.

`lowering_classical_mux_phi_onereg_spec_quantum_base_fp_rebuilt.ll` pins exactly this.
There, an f64 site that `specialize()` REBUILDS into an `i32` handle IS the lift's base
and one of its incomings, and the record follows it. Mutant M6 (`WeakVH`) turns that
fixture red (§8.4). Rule 12 can supply no fixture for the null branch itself (M7 MISSED).

### 6.5 L1 and L2, asked of this change

**L1: is anything computed between the record and the re-ask over a premise the window
falsifies?** At v1, yes: the 2qyz re-sweep. It read the post-lift IR on PRE-scrub taint
and gave `g01C` a stale-record verdict for a staleness the false RAUW manufactured. v2
moves it below the re-ask.

That move is ACCEPT-direction only for modules whose sole decline was a stale verdict
over a now-scrubbed name. For such a module:

- if the lift's base was scrubbed, the re-ask declines it anyway;
- otherwise the op's scrubbed operand is classical in the twin too.

Measured: 0 corpus movers from the move, and `g01Q`, the true-lift twin, still declines
at the re-sweep.

**Can anything after the re-ask change taint before `lowerRotations`?** No. None of the
following inserts, erases or RAUWs anything:

- `declineLiftedStaleRecordOps` (it writes only `StaleDeclined`);
- `declineScrubbedHandleReads` (const);
- `declineRecordedStaleQuantumReaders`;
- `declineDephasingUnmarkedLoopRails`;
- `declineRound2FalsifiedRailGrants`.

**L2: what other set is computed over the lift's closure?** `LiftedConsumers`, the
witness that triggers the re-sweep. It is unchanged. Its consumer is the re-sweep that
§4 moved.

**The brief's L2 question: which OTHER stages between `propagate` and `specialize()`
rewrite on "a spec-site result is a register"?** An independent audit agent read every
stage in the window. I verified its non-trivial verdicts by probe. The verdicts fall
into five groups:

- **(a) Caught by l3oi.** An emitted gate, or a masked clone argument, reads the
  scrubbed value:
  - the value arm, the 4.4 select merge, kickback/nest, the switch emitters, and 6.5;
  - AbortPark and GuardedStoreArm;
  - the IO, QRAM and Shadow lowerings;
  - a spec site feeding another spec site.
- **(b) Safe declines:**
  - The rail bank (`a03`), caught at run end by `declineNonHandleBankStores`. ⚠
    FRAGILE: the bank loads are tainted by METADATA, and the scrub never reaches them.
    It stays a decline only while `isLoweredRailHandle` refuses clone results.
  - The 7.4 break (`a04`).
  - Loop rail roots: a root mint must be a theta in `GateCalls`.
  - Invariant roots and the zujr promotion: the seed must be untainted, and the latch is
    a merge `%out`.
  - The stale-reader backstop.
- **(c) Correct accepts outside the scoped shape:**
  - the in-place Ry arm that becomes a runtime-seed prep (`l12`/`l17`/`a02`);
  - the Ry-stem angle select on a spec base (`a01`).

  Both are measured, and both are filed as ONE owner question (bd `z0re`).
- **(c) Value-preserving, so correct whatever the taint:**
  - `MergePhiPeel`, `RegionFlatten`;
  - the bitcast/volatile folds, fp80 union, the unroller, `lowerByRefInline`;
  - PredMux.
- **(d) Silent miscompiles other than d88e: none found.**

The audit read code only. I compiled the (b)/(c) reproducers (`a01`–`a04`, `l12`,
`l17`) and the verdicts matched, with one difference: `a04` declines one owner EARLIER
than predicted (`loop under quantum control`, not `kMsgBreakRederive`). Both are
declines.

One finding is outside the audit's frame: `j02` (bd `hgwx`, §5). It is a different
circuit from the twin. The cause is not a taint premise but the classical clone call's
unused handle argument.

## 7. Composition with bd 9bhg

The 9bhg diffs `983f9361..30529716` for `ir-pass/{include,src}` and `ir-pass/test`
apply to v2 without conflict.

In the composed pipeline, the stages after `specialize()` run in this order:

1. the re-ask;
2. the 2qyz re-sweep;
3. l3oi;
4. 9bhg's late 3jru ask.

**Composed lit:** `Total Discovered Tests: 2312`, Passed 2311, Expectedly Failed 1.

| probe | 9bhg alone (`8b837d1f`) | composed (`242f8b61`) | twin |
|---|---|---|---|
| `l09C` | exit 0, 0 `cqrt_measure` | `f`: classical-φ decline | **DECL-SAME** |
| `l10C` | exit 0, 0 `cqrt_measure` | `f`: classical-φ decline | **DECL-SAME** |
| `g01C` | stale-record decline | classical-φ decline | **DECL-SAME** |
| `g01Q` | stale-record decline | stale-record decline (unchanged) | — |

**Composed twin battery:** 30 of 42 twin-identical. That is the subject's 28 plus
`l09` and `l10`.

## 8. Measurements

The scripts are in `d88e_probes/` and use the frozen binaries named in the header. `lit`
means `cd build && lit -s ir-pass/test`.

### 8.1 Red-green

**Decline fixtures: red on the oracle, green on the subject.** The corpus A/B measures
each of them as a mover against the oracle (§8.2).

- `lowering_reject_classical_mux_phi_spec_scrubbed_base{,_nonmain,_switch,_two_lifts,_arm_chain,_ifelse_all_arms,_switch_nway_all_arms,_fp,_store}.ll`
  - 9 fixtures, A→D;
  - each decline string mirrors `kMsgClassicalPhi` with its `in function …` prefix.
- `..._spec_scrubbed_base_owner.ll`, `..._pure_consumer.ll` and `..._l3oi_owner.ll`
  - 3 fixtures, DIAG: a decline-string move onto the twin's string;
  - they are the slot pins, against the 3d8q backstop, the moved 2qyz re-sweep and the
    l3oi fence respectively;
  - `_l3oi_owner.ll` was added after the v2 corpus sweep (§8.4, M8), so it is not in
    §8.2's 2301. On the oracle it declines at l3oi's string, and on the subject at the
    twin's.

**Accept and true-lift controls: GREEN ON BOTH binaries.** These are regression pins
for the directions the re-ask must NOT fire, not red-green:

- `lowering_classical_mux_phi_onereg_spec_quantum_base{,_switch_nway,_fp_rebuilt}.ll`;
- `..._spec_scrubbed_elsewhere.ll`;
- `..._spec_scrubbed_base_degenerate.ll`;
- `lowering_reject_classical_mux_phi_lift_stale_spec_quantum_base.ll` (the re-sweep
  still fires on a true lift).

### 8.2 Corpus A/B (v2)

`ab.py ORACLE SUBJECT LIST` runs its null control first and prints its denominator
before anything else.

**Lit corpus**

- Denominator 2301; null control 0 of 2301.
- Movers: 11 of 2301, all this change's own fixtures:
  - 9 A→D;
  - 2 DIAG (`_owner`, `_pure_consumer`).
- The oracle accepts 1149 of the 2301.
- The v1 sweep, before the re-sweep moved, gave 9 of 2297, all own fixtures.
- **So the move changed no other fixture:** the 2qyz fixtures `lift_stale`,
  `lift_thetahop_stale` and `lift_diaghop_stale` are not movers.

**Multi-TU e2e modules**

- `multi_mods.py` rebuilds the combined stage-1 module of every `run_slice_multi.sh`
  ctest entry.
- Denominator 22; null control 0 of 22.
- Movers: **0**. All 22 accept on both binaries.

**Probe battery**

- Denominator 112; null control 0 of 112.
- Movers: 14.
  - 12 A→D: the d88e C variants.
  - 2 DIAG: `g01C`, `l25C`.
- No `*Q` or `*T` variant moved.

### 8.3 e2e

Three new slices and one twin-identity gate. All are **accept pins**: the miscompile
itself declines, so lit pins it.

- **`e2e-slice-spec-lift-quantum-base`** (2-TU, lib `a + k`).
  - 9 trace lines, including the clone's Bennett wrap.
  - The arm's Ry acts on the clone's out handle `h2`, then one `cqrt_measure_i32(h2)`.
- **`e2e-slice-spec-lift-scrubbed-elsewhere`** (2-TU, lib `k + 1`) and its single-TU
  twin **`e2e-slice-spec-lift-scrubbed-elsewhere-twin`**.
  - `e2e-spec-lift-scrubbed-elsewhere-twin-identical` (`compare_files`) gates the pair.
  - The two goldens are byte-identical, 4 trace lines each.
- **Cross-check.** All three traces were also generated on the ORACLE and diffed:
  identical.
- **Source constraints.** The sources pass `argc` through a `noinline` `slice(int m)`
  (bd 46oo). `main` returns 0, because the harness runs under `pipefail`.
- **Result:** `ctest -R spec-lift` passed 4/4.

### 8.4 Mutation matrix

`d88e_probes/mut.py` runs every mutant through the same four steps:

1. It applies a textual patch to a COPY of the subject tree. That copy was rebuilt and
   hashed BIT-IDENTICAL to the subject before the matrix ran.
   - ⚠ The first v2 re-sync built a STALE binary: rsync kept the older mtimes, so
     `make` saw nothing to do. The hash check caught it, and the sources were touched
     and rebuilt.
2. It rebuilds `CQPass` and `cq-opt`.
3. It runs the FULL `lit -s` for that tree and prints the denominator.
4. It runs the 112-module probe battery against the frozen subject.

After every mutant the file is restored. At the end the tree is rebuilt, and its hash
must equal the subject's.

**Result: restored `e587c19152bf39e5 == subject: True`.** Logs are in
`d88e_probes/results/mut_run_v{1,2}*.log`. The table is v2; the v1 run agrees on every
predicate mutant.

| mutant | removes / changes | lit failures (of 2301) | probe movers (of 112) | verdict |
|---|---|---|---|---|
| N0 | nothing (a no-op conjunct; the binary changes to `47ebf9a9`) | 0 | 0 | **null control** |
| M1 | the re-ask call in `run()` | 11 (every decline fixture) | 14 | KILLED |
| M2 | the RECORD (no `push_back`) | 11 | 14 | KILLED |
| M3 | the entry test (no-tainted-incoming skip) | 1 (`_degenerate`) | 1 (`d01C`) | KILLED |
| M4 | conjunct (2) | 0 | 0 | **MISSED, argued equivalent** (see below) |
| M5 | conjunct (3) | 2 (`_ifelse_all_arms`, `_switch_nway_all_arms`) | 2 (`b01C`, `b02C`) | KILLED |
| M6 | `WeakTrackingVH` → `WeakVH` | 1 (`_fp_rebuilt`) | 1 (`f01Q`) | KILLED |
| M7 | a nulled handle passes instead of declining | 0 | 0 | **MISSED, argued unreachable** (§6.4) |
| M8 | the re-ask moved AFTER the l3oi fence | 1 (`_l3oi_owner`) | 1 (`h03C`) | KILLED (see below) |
| M9 | the re-ask moved AFTER the 3d8q backstop | 1 (`_owner`) | 1 (`l25C`) | KILLED |
| M10 | the 2qyz re-sweep moved BACK to its old slot | 1 (`_pure_consumer`) | 1 (`g01C`) | KILLED |
| M11 | the moved 2qyz re-sweep deleted | 4 (`lift_stale`, `lift_thetahop_stale`, `lift_diaghop_stale`, `lift_stale_spec_quantum_base`) | 1 (`g01Q`) | KILLED |
| MC | CENSUS: every recorded lift declines | 28 | 22 | census (see below) |

Notes on the table:

- **M4 is equivalent.** Suppose an incoming `V` is untainted while
  `resolveWireBase(V).Base` still equals the base. Then `V` IS the base (a source-theta
  base is always tainted). If every other incoming is also the base, the entry test
  already skipped. Otherwise another incoming carries a gate whose chain now stops at
  that gate, and (3) fires on it. The conjunct stays, for fidelity to the lift it
  re-asks.
- **M8 was MISSED in the first v2 run**, when no fixture held both a false lift and an
  l3oi reader. Pinning it needed a second spec result: a false lift on `t` beside a
  branch on `t2`. A single `t` hits the condition-wire fence first (`h01C`/`h02C`).
  After `_l3oi_owner.ll` (`h03C`) was added, N0 and M8 were re-run: N0 0 of 2302, M8
  KILLED.
- **MC shows the population is not absent.** The 28 lit failures are 23 PRE-EXISTING
  shipped fixtures that carry a TRUE lift through the re-ask, plus 5 of this change's
  accept/true-lift controls. The 23 are every fixture whose verdict or first string
  comes AFTER the re-ask's slot:
  - 10 `control_*lifted_phi*` / `control_*classical_lift*` / kickback-rail fixtures;
  - 7 `lowering_classical_mux_phi_onereg*` / `_lift_*_before_sibling` accepts;
  - 3 `*live_record*router_phi*`;
  - the 3 2qyz stale declines, which at the new slot reach the re-ask first.

  So the corpus's `0 non-own movers` (§8.2) is measured over a population that
  EXERCISES the new code 23 times, and the §4k trap (a clean A→D over a class with no
  members) does not apply.

### 8.5 Full ctest, equivalence, code map

All of these ran on the final binary, `cq-opt` `e587c191` / `libCQPass.so` `66c1b68f`.
The one comment edit made after them rebuilt to the same two hashes.

**Full `ctest --test-dir build -j6 --output-on-failure`**

- 504 entries: **503 passed, 1 failed** (`code_map_drift`), in 1464 s.
- The failure was an ordering artefact of my own. `code_map_drift` runs first (entry
  #1), and it ran BEFORE I regenerated `CODE_MAP.md` a few minutes into the suite. Its
  output reads `CODE_MAP.md is stale`. After the regeneration I re-ran it on its own:
  **Passed**.
- ⚠ **Quoted with its load.** During the run the load average was 82–180, from other
  agents on the box. The long pole was `e2e-loop-twin-matrix`, at 1072 s. This time is
  not comparable with a quiet-box figure.
- Every other row was green. A pass under contention is still a pass.

**`cmake --build build --target cq-opt-equivalence-full`**

- `compared 2302 fixtures, 0 mismatch(es)`.

**`python3 tools/update_code_map.py --check`**

- Clean after regeneration.
- The map gains `collectLiftGateCalls` and `declineFalsifiedMergePhiLifts`.

**Final `lit -s ir-pass/test`**

- `Total Discovered Tests: 2302`, Passed 2301, Expectedly Failed 1.

## 9. Filed

| bead | what |
|---|---|
| **bd `z0re`** (P2, decision) | OWNER QUESTION. The spec-classical scrub turns a round-1 in-place-Ry arm or Ry-stem angle select into a runtime-seed state prep or untainted-base angle select, which the direct twin declines. The unitary is correct, but the owner's scope is bypassed (PRD §14.11 Q2 / bd `drbq.14`). Probes: `l12C`, `l17C`, `a02C`, `a01C`. |
| **bd `hgwx`** (P2, bug) | A classical-verdict clone call still reads as a USE of its masked quantum argument. As a result, M-C refuses the in-place add the twin gets (`j02C`: a dephased circuit versus the twin's coherent one, with only a warning), `warnLiveRecordRotations` warns spuriously, and stage 2b's census counts a dirty rail (`e02C`). |
| **bd `8osk`** (P3, feature) | The TWIN's own over-decline, `r = t; if (c) r = cq_theta(t, a); cq_measure(r)` with classical `t`. This is the bead that would let every d88e program compile. |
| **bd `cepm`** (notes appended) | Measured members `l19C`, `a03C` (with the FRAGILE rail-bank backstop), `a04C`, and `l04C`–`l06C` (the early stale sweep): same conservative-taint root, safe direction. |

## 10. What a Rule-13 reviewer should attack first

1. **§6.3's argument that every decline is the twin's.** I measured it on 42 pairs and
   argued it structurally, but I did not prove it for an EARLIER owner that declines
   the twin before `declineClassicalMuxes`.
2. **The re-sweep move (§4, §6.5).** It is the one ACCEPT-direction edge in this change.
   Look for a module whose ONLY decline was the 2qyz re-sweep over an op that becomes
   untainted after the scrub, while the lift's base stays tainted. §6.5 argues such a
   module is correct in its new form, but I did not construct one.
3. **(5) and taint monotonicity (§6.1).** The claim is that nothing in the window can
   make a terminator newly tainted. It rests on an enumeration of two sites in
   `Specialization.cpp`, and bd 9bhg edits that file. After the merge, re-enumerate on
   the composed tree; I did not re-read 9bhg's `specialize()` for new `Tainted.insert`s.
4. **Keys that dangle and alias.** The parallel bd `j8sk`/`8e5r` track exists because
   erase sites leave dangling `Tainted` keys. `resolveWireBase` asks
   `Tainted.count(Handle)` on live values only, but a freed address reused by a new
   value would alias. The re-ask reads `Tainted` at a slot where `specialize()` has
   just erased rebuilt sites. The record itself holds `WeakTrackingVH`s and never keys a
   freed pointer, but the `Tainted` set it queries can.
5. **bd `z0re`'s two accepts.** They are correct by argument and stream-read only, with
   no statevector (Rule 2). A reviewer may want to confirm the controlled-Ry-by-difference
   stream of `a01C` independently.

**What I did NOT attack:**

- in-process hosts that continue past a `DS_Error`;
- `+Asserts`;
- `invoke` call sites;
- `weak`/`available_externally` callees;
- a lift inside a loop body whose base is spec-provisional (none of the loop probes
  reached the lift: `k01`–`k03`, `l11`, `l14`, `l16`, `l23`, `l24` all decline earlier);
- G-13's rolled-vs-unrolled probe, which is not applicable because no condition fence
  was widened.
