# Control-in-place Increment 3 — the **Ry arm in the 8h7d.5 rolled loop**, and the P1 fence

> bd `test_C_libtooling-drbq`, child `drbq.4`. Companion to
> [`control-in-place-PRD.md`](control-in-place-PRD.md) **§13** and to
> [`CONTROL_IN_PLACE_INC1_NOTES.md`](CONTROL_IN_PLACE_INC1_NOTES.md) /
> [`CONTROL_IN_PLACE_INC2A_NOTES.md`](CONTROL_IN_PLACE_INC2A_NOTES.md) /
> [`CONTROL_IN_PLACE_INC2B_NOTES.md`](CONTROL_IN_PLACE_INC2B_NOTES.md).
> Written at the end of the increment, 2026-09-04, against the pre-Inc-3 oracle
> built from `1bdaa60` (`md5 5ae372bf94d7dffd…`, byte-identical to the HEAD
> `d44fe5b` binary before this work started — verified, not assumed).
> **Every number here is measured on this machine at this commit. Re-measure
> rather than trusting them.**

## 0. What shipped, in one paragraph

A tainted-condition `if` whose arm is ONE `cq_theta` (Ry) on a register disjoint
from the condition now lowers **inside a classically-bounded loop, ROLLED** — the
8h7d.5 rolled path, with `cqrt_ry_<W>_controlled` as the arm gate instead of
`cqrt_rz_<W>_controlled`. Two fences moved and **both were required**: R7's loop
half in `ArmClassify` (replaced by clauses (b)/(b′)) and R6's position predicates
(a per-activation certificate, in-loop only); and — with no loop in it at all —
the final **P1** fence, whose `(SawValueArm || !SawPhaseArm)` was phase-arm-only
and declined the flagship customer's **Ry reflection on the condition wire**. The
emitter gained **M-β**: for the Ry stem the region's merge φ is RAUW'd to the
HOISTED GATE rather than to the base, which makes the gate a chain member and lets
every `LoopLowering` predicate read the truth with no exemption and no licence. No
new frozen symbol, no new diagnostic string, no CFG surgery beyond the existing
flatten. `+29` lit fixtures (1430 → 1459), `+15` ctest entries (305 → 320), **0
existing goldens moved**, and the loop stays rolled (74 lines of lowered IR at
K=3 and at K=1000).

**One thing did NOT ship green, and it is the headline finding: the full suite is
319/320 and the one red is `e2e-loop-twin-matrix`, on 15 of its 273 cells.** Both divergence classes were root-caused and **both reproduce
byte-for-byte on the pre-Inc-3 oracle with an `Rz` arm** — they are pre-existing,
arm-class-independent, and exposed (not introduced) by this axis. §10 has the
measurements; they are an owner decision, not something this increment may bless.

## 1. Files changed

