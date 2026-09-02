# Control-in-place Increment 2a — the §6a **Rz peephole**, default-on

> bd `test_C_libtooling-drbq.3`. Companion to
> [`control-in-place-PRD.md`](control-in-place-PRD.md) §12.1/§12.2 and to
> [`CONTROL_IN_PLACE_INC1_NOTES.md`](CONTROL_IN_PLACE_INC1_NOTES.md) (the Ry arm).
> Written at the end of the increment, 2026-09-02. **Numbers here are measured on
> this machine at this commit; re-measure rather than trusting them.**

## 0. What shipped, in one paragraph

Every `cq_phi` phase spine the **FLAT** `SwapRouteEmit::emitRegion` path accepts —
diamond, if/else, hcrg sequential regions, the 8h7d.5 rolled in-loop region,
`ShareCondFlag`, multi-Rz spines, Rz on the condition register, and the 4.5
eq-folded diamond that reuses `emitRegion` — now lowers **control-in-place**: the
route quintuple

```
cqrt_alloc_<W>(0) -> rail ; cqrt_cswap(f, q, rail) ; cqrt_rz_<W>(rail, θ)
                          ; cqrt_cswap(f, q, rail) ; cqrt_free(rail)
```

becomes **one `cqrt_rz_<W>_controlled(f, q, θ)` per arm gate**. The flag mint, the
`cqrt_x` bracket, the flag strip and the flag free are byte-identical and in the
same order. **The 4.3 depth-2 nest and the 4.5 switch keep the route**, and so
does the method-B value arm. The two forms are the **same unitary**, not an
approximation: with `w = |0⟩`, `cswap(f,q,w)·Rz_w(θ)·cswap(f,q,w)` applies `Rz(θ)`
to `q` exactly on the `f=1` branch and, on `f=0`, applies `Rz(θ)` to a rail still
holding `|0⟩` — the identity with **no global-phase residue** under the project's
`Rz = diag(1,e^{iθ})` convention. (This is exactly why the Ry stem could never
route and control-in-place is the *mechanism* there — PRD §2.)

No new frozen symbol: `cqrt_rz_<W>_controlled` already existed in the core ABI
(the `emitRz(controlled=true)` arm, dormant since `7cde677`); Inc 2a gave it a
caller. **No new ctest entry** — the increment adds 9 lit fixtures and
*regenerates 26 existing e2e goldens* rather than adding slices.

## 1. Files changed (file:line at this commit)