| file:site | what |
|---|---|
| `ir-pass/src/ArmClassify.cpp` `classifyArms` R7-loop | the unconditional `if (Region.InLoop) decline` became clauses **(b)** (some `BaseWire` member is a `PHINode` in `L`'s header) and **(b′)** (that φ is one the round-2 collapse will CLAIM, asked by calling `railPhiRootMint`) |
| `ir-pass/src/ArmClassify.cpp` `recordLivePerActivation` (new, beside `cannotFollowGate`) | R6's per-activation certificate — the refresh fence, the phi-edge read position, the `Barrier == To` vacuity refusal, and the certificate itself |
| `ir-pass/src/ArmClassify.cpp` R6 user loop | `Region.InLoop ? recordLivePerActivation(M, UI, BI) : <the two flat predicates, verbatim>` |
| `ir-pass/src/ArmClassify.cpp` P1 (`§13.4b`) | `(SawValueArm || !(SawPhaseArm ‖ SawRotationArm))` |
| `ir-pass/src/ArmClassify.cpp` signature + `ir-pass/include/ArmClassify.h` | `classifyArms(…, const LoopInfo *LI)` |
| `ir-pass/src/ControlDetect.cpp` | threads `LI`; **in-loop scope fence part 3 RETIRED** (it was a blanket decline of the shape this increment ships) |
| `ir-pass/src/SwapRouteEmit.cpp` `emitInPlaceRotationRegion` steps 2 + 4 | **M-β** — chain the hoisted gates (`setArgOperand(0, Prev)`) and `MergePhi->replaceAllUsesWith(Gates.back().first)`; the two-conventions site comment |
| `ir-pass/src/LoopLowering.cpp` (new `railPhiRootMint`) + `ir-pass/include/LoopPlan.h` | step (1)'s external-incoming claim condition, NAMED and shared; `collapseRailPhisIn` now CALLS it |
| `ir-pass/src/LoopLowering.cpp` `isHoistedRegionArmGate` | **not widened**; its "THE OBLIGATION INC 3 OWES" paragraph rewritten to say the obligation was discharged by MECHANISM |
| `ir-pass/src/WireWalk.cpp` + `ir-pass/include/WireWalk.h` | `phiTracksWire` moved out of the anonymous namespace and EXPORTED for R6's refresh fence |
| `tools/inplace_twin_matrix.py:835` | a **pre-existing** 4-vs-5 arity bug that made every `--route-oracle` run die before classifying one cell (see §10) |

**Added by the ROUND-1 REVIEW (§11):**

| file:site | what |
|---|---|
| `ir-pass/src/TaintPropagation.cpp` `resolveWireBase` | STOP at a `ControlledRotations` gate — F-L5-1, the M-β lifted-φ over-decline (PRE-EXISTING, repaired) |
| `ir-pass/src/SwapRouteEmit.cpp` `emitInPlaceRotationRegion` step 2 | `if (Prev == G.first) { diagnoseUnderControl(Cond, "control flow"); return; }` — F-L4-2, an unreachable self-chain that would have ABORTED the verifier instead of declining |
| `ir-pass/src/SwapRouteEmit.cpp` Kahn-cycle backstop comment | F-L4-1 — it cited a fixture that was renamed AND flipped to accept, and claimed a guard that no longer stands |
| `ir-pass/src/SwapRouteEmit.cpp` + `LoopLowering.cpp` M-β notes | L2-F2 — "`T` is a chain MEMBER" narrowed to the CARRIED case |
| `ir-pass/include/LoopPlan.h` + `ArmClassify.cpp` `railPhiRootMint` sites | L5-Q4 — the `GateCalls` monotonicity argument + trigger, and the correction that "a divergence between the two callers is impossible by construction" is FALSE for the unshared latch half |
| `ir-pass/include/WireWalk.h` + `ArmClassify.cpp` refresh fence | L5-Q3 — the INVERTED polarity between `phiTracksWire`'s two callers, the dtzb vocabulary gap, why it is not exploitable, and its RETIREMENT TRIGGER |
| `tools/loop_twin_matrix.py` + `tools/loop_twin_matrix.quarantine.txt` (new) | L7-1/L7-2 — the PINNED-SIGNATURE quarantine, its two boundary controls, and `--refresh-quarantine` |
| `tests/e2e/CMakeLists.txt` + `slice_control_inplace_ry_loop_leak{,_unrolled}.c` (+ goldens) | L3-1 — the O(K) freeze-leak reproducer and its `cmp` twin gate |
| `tools/loop_twin_matrix_quarantine_test.py` (new) + its ctest entry | the quarantine's own mutant validation — 7 cases, no clang/opt/plugin, 0.2 s |

## 2. R6 PER ACTIVATION — the certificate, and the worked trace

**The predicate.** For an `InLoop` region only, each enumerated user `U` of each
member `M` owes: let `D = def(M)` (a non-instruction member FAILS); let `p(U)` be
`U` itself, or — for a `PHINode` consumer — the terminator of the incoming block on
each edge that names `M`. Then

> **OK iff `D` REFRESHES and `everyPathReExecutes(BI, p(U), D)`.**

`D` refreshes unconditionally when it is not a φ (an in-place gate or a producer
re-reads the wire by construction); a `PHINode` `D` must satisfy
`WireWalk::phiTracksWire`. `Barrier == p(U)` is refused outright (assert + early
false) — the finding-P1 vacuity, where the walk cuts at the instruction it is
trying to reach and the certificate is granted to everything, silently.

**The one widening, stated plainly:** the DOMINANCE conjunct that
`provablyBeforePerActivation` bundles is deliberately dropped, so the certificate
is strictly weaker than both flat predicates. That is exactly why the FLAT path
keeps its own spelling byte-for-byte, and it is what the whole-corpus acyclic
sweep in §7 is checking.

**TWO SETS, TWO QUESTIONS — unchanged.** The MEMBER set stays `BaseWireOrder`; the
SKIP set stays `BaseWire`. In-loop both obligations collapse to the one
certificate — a relaxation for reads, no change for hops — but the sets still
differ; only the predicate they feed is now common. Said at the site, not deleted.

**Worked, against the MEASURED `-O1` IR** (`ir/*.s1.ll` of the probe programs; the
block numbers are `clang -O1`'s own):

| shape | member / user | verdict | why, on the measured IR |
|---|---|---|---|
| **S2** `for(){ if(q==5) r=Ry(r,.9); q=Rz(q,.1); }` | `%15` (the merge φ, a member via the header φ `%9`'s latch incoming) / user `%9` | **ACCEPT** | `p(%9)` = `%14`'s terminator; BOTH paths `BI→%12→%14` and `BI→%14` execute `%15` at the top of `%14` first ⇒ cut. `phiTracksWire(%15)` true (nothing rotates between either incoming and its edge) |
| S2 | `%2` (the mint) / user `%9` on the ENTRY edge | **ACCEPT** | the **phi-edge rule**: `p` = entry's terminator, which `BI` cannot reach at all ⇒ the certificate is vacuously satisfied. Without the edge rule this row alone kills S2 |
| S2 | `%15` / user `%5 = cq_measure(%15)` in the exit block | **ACCEPT** | every `BI → %5` path re-executes `%15` first. The flat `dominates` conjunct would have refused it — the customer's own post-loop measure |
| **S1** (post-region `%16 = cq_theta(%15,.25)`) | `%15` / user `%16` (a HOP) | **ACCEPT** | `%16` is in the merge block, below `%15` |
| **S11** (leading gate `%11` in the header above the compare) | `%9` / user `%11` | **ACCEPT** | every `BI → %11` path re-enters the header and executes `%9` (top of block) first |
| **ALIAS** `%p = phi [%r0,pre],[%p,merge]` rotated in place, merge escapes | `%p` / user `%p` on the LATCH edge | **DECLINE** | `p` = latch terminator; `BI → arm → merge → latch` never re-enters the header. **Independently**: `phiTracksWire(%p)` is false, so the disjunct is refused before the walk runs |
| **j4** `d = cq_phi(r_pre,.2)` after the region, in the body | `%r` / user `%d` (a HOP) | **DECLINE** | `BI → merge → %d` does not re-execute `%r`. Correct physics: `Rz` after the `Ry` is a different unitary from `Rz` before it |
| **PREMARK** `mark = r` before the loop, measured after | `%r0` / the measure | **DECLINE** | `D` = the mint, in the entry block, never re-executed; the path carries no barrier |

All eight measured. The three declines are
`control_inplace_ry_reject_inloop_{alias,j4,premark}.ll`; the five accepts are
`control_inplace_ry_inloop_{diamond,post_region_gate,leading_gate}.ll` and the
`slice_control_inplace_ry_loop*` e2e pairs.

## 3. M-β, and the "WHAT OTHER SET IS COMPUTED OVER THE SAME CLOSURE" audit

**What changed:** for the Ry stem the emitter RAUWs the merge φ to the **last
hoisted gate**, and for an if/else the two hoisted gates are **chained** in
emission order (`T_f`'s arg-0 := `T_t`'s result, via `setArgOperand` so the USE is
rewritten and `lowerRotations`' later RAUW-to-handle still finds it).

**Why, in one sentence:** it makes the SSA say what is physically true — the
hoisted controlled Ry *moved the register*, so the value after it is a different
state from the value before it — and every `LoopLowering` predicate then reads the
truth with **no exemption, no licence and no cross-file dependency**.

**The two shapes that break under the other convention, both MEASURED** (with R7
lifted and M-α kept): S2 becomes the zero-hop identity carry, `recordRefreshedByDef`
answers FROZEN (the F-2 rule), `railGateBetween` takes no cut, and the increment's
own target shape declines `rail record read past an in-place gate on the same
rail`; S1 gives the header φ TWO in-place `cq_theta` users and
`collapseRailPhisIn` step (2) fires `loop-carried rail has multiple in-place
consumers`. S11 breaks on neither — two of three, which is why this needed
deciding rather than measuring one program.

**THE PER-STEM SPLIT, stated because two conventions in one file is a real cost:**
Ry uses **M-β** (the hoisted gate), Rz keeps **M-α** (the base), and the reason is
the physics — `cqrt_rz_<W>_controlled` is DIAGONAL, so the two names denote the
same computational-basis state and either target is correct. Retiring
`isHoistedRegionArmGate` by moving Rz to M-β as well is filed as **`drbq.10`**.

**The audit table, re-derived — and the four rows the PRD marked "audit, do not
assume" now say what was READ in the BODIES, not the headers.** The window is
emission (`CQLoweringPass.cpp:323`) → `lowerRotations` (`:422`).

| reader | what it decides | verdict, and how it was established |
|---|---|---|
| a LATER region's `ControlRegion::RoutedBase` | the routed handle at emission | `WeakTrackingVH`, follows the RAUW to `T`; the later region's own theta operand followed the SAME RAUW, so the emitter's identity re-validation still matches. **PINNED**: `control_inplace_ry_inloop_seq.ll` (in-loop) and the existing `control_inplace_ry_sequential.ll` (flat) both green |
| the bd `hcrg` precedence graph | emission ORDER | reasons about **BasicBlocks**; a RAUW target is a VALUE. Read `lowerControlRegions`' pre-flight: it collects block identities only. Unchanged |
| `collapseFlattenedLoopRails` / `collapseRailPhisIn` | the rail chain, gates, fan-out, records | **THE POINT OF THE CHANGE.** `T` becomes a chain member; nothing edited |
| `markIfRailLocal`'s `onRail` | register vs iteration-local temp | `peelInPlaceBase(T, AsLowered=true)` peels `T` through its arg-0 to the collapsed root under BOTH mechanisms ⇒ on the rail either way. Under M-β that is a *fact* rather than a coincidence about a dead value |
| `lowerIOSinks` / `lowerQramReads` / `lowerShadowMemory` | tainted sinks | **READ** (`IOLowering.cpp` / `QramLowering.cpp`): all three enumerate by CALL-SITE name (`cq_tape_write_`, `cq_qram_*`, Shadow `load`/`store`) and ask `taint.Tainted` of the operand. `T`'s result is tainted under both mechanisms and neither reads the merge φ by identity. Unchanged |
| `declineClassicalMuxes` | live select/φ over tainted data | the region's φ is erased by the emitter either way; the loop's rail φ is erased by `collapseFlattenedLoopRails`, which runs at `:340`, BEFORE this. **The un-claimed-loop path was AUDITED** — that is exactly row DB, and clause (b′) now refuses it at detection so the guard is never reached for this class |
| `liftOneRegisterMergePhi` / `repropagateControlMerges` | classical join φs RAUW'd to the base | **READ** (`TaintPropagation.cpp`): both key on `PHINode` identity and on `resolveWireBase` agreeing across incomings. `T` is a `CallInst`, not a φ, so it is never a lift candidate; as an INCOMING it peels to the same wire base the merge φ did. Unchanged |
| `declineLiftedStaleRecordOps` | post-lift stale records | **READ**: it re-runs the stale-record question over values the lift produced. M-β produces no lift, and the values it hands downstream are the same tainted rail members. Unchanged |
| Phase-6 `specialize` | clone-on-taint arguments | **READ** (`Specialize.cpp`): the signature mask keys on `taint.Tainted` per argument, never on identity. A post-region consumer that is a clone argument now names `T`, which is tainted. Unchanged |
| `lowerRotations` | the mint + `replaceAllUsesWith(Handle)` | collapses both mechanisms to identical IR — **the byte-identity claim, and it is measured**: 0 of 1458 pre-existing lit fixtures and 0 of 267 pre-existing e2e slices moved (§7) |

## 4. P1 — §13.4b, the fence with no loop in it

One clause: `(SawValueArm || !(SawPhaseArm || SawRotationArm))`. **The argument is
P1's own with the arm class substituted**: a value arm is refused because method-B
copies a basis LABEL out and replays the chain on the routed rail, so a later
in-place Ry on that wire is a real staleness hazard. An in-place rotation arm
copies nothing, replays nothing and allocates no work rail — its entire emitted
stream is `mint ; [x] cRy ; [x] strip ; free`, all before `BI` — and
`ProvenPostRegion` plus `condWireDisposition`'s own lemma carries the position
proof to every call in that stream. R4 has already proved the rotated wire ∉ the
condition's wires. The residual (a DERIVED condition's template rails, live past
the strip, dephased by a later Ry on `C`) is **identical to the phase arm's** —
that half is CONFIRMED, and by an independent measurement: lens L8 compiled,
linked and ran the derived-`and` and derived-`sqrt` programs on both binaries and
their traces are byte-identical to the `cq_phi`-arm twins apart from
`cqrt_rz_i32_controlled` ↔ `cqrt_ry_i32_controlled` on ONE line, with the whole
condition chain `_unc`'d and freed BEFORE the deferred gate fires. Two new accept
fixtures pin that order (`control_inplace_ry_post_region_theta_derived_cond.ll`,
`..._negated.ll`).

⚠ **The other half of that sentence — "and has been owned since bd `lyyf` by
M-A's `warnLiveRecordRotations`" — is an OVERCLAIM, corrected here rather than
deleted (lens L8, F-L8-1).** M-A does NOT fire for an **escaping** condition
record. Measured: `int d = q & 6; if (d==4) r = cq_theta(r,.9); q = cq_theta(q,.3);
return … + cq_measure(d);` — the `and` rail is MEASURED, so the whole-DAG spine
never uncomputes it, it is live and entangled with the condition register when
the post-region Ry fires, and HEAD's stderr is **empty**: no warning, no error.
The gap is **arm-class-independent and PRE-EXISTING** (the `cq_phi`-arm twin is
accepted by the pre-Inc-3 ORACLE, produces a byte-identical trace, and is equally
silent), so it is not this increment's to fix — but it must not be cited as the
thing that makes the widening safe. What actually makes P1 safe is the ORDER
argument above, which is measured; M-A is a warning that covers SOME residuals
(it does fire for a derived rotated BASE) and not this one.

**And drbq.7's OTHER HALF IS UNTOUCHED**, which the PRD's "P1 is half of the
recorded over-decline" should be read against: a rotated register that gates a
SECOND region still declines, on BOTH binaries — `if (q==5) r=Ry(r,.9);
q=Ry(q,.3); if (r==2) s=Ry(s,.7);` refuses region 2 because `r` gained region 1's
arm theta before region 2's branch. That is an over-decline this increment
neither introduces nor fixes.

**The flat flips it produced, listed in full.** Whole-corpus sweep, 1458 lit
fixtures: **exactly ONE acyclic flip**, `control_inplace_ry_post_region_theta_cond.ll`
— the red-green fixture shipped with the clause. **Zero pre-existing acyclic
fixtures moved.** E2e, 274 slices: two acyclic flips, both added here
(`slice_control_inplace_ry_loop_grover_unrolled.c` and
`slice_control_inplace_ry_loop_derived_unrolled.c`), each of which the pre-Inc-3
binary declines at P1 with no loop in it. **The PRD predicted a wider blast radius
and was wrong; the corrected statement is in §13.4b, and the honest reading is that
the corpus contained no such shape before this increment added one, so the sweep's
silence is weak evidence and the fixture pair is the real witness.**

**It also produced ONE new disposition MISMATCH in the twin matrix**, and that is
in §10.

## 5. The freeze inside a loop — measured

`ChainWalk::railCarriesControlledRotation` answers true STRUCTURALLY from the
emitted gate's own arg-1 use, so `DagTraversal` sets `NotClosed` and the rotated
register is never reverse-played and never freed — **per activation as well as
flat**. Measured on the shipped slices:

| slice | rail mints | left allocated | `cqrt_free` sites | strict 2b |
|---|---|---|---|---|
| `slice_control_inplace_ry_loop` | 2 | 2 | 1 | verified |
| `_leading_gate` | 2 | 2 | 1 | verified |
| `_two_regs` | 3 | 3 | 2 | verified |
| `_derived` | 2 | 2 | 2 (+2 template rails discharged in body) | verified |
| `_grover` | 2 | 2 | 2 | verified |

Both registers are left allocated in every case — `q` because the user measures it,
`r` because of the freeze — and **the twin leaks exactly the same rails for exactly
the same reason**, which is why every pair is byte-identical rather than
"rolled is shorter". The derived-condition slice is the one that proves the
condition chain is NOT frozen: `cq_template_and_i32_hl_unc` + `cqrt_free` land
once per activation, BEFORE the Ry reflection, on both sides. Zero M-A warnings on
either side of any pair.

⚠ **READ THAT LAST SENTENCE AS A STATEMENT ABOUT THESE FIVE SLICES, NOT AS A
SYMMETRY CLAIM** (lens L3, DOC-IMPRECISE, corrected here). `warnLiveRecordRotations`
fires **per STATIC gate**, so on any shape that does exercise it the counts are
NOT symmetric between the rolled and unrolled forms: the O(K)-leak pair added by
this round emits **1 warning rolled and 2 on its K=2 flat twin**, for the same
program, with byte-identical traces. The hazard the warning names occurs K times
at run time and the warning counts source positions. Nothing in the tree pins
that, and the pair's CMake comment says so at the registration.

The O(K) leak §13.5 warns about (iteration-local temps DERIVED from the frozen
rail) was **not exercised by any slice at hand-back** — and §9 worry 2 recorded
that honestly. **It is MEASURED now** (round-1 lens L3 Q1, and the reproducer is
committed as `tests/e2e/slice_control_inplace_ry_loop_leak.c` + its twin + the
`e2e-inplace-ry-loop-leak-twin-identical` gate). The spelling that works is to
read the rotated register **BEFORE** the region in the same body — the read then
precedes that activation's own relabelling gate, and the loop-carried `r` phi
crosses a real rail gate every trip so the back edge does not stale it. The two
spellings that do NOT work are exactly the ones tried at hand-back: a read AFTER
the region is `cq opcode lowering: operand predates a non-diagonal gate`, and a
read in a SECOND loop is `tainted value muxed by a classical-condition phi`.

**The numbers, from the committed golden:** 2 TEMPLATE-minted rails per activation
(`cq_template_mul_i32_hl` and `cqrt_tape_write_i32`), **never freed** — 4 at K=2,
6 at K=3 — while the only `cqrt_free` per trip is the region's own flag. Rule-6
correct (all left ALLOCATED, none freed dirty), invisible to strict stage 2b (its
census counts `cqrt_alloc` mints), and **the flat twin leaks the same rails for
the same reason**, which is why the pair is byte-identical. §13.5's "K rails at
run time" is therefore confirmed with a real program on the shipped binary; the
right response was to record the reproducer, not to add a fence.

## 6. Fixtures

**AT HAND-BACK: 30 files in the family, 11 ACCEPT / 19 DECLINE, corpus 1430 →
1459.** **AFTER THE ROUND-1 REVIEW (§11): 44 files, 20 ACCEPT / 24 DECLINE, corpus
1430 → 1473** (+43 new files; the rename-and-rewrite below is net-zero).
**AFTER THE ROUND-2 REVIEW (§12): 45 files, 21 ACCEPT / 24 DECLINE, corpus 1430 →
1474** — the one file the round added is `control_angle_select_rz_lifted_phi_
after_select.ll`, the **Rz** twin of the round-1 F-L5-1 angle-select accept
(R1-Q1(c): `AngleSelectEmit` records BOTH stems, so the Rz stem flips
oracle-decline → HEAD-accept too, and nothing pinned it). It also takes the
separately-counted `control_angle_select_*` family on disk from **68 files (18
accept / 50 decline)** to **70 (20 / 50)**, both of the additions being Inc-3
accepts. The
fourteen added by round 1 are listed in §11.1 against the findings that asked
for them; re-measure rather than trusting these numbers —
`ls ir-pass/test/*.ll | wc -l`, and
`for f in <family>; do grep -q 'RUN: not' $f; done` for the split.

* **accepts (11)** — `control_inplace_ry_inloop_{diamond, negated, post_region_gate,
  leading_gate, two_registers, seq, rz_reflection, offset, derived_cond, ifelse}.ll`
  and `control_inplace_ry_post_region_theta_cond.ll` (flat, §13.4b).
* **declines (18)** — `control_inplace_ry_reject_inloop_{irreducible, iterlocal_base,
  nested_loop, multilatch, second_cycle, nested, cond_register, premark, j4, alias,
  two_gates, stateprep, tainted_angle, sharecond, stalecond, invariant_cond_hoisted,
  derived_base, frozen_leading_gate}.ll` and
  `control_inplace_ry_reject_post_region_theta_stalecond.ll`. The last in-loop one
  was added DURING the mutation round (§6a) and is the fixture whose header had to
  be corrected to the clause that actually refuses it.
* **rewritten / re-homed** — `control_inplace_ry_reject_in_loop.ll` FLIPPED to accept
  and was `git mv`'d to `control_inplace_ry_inloop_diamond.ll` and rewritten in full;
  its decline was re-homed onto `..._reject_inloop_alias.ll` (the same CFG with the
  carry made an identity and the merge escaping).
* **the two C-sourced declines** (`invariant_cond_hoisted`, `derived_base`) carry
  VERBATIM `clang -O1` output, because both rows are about what the optimizer does
  to the source.
* fixture-integrity detectors run: `grep -rn '^; *[A-Z0-9-]*NOT: .*;$' ir-pass/test/*.ll`
  → **nothing**; no `CHECK-COUNT-` in any new header.

**Mutation verification, per clause.** Each mutation was applied, the plugin AND
`cq-opt` rebuilt (never `--target CQPass` alone), the named fixtures run, then
reverted.

| # | clause mutated | measured result |
|---|---|---|
| **M1** | R7-loop **(b)** — accept a `BaseWire` φ anywhere, not only in `L`'s header | **NOTHING WENT RED.** See §6a |
| **M1′** | R7-loop **(b) AND (b′)** both dropped (`Rollable = true`) | RED: `..._reject_inloop_{iterlocal_base, nested_loop, derived_base}.ll` — whole corpus, 3 of 1459 |
| **M2** | **(b′)** — drop the `railPhiRootMint` call | RED: `..._reject_inloop_{derived_base, nested_loop}.ll` |
| **M3** | R6 refresh fence — drop `phiTracksWire(DP)` | **NOTHING WENT RED, over all 1459 fixtures.** See §6a |
| **M4** | R6 phi-edge read position — use `U` itself instead of the edge terminator | RED: `..._inloop_{diamond, post_region_gate, leading_gate}.ll` (all three flagship accepts) |
| **M5** | R6 certificate (non-φ path) — `return true` | RED: `..._reject_inloop_{premark, j4}.ll`; `..._reject_inloop_alias.ll` stayed green (it declines through the φ path) |
| **M6** | M-β RAUW target — back to `Base` | RED: `..._inloop_{diamond, post_region_gate}.ll` — the two shapes §13.4 predicted |
| **M7** | M-β chain — drop `setArgOperand(0, Prev)` | RED: `..._inloop_ifelse.ll` |
| **M8** | P1 — drop `SawRotationArm` | RED: `control_inplace_ry_post_region_theta_cond.ll` |

### 6a. THE TWO CLAUSES NOTHING PINS, and what stands behind them instead

**M1 — clause (b)'s "in `L`'s HEADER" refinement is UNPINNED, and it is REDUNDANT
under (b′).** Relaxing it to "any `BaseWire` φ" turns nothing red, because
`railPhiRootMint` can only succeed for a φ with EXACTLY ONE incoming block outside
`L` — and in a reducible single-latch loop (gates (A)/(C), already proved before
`Region.InLoop` is set) the header is the only block with a predecessor outside
`L`. So (b)'s live half is "there IS a rail φ at all", and THAT is pinned by
`..._reject_inloop_iterlocal_base.ll` under M1′. The header test is defence in
depth, in the same style as the two `STRUCTURALLY UNREACHABLE, kept as defence in
depth` notes already in `classifyArms`.

**M3 — R6's REFRESH FENCE (`phiTracksWire`) is pinned by NOTHING.** Deleting it
turns **0 of 1459** fixtures red. Every shape I could construct that reaches it is
also refused, earlier, by the PHI-EDGE READ POSITION rule (a frozen self-carry is
its own user on the latch edge, and `BI → arm → merge → latch` never re-enters the
header) or, post-flatten, by `LoopLowering` round 2's `staleRailRecordRead`. I wrote
`..._reject_inloop_frozen_leading_gate.ll` specifically to isolate it — a frozen
carry under a LEADING gate, where the certificate alone WOULD accept — and measured
that it declines with the identical message with the fence deleted. **The fixture
ships anyway, with its header corrected to name the clause that actually refuses
it**, because a fixture whose header names the wrong clause is worse than no
fixture. The fence stays: `false` only ever ADDS declines, it is the same predicate
bd [[identity-carry-phi-does-not-refresh]] needed for a CONFIRMED silent
miscompile, and Rule 14 says reuse the one spelling rather than write a third.
**A reviewer should treat it as defence in depth, not as a live wall**, and lens 1
should try harder than I did to construct the isolating program.

**A third thing measured on the way, and it is the bd
[[mint-at-consumer-window-protection-lives-elsewhere]] pattern:** with R6's
per-activation certificate disabled ENTIRELY (both the φ and non-φ paths), the
ALIAS and FROZEN-LEADING-GATE programs still decline — at a different stage, with a
different owner (`LoopLowering` round 2, post-flatten). R6's value for those shapes
is that it declines BEFORE emission and the flatten (Rule 9) and owns an accurate
message. **If round 2 is ever narrowed, R6's clause becomes the only wall.**

## 7. What was RUN, with counts (Rule 19)

* `lit ir-pass/test` — at hand-back **1458 passed, 1 expectedly failed, 1459
  discovered**; after the round-1 review **1472 passed, 1 expectedly failed, 1473
  discovered**; after the round-2 review (§12) **1473 passed, 1 expectedly
  failed, 1474 discovered, 0 unresolved** (50.6 s). The `0 unresolved` is not
  decoration: round 2 found `ir-pass/test/` holding three stray pass-output files
  (`*.head.ll` / `*.orc.ll`, written there by a reviewer), and `lit.cfg.py`
  discovers any `.ll` in that directory — so the suite was RED at 1476 discovered
  / 3 unresolved while every fixture was fine. Sweep for strays before quoting a
  count: `find ir-pass/test -maxdepth 1 \( -name '*.ll.*' -o -name '*.head.ll' -o
  -name '*.orc.ll' \)` must print nothing.
* whole-corpus lowered-IR + stderr + exit-code sweep, HEAD vs the pre-Inc-3
  oracle, all 1458 fixtures at the time of the sweep — **14 differ, every one a file this increment added**
  (11 accept-flips, 3 R6 message changes). **0 pre-existing fixtures moved.**
  **RE-MEASURED AFTER THE ROUND-1 REVIEW, over all 1473 fixtures: 24 differ, and
  every one is still a file this increment added or rewrote** — **18** accept-flips
  (`EXIT 1→0`) and **6** stderr-only R6 message changes. ⚠ **That line first said
  23 = 17 + 6 and was wrong by one** (round-2 review, §12): the sweep was run
  before the last fixture of the round was written, so
  `control_inplace_ry_inloop_rotated_dead.ll` — an accept-flip — was not in it.
  The round-2 reviewer re-swept all 1473 independently and measured 24 / 18 / 6.
  **The CLEARANCE reviewer then re-swept all 1474 (after the round-2 mini-fix added
  `control_angle_select_rz_lifted_phi_after_select.ll`, itself an accept-flip): 25
  differ = 19 accept-flips + 6 message changes, every one this increment's own, and —
  the M-β byte-identity claim stated as a corpus fact — ZERO lowered-IR differences on
  any file both binaries accept.** The figures 14/1458, 24/1473 and 25/1474 are three
  stamped moments of one growing corpus, not three disagreements.
  The lesson is the cheap one: a whole-corpus number is stamped with the moment
  it was taken, and a fixture added afterwards silently invalidates it.
  (With §12's own fixture the corpus is now **1474**; that file is a 25th
  differing path — an accept-flip whose oracle decline is quoted in its header —
  and it is deliberately NOT folded into the 24 above, which is a measurement of
  a stated corpus.) Two corrections to the
  line above while we are here (round-1 lens L6): the message-change count was
  already **4**, not 3, at 1459 — a miscount, not a movement — and the ONE
  git-tracked path among the 23 is `control_inplace_ry_inloop_diamond.ll`, which
  is this increment's own rename-and-rewrite. **0 pre-existing fixtures moved,
  re-verified.** Note also what does NOT flip and is load-bearing for two new
  fixture headers: `control_inplace_ry_reject_flat_cond_pre_measure.ll` and
  `control_inplace_ry_reject_flat_rotated_dead.ll` are byte-identical on both
  binaries, which is exactly the "measured identically on the ORACLE" claim their
  headers make.
* e2e stage-2 sweep, all 274 `tests/e2e/slice_*.c` — **8 differ: 7 added here, and
  `slice_multi_lib.c`, a deliberately CQ.h-free helper TU whose `#error` tripwire
  fires under the sweep's force-include, identically on both binaries.**
  **0 pre-existing slices moved.**
* `tools/golden_multiset_audit.py --all` — **290 goldens: 10 NEW-FILE, 280
  UNCHANGED, 0 routes collapsed. PASS.** Re-run after the round-1 review: **292
  goldens, 12 NEW-FILE, 280 UNCHANGED, 0 routes collapsed, PASS** — the two extra
  NEW-FILEs are the O(K)-leak pair, and **the 280 UNCHANGED is the load-bearing
  number: not one existing golden moved in either round.**
* `tools/free_pairing_check_test.py` — 69 named + 313 proof-targeted mutants,
  **0 failures** (re-run after the round-1 review: 26 positive fixtures, 2
  free-order pairs, 1 cost bound, 69 named mutants, 5 Case-A negatives, 313
  proof-targeted mutants, **0 failures**).
* `tools/loop_twin_matrix_quarantine_test.py` (NEW, round-1 review) — the
  quarantine's own mutant validation: **7 cases, 0 failures**, 0.2 s, no
  clang/opt/plugin. Registered as ctest `e2e-loop-twin-quarantine-selftest`.
  **After the round-2 review (§12): 12 cases, 0 failures** — the five added ones
  drive `--regenerate` / `--refresh-quarantine`, the two modes round 2 found
  untested and defective (F-R2-1, F-R2-2), and three of them assert on FILE
  BYTES rather than on the exit code, because F-R2-1 was a refusal that exited 1
  while writing the forbidden verdict to disk. Red-green witness: re-run against
  a copy of the script mutated back to the pre-fix ordering and exactly those
  three go red (`NEG-7`, `NEG-8`, `NEG-9`), with the other nine unmoved.
* `tools/control_flag_order_check.py` — **1459** files, 407 control flags, **0
  violations** (corrected: the tool prints the FILE count, and 1458 was lit's
  PASSED count — round-1 lens L7-5. Re-run after the review: see §11).
* `tools/inplace_twin_matrix.py --route-oracle <pre-2a f92d95e>` — see §7a.
* `tools/loop_twin_matrix.py` — **273 cells; 76 Ry-axis rows regenerated, 0 of the
  156 pre-Inc-3 rows moved; RED on 15 cells (§10.1)** at hand-back. **After the
  round-1 review the gate is GREEN**: the 15 cells moved OUT of `expected.txt`
  (258 rows) and INTO `tools/loop_twin_matrix.quarantine.txt` (15 cells) with
  their exact unified-diff signatures pinned, plus two boundary controls that run
  on every invocation. See §11.1 / L7-1 / L7-2. **"On every invocation" became
  TRUE only in round 2** (§12, F-R2-2): as first written the controls sat below
  both write modes' early returns, so `--regenerate` and `--refresh-quarantine`
  never ran them and exited 0 with a control diverging.
* **FULL `ctest --test-dir build -j6 --output-on-failure` — 319/320 passed, 476.7 s
  wall (1253 s user; the box carried other sessions at load 17–190, so this is a
  LOADED figure and is not comparable to CLAUDE.md's 130–230 s quiet-box band).**
  The single failure is `e2e-loop-twin-matrix`, **re-run SERIALLY and reproduced
  exactly** (200.5 s, 15 trace divergences + the 15 deliberately-restored verdict
  rows, nothing else) — deterministic, not contention.
  **AFTER THE ROUND-1 REVIEW: 324/324 passed, 528.03 s wall (1265 s user, 276 %
  CPU), again on a box carrying concurrent agent sessions (load 5–114 across the
  run) — a LOADED figure, not comparable to the quiet-box band. `e2e-loop-twin-matrix`
  alone took 450.19 s in that run and 233.12 s when run on its own earlier the same
  day; both are load figures, and neither is the ~120–150 s the gate costs quiet.**
* K-independence, `slice_control_inplace_ry_loop_grover.c` — **74 lines of lowered
  IR at `-DCQ_K=3` and 74 at `-DCQ_K=1000`**, the two modules differing only in the
  trip constant; trace 36 → 10006 lines.
* `cmake --build build --target cq-opt-equivalence-full` — **1459 fixtures
  compared, 0 mismatches** at hand-back; **1473 compared, 0 mismatches** after the
  round-1 review.
* per-layer ctest: `runtime` **7/7**, `frontend-lit` **1/1**, the 15 new
  `inplace-ry-loop` entries **15/15**.

### 7a. `tools/inplace_twin_matrix.py` — what it did and did NOT claim here

Run as `--jobs 6 --route-oracle <pre-2a f92d95e cq-opt>`, after fixing the
pre-existing arity bug (§10.4) that had made every `--route-oracle` run die before
classifying a cell. **472 cells: 287 PREFIX-IDENTICAL, 104 DECLINE-BOTH, 5
DECLINE-BOTH-DIFF, 42 RY-ONLY, 34 RZ-ONLY; Rz half 321 RZ-COLLAPSE-ONLY, 123
RZ-DECLINE-BOTH, 1 RZ-DECLINE-DIFF, 27 RZ-DISPOSITION-MOVED.**

**READ THAT TALLY FOR WHAT IT IS.** The oracle is `f92d95e` — PRE-2a — so the
dispositions it reports as "moved" are the union of Inc 2a, Inc 2b AND Inc 3, and
the tally is **not by itself an Inc-3 delta**. Producing one would need the same
matrix run with the pre-Inc-3 binary as the SUBJECT and the same pre-2a oracle,
then a diff of the two tallies; on a box carrying other sessions each run is ~20
minutes and I did not spend a second one. **The Inc-3 no-flat-movement claim rests
instead on three stronger and cheaper witnesses that cover real programs rather
than 472 synthesized cells: the whole-corpus lit sweep (0 of 1430 pre-existing
fixtures moved), the e2e stage-2 sweep (0 of 267 pre-existing slices moved), and
`golden_multiset_audit.py --all` (280 UNCHANGED, 0 routes collapsed).**

> ⚠ **THE RUN I DECLINED TO DO WAS DONE BY LENS L7, AND IT CONTRADICTS THE
> HEADLINE OF THIS SECTION (L7-6, DOC-FALSE).** L7 built a shadow `--root` whose
> `cq-opt` symlinks to the pre-Inc-3 binary and everything else to HEAD's, and ran
> the same 472-cell matrix against the same pre-2a route oracle for BOTH subjects.
> Both runs completed. HEAD reproduces §7a's tally exactly (287 / 104 / 5 / 42 / 34;
> Rz half 321 / 123 / 1 / 27), which confirms the tally is a real classification —
> **and the PRE-3 subject differs in exactly 15 cells**:
> `DECLINE-BOTH → RY-ONLY(suspicious)`, every one a `*_printf_*` cell (a
> controlled-Ry arm plus a 7.6 output-tape write on the ROTATED register).
> So **Inc 3's delta on the FLAT twin matrix is 15 flat programs moving from a loud
> decline to an accept**, and "no flat movement" was false as a blanket claim. The
> three witnesses above are still true of what they measure — the lit corpus, the
> e2e slices and the goldens contained NO program of that shape, which is why none
> of the three could see it. That is the lesson, not the tally: **three sweeps over
> corpora that lack the shape are not evidence about the shape.**
>
> **DISPOSITION: KEEP THE ACCEPTS.** The first fix agent measured the question this
> round turns on — is taping an unmeasured superposed rail an Inc-3 widening or a
> pre-existing property? — on the ORACLE, and the answer is (a): a tape write of a
> rotated-but-unmeasured register with **no control flow at all** ACCEPTS on the
> pre-Inc-3 binary. The guard that actually decides is TERMINALITY (a CONTINUED
> lineage after the tape write declines on both binaries). So the 15 cells are the
> pre-existing flat accept class meeting a register the Ry arm can now rotate, not a
> new licence — pinned red-green by `control_inplace_ry_tape_after_region.ll`
> (accept) and `control_inplace_ry_reject_tape_continued.ll` (decline). The Rz-stem
> "continued lineage" artifact L7 noticed alongside is filed separately as bd
> `test_C_libtooling-j2ac`. What remains open is the 7.6 owner's question, not a
> lowering fence.

An earlier
run of this instrument with the PRE-3 binary as the route oracle is recorded in
the scratch log and is **meaningless by construction** — a post-2a oracle has no
routes to collapse, so `reduce_routes` finds zero and every cell reports
`PREFIX-MISMATCH … collapsed routes 0`. That is the failure mode the tool's own
header warns about, met from the other side.

## 8. Walker audit — `LoopLowering.cpp`, re-derived

**Headline, re-checked at this commit: `LoopLowering.cpp` contains NO name test on
`cqrt_ry_`, `cqrt_rz_` or `_controlled`, at any site** (`grep -n 'cqrt_' ir-pass/src/LoopLowering.cpp`
returns only the `kMsg*` strings and the `cqrt_{addc,xorc}` prose). Both loop
rounds run strictly before `lowerRotations`, so their vocabulary is always the
front-end `@cq_theta_` / `@cq_phi_` spelling with the wire at arg 0 — which is
exactly what hoist-and-defer preserves.

| site | test | sees a HOISTED controlled gate in a loop? |
|---|---|---|
| `isHoistedRegionArmGate` | `ControlledRotations` ∧ `cq_phi_` | **Rz: yes** (round 2 only). **Ry: NO, deliberately** — M-β removes the need, and the site comment now says the obligation was discharged by mechanism |
| `collectRailGates::noteGate` | `cq_theta_` ∧ `GateCalls` | **YES, round 2 — the hoisted Ry IS a gate, which is correct and is the whole point** |
| `peelInPlaceStep` / `peelInPlaceBase` | via `GateCalls` | **YES, round 2 — under M-β the hoisted theta is a PEEL STEP, which is the mechanism** |
| `isInPlaceGateOnArg0` | `GateCalls` ∧ arg-0 | **YES, round 2, both stems** |
| `railPhiRootMint` (NEW) | `GateCalls` + untainted arg-0 + dominance | **round 2 AND detection** — one body, two callers |
| `isMeasureCall`, `breakLineageCarriesPhase`, `inPlaceValueRailOperand`, `railValueConsumerDisposition` | — | n/a for this class |

## 9. What worries me

1. **The twin matrix is red and I could not resolve it inside this increment.**
   §10. I root-caused both classes and proved both pre-existing with controls on
   the oracle binary, which is as far as an implementer can honestly go — but a
   red gate is a red gate, and the increment does not ship green.
   > **RESOLVED BY THE ROUND-1 REVIEW (§11, lens L7) — WITHOUT BLESSING THE
   > DIVERGENCE.** The 15 cells moved out of `expected.txt` and into
   > `tools/loop_twin_matrix.quarantine.txt`, each pinned to the SHA-256 digest of
   > its exact unified diff, with class / bd id / owning subsystem AND DIRECTION.
   > A quarantine fails in both directions — signature moved, or cell stopped
   > diverging — plus a cell in both files, plus any non-quarantined divergence.
   > The gate is GREEN; the finding is unchanged and now bd-tracked as
   > `test_C_libtooling-1m5p` / `test_C_libtooling-a3z7`.
2. **The O(K) freeze leak is ARGUED, NOT MEASURED.** §5. No shipped slice reads
   the rotated register inside the body, so the "K rails at run time" claim in
   §13.5 has no witness here. I could not construct one that also survives R6 and
   `declineStaleRecordOps`; I did not prove one does not exist.
   > **DISCHARGED BY THE ROUND-1 REVIEW (§11, lens L3 Q1).** One does exist: read
   > the rotated register **BEFORE** the region in the same body. Committed as
   > `tests/e2e/slice_control_inplace_ry_loop_leak.c` + its twin + the
   > `e2e-inplace-ry-loop-leak-twin-identical` gate. 2 template rails per
   > activation, never freed; twin byte-identical; strict 2b blind. §5 updated.
3. **The acyclic P1 sweep found nothing, and that is weak evidence, not strong.**
   Zero pre-existing fixtures had the shape. The clause's real witness is the one
   red-green pair I wrote, and I wrote both halves — the same person choosing the
   probe and the answer. Lens 8 should re-probe the boundary independently.
   > **IT DID (§11, F-L8-2), 29 independent plain-C probes on both binaries: no
   > confirmed miscompile and no confirmed over-accept, 14 oracle-DECLINE →
   > HEAD-ACCEPT flips all linked, run and 2b-clean — and a real Rule-12 gap.** The
   > clause admits at least SEVEN structurally distinct acyclic classes and shipped
   > with a fixture for one. Two of them are now pinned (derived condition, negated
   > polarity); the two-exit rolled loop is pinned too. The worry was correct and
   > the answer is coverage, not a fence.
4. **I wrote TWO decline fixtures that did not decline**, and both times the reason
   was the same: `findNonDiagonalWireGate` EXEMPTS gates on the compare's own
   ancestry, so "a `cq_theta` before the compare" is not automatically a
   `DeclineNow` shape. Caught because the P1 widening turned them green. Nothing
   guarantees I did not make the mirror-image mistake somewhere — write a fixture
   that declines for a reason other than the one its header claims. The mutation
   table (§6) is the only defence and it is per-clause, not per-fixture.
5. **`recordLivePerActivation` asks about the region's OWN branch and nothing
   else.** A post-region gate between the record and a sunk read is caught only by
   `LoopLowering` round 2, which runs only when `InLoopFlattenedPreds` is non-empty
   AND `collapseRailPhisIn` claims the loop. Clause (b′) now makes an unclaimed
   loop decline at detection, which narrows that gap a lot — but I did not prove it
   closes it.
6. **M-β's safety rests on "the lowered IR is byte-identical after
   `lowerRotations`", and I verified that by SWEEP, not by proof.** The sweep is
   strong (1458 + 274 programs, 0 pre-existing movement), and it is still a
   statement about the corpus rather than about the mechanism.
7. **The `ifelse` accept is hand-IR only and always will be from C** (SimplifyCFG
   makes it an angle select). So the M-β CHAIN — the part that needs two gates — is
   witnessed by exactly one lit fixture and no e2e slice. If the chain rule breaks,
   only that fixture says so.
8. **I could not construct row L-c as the PRD described it.** A genuine
   `flatRegionRollableInLoop` (B) failure for a flat diamond appears to be
   unreachable (§13.2 correction). The fixture I shipped pins a real nested-loop
   decline, at a different clause. So gate (B) has no Ry-family fixture at all — it
   is covered only by the pre-existing Rz ones.
9. **I did not measure the cost of clause (b′)'s `GateCalls` rebuild.** It is
   constructed per in-loop rotation-arm region rather than once per module. In-loop
   rotation-arm regions are rare, so this is almost certainly noise — but "almost
   certainly" is not a measurement.

## 10. Findings made while building

### 10.1 THE HEADLINE — `e2e-loop-twin-matrix` is RED on 15 cells, and both classes are PRE-EXISTING

> **STATUS AFTER THE ROUND-1 REVIEW (§11, lens L7): the gate is GREEN and the
> finding is unchanged.** The 15 cells are no longer in `expected.txt`; they are
> in `tools/loop_twin_matrix.quarantine.txt`, pinned to the SHA-256 digest of the
> exact unified diff of their two traces, with class / bd id / owning subsystem
> AND DIRECTION. A quarantine is NOT a blessing: the gate fails if the signature
> CHANGES, if the cell STOPS diverging ("quarantine stale — remove it"), if a cell
> appears in both files, and — unchanged — on any non-quarantined divergence. Two
> boundary controls run beside the cells on every invocation (no region ⇒
> identical; arm ON the condition register ⇒ identical), which is the pair of
> measurements this section's class story rests on. bd `test_C_libtooling-1m5p`
> (class A) / `test_C_libtooling-a3z7` (class B). Everything below stands as
> written; read it as the defect report the quarantine points at.

**The instrument is `tools/loop_twin_matrix.py`** (ctest entry `e2e-loop-twin-matrix`),
not `inplace_twin_matrix.py`. Its oracle is **the hand-unrolled twin compiled by the
SAME binary** — it is a self-consistency gate, so "run the same cells on the
pre-Inc-3 oracle" is not the available experiment: on that binary these 15 cells'
ROLLED side DECLINES `control flow inside a loop body`, which IS their committed
`UNROLLED-ONLY` verdict. **The control that IS available, and the one that proves
the point, is the same program with the ARM changed from `cq_theta` (Ry) to
`cq_phi` (Rz)** — a shape the pre-Inc-3 binary lowers rolled. Run for both classes;
the resulting rolled-vs-unrolled diff is **character-for-character identical** to
the Ry cell's diff at HEAD.

```
CLASS A  Rz control on the ORACLE          |  the Ry cell at HEAD
-cq_template_fadd_f64_hl_unc(h3,h2,3.0)    |  -cq_template_fadd_f64_hl_unc(h3,h2,3.0)
-cqrt_free(h3)                             |  -cqrt_free(h3)
-cq_template_sitofp_i32_to_f64_unc(h2,h0)  |  -cq_template_sitofp_i32_to_f64_unc(h2,h0)
-cqrt_free(h2)                             |  -cqrt_free(h2)
+cq_template_sqrt_f64_unc(h4, h3)          |  +cq_template_sqrt_f64_unc(h4, h3)
+cqrt_free(h4)                             |  +cqrt_free(h4)
+cq_template_fadd_f64_hl_unc(h3,h2,3.0)    |  +cq_template_fadd_f64_hl_unc(h3,h2,3.0)
+cqrt_free(h3)                             |  +cqrt_free(h3)
+cq_template_sitofp_i32_to_f64_unc(h2,h0)  |  +cq_template_sitofp_i32_to_f64_unc(h2,h0)
+cqrt_free(h2)                             |  +cqrt_free(h2)

CLASS B  Rz control on the ORACLE          |  the Ry cell at HEAD
-cqrt_addc_i32(h0, 3)                      |  -cqrt_addc_i32(h0, 3)
-cqrt_measure_i32(h0) -> 0                 |  -cqrt_measure_i32(h0) -> 0
+cq_template_add_i32_hl(h0, 3) -> h10      |  +cq_template_add_i32_hl(h0, 3) -> h10
+cqrt_measure_i32(h10) -> 0                |  +cqrt_measure_i32(h10) -> 0
```

**Representative reproducer** (class A; swap the arm for `r = cq_phi(r, 0.9)` and
compile the pair with `scratchpad/wt/pre3/build/ir-pass/libCQPass.so` to see the
identical divergence on the pre-Inc-3 binary):

```c
#include <math.h>
volatile int off = 3;
int slice(void){
    int a = 0; int r = 0;
    a = cq_theta(a, 0.5);
    r = cq_theta(r, 0.3);
    for (int i = 0; i < 2; ++i) {
        if (sqrt(a + 3.) <= (double)off) { r = cq_theta(r, 0.9); }   /* Rz control: cq_phi */
    }
    return cq_measure(a) + cq_measure(r);
}
```

**A THIRD control fixes the boundary:** with **NO REGION AT ALL** (just
`a = a + off;` in the body) the rolled and unrolled sides AGREE on the oracle. So
the divergence needs the region present AND the arm off the condition register —
which is exactly why no pre-Inc-3 matrix cell exhibits it, and why this axis is
where it surfaces.

The Ry axis is the **first place in the matrix where the ARM ROTATES A REGISTER THE
CONDITION DOES NOT READ**. That one property makes `a` loop-invariant in bodies
with no a-register gate, and `clang -O1` then treats the rolled and flat spellings
differently in two ways that have nothing to do with the arm class. **Both were
reproduced byte-for-byte on the pre-Inc-3 ORACLE binary with an `Rz` arm.**

* **CLASS A — the hoisted loop-invariant derived chain (6 cells, `oder` with no
  a-gate).** LICM hoists the whole `sitofp; fadd; sqrt` chain into the preheader on
  the ROLLED side; CSE merges the two repetitions' chains on the FLAT side. The
  rolled form discharges the two INTERIOR rails immediately after the `sqrt` and
  **leaves the TOP rail (`h4`, entangled with `a`) allocated**; the flat form
  discharges all three at the end. Rule-6 safe and invisible to strict stage 2b
  (template-minted rails), but a genuinely different circuit — `a` stays dephased.
  **CONTROL: `if (sqrt(a+3.) <= (double)off) r = cq_phi(r, 0.9);` in the same loop
  diverges identically, line for line, on the oracle.**
* **CLASS B — the M-C in-place vs out-of-place trailing `a += off` (9 cells, any
  with `add` in the a-gate suffix).** Rolled emits `cqrt_addc_i32(h0, 3)` and
  measures `h0`; flat emits `cq_template_add_i32_hl(h0, 3) -> h10` and measures
  `h10`. Same value, same `_unc`/free counts, one extra rail on the flat side: the
  rolled add is a chain member that `collapseRailPhisIn` step (3) MARKS in place,
  the flat one is straight-line and M-C's G6/G7 decide. **CONTROLS: identical
  divergence on the oracle with an `Rz` arm on `r`; and with NO REGION AT ALL the
  two sides AGREE**, so it needs the region present and the arm off the condition
  register.

Neither is in this increment's scope to fix — class A is `Uncomputation`'s interior
placement for a chain the loop does not own, class B is `ArithLowering`'s M-C
decision versus the round-2 marking — and both would move shipped Rz goldens. **The
15 rows were therefore RESTORED to their pre-Inc-3 verdicts rather than
regenerated**, so the table never records a `TRACE-DIVERGENCE` as an expected
outcome and the gate stays red on exactly the finding. `tools/loop_twin_matrix.expected.txt`
carries the full list and both controls in its header.

### 10.2 A NEW DISPOSITION MISMATCH, created by §13.4b, and it is a safe over-decline

`m_ry_rzry_none_none_none` was `DECLINE-BOTH`; it is now `UNROLLED-ONLY`. The
program is `for(){ a = Ry(a,.25); if (a==5) a = Rz(a,PI); if (a==6) r = Ry(r,.9); }`.
On the FLAT side the *next repetition's* `a = Ry(a,.25)` is provably after region 2,
so `condWireDisposition` returns `ProvenPostRegion` and P1 now accepts. On the
ROLLED side that same theta is reached around the BACK EDGE, and
`condWireDisposition` uses flat `provablyBefore`, whose reachability conjunct every
back edge falsifies ⇒ `DeclineNow`. **An over-decline on the rolled side, safe, and
deliberately not fixed**: giving `condWireDisposition` a per-activation reading is a
sibling-spelling change to a predicate shared by four callers (this path, the 4.4
select's gate 2c, 2b's S6, `RegionTreeDetect`'s nest) — §13.10 Q1 / `drbq.12`
territory, and bd [[sibling-predicate-spelling-is-the-hole]] is precisely about one
of four being spelled differently.

Four more cells (`*_rpostmark_rypost`) keep their `UNROLLED-ONLY` disposition and
change only their ROLLED message, from the R7 blanket to `cq loop lowering: rail
record read past an in-place gate on the same rail` — the shape now gets past R7 and
is refused by the loop's own rail-record fence, which is a more specific and more
accurate owner.

### 10.3 Four PRD claims falsified by measurement — all corrected in place

1. **§13.2c's predicted probe message.** The mandatory row-DB probe was run FIRST,
   with R7 lifted and nothing else. It did **not** accept — no over-accept, the
   increment proceeded — but it declined `stale rail record read past a controlled
   Ry` on R6's FLAT predicates, not `tainted value muxed by a classical-condition
   phi`. The predicted message describes the increment MINUS clause (b′), not the
   R7-only probe. Disposition unchanged and shipped as designed.
2. **§13.2 row R4's diagnostic.** Predicted `rotation arm on a condition wire`;
   measured `condition predates a non-diagonal gate`, because `declineArm` re-spells
   every later decline once `condWireDisposition` returned `ProvenPostRegion` — which
   the arm's own theta on the condition wire always is. **The FLAT sibling prints the
   same string**, so it is pre-existing; it is §13.11 worry 2 met in the field.
3. **§13.2 row L-c's owner.** Gates (A)–(D) all PASS for the inner loop; the refusal
   is clause (b′) (the inner header φ's external incoming is the OUTER header φ, and
   `peelInPlaceBase` stops at a φ). A genuine (B) failure for a flat diamond appears
   to be unconstructible — see §9 item 8.
4. **§13.4b's blast radius.** Predicted acyclic flips needing individual accounting;
   measured **exactly one**, and it is the clause's own new fixture.

Also corrected: **§13.8's `derived_cond` guidance.** "Use a SATISFIABLE predicate"
is necessary and not sufficient. `q*3 == 6` is satisfiable and `clang -O1` still
folds it to `icmp eq i32 %q, 2`, deleting the `mul` — so the C slice would have
tested a DIRECT condition while claiming a derived one. The shipped slice uses
`(q & 6) == 4`, which survives as a real `and` + `icmp`. The hand-IR lit fixture is
unaffected and its output was checked to contain `cq_template_mul_i32_hl`.

### 10.4 A pre-existing harness bug that made one of the four required instruments unrunnable

`tools/inplace_twin_matrix.py:835` unpacked FOUR values from
`golden_multiset_audit.reduce_routes`, which returns FIVE (it gained
`n_negated_arms` at `24bb42d`, the same commit that last touched the consumer). So
**every `--route-oracle` run has died with `ValueError: too many values to unpack`
before classifying a single cell** since that commit. Verified pre-existing:
`git diff 1bdaa60 -- tools/inplace_twin_matrix.py tools/golden_multiset_audit.py`
is empty. Fixed here, with the history at the site. The sibling call at `:795`
already used `[0]` and was never affected, which is why nothing noticed.

### 10.5 Two decline fixtures I wrote did not decline

Both `..._reject_post_region_theta_stalecond.ll` and
`..._reject_inloop_stalecond.ll` were first written with the staling gate as
`%q1 = cq_theta(%q, .1)` and the compare on `%q1` — which puts the gate ON THE
COMPARE'S OWN ANCESTRY, and `findNonDiagonalWireGate` exempts those by design (they
PRODUCE the record; they cannot stale it). Both shapes are correct ACCEPTS and
accepted before this increment too. Rewritten as SIBLING aliases off `%q`. Recorded
in both fixture headers, because the mistake is easy and the fixture looked right.

---

## 11. ROUND-1 ADVERSARIAL REVIEW (Rule 13) — every finding, graded, with its fix and its red-green evidence

Eight lenses (L1–L8), each compiling its probes on **both** binaries (HEAD = the
working tree; ORACLE = `scratchpad/wt/pre3/build/ir-pass/cq-opt`).

**HEADLINE: no lens found a CONFIRMED MISCOMPILE, a CONFIRMED OVER-ACCEPT or a
crash attributable to this increment.** What the round produced is one
CONFIRMED-OVER-DECLINE that is PRE-EXISTING and flat (L2-F1), one CONFIRMED FLAT
ACCEPT WIDENING that was undocumented (L7-6), one disabled assertion in a shipped
fixture (F-L6-1), a weak-pin family (F-L6-2), five DOC-FALSE / DOC-IMPRECISE
statements, and a Rule-12 coverage gap (F-L8-2). Every one is addressed below.
That is a good outcome and it is **not** evidence that the next round will be
quiet: CLAUDE.md's own record for this machinery is 4-for-4 on rounds that found
something, and three of this increment's own fences exist because an earlier round
found their absence.

### 11.1 The findings

| # | lens | grade | finding | fix |
|---|---|---|---|---|
| F-L5-1 | L5 | CONFIRMED-OVER-DECLINE + DOC-FALSE | M-β broke `liftOneRegisterMergePhi` for a classical join φ over the rotated register | `resolveWireBase` now STOPS at a `ControlledRotations` gate. 3 new accepts + 1 decline; mutation M-A1 reds exactly the 2 accepts. **The repaired over-decline was PRE-EXISTING, not an Inc-3 regression** |
| F-L5-2 | L5 | CONFIRMED accept-class widening (flat) | `lowerIOSinks` accepts a tape write the oracle declines | **MEASURED on the oracle: answer (a) — taping an unmeasured superposed rail with NO control flow already ACCEPTS there; the live guard is TERMINALITY.** Accept KEPT, pinned red-green by `control_inplace_ry_tape_after_region.ll` / `..._reject_tape_continued.ll`. Rz-stem artifact → bd `test_C_libtooling-j2ac` |
| L7-1 / L7-2 | L7 | LEAK, pre-existing, not a miscompile | the 15 trace-divergence cells: class A (rolled strands an ENTANGLED `sqrt` rail) and class B (FLAT strands `h0`) | **PINNED-SIGNATURE QUARANTINE** (`tools/loop_twin_matrix.quarantine.txt`), 15 cells, class + bd + owner + DIRECTION + exact unified-diff digest; the 15 rows are OUT of `expected.txt`; **the gate is GREEN again and fails in both directions** — proved by `tools/loop_twin_matrix_quarantine_test.py` (ctest `e2e-loop-twin-quarantine-selftest`), which stubs the cell results and asserts all four failure modes plus an unknown-cell entry and a moved boundary control against a passing control: **7 cases, 0 failures, 0.2 s, no clang/opt/plugin**. bd `test_C_libtooling-1m5p` (A) / `test_C_libtooling-a3z7` (B) |
| L7-4 | L7 | doc gap | §13.8 predicted 3 `ry`-prefix cells "most likely stay"; 2 flipped to ACCEPT-IDENTICAL (sound, streams inspected) and 1 is the §10.2 mismatch | §13.8 CORRECTED in place |
| L7-6 | L7 | DOC-FALSE on §7a | the flat twin matrix moved 15 `*_printf_*` cells `DECLINE-BOTH → RY-ONLY` | §7a corrected: the three sweeps could not see the shape because none of the three corpora contains it. Disposition = keep (see F-L5-2) |
| L7-5 | L7 | cosmetic | §7 said `control_flag_order_check.py` swept 1458 files; the tool prints 1459 (1458 is lit's PASSED count) | counts re-measured wholesale in §7 |
| F-L6-1 | L6 | DISABLED CHECK, mutant-confirmed | trailing `CHECK-NOT`s scan only from the last positive match to EOF, so a `cqrt_cswap` injected into the LOOP BODY left `control_inplace_ry_inloop_diamond.ll` GREEN while its header claimed "anywhere in the module" | **5 fixtures converted to the whole-file `NOROUTE` prefix**; injection re-run: the `cqrt_cswap` mutant now reds all 5 (`NOROUTE=1`) |
| F-L6-2 | L6 | WEAK PIN ×3 | the three CFG-gate decline fixtures also carried a `premark` stale read that R6 refuses independently | exit-block read moved to the POST-region value in all three; **mutation-verified**, see §11.2 |
| F-L8-1 | L8 | DOC-FALSE, pre-existing | "the residual has been owned since bd `lyyf` by M-A's `warnLiveRecordRotations`" is false for an ESCAPING condition record (stderr EMPTY) | struck in PRD §13.4b, notes §4, the fixture header AND `ArmClassify.cpp`; the ORDER argument (measured) is what makes P1 safe. drbq.7's other half recorded as untouched |
| F-L8-2 | L8 | Rule-12 coverage | the P1 widening shipped ONE flat accept fixture (direct `icmp eq`) while admitting ≥7 structurally distinct acyclic classes | 2 new accept fixtures — derived condition and negated polarity — the two the lens named as its minimum. The two-exit rolled loop is pinned too (`control_inplace_ry_inloop_two_exits.ll`) |
| L2-F1 | L2 | CONFIRMED-OVER-ACCEPT, **flat, pre-existing** | the FLAT twin of `*_rpostmark_rypost` accepts and measures a stale record; byte-identical on the ORACLE | **NOT fixed here** — it is the Inc-1 flat path (bd `0njv` / the F-1 class) and needs its own owner. Recorded so that the `UNROLLED-ONLY` row is never "fixed" by relaxing the roll |
| L2-F2 | L2 | DOC-IMPRECISE | "`T` is a chain MEMBER, so it is in the SKIP set" holds only when `T`'s result is CARRIED | narrowed at BOTH sites (`SwapRouteEmit`, `isHoistedRegionArmGate`) |
| L3-2 | L3 | DOC-IMPRECISE | notes §5's "zero M-A warnings on either side (symmetric)" reads as a general claim; the warning is PER STATIC GATE (1 rolled vs 2 flat at K=2) | §5 corrected; the asymmetry is documented at the new slice pair's registration |
| L3-8 | L3 | witness gap (new) | a rotated register DEAD after the loop accepts ROLLED and its flat twin does not exist (`-O1` drops the merge φ) | committed as a PAIR — `control_inplace_ry_inloop_rotated_dead.ll` (accept) / `..._reject_flat_rotated_dead.ll` (decline) — with the "no oracle for this shape" statement in both headers. bd `test_C_libtooling-rhwb` |
| L3-1 | L3 | RESOLVED (not a defect) | the O(K) freeze leak was ARGUED, not measured (§9 worry 2) | **MEASURED and committed**: `slice_control_inplace_ry_loop_leak.c` + twin + `cmp` gate; 2 template rails per activation, never freed, twin byte-identical, strict 2b blind |
| F-L4-1 | L4 | DOC-FALSE, pre-existing | the Kahn-cycle backstop cites `control_swap_reject_seq_in_loop.ll`, which was RENAMED **and flipped to ACCEPT** by 8h7d.5 — and flat regions on a cycle DO reach the plan | comment corrected; the narrower true claim (a cycle needs a 3-pred merge φ, which `soleMergePhi` refuses) kept |
| F-L4-2 | L4 | PLAUSIBLE, unreachable | `Prev == G.first` would mint self-referencing SSA and ABORT the verifier rather than decline | one-line loud decline added, matching the sibling `Cls != InPlaceRotation` posture |
| L5-Q3 | L5 | PLAUSIBLE → REFUTED | `phiTracksWire` counts only `cq_theta` stalers while `collectRailGates` also counts dtzb `add`/`xor`, and R6 uses it in the GRANTING direction | **constructed, 5 probes: not exploitable.** A frozen carry is its own user, so the phi-edge read-position rule refuses first; a non-frozen φ's wire reaches the arm theta, so the fence answers `false` anyway. Argument + RETIREMENT TRIGGER written at the call site, in `WireWalk.h` and in `control_inplace_ry_reject_inloop_frozen_dtzb_carry.ll` |
| L5-Q4 | L5 | DOC-FALSE | "a divergence between `railPhiRootMint`'s two callers is impossible by construction" is FALSE — the shared body covers the EXTERNAL-incoming half only | corrected in `LoopPlan.h` and `ArmClassify.cpp`; the `GateCalls` monotonicity argument (smaller vocabulary ⇒ earlier peel stop ⇒ decline) and its retirement trigger written at both |
| L1-Q2 | L1 | live divergence, safe direction | the in-loop certificate ACCEPTS a shape the flat pair DECLINES (dominance is the operative conjunct, and it is an over-decline in both) | committed as the PAIRED witness `..._reject_flat_cond_pre_measure.ll` / `..._inloop_cond_pre_measure.ll`, cross-referenced at BOTH `ArmClassify` R6 sites: the certificate is the GENERAL predicate, the flat pair a deliberately stronger LEGACY spelling, and widening it owes its own round |
| L1-Q1a | L1 | note | both `assert`s in `recordLivePerActivation` are no-ops in the Release build this project configures | recorded at the site: the early `return false` is the real refusal |
| L1-out-of-scope | L1 | PRE-EXISTING | a rail record read past an in-place `cq_theta` compiles when the consumer is a `cq_*` CALL rather than a pure op (`declineStaleRecordOps` covers pure ops only), with NO control flow anywhere | bd `test_C_libtooling-67s8`. It is also the reason the R6 refresh fence is KEPT although deleting it reds nothing — nothing downstream would catch this |

### 11.2 The gate mutations, re-run properly (F-L6-2)

Each gate of `flatRegionRollableInLoop` was disabled in turn, the plugin AND
`cq-opt` rebuilt, and the **whole corpus AS IT STOOD MID-ROUND — 1468 files**,
run — not just the three named files, which is what makes the result
interpretable. (Round-2 review: 1468 is the fourth corpus figure in this file —
1459 / 1468 / 1473 / 1474 — and it named no moment. **The moment is
"mid-round-1-review": after the hand-back 1459 and before the round-1 end state
1473**, i.e. with some but not all of the round's fourteen fixtures on disk.
WHICH nine is not recorded and cannot now be reconstructed, and nothing in the
table's reading depends on it — what the figure is there to say is that each
mutation was run over the WHOLE corpus rather than the three named files. The
current count is **1474**. If you re-run these mutations, quote the corpus you
actually ran.)

| mutation | corpus reds | reading |
|---|---|---|
| **(A)** `!L` → `return true` | `control_swap_reject_inloop_diamond_irreducible.ll` (the **Rz** sibling) | gate (A) **is pinned** — but NOT by the Ry fixture, which keeps declining with a byte-identical message because `L` is null all the way down to clause (b')/`LHdr`. The Ry file cannot ISOLATE it |
| **(C)** single-latch check deleted | `control_swap_reject_inloop_multilatch.ll` (the **Rz** sibling) | same shape, and the reason is STRUCTURAL: a multi-latch header rail φ has ≥3 incomings while `railPhiRootMint` requires exactly 2, so (C) is redundant with (b') for the Ry family — the same way (b)'s `!= LHdr` half is |
| **(D)** second-cycle walk deleted | `control_swap_reject_inloop_second_cycle.ll` **and** `control_inplace_ry_reject_inloop_second_cycle.ll` | gate (D) **is isolated by our own fixture** — and only since the premark read was removed; with it in place R6 refused first and the mutation changed nothing |

All three headers now state their measured result, including the two that say
"this file does not red on it". A fixture whose header claims a mutation result it
does not have is worse than no fixture (§10.5's lesson, applied to itself).

### 11.3 What the round did NOT clear

* **L2-F1** — the flat `*_rpostmark_rypost` over-accept. Pre-existing, Inc-1 path,
  needs an owner. Do not "resolve" the matrix row by relaxing the rolled side.
* **The two quarantined classes.** Root-caused, bd-tracked, reproduced by signature
  on the oracle with an Rz arm — and **still defects**. "Pre-existing" is true of
  the defect and FALSE of its population: all 15 shapes declined before Inc 3 and
  compile now, so this increment is a customer-adding change to a known-defective
  path.
* **bd `test_C_libtooling-67s8`** (the `cq_*`-call-consumer stale-record hole) and
  the `cq_invert` link-time failure (Phase 8 not implemented) — both measured
  identical on both binaries, both out of scope.
* **drbq.7's second half** (a rotated register gating a second region) — an
  over-decline this increment neither introduces nor fixes.

## 12. ROUND-2 ADVERSARIAL REVIEW (Rule 13) — the round that reviewed the round-1 FIXES

Two independent read-only reviewers on the working tree at `d44fe5b` + the
round-1 fixes, each compiling every probe on **both** binaries (HEAD; ORACLE =
the pre-Inc-3 `1bdaa60` build). R1 re-probed the five round-1 code changes; R2
audited the fixtures, the numbers and the two new instruments.

**HEADLINE: no CONFIRMED MISCOMPILE, no CONFIRMED OVER-ACCEPT, no crash, in
either reviewer's set.** What the round produced is one unpinned accept-class
flip (sound), one incomplete refutation argument, two MEDIUM defects in the
QUARANTINE INSTRUMENT — both of them doc-false claims that were also real
footguns — and two counting errors. Everything below is fixed in this commit
except the two items explicitly marked NOT FIXED.

**AND SAY THE UNCOMFORTABLE HALF FIRST.** Round 2 opened by finding
`ir-pass-lit` **RED** — three stray `*.head.ll` / `*.orc.ll` pass-output files
left in `ir-pass/test/` by a reviewer's own probe run, discovered by
`lit.cfg.py`'s `config.suffixes = [".ll"]` as three UNRESOLVED tests and
inflating `ls ir-pass/test/*.ll | wc -l` from 1473 to 1476. Twice. A review that
writes into the fixture directory can red the suite it is reviewing, and the
failure reads like a lowering regression. Probe outputs go in the scratchpad.

### 12.1 R1 — the five round-1 code changes, re-probed (15 probes)

| Q | subject | grade |
|---|---|---|
| Q1 | the F-L5-1 `ControlledRotations` stop in `resolveWireBase` | **CLEAN**, with one DOC/Rule-12 gap — see below |
| Q2 | the F-L5-2 tape decision | **CLEAN** — the oracle premise re-measured independently and it holds; four boundary probes (chained region, condition-register tape, in-loop tape) decline IDENTICALLY on both binaries. Two of them are refused by **R6**, one fence EARLIER than `lowerIOSinks`, which the notes did not say |
| Q3 | F-L4-2's `Prev == G.first` decline | **CLEAN** — doubly unreachable (`Gates` entries already passed `T->getParent() != A.BB`, and one `CallInst` has one parent), message and anchor family-consistent |
| Q4 | the L5-Q3 `phiTracksWire` dtzb refutation | **PLAUSIBLE / DOC-IMPRECISE** — see 12.2 |
| Q5 | `control_inplace_ry_inloop_two_exits.ll` | **CLEAN** — linked and RUN: flag stripped+freed per activation on BOTH exit paths, `%h1` frozen (no `_unc`, no `cqrt_free`) on both, one free site, STRICT stage 2b clean |

**Q1(c) — the flip nobody pinned, FIXED HERE.** The F-L5-1 stop was documented as
an **Ry** story. It is not: `AngleSelectEmit.cpp` records its consumer in
`taint.ControlledRotations` for **BOTH stems** with no stem test, so an **Rz**
angle select followed by the 5j5 lift ALSO flips ORACLE-decline → HEAD-accept.
R1 measured it (`ORACLE: cq taint escape: tainted value muxed by a
classical-condition phi` → `HEAD: exit 0`) and graded the emitted stream CLEAN —
diagonal, one handle throughout, the classical `if` keeps its own block so the
lifted `Rz` still fires on one path. The Rz **phase REGION** + lift does NOT flip
(byte-identical lowered IR on both binaries), because the §6a peephole RAUWs the
merge φ to the base and the recorded `cq_phi` never enters a `WireChain`. **FIX:
`ir-pass/test/control_angle_select_rz_lifted_phi_after_select.ll`**, R1's own
ready module committed unchanged, mutation-pinned four ways (stem swap, flattened
`br`, `cqrt_cswap` injected at the entry AND at the last block — the F-L6-1 trap).

### 12.2 Q4 — the refutation is right and its BOUNDARY was not measured (comment-only fix)

The L5-Q3 refutation has two legs: (1) a frozen carry is its own user, so R6's
phi-edge read-position rule refuses first; (2) any NON-frozen φ on the wire has an
incoming whose closure reaches the arm `cq_theta`, so `thetaOnPathTo` answers
`false`. R1 built the construction neither leg covers — a NON-frozen carry seeded
from the region's MERGE value, the dtzb `add` AFTER the region on the sibling
chain, the carry read IN THE BODY so R6's path conjunct is satisfiable — and it
**declines**, so there is no defect. But it is refused by a **THIRD** fence the
argument never names: `LoopLowering::collapseRailPhisIn` step (1)'s loop-carried
guard (`kMsgCrossIter`, "cq loop lowering: loop-carried tainted value crosses
iterations"). **FIX: the RETIREMENT TRIGGER now names all three ways**, at all
three sites that must move together (`WireWalk.h`'s declaration,
`ArmClassify::recordLivePerActivation`'s call site, and
`control_inplace_ry_reject_inloop_frozen_dtzb_carry.ll`'s header). No code
change: the shape declines on both binaries.

### 12.3 R2 — the QUARANTINE instrument, audited claim by claim

R2 hand-ran the quarantine's seven claims against a stubbed pool. Five hold as
written — a changed signature FAILS, a stale quarantine FAILS, an
un-quarantined divergence FAILS, `--refresh-quarantine` can neither add nor
remove a cell, and the digest really does cover the FULL unified diff (the same
differing content moved four lines changes it). Two did not:

* **F-R2-1 (MEDIUM) — `--regenerate` wrote the forbidden verdict and then called
  itself a refusal.** The table was written FIRST and `blocking` computed after,
  so a run with a live un-quarantined divergence exited 1 with
  `m_b TRACE-DIVERGENCE` **on disk** — the exact verdict `EXPECTED_HEADER` and the
  quarantine header both say may never appear there — under a message reading
  "REGENERATION REFUSED TO HIDE 1 HARD FAILURE(S)". A poisoned table could then be
  committed by someone who fixed the *other* red first. **FIX: compute `blocking`
  first and write only when it is empty; the message now says the file is
  UNCHANGED, and it is.**
* **F-R2-2 (MEDIUM) — the two boundary controls did NOT run on every invocation.**
  `main()` returned inside `--refresh-quarantine` and `--regenerate` BEFORE the
  control loop, so both write modes exited **0** with a control diverging. That is
  backwards in the sharpest possible way: `--refresh-quarantine` is the one
  operation that RE-PINS a defect, and it was the one operation that never
  consulted the measurements the quarantine's class story rests on. Four prose
  sites claimed otherwise verbatim (the quarantine file header, the module
  docstring, the `QUARANTINE_CONTROLS` comment, CLAUDE.md's in-loop paragraph).
  **FIX: `run_boundary_controls()` extracted and called ABOVE every mode's early
  return; `--regenerate` folds the control failures into `blocking`, and
  `--refresh-quarantine` refuses outright and leaves the file byte-unchanged.**
  All four prose sites are now true, and two of them say *including the write
  modes* so the claim is checkable.
* **F-R2-3 (LOW) — a hand-added header paragraph is silently destroyed.**
  `write_quarantine` emits `QUARANTINE_HEADER` verbatim and re-sorts the blocks,
  while the file's own "TO ADD A CELL" instruction tells you to hand-edit and then
  `--refresh-quarantine`. Harmless today (the constant and the file agree
  byte-for-byte) and a trap for the next person. **FIX (documentation, the cheaper
  option): the file header now says it is SCRIPT-OWNED and that a new class
  paragraph goes in `QUARANTINE_HEADER`.**
* **F-R2-4 (LOW) — the selftest's own count was stale and its coverage had a hole
  exactly where the two defects were.** Its header said "the four claims" above
  six NEG cases, and neither `--regenerate` nor `--refresh-quarantine` was
  exercised at all. **FIX: 12 cases (was 7).** The five new ones drive both write
  modes, and **three assert on FILE BYTES** rather than the exit code — because
  F-R2-1 exited 1 the whole time it was writing. `POS-3` exists so that "refuse to
  write" cannot degenerate into "never write". Red-green: against a copy of the
  script mutated back to the pre-fix ordering, exactly `NEG-7`/`NEG-8`/`NEG-9` go
  red, reproducing R2's measured symptoms (regen exit 0 with a moved control;
  refresh re-pinning against one).

**The counting errors, both fixed above:** the §7 whole-corpus sweep was **24
differ = 18 accept-flips + 6 message changes**, not 23 = 17 + 6 — the sweep
predated the round's last fixture (`control_inplace_ry_inloop_rotated_dead.ll`);
and §11.2's "1468-fixture corpus" named no moment. R2 independently confirmed
every other number in §7 and §6, plus the O(K)-leak pair's four claims (the
diamond really is inside the loop after `-O1`, the two goldens `cmp` identical,
two template rails per activation never freed, and the registration is plain
`run_slice.sh` with **no** `--allow-unproven`, i.e. STRICT stage 2b on both
sides) and the NOROUTE conversion (all five fixtures red on a `cqrt_cswap`
injected at BOTH the entry and the last block).

### 12.4 NOT fixed, recorded

* **A house-pattern nit, R2's wording: 22 decline fixtures in this increment end
  in a decorative `CHECK-NOT: cqrt_ry_i32_controlled`.** A decline emits no IR at
  all — the RUN line pipes stderr into FileCheck — so the assertion cannot fail
  and pins nothing. It is harmless and it is not free: it reads like coverage. Not
  changed here (it is the house pattern across the tree, so removing it is its own
  sweep with its own diff), but do not count those lines as assertions.
* Everything §11.3 lists as uncleared is **still uncleared** — L2-F1, the two
  quarantined classes, bd `test_C_libtooling-67s8`, drbq.7's second half. Round 2
  re-read §11.3 and found nothing missing from it.