| file | what |
|---|---|
| `ir-pass/src/SwapRouteEmit.cpp:874-951` | `emitRegion`'s phase path: allocs / route-in / verbatim bodies / route-back / rail frees **replaced** by per-arm `cqrt_x` bracket + **hoist** (`Phi->moveBefore(BI)`) + `taint.ControlledRotations[Phi] = Flag`. |
| `ir-pass/src/SwapRouteEmit.cpp:889-905` | the **§5 const-fold re-anchor** on the FIRST spine gate (new, and load-bearing — §3 below), fenced: a first gate whose arg 0 is neither `Q` nor a `Constant` declines `control flow under quantum control`. |
| `ir-pass/src/SwapRouteEmit.cpp:1003-1020` | step 4: the arm `cq_phi` calls are **no longer erased** (they are `lowerRotations`' to own), and `AllPhis` is gone. |
| `ir-pass/src/SwapRouteEmit.cpp:819-837` | width fence moved from `rzRtFn`/`allocFn` to `abiWidthHasControlledRotation` (the width the emitted stream actually needs; measured to be the **same set** on this frontend). |
| `ir-pass/src/RotationLowering.cpp:349-381` | `lowerRotations`' phi loop reads `taint.ControlledRotations` and emits the controlled gate; a recorded gate with a **classical** arg 0 bails loudly (`controlled phi operand`) instead of silently RAUW-ing the rotation away. |
| `ir-pass/src/RotationLowering.cpp:183-191` | `emitRz`'s controlled arm now **records** into `taint.UserPhaseRotations` (§5, set-ADDITION). |
| `ir-pass/src/ChainWalk.cpp:151-201` | **REMOVAL A** — `isInPlaceGateOn` narrowed to the `ry` stem. |
| `ir-pass/src/ChainWalk.cpp:262-282` | **REMOVAL B** — `railCarriesControlledRotation`'s whitelist narrowed to the `ry` stem. |
| `ir-pass/src/ChainWalk.cpp:410-434` | `preservesBasisUnderRecord`'s `cqrt_rz_..._controlled` arm is now **unreachable**; kept as the fail-safe answer, with that fact recorded at the site. |
| `ir-pass/include/ChainWalk.h:117-141` | the header's note (1) rewritten: the round-2 contradiction is **resolved**, and how. |
| `ir-pass/src/Uncomputation.cpp:598-635` | `preservesBorrowedParent` **clause (1b)**: `cqrt_rz_<W>_controlled(f, P, θ)` is read-only on `P`. Required, not opportunistic (§4). |
| `ir-pass/src/Uncomputation.cpp:723-750` | `routeGroupFullyInside` — recorded as having **no live customer** (§6). |
| `ir-pass/include/TaintPropagation.h:253-262` | `RestoringRoutes` — recorded as having **no writer** (§6). |
| `ir-pass/src/LoopLowering.cpp:303-342` | `isHoistedRegionArmGate` (new) + its two call sites at `:2031` (`tryCaseA`) and `:2426` (`collapseRailPhisIn`) — the rail fan-out repair (§4). |
| `tools/golden_multiset_audit.py` | new instrument: the §9.2 witness, as a script. |
| `tools/inplace_twin_matrix.py` | `--route-oracle` — the oracle INVERTS (§7). |
| `tools/control_flag_order_check.py` | `EXEMPT` grows by one **named** file (§8). |

## 2. The stem split (PRD §12.1), with the streams that decide it

| stem | DAG link (`isInPlaceGateOn`) | adjoint | freeze | `preservesBorrowedParent` |
|---|---|---|---|---|
| `cqrt_ry_<W>_controlled` | **link** (unchanged, Inc 1) | never (its flag is already freed) → whole DAG `NotClosed` | **frozen** | refused (it relabels `P` on `f=1`) |
| `cqrt_rz_<W>_controlled` | **NOT a link** | **none** | **not frozen** | **admitted** (clause 1b) |

The split is not a preference; it is what makes the golden diff come out empty.
The **route is the oracle for what a controlled Rz must look like to the spine**,
and under the route the register's only users are `cqrt_cswap`s — an *unrecognized*
consumer. Refusing the `rz` spelling in `isInPlaceGateOn` reproduces the route's
four verdicts exactly: `isTerminalHandle` false, `isInteriorConsumer` false,
`DagTraversal` closure `NotClosed`, `railCarriesControlledRotation` false.

### Measured, side by side (the probe the PRD names)

Source (hand IR, `scratchpad/inc2b/h2_clause_d_rz_twin.ll`): `r` carries a dead
two-link chain `y = r*7 ; z = y*2` computed **before** a phase region on `r`;
`t = z*3` is measured after. Pre-2a binary = `f92d95e` in a scratch worktree.

```
OLD (route)                                     NEW (control-in-place)
─────────────────────────────────────────────   ─────────────────────────────────────────────
alloc_i32(0)->h ; ry(h,0.7)                     alloc_i32(0)->h ; ry(h,0.7)
alloc_i32(0)->h1 ; ry(h1,0.3)                   alloc_i32(0)->h1 ; ry(h1,0.3)
mul_i32_hl(h1,7)  -> h_op                       mul_i32_hl(h1,7)  -> h_op
mul_i32_hl(h_op,2)-> h_op2                      mul_i32_hl(h_op,2)-> h_op2
icmp_eq_i32_hl(h,5) -> h_cmp                    icmp_eq_i32_hl(h,5) -> h_cmp
alloc_i32(0) -> rail                            ── the five route lines are GONE ──
cswap(h_cmp, h1, rail)
rz_i32(rail, 0.9)                               rz_i32_controlled(h_cmp, h1, 0.9)
cswap(h_cmp, h1, rail)
free(rail)
icmp_eq_i32_hl_unc(h_cmp, h, 5)                 icmp_eq_i32_hl_unc(h_cmp, h, 5)
free(h_cmp)                                     free(h_cmp)
mul_i32_hl(h_op2,3) -> h_op3                    mul_i32_hl(h_op2,3) -> h_op3
mul_i32_hl_unc(h_op2, h_op, 2)   ◀── THE        mul_i32_hl_unc(h_op2, h_op, 2)   ◀── IDENTICAL
free(h_op2)                          TAIL       free(h_op2)
mul_i32_hl_unc(h_op, h1, 7)          THAT       mul_i32_hl_unc(h_op, h1, 7)
free(h_op)                           MATTERS    free(h_op)
measure(h_op3) ; measure(h) ; measure(h1)       measure(h_op3) ; measure(h) ; measure(h1)
```

That four-line tail is the **transparency witness**: the register's dead chain is
still reversed LIFO and freed, and the `y` adjoint still reads `h1` — the register
the region rotated. Pinned as
`ir-pass/test/control_inplace_rz_dead_chain_reversed.ll`.

The **Ry** twin of the same module (`scratchpad/inc2b/h1_clause_d_dag_after_region.ll`,
`cq_theta` in the arm) is **unchanged by Inc 2a** and still freezes: no `mul_unc`,
no `free`, plus the M-A `non-diagonal gate over a live derived record` warning.
Both stems side by side are pinned by
`ir-pass/test/control_inplace_ry_then_phase_region.ll`.

## 3. The one thing the PRD did not name: the §5 const-fold re-anchor

The route read **only arg 1** (the angle) off the arm gate and put the rotation on
its own work rail. Hoist-and-defer reads **arg 0**. `clang -O1` proves `q == k`
inside an equality arm and value-propagates it, so the arm's `cq_phi` bottoms at a
folded `ConstantInt` — and `lowerRotations` would then see an *untainted* operand,
emit **nothing**, and RAUW the gate to the constant: **the arm's Rz silently
dropped**, a verify-clean wrong unitary. `emitRegion` re-anchors the first spine
gate's arg 0 to `Region.RoutedBase` (the handle `tryEqFoldArm` /
`straightThroughConstFoldHandle` already **proved** the arm rotates), and declines
loudly on any other non-`Q` base. Pinned by `control_swap_eqfold_{diamond,ifelse,
polarity}.ll` and `control_swap_straightthrough_constfold.ll`, whose headers now
say so.

## 4. The two things that had to MOVE WITH the change, both found by measurement

Neither was predicted; both showed up the moment the peephole was switched on, and
both are the *"what other set is computed over the same closure"* question from the
8h7d.5 F-1/F-3 lesson.

**(a) `Uncomputation::preservesBorrowedParent` needed clause (1b).** Under the
route, clause (d) was satisfied as a **GROUP** property — `cswap; rz(rail); cswap`
restores `P`'s basis label only because *both* cswaps run (clause (d2),
`TaintSet::RestoringRoutes`). Control-in-place emits no group, so the licence had
to be made **at the gate**, where it is *stronger*: a controlled Rz is
`diag(1,e^{iθ})` on `f=1` and `I` on `f=0`, **diagonal either way**, so `P`'s label
is not restored-after-being-moved, it is **never moved**. Without the clause,
**nine** modules lost their whole M-B interior discharge (`lowering_mc_late_sub_after.ll`
&c — the condition chain's `_unc` + `cqrt_free` pair vanished and an in-place M-C
`sub` reverted to an out-of-place template), each announcing itself only as a *new
M-A warning on an otherwise rc-0 module*.

**(b) `LoopLowering`'s round-2 rail fan-out guard needed `isHoistedRegionArmGate`.**
The guard's own comment stated its premise: *"the emitted region stream is NOT
counted here and must not be — `cqrt_cswap` / `cq_template_*` are not in
`GateCalls`"*. That was true while every phase region put its arm gate on a fresh
work rail and **erased** the `@cq_phi`. Hoist-and-defer keeps the `@cq_phi` alive
with the register at arg 0, so the guard began counting the region's **own** arm
gate as a second in-place mutator: **11** accepting in-loop fixtures (the whole
rolled-Grover family, including every `cmp` twin gate) flipped to a loud
`loop-carried rail has multiple in-place consumers` whose hand-unrolled twin still
compiled. The exclusion is deliberately narrow — membership in
`taint.ControlledRotations`, written only by the two in-place emitters, for a gate
they have already fully adjudicated — and is asked at **both** rounds so they
cannot drift, even though round 1 runs before `lowerControlRegions` and can never
see a member. Pinned by `control_inplace_rz_in_loop_rolled.ll`, which mirrors that
diagnostic character-for-character.

## 5. The two set REMOVALS, and what else was computed over the same closure

### Removal A — `isInPlaceGateOn` lost the `cqrt_rz_<W>_controlled` stem

| other consumer of that closure | did it move? |
|---|---|
| `railCarriesControlledRotation` | **YES, deliberately** (removal B) — it is derived from this predicate, and the whitelist was narrowed at both ends rather than left to the derivation. |
| `preservesBasisUnderRecord`'s `cqrt_rz_` `_controlled` arm | **No — it became UNREACHABLE.** Membership in `D.Calls` / `isInteriorConsumer` goes through `isInPlaceGateOn`. Kept (not deleted) because `true` is the physically correct answer for a diagonal gate and the fail-closed default is `false` = frozen, which is the *wrong* claim to leave for whoever re-admits the stem. Recorded at the site. |
| the six `isTerminalHandle` dependants | **No, and they could not**: the narrowing moves the `rz` spelling from *"in-place gate"* to *"unrecognized consumer"*, and both make `isTerminalHandle` false. |
| `Uncomputation::preservesBorrowedParent` | **YES, and it had to be widened BY HAND** — §4(a). This is the one the derivation does *not* supply, and the one that would have been missed. |
| `LoopLowering::isInPlaceGateOnArg0` | A **different** predicate (pre-lowering, over `@cq_theta`/`@cq_phi` intrinsics, not `cqrt_*`). It also needed a hand change — §4(b). |
| `LoopLowering::collectRailGates` | **No change needed, and the reason is worth stating.** It reads the *pre*-lowering vocabulary. A `cq_phi` is a rail **HOP**, never a rail **GATE** (Rz is diagonal and explicitly exempt), so the hoisted call adds a member to the rail's forward closure and adds nothing to the gate set. That new member (`%r1`, the hoisted call's result) is **dead** — `emitRegion` RAUW'd the merge φ to the base — so it introduces no record read either. Round 1 (`lowerLoops`) runs *before* `lowerControlRegions` and never sees a hoisted gate at all; round 2 (`collapseFlattenedLoopRails`) runs after the flatten and does, which is why §4(b)'s exclusion is asked there. |
| `EmitInverse`'s controlled-rotation adjoint | **No.** It already handles both stems with the correct slots (control at arg 0 threaded verbatim, handle at arg 1, angle negated). It stays **unreachable for the `rz` stem** because that stem is not a DAG link — see §9 for the composition probes that tested this. |

### Removal B — `railCarriesControlledRotation` lost the `cqrt_rz_` stem

Same closure, one consumer: `DagTraversal`'s step-1 and step-3 rail scans, which
`cut` to `NotClosed` on a frozen rail. With the stem gone they no longer cut for a
controlled Rz, so the register's DAG is recovered and reversed — which is precisely
the §2 tail. The **qram guarded store** exclusion that shared this whitelist is
untouched and still excluded, for its own (different) reason: its
`..._controlled_unc` adjoint is emitted while its flag is still live.

### The set ADDITION nobody asked for: `UserPhaseRotations`

`emitRz`'s controlled arm now records into `taint.UserPhaseRotations`. The
CLASSIFICATION is right — `RotationLowering::isTeardownUse` reads *"a rotation that
is NOT a recorded user gate is the spine's negated-angle adjoint"*, and its
`cqrt_rz_` prefix test already matches the `_controlled` spelling, so an
*unrecorded* controlled Rz would be classified as the compiler undoing itself.

**⚠ IT IS BEHAVIOURALLY INERT AT HEAD, AND THIS PARAGRAPH ORIGINALLY SAID IT WAS
NECESSARY** (corrected by the round-1 review, §11.4). The claim was that an
unrecorded gate *"would exempt a live record it must not exempt"*; that is not
reachable. The set has exactly ONE reader chain — `isRecordedUserRotation` →
`isTeardownUse` → `reachesObservingSink`'s NON-USES block — and **two lines below**
that consumer sits the F2-ruling clause `if (N.starts_with("cqrt_ry_") ||
N.starts_with("cqrt_rz_")) continue;`. Recorded ⇒ `isTeardownUse` false ⇒ falls to
that clause ⇒ `continue`. Unrecorded ⇒ `isTeardownUse` true ⇒ `continue`. **Same
`continue`, same walk, same verdict.** `warnLiveRecordRotations` keys on
`UserChainedRotations` and re-checks `cqrt_ry_` structurally, so it never sees the
gate either. It is KEPT because it is the correct classification, it is the
conservative direction, and it becomes load-bearing the moment that F2 clause is
narrowed — which is what the site now says. Writing "it must" for a no-op is the
8h7d.5 round-5 finding *"a comment that overstated a no-op"*, one increment later.

**⚠ This falsifies a written justification, and it is corrected in place.** The
declaration comment said: *"The Phase-4 arm Rz (`SwapRouteEmit` / `SwitchRouteEmit`
/ `NestedRouteEmit`) is deliberately NOT recorded — its arg-0 is always a freshly
`cqrt_alloc`'d work RAIL"*. Since Inc 2a the `SwapRouteEmit` flat path's arm Rz
**is** recorded and its target is the **user's own register**, which may well be a
template-minted record. The `SwitchRouteEmit` / `NestedRouteEmit` half of the
sentence is still true. Measured consequence: **zero** — the whole-corpus
diagnostic sweep (§7) shows no warning moved, because the gate is diagonal and
`warnLiveRecordRotations` is about *non-diagonal* gates over a live record.

## 6. `RestoringRoutes` now has **no writer**, and `routeGroupFullyInside` **no customer**

`SwapRouteEmit::emitRegion`'s phase path was the **only** writer of
`TaintSet::RestoringRoutes` (`emitRoute`'s three other callers — the 4.3 nest, the
4.5 switch, the method-B value arm — record nothing, the last deliberately). Inc 2a
deleted that `push_back`, so the set is permanently empty, `routeGroupFullyInside`
never iterates, and **clause (d2) is inert**.

This is not a regression: the exemption **moved to the gate** and got stronger
there (§4(a)). It is recorded at all three sites rather than silently left as dead
code, because a fence whose set is empty and whose comment still claims a live
customer is the exact justification-gone-stale shape this project keeps
re-learning. The code is **kept**: the route is still emitted by three other
emitters, any of which could legitimately start recording, and deleting the
function would delete the only written statement of *why* a route pair may be read
across.

`ir-pass/test/lowering_uncompute_interior_leak_route_in_interval.ll` is the fixture
this hits hardest — its whole subject was "a route strictly inside the interval".
Its **verdict and its refusing element are unchanged** (the flag strip, exactly as
the Increment-6 re-disposition already recorded), and it now additionally proves
that the *controlled Rz* strictly inside the interval is **admitted**. The header
says all of that in as many words rather than pretending the file still measures
what its name says.

## 7. Verification — what was run, and what it says

| gate | result |
|---|---|
| `tools/golden_multiset_audit.py` | **26 goldens moved, ALL `COLLAPSE-ONLY`**, 65 regions / 66 arms / 70 rz gates, 0 findings. The check is the *structural reduction* (order-sensitive), not only the multiset. |
| whole-corpus disposition sweep vs the pre-2a binary | **0 accept/decline flips and 0 stderr differences over all 1358 fixtures** (exit code + full stderr compared per fixture). |
| `ir-pass-lit` | 1358 fixtures, 1357 pass + 1 expected XFAIL. |
| full `ctest -j6` | **295/295**, 268 s. |
| six 8h7d.5 `cmp` twin gates | pass (rolled ≡ hand-unrolled, byte-identical). |
| `e2e-loop-twin-matrix` | at the increment: 120 cells — 105 ACCEPT-IDENTICAL, 12 DECLINE, 3 other, all matching a table written BEFORE this increment existed. **After the round-1 review added the RECORD axis (§11): 156 cells — 123 ACCEPT-IDENTICAL, 12 DECLINE, 21 other**, table regenerated deliberately with ADDITIONS ONLY. |
| K-independence, `slice_control_grover_loop_dynamic.c` | lowered IR **77 lines at K=3 and 77 at K=1000**, 13 gate calls each; the only textual difference is the global's initializer. (Pre-2a: **87/87** — the recorded 8h7d.5 figure, so the collapse is −10 lines and the *independence* is unchanged.) |
| `tools/control_flag_order_check.py` | **0 violations**, 371 control flags, 1358 files (EXEMPT 9). |
| `cq-opt-equivalence-full` | 1358 fixtures, **0 mismatches**. |
| `tools/free_pairing_check_test.py` | 69 named mutants + 313 proof-targeted mutants, **0 failures**. |
| `tools/inplace_twin_matrix.py --route-oracle <pre-2a cq-opt>` | see §7.1. |

### 7.1 The inverted-oracle matrix

`python3 tools/inplace_twin_matrix.py --jobs 8 --route-oracle
<scratch worktree at f92d95e>/ir-pass/cq-opt`, **472 cells** (all-pairs over five
axes), ~11 min. Reproduced twice with identical tallies.

```
=== TALLY (ALL-PAIRS, 472 cells) ===        # the Ry axis, PREFIX only
  PREFIX-IDENTICAL           287            #   269 SUFFIX-IDENTICAL
                                            # +  18 SUFFIX-2A-COLLAPSE(expected)
  RZ-ONLY(over-decline)       34
  DECLINE-BOTH               149
  DECLINE-BOTH-DIFF            2

=== Rz STEM vs the INVERTED (pre-2a) ROUTE ORACLE, whole trace ===
  RZ-COLLAPSE-ONLY           321
  RZ-DECLINE-BOTH            151
```

**0 `PREFIX-MISMATCH`, 0 `RY-ONLY(suspicious)`, 0 `RZ-MISMATCH`, 0
`RZ-DISPOSITION-MOVED`, 0 `HARNESS-ERROR`, 0 invariant failures.** The Rz line is
the one this increment lives or dies on: for all **321** accepting cells, this
build's Rz stream equals the pre-2a routed stream with the routes collapsed, on
**prefix AND suffix** — the whole trace, because the Rz stem is transparent to
uncomputation.

**The 18 `SUFFIX-2A-COLLAPSE(expected)` are an instrument artifact of this
increment, and I changed the tool rather than explain them away in prose.** They
are all `*_route2_*` cells: a `route2` consumer adds a SECOND, genuine phase region
whose angle is deliberately kept OUTSIDE `ARM_HEX` so `reduce_route` will not
reduce it (that is what keeps the I1 invariant `controlled-Ry count == collapsed
routes` honest). Inc 2a collapses that second region on the build under test while
the pre-2a oracle still routes it, so the Ry-axis suffixes diverge for a reason
that is the increment *working*. The classifier now re-reduces the old suffix with
the FULL reduction (`golden_multiset_audit.reduce_routes`) and uses the new label
**only when the two then become byte-identical** — a narrowing of the report, never
of the check. Before the change all 18 were flagged `!!`; after it, `!!` is **0**.

**A disposition cross-check against a RECORDED Inc-1 baseline.** The round-2 review
recorded `--quick` as *"40 cells: 32 PREFIX-IDENTICAL, 8 RZ-ONLY(over-decline)"*.
Re-run today **without** `--route-oracle` it is *"32 PREFIX-MISMATCH, 8
RZ-ONLY(over-decline)"* — the **same 32 accept-both cells and the same 8 Ry-side
declines**, with the prefix class flipping because both sides are now in-place and
differ only by stem (`cqrt_ry_i32_controlled` vs `cqrt_rz_i32_controlled`), which
is exactly what the tool's header says a no-oracle run degenerates to post-2a. So
**no Ry-axis disposition moved**, measured against a number written down before
this increment existed.

### 7.2 A fixture-integrity defect found while auditing the earlier work

The agents who started this increment inserted the `NOROUTE` block into 15 in-loop
/ live-record fixtures with a script that glued a `;` onto the **last `CHECK-NOT`
pattern of the file**:

```
-; CHECK-NOT: rail record read past an in-place gate
+; CHECK-NOT: rail record read past an in-place gate;
```

Every one of those 15 assertions was **silently disabled** — the pattern can never
match real output — and the suite was fully green with them dead. All 15 are
restored, and all 15 pass once re-enabled, so the mask was hiding nothing real.
Recorded because *"the fixtures are green"* was, for a few hours, a false statement
about 15 of the most safety-critical negatives in the tree (the 8h7d.5 rail-record
family). Files: `control_swap_inloop_{offwire_theta,post_region_theta,
postloop_railop,rail_record_live,railop_inplace,range_cond,seq,two_registers}.ll`,
`lowering_inloop_derived_cond_leading_gate.ll`,
`lowering_live_record_{region_owner_probe,sibling_region_then_measured_accept}.ll`,
`lowering_mc_{late_add_sub_around,late_fallback_reader_after,late_sub_after,
seq_region_customer}.ll`.

## 8. Fixtures

**9 new** (`ir-pass/test/control_inplace_rz_*.ll`), every one **red-green against
the pre-2a binary** — each FAILS under `f92d95e`'s `cq-opt` and PASSES under this
build, which is what makes them pins of *this increment* and not of the shape in
general:

`diamond` (the flagship), `negated` (Rule-9 polarity + the `cqrt_x` **count**
arithmetic), `ifelse` (arm ORDER), `multi_rz_spine` (spine order survives the
hoist), `on_condition_register` (the stem separator — the identical shape with
`cq_theta` **declines**), `share_cond_flag` (mint position; the one accepted Rz
shape with **zero** `cqrt_free`), `sequential` (the hcrg Kahn-sorted emission order
survives a second positional actor), `in_loop_rolled` (§4(b)'s pin), and
`dead_chain_reversed` (§2's transparency witness).

**66 edited.** Every one keeps its original subject; what changed is the arm's
five lines → one, the `cqrt_alloc`/`cqrt_free` **counts**, and the `CHECK-NOT:
_controlled` dephasing guards (which would now match the very gate the increment
emits) → `CHECK-NOT: cqrt_cswap` / `cqrt_copy`. Most gained a `NOROUTE` prefix
**anchored at the function header**, because a trailing `CHECK-NOT` scans only past
the last positive of its own prefix and every route line lands *before* that (bd
`filecheck-check-not-window-trap`).

**`control_swap_cond_datause_ifelse.ll`'s zero-free guard is deliberately
UNANCHORED.** A `define` anchor made `tools/fixture_guard_liveness.py` report
`anchor unresolvable` and count it **DEAD**; an unanchored `NOFREE-NOT` gets the
whole input as its window and is reported *"not checkable, not dead"*, which is the
honest classification for a whole-module guard.

**`tools/control_flag_order_check.py`'s `EXEMPT` grew by one, by NAME.**
`control_inplace_rz_share_cond_flag` is the same `ShareCondFlag` shape the existing
`control_swap_cond_datause_` prefix already exempts (no strip, no flag free — the
data lineage owns the flag), spelled for the peephole. It is listed separately
rather than by widening that prefix to `control_`, because an exemption that
silently swallows more than it names is the failure mode that file's own header
warns about.

## 9. Composition probes run by hand (all identical old vs new)

| shape | verdict |
|---|---|
| in-loop tainted phase region **+** a 7.4 value-arm `break` in the same loop | **declines identically** in both binaries (`loop under quantum control`). So `lowerBreakReversePlay` — the one stage that reverse-plays an *emitted* loop stream and could therefore meet a controlled Rz whose flag is already freed — is not reachable from this composition. |
| phase region **inside a callee** that would be Phase-6 specialized | **declines identically** (`callee contains a quantum primitive`). |
| phase region on a register whose derived rail is **recorded onto the 7.6 output tape** | accepts in both; the new stream is the old one minus the quintuple, the taped record is **left allocated** in both, and STRICT stage 2b is clean either way (old: 3 mints / 2 frees / 2 verified; new: 2 mints / 1 free / 1 verified — 0 violations, 0 unproven). |
| the 6.5 classical-call arm followed by an onward phase region | `control_classical_call_arm_accept_onward_ctl_phase.ll` — the ccarm's own copies are untouched, only the onward region collapses. |
| the 4.5 switch data-mux followed by an onward phase region | `control_swap_switch_datamux_onward_ctl_phase.ll` — same. |
| an in-loop **Ry** arm (would make §4(b)'s exclusion apply to the Ry stem too, since `emitInPlaceRotationRegion` also writes `ControlledRotations`) | **declines identically** in both binaries (`condition predates a non-diagonal gate under quantum control`). In-loop Ry is Inc 3 and deferred, so the widened exclusion is unreachable for that stem — recorded because the widening was not deliberate and is not fenced. |
| the 4.3 nest and the 4.5 switch | **still route**, measured: every `control_swap_nested_phase*.ll` emits 4 `cqrt_cswap` + 1 declare and **zero** `cqrt_rz_*_controlled`; `control_swap_switch_phase{,_passthrough}.ll` the same. The scope split is a measured fact, not only an intent. |

## 10. What still worries me

1. **The `cqrt_x` count changed and PRD §9.2's literal wording did not survive it.**
   A negated arm carried FOUR `cqrt_x(f)` under the route (one pair per cswap) and
   carries TWO now (one pair around the gate run). The audit models that
   explicitly, and `control_inplace_rz_negated.ll` pins the count — but the PRD
   sentence *"the `cqrt_x` brackets … unchanged"* is true only of a non-negated
   arm, and anyone re-deriving the expected shape from the PRD alone will get it
   wrong.
2. **`EmitInverse`'s controlled-rotation adjoint is still unreachable — by
   argument, not by construction.** For the `rz` stem it is unreachable *because*
   the stem is not a DAG link; nothing structurally prevents a future stage from
   handing a `cqrt_rz_<W>_controlled` to `emitInverseChain`, and if one did it
   would emit `cqrt_rz_<W>_controlled(f, h, -θ)` naming a flag the region already
   freed — Inc-1 **finding A**, one stem over. The two compositions I could think
   of (§9) both decline, which is evidence and not proof.
3. **The hoist moved a gate's POSITION, and position is an input to the 8h7d.5
   fences.** The arm `cq_phi` now sits in the pred rather than the arm block. I
   argued (§5) that this is inert — Rz is a rail *hop*, not a rail *gate*, and the
   flatten would have spliced the arm into the pred anyway — and the loop
   twin matrix plus the six `cmp` gates agree. But the 8h7d.5 history is **9 holes
   over 5 review rounds** in exactly this machinery, three of them found *after*
   the increment was declared Rule-13 cleared. I would not treat "the twin matrix
   is green" as sufficient for the in-loop half of this increment.
   **Round 1 (§11) partly answered this and partly sharpened it:** L2 ran 243
   rolled/unrolled twin cells on both binaries with zero movement, and the review
   then found that the matrix had **no `int mark = a;` in any of its 120 cells** —
   i.e. the instrument was blind to the exact shape F-1 and F-3 lived in. A RECORD
   axis is now shipped (156 cells). Read worry 3 as: the in-loop half is better
   witnessed than it was, and the reason to keep worrying is unchanged.
4. **The disposition sweep is a strong instrument and a weak proof.** 0 flips and 0
   diagnostic differences over 1358 fixtures says the *decline partition did not
   move*; it says nothing about whether an accepted module's unitary is right. The
   golden audit closes some of that (the diff is the collapse and nothing else) but
   is explicitly *a claim about the diff, not about the unitary* — if the routed
   stream was wrong, both are wrong identically.
5. **`routeGroupFullyInside` is dead code with a live-looking fence.** I chose to
   keep and annotate rather than delete. That is a judgement call: the next reader
   who needs a route-group exemption will find a correct implementation, but also a
   function no test can reach, so a change to it cannot be caught by any gate in
   the tree.
6. **Nine of the ~40 updated fixtures were edited by the earlier agents and are
   trusted on review, not on red-green.** I re-read every one and found the §7.2
   defect, but a semicolon is the *visible* kind of weakening; a CHECK deleted
   rather than updated would not have shown up in a diff-line count.

---

## 11. Round-1 Rule-13 review (2026-09-02) — three lenses, ZERO defects

Three independent adversarial reviewers ran against this uncommitted tree over
`f92d95e`, each holding a **pre-2a `cq-opt` built from `f92d95e` in a scratch
worktree** as the oracle and running every probe on BOTH binaries. Lenses:
**L1** the stem split and its co-movers · **L2** the rolled loop · **L3** did the
witnesses witness, and are the docs true. The PRD's §11.7 is the plan-of-record
summary; this section is what CHANGED in the tree.

### 11.1 The verdict, and the instruments behind it

**No silent miscompile, no crash, no over-decline, and no cross-binary
disposition movement of any kind.** Independently written instruments, not
re-runs of §7's:

| instrument | result |
|---|---|
| independent 1358-fixture collapsed-stream sweep, both binaries | 672 collapse-exact, 675 decline-both, **0 disposition flips, 0 stderr differences** (11 raw stream diffs, all adjudicated as reducer artifacts) |
| independent re-derivation of all 26 golden diffs (aligned mint sequences + use-set rail identification, arms found in the NEW stream — the opposite direction from the shipped audit) | **26/26 `COLLAPSE-ONLY`**, 66 rails / 66 arms / 70 rz gates, agreeing golden by golden |
| 243 rolled/unrolled twin cells (123 on both binaries) + an 80-cell PREFIX × NEW-REGION × SUFFIX product | **0 `VERDICT-CHANGED`**, 0 hard failures |
| per-cell collapse identity **on a rolled loop** — the axis `inplace_twin_matrix.py` explicitly excludes | **36/36 `COLLAPSE-ONLY`** |
| 73/73 in-scope fixtures replayed under the pre-2a oracle | **all 73 FAIL there** (§8 claimed it for the 9 new ones; it holds for the 64 edited ones too) |
| 7 × 73 lowered-output mutation matrix; 20-mutant validation of the golden audit | 0 survivors in the audit family; 6 weak fixtures found (§11.4) |
| whole-corpus scan for a controlled rotation naming a `cqrt_free`d flag | 151 gates / 100 fixtures, **0 real hits** |
| K-independence re-measured on `slice_control_grover_loop_dynamic` at K ∈ {1,2,3,7,1000} | lowered IR **77 lines and 13 gate calls at every K** (pre-2a: 87 / 21); trace is exactly `10·K + 3` lines |

### 11.2 The §5 const-fold re-anchor is on the HOT path, and it declined MID-EMISSION

L2 measured what §3 presents as an eq-fold corner case: on
`slice_control_grover_loop_dynamic` — the **flagship rolled slice** — `clang -O1`
const-folds **both** arm gates to `cq_phi_si32(i32 5/0, …)`, so the re-anchor
fires **once per region per rolled loop**. Without it `lowerRotations` would see
an untainted arg 0, emit nothing and RAUW the gate to the constant: the arm's Rz
silently dropped in the shipped rolled Grover.

And the fence guarding that hot path **bailed after mutating**: past the flag
mint, possibly past a lone `cqrt_x`, and past a previous arm's hoisted-and-
recorded gates, with the CFG un-flattened. Rule 1 says *lower nothing*. It is
inert today — no output is written on a `DS_Error` decline (measured with a
sentinel pre-written into the output file: byte-untouched under `cq-opt`,
truncated-empty under stock `opt`, rc 1 both) and neither reviewer could build a
reaching program — but the sibling `emitInPlaceRotationRegion` states the
invariant in its own header (*"never emit half a region"*) and places all four of
its bails before its flag mint, so the discipline was understood and simply not
applied here.

**FIXED:** the per-arm "first gate's arg 0 is `Q` or a `Constant`" test is now a
**read-only pre-pass over `Streams`**, placed immediately after the width fence
and **before** step 1's flag mint; the emission loop keeps only the
`setArgOperand`. Same diagnostic string, so the negative fixtures are unmoved.
Every decline in `emitRegion` now precedes the first emitted instruction.

### 11.3 `isHoistedRegionArmGate` was stem-agnostic; its proof is diagonal-specific

`taint.ControlledRotations` has **two** writers — `emitInPlaceRotationRegion`
(the Inc-1 **Ry** arm) and `emitRegion` (the Inc-2a **Rz** arm) — and the
predicate did not distinguish them, so the Ry stem inherited an exemption nobody
derived for it. Half the in-source argument is stem-agnostic (the gate's result is
dead, one link in one sequence on one rail) and half is **false of Ry** (*"it is
DIAGONAL … which is why `collectRailGates` follows a `cq_phi` as a rail HOP and
not as a gate"* — `collectRailGates` counts a `cq_theta_` as a **GATE**).

Unreachability is now measured across five shapes rather than one: in-loop
cross-register Ry, + a second in-place mutator, + an in-place `add`, and the
`if/else` form **all decline identically on both binaries**, while the *same*
cross-register Ry region **outside** a loop **ACCEPTS on both** — so the stem is
live and the loop is the fence.

**FIXED:** narrowed to the `cq_phi` stem (a name test beside the map lookup).
Free today, and it stops Inc 3 inheriting a licence it was never granted. The
obligation Inc 3 owes if it widens is written at the site: **two independently-
written predicates over one closure** — this one would exempt the hoisted gate
from the fan-out count while `collectRailGates`' `noteGate` (a plain
`starts_with("cq_theta_")` test that never consults `ControlledRotations`) would
still count it for staleness. They move together, or the widening states in
writing why two answers for one call are legitimate. That is the 8h7d.5 F-1/F-3
shape verbatim.

### 11.4 Five justifications this increment falsified, and six fixtures that could not witness

**Comments (all corrected in place, none changes an emitted gate):**

| site | what was false |
|---|---|
| `ChainWalk.cpp` row (iv) | told the next editor `preservesBorrowedParent` *"must KEEP excluding"* the `_controlled` spelling — following it deletes clause (1b) and reintroduces §4(a)'s **measured nine-module** regression, whose only outward sign is a new M-A warning on an rc-0 module. Two comments, one gate, two answers, **in the same commit**, and no gate in the tree can see it. Now states clause (1b) and why the licence moved from the GROUP to the GATE. |
| `ChainWalk.cpp` row (iii) | claimed both readings make `isTerminalHandle` false. They do not: an in-place gate is a BENIGN user (`continue`, may stay terminal); only the unrecognized reading forces `false`. The verdict is still right for the file's *other* reason — the ROUTE is the oracle and a `cqrt_cswap` was unrecognized there too — and the move is toward leaking, Rule-6 safe. |
| `ArithLowering.cpp`'s ⚠ block (`priorUseIsSettled`) | asserted arm **(a)** is operative for a controlled rotation and **forbade citing** arm (c)'s ground, while grounding (a)'s safety on the freeze *this increment removed for the Rz stem*. Post-2a: `ry` → (a) (still frozen), `rz` → **(c)** (whose "never a `D.Calls` member" ground is RESTORED for it). Verdict `true` on both paths and under the route, so nothing moved behaviourally — what moved is which argument is load-bearing. This is the file §5's removal table does not list; it is the **third** co-mover. |
| `RotationLowering.cpp`'s `UserPhaseRotations` addition | §5 said an unrecorded controlled Rz *"would exempt a live record it must not exempt"*. Traced end to end, that is unreachable: the set has one reader chain and two lines below its consumer sits the F2 clause `if (N.starts_with("cqrt_ry_") ‖ N.starts_with("cqrt_rz_")) continue;` — recorded and unrecorded reach the **same** `continue`. Measured: 0 stderr differences over 1358 fixtures. KEPT (right classification, conservative direction, load-bearing if that clause narrows) with the comment now saying *inert*, not *necessary*. |
| `LoopLowering.cpp`'s round-2 fan-out block | still claimed the region stream is rejected *"by construction"*. Post-2a a **routed** region still is; a **control-in-place** region is rejected by a **predicate**. Split in two so the first sentence a reader hits is true. |

Plus `ControlPlan.h`'s live `ArmClass::Phase` doc (still "the 4.1 route"),
`Uncomputation.cpp`'s `1356`-fixture corpus (**1358**, re-measured), five fixture
headers — including one saying *"zero controlled Rz"* nine lines above its own
assertion of `cqrt_rz_i32_controlled`, and one claiming *"four rail frees"* where
its own count block asserts **zero** — and a dated superseded banner on `PRD.md`
§20.3, `IMPLEMENTATION.md` §4 and **ROADMAP's own 4.1 entry**.

**Six fixtures survived a re-inserted swap route** (route **and** in-place gate
both emitted = `Rz(θ)` applied twice on the `f=1` branch). Three
`control_swap_cond_datause_*` carry `CHECK-NOT: cqrt_cswap` as the LAST directive
of their prefix, so its window begins after the arm gate a route would precede
(bd `filecheck-check-not-window-trap`, the very trap §8 says was fixed
elsewhere); three others lost a positive `CHECK: cqrt_cswap` in this edit and
gained no negative. All six now carry the bounded `NOROUTE` prefix anchored at
`define`, and each is **mutation-verified**: re-inserting `cqrt_alloc_<W>(0) +
cqrt_cswap` before the first controlled gate turns `NOROUTE` **red in 6/6** while
**every pre-existing prefix stays green** — which is the measurement showing the
gap was real and not hypothetical.

### 11.5 Both instruments were blind where they are quoted

**`tools/golden_multiset_audit.py` modelled the collapse's SHAPE, not its SCOPE.**
Measured, not argued: feeding it a reduced 4.3-nest or 4.5-switch stream as the
new golden came back `COLLAPSE-ONLY` — so PRD §12.2's scope claim ("Nested (4.3)
and switch (4.5) keep the route") was **not witnessed by the witness that states
it**. Now:

* a **scope check** — the reducer refuses a region whose routed base is itself a
  work rail (exactly the nest's inner level), and a golden whose OLD trace bears a
  nest signature must be byte-identical or it reports `OUT-OF-SCOPE`;
* check **(A)** — the literal §9.2 multiset delta — was computed, **never
  enforced** and not printed without `--verbose`. It is now **handle-INVARIANT**
  (`hN` → `h`, so the deleted alloc does not bury the arithmetic under
  first-appearance renumbering), **enforced**, printed unconditionally, and joined
  by a `cqrt_cswap` accounting check (`2 × n_arms` removed, none moved);
* untracked goldens are no longer skipped (`git ls-files --others` unioned in);
* **`--selftest`**: 19 mutants (the reviewer's, verbatim — order ×4, angle,
  operand ×3, deletion, extra frees ×2, bracket ×3, gates ×2, free aliasing, stem,
  width) + 4 controls + the out-of-scope probe, over **embedded** goldens (no git,
  no build, no test tree). **0 survivors.**

Its one remaining gap is recorded IN the tool rather than left implicit: a **4.5
switch's phase trace is structurally indistinguishable from a sequence of flat
regions** — measured, `slice_control_switch_phase` (three `icmp_eq` mint / route /
strip groups on one base, nothing between) has the same shape as
`slice_control_seq_regions` (two `icmp_sgt` groups on one base, nothing between),
and the second **is** in scope and **does** collapse. There is no sound trace-only
discriminator, so the switch half of the scope split is witnessed by the
`control_swap_switch_phase*.ll` fixtures and by the whole-corpus census that **no
module emits both a `cqrt_cswap` and a `cqrt_rz_*_controlled`** — not here.

**`tools/loop_twin_matrix.py` had no RECORD axis.** No `int mark = a;` in any of
its 120 cells, while 8h7d.5's F-1 and F-3 — two of the three CONFIRMED silent
miscompiles that machinery produced — were **entirely** about rail records. A
fourth axis is shipped: `premark` (record before the region, read after the loop;
also the condition-register record, since every REGION spelling builds its
condition from `a`), `postmark` (record after the region), `bodyread` (`acc =
mark * 7;` read inside the body — the round-1 F1 program). The declaration is
hoisted out of the loop deliberately, which designs out the redeclaration
`CLANGFAIL` that cost the reviewer 8 of his own 32 cells. Crossed with a declared
12-cell sub-grid rather than the whole product (a full 5×6×4×4 = 480 would
quadruple a gate the suite already pays for): **120 → 156 cells**.

Table regenerated deliberately; **the diff is ADDITIONS ONLY — 36 lines, no
existing cell's disposition moved.** 18 of the new cells are `ACCEPT-IDENTICAL`
(a rolled trace byte-identical to its twin's **with a live record present**, which
is new coverage) and 18 are `UNROLLED-ONLY`, the 8h7d.5 rail-record fence firing
on the rolled side. Cost 133s wall / 385s CPU at `--jobs 4` on a box carrying
another agent session (not comparable to the quiet-box 112s/279s at 120 cells).

### 11.6 One observation FILED, not fixed

The record axis surfaced a **pre-existing straight-line behaviour**:

```c
int a = 0; a = cq_theta(a, 0.5);
int mark = a;
a = cq_theta(a, 0.25);
return cq_measure(mark) + cq_measure(a);
```

accepts with **rc 0 and no warning** and emits
`ry(%h,.5); ry(%h,.25); measure(%h); measure(%h)` — the record is measured at its
**post-Ry** value. The LOOP half of that class is fenced
(`LoopLowering::staleRailRecordRead`, 8h7d.5 rounds 1–3, where the identical shape
was a CONFIRMED silent miscompile); the straight-line half is not.

**Measured byte-identically on the pre-2a (`f92d95e`) and post-2a binaries**, on
the matrix cells and on the minimal probe above, so **nothing in this increment
moves it in either direction** and it is not an Inc-2a defect. Whether it should
decline is an **owner question**: under Rule 8 `int mark = a` is an ALIAS of one
register, so measuring the current register may be the only thing physically
available — in which case the right answer is a loud decline rather than a
different unitary, and the loop fence is the precedent for that reading.

### 11.7 What was RUN for this round's fixes (Rule 19)

Reported per layer, and only what was executed:

| layer | result |
|---|---|
| `cmake --build build -j8` (BOTH `CQPass` and `cq-opt` — never `--target CQPass` alone) | clean |
| `ctest -R ir-pass-lit` | **1358 fixtures, 1357 pass + 1 expected XFAIL**, 27.6 s |
| full `ctest -j6` (Rule 19 moment 1 — a lowering-core commit — **and** moment 3, a harness change, **and** moment 5, an accept/decline predicate change) | **295/295 passed, 0 failed**, 360 s wall / 963 s CPU. That figure is under concurrent agent load and includes the matrix's 120 → 156 growth; it is NOT comparable to CLAUDE.md's quiet-box band |
| `cmake --build build --target cq-opt-equivalence-full` | **1358 fixtures compared, 0 mismatches** |
| `python3 tools/golden_multiset_audit.py` | **26 goldens, all `COLLAPSE-ONLY`, 65 regions / 66 arms / 70 rz gates, 0 findings** — tallies UNCHANGED by the new scope + (A) enforcement, which is the point: the checks were added without moving a verdict |
| `python3 tools/golden_multiset_audit.py --all` | 273 goldens: 26 `COLLAPSE-ONLY` + 247 `UNCHANGED`. Exactly **two** bear an out-of-scope signature (`slice_control_nested_phase` — both the nested-route and the two-control-flag spelling; `slice_control_switch_value`) and **both are correctly `UNCHANGED`** |
| `python3 tools/golden_multiset_audit.py --selftest` | 19 mutants + 4 controls + 1 scope probe, **0 survivors** |
| `python3 tools/control_flag_order_check.py` | 1358 files [EXEMPT 9, NOT-LOWERED 675, OK 674], 371 control flags, **0 violations** |
| `python3 tools/free_pairing_check_test.py` | 26 positive fixtures, 69 named + 313 proof-targeted mutants, **0 failures** |
| `tools/loop_twin_matrix.py --jobs 4` | **156 cells — 123 ACCEPT-IDENTICAL, 12 DECLINE, 21 other; all match the committed table** |
| the six-fixture route-reinsertion mutation gate (§11.4) | **6/6 DETECTED**, and every pre-existing prefix still PASSES on the mutant — which is the evidence that the `NOROUTE` block, not an existing assertion, is what closes the gap |

Not re-run by this pass and unchanged from §7: `tools/inplace_twin_matrix.py
--route-oracle` (472 cells) and the whole-corpus disposition sweep — both are
reported there, and the round's three reviewers re-derived their central claim
independently (§11.1).
