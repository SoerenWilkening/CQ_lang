# PRD — Control-in-place rotation arms (§6a): controlled-Ry + the Rz peephole

> **Status:** proposed 2026-09-02, owner-scoped the same day (eight questions
> answered, recorded verbatim in §2). Extends Phase 4 (`ArmClassify` /
> `SwapRouteEmit` / `RegionFlatten`) and the 8h7d.5 rolled in-loop path.
> **A Rule-13 core change** (a new in-place NON-diagonal gate on a user
> register under quantum control — the rail-relabelling class every stale-record
> silent miscompile in the history belongs to). **Adds one frozen-designate
> runtime family** (`cqrt_ry_<W>_controlled`, §5). Implementing epic: bd
> `test_C_libtooling-drbq` (children `.1`–`.5` = Inc 0–4).

## 1. Motivation

A controlled-Ry is the textbook controlled rotation, and CQ cannot emit one.
Measured at HEAD (2026-09-02, `build/ir-pass/cq-opt`): every shape below declines
`cq controlled lowering: control flow under quantum control`, while the `cq_phi`
twin of each ACCEPTS via the swap route (`cswap; rz; cswap; free; icmp_unc; free`).

| # | source (clang -O1, `-Iinclude -include CQ.h`) | today |
|---|---|---|
| S1 | `if (q == 5) r = cq_theta(r, .9);` — Ry on a DISJOINT register | decline |
| S2 | `if (q == 5) q = cq_theta(q, .9);` — Ry on the CONDITION register | decline |
| S3 | `if (q == 5) { r = cq_phi(r,.2); r = cq_theta(r,.9); }` — mixed | decline |
| S4 | `_Bool c = cq_theta(0,1.1); if (c) r = cq_theta(r,.9);` — raw i1 qubit condition | decline (also for `cq_phi`: the flag is minted AT A COMPARE and there is none) |
| S5 | `int r = 0; if (q == 5) r = cq_theta(0, .9);` — controlled state-prep | decline |
| S6 | `if (q == 5) r = cq_phi(r, .9);` — the Rz twin of S1 | **accepts** (route) |
| S8 | `int a = q; if (q == 5) a = cq_phi(a, .9);` — Rz on an alias of the condition register | **accepts** (route; §3c permits phase ops on a condition variable) |

## 2. The design decision, and why the route is not an option for Ry

**The cswap route cannot carry an Ry.** The route's premise is that the arm
gate is a no-op on the inactive `|0⟩` work rail: `Rz|0⟩ = |0⟩` under
`Rz = diag(1, e^{iθ})`, so the rail comes back `|0⟩` on the inactive branch and
is freed for free (Rule 6). `Ry(θ)|0⟩ = cos|0⟩ + sin|1⟩`: on the inactive
branch the work rail comes back DIRTY and ENTANGLED with the flag (hence with
`q`). Cleaning it needs `Ry†` controlled on `¬f` — method-A, dropped 2026-06-09
precisely because "if you would emit a controlled gate to clean a rail, you could
have controlled the op in place from the start" (`SCOPING.md` §3 correction
history; `ROADMAP.md` "Method-A … is dropped"). `SCOPING.md` §3 already defers Ry
arms on a non-condition register to "§6a control-in-place".

So for Ry, control-in-place is **the mechanism, not a peephole**. The
route-vs-in-place choice exists only for Rz, where the two are the same unitary:
`cswap(f,r,w); rz(w,θ); cswap(f,r,w)` with `w=|0⟩` equals `cRz(f, r, θ)` exactly
(inactive branch: `Rz|0⟩ = |0⟩` with phase 1, no global-phase residue under the
`diag(1,e^{iθ})` convention). The in-place form is strictly cheaper (a `cqrt_cswap`
on a W-bit register is W Fredkins, twice, plus a rail alloc/free; a `cRz` is one
controlled rotation) — the §6a "footprint optimization" the ROADMAP lists.

**Owner scoping 2026-09-02 (eight questions, answers verbatim):**

1. Mechanism — "yes, general mechanism": ONE in-place rotation-arm emitter
   (`cqrt_ry_<W>_controlled(flag, h, θ)` / `cqrt_rz_<W>_controlled(flag, h, θ)`,
   flag minted at the compare as today, stripped by the same `_unc`), no route,
   no work rail, so the Rz peephole later is "also admit `cq_phi`", not a second
   emitter.
2. Rz peephole in this epic — "yes" (read as: default-on, for the FLAT
   `SwapRouteEmit` path: diamond, if/else, sequential regions, the 8h7d.5 rolled
   loop; nested 4.3 and switch 4.5 keep the route). Every phase-arm golden
   changes; the audit is the per-golden MULTISET diff (§9.2).
3. Freeze — "your recommendation": `cqrt_ry_<W>_controlled` is a new
   frozen-designate family (like kjd1's `cqrt_copy_f*_controlled`), all 9 widths
   to mirror `cqrt_rz_<W>_controlled`; adjoint = SAME symbol with a negated angle
   (the existing rotation convention in `EmitInverse`); the `_controlled_inv`
   reserve is left untouched.
4. Arm shape for Increment 1 — "(a), the safer option": exactly ONE
   tainted-operand `cq_theta` per arm, on a register disjoint from every
   condition wire; diamond and if/else (via the existing `cqrt_x` bracket).
5. Condition register — "they can stay declined, but this only applies for
   theta and NOT phi": S2 and its alias forms stay declined for Ry (§3c physics:
   after the Ry the flag is no longer a function of `q`'s basis and cannot be
   stripped); Rz on the condition register (S6-on-q, S8) keeps accepting.
6. Raw qubit control (S4) — "defer, if you agree" (agreed: deferred, §8).
7. Controlled state-prep (S5) — include, as the LAST increment (§7 Inc 4): same
   mechanism plus ONE fence (merge-phi pred incoming bit-identical to the theta's
   classical seed).
8. Loops — "in a classical loop (so classical bounds), cRy should NOT decline.
   nesting is a different story": Ry arms inside a classically-bounded loop lower
   ROLLED via the 8h7d.5 path (§7 Inc 3); depth-2 nests stay declined.

## 3. Physics of the accept, stated once

Let the condition read register set `C` (the wires `condProvenance` bottoms at,
closed through diagonal `cq_phi` aliases — the same wire set ArmClassify already
computes), and let the arm rotate register `R`.

- **Flag mint.** `f = [pred(C)]` on a fresh `|0⟩` rail via
  `cq_template_icmp_<pred>_<W>_hl(c, lit)` — unchanged from the route path
  (compound `&&`/`||` conditions via the 3c6m.12 flag network, unchanged).
- **Controlled rotation.** `cqrt_ry_<W>_controlled(f, R, θ)` (Inc 1) or
  `cqrt_rz_<W>_controlled(f, R, θ)` (Inc 2); a `¬f` arm is bracketed
  `cqrt_x(f); …; cqrt_x(f)` exactly as the route's negated arm is today.
- **Flag strip.** `cq_template_icmp_<pred>_<W>_hl_unc(f, c, lit)` recomputes the
  predicate on `C` and XORs it onto `f`. **Valid iff `C`'s computational basis
  is unchanged by the arm.** For Rz (diagonal) it is unchanged even when
  `R ∈ C` (why S8 accepts). For Ry it is unchanged iff `R ∉ C` as a PHYSICAL
  wire — not merely as an SSA value: `int a = q` (same value), `a = cq_phi(q,·)`
  (diagonal alias, `diagonalAliasHit`), and a dtzb/M-C in-place `add`/`xor` on
  `q` (`taint.InPlaceRailOps`) all name the same wire. An OUT-of-place derived
  value (`a = q + 1` lowered into a fresh rail) is a different wire — entangled
  with `q`, but `q`'s basis is untouched, so the strip stays valid.
- **Free.** `cqrt_free(f)` — `f` is provably `|0⟩` after the strip (Rule 6).
- **What the register holds afterwards.** `R` is relabelled by the Ry on the
  `f=1` branch. Every downstream consumer must read the POST-region SSA name:
  the merge phi is RAUW'd to the base (both incomings denote the one physical
  rail, as for a phase arm). Any PRE-region SSA record of `R` read after the
  region is a STALE-RECORD read — the wrong-VALUE class of bd `0njv` (still
  open, owner ruling pending). Fence R6 below refuses it for this shape
  loudly, so this increment does not widen `0njv`'s hole.

No copy, no reverse-play, no work rail: the answer is a superposition on `R`,
coherent, entangled with `C` exactly as the source demands (Rule 7 — a Ry arm is
neither a phase arm nor a value arm; method-B would dephase it).

## 4. Accept shape (Increment 1) and the decline partition

A `BranchRegion` (diamond, or if/else) whose every content arm is an
**in-place rotation arm**:

- **R1 — one theta, nothing else.** The arm block's non-terminator content is
  exactly ONE `@cq_theta_<sfx>` call `T` whose result is the arm's merge-phi
  incoming and whose arg-0 is TAINTED (a chained/in-place Ry — Rule 3: a
  classical arg-0 is state-prep, Inc 4, declined until then). Stray ops, a
  second rotation, a `cq_phi` in the same arm (S3) and a fan-out user of `T`
  all decline (`armBlockIsPureSpine`'s two reasons apply verbatim: the flatten
  erases the arm block).
- **R2 — classical angle.** `T`'s arg-1 is untainted (`declineTaintedAngle`
  / G3 — unchanged).
- **R3 — one base.** If/else: both arms rotate the SAME base value `R` (the
  merge phi's incomings are `T_true` and `T_false` with a common arg-0). A
  diamond's straight-through incoming IS `R`. Mixed classes across arms (a theta
  arm beside an Rz spine or a value chain) decline `mixed phase/value arm`.
- **R4 — disjoint wires.** `R`'s physical wire is not in `C`'s wire set (§3).
  S2, `int a=q` (S8-with-theta), and `a = cq_phi(q,·)` all decline
  `under quantum control` with a message naming the reason.

  **AMENDED (this PRD originally said "do NOT write a new alias walker"; Inc 1
  wrote one, and the deviation belongs on the record — round-1 review, lens L6
  §9).** "Same wire" is computed by ONE TU-local closure `railWireClosure`
  (backward for `C`, both ways for `R`), read by BOTH R4 and R6 so they cannot
  drift. It deliberately does not reuse
  `WireWalk`/`diagonalAliasHit`/`InPlaceRailOps`: those answer a **position-aware
  gate** question, whereas R4/R6 need the **SET of SSA names of one physical
  rail**, and the `add`/`sub`/`xor` hop must admit BOTH roots because
  in-place-ness is decided by the M-C fence in `lowerOps`, long after detection
  (notes finding H). `InPlaceRailOps` is subsumed — every member is an
  `add`/`xor` this hop already crosses. `condProvenance` IS reused, and is
  load-bearing in a way its own callers did not need it to be: the
  `railWireClosure(Region.Condition, …)` seed contributes only the compare
  itself (a `CmpInst` is not a `BinaryOperator`, so the walk stops), so R4's
  ENTIRE condition side is `⋃_{P ∈ Prov} backwardClosure(P)` and narrowing
  `condProvenance` is a Rule-13 change to R4 (L1 §2; both ends now carry the
  note).
- **R5 — stale condition wire (existing).** ArmClassify's compare-to-branch
  chained-theta guard (`CondWireDisp::DeclineNow`, the kjd1 gate-2c mirror) and
  the post-region-theta disposition apply unchanged.
- **R6 — no post-region read of the pre-Ry record.** **AMENDED TWICE, and the
  wording below is the shipped one** — leaving this clause at its pre-finding-J
  text ("every user of the SSA value `R`") is exactly how the defect got written
  the first time, and the round-1 review then found a second hole in the fix.

  Every user of every member of `R`'s **RAIL WIRE CLOSURE**
  (`railWireClosure(R, BothWays)`, the same set R4 intersects) — other than the
  arm gate(s) and the merge phi, and other than users inside the region's own arm
  blocks — must satisfy a position proof. **TWO SETS, TWO QUESTIONS:** a user
  that is itself a closure member is an alias **HOP** (a gate on the wire, not a
  record read) and owes only `cannotFollowGate(U, BI)` =
  `!isPotentiallyReachable(BI, U)`; every other user owes the full
  `provablyBefore(U, BI)`. Widening the member set must **not** widen the skip
  set on its own account — measured, widening both indiscriminately turns a
  decline into an accept. (Inside a loop the per-activation reading with the
  region's own branch as barrier would be needed; both predicates here are FLAT,
  which is why R7's loop clause is asked FIRST — Inc 3 owns lifting it.)

  The closure crosses `PHINode`/`SelectInst`/`FreezeInst` **FORWARD** from a
  tainted member, with ONE exclusion: the region's own merge φ. Inc 1 banned the
  whole class on a justification that named only that one φ, and the gap was a
  CONFIRMED silent miscompile — an ordinary CLASSICAL join φ
  (`int m; if (c) m = cq_phi(r,.1); else m = r;`) was a plain user that passed
  `provablyBefore` honestly, so its own users were never enumerated, and
  `liftOneRegisterMergePhi` later RAUW'd it to the base: `cq_measure`, `ret`, a
  7.6 tape write, a Phase-6 clone argument and a `cq_invert` bracket all read the
  POST-Ry register (round-1 review, lens L2 §1; six accepting reproducers).

  Anything that fails — a `cq_measure(R)`, a `ret`, a pure op, a store, a phi —
  declines `stale rail record read past a controlled Ry`. This is deliberately
  stricter than `declineStaleRecordOps` (pure ops only) so that the `0njv` hole
  is not reachable through this accept.
- **R7 — flat only (Inc 1).** The region is not inside a loop
  (`flatRegionRollableInLoop` false ⇒ the existing loop decline), not a 4.3
  nest, not a switch/select, not a ShareCondFlag region (the flag is also read
  as data — decline in Inc 1; revisit in Inc 2 where the Rz path already
  handles it), not an AnglePhi/AngleConsumers region.

Everything outside R1–R7 declines loudly with a message that a negative fixture
mirrors character-for-character (Rule 12).

## 5. ABI — the one new frozen-designate family

```
void cqrt_ry_<W>_controlled(int32_t ctrl, int32_t handle, double angle);
      W ∈ {i1, i8, i16, i32, i64, f16, f32, f64, f80}
trace: "cqrt_ry_<W>_controlled(h<ctrl>, h<handle>, <angle %a>)"
```

Hand-written in `runtime/cq_runtime.{h,c}` beside `cqrt_rz_<W>_controlled`
(same `(ctrl, handle, angle)` shape, same trace format, `%a` hex float — bd
`ni15`). The header comment "There is NO plain `cqrt_ry_<W>_controlled` twin"
is rewritten to say there is one, minted ONLY by the in-place rotation-arm
emitter. `runtime/test_trace.c` + `.expected.log` exercise every width once.
`ControlledSymbols::controlledRotationFn` gains the stem (`ry`/`rz`).
**Adjoint:** `EmitInverse` inverts `cqrt_{ry,rz}_<W>_controlled(f, h, θ)` as
the SAME symbol with `-θ` (arity 3, void, handle at arg **1**, control at arg 0
threaded unchanged; a `CurHandle` relabel applies to arg 1). The
`_controlled_inv` reserve (7 Ry widths, 9 Rz widths) stays declared, unused,
frozen-but-unused per ROADMAP.
**Checker:** `tools/free_pairing_check.py` `classify()` models
`cqrt_ry_<W>_controlled` as a NON-diagonal write of arg 1 with control arg 0 and
adjoint negate-angle, and `cqrt_rz_<W>_controlled` as the DIAGONAL twin; both
leave the "unmodelled reserve" list; `free_pairing_check_test.py` gains a
mutant per symbol.

## 6. Emission recipe (Inc 1) and the walker-audit obligation

Inside `emitRegion` (`SwapRouteEmit.cpp`), the dispatch on the new arm class sits
BEFORE the phase path's flag mint and stream collection (the in-place emitter mints
its own flag, step 1 below):

1. flag mint at `BI` (unchanged, `lowerCompareToFlag`);
2. per arm, in successor order: `cqrt_x(f)` if negated; **hoist `T` to
   before `BI`** (move the call, do not re-mint) and record
   `taint.ControlledRotations[T] = f`; `cqrt_x(f)` if negated;

   **NOT on `ControlPlan`** (amended after Inc 1 measured it; notes finding G).
   There is not ONE `ControlPlan` per compilation:
   `TaintPropagation::detectAndLowerOnwardControl` (the yn71 onward-control
   fixpoint) builds a LOCAL `plan2`, emits its regions and DISCARDS it, while
   `lowerRotations` is later handed the FIRST plan. A plan-hosted map would
   therefore silently lose an onward region's entries and lower its hoisted theta
   **unconditionally** — an unconditional Ry where a controlled one was meant,
   i.e. a verify-clean wrong unitary. `TaintSet` is the one object every emitter
   and `lowerRotations` share.
3. flag strip + free (unchanged);
4. merge phi RAUW → `R`, scrub, erase; `flattenRegion` (unchanged).

`lowerRotations` then lowers a theta with a `ControlledBy` entry as
`cqrt_ry_<W>_controlled(f, Handle, θ)` at the theta's (hoisted) position, and
RAUWs its result to the handle as it does for a chained theta; the minted call
joins `taint.UserChainedRotations`.

**Why hoist-and-defer rather than emit the controlled gate in the emitter:**
every PRE-lowering wire walker (`WireWalk`, `LoopLowering::collectRailGates`,
`isInPlaceGateOnArg0`, ArmClassify's cond-wire scans, `declineStaleRecordOps`)
recognizes the gate by its `@cq_theta_` spelling with the wire at **arg 0**.
Keeping the theta call alive until `lowerRotations` means those walkers see a
theta on `R` where one will fire — over-approximating a controlled gate as
unconditional, which is the SAFE direction for every staleness fence.

**The audit (the F-1/F-3 lesson, mandatory before Rule 13):** enumerate every
name-test on `cqrt_ry_` / `cqrt_rz_` / `_controlled` in `ir-pass/src`,
`tools/free_pairing_check.py` and `tools/loop_twin_matrix.py`, classify each as
pre- or post-`lowerRotations`, and for every POST-lowering one decide whether
the `_controlled` spelling with the handle at **arg 1** must be admitted (it is
a rail-relabelling gate on arg 1, a read of arg 0). Record the table in the
clearance doc. A walker that keys "in-place gate on arg 0" and silently misses a
`cqrt_ry_<W>_controlled` is exactly the widened-one-set-not-the-other hole.

## 7. Increments and done-criteria

Each increment: Rule 12 red-green (positive `CHECK` + negative
`RUN: not … | FileCheck` mirroring the diagnostic), ≥1 e2e golden slice that
LINKS, full `ctest -j6` before commit (Rule 19 moment 1 and 5), independent
adversarial Rule-13 review (opus lenses; one Fable clearance per increment).

- **Inc 0 — surface.** §5 in full (runtime ×9, trace test, `ControlledSymbols`
  stem, `EmitInverse` adjoint, checker model + mutants). Done: `ctest -R runtime`
  green; `e2e-free-pairing-selftest` green with the new mutants.
- **Inc 1 — flat Ry arm, shape (a).** §4 R1–R7 + §6, **plus the FREEZE**: a
  register a `cqrt_{ry,rz}_<W>_controlled` fired on is never reverse-played and
  never freed by the whole-DAG spine (Rule 6's "left allocated" fallback). A
  controlled gate's adjoint needs its CONTROL and the flag is stripped + freed
  inside the region's own stream, so the spine — which runs last and reverses
  after a rail's final user — would emit an adjoint naming a freed flag and then
  free a still-dirty, condition-entangled register.

  **THE FREEZE IS ASKED STRUCTURALLY OF THE EMITTED GATE**
  (`ChainWalk::railCarriesControlledRotation`: does `H` have a user `G` with
  `isInPlaceGateOn(G, H)` and a `cqrt_{ry,rz}_*_controlled` callee?), never from
  a recorded `Value *`. Inc 1 shipped a `TaintSet::ControlledRotationRails`
  keyed on the theta's arg-0 at `lowerRotations` time; for a DERIVED base that is
  an instruction `lowerOps` (the very next stage) RAUWs and ERASES, so the set
  dangled and the freeze silently did not apply — the use-after-free + dirty free
  returned verbatim from plain C on 5 of 5 out-of-place base opcodes and through
  two independent `promote()` paths (round-1 review, lenses L3 §1 and L5 §1,
  independently). Fixtures (names
  indicative): `control_inplace_ry_diamond.ll`,
  `control_inplace_ry_diamond_negated.ll` (false-successor polarity, Rule 9),
  `control_inplace_ry_ifelse.ll`, one non-i32 width (f64 or i8); negatives for
  S2, S8-with-theta, the diagonal alias, two thetas, theta+phi (S3), tainted
  angle, stray op, raw-i1 (S4), state-prep (S5), R6 stale record (measure and
  ret variants), nested, switch, in-loop, heterogeneous if/else. e2e:
  `slice_control_inplace_ry.c` (+ a `_negated` twin), goldens hand-argued in
  the clearance doc (the trace must read
  `icmp_hl; ry_controlled; icmp_hl_unc; free` per arm).
- **Inc 2 — Rz peephole.** Admit `cq_phi` spines on the in-place path for the
  FLAT `emitRegion` route (diamond/if-else/sequential/in-loop rolled); nested
  and switch keep the route. Multi-rotation spines (`rz; rz` in one arm) are
  admitted here since a diagonal chain has no basis hazard. Golden regeneration
  with the §9.2 multiset audit; the six 8h7d.5 `cmp` twin gates and
  `e2e-loop-twin-matrix` must stay byte-identical rolled≡unrolled.
  ShareCondFlag regions ride the same path as they do today (strip skipped).
- **Inc 3 — Ry arm in the 8h7d.5 rolled loop.** Lift R7's loop clause for a
  natural single-latch loop (`flatRegionRollableInLoop`). Obligations: the
  hoisted `T` is inside the loop body and is a member of `collectRailGates`'
  gate set for its wire; `collapseFlattenedLoopRails` / `markIfRailLocal` /
  `staleRailRecordRead` re-asked with a controlled Ry as the relabelling gate;
  **add the Ry-arm shape as a `tools/loop_twin_matrix.py` axis FIRST**; rolled
  and hand-unrolled twins byte-identical; budget ≥3 adversarial rounds (the
  loop history is 4-for-4 on hidden over-accepts).
- **Inc 4 — controlled state-prep (S5). IMPLEMENTED 2026-09-05** (bd
  `test_C_libtooling-drbq.5`; see §14, its dated CORRECTED notes, and
  `CONTROL_IN_PLACE_INC4_NOTES.md`). Shipped: F1 + F2 + the if/else clause in
  `ArmClassify`, the `!Chained` controlled accept path in `RotationLowering`
  (with the sibling `controlled theta suffix/width` bail hoisted ABOVE the alloc
  — it was a mid-emission bail), comments only in `SwapRouteEmit`. 58 fixtures
  (20 accept / 39 decline), 3 e2e slices, corpus 1474 → 1531, ctest 324 → 327.
  Whole-corpus lowered-IR sweep vs the pre-Inc-4 oracle: **48 files differ, every
  one in the new family, ZERO pre-existing files changed.** `--stateprep` twin
  matrix 297 cells, **0 MISMATCH**, post-4 table committed beside the pre-4 one.
  **The implementation found one headline OVER-DECLINE the design could not see**
  — `clang -O1` SINKS a post-region op on `r` into the arm, because a state-prep
  register's straight-through value is a compile-time constant and the op folds on
  that edge (48 matrix cells; §14.12 worry 8 predicted it). Notes §8/§9.
  §14 as written CORRECTS
  this bullet on two counts: there are **TWO** new fences, not one (the
  equality-fold ambiguity F2 is required and is not anticipated here — measured,
  `if (q==k) r = cq_theta(q, θ)` and `int r = q; if (q!=k) r = cq_theta(k, θ)`
  compile to modules BYTE-IDENTICAL to a genuine state prep), and the if/else
  bullet describes a shape plain C does not produce (`clang -O1` makes it an
  angle `select`, refused at `classifyAngleSelect` S3 — a SECOND customer site).
  `T` with a CLASSICAL arg-0 in the
  arm: hoist to `BI` (the alloc is classical and hoists with it), controlled Ry
  on the fresh rail, merge phi RAUW → the new handle. ONE new fence: the merge
  phi's pred-edge incoming is a `Constant` BIT-IDENTICAL to `T`'s seed (an
  `int r = 0; … cq_theta(0, θ)` pair; `-0.0` vs `0.0` is a decline), else it
  is a data mux and declines. If/else with two preps declines (two rails).

## 8. Deferred / out of scope (with re-opening condition)

- Raw i1 qubit control, S4 (owner Q6): the flag is minted at a compare; a bare
  `br i1 %theta` has none. Re-open as "control on the register itself, no flag
  ancilla" — a 3-gate saving, its own PRD.
- Depth-2 nests (4.3), switch (4.5), select, 6.5 classical-call arms, value
  arms: unchanged, keep their routes/declines.
- Multi-Ry / Ry+Rz spines in one arm (S3), and two-register arms: after Inc 3,
  as shape (b) — the general in-place spine (owner Q4 chose (a) first).
- bd `0njv` (straight-line stale-record measure/ret) is NOT fixed here; R6
  only keeps it unreachable through this accept.

## 9. Verification plan

### 9.1 Layers
- `ir-pass-lit` (targeted per fixture while iterating; whole entry before
  commit); `cq_opt_equivalence` FULL sweep once, since the diagnostic surface
  changes. **RUN, twice: 1330 fixtures / 0 mismatches at the Inc-1 hand-back
  (round-1 review, lens L6 §11), and 1347 / 0 after the round-1 fixes
  (`CONTROL_IN_PLACE_INC1_NOTES.md` §9).**
  Record the count, so the next agent does not re-spend ~658s of CPU learning
  what is already known.
- e2e goldens + stage-2b strict (`free_pairing_check.py` sees a controlled
  non-diagonal write of the register and the flag's strip/free pairing).
- Full `ctest -j6` at every Rule-19 gate moment.

### 9.2 The Inc-2 golden audit
For every regenerated `.expected.log`, the multiset difference old→new must be
EXACTLY, per in-place-lowered arm: `−cqrt_alloc_<W>(0) −cqrt_cswap ×2
−cqrt_free(rail) −cqrt_rz_<W>(rail,θ) ×g +cqrt_rz_<W>_controlled(f,h,θ) ×g`, the
flag mint, strip and free unchanged, and NO other line moving. Handle NUMBERS may
shift (one fewer alloc per arm); the audit compares with handles normalised. A
golden whose diff is anything else is a finding, not a regeneration (bd
`golden-multiset-diff-audit-2026-08-29`).

> ⚠ **AND THE `cqrt_x` BRACKETS ARE *NOT* UNCHANGED ON A NEGATED ARM.** An earlier
> wording of this section said "with the `cqrt_x` brackets … unchanged"; that is
> true of a NON-negated arm and **false** of a negated one, and the difference is
> structural rather than a compiler choice. The route brackets **each** of its two
> `cqrt_cswap`s, so a ¬flag arm carries **FOUR** `cqrt_x(f)`; control-in-place
> brackets the arm's gate **run** once, so it carries **TWO**. The expected delta
> for a negated arm therefore additionally carries **`−cqrt_x(f) ×2`**.
>
> MEASURED LINE COUNTS, so nobody re-derives this from prose:
>
> | shape | old | new | net |
> |---|---|---|---|
> | `slice_control_phase_diamond` — 1 non-negated arm, 2 gates | 12 | 8 | **−4** |
> | `slice_control_phase_ifne` — 1 NEGATED arm, 1 gate | 15 | 9 | **−6** |
> | rolled loop, 2 activations, non-negated (`eq`) | — | — | **−8** = 2 × 4 |
> | rolled loop, 2 activations, NEGATED (`der` — `clang -O1` canonicalizes `sqrt(a+3.) <= 3.5` to `fcmp ugt` with the gate on the FALSE successor) | — | — | **−12** = 2 × (4 + 2) |
>
> So **−4 per non-negated arm and −6 per negated arm**, independent of the gate
> count (each extra gate removes one `cqrt_rz(rail,θ)` and adds one
> `cqrt_rz_<W>_controlled`, net zero). The last two rows are the round-1 review's
> own rolled-loop measurements (L1 §3.8), and the −12 is the one number this
> section's literal wording did not predict.
>
> `tools/golden_multiset_audit.py` **models this rather than waiving it** —
> confirmed, not assumed: `_route_leg` matches the `[x(f)] cswap [x(f)]` bracket
> on both legs and demands the same polarity on the route-back, and the
> replacement emits exactly ONE pair per negated arm. Its printed (A) delta for
> `slice_control_phase_ifne` reads `− … cqrt_x(h) x2`, i.e. four removed and two
> re-emitted. The audit reduced **8 negated arms** across the 26 regenerated
> goldens with zero findings, and its `--selftest` pins the arithmetic with three
> dedicated mutants (`f1` one bracket dropped, `f2` both dropped, `f3` an extra
> one added) — all three DETECTED.

### 9.3 Rule-13 lenses (per increment)
1. Flag-strip validity: every accepted shape has `C`'s basis unchanged — probe
   aliases (SSA, diagonal, in-place add/xor, pointer-mediated via Shadow).
2. Stale-record reachability: try to read the pre-Ry SSA record after the region
   through every consumer kind (measure, ret, pure op, store, phi, call,
   select, tape write); each must decline under R6.
3. Walker audit (§6): mutation-test each post-lowering walker with the
   controlled spelling.
4. Polarity: false-successor diamonds, if/else, and `!=` canonicalization.
5. Adjoint: a Ry-arm region inside a Phase-6 Bennett wrap (clone-on-taint) and
   under the 7.4 break reverse-play — `EmitInverse` emits `-θ` with the control
   threaded.
6. Loop (Inc 3): the per-activation barrier, identity-carry phis, two registers
   in one loop, leading gate, derived condition — the 8h7d.5 fixture family with
   Ry arms substituted.

## 10. Risks
- The stale-record family (bd `uzb`, `6j1`, `6vk`, `2qyz`, `0njv`) is the
  closest prior art: every one was a verify-clean wrong VALUE from reading a
  pre-Ry record. R6 is the fence; its probe family is the priority.
- Hoisting `T` moves a `cq_theta` into the pred: any analysis that keys on
  "theta in the arm block" (the stray-op check, `walkPhaseSpine`'s
  `getParent() != ArmBB` cut) runs BEFORE the hoist at detection time; the
  hoist happens at emission. Keep that order; a detector re-run post-hoist
  would misread the shape.
- Inc 2 rewrites ~100 goldens; the §9.2 audit is the only thing standing
  between "regenerated" and "regenerated from a broken build".

---

## 11. Round-1 Rule-13 review findings (2026-09-02) — six lenses, three defects

Six independent adversarial reviewers (L1 flag-strip/R4 · L2 stale-record/R6 ·
L3 freeze/spine · L4 polarity/order/plan-lifetime · L5 walker audit/adjoint/ABI/
checker · L6 fixture + doc truth) ran against the Inc 0+1 working tree. All 37
committed `control_inplace_ry_*` fixtures and both e2e slices were GREEN
throughout — **every defect below shipped through a green suite**, which is the
fact to carry, not the count.

**Two of the three defects were CONFIRMED silent miscompiles and one a CONFIRMED
crash; two of the three were found INDEPENDENTLY BY TWO LENSES.** Budget the next
round accordingly (this epic now matches the 8h7d.5 loop history's hit rate).

### 11.1 L3 §1 = L5 §1 — the freeze was keyed on a pointer the next stage erases
`CONFIRMED SILENT MISCOMPILE.` `taint.ControlledRotationRails` was populated in
`lowerRotations` with the theta's arg-0. For a DERIVED base (`p*5`, `p+5`, `p^5`,
`p&5`, `p<<5`, `zext p`, `@llvm.sqrt(p)` at f64) that is the raw LLVM
instruction, which `lowerOps` — the very NEXT pipeline stage — RAUWs to a
`cq_template_*` result and ERASES, through five separate `promote()` copies none
of which scrubbed the set. All three spine query sites then compared the live
rail against a dangling pointer and answered "not frozen", so finding A's
use-after-free of the control flag + dirty free of the entangled register
returned VERBATIM, from plain C, `opt` exit 0, verify-clean. 5 of 5 out-of-place
base opcodes, two independent `promote()` paths, i32 and f64. **Fixed
structurally:** the `Value *` set is REMOVED; `ChainWalk::railCarriesControlledRotation`
derives the rail from the emitted gate's arg-1 USE at query time, so no RAUW or
erase can move it, no address can be reused, and BOTH stems are covered (Inc 2's
Rz peephole inherits the freeze rather than the defect — L3 §2). Pinned by
`control_inplace_ry_derived_base_{mul,add,f64}_late_use_frozen.ll` and the strict
stage-2b slice `slice_control_inplace_ry_derived_base`. Red-green measured by
disabling the predicate: 5 fixtures red, 53 green with it.
**The lesson (L5's own):** §3's audit enumerated NAME TESTS and asked the right
question of every site it listed. The freeze it was auditing is a `Value *` SET,
and nobody enumerated who INVALIDATES that.

### 11.2 L2 §1 — R6 laundered by a liftable one-register classical merge φ
`CONFIRMED SILENT MISCOMPILE.` `railWireClosure` crossed `PHINode`/`SelectInst`/
`FreezeInst` BACKWARD but not FORWARD, justified in-source by "the region's OWN
MERGE φ is a user of the base" — which names ONE φ, not the class. An ordinary
CLASSICAL join φ (`int m; if (c) m = cq_phi(r,.1); else m = r;`) was therefore a
plain USER of a member: it passes `provablyBefore` HONESTLY, R6 stopped there,
and its own users were never enumerated. `liftOneRegisterMergePhi` then RAUW'd it
to the base AFTER the region was emitted, so `cq_measure(m)`, `ret m`, a 7.6 tape
write, a Phase-6 clone argument and a `cq_invert` bracket all read the POST-Ry
register. Six accepting reproducers over five consumer kinds, plus the N-way
classical `switch` lift and a chained-Ry alias. **Fixed:** cross φ/select/freeze
forward from a tainted member, with the region's own merge φ as the ONE
exclusion (passed in beside `ArmA`/`ArmB`). Seven negatives
(`control_inplace_ry_reject_lifted_phi_{measure,ret,tape,clone_arg,invert,switch,chained_theta}.ll`)
and the accept control `control_inplace_ry_lifted_phi_base.ll` (base IS the
lifted φ). Red-green measured by disabling the crossing: exactly those 7 red.

### 11.3 L4 §1-2 — `ControlRegion::RoutedBase` dangles across emission order
`CONFIRMED CRASH (pre-existing) + OVER-DECLINE (introduced by Inc 1).` The field
is recorded at DETECTION and read at EMISSION, and an earlier-emitted region's
`MergePhi->replaceAllUsesWith(); eraseFromParent()` neither updates it (a raw
pointer is not a use) nor is visible to the bd `hcrg` pre-flight (which reasons
about BASIC BLOCKS; a classical branch between two quantum regions defeats the
block alias). The eq-fold PHASE path then DEREFERENCED it — SIGSEGV under
libgmalloc, from plain C. Inc 1 made the field non-null on EVERY in-place accept,
so the in-place emitter became a second reader: it COMPARES the stale pointer
against the RAUW-updated theta operand, and declined the increment's own headline
shape whenever a classical branch sat between two regions — a verdict that
flipped with textual BLOCK ORDER, which detection cannot see. **Fixed:**
`RoutedBase` is a `llvm::WeakTrackingVH` (follows RAUW, nulls on erase) plus a
`RoutedBaseRecorded` bit written only through `setRoutedBase`, so "never
recorded" (derive) and "recorded then erased" (LOUD decline) are distinguishable.
Pinned by `control_swap_eqfold_classical_between.ll` and
`control_inplace_ry_sequential_classical_between.ll`.

**`ControlRegion` field audit** (every field recorded at detection and read at
emission, asked the same question). Verdicts in
`CONTROL_IN_PLACE_INC1_NOTES.md` finding M; the short form is that `RoutedBase`
was the ONLY field naming a value that belongs to ANOTHER region — every other
`Value *`/`Instruction *` field names the region's own instructions, and the
BasicBlock fields are exactly what the `hcrg` pre-flight already protects.

### 11.4 What the review found and did NOT change
- **L1** found no miscompile in R4's scope and, better, proved R4 is a genuine
  TRUE-POSITIVE fence rather than only an over-decline — but its only committed
  fixture was an over-decline that disclaims itself. Added
  `control_inplace_ry_reject_inplace_alias_base.ll` (base and condition really
  share a rail through an M-C in-place `xor`), its measured M-C premise
  `control_inplace_ry_inplace_alias_witness.ll`, and the `sub` spelling. Also
  recorded the `condProvenance` dependency at both ends (L1 §2, §11.5).
- **L5** audited 40+ name-test sites independently, found seven the notes' §3
  table omitted and one non-existent function name, contributed two checker
  mutants the shipped list lacked (ctrl/handle slot swap on real emitted IR; the
  same swap in the adjoint only), and corrected two justifications that had gone
  false. All folded in; none was a miscompile.
- **L6** measured that the flagship accept fixture's own stated assertions were
  not the assertions FileCheck evaluated (injected `cqrt_x` / `cqrt_cswap` passed
  green), that two decline fixtures matched every diagnostic in the family, and
  that R3's "one base" clause was reachable and unpinned. All three fixed.
  **One L6 finding was itself wrong and is recorded as such:** its §6 flags
  CLAUDE.md's "1 XFAIL" claim as stale because `grep -l XFAIL ir-pass/test/*.ll`
  returns 9. Re-measured — `lit ir-pass/test` reports `Expectedly Failed: 1`; the
  other 8 files only MENTION the directive in prose ("XPASSes — XFAIL gone").
  The claim was correct; CLAUDE.md now says which instrument to trust.
- **Over-declines recorded, deliberately NOT fixed** (Prime Directive; they are
  follow-ons, not debt): "rotate, then branch on the rotated register" declines
  while its `cq_phi` twin compiles (L1 §5, L2 §2, L3 §4 — the natural
  Grover-ish composition); two in-place regions on DIFFERENT registers under one
  condition (L3 §4); `cq_invert` around a region is a silent no-op (L3 §5,
  pre-existing, Phase-8); the unconditional flag free after a null strip mint
  (L3 §3, pre-existing house style copied from the phase path).
  **Two of those four were mis-recorded and are corrected by the round-2 review
  (lens B §2/§3) — read them together with `CONTROL_IN_PLACE_INC1_NOTES.md`
  §8.2:** (a) the first is WIDER than "rotate, then branch on the rotated
  register" — a non-diagonal gate on the CONDITION register after a **fully
  emitted** region (mint, gate, strip and free all already in the stream) also
  declines, including the very natural `if (q==5) r=…; if (p==4)
  q=cq_theta(q,.3);` where a second region rotates the first's condition
  register; (b) the second is NARROWER than it reads — it is two regions on
  different registers under the **same literal comparison**, and the plain
  composition `if (q==5) r=…; if (q==6) r=…;` on ONE condition register
  **ACCEPTS** and is prefix-identical to its twin. Also (c) `cq_invert` around a
  region is worse than a no-op: the module `opt` accepts **does not link**
  (`Undefined symbols … ___cq_invert_begin`), pre-existing and Phase-8-owned.

### 11.5 Standing obligations this review created
1. `condProvenance` carries R4's completeness; narrowing it is a Rule-13 change
   to R4 (noted at both ends in source).
2. The `add`/`sub`/`xor` hop admits both roots because M-C decides in `lowerOps`;
   teaching detection the M-C answer NARROWS the closure, and every member that
   disappears loses its R6 obligation — a Rule-13 change, not a cleanup.
3. Inc 2's Rz peephole inherits the structural freeze automatically. It must
   still re-ask §9.2's multiset audit and the L5 blind spot: a ctrl/handle slot
   swap on the `rz` twin is INVISIBLE to `free_pairing_check.py`, because
   `diagonal=True` makes the write transparent.
4. `cq_opt_equivalence` FULL sweep is a §9.1 obligation that Inc 1's notes never
   recorded. It is now recorded, with its count, in the notes' §9 — which also
   lists the full-suite gate (295/295) and the mechanical red→green evidence for
   each fix. Keep that section; the next round should not have to re-derive what
   was run.

### 11.6 Round 2 (2026-09-02) — three lenses, ZERO defects, six stale justifications
Three more independent adversarial reviewers ran against the post-round-1 tree
(A set-widenings · B build-the-instrument · C plan-lifetime/emission-order),
covering **76 probes**, a **472-cell all-pairs twin matrix** (944
`clang -O1` → `cq-opt` → strict stage-2b → link → run pipelines) plus a
**198-cell hand-picked 3-way slice**, and **49 `libgmalloc`-instrumented,
twice-compiled determinism probes**. **No confirmed silent miscompile, no crash
and no confirmed over-accept in any lens** — the first clean round this epic has
had, and it is evidence, not a licence (round 1 found three defects, two of them
CONFIRMED silent miscompiles; bd 8h7d.5's loop history is 4-for-4). Every one of
the 287 accepted twin pairs is **byte-identical to the trusted swap-route stream
with the route collapsed**, prefix AND suffix, with 0 failures across six
invariants — which is the closest thing to a proof of the increment's central
claim that a simulator-free project can have.

What the round produced instead of defects is **one plausible structural hole and
a list of written justifications that had gone false** — the bd 8h7d.5 F-1 shape,
"the reason is now wrong; the behaviour is right by accident of another file".
Closed in this pass:

- **The hole (A §1), fixed in CODE.** The control-in-place freeze was asked over
  `DataDag::Rails` while the thing it must suppress (`emitInverseCall`) iterates
  `DataDag::Calls` — two sets that `emitDagReversal`'s own header documents to be
  UNEQUAL, and whose `cqrt_free` half bd `uow0` had already closed with an
  explicit intersection. The **adjoint** half was not closed, and Inc 0 gave it a
  customer by making `cqrt_ry_<W>_controlled` `isInverseEmittable`; a Phase-6
  `@__cq_q_*` clone result is exactly a member of the difference. It does not
  fire at HEAD (measured on three C reproducers plus their uncontrolled and
  no-rotation twins — the suppression today comes from a different subsystem),
  but "the other subsystem happens to stop it" was the prior justification for
  the FREE half too and it was recorded wrongly. The freeze is now asked
  structurally of **every walked handle** in `recoverDataDag`'s step-1 walk.
  **THE STANDING LESSON, again: when you widen a set, ask what OTHER set was
  computed over the same closure** — here, which set the SUPPRESSION is asked
  over versus which set the EMISSION iterates.
- **A second dead branch made LOUD (C §3).** `emitInPlaceRotationRegion`'s
  `Cls != InPlaceRotation → continue` claimed support for a gate-free sibling arm
  that classification declines in both processing orders; skipping would have
  DROPPED that arm's gates silently. It now declines loudly. Unreachable, so no
  behaviour change — the direction is the point.
- **Six stale justifications corrected in source** (A §2 the "classical angle"
  claim, A §3 `ArithLowering` arm (c), A §4 the `preservesBasisUnderRecord` /
  freeze contradiction on the Rz stem, A §5 the pre- vs post-`lowerRotations`
  spellings, A §6 the freeze suppressing diagnostics, B §1 the `sub` hop's
  M-C premise — there is **no `cqrt_subc` at any width**), plus C §1's
  `Condition`-row ground (structural, not the measurement whose diagnostic names
  a different clause) and C §2's `InShadow` hedge (nothing populates it, anywhere).
- **Two fixtures** (`control_inplace_ry_clone_base_frozen.ll`,
  `control_inplace_ry_ifelse_classical_between.ll`) and **two committed
  instruments** — `tools/inplace_twin_matrix.py` and
  `tools/control_flag_order_check.py`, each with a header stating what it does
  and does NOT witness, and **neither a ctest gate** (owner cost decision
  pending). The twin matrix's blind spot is structural and must be quoted with
  it: its oracle is the `cq_phi` twin, which is EXEMPT from R4 and R6, so an
  R4-violating shape would emit a byte-identical prefix and still be wrong.

### 11.7 Round 1 on **Increment 2a** (2026-09-02) — three lenses, ZERO defects, six stale justifications + two blind instruments
Three independent adversarial reviewers ran against the uncommitted Inc-2a tree
over `f92d95e`, each with a **pre-2a `cq-opt` built from `f92d95e` in a scratch
worktree as the oracle** and every probe run on BOTH binaries: **L1** the stem
split and its co-movers · **L2** the rolled loop · **L3** did the witnesses
witness, and are the docs true.

**No silent miscompile, no crash, no over-decline, and no cross-binary
disposition movement of any kind.** The instruments behind that, all independently
written rather than re-run from the increment's own scripts:

- a **1358-fixture collapsed-stream sweep** — 672 collapse-exact, 675
  decline-both, **0 disposition flips and 0 stderr differences**;
- an **independent re-derivation of all 26 golden diffs** by different machinery
  (aligned mint sequences and use-set rail identification, arms found in the NEW
  stream — the opposite direction from the shipped audit): **26/26
  `COLLAPSE-ONLY`, 66 rails / 66 arms / 70 rz gates**, agreeing golden by golden;
- **243 rolled/unrolled twin cells** (123 run on both binaries), an **80-cell
  PREFIX × NEW-REGION × SUFFIX product**, and a **36-of-36 `COLLAPSE-ONLY`
  per-cell collapse identity on a ROLLED LOOP** — an axis the shipped inverted
  oracle explicitly excludes;
- **73/73 in-scope fixtures red under the pre-2a oracle** (the notes claimed this
  for the 9 new ones; it is true of all 64 edited ones too), a **7 × 73
  lowered-output mutation matrix**, a **20-mutant validation of the golden audit
  with 0 survivors**, and a **whole-corpus scan for a controlled rotation naming
  a freed flag: 151 gates over 100 fixtures, 0 real hits**;
- `ir-pass-lit` **1357 + 1 XFAIL**, `ctest -j6 -R '^e2e-'` **285/285**, and
  `loop_twin_matrix` **120/120 against a table written BEFORE the increment
  existed**.

What the round produced instead of defects is the same shape round 2 produced:
**justifications the increment itself falsified, and instruments that cannot see
what they are quoted for.** All of it is closed in this pass.

**Justifications corrected in source (five):**

- **`ChainWalk.cpp` row (iv) told the next editor to delete the clause the
  increment could not work without** (L1 F-0, the round's most dangerous finding
  even though nothing miscompiles). It said `preservesBorrowedParent` "already
  excluded the `_controlled` spelling and **must KEEP excluding it**"; the same
  commit's clause (1b) admits the diagonal controlled Rz as READ-ONLY and §4(a)
  measured it as REQUIRED by nine modules. Two comments, one gate, two answers —
  and unlike the round-2 predicate version, **nothing in the build can see it**.
  Row (iv) now states clause (1b) and why the licence moved from the GROUP
  (`routeGroupFullyInside`) to the GATE.
- **`ChainWalk.cpp` row (iii) stated the opposite of what the code does** (L1
  F-2): an in-place gate is a *benign* user that leaves `isTerminalHandle` free to
  return true, so the narrowing DOES move the verdict (possibly-true →
  always-false). The verdict is still right, for the other reason the file gives —
  the ROUTE is the oracle and a `cqrt_cswap` was unrecognized there too — and the
  direction is toward leaking, i.e. Rule-6 safe.
- **`ArithLowering.cpp`'s ⚠ block named the wrong operative arm** (L1 F-1, the
  third co-mover, in a file the notes' §5 table does not list). Post-2a a
  controlled **Rz** moves from `priorUseIsSettled` arm (a) to arm **(c)** with an
  identical verdict, and the comment both asserted (a) and *forbade citing* (c)'s
  ground — while grounding (a)'s safety on the freeze this increment removed for
  that stem. It is now a per-stem table: `ry` → (a), frozen; `rz` → (c), whose own
  "never a `D.Calls` member" ground is RESTORED for it.
- **`RotationLowering.cpp`'s `UserPhaseRotations` addition is INERT and said it
  was necessary** (L1 F-3). Traced end to end: the set has one reader chain, and
  two lines below its consumer sits the F2 clause `if (N.starts_with("cqrt_ry_")
  || N.starts_with("cqrt_rz_")) continue;` — recorded and unrecorded reach the
  same `continue`. Measured: 0 stderr differences over 1358 fixtures. The
  recording is KEPT (right classification, conservative direction, load-bearing
  the moment that clause narrows) and the comment now says so — the 8h7d.5 round-5
  "a comment that overstated a no-op", one increment later.
- **`LoopLowering.cpp`'s round-2 fan-out block still claimed "by construction"**
  (L2 N-3). Post-2a a routed region is still structural, but a control-in-place
  region is rejected by a **predicate** (`isHoistedRegionArmGate`). Split in two,
  so the sentence a reader hits first is true.
- Plus `ControlPlan.h`'s live `ArmClass::Phase` doc (still "the 4.1 route"), five
  fixture headers (one saying "**zero controlled Rz**" nine lines above its own
  assertion of `cqrt_rz_i32_controlled`; another claiming "four rail frees" where
  its own count block asserts zero), `Uncomputation.cpp`'s `1356`-fixture corpus
  (it is **1358**), and a dated superseded banner on `PRD.md` §20.3,
  `IMPLEMENTATION.md` §4 and **ROADMAP's own 4.1 entry** — a reader landing there
  previously got the route in the present tense with no pointer to §6a.

**Two structural fixes in code:**

- **`emitRegion`'s §5 const-fold re-anchor declined MID-EMISSION** (L1 F-5 =
  L2 N-1) — after the flag mint, possibly after a lone `cqrt_x`, and after a
  previous arm's gates were hoisted and recorded, leaving the CFG un-flattened.
  Rule 1 says *lower nothing*, and the sibling `emitInPlaceRotationRegion` states
  that invariant ("never emit half a region") and honours it. Inert today — no
  output is written on a `DS_Error` decline and no reaching program could be
  built — but the fence is on the **HOT PATH** for the flagship rolled Grover
  (L2 measured `clang -O1` const-folding **both** arm gates of
  `slice_control_grover_loop_dynamic` to `cq_phi_si32(i32 5/0, …)`, so the
  re-anchor fires once per region per rolled loop). The validation is now a
  read-only pre-pass over the arms placed immediately after the width fence;
  every decline in `emitRegion` precedes the first emitted instruction.
- **`isHoistedRegionArmGate` was stem-AGNOSTIC while its soundness argument is
  DIAGONAL-specific** (L2 N-2). `taint.ControlledRotations` has two writers (the
  Inc-1 Ry arm and the Inc-2a Rz arm) and the predicate did not distinguish them,
  so the Ry stem inherited an exemption nobody derived for it. Narrowed to the
  `cq_phi` stem — free today (in-loop Ry declines before it can reach the
  predicate, measured on five shapes with an out-of-loop control that accepts) —
  and the obligation Inc 3 owes if it widens is now written at the site: this
  predicate exempts the gate from the fan-out count while `collectRailGates`'
  `noteGate` would still COUNT a `cq_theta_` for staleness, which is the 8h7d.5
  F-1/F-3 "two independently-written predicates over one closure" shape verbatim.

**Two instruments made honest, and one blind spot closed:**

- **`tools/golden_multiset_audit.py` modelled the collapse's SHAPE but not its
  SCOPE** (L3 F1, measured not argued: feeding it a reduced 4.3-nest stream as the
  new golden came back `COLLAPSE-ONLY`). It now carries a **scope check** — the
  reducer refuses a region whose routed base is itself a work rail (the nest's
  inner level), and a golden whose OLD trace bears a nest signature must be
  byte-identical or it is reported `OUT-OF-SCOPE`. Check **(A)** (the literal §9.2
  multiset delta) was computed, never enforced and not even printed without
  `--verbose`; it is now handle-INVARIANT, enforced, printed unconditionally, and
  joined by a `cqrt_cswap` accounting check. Untracked goldens are no longer
  skipped. And it grew a **`--selftest`**: 19 mutants (L3's, verbatim) + 4
  controls + the out-of-scope probe, over embedded goldens, **0 survivors**. Its
  one remaining gap is recorded IN the tool: a 4.5 switch's phase trace is
  **trace-indistinguishable** from a sequence of flat regions (measured,
  `slice_control_switch_phase` vs `slice_control_seq_regions`), so the switch half
  of the scope split is witnessed by the lit fixtures and the whole-corpus census,
  not here.
- **`tools/loop_twin_matrix.py` had no RECORD axis** (L1 §3.8) — no `int mark = a;`
  in any of its 156 cells, while 8h7d.5's F-1 and F-3, two of the three CONFIRMED
  silent miscompiles that machinery produced, were **entirely** about rail
  records. A fourth axis is added (`premark` / `postmark` / `bodyread`, crossed
  with a declared 12-cell sub-grid): **156 cells**, the table regenerated
  deliberately with **additions only — no existing cell's disposition moved**. 18
  of the 36 new cells are ACCEPT-IDENTICAL (a rolled trace byte-identical to its
  twin's *with a live record present*); the other 18 are the 8h7d.5 rail-record
  fence firing correctly on the rolled side.
- **Six fixtures could not witness a re-inserted route** (L3 F2): three
  `control_swap_cond_datause_*` carry `CHECK-NOT: cqrt_cswap` as the LAST
  directive of their prefix, so its window starts after the arm gate the route
  would precede, and three others lost a positive `CHECK: cqrt_cswap` in this edit
  and gained no negative. All six now carry the bounded `NOROUTE` prefix anchored
  at `define`, and each is **mutation-verified**: re-inserting
  `cqrt_alloc_<W>(0) + cqrt_cswap` before the first controlled gate turns
  `NOROUTE` red in 6/6 while **every pre-existing prefix stays green**, which is
  the measurement that shows the gap was real.

**One observation filed, not fixed.** The record axis surfaced a pre-existing
STRAIGHT-LINE behaviour: `int mark = a; a = cq_theta(a, 0.25); return
cq_measure(mark);` accepts with **rc 0 and no warning** and emits
`ry(%h,.5); ry(%h,.25); measure(%h); measure(%h)` — the record is measured at its
POST-Ry value. The LOOP half of that class is fenced
(`LoopLowering::staleRailRecordRead`, 8h7d.5 rounds 1–3); the straight-line half
is not. **Measured byte-identically on the pre-2a and post-2a binaries**, so
nothing in this increment moves it in either direction. Whether it should decline
is an owner question — under Rule 8 `int mark = a` is an ALIAS of one register, so
measuring the current register may be the only thing physically available, in
which case the right answer is a loud decline rather than a different unitary.

## 12. Increment 2 design (settled 2026-09-02, after the Inc 0+1 clearance)

Owner confirmations 2026-09-02: the Rz peephole is **default-on** (Q2 stands), and
`drbq.6` (angle-select by-difference) is **folded into Inc 2**. Inc 2 ships as two
commits: **2a** the Rz peephole, **2b** the angle-select lowering.

### 12.1 The two rotation stems get DIFFERENT uncompute treatment — measured, not chosen
The route path today leaves the register's chain untouched by the arm Rz (the Rz sits
on the work rail, freed inside the region), so after a phase region the whole-DAG spine
reverses and frees the register's dead chain exactly as if no region existed (probe
`h2`: `mul_unc ×2, free ×2` after the region). The in-place Rz must reproduce that
byte-for-byte after collapsing the route quintuple — the §9.2 audit — which forces:

| stem | DAG link (`isInPlaceGateOn`) | adjoint | freeze | WireWalk |
|---|---|---|---|---|
| `cqrt_ry_<W>_controlled` | link (as shipped) | never (flag dead) → whole DAG `NotClosed` | frozen (as shipped) | relabelling gate |
| `cqrt_rz_<W>_controlled` | **NOT a link** | **none** | **not frozen** | transparent (diagonal) |

Soundness of the Rz row: a controlled Rz is diagonal, so a skipped adjoint moves no
basis (the 261j clause-(d) trap cannot arise); the register's chain reversed after the
region returns the rail to `|0⟩` and the phase `e^{iθ·[f]·g(x)}` lands on the live
registers as a function of their basis — identical to the route's work-rail Rz. This
is the phase-kickback semantics; bd `wt3l` asks the owner whether the straight-line
uncontrolled user Rz should follow it too (today it is cancelled or leaked — NOT
changed by this epic). Both `railCarriesControlledRotation` and `isInPlaceGateOn` must
therefore be split by stem, and `preservesBasisUnderRecord`'s "freeable" verdict for
the Rz stem becomes the operative one (the §11 contradiction resolves in its favour).

### 12.2 Inc 2a — the Rz peephole, default-on — **IMPLEMENTED 2026-09-02**
> **Status: DONE.** Shipped as described below, with the stem split of §12.1.
> Implementation notes, the measured before/after streams and the two set
> REMOVALS are in
> `docs/prd/phase-04-swap-route-control/CONTROL_IN_PLACE_INC2A_NOTES.md`.
> Witnesses, all four run: (i) `tools/golden_multiset_audit.py` — 26 goldens,
> ALL `COLLAPSE-ONLY`, 65 regions / 66 arms / 70 rz gates, zero findings;
> (ii) the six 8h7d.5 `cmp` twin gates + `e2e-loop-twin-matrix` (156 cells,
> 105 ACCEPT-IDENTICAL / 12 DECLINE / 3 other, matching the committed expected
> table); (iii) `tools/inplace_twin_matrix.py --route-oracle <pre-2a cq-opt>`;
> (iv) `tools/control_flag_order_check.py` — 0 violations over 371 flags.
> Plus: `ir-pass-lit` 1358 fixtures green (1 XFAIL), full `ctest -j6` 295/295,
> `cq-opt-equivalence-full` 0 mismatches, `free_pairing_check_test.py` 0
> failures, and a whole-corpus disposition sweep against the pre-2a binary —
> **0 accept/decline flips and 0 diagnostic differences over all 1358 fixtures**.
> IR size stays independent of the trip count on
> `slice_control_grover_loop_dynamic.c` (77 lines at K=3 and at K=1000; it was
> 87/87 pre-2a).
>
> **THE `cqrt_x` COUNT.** §9.2's expected multiset delta is stated per arm as the
> quintuple alone; on a **NEGATED** arm it additionally carries `−cqrt_x(f) ×2`
> (the route brackets each of its two `cqrt_cswap`s = four; control-in-place
> brackets the gate run once = two). Net **−4 lines per non-negated arm, −6 per
> negated arm** — measured on `slice_control_phase_diamond` (12→8),
> `slice_control_phase_ifne` (15→9) and, per activation of a rolled loop, −8 for
> `eq` and −12 for the negated `der`. See §9.2's box; the audit models it and
> `--selftest`'s `f1`/`f2`/`f3` mutants pin it.
>
> **One thing shipped that this section did not name**, because the increment
> could not work without it: `emitRegion` needed the **§5 const-fold re-anchor**
> on the FIRST spine gate. The route read only arg 1 (the angle); hoist-and-defer
> reads arg 0, and an eq-folded arm's `cq_phi` bottoms at a `ConstantInt`, so
> without the re-anchor `lowerRotations` would emit nothing and RAUW the gate to
> the constant — the arm's Rz silently dropped. It is fenced (a first gate whose
> arg 0 is neither the routed base nor a `Constant` declines loudly).

Scope: every `cq_phi` phase spine the FLAT `emitRegion` path accepts today — diamond,
if/else, sequential regions (hcrg), the 8h7d.5 rolled loop, `ShareCondFlag` (strip
skipped, as today), multi-Rz spines (`rz; rz` in one arm — diagonal, no basis hazard),
Rz on the condition register (§3c permits it; R4 is Ry-only). Nested (4.3) and switch
(4.5) keep the route. Mechanism: the same hoist-and-defer through
`TaintSet::ControlledRotations`; `lowerRotations`' phi loop mints
`cqrt_rz_<W>_controlled(f, h, θ)` for a recorded `cq_phi` (the `emitRz(controlled=true)`
hook, dormant since 7cde677). Witnesses, all mandatory: (i) the §9.2 multiset audit as
a script (`tools/golden_multiset_audit.py`: old golden from `git show HEAD:…`, handles
normalised, the diff must be exactly k × {−alloc(0), −cswap, −cswap, −free(rail),
−rz(rail,θ), +rz_controlled(f,h,θ)} with θ matched, and NOTHING else); (ii) the six
8h7d.5 `cmp` twin gates + `e2e-loop-twin-matrix` byte-identical rolled≡unrolled;
(iii) `tools/inplace_twin_matrix.py` with its oracle INVERTED: a pre-2a `cq-opt` built
from `f92d95e` in a scratch worktree supplies the route stream; the 2a Rz stream must
equal collapse(route) on PREFIX AND SUFFIX (no freeze for Rz), the Ry stream on the
prefix as before; (iv) `tools/control_flag_order_check.py` 0 violations.

### 12.3 Inc 2b — angle-select by-difference (`drbq.6`), both stems — **IMPLEMENTED 2026-09-03**

> **Status: DONE.** Shipped as described below. Implementation notes, the walker/
> set audit, the mutation table, the goldens argued line by line and the
> "what worries me" list are in
> `docs/prd/phase-04-swap-route-control/CONTROL_IN_PLACE_INC2B_NOTES.md`.
>
> **Scoped to ONE consumer per select.** The C target shape has one; N consumers
> is a recorded follow-on because S6's positional scan is deliberately wire-blind,
> which would make an N-consumer accept ORDER-dependent.
>
> **ROUND-1 RULE-13 REVIEW (7 lenses, 2026-09-03) — FOUR ACCEPTED FINDINGS, all
> fixed here; read them before quoting anything above as settled.**
>
> 1. **S7 asked a NARROWER loop question than every sibling — TWO over-accepts.**
>    It was spelled `LoopInfo::getLoopFor` of `Cond`/`Sel`/`T`'s blocks only.
>    (a) an IRREDUCIBLE cycle has no `LoopInfo` loop, so S7 was VACUOUS on it and
>    the angle select ACCEPTED where the manual by-difference DIAMOND declines
>    `control flow inside a loop body` (the d8jl `regionEntryInLoop` walk is a
>    reducibility-independent CFG reachability) and the plain uncontrolled
>    rotation declines `crosses a loop backedge`; (b) the ROTATED REGISTER's rail
>    can live in a loop while all three anchors sit in the loop's EXIT block —
>    `lowerLoops` (`CQLoweringPass.cpp:310`) runs BEFORE detection (:322) and
>    emission (:323), so its `staleRailRecordRead` fence, which refuses the
>    diamond spelling of exactly this shape, structurally cannot see 2b's twin
>    `T0` (inserted 13 steps later). S7 now ORs three questions: `LoopInfo`,
>    `ControlShape.h`'s exported `blockOnCycle` walk over the three anchor blocks,
>    and either question over EVERY MEMBER of the base's rail closure. That
>    closure is now computed ONCE, for BOTH stems (the Rz stem computed none),
>    and REUSED by S8's intersection, S9's member set and S9's skip set unchanged.
> 2. **Nothing in S1–S10 inspected the arm VALUES.** An `undef`/`poison` arm
>    folded the difference to a concrete NaN and DESTROYED the well-defined arm
>    (`LiteralIntegrity`'s guard 1 is correct to stay silent: it counts one undef
>    slot, the other being the folded NaN); a non-finite constant arm, or an
>    overflowing difference of two FINITE ones, manufactured an `inf`/`NaN` the
>    source never named. Fenced in S1 via `angleSelectArmsAdmissible`, re-asked in
>    the emitter's step 0.
> 3. **THE ALGEBRA IS EXACT AND THE ARITHMETIC IS NOT.** The emitted true-arm
>    angle is `B + fl(A−B)`, so `|δ| ≤ ½ ulp(A−B) ≈ |A−B|·2^-53`: 2^-54 rad on the
>    flagship `0.9/0.3` golden, **0.858 rad on `π/1e16`**, **1.0 rad on
>    `1.0/1e300`** — the last two DECLINED LOUDLY on the pre-2b binary. CONSTANT
>    arms now compute δ exactly at compile time (TwoSum in APFloat at
>    `rmNearestTiesToEven`) and decline above `kAngleSelectMaxRoundingRad`, a
>    NAMED PLACEHOLDER of 2^-40 rad. **The ruling that would remove it is on the
>    owner's desk** — see the OWNER-DESK item in
>    `CONTROL_IN_PLACE_INC2B_NOTES.md` §9, now a THREE-WAY choice.
>    **RUN-TIME arms cannot be fenced at compile time and therefore DECLINE**
>    (Rule-13 CLEARANCE review, finding F-11 / ranked blocker B1; the round-2
>    review had graded the class CONFIRMED-MISCOMPILE and the disposition then was
>    "stay accepted, document the residual" — notes §10 — which the clearance
>    review ranked BLOCKING and the owner resolved as option (2), notes §11). The
>    two residual halves are now the REASON for the refusal: (i) the rounding
>    `|δ| ≤ ½ ulp(A−B)` bounds the DIFFERENCE and is unbounded in absolute
>    radians, measured **0.858 rad from plain C** with `π`/`1e16` as run-time
>    angles (`Ry(π)` realized as `Ry(4.0)`), and (ii) a **NON-FINITE `fl(A−B)`
>    from two FINITE arms**, measured `cqrt_ry_i32_controlled(f, h, inf)` from
>    `±8.99e307`, which no half-ulp bound describes. Note that (ii) is the SAME
>    class this finding's item 2 fences for constant arms — before the narrowing,
>    which of the two you got depended only on how the user SPELLED the angle. The
>    twin witness could never have seen either, since the manual twin performs the
>    identical `fsub`; what decided it instead is that **the manual twin of a
>    run-time-arm by-difference program does not compile at all** — `clang -O1`
>    sinks the `fsub` into the arm block and `inPlaceRotationArmTheta` refuses it,
>    on BOTH binaries — so the residual was reachable only through 2b rather than
>    inherited from an already-accepted shape (clearance observation 1).
> 4. **The emitter's step 0 re-validated SSA IDENTITY but not S4's SEMANTIC
>    half**, so a preceding `SwitchDataMux` region's RAUW could turn the compare
>    Q+Q and the emitter bailed MID-STREAM (after the `fsub` and the twin), with a
>    mislabelled `no template for opcode 'icmp i1'`, loud only because `DS_Error`
>    exits. Step 0b now re-asks S4 in lockstep before the first `CreateFSub`, and
>    `AngleSelectEmit.h`'s "every bail precedes the first emitted instruction" is
>    true rather than aspirational.
>
> Also recorded by that round, NOT fixed: two SOURCE-ORDER-dependent OVER-DECLINES
> (an angle select followed by an Rz diamond on the same register, and an angle
> select followed by a value arm / data select on the same register — the reverse
> order accepts in both cases), which are Rule-13 changes to `taintedAngleGate`
> and to gate 5's coherence fence. See notes §9.
>
> **Witnesses, all run:** (i) THREE e2e subject/twin pairs with `compare_files`
> gates (`e2e-angle-select-{ry,ry-ne,rz}-twin-identical`), byte-identical, and
> the twin goldens additionally verified byte-identical when produced by the
> PRE-2b binary; (ii) `tools/angle_select_twin_matrix.py` — 158 all-pairs cells /
> 632 full pipelines: **116 BOTH-ACCEPT-IDENTICAL, 0 MISMATCH, 0 ORACLE-MOVED,
> 0 RED-GREEN-MISS, 0 stage-2b failures** (after the clearance narrowing: 102
> BOTH-ACCEPT-IDENTICAL + the 16 `angle=args` cells reclassified
> EXPECTED-DECLINE-RUNTIME-ARMS, the other 142 line-for-line identical); (iii) a whole-corpus disposition sweep
> against the pre-2b oracle — 1407 fixtures, 35 moved, every one accounted for
> (17 intended accepts, 15 message sharpenings, 3 pre-existing `ogw2` eq-fold
> cells); (iv) a 17-row mutation matrix, which produced THREE fixtures for
> clauses that had none. Plus `ir-pass-lit` 1406 + 1 XFAIL,
> `ctest -j6 -R '^e2e-'` 295/295, `cq-opt-equivalence-full` 1407/0,
> `golden_multiset_audit --all` 280 goldens with **no existing golden moved**,
> `control_flag_order_check` 0 violations over 391 flags, and
> `e2e-loop-twin-matrix` unchanged.
>
> **FOLLOW-ONS, recorded rather than built:** N consumers on one select;
> a SECOND select on one compare (the `if(c){g1;g2}else{g3;g4}` fold); a compare
> shared with a `br` region or with a data use (one flag, two owners — the
> `ShareCondFlag` analogue); a Q+Q condition (the 4.4 data select admits one via
> `qqSelectLeafWidth`); a `float`-armed select behind an `fpext`; the in-loop form
> (Increment 3 = `drbq.4`, which must re-ask S9's flat position predicates with a
> per-activation barrier); and controlled state prep (Increment 4).
>
> **TWO EXISTING FIXTURES FLIPPED TO ACCEPT** and were rewritten in full:
> `control_swap_defer_select_angle.ll` (the shape this section describes, which
> that fixture had pinned as a DEFER since 4.4 WI-1) and
> `control_swap_reject_switch_datamux_angle.ll`. The second is worth reading: its
> header claimed the shape was "a Rule-3 f64/angle wrong unitary if lowered",
> which was true of the lowering that existed then and is false of this one —
> 2b never realizes the angle as a number, it emits the controlled rotation the
> source describes with every emitted angle classical. That cell is also the live
> exercise of §6's `TaintSet`-not-`ControlPlan` decision: it is detected and
> emitted inside the yn71 onward-control fixpoint, whose `plan2` is discarded
> before `lowerRotations` runs.
>
> **One thing this section did not name, and it is a dependency rather than a
> design choice** (notes finding H): the flag is minted AT THE CONSUMER, so an
> in-place `cqrt_addc`/`cqrt_xorc` on the CONDITION's rail between the source's
> compare and the consumer would mint a wrong predicate — and S6's positional
> scan looks for `cq_theta` only, while the Rz stem is exempt from S8. It is
> correct on every reproducer measured, **because `lowerOps` runs after this
> emitter and M-C refuses an in-place conversion when a later read exists — our
> own mint and strip being exactly that.** If M-C's later-read test ever narrows,
> S6 must be widened to the rail for BOTH stems, and that is a Rule-13 change.

Shape: `%a = select i1 %c, double A, double B` whose **ONE** user is the arg-1
(angle) slot of a `cq_theta`/`cq_phi` call with TAINTED arg-0; `%c` a lowerable
tainted compare (the same mint the regions use) with exactly one tainted operand
and exactly one user; `A`, `B` classical. Lowering, for that ONE consumer
`R(h, %a)`: `R(h, B)` uncontrolled; `f = icmp(%c)` minted **AT THE CONSUMER**
(not at the compare — the design draft said "at the compare" and the shipped
emitter mints at `T`, which is what makes the compare→consumer window the flag's
staleness window and why S6 scans to `T`); `R_controlled(f, h, A−B)` (`fsub` on
the classical operands, constant-folded when both are constants); `icmp_unc`;
`free(f)`.

**Exact in REAL arithmetic** by angle additivity on one axis
(`Ry(a)=Ry(b)·Ry(a−b)`, same for Rz — under `Rz = diag(1,e^{iθ})` the two
diagonals multiply entrywise, so no global-phase residue). **In IEEE double the
emitted true-arm angle is `B + fl(A−B)`, `|δ| ≤ ½ ulp(A−B)`**, so `A`, `B` must be
classical **CONSTANTS** (`ConstantFP`), fenced at the placeholder
`kAngleSelectMaxRoundingRad = 2^-40 rad`. **RUN-TIME classical arms DECLINE** —
owner option (1) widens back, in one line. They cannot be fenced at compile time
and carry BOTH residual classes: that rounding bound, unbounded in absolute
radians, AND a non-finite `fl(A−B)` from two FINITE arms (round-1 review finding 3
above for the constant half; round-2 review lens R1 item 1 for the both-halves
statement; the CLEARANCE review's finding F-11 for the narrowing).

> ### OWNER-DESK ITEM — THE THREE-WAY CHOICE, VERBATIM (also in notes §9)
>
> "(1) accept-with-residual: round-to-nearest angle arithmetic is IN the
> model, the runtime residual (both halves) is documented, the 2^-40 constant
> placeholder goes; (2) decline runtime arms (constant arms only) until (3)
> — **SHIPPED**; (3) the two-controlled form x(f)·R_c(f,h,B)·x(f)·R_c(f,h,A) — no
> fsub, no rounding, no inf/NaN manufacture, no undef fold, existing symbols only,
> one extra controlled gate + an X pair, twin = two Inc-1 diamonds, exact for
> runtime arms too — a PRD §12.3 design change."
>
> **Option (2) is what shipped**, on the Rule-13 clearance review's blocker F-11
> (notes §11). It was separable and cheap exactly as predicted: constant arms were
> already fenced, so refusing only the runtime ones cost **two fixtures rewritten,
> ZERO e2e goldens, and 16 twin-matrix `args` cells reclassified** — measured, not
> estimated. Options (1) and (3) stay on the desk. **Option (1) is ONE line** —
> `angleSelectArmsAdmissible` clause (2c) returns `true` again — plus the three
> run-time decline fixtures flipping and the matrix class flipping; it requires an
> explicit ruling that round-to-nearest angle arithmetic AND non-finite angle
> arithmetic are BOTH in the semantic model, the second half being the one option
> (1)'s own stated reasoning does not reach. Option (3) removes both halves
> outright and is exact for run-time arms too.

For the Ry stem every Inc-1 fence applies verbatim (R4 disjoint wires —
`cq_theta(q, q==5 ? A : B)` declines; R6 stale record; the classical-angle rule on BOTH
select arms; the freeze); for the Rz stem the 12.1 transparency. No CFG, no hoist, no
flatten.

Declines: any other user of `%a`, a nested/second select in the angle, a
non-lowerable or Q+Q compare, a tainted `A`/`B`, the select's condition also used as
control of a region (`ShareCondFlag`-like: decline in 2b), **an `undef`/`poison`
arm or a `ConstantExpr` carrying one, ANY `Constant` arm that is not a
`ConstantFP` (a link-time constant this compiler cannot evaluate — round-2 review
lens R1 item 5), a non-finite constant arm, a non-finite
difference of two finite arms, a constant-arm pair whose rounding residual exceeds
the placeholder bound, and any form in a loop OR ON A CFG CYCLE — including one
that only the rotated register's RAIL sits in** (the last two families are the
round-1 review's).
**What S7's cycle question does NOT reach, stated because the round-1 comment
claimed otherwise:** the rotated register's rail FORWARD of the consumer (the
closure carries `Exclude = T`) and the CONDITION register's rail at all. Both
accept; both are byte-identical to the manual by-difference twin on the pre-2b
oracle, so the disposition belongs to Inc-1's structural freeze rather than to
this increment (round-2 review, lens R1 item 2; accept fixture
`control_angle_select_forward_rail_cycle_frozen.ll`). And prong (iii)'s coverage
of the loop-rail family is CONTINGENT on `lowerLoops`' Case-A rail collapse having
already re-anchored the in-loop gate onto the base — a change there silently
narrows S7 (lens R1 item 3). This is what makes the C
`if/else` with two rotations on one register compile (clang merges it into exactly this
shape); the hand-IR if/else fixture stays as the two-block form's pin.

---

## 13. Increment 3 design — the Ry arm in the 8h7d.5 rolled loop (settled 2026-09-04)

> **Status: IMPLEMENTED 2026-09-04** (bd `test_C_libtooling-drbq`, child
> `drbq.4`), BOTH halves — §13.3+§13.2b (the loop) and §13.4b (P1). Shipped
> counts, all measured at the implementing commit and **not** inherited from the
> design: **+29 lit fixtures** (1430 → **1459**; the family is 11 accepts / 19
> declines over 30 files, of which one — `control_inplace_ry_reject_in_loop.ll` —
> was an EXISTING decline rewritten in full as
> `control_inplace_ry_inloop_diamond.ll`, its decline re-homed onto
> `..._reject_inloop_alias.ll`); **+15 ctest entries** (305 → **320**:
> 10 e2e slices — 5 rolled + 5 hand-unrolled twins — and 5 `cmp` twin gates; the
> round-1 review added a SIXTH pair and gate, the O(K)-freeze-leak reproducer, for
> **+18 / 323** in total);
> **0 existing goldens moved** (`golden_multiset_audit.py --all`: 290 goldens, 10
> NEW-FILE, 280 UNCHANGED, 0 routes collapsed). Whole-corpus HEAD-vs-oracle sweep:
> **14 of 1458 lit fixtures differ and every one is a file this increment added**
> (re-measured after the round-1 review: **24 of 1473**, still every one this
> increment's own — **18** accept-flips and 6 stderr-only R6 message changes;
> the round-2 review re-swept independently and corrected 23/17, which had been
> taken before the round's last fixture was written — notes §12; the CLEARANCE
> review re-swept all **1474** after the round-2 mini-fix's own fixture: **25 = 19 +
> 6**, still every one this increment's own, with ZERO lowered-IR differences on any
> file both binaries accept). With the ONE
> fixture round 2 added the corpus is **1474**);
> **8 of 274 e2e slices differ, 7 of them added here and the 8th a harness
> artifact** (`slice_multi_lib.c` is a deliberately CQ.h-free helper TU whose
> `#error` tripwire fires under the sweep's force-include, identically on both
> binaries). K-independence, measured on the Grover slice: **74 lines of lowered
> IR at `-DCQ_K=3` and 74 at `-DCQ_K=1000`**, differing only in the trip constant,
> while the trace goes 36 → 10006 lines.
>
> **THE INCREMENT DOES NOT SHIP A GREEN SUITE, and that is the headline finding
> rather than a footnote.** Full `ctest -j6`: **319/320**, 476.7 s on a loaded box.
> The one red is `e2e-loop-twin-matrix`, on **15 of its 273 cells**, in two
> divergence classes — a hoisted loop-invariant derived chain whose top rail the
> ROLLED form leaves allocated and the flat form discharges, and the M-C
> in-place-vs-out-of-place decision on a trailing `a += off`. **Both reproduce
> character-for-character on the pre-Inc-3 oracle with an `Rz` arm**, and a
> no-region control AGREES on both sides — so both are PRE-EXISTING and
> arm-class-independent, exposed only because this axis is the first whose ARM
> ROTATES A REGISTER THE CONDITION DOES NOT READ. Neither is in §13's scope to fix
> (one is `Uncomputation`'s interior placement, the other `ArithLowering`'s M-C
> decision versus the round-2 marking; both would move shipped Rz goldens). The 15
> rows were **restored to their pre-Inc-3 verdicts rather than regenerated**, so
> the table never records a `TRACE-DIVERGENCE` as an expected outcome and the gate
> stays red on exactly the finding. Owner disposition required — notes §10.1.
>
> > **CORRECTED 2026-09-04, ROUND-1 REVIEW (lens L7): THE SUITE IS GREEN AND THE
> > FINDING IS UNDIMINISHED.** Leaving the gate permanently red was the one option
> > the lens pushed back on hardest, on Rule 19's own argument: a gate expected to
> > be red is a gate people stop reading, and the 8h7d.5 F-4 class was found
> > BECAUSE the gate was green and one cell went red. The three cheap ways out are
> > all forbidden by the instrument's charter (bless the verdict = retire the gate;
> > delete the cells = the `165/174` move, making a number green by changing what
> > it measures; fix `Uncomputation`/`ArithLowering` under increment pressure = two
> > Rule-13 subsystems this increment did not touch). What shipped instead is a
> > **PINNED-SIGNATURE QUARANTINE**, `tools/loop_twin_matrix.quarantine.txt`: the
> > 15 cells leave `expected.txt` (258 rows) and are pinned to the SHA-256 digest
> > of the exact unified diff of their two traces, with class, bd id, and owning
> > subsystem **plus direction**. It fails in BOTH directions — signature changed,
> > or cell stopped diverging ("quarantine stale — remove it"), or cell present in
> > both files — and any non-quarantined divergence still fails as before. Two
> > BOUNDARY CONTROLS run beside the cells on every invocation (no region ⇒
> > identical; arm ON the condition register ⇒ identical), so the class story is a
> > measurement rather than a paragraph. **⚠ 'On every invocation' became true
> > only in the ROUND-2 review (notes §12, F-R2-2): as first written the controls
> > sat below the `--regenerate` and `--refresh-quarantine` early returns, so both
> > write modes exited 0 with a control diverging — and `--regenerate` wrote the
> > forbidden `TRACE-DIVERGENCE` row to disk before printing that it had refused
> > (F-R2-1). Both are fixed, and the quarantine selftest went 7 → 12 cases,
> > three of them asserting on FILE BYTES.** Full `ctest -j6` is now **324/324**
> > (notes §7, measured on a loaded box after the round-1 review). bd
> > `test_C_libtooling-1m5p` (class A, 6 cells, `Uncomputation`/`FreePoint`, ROLLED
> > deficient) and `test_C_libtooling-a3z7` (class B, 9 cells, `ArithLowering` M-C
> > vs `collapseRailPhisIn` step (3), **FLAT** deficient — the rolled circuit is the
> > BETTER one, so "make the roll match the flat" would make it worse). L7 rebuilt
> > all 15 controls itself and confirmed 15/15 identical signatures on the oracle.
> > ⚠ And it recorded the scoping honestly, which belongs here too: **Inc 3 does
> > not create these classes, it adds CUSTOMERS to them** — all 15 shapes declined
> > before this increment and compile now.
>
> **Corrections this section owes are
> marked `CORRECTED 2026-09-04` in place — read them; four §13 claims were
> falsified by measurement and the dispositions they argued for all survived. The
> ROUND-1 REVIEW added more, marked the same way: §13.4b's M-A ownership sentence
> (struck — it does not fire for an escaping condition record), §13.8's
> "3 `ry`-prefix cells most likely stay" (2 flipped to ACCEPT-IDENTICAL, sound;
> 1 is the §10.2 mismatch), and the notes' §7a "no flat movement" (15 `*_printf_*`
> cells DID move; disposition = keep, measured on the oracle). The full finding
> table is notes §11.**
> Companion notes:
> [`CONTROL_IN_PLACE_INC3_NOTES.md`](CONTROL_IN_PLACE_INC3_NOTES.md).
>
> **Original design header (written at HEAD `1bdaa60`), kept verbatim below.**
>
> **Status at design time: DESIGNED, NOT IMPLEMENTED.** Written at HEAD `1bdaa60` against a
> `cq-opt` byte-identical to the pre-Inc-3 oracle (`md5 5ae372bf94d7dffd…`, 43
> stderr comparisons and 10 lowered-IR comparisons, **0 differences** — the two
> binaries are the same file, so every "measured on both binaries" claim below is
> literal rather than a coincidence re-checked per program). Implementing epic bd
> `test_C_libtooling-drbq`, child `drbq.4`. Owner scoping Q8: *"in a classical loop
> (so classical bounds), cRy should NOT decline. nesting is a different story."*
> **A Rule-13 core change** touching `ArmClassify`, `SwapRouteEmit` and
> `LoopLowering` — three of the six modules Rule 13 names. Budget **≥3 adversarial
> rounds**: the loop machinery is 4-for-4 on hidden over-accepts and this epic is
> 3-defects-in-round-1.
>
> **THE HEADLINE, AND IT IS NOT WHAT THE INCREMENT WAS SCOPED AS.** Lifting R7's
> loop clause is **necessary and not sufficient**. Measured on the nine in-loop
> Ry-arm C programs, the *printed* diagnostic is
> `condition predates a non-diagonal gate` for every one of them — and that string
> is a **re-spelling**, not the reason (`ArmClassify.cpp:1342-1348`'s `declineArm`
> lambda rewrites every later decline whenever the condition wire carries a
> provably-post-region non-diagonal gate, which the customer's own
> `q = cq_theta(q, θ)` reflection always is). Change that one token to `cq_phi` and
> the real reason appears: `control flow inside a loop body`, `ArmClassify.cpp:1645`,
> R7, in **all nine**. But the hand-unrolled TWIN of the same programs **also
> declines**, with **no loop present at all**, at a *second and independent* fence —
> `ArmClassify.cpp:2011-2013`, the Increment-4 P1 clause
> `if (DeferredWireGate && (SawValueArm || !SawPhaseArm))`, which is
> **phase-arm-only** and has no `SawRotationArm` disjunct. So the flagship customer
> (Grover: Rz oracle + controlled Ry on an ancilla + **Ry** reflection) is *two*
> fences away, the 8h7d.5 rolled-vs-unrolled byte-identity witness does not exist
> for it until P1 moves, and an Inc 3 that lifts only R7 ships the Rz-reflection and
> dtzb-offset loops while still declining the program it was scoped for — which is
> Rule 17's "a decline is not the development escape hatch". **Both fences move in
> this increment.** §13.4b owns P1.

### 13.1 The accept shape, and the physics

**The shape.** A `BranchRegion` that satisfies §4's R1–R6 verbatim, whose `Pred`
sits inside a loop `L` that `ControlDetect::flatRegionRollableInLoop` proves
rollable ((A) natural `LoopInfo` loop, (B) every region block at exactly `L`'s
depth, (C) single latch, (D) the entry on no cycle other than `L`'s back edge),
whose rotated base's **rail crosses `L`'s back edge** (§13.2 row L-b), and whose
condition-wire disposition is `None` or `ProvenPostRegion` (§13.4b). The region's
arm is ONE tainted-arg-0 `cq_theta` on a register whose physical wire is disjoint
from every condition wire (R4), with no post-region read of a pre-Ry record of that
wire **per activation** (R6, §13.3). Diamond and if/else; one region per condition,
any number of regions per loop body (sequential regions in a loop already lower for
the Rz stem — `control_swap_inloop_seq.ll`). Depth-2 nests, switches, angle
selects, value arms, `ShareCondFlag`, classical-call arms, irreducible cycles,
multi-latch loops, state prep and Ry on the condition wire all keep their declines
(§13.2). The loop stays **ROLLED**: one copy of the body, IR size independent of
the trip count.

**FROM C, THE CONDITION REGISTER MUST BE LOOP-VARIANT.** This is not a fence, it
is a consequence of `clang -O1`, and it is a THIRD wall the matrix found (§13.2 row
W): with no gate on `q` in the body, `q` is loop-invariant, so LICM hoists the literal
compare `q == 5` into the preheader (and CSEs the two compares in the hand-unrolled
twin). `condWireDisposition`'s P4 precondition then fires — `Cond->getParent() !=
R.Pred`, `ArmClassify.cpp:947-948` — and BOTH sides decline `condition predates a
non-diagonal gate` before any rotation clause is reached. So the C accept class is
exactly: **a gate on the condition register inside the body** (`q = cq_phi(q, θ)`, a
dtzb `q += off`, an `Rz` region on `q`, or — after §13.4b — `q = cq_theta(q, θ)`), OR
a compare that reads something the optimizer cannot hoist (a `volatile`, which is what
the matrix's `oeq`/`one`/`oder` opaque family uses). **The Grover customer always
satisfies this** — its reflection is exactly such a gate — but the simplest C spelling
of the shape does not, and it will STILL decline after this increment (§13.10 Q1).

**The physics, per activation.** Nothing about the unitary is new — this is
Increment 1's stream executed K times. Each trip: mint `f = [pred(C)]` on a fresh
`|0⟩` rail from the condition registers' *current* basis; fire
`cqrt_ry_<W>_controlled(f, R, θ)` (bracketed in a self-inverse `cqrt_x(f)` pair on
a ¬flag arm); strip `f` with the uncontrolled `cq_template_icmp_…_hl_unc(f, C, k)`,
which recomputes the predicate on `C` and XORs it back — valid because R4 proves
`R`'s wire ∉ `C`'s wires, so `C`'s computational basis at the strip is the basis the
mint read; `cqrt_free(f)` on a provably-`|0⟩` rail (Rule 6). The register `R` is
relabelled on the `f=1` branch of *this* activation, and the rail is loop-carried
**through** the region: the state entering trip k+1 is the state trip k left. The
flag is the region's only ancilla and it is born and dies inside the iteration, so
**nothing dirty crosses the back edge** — the same property the 8h7d.5 phase path
was cleared on, with `cqrt_rz_<W>_controlled` replaced by `cqrt_ry_<W>_controlled`
and one extra obligation: an Ry is **not** diagonal, so the rail-record machinery
must see it as a gate (§13.3, §13.4). `R` is FROZEN by Inc 1's structural freeze —
never reverse-played, never freed — per activation as well as flat (§13.5).

**The per-activation reference stream, measured**, from `FLAT1x1diag`
(one activation; the FLAT twin with an `Rz` reflection, since the `Ry`-reflection
twin does not lower at HEAD — that is the P1 finding):

```
cq_template_icmp_eq_i32_hl(%h, 5) -> %h_cmp
cqrt_ry_i32_controlled(%h_cmp, %h1, 9.0e-01)
cq_template_icmp_eq_i32_hl_unc(%h_cmp, %h, 5)
cqrt_free(%h_cmp)
```

Four calls per region per activation, no `cqrt_alloc` in the body, no `cqrt_cswap`,
no work rail. That block, repeated once per trip in the hand-unrolled twin, is what
the rolled body must emit **once**, byte for byte — the increment's load-bearing
witness (§13.9 lens 7).

### 13.2 The decline partition

Every row is a **loud** `DiagnosticInfoUnsupported` with a negative fixture
mirroring the string character-for-character (Rule 12). **No new diagnostic string
is added by this increment** — every decline below reuses one already in the
dialect, which is deliberate: a new string is new fixture surface and this
increment has enough.

| # | shape | clause that owns it | exact diagnostic (post-`under quantum control` suffix where shown) | fixture |
|---|---|---|---|---|
| L-a | irreducible cycle carrying the region | `flatRegionRollableInLoop` (A) | `cq controlled lowering: control flow inside a loop body under quantum control` | `control_inplace_ry_reject_inloop_irreducible.ll` |
| L-b | **rotated base's rail does not cross `L`'s back edge** (an iteration-local rotated register) | NEW R7-loop clause (b), §13.2b | same | `control_inplace_ry_reject_inloop_iterlocal_base.ll` |
| L-c | region blocks at two loop depths / nested loop | **CORRECTED 2026-09-04:** the shipped fixture is the region WHOLLY INSIDE an inner loop with the rail crossing BOTH back edges, and `flatRegionRollableInLoop` (A)-(D) all **PASS** for the inner loop. What refuses it is R7-loop clause (b'): the inner header's rail phi has its external incoming coming from the OUTER header phi, and `peelInPlaceBase` STOPS at a phi, so `railPhiRootMint` returns null. Same string, different owner. (A genuine (B) failure for a flat DIAMOND could not be constructed: Arm/Merge can only be at a deeper depth if one of them is an inner-loop header, which breaks `armBlockIsPureSpine` or `soleMergePhi`; the Pred-in-inner/Merge-in-outer spelling makes the tainted `br` a loop EXIT, which `tryCaseA` L1 claims first as row L-l) | `control_inplace_ry_reject_inloop_nested_loop.ll` |
| L-d | multi-latch loop | (C) | same | `control_inplace_ry_reject_inloop_multilatch.ll` |
| L-e | a second, `LoopInfo`-invisible cycle through the entry | (D) | same | `control_inplace_ry_reject_inloop_second_cycle.ll` |
| L-f | depth-2 nest inside a loop | `ControlDetect` `RegionShape::Nested` + `regionEntryInLoop` | `cq controlled lowering: nested control flow under quantum control` | `control_inplace_ry_reject_inloop_nested.ll` |
| L-g | tainted `switch` in a loop | `SwitchClassify` / existing | existing string | `control_swap_reject_inloop_switch.ll` (exists, unchanged) |
| L-h | tainted-condition **angle select** in a loop or on any cycle | `classifyAngleSelect` S7 (§13.6 — **stays declined**) | `cq controlled lowering: control flow inside a loop body under quantum control` | `control_angle_select_reject_loop_*.ll` (exist, unchanged) |
| L-i | `if/else` with a rotation in EACH arm, in a loop | `clang -O1` folds it to an angle select ⇒ L-h | as L-h | `control_inplace_ry_reject_inloop_ifelse_c.ll` (C-shape note) |
| L-j | method-B **value** arm in a loop | `ControlDetect` in-loop scope fence part 2 | `control flow inside a loop body` | `control_swap_reject_inloop_value_arm.ll` (exists) |
| L-k | 6.5 classical-call arm in a loop | in-loop scope fence part 1 (classifier skipped) | existing | existing |
| L-l | quantum/measurement-bounded loop exit | `tryCaseA` L1 (runs BEFORE detection) | `cq loop lowering: loop under quantum control` | existing |
| L-m | X1 cross-iteration dirty rail | `collapseRailPhisIn` step (1) / `tryCaseA` | `cq loop lowering: loop-carried tainted value crosses iterations` | existing |
| R4 | Ry on the CONDITION register's own wire, in a loop | R4 (a wire-SET question — position-free, unaffected by the loop, §13.3d) | **CORRECTED 2026-09-04:** `cq controlled lowering: condition predates a non-diagonal gate under quantum control` — *not* R4's own string. `declineArm` re-spells every later decline whenever `condWireDisposition` returned `ProvenPostRegion`, which the arm's own `cq_theta` on the condition wire always is. MEASURED IDENTICAL on the FLAT sibling `control_inplace_ry_reject_cond_register.ll`, so this is pre-existing and not an Inc-3 regression — it is §13.11 worry 2, met in the field | `control_inplace_ry_reject_inloop_cond_register.ll` |
| R6-1 | a pre-Ry record read after the loop (`int mark = r;` … `cq_measure(mark)`) | R6 per activation, §13.3 | `cq controlled lowering: stale rail record read past a controlled Ry under quantum control` | `control_inplace_ry_reject_inloop_premark.ll` |
| R6-2 | the **j4** shape: a dead `cq_phi(r_pre, ·)` written after the region in the body | R6 per activation (ALIAS-HOP half) | same | `control_inplace_ry_reject_inloop_j4.ll` |
| R6-3 | the **ALIAS** shape: a self-carry `%P = phi [%r0, pre], [%P, latch]` rotated in place while the merge escapes (two copies of one wire — Rule 8) | R6 per activation, via the PHI-EDGE read-position rule; **and** independently by the refresh fence (`phiTracksWire(%P)` false) | same | `control_inplace_ry_reject_inloop_alias.ll` (hand IR) |
| R1 | two thetas, or theta+phi, in one arm | `inPlaceRotationArmTheta` / homogeneity | `mixed phase/value arm` / `control flow` | `control_inplace_ry_reject_inloop_two_gates.ll` |
| R1' | controlled **state prep** (classical arg-0) in a loop | R1 (Inc 4 owns it) | `control flow` | `control_inplace_ry_reject_inloop_stateprep.ll` |
| R2 | tainted angle in a loop | R2 | `rotation angle` | `control_inplace_ry_reject_inloop_tainted_angle.ll` |
| R7' | `ShareCondFlag` region in a loop | R7's ziov clause | `rotation arm shares the condition flag` | `control_inplace_ry_reject_inloop_sharecond.ll` |
| P1 | condition wire gains a non-diagonal gate that is **not** provably post-region (before the compare, on a sibling alias, through a pre-compare router) | `condWireDisposition` → `DeclineNow` | `cq controlled lowering: condition predates a non-diagonal gate under quantum control` | `control_inplace_ry_reject_inloop_stalecond.ll` |
| X | in-body pure-op read of the register that `clang -O1` **sinks to the exit block** (`acc = r * 7`) | **`declineStaleRecordOps`, a DIFFERENT STAGE** (`CQLoweringPass.cpp:282`, before detection) | `cq opcode lowering: operand predates a non-diagonal gate` | recorded, not owned here |
| **W** | **condition register LOOP-INVARIANT** ⇒ `clang -O1` LICM-hoists the compare to the preheader (rolled) and CSEs the two compares (flat), so the compare no longer lives in the region's `Pred` | **`condWireDisposition`'s P4 precondition**, `ArmClassify.cpp:947-948` (`Cond->getParent() != R.Pred` — "unbounded gap across blocks"), reached from `classifyArms`' call at `ArmClassify.cpp:1325-1326` | `cq controlled lowering: condition predates a non-diagonal gate under quantum control` | `control_inplace_ry_reject_inloop_invariant_cond_hoisted.ll` (+ a C-shape note) |
| **DB** | a DERIVED OUT-OF-PLACE base minted before the loop (`int r = p * 5;` then the Ry arm on `r` in the body) — the finding-L family | `collapseRailPhisIn` step (1) requires the root to peel to a **classical-arg-0 `cq_theta` mint**; a `mul` is not a `CallInst`, so it `continue`s and `r`'s header φ is never collapsed. The surviving tainted header φ then reaches `declineClassicalMuxes` (`:399`), where `liftOneRegisterMergePhi` fails at its clause (3): `resolveWireBase(%mul)` = `%mul` while `resolveWireBase(T)` peels to the header φ, two distinct bases | `cq taint escape: tainted value muxed by a classical-condition phi` — **loud, but downstream of emission and the flatten, and it mislabels a quantum register as a classical mux** | `control_inplace_ry_reject_inloop_derived_base.ll`; see §13.2c |
| Y | a rail record read past an in-place gate, post-flatten | `LoopLowering` round 2 `staleRailRecordRead` | `cq loop lowering: rail record read past an in-place gate on the same rail` | `lowering_reject_inloop_rail_*.ll` (exist) |
| Z | Rule-8 fan-out on the loop-carried rail | `collapseRailPhisIn` step (2) | `cq loop lowering: loop-carried rail has multiple in-place consumers` | existing |

**Row X is the one a reader will get wrong, so it is stated with its measurement.**
`BODYREAD` (`for (…) { if (q==5) r = cq_theta(r,.9); acc = r*7; } measure(acc)`)
declines **before control detection ever runs**, because `clang -O1` sinks the
`mul` into the loop exit block and `declineStaleRecordOps` (pipeline step at
`CQLoweringPass.cpp:282`) refuses it on `r`'s wire. Lifting R7 does **not** make it
compile, and it prints `<unknown>:0:0` even in a `-g` build because clang drops the
sunk instruction's `!dbg`. Do not write a fixture that claims this row for R6.

**Row W is the third wall, it was found by the MATRIX and not by this analysis, and
the matrix agent's own attribution of it is one clause off — corrected here from the
IR.** The remedy family in the matrix (`oeq`/`one`/`oder`, whose compare reads the
`volatile int off`) is right about the *cause* — the compare is hoisted/CSE'd out of
the region's `Pred` — but the clause that fires is **not** the wire-blind gate-2c
WINDOW scan (`ArmClassify.cpp:954-962`, the compare→branch chained-`cq_theta` loop).
It is the **P4 precondition two lines above it** (`:947-948`). Measured, on
`m_none_req_none_none_none`'s own `-O1` IR: rolled, `%3 = icmp eq i32 %1, 5` sits in
the ENTRY block while the region's `Pred` is the loop header `%8`; flat, the two
compares are CSE'd to one `%3` in the entry block while region 2's `Pred` is region 1's
merge `%6`. In both cases `Cond->getParent() != R.Pred` and the function returns
`DeclineNow` **before** the window scan runs — so **the arm's own Ry on `r` plays no
part in this decline at all**. That distinction is load-bearing for the remedy (§13.10
Q1): making the window scan wire-aware would not move one of these 16 cells.

**Disposition for Inc 3: row W STAYS DECLINED, recorded as an OVER-DECLINE.** The
argument that it is one: the only thing between the hoisted compare and the branch is
the arm's own `cq_theta` on `r`, and **R4 has proved `r`'s physical rail disjoint from
every condition rail** — so the flag minted at `BI` reads exactly the basis the source
compare read, and the `icmp_…_unc` strip returns it to `|0⟩`. The unitary is fine; what
is missing is a clause that can *say so*. Both P4 and P5 are position-only and
wire-blind by design, and widening either is a sibling-spelling change shared with the
phase path, the 4.4 select's gate 2c and 2b's S6 — a Rule-13 change to four callers,
which is why it is **not** in this increment. The fixture pins it as a DECLINE with the
exact string, so the day it moves, it moves deliberately.

> **CORRECTED 2026-09-04 — §13.2c's PREDICTED PROBE MESSAGE WAS WRONG; ITS
> DISPOSITION WAS RIGHT.** The probe was run FIRST, exactly as demanded, on a
> throwaway build with R7's loop clause lifted and NOTHING else changed. The
> module did **not** accept — so there was **no over-accept and the increment
> proceeded** — but it did not reach `declineClassicalMuxes` either. It declined
> `cq controlled lowering: stale rail record read past a controlled Ry under
> quantum control`, on R6's **FLAT** position predicates, which fire long before
> emission. The predicted `tainted value muxed by a classical-condition phi` is
> what it would print with R6 *also* made per-activation and clause (b') absent —
> i.e. it is a statement about the FINAL increment minus (b'), not about the
> R7-only probe. The remedy is unchanged and shipped as designed: clause (b'),
> spelled by CALLING `LoopPlan.h`'s `railPhiRootMint` (the collapse's own step-(1)
> body). Fixture text is written from the MEASURED final message,
> `control flow inside a loop body`.

**§13.2c — row DB, and it is a MANDATORY IMPLEMENTER PROBE, not a settled row.** The
disposition above was derived by READING (`collapseRailPhisIn` step (1)'s
`dyn_cast<CallInst>(Root)` test; `resolveWireBase`'s two bases; `declineClassicalMuxes`'
own comment, which names "derived fresh-rail incomings" and "loop-reachable merges" as
declined). **It could not be measured, because R7 declines first at HEAD** — so it is
the FIRST thing to run with R7 lifted, before anything else in the increment is
trusted. Two things follow if the probe confirms it. (i) The decline is **loud and
therefore safe**, but it is a decline AFTER the region was emitted and `flattenRegion`
erased the diamond — the "accepted then declined downstream" shape this file has
already had to fix once (§11.2), and its message mislabels a quantum register as a
classical mux, which is exactly `ControlDetect`'s d8jl complaint about leaning on that
guard. (ii) The detection-time fix is a **clause (b′)** on R7-loop: the header φ found
by clause (b) must additionally have its EXTERNAL incoming peel — through in-place
steps — to a **classical-arg-0 `cq_theta` mint**, i.e. `collapseRailPhisIn` step (1)'s
own claim condition asked at detection. Spell it by CALLING `peelInPlaceBase` and the
same `dyn_cast<CallInst>` + untainted-arg-0 test, never by re-writing them (Rule 14 —
this is a second reader of one predicate, which is how two spellings start to
disagree). If the probe shows the module accepts and emits instead, that is a
CONFIRMED over-accept and the increment stops.

**Row L-i is a C-level fact, not an IR-level clause.** `clang -O1`'s SimplifyCFG
merges `if (c) r=R(r,A); else r=R(r,B);` into ONE call with a `select` on the
ANGLE (drbq Inc 2b), so the in-loop if/else *from C* is an angle select and is
owned by S7. The hand-IR two-block if/else form is a genuine `BranchRegion` and
**is in the accept class** (`control_inplace_ry_inloop_ifelse.ll`, hand IR, the
same asymmetry Inc 1 records for the flat case).

#### 13.2b The one new accept-shape clause: R7-loop (b)

R7's loop half becomes: `Region.InLoop` is admitted **iff** some member of
`BaseWire` (the rotated base's `railWireClosure`, already computed for R4/R6) is a
`PHINode` in `L`'s header. Rationale, and it is a scoping clause rather than a
safety one: Inc 3 is *the Ry arm on the loop's persistent register*. An
**iteration-local** rotated register (minted inside the body) is a different
capability, and it is not merely unscoped — it is measurably **not twin-identical**:
its escape makes `markIfRailLocal` refuse the marking, so the rolled form leaks the
condition chain once per trip while the hand-unrolled twin discharges it. That is a
*different circuit*, which is exactly what the twin matrix exists to catch. Declining
it is correct scoping (the shape was never the target), not a Rule-17 punt.

### 13.3 R6 PER ACTIVATION

**Why the shipped clause cannot stay.** R6's two position predicates are flat:
`provablyBefore(U, BI)` for a genuine read and `cannotFollowGate(U, BI)` =
`!isPotentiallyReachable(BI, U)` for an alias hop. Both contain the reachability
conjunct, which **every back edge falsifies** (bd
[`provably-before-per-activation`]). Inside a loop the closure additionally reaches
values it never reaches flat: `railWireClosure` crosses phis **backward**, and the
loop-carried header φ `P`'s latch incoming is (S2) the region's own merge φ `m` or
(S1) a post-region gate whose arg-0 is `m` — so `m`, and through it the arm theta
`T`, become **members**, defeating the forward `Exclude = MergePhi`. Every one of
their in-loop users then fails both flat predicates. This is measured, not argued:
`control_inplace_ry_reject_in_loop.ll`'s own header records that before R7's loop
clause was moved ahead of R6, that module declined on the *stale-record* string.

**The predicate.** For an `InLoop` region, and **only** for one (flat regions keep
both shipped predicates verbatim, so no acyclic shape moves), each enumerated user
`U` of each member `M` owes:

> Let `D = def(M)` (an `Instruction`; a non-instruction member has no `D` and the
> obligation FAILS). Let `p(U)` be `U`'s **read position**: `U` itself, or — when
> `U` is a `PHINode` — the **terminator of the incoming block on the edge that
> names `M`**. Let `BI = Region.Pred->getTerminator()`.
>
> **OK iff `D` REFRESHES and `!reachesWithoutBarrier(BI, p(U), {D})`** — i.e. every
> CFG path from the region's branch to the read re-executes the record's own
> definition first.

Three parts, each with its reason:

* **The barrier is `D`, the record's own definition — never `BI`, and never `U`.**
  The premise being re-established is *"`M` denotes the register"*, and `D` is the
  instruction whose execution establishes it (the stale-record family's barrier;
  `WireWalk::gateIsHarmless` and `LoopLowering::railGateBetween` both take it). The
  bd `drbq.4` note proposing `BI` is **wrong and is corrected here**: with
  `Barrier == B == BI` the walk asks "can you get from `BI` back to `U` without
  passing `BI`", which is FALSE for every `U` positioned *before* `BI` in the body —
  i.e. for the ordinary pre-region read the clause must accept. `Barrier == A` is
  refused outright by `provablyBeforePerActivation` (the P1 vacuity lesson, bd
  [`peractivation-barrier-must-not-be-subject-p1`]); `Barrier == D` cannot alias
  `p(U)` here (a value is not its own user except a self-carry φ, whose read
  position is the latch terminator ≠ `D`) and the implementation asserts it.
* **The gate position is `BI`, not `T`.** At detection `T` still sits in the arm
  block, so a path through the *merge* that skips the arm never "sees" it — while
  the **hoisted** controlled gate executes unconditionally at `BI` on every
  activation. Asking at `BI` is both the conservative reading and the post-emission
  truth.
* **The refresh fence.** The certificate's premise is *"re-executing `D`
  re-establishes `M`"*. True by construction for an in-place gate or a producer
  (it re-reads the wire). **FALSE for a φ that does not track the wire** — bd
  [`identity-carry-phi-does-not-refresh`] — so a `PHINode` `D` must satisfy
  `WireWalk::phiTracksWire(D)` or the disjunct is refused. Reuse that predicate
  (Rule 14); do **not** re-spell `LoopLowering::recordRefreshedByDef`, which asks
  the same question over a *post-flatten* gate set this stage does not have.

**The API.** `WireWalk::everyPathReExecutes(From, To, Barrier)` is already exported
for exactly this — a per-activation **window** certificate *without* the dominance
conjunct `provablyBeforePerActivation` bundles. Use it. **The dominance conjunct is
deliberately dropped in-loop, and that is the ONE widening this clause makes**:
`provablyBefore ⇒ certificate` and `cannotFollowGate ⇒ certificate`, so the
certificate is strictly weaker than both, which is why the flat path must keep its
own spelling. Dominance answers *"did `U` definitely execute"*, a question R6 has
never asked (see `cannotFollowGate`'s own header); keeping it in-loop would refuse
the customer's own post-loop `cq_measure(r)`, whose read position sits in the exit
block and dominates nothing.

**Two sets, two questions — unchanged.** The MEMBER set (whose users are
enumerated) stays `BaseWireOrder`; the SKIP set (users exempt from a position
proof — the alias hops) stays `BaseWire`. In-loop both obligations collapse to the
same certificate, which is a **relaxation for reads** and no change for hops. Say
that out loud rather than deleting the distinction: the sets still differ, only the
predicate they feed is now common.

**Worked check** (all shapes measured at HEAD; the `-O1` topology cited is from
`ir/<P>.s1.ll`):

| shape | member / user | verdict | why |
|---|---|---|---|
| **S1** `for(){ if(q==5) r=Ry(r,.9); r=Ry(r,.25); q=Ry(q,.1); }` | `m` (merge φ, a member via `P`'s latch incoming `r_next = cq_theta(m,.25)`) / user `r_next` (a HOP) | **ACCEPT** | every `BI → r_next` path enters the merge block and re-executes `m` first |
| S1 | `m` / user = the post-loop `cq_measure` | **ACCEPT** | `BI → merge(m) → exit → measure` re-executes `m`; the flat `dominates` conjunct would have refused it |
| **S2** (no post-region gate; `P`'s latch incoming IS `m`) | `r0` (the mint) / user `P` on the ENTRY edge | **ACCEPT** | the **phi-edge rule**: `p(P) =` entry's terminator, unreachable from `BI` ⇒ the certificate is vacuously satisfied. Without the edge rule this row alone kills S2 |
| **S11** `for(){ r=Ry(r,.25); if(q==5) r=Ry(r,.9); … }` (routed base is the leading gate `G`, **defined in the header above the compare**, not the header φ — measured) | `P` / user `G` | **ACCEPT** | every `BI → G` path re-enters the header and executes `P` (top of block) before `G` |
| **ALIAS** `%P = phi [%r0,pre],[%P,latch]` rotated in place, `m` read elsewhere | `P` / user `P` itself on the LATCH edge | **DECLINE** | `p = latch terminator`; `BI → arm → merge → latch` never re-enters the header, so `D = P` is not re-executed. **Independently**: `phiTracksWire(P)` is false (a `cq_theta` on `P` runs between the incoming and the edge), so the disjunct is refused before the walk |
| **j4** `pre = r; if(q==5) r=Ry(r,.9); d = cq_phi(pre,.2);` | `P` / user `d` (a HOP, `forwardRailHop` admits `cq_phi`) | **DECLINE** | `BI → merge → d` does not re-execute `P`. Correct: `Rz` after the `Ry` is a different unitary from `Rz` before it |
| **PREMARK** `mark = r;` before the loop, `cq_measure(mark)` after | `r0` / the measure | **DECLINE** | `D` = the mint, in the entry block, never re-executed; `BI → merge → exit → measure` carries no barrier |
| **BODYREAD** sunk `acc = r*7` | — | **DECLINE, elsewhere** | `declineStaleRecordOps`, before detection (§13.2 row X) |

### 13.4 The post-flatten mechanism: **M-β**, and the emitter's RAUW target

**The problem, stated as the two shapes that break.** `emitInPlaceRotationRegion`
step 4 does `MergePhi->replaceAllUsesWith(Base)` and then `flattenRegion` erases the
CFG. Inside a loop that RAUW **destroys the fact that the loop's carry went through
the region**, and two of the three flagship shapes then die on `LoopLowering`'s
round-2 machinery — not on a physics fence, on bookkeeping:

* **S2** (no post-region gate) becomes the **zero-hop identity carry**
  `%P = phi [%r0, entry], [%P, latch]` with the hoisted `T = cq_theta(%P, .9)` in the
  body. `recordRefreshedByDef(%P)` answers **FROZEN** (the F-2 rule: a self-carry
  that crosses no gate does not refresh), so `railGateBetween` takes no cut, walks
  `%P → T (a gate) → latch → header → T` and reports a stale read of `%P` at `T`:
  a LOUD `rail record read past an in-place gate on the same rail` **on the
  increment's own target shape** — Rule 17.
* **S1** (post-region gate `r_next = cq_theta(m,.25)`, and `m` RAUW'd to `%P`)
  gives `%P` **two** in-place `cq_theta` users, `T` and `r_next`, and
  `collapseRailPhisIn` step (2) fires `loop-carried rail has multiple in-place
  consumers`.

Note S11 breaks on **neither** (its chain runs `%P → G → T`, so the carry crosses a
real gate and `%P` has one in-place user). Two of three, which is why this needed
deciding rather than measuring one program.

**M-α (rejected).** Keep `RAUW(m → Base)`; widen `isHoistedRegionArmGate` to the Ry
stem *for the fan-out count only*; keep `collectRailGates::noteGate` counting the
hoisted `cq_theta` as a GATE for staleness; and teach `recordRefreshedByDef` that a
self-carry φ refreshes when a hoisted controlled `cq_theta` in
`taint.ControlledRotations` has arg-0 == `P` inside the loop.

**M-β (SHIPPED).** For the **Ry stem only**, the emitter's RAUW target becomes the
hoisted gate itself: `MergePhi->replaceAllUsesWith(T)` for a diamond, and for an
if/else the two hoisted gates are **chained in emission order** — `T_f`'s arg-0 is
set to `T_t`'s result and the merge φ is RAUW'd to the LAST one. `T` dominates the
merge (it is hoisted into `Pred`, which dominates `MergeBB`), so the RAUW is
well-formed. `lowerRotations` then does `Theta->replaceAllUsesWith(Handle)` on every
hoisted theta exactly as it does today, so **the final lowered IR is identical** —
every SSA name on one rail ends on one `cqrt_alloc` handle either way.

**Why M-β wins, in one sentence:** it makes the SSA say what is physically true —
the hoisted controlled Ry *moved the register*, so the value after it is a different
state from the value before it — and every `LoopLowering` predicate then reads the
truth with **no exemption, no licence, and no cross-file dependency**. Under M-β the
chain is `%P → T → (r_next) → %P`, so `T` is a chain **MEMBER**: it is in the SKIP
set (its own execution *is* the wire moving), it is in `Gates` (it *is* a
relabelling gate — correct), and `%P`'s carry crosses it, so
`recordRefreshedByDef(%P)` is TRUE with the F-2 rule **unchanged**. `%P`'s single
in-place user is `T`; `T`'s is `r_next`. Hand-simulated on S1, S2 and S11: all three
accept with no predicate edited. M-α, by contrast, needs **two** independently-written
licences over one closure — precisely the 8h7d.5 F-1/F-3 shape the site comment on
`isHoistedRegionArmGate` warns Inc 3 about — and its refresh licence would rest on
`ArmClassify`'s R6 refusing the alias shape, i.e. **a fence in another file**, the
bd [`mint-at-consumer-window-protection-lives-elsewhere`] pattern. That is M-α's
fatal flaw: not unsoundness we can demonstrate, but that its soundness is not local
to the file that enforces it.

**What OTHER set is computed over the same closure** (the mandatory question). The
change is *which value the merge φ is RAUW'd to*, so the audit is every consumer that
reads that value between emission (`CQLoweringPass.cpp:323`) and `lowerRotations`
(`:422`) — a bounded window, because after `lowerRotations` the two mechanisms produce
identical IR.

| reader, in pipeline order | what it decides | M-β verdict |
|---|---|---|
| a LATER region's `ControlRegion::RoutedBase` (`WeakTrackingVH`, follows RAUW) | the routed handle at emission | follows to `T` instead of `Base`; the later region's own theta operand followed the SAME RAUW, so the identity comparison in `emitInPlaceRotationRegion` still matches. **Pinned by `control_inplace_ry_inloop_seq.ll` + the existing `control_inplace_ry_sequential.ll`** |
| the bd `hcrg` precedence graph | emission ORDER | reasons about **BasicBlocks**; a RAUW target is a VALUE. Unchanged — and that is the L4 §1 lesson in reverse (blocks were protected, values were not), so it is listed rather than assumed |
| `collapseFlattenedLoopRails` / `collapseRailPhisIn` (`:340`) | the rail chain, gates, fan-out, records | **THE POINT OF THE CHANGE.** `T` becomes a chain member; nothing is edited |
| `markIfRailLocal`'s `onRail` | register vs iteration-local temp | `peelInPlaceBase(T, AsLowered=true)` peels `T` to the collapsed root under **both** mechanisms, so `T` classifies as ON THE RAIL either way — but under M-β that is a *fact* (its result is the register) rather than a coincidence about a dead value |
| `lowerIOSinks` / `lowerQramReads` / `lowerShadowMemory` | tainted sinks | operate on the same values; `T`'s result is tainted under both. **Audit, do not assume** |
| `declineClassicalMuxes` (`:399`) | live select/φ over tainted data | the region's φ is erased by the emitter either way; the loop's rail φ is erased by `collapseFlattenedLoopRails`, which runs at `:340`, BEFORE this. **Audit the un-claimed-loop path** |
| `liftOneRegisterMergePhi` / `repropagateControlMerges` (`:402`) | classical join φs RAUW'd to the base | `T` is not a φ; the finding-K class is unchanged. **Audit** |
| `declineLiftedStaleRecordOps` | post-lift stale records | **Audit** |
| Phase-6 `specialize` (`:413`) | clone-on-taint arguments | a post-region consumer that is a clone argument now names `T`. Keys on taint, not identity. **Audit** |
| `lowerRotations` (`:422`) | the mint + `replaceAllUsesWith(Handle)` | collapses both mechanisms to identical IR — the byte-identity claim |

**The implementer's witness for M-β is a whole-corpus lowered-IR diff against the
pre-Inc-3 oracle** (`scratchpad/wt/pre3`): every one of the 1430 `ir-pass/test`
fixtures and every e2e slice must produce **byte-identical lowered IR**, except the
in-loop shapes this increment newly accepts. Anything else in that diff is a finding,
not a regeneration. `tools/inplace_twin_matrix.py` against the same oracle is the
second.

**The §12.1 stem table gains a row** (and the split is the same physics, not a new
one):

| stem | DAG link | adjoint | freeze | WireWalk | **emitter RAUW target (NEW)** |
|---|---|---|---|---|---|
| `cqrt_ry_<W>_controlled` | link | never → whole DAG `NotClosed` | frozen | relabelling gate | **the hoisted gate `T`** — it moved the register, so the post-gate name must be a different SSA value |
| `cqrt_rz_<W>_controlled` | NOT a link | none | not frozen | transparent (diagonal) | the base `Q` (as shipped) — diagonal, so the two names denote the same computational-basis state and either target is correct |

**The Rz stem stays on M-α in this increment**, and `isHoistedRegionArmGate` keeps
its `cq_phi_` restriction with its written obligation **discharged rather than
inherited**: the reason it is unnecessary for Ry is not that the licence was
granted, but that M-β removes the need for one. Moving Rz to M-β would retire
`isHoistedRegionArmGate` outright and leave ONE emission convention — file it
(**follow-on `drbq.10`**) rather than doing it here: the Rz stem shipped 2026-09-03
with a clearance, it touches 26 goldens' worth of already-cleared surface, and the
audit above would have to be re-run for a stem whose current mechanism is
*provably* sound (a diagonal gate genuinely is not a rail gate). Two conventions in
one file is a real cost and it is paid deliberately; the site comment must say which
stem uses which and why.

#### 13.4b P1 — the second fence, and it is NOT optional

`ArmClassify.cpp:2011` (the string it prints is at `:2013`):
`if (DeferredWireGate && (SawValueArm || !SawPhaseArm))` declines. `DeferredWireGate` is set when `condWireDisposition` returns
`ProvenPostRegion` — the Increment-4 accept: a non-diagonal gate exists on the
condition's wire but **every one of them is provably after the region's entire
emitted stream**. A control-in-place rotation arm sets `SawRotationArm` and never
`SawPhaseArm`, so `!SawPhaseArm` is true and the region declines.

**Measured, at HEAD, both binaries:**

| program | result |
|---|---|
| FLAT `if (q==5) r=Ry(r,.9); q=Ry(q,.3);` | **DECLINE** `condition predates a non-diagonal gate` at `ArmClassify.cpp:2011` — no loop involved |
| FLAT, same with `q=Rz(q,.3)` | **ACCEPTS** |
| LOOP, `Rz` reflection on `q` | `control flow inside a loop body` (R7 only) |
| LOOP, dtzb `q += off` | `control flow inside a loop body` (R7 only — a dtzb add is not a `cq_theta`, so the wire walk does not see it) |
| LOOP, **`Ry` reflection on `q`** (canonical Grover) | `condition predates a non-diagonal gate` — **R7's decline wearing P1's string**, and after R7 lifts it declines *again* at P1 |

**The change:** `if (DeferredWireGate && (SawValueArm || !(SawPhaseArm || SawRotationArm)))`.
**The argument, and it is P1's own argument with the arm class substituted.** P1 refuses
a VALUE arm because method-B copies a basis LABEL out and replays the chain on the
routed rail, so a later in-place Ry on that wire is a genuine staleness hazard. An
in-place rotation arm copies nothing, replays nothing and allocates no work rail: its
entire emitted stream is `mint(f from C) ; [x(f)] cRy(f, R, θ) [x(f)] ; strip(f from C) ; free(f)`,
all inserted before `BI`. `ProvenPostRegion` means the wire gate `G` satisfies
`provablyBefore(BI, G)`, and `condWireDisposition`'s own lemma carries that to every
call in the stream (dominance over `BI` implies dominance over each stream call, which
precedes `BI` in `BI`'s block; `!reachable(G, BI)` implies `!reachable(G, S)` for each).
So at the moment `G` fires, the flag is already stripped and freed and `R`'s
relabelling is complete; and R4 has proved `R`'s wire ∉ `C`'s wires, so `G` is not on
the register this arm touched. The residual is **identical to the phase arm's**: a
DERIVED condition leaves template rails entangled with `C`, live past the strip, which
a later Ry on `C` dephases — a property of the CONDITION's chain, not of the arm class.

> **CORRECTED 2026-09-04 (round-1 lens L8, F-L8-1). The identity claim is
> CONFIRMED; the ownership claim was an OVERCLAIM.** L8 independently compiled,
> linked and ran the derived-`and` and derived-`sqrt` programs on both binaries:
> the traces are byte-identical to the `cq_phi`-arm twins apart from
> `cqrt_rz_i32_controlled` ↔ `cqrt_ry_i32_controlled` on one line, and the whole
> condition chain is `_unc`'d and freed BEFORE the deferred gate fires. So "the
> residual is identical to the phase arm's" is TRUE as an ORDERING claim, and it
> is now pinned by two new accept fixtures
> (`control_inplace_ry_post_region_theta_derived_cond.ll`, `..._negated.ll`).
>
> What this paragraph used to add — "and owned since bd `lyyf` by M-A's
> `warnLiveRecordRotations` as a `DS_Warning`" — is **struck**. M-A does not fire
> for an **escaping** condition record: with `int d = q & 6;` measured after the
> region, the `and` rail is never uncomputed, is live and entangled when the
> post-region Ry fires, and HEAD's stderr is EMPTY. The gap is
> arm-class-independent and PRE-EXISTING (the `cq_phi` twin behaves identically on
> the ORACLE, equally silently), so it is not Inc 3's to fix — but it must not be
> cited as what makes this widening safe. The ORDER argument above is what makes
> it safe, and that is measured.

**Blast radius, stated because it is the one place Inc 3 moves a FLAT program.**
This widening also lowers the flat `if (q==5) r=Ry(r,.9); q=Ry(q,.3);` — which is
half of the recorded over-decline bd `drbq.7`.

> **AND THE OTHER HALF IS UNTOUCHED, MEASURED (lens L8 Q1(d)).** A rotated register
> that gates a SECOND region still declines on BOTH binaries: `if (q==5)
> r=Ry(r,.9); q=Ry(q,.3); if (r==2) s=Ry(s,.7);` refuses region 2, because `r`
> gained region 1's arm theta before region 2's branch and `condWireDisposition`
> returns `DeclineNow`. It is an over-decline (the merge φ denotes the post-cRy
> value, so the mint would read the right basis) that this increment neither
> introduces nor fixes. Read "half of drbq.7" literally.

> **CORRECTED 2026-09-04 — MEASURED, THE BLAST RADIUS IS SMALLER THAN PREDICTED
> AND THAT IS A FACT ABOUT THE CORPUS, NOT A REASON TO RELAX.** The whole-corpus
> HEAD-vs-oracle sweep over all 1458 lit fixtures shows **exactly ONE acyclic
> flip**, and it is `control_inplace_ry_post_region_theta_cond.ll` — the red-green
> fixture this widening ships with. **ZERO pre-existing acyclic fixtures moved.**
> On the e2e side two acyclic programs flip and both are new here: the
> `_unrolled` twins of the Grover and derived slices, which are hand-flat programs
> that the pre-Inc-3 binary declines at P1. So no composition nobody predicted was
> found — but the corpus simply contained no rotation-arm region with a
> provably-post-region condition-wire gate before this increment added one, which
> means the sweep's silence is weak evidence and the fixture pair is the real one.

It gets
its own red-green pair — `control_inplace_ry_post_region_theta_cond.ll` (accept,
flat) and `control_inplace_ry_reject_post_region_theta_stalecond.ll` (the gate that
is NOT provably post-region, still declining) — so the two halves of
`condWireDisposition` cannot drift. Owner FYI in §13.10.

### 13.5 The freeze inside a loop — ACCEPT the per-activation leak

**What happens, traced through the code.** After `lowerRotations` mints
`cqrt_ry_<W>_controlled(f, %h, θ)`, `ChainWalk::railCarriesControlledRotation(%h)`
answers true **structurally**, from the emitted gate's own arg-1 use (never from a
recorded `Value *` — finding L). `DagTraversal` then sets `D.NotClosed` at BOTH the
step-1 walked-handle site and the step-3 ancestor site, which aborts
`reverseTerminalGroup` and the M-B interior partition before either emits anything.
So the register is **never reverse-played and never freed** — left allocated, Rule
6's sanctioned fallback, exactly as in the flat `_dead_base_*` fixtures. `FreePoint`
is never reached for it, so its back-edge reject (`kMsgLoopBackedge`) cannot fire on
the frozen rail. In every customer shape `r` is `cq_measure`d after the loop and the
spine would not have freed it anyway.

**Iteration-local temps derived from the frozen rail** (`acc = r * 7` read inside
the body, a 7.6 tape write, …) have a DAG whose step-1 walk reaches the frozen
handle ⇒ `NotClosed` ⇒ that temp's rail is also left allocated. In a rolled loop
that is **K rails at run time**, one per activation. Three facts make this an
accept rather than a fence:

1. It is **Rule-6 safe by construction**: left allocated, never freed dirty. The
   only thing a `cqrt_free` could have done here is collapse a rail entangled with
   `r` and hence with the condition.
2. It is **identical in the hand-unrolled twin**, which leaks the same K rails for
   the same reason — so `tools/loop_twin_matrix.py` reads `ACCEPT-IDENTICAL`
   (or `-WARN`), which is the increment's witness, not a hole in it.
3. It is **invisible to strict stage 2b** and that is documented, not discovered:
   `free_pairing_check.py` counts `cqrt_alloc` mints and these rails are
   TEMPLATE-minted (its own header says so; bd 8h7d.5 round-4 F-4 is the same
   fact). Quoting a green stage 2b as evidence here would be false.

> **MEASURED 2026-09-04, round-1 review (lens L3 Q1) — all three facts confirmed
> on a real program, with a committed reproducer.** At hand-back this was
> analytic: no shipped slice read the rotated register inside the body, and the
> two obvious spellings are refused (a read AFTER the region is
> `cq opcode lowering: operand predates a non-diagonal gate`; a read in a SECOND
> loop is a classical-condition mux). The spelling that works is to read it
> **BEFORE** the region in the same body — the read then precedes that
> activation's own relabelling gate, and the loop-carried `r` phi crosses a real
> rail gate every trip so the back edge does not stale it. Committed as
> `tests/e2e/slice_control_inplace_ry_loop_leak.c` + `..._unrolled.c` + the
> `e2e-inplace-ry-loop-leak-twin-identical` gate. **2 template rails per
> activation** (`cq_template_mul_i32_hl` and `cqrt_tape_write_i32`), never freed:
> 4 at K=2, 6 at K=3. Fact 1 holds (all left ALLOCATED, none freed dirty); fact 2
> holds (the twin traces are BYTE-IDENTICAL, so the cost is the FREEZE's, not the
> ROLL's); fact 3 holds (strict 2b reports `2 rail mints, 2 left allocated, 1
> verified, 0 violations` — it cannot see the four template rails at all). One
> thing the section did NOT predict and the pair now records: **M-A's warning is
> emitted PER STATIC GATE, so it is 1 on the rolled side and 2 on the K=2 flat
> twin** for the same program with identical traces.

**Owner FYI, not a question (§13.10):** the leak's *magnitude* is new even though
its *class* is not. Flat, the freeze leaks O(1) rails; rolled, it leaks O(K). In the
qubits-not-scarce regime this is accepted. The alternative — a new fence declining
derived temps of a frozen rail inside a loop — would cost the whole
`control_swap_inloop_diamond_iterlocal` family for the Ry stem while the Rz stem
keeps it (Rz is not frozen), i.e. a stem asymmetry paid for with a decline of a
correct circuit. Not recommended.

**`markIfRailLocal` dispositions**, asked explicitly because it grants the spine a
permission:

* `onRail(T's result)`: `peelInPlaceBase(T, AsLowered=true)` peels through `T`'s
  arg-0 to the collapsed root ⇒ **on the rail** ⇒ exempt from the escape check.
  Under M-β that is correct on its own terms (the value IS the register). Under M-α
  it would be a dead value classified as the register — true but for the wrong
  reason, another small argument for M-β.
* The **condition** chain's iteration-local temps (a derived condition's four
  template rails) are on `q`'s rail, which carries **no** controlled rotation (R4
  guarantees it), so they are NOT frozen and still discharge in-body exactly as they
  do on the shipped phase path. The derived-condition slice keeps its three
  discharges.
* `markIfRailLocal`'s marking is a permission that `Uncomputation` and `FreePoint`
  both re-verify, and not-marking is always safe. Nothing here weakens it.

### 13.6 Angle select in a loop (S7 / S9) — **stays declined**

**Recommendation: do not widen S7 in this increment.** The reason is structural and
measured, not caution: `taint.InLoopFlattenedPreds` has exactly **one writer**,
`SwapRouteEmit.cpp:1468`, and it is the **sole trigger** of
`collapseFlattenedLoopRails`. `AngleSelectEmit` performs no CFG surgery at all (§12.3
— "no CFG, no hoist, no flatten"), so it can never set it. And round 1 (`tryCaseA`)
does not claim a loop containing a tainted select either: its COVERAGE clause refuses
any tainted body value not on a rail, and the tainted compare and the tainted-condition
select are both exactly that. **So an in-loop angle select would have NO rail-record
fence at all — neither round — which is precisely the "a shipped loud decline becomes
silence" shape S7's own round-1 fix was written for** (bd
[`sibling-predicate-spelling-is-the-hole`]). Lifting it needs either a round-2 trigger
for the angle-select emitter or a proof that the loop's rail is adjudicated elsewhere;
both are a separate increment.

If it ever moves, S9 owes the identical per-activation treatment §13.3 specifies, with
the consuming rotation `T` in the barrier role `BI` plays here, plus the phi-edge read
position — and S7's prong (iii) is already recorded as CONTINGENT on Case-A's collapse
having re-anchored the in-loop gate, a contingency this increment's M-β RAUW change
touches. **File as `drbq.11`.** This is a recommendation, and widening it is the
owner's call.

### 13.7 Walker audit — `LoopLowering.cpp`, pre/post `lowerRotations`

The audit's headline: **`LoopLowering.cpp` contains NO name test on `cqrt_ry_`,
`cqrt_rz_` or `_controlled`, at any site.** Both loop rounds run strictly before
`lowerRotations` (`:310` and `:340` vs `:422`), so the vocabulary they see is always
the front-end `@cq_theta_` / `@cq_phi_` spelling with the wire at **arg 0** — which
is exactly what hoist-and-defer preserves, and exactly why `noteGate` counts the
hoisted Ry without being taught anything.

| site | test | stage | sees a HOISTED controlled gate in a loop? |
|---|---|---|---|
| `isHoistedRegionArmGate` :366-372 | `taint.ControlledRotations` ∧ `cq_phi_` | pre | **Rz: yes** (round 2 only — round 1 runs before emission, so the map is empty; the round-1 call site passes it anyway so the rounds cannot drift). **Ry: NO, deliberately** — M-β removes the need |
| `isMeasureCall` :373-386 | `cq_measure_` / `cqrt_measure_` | pre | n/a |
| `collectRailGates::noteGate` :758-765 | `cq_theta_` ∧ `GateCalls` | pre | **YES, round 2 — the hoisted Ry IS a gate, which is correct and is the whole point.** Round 1 never sees one |
| `breakLineageCarriesPhase` :953-973 | `cq_phi_` | pre | 7.4 `break` path; in-loop control declines there, so unreachable for this class |
| `isInPlaceGateOnArg0` :294-305 | `GateCalls` membership ∧ arg-0 (no name test) | pre | **YES, round 2, both stems** |
| `peelInPlaceStep` / `peelInPlaceBase` :257-289 | via `GateCalls` | pre | **YES, round 2 — and under M-β the hoisted theta is a PEEL STEP, which is the mechanism** |
| `inPlaceValueRailOperand` :142-155, `railValueConsumerDisposition` :200-216 | opcode + taint | pre | n/a (never a rotation) |

**The one obligation this discharges in writing** (`isHoistedRegionArmGate`'s site
comment demands it): the predicate would exempt the hoisted gate from the fan-out
count while `noteGate` counts it for staleness — two answers for one call. Inc 3
does **not** widen it, so the two answers never diverge: under M-β the Ry gate is a
chain member, so the fan-out count sees ONE in-place user per rail value *without*
an exemption, and `noteGate` counts it as a gate *correctly*. The site comment must
be updated to say the obligation was discharged by mechanism, not by licence.

### 13.8 Fixtures, slices and gates

**lit accepts** (family `control_inplace_ry_inloop_*.ll`, 10):
`diamond` (S2, the identity-carry shape M-β repairs) · `negated` (¬flag polarity,
Rule 9) · `post_region_gate` (S1, the fan-out shape) · `leading_gate` (S11 — the
routed base is a derived value **in the header above the compare**, measured;
re-ask the finding-L structural freeze here) · `two_registers` · `seq` (two regions
in one body) · `rz_reflection` · `offset` (dtzb `q += off` on the condition rail) ·
`derived_cond` (**use a satisfiable predicate** — `q*3 == 6`, never `q*3 == 5`,
which `clang -O1` proves unsatisfiable under `nsw` and deletes outright: a vacuous
accept, measured. **CORRECTED 2026-09-04: SATISFIABLE IS NECESSARY AND NOT
SUFFICIENT, and only the C SLICE is affected.** `q*3 == 6` is satisfiable and
still vacuous from C — `clang -O1` canonicalizes it to `icmp eq i32 %q, 2` and the
`mul` is GONE, so the slice would have tested a DIRECT condition while claiming a
derived one. The shipped C slice uses `(q & 6) == 4`, which survives `-O1` as a
real `and` + `icmp` pair and whose golden genuinely carries
`cq_template_and_i32_hl` with its in-body `_unc` + `cqrt_free`. The hand-IR lit
fixture keeps the `mul` and is unaffected — hand IR is not re-canonicalized —
and its lowered output was checked to contain `cq_template_mul_i32_hl`) · `ifelse` (hand IR, the two-block form; the C spelling is an
angle select — §13.2 row L-i). **Every C-sourced accept fixture must keep the
condition register LOOP-VARIANT** (§13.1) or `clang -O1` hoists its compare and the
fixture lands on row W instead of on the clause it claims to pin. Hand-IR fixtures may
write the compare inside the loop block directly, which is why
`control_inplace_ry_reject_in_loop.ll` flips to accept even though `q` is invariant in
it (measured: its `Cond->getParent() == R.Pred`, so P4 passes and R7 is the only wall).

**lit declines** (family `control_inplace_ry_reject_inloop_*.ll`, 16 — **SHIPPED
17**, because P1's `stalecond` sits inside the family name and was counted
separately in the prose below; plus the §13.4b flat pair, which is 1 accept + 1
decline OUTSIDE the family name): one per
§13.2 row L-a, L-b, L-c, L-d, L-e, L-f, R4, R6-1, R6-2, R6-3, R1, R1', R2, R7',
plus P1's `stalecond`, **row W's `invariant_cond_hoisted`** (with a C-shape note: its C
program is the customer's simplest spelling, so pinning its decline is what makes the
day P4 widens a deliberate move) and **row DB's `derived_base`** (a mandatory probe —
§13.2c — whose fixture text must be written from the MEASURED message, not the read
one). Each mirrors its string character-for-character.

**Two existing fixtures move.** `control_inplace_ry_reject_in_loop.ll` **FLIPS TO
ACCEPT** and is rewritten in full (its whole header is an Inc-3 to-do list; hand-
simulated: `q` loop-invariant with the compare written inside the loop block, `r`
loop-carried, R6 per-activation clears every member). Its decline sibling is
**re-homed** onto a shape that still declines — the R6-3 ALIAS fixture, which is the
same CFG with the carry made an identity and the merge escaping. `control_inplace_rz_in_loop_rolled.ll`
must stay **byte-identical** (the Rz stem does not move).

**e2e**, in the 8h7d.5 style — every rolled slice gets a hand-unrolled `_unrolled`
twin and a `cmp` ctest gate:

| slice | twin | gate |
|---|---|---|
| `slice_control_inplace_ry_loop` | `_unrolled` | `e2e-inplace-ry-loop-twin-identical` |
| `slice_control_inplace_ry_loop_leading_gate` | `_unrolled` | `e2e-inplace-ry-loop-leading-gate-twin-identical` |
| `slice_control_inplace_ry_loop_two_regs` | `_unrolled` | `e2e-inplace-ry-loop-two-regs-twin-identical` |
| `slice_control_inplace_ry_loop_grover` (Rz oracle + cRy on `r` + **Ry** reflection on `q` — the customer, and the one that needs §13.4b) | `_unrolled` | `e2e-inplace-ry-loop-grover-twin-identical` |
| `slice_control_inplace_ry_loop_derived` (derived condition, satisfiable) | `_unrolled` | `e2e-inplace-ry-loop-derived-twin-identical` |

Count: **10 slices + 5 `cmp` gates = 15 new ctest entries** (305 → 320), plus the
K-independence gate below. All run **STRICT** stage 2b — no `--allow-unproven`.

**The K-independence gate.** `slice_control_inplace_ry_loop_grover.c` compiled with
`-DK=3` and `-DK=1000` must produce **the same lowered-IR line count** (the 8h7d.5
measurement was 87 lines pre-2a and 77 post-2a on `slice_control_grover_loop_dynamic`;
re-measure, do not quote). A count that grows with `K` means the loop was unrolled and
the increment's central claim is false.

**`tools/loop_twin_matrix.py` — the axis, MEASURED FINAL (re-measured from the files
on 2026-09-04, not inherited).** At HEAD `1bdaa60` the matrix had **156 cells and no Ry
axis**. The committed working tree now carries the **`FIFTH AXIS — CONTROLLED Ry ARM`**:
**117 new cells, 273 total** (`grep -c '^m_' tools/loop_twin_matrix.expected.txt`), in
**eight declared sub-grids** whose sizes the script asserts
(`assert (len(base), len(rec), len(ry)) == (120, 36, 117)`):

| grid | what | cells |
|---|---|---|
| A1 | the two LITERAL core regions × the full `a`-gate product | 18 |
| A2 | every other literal region at an `a`-gate STAR (one gate at a time) | 25 |
| A3 | the three **OPAQUE** regions (`oeq`/`one`/`oder`, whose compare reads `volatile int off`) at the same star | 15 |
| B1 | the second-register `RGATE` axis: opaque core × 4 gates × 2 `a`-shapes | 24 |
| B2 | every remaining region at the one second-register gate that refreshes | 6 |
| C | the RECORD axis on the ROTATED register (opaque, so it is live) | 24 |
| D | the RECORD axis on the CONDITION register while the arm rotates `r` | 3 |
| E | the two decline controls (`rcond`, `rifelse`) | 2 |

`RGATE` = `{none, rypre, rypost, rzpost, addpost}` — what stands on the ROTATED
register inside the body, on each side of the region. The **opaque family is the
matrix's own answer to row W**: `if (a == off)` defeats both LICM and CSE without
changing the tainted lineage, so its rolled side declines on the LOOP and its flat side
**ACCEPTS** — which is what makes 24 + 24 + 6 of the cells above a live witness rather
than 48 restatements of row W. **Gate time moved 120 s → 151 s.**

**The 117 cells' committed verdicts, and the flip partition Inc 3 must produce.** These
counts are `awk`-derived from the file, not quoted:

| # | verdict today | family | Inc 3 must make it |
|---|---|---|---|
| **59** | `UNROLLED-ONLY` (rolled: `control flow inside a loop body`) | the payload | **`ACCEPT-IDENTICAL` after 3a alone** |
| **9** | `DECLINE-BOTH-DIFFERENT` rolled `…loop body` / flat `condition predates` — **every one has PREFIX `ry`** (`m_ry_{oeq,one,oder,req,req0,rne,rder,rrange,ryrz}_none_none_none`) | 3b, **if** their flat owner is P1 | **`ACCEPT-IDENTICAL` only after 3b — and after 3a ALONE they go `ROLLED-ONLY`, i.e. RED.** See the box below |
| **15** | `DECLINE-BOTH` `condition predates`, with a `cq_theta` on `a` | 3b (P1) | **12 → `ACCEPT-IDENTICAL` after 3b**; the 3 with PREFIX `ry` (`ry/req/ry`, `ry/rder/ry`, `ry/rzry/none`) most likely **stay** — a prefix gate is not provably post-region, so `condWireDisposition` returns `DeclineNow` (`:1329`) and P1 never runs. **MEASURE per cell** |
| **16** | `DECLINE-BOTH` `condition predates`, literal region with NO gate on `a` (`m_none_{req,rder,req0,rne,rrange}_none_none_*`) | **row W** | **STAY DECLINED** (over-decline, §13.2) |
| **8** | `DECLINE-BOTH-DIFFERENT` rolled `…loop body` / flat `stale rail record read past a controlled Ry` — the `oeq`/`oder` × **`rpremark`** cells | R6 | **`DECLINE-BOTH` with the IDENTICAL R6 string** — *not* `ACCEPT-IDENTICAL`. The rolled side's per-activation R6 must decline these for the same reason the flat side already does (§13.3's PREMARK row); a verdict change, recorded deliberately |
| **8** | `DECLINE-BOTH` `cq opcode lowering: operand predates a non-diagonal gate` — `oeq`/`oder` × **`rbodyread`** | `declineStaleRecordOps`, a different stage | **STAY** |
| **1** | `m_none_rcond_none_none_none` `DECLINE-BOTH` `cq controlled lowering: control flow under quantum control` | R4 control | **STAY** — and note it prints the **GENERIC** string, not R4's own `rotation arm on a condition wire`, so this cell does not pin R4; `control_inplace_ry_reject_inloop_cond_register.ll` must |
| **1** | `m_none_rifelse_none_none_none` `DECLINE-BOTH-DIFFERENT` rolled `…loop body` / flat `rotation angle` | angle select (§13.6) | **STAY** |

> **THE 9 `ry`-PREFIX CELLS ARE THE ARGUMENT FOR SHIPPING 3a AND 3b TOGETHER.** Today
> both sides decline. After 3a alone the ROLLED side accepts (its `condWireDisposition`
> is `None` — that is *why* its message is the unmasked loop string) while the FLAT side
> still declines, so the cell becomes **`ROLLED-ONLY`: a DISPOSITION MISMATCH, which the
> table's own header calls a RED needing a written reason, and the only three that exist
> today are a `clang -O1` canonicalization artifact.** Nine new ones with no artifact
> reason is the gate telling you the increment is half-landed.

Accounting: 59 + 9 + 15 + 16 + 8 + 8 + 1 + 1 = 117. ✓

> **CORRECTED 2026-09-04 (round-1 lens L7, finding L7-4) — the "3 with PREFIX `ry`
> most likely **stay**" row is WRONG, and the table said "MEASURE per cell" for
> exactly this reason.** Measured on the committed table: **two of the three
> FLIPPED to `ACCEPT-IDENTICAL`** — `m_ry_req_ry_none_none` and
> `m_ry_rder_ry_none_none` — i.e. the FLAT side newly accepts, which the predicted
> row did not anticipate. L7 dumped both flat streams and they are **SOUND**: the
> prefix `cqrt_ry_i32(h0, .25)` on the condition wire is followed by the flag MINT
> against that same post-Ry `h0`, the controlled rotation on the DISJOINT rail, and
> the STRIP against the same `h0` — mint and strip read one basis, and the suffix
> Ry lands after the free. The third, `m_ry_rzry_none_none_none`, did NOT stay
> either: it is the NEW `UNROLLED-ONLY` disposition mismatch §10.2 accounts for (a
> safe rolled over-decline — the next repetition's `a = Ry(a,.25)` is provably
> post-region FLAT but is reached around the BACK EDGE rolled, and
> `condWireDisposition` uses the flat `provablyBefore`). So the honest score for
> this row is **12 → `ACCEPT-IDENTICAL` as predicted, 2 more `ACCEPT-IDENTICAL`
> unpredicted-but-sound, 1 `UNROLLED-ONLY` accounted for in §10.2, 0 that "stayed"**
> — and §10.3 item 4's "exactly one acyclic flip" is a statement about the LIT
> corpus, not about these C programs.

**The axis was written and committed BEFORE any lowering exists, which is the whole
point** (the fixture `control_inplace_ry_reject_in_loop.ll`'s own header and bd
`drbq.4`'s notes both demand it): a table regenerated after the implementation can only
prove that the implementation agrees with itself, whereas this one's **diff IS the
witness**. **Its blind spot must be quoted with it:** the oracle is the unrolled twin,
which for an Ry cell IS the Inc-1 flat lowering — so a defect Inc 1 and Inc 3 SHARE (a
wrong controlled-rotation polarity, a missed R4 aliasing, a freeze that should have
fired on both sides) is byte-identical on both and this gate reports `ACCEPT-IDENTICAL`.
The flat side's own witnesses are the Inc-1 lit family and
`tests/e2e/slice_control_inplace_ry.c`; nothing here replaces them.

### 13.9 Review lenses — ≥3 rounds, 8 lenses

Each lens must **compile** its named twin on **both** binaries (HEAD and the
pre-Inc-3 oracle at `scratchpad/wt/pre3`) and report only what it ran (Rule 19).

1. **Per-activation R6.** Is the barrier the record's own def at every call site, is
   `Barrier == A` refused, and is the phi-edge read position applied on *every*
   consumer path? Try to reach a post-region read of a pre-Ry record through: a
   `cq_measure`, a `ret`, a `store`, a specializable call argument, a 7.6 tape write,
   a `cq_invert` bracket, a classical join φ (the finding-K launder), a `select`, and
   a `freeze` — from **inside** the body, from the **exit** block, and from **after**
   the loop. Twin to compile: the same program hand-unrolled with an `Rz` reflection
   (so P1 does not mask the result).
   **And the SIBLING-SPELLING obligation, which is this lens's real job** (bd
   [`sibling-predicate-spelling-is-the-hole`]): §13.3 leaves R6 with **TWO
   spellings** — the flat `provablyBefore`/`cannotFollowGate` pair and the in-loop
   certificate — and *"a new clause that asks the SAME question as its siblings with
   a DIFFERENT predicate"* is where the last two over-accepts in this epic lived.
   The reviewer must therefore **temporarily use the certificate for FLAT regions
   too**, run the whole 1430-fixture corpus plus every e2e slice, and list every
   ACYCLIC fixture whose disposition flips. Expect flips: the certificate is
   strictly weaker (it drops the dominance conjunct), so a flat alias hop on an
   unexecuted classical path may newly accept. **If NOTHING flips, the round-1 fix
   should collapse to ONE spelling** — two predicates that agree on the whole corpus
   are one predicate wearing two names, and keeping both is how they later disagree.
   If something flips, each flip must be individually argued and the split kept.
2. **Rail / record closure in the loop.** The F-1/F-3 question, asked of *this*
   increment: when M-β makes `T` a chain member, **what other set was computed over
   the same closure**? Specifically — `collectRailGates`' `OnRailOut` record set, the
   `MemberSet` skip set, `railRoot`'s round-1 fixpoint, and `BaseWire`'s three
   consumers in `classifyArms`. Build the 8h7d.5 rail-record fixture family with the
   Rz arm replaced by an Ry arm and check every one keeps its verdict.
3. **Freeze + spine + back edge.** Prove `NotClosed` really fires per activation and
   that nothing frees the register or a derived temp; probe a Phase-6 Bennett wrap
   around the loop, a 7.4 `break` in the same function, and a `cq_invert` bracket.
   Confirm `EmitInverse`'s controlled-rotation adjoint stays unreachable — by
   construction, not by argument (Inc 2a worry 2).
4. **Polarity, order, plan lifetime.** `!=` canonicalization inside a loop; two
   regions in one body in both orders; a classical branch between two in-loop
   regions (the L4 `RoutedBase` shape, now with M-β's new RAUW target); the hcrg
   Kahn sort with in-loop preds; and the emission-order chain rule for an if/else
   (`T_f`'s arg-0 := `T_t`'s result) under both polarities.
5. **Walker / set audit.** §13.7's table, re-derived independently. Mutation-test:
   delete `noteGate`'s `cq_theta_` arm and confirm the target fixtures go red;
   restore `isHoistedRegionArmGate`'s stem-agnostic form and confirm nothing
   silently changes for Ry (it must not, under M-β).
6. **Fixture and doc truth.** Does every `CHECK` line assert what its header claims?
   Mutation-verify each new decline by relaxing its clause. Re-measure every number
   this section states (fixture counts, ctest counts, matrix cells). Check the
   `-O1` shape of every e2e slice actually contains a diamond (the DER lesson: a
   vacuous accept looks exactly like a capability).
7. **The twin matrices + K-independence.** `loop_twin_matrix.py` (the committed table
   diff IS the witness), `inplace_twin_matrix.py --route-oracle <pre-3>`, the five new
   `cmp` gates, `control_flag_order_check.py`, `golden_multiset_audit.py --all` (no
   existing golden may move), and the whole-corpus lowered-IR diff against the
   pre-Inc-3 oracle demanded by §13.4.

8. **P1 ALONE, on acyclic programs** — formally a lens, not an optional eighth,
   because it is the one part of this increment that moves programs with no loop in
   them and every other lens above is about loops. Run the whole-corpus disposition
   sweep against the pre-Inc-3 oracle with **only** §13.4b applied, and account for
   **every** acyclic flip individually: which are the intended drbq.7 family, which
   are compositions nobody predicted. Probe the boundary in both directions — a
   condition-wire gate that is provably post-region (must now ACCEPT with a rotation
   arm) versus one that is not (must still decline at `condWireDisposition`'s
   `DeclineNow`, `ArmClassify.cpp:1329`), and the same pair with a VALUE arm (must
   still decline, `SawValueArm`). Then re-run it with §13.3 also applied and confirm
   the two sweeps' flip sets are disjoint.

### 13.10 Questions for the owner

**One** — row W, below. Everything else is settled analytically or by measurement.

**Q1 — should the compare→branch staleness family become WIRE-AWARE?** §13.2 row W:
the simplest C spelling of the customer's own shape,
`for (…) { if (q == 5) r = cq_theta(r, .9); }` with `q` untouched in the body,
declines at HEAD and **will still decline after this increment**, for a reason that is
neither R7 nor P1. `clang -O1` hoists the loop-invariant compare into the preheader,
and `condWireDisposition`'s P4 precondition (`Cond->getParent() != R.Pred`,
`ArmClassify.cpp:947-948`) refuses any compare that does not live in the region's own
`Pred`. It is an OVER-DECLINE: the only thing in the widened window is the arm's own
`cq_theta` on `r`, and R4 has already proved that rail disjoint from every condition
rail, so the flag the mint reads is the flag the source describes and the strip returns
it to `|0⟩`. **16 matrix cells are this family.**

Both halves of the family are wire-blind on purpose — P4 refuses a cross-block gap it
cannot bound, P5 (`:954-962`, the kjd1 gate-2c window scan) refuses a `cq_theta`
between the compare and the branch *even on another wire*. The natural repair is to
make them wire-aware using the closure R4 already computes
(`railWireClosure(…, BackwardOnly)`), which would let a hoisted-but-dominating compare
through when nothing on the CONDITION's wire stands between its position and `BI`.
**Recommendation: NOT in this increment, as a separate follow-on `drbq.12`.** Three
reasons: it is a **sibling-spelling change shared by four callers** (this path, the 4.4
select's gate 2c, 2b's S6, and the `RegionTreeDetect` nest), and bd
[`sibling-predicate-spelling-is-the-hole`] is precisely about one of those four being
spelled differently from the rest; it moves ACYCLIC programs, so it lands on top of
§13.4b's flat movement in one review; and it is *orthogonal* to Ry — the identical
over-decline exists for the shipped Rz stem today, which means it is a pre-existing
capability gap, not something Inc 3 introduces. **Note the correction that changes the
shape of the fix:** the matrix agent attributed row W to the P5 window scan; measured
on the IR it is P4, so a wire-aware P5 alone would move **zero** of the 16 cells. Say
if you want it folded in anyway.

Two FYIs:

1. **Inc 3 moves a FLAT fence.** §13.4b's P1 widening is required for the flagship
   customer and, as a side effect, lowers the flat shape recorded as over-decline bd
   `drbq.7`. Say the word if you would rather it shipped as its own increment (Inc
   3a = the loop, Inc 3b = P1); the cost of splitting is that Inc 3 alone delivers
   the `Rz`-reflection and dtzb-offset loops and still declines Grover-with-a-cRy.
2. **The freeze leaks O(K) rails, not O(1).** §13.5. Rule-6 safe, identical to the
   hand-unrolled twin, and the alternative fence would cost a correct circuit. No
   action requested.

### 13.11 What worries me

1. **The customer shape was two fences away and the PRD that scoped it named one.**
   Nothing in the epic's notes, the bd issue, or `control_inplace_ry_reject_in_loop.ll`'s
   own header mentions P1 — and P1 is not a loop fence at all. That was found by
   compiling the *hand-unrolled twin* and discovering it does not lower either. **The
   generalizable lesson: when an increment's witness is "it equals its twin", compile
   the twin FIRST.** If more than one wall is still standing, budget for it now.
2. **`declineArm`'s re-spelling makes the target shape's decline lie about itself.**
   All nine in-loop Ry programs print `condition predates a non-diagonal gate`, which
   names the condition wire — a different fence entirely. Anyone triaging a customer
   report chases the wrong guard, and a fixture written from the observed string pins
   the wrong clause. It is deliberate (message-churn avoidance) and it is now the
   *default* experience for this shape.
3. **M-β changes Increment 1's FLAT emission**, and its safety rests on "the lowered
   IR is byte-identical after `lowerRotations`". That is true of the RAUW, and the
   window between emission and `lowerRotations` is nine stages long. §13.4's audit
   table lists them; four rows say "audit, do not assume" because I read their
   headers and not their bodies.
4. **R6's per-activation certificate deliberately does NOT ask about gates other than
   the region's own**, and the shape it therefore misses (a post-region gate between
   the record and a sunk read) is caught only by `LoopLowering` round 2 — which runs
   **only** when `InLoopFlattenedPreds` is non-empty *and* `collapseRailPhisIn` claims
   the loop. A loop where the collapse returns `NotClaimed` has R6's narrower question
   and nothing else. I could not construct such a program that also passes R7-loop (b),
   but I did not prove one does not exist.
5. **The matrix axis was written by a concurrent agent while I was reading it**, and
   the table moved under me (265 rows at one moment, 156 the next). Every count in
   §13.8 tagged to it must be re-measured before it is quoted, and the axis must be
   committed and green *before* the lowering lands or its witness value is gone.
6. **`markIfRailLocal`'s escape clause is load-bearing for a UNITARY, not a leak**
   (its own round-5 note), and this increment adds a frozen rail to the values it
   classifies. I argued `onRail` is unchanged; I did not re-derive the multiplicity
   argument in `Uncomputation`'s §4/§2.9 pair with a frozen rail present.
7. **THE SIMPLEST C SPELLING OF THE CUSTOMER'S SHAPE STILL DECLINES AFTER THIS
   INCREMENT.** `for (…) { if (q == 5) r = cq_theta(r, .9); }` — no gate on `q` — is
   what a user writes first, and row W refuses it for a reason that is neither of the
   two fences this PRD is about. It was found by the MATRIX, not by me: I measured
   nine in-loop programs and every one of them happened to carry a gate on `q`, so
   every one of them cleared P4 and I never saw the wall. **That is the same failure
   mode as worry 1, one level down** — a probe set chosen from the customer program
   is a probe set that shares the customer program's accidental properties. The
   opaque `volatile`-compare family exists in the matrix precisely because someone
   went looking for the property my probes all shared.
8. **Three of the five e2e twins are for shapes whose C spelling I measured, and two
   are not.** `_two_regs` and `_derived` were reasoned about from the Rz analogues.
   The DER lesson says that is exactly where a vacuous accept hides.

## 14. Increment 4 design — controlled STATE PREP (S5) (settled 2026-09-04)

> ## ⚠⚠ ERRATA / RULING — 2026-09-11: F2 IS NARROWED BY THE CONDITION'S OWN WIRE
> ## (owner ruling; bd `drbq.14`). READ THIS BEFORE §14.2b, §14.3, §14.11 Q1.
>
> **This is an ERRATA BLOCK, not an edit.** Everything below §14 is the Inc-4
> design as settled 2026-09-04 and implemented 2026-09-05, and it stays verbatim —
> including the four adversarial rounds F2 lost, which are the reason this change
> is risky and must not be deleted to make the section read cleanly. What changed
> on 2026-09-11 is the **DISPOSITION** of one clause, not the facts under it.
>
> **OWNER RULING, verbatim:** *"WE DO NOT WANT TO WRITE `int b1`. also WE DO NOT
> WANT ANOTHER cq function. it should just be an application of gates … I dont see
> the need for the over-decline."* The trade (§H-1 below) was put to the owner
> plainly and was not vetoed.
>
> **THE CHANGE.** `f2SeedPinnedByLiveRegister`'s equality test gains ONE conjunct:
> a pinned value `V` is not a collider when `CondWire.count(V)`, where
> `CondWire = {Region.Condition} ∪ ⋃_{P ∈ condProvenance(Cond)} railWireClosure(P,
> BackwardOnly)` — the condition's own backward wire, built at the caller **by
> calling R4's own helper** so the two fences cannot drift on what "the
> condition's wire" means (Rule 14). The now-dead plain-literal fast path
> (clause (a)) is **DELETED**: its `H` is the compare's own operand and therefore
> unconditionally in `CondWire`, so keeping it would re-assert exactly the
> declines the ruling removes. Its "depends on no analysis" backstop argument is
> **retired with it**, said out loud rather than dropped — a future LLVM that
> weakens LVI costs over-ACCEPTS here, and the answer to that is a fresh fence,
> not a literal test that contradicts the ruling. PROVED DEAD BY MEASUREMENT: with
> the fast path deleted AND the conjunct absent, all 40 F2 fixtures — including
> `eqfold_coincidence{,_ne}`, the two that pinned it — still decline.
>
> **WHAT MOVES: 19 of the 40 F2 fixtures flip to ACCEPT; 21 stay declines.**
> Measured, and it reproduces the scoping prediction cell for cell. The 21 that
> stay are the whole of the recorded-miscompile population: the F-R1-1 six
> (forward users), both sideways rewrites, the four curated `llvm.*` rails, the
> three cast rails, the fp forward hop, the `sitofp`, and the three `Truncated`
> cells.
>
> **§14.11 Q1 IS ANSWERED FOR CONE PINS AND KEPT FOR OFF-CONE ONES.** Q1's
> "workaround one character — any seed other than the compare literal" no longer
> applies when the pinning register is on the condition's wire (that is now an
> ACCEPT; `slice_control_inplace_ry_stateprep_seed_eq_k.c` is the e2e, whose
> golden differs from the Inc-4 flagship's by EXACTLY ONE LINE, the alloc
> literal). It still applies verbatim off the cone.
>
> **THE `i1` CLAUSE.** §14's "the `i1` state-prep width is OUT" is REVERSED — but
> the correct phrasing is *"the `i1` width is no longer CATEGORICALLY out"*, never
> *"`i1` is in"*. There never was an `i1` special case: the collision was a
> CONSEQUENCE of F2's candidate list, because the branch's own condition is a
> tainted `i1` that LVI pins to `{true}`/`{false}` on the two edges, so every `i1`
> seed matched one. `Region.Condition` is the first element of `CondWire`, so that
> particular collision is gone. An `i1` seed pinned by an INDEPENDENT second
> compare still collides and still declines
> (`control_inplace_ry_reject_stateprep_second_flag_i1.ll`).
>
> **WHAT IT SILENTLY ABSORBS — say it in these words.** A program that was LOUDLY
> REFUSED before now receives the circuit for the OTHER reading, with no
> diagnostic.
> * **α, 15 of the 19.** `int r = k; if (q == k) r = cq_theta(q, θ);` — an
>   in-place Ry on the CONDITION's own register — is **BYTE-IDENTICAL after
>   `-O1`** to the genuine prep (MEASURED: `probes/a_prep.c` vs `probes/a_self.c`,
>   `diff` EMPTY). It compiles now as a fresh rail rotated under the flag, with
>   `q` never touched.
> * **β, 4 of the 19.** The straight-through incoming was a live register `-O1`
>   folded to the seed; the rival is a quantum-data MUX that F1 refuses in its
>   unfolded spelling.
>
> There is **no fence** that could separate these, because after `-O1` there is
> ONE module. The mitigation is disclosure: this block, the CLAUDE.md ruling
> paragraph, the fixture headers that name the rival and cite its measured
> decline string, and the committed e2e slices. **A `DS_Warning` was considered
> and deliberately NOT added** (SCOPE §5.4): it would fire on every narrowed
> accept — i.e. on every Grover state prep the ruling exists to enable — and a
> warning nobody can silence is one everybody learns to skim (Rule 19's own
> argument). A flag-gated `-cq-warn-folded-prep` is on the owner's desk as an
> option, not in the default build.
>
> **WHY IT IS ADMISSIBLE — A THEOREM ABOUT R4, NOT A SURVEY.** `railWireClosure`
> inserts its seed BEFORE any gate, so `RotBase ∈ BaseWireOrder` always, so
> `RotBase ∈ CondRails ⇒ R4 declines` for EVERY chained (register-arg-0) rotation
> arm. The only path past R4 is `StatePrep` — the folded case, where the register
> is no longer in the module at all. The rival therefore has no lowering to be
> robbed of. (The survey was run anyway and agrees: 19/19 unfolded alternative
> readings in `probes/alt/` decline, plus 13 plain-C spellings in `probes/`, all
> re-measured 2026-09-11 **on the narrowed binary**. In practice 2c fires first
> for 14 of the 15 α shapes, the condition-data-use clause for the 15th, and F1
> for the β rivals — which is SCOPE H-4: the theorem's fence is a BACKSTOP that is
> rarely reached, which is fine but fragile.)
>
> **β IS NOT COVERED BY THAT THEOREM** and gets its own argument, from the state
> vector: on the pinned edge the register is pinned to the seed by a SOUND LVI
> edge fact (a singleton range is a superset claim, the same soundness IPSCCP
> relies on to perform the substitution), so within that flag subspace the rail is
> the PRODUCT basis state |seed⟩ and carries no superposition. The rival's only
> reversible realisation is a controlled copy of it into a fresh |0⟩ rail, which
> on that subspace yields |seed⟩⊗|seed⟩ — exactly what preparing |seed⟩ yields;
> and the other subspace is identical in both readings because the ARM's seed is a
> literal in both. Nothing is cloned. What is given up is F1's loud refusal of the
> UNFOLDED spelling, which still stands.
>
> **⚠ RETIREMENT TRIGGER (SCOPE H-4), and it is a live wish:** *the day any
> chained rotation arm whose `RotBase` is in `CondRails` LOWERS — R4 narrowed, or
> 2c made position-aware enough to admit a post-region rotation on the condition's
> wire — this narrowing is an OVER-ACCEPT and must be re-derived from scratch.*
> "Rotate the flag in place" is a natural Grover-ancilla idiom. Correspondingly,
> narrowing `condProvenance` was already a Rule-13 change to R4 and is now one to
> **F2 as well**.
>
> **⚠ THE EXCLUSION IS AT THE TEST, NEVER AT THE ANCHOR (SCOPE H-6).** `CondWire`
> members keep SEEDING the forward evaluation — they are still `f2Note`d and their
> users are still modelled — and only the *answer* is filtered. MEASURED on a
> deliberate anchor-spelling mutant (filtering `Cand` and the fp anchor instead):
> **all 40** F2 fixtures flip, including the six F-R1-1 CONFIRMED plain-C
> miscompiles, the 30-program sideways family, the four curated intrinsics **and
> all three `Truncated` cells** — a smaller candidate list never trips the step
> bound, so the conservative half becomes selectively skippable (SCOPE H-8). The
> shipped narrowing therefore touches no path that sets `Truncated`.
>
> **⚠ THE OWNER'S `grover_oracle_uncompute.c` STILL DOES NOT COMPILE.** F2 was
> **wall 3 of 3**: `control flow` (TWO merge phis, bd `b6ap`) → `bare i1 register
> condition` (bd `l4x4`) → F2. Only wall 3 moved. Measured 2026-09-11 on the
> narrowed binary: `probes/V0.c` ⇒ `control flow`; `probes/C2.c` and `probes/M1.c`
> ⇒ `bare i1 register condition`. Pinned by
> `control_inplace_ry_reject_stateprep_rail_i1_seed_l4x4.ll`.
>
> **NO NEW FROZEN SYMBOL, no YAML row, no `include/` change** — the owner refused
> a new `cq_*` function and the narrowing needs none. Scope record:
> `inc1-records/session-f2-i1/SCOPE_f2_i1.md` (+ `probes/`) and `IMPL_f2.md`.
>
> **⚠ THIS IS AN ACCEPT-WIDENING OF A RULE-13 CORE FENCE THAT LOST FOUR
> CONSECUTIVE ADVERSARIAL ROUNDS** (Inc-4 R1–R4, each to a different InstCombine
> rewrite). Budget **two** rounds. The standing lesson — *a syntactic answer to a
> semantic question loses* (bd memory `f2-syntactic-enumeration`) — applies to the
> narrowing too, since the exclusion set is a syntactic cone. Its saving grace is
> the DIRECTION: the excluded set has a theorem, so a round should attack **the
> theorem**, not the cone.


> **Status: IMPLEMENTED 2026-09-05** (bd `test_C_libtooling-drbq.5`; the
> implementation record is `CONTROL_IN_PLACE_INC4_NOTES.md`, and the post-4 twin
> matrix is `inc4-records/inplace_stateprep_post4.txt` beside the pre-4 one —
> **the pair is the witness**). Everything below is the DESIGN as settled
> 2026-09-04; wherever the implementation MEASURED something different it carries
> a dated `CORRECTED 2026-09-05` note in place rather than a silent edit. There
> are **six** such notes: §14.2b (F2's `fcmp` completeness argument survives, the
> two fp DECLINE ROWS' strings do not), §14.3 (rows A-12, A-15, A-18, F2-8, FP-1,
> IE-3, IE-4, IE-5), §14.4 (F1's third clause is UNREACHABLE, not hand-IR-only),
> §14.6 (`warnLiveRecordRotations`, re-derived and measured), §14.9 (the fixture
> and slice counts) and a NEW §14.13 carrying the increment's headline finding.
>
> **THE ONE THING TO READ IF YOU READ NOTHING ELSE: `clang -O1` SINKS A
> POST-REGION OP ON `r` INTO THE ARM**, because a state-prepped register's
> straight-through value is a compile-time constant and the op folds on that edge.
> `int s = r * 3;` after the region turns the accept shape into `arm = {theta,
> mul}` and DECLINES. The CHAINED twin is immune, which is exactly why no probe in
> this section could see it. §14.13.
>
> Originally written at HEAD `b506b3b` against a
> pre-Inc-4 oracle built in a scratch worktree from the same commit. **The two
> binaries are the same file** — `md5 -q` of `build/ir-pass/cq-opt` and of
> `scratchpad/wt/pre4/build/ir-pass/cq-opt` are both
> `8931bc461dc1db08e90288880f7d67be` (and `libCQPass.so`
> `82217c6381c0bf0cf56f92b02b043c96`), re-measured independently by two agents;
> 108 probe programs were nonetheless run through BOTH with **0 disagreements**.
> Every "measured" claim below is a program that was compiled at `-O1`, run
> through `cq-opt`, and — where it accepts — linked and executed. Implementing
> epic bd `test_C_libtooling-drbq`, child `drbq.5`. **A Rule-13 core change**
> touching `ArmClassify`, `SwapRouteEmit` and `RotationLowering`.
>
> Companion measurements: `inc4-records/PROBE_RESULTS.md` (committed beside this PRD; originally `scratchpad/probe/RESULTS.md`) (70 probes, the
> pre-implementation record) and `inc4-records/PRD_PROBES.md` (38 more, the
> fold / derived-temp / uniqued-constant / `fcmp` questions).
>
> **THE HEADLINE, AND IT IS NOT WHAT §7's INC-4 BULLET SCOPED.** §7 promised
> "ONE new fence: the merge phi's pred-edge incoming is a `Constant`
> BIT-IDENTICAL to `T`'s seed". That fence is necessary and **it is not
> sufficient**. `clang -O1` performs equality value-propagation on BOTH edges of
> an `icmp eq`/`ne` diamond, and the result is that **two programs CQ must
> decline compile to a module BYTE-IDENTICAL to a genuine state prep**:
>
> ```c
> int r = 0; if (q == 0) r = cq_theta(q, .9);   /* an in-place Ry on the CONDITION register — R4 forbids it */
> int r = 0; if (q == 0) r = cq_theta(0, .9);   /* genuine state prep — Inc 4 wants to accept it */
> ```
>
> `diff` of the two `-O1` modules differs only in `source_filename`
> (probe `p08a` vs `p08a_ctl_prep0`; independently re-measured as
> `prd/ir/q01` ≡ `q04` and `q02` ≡ `q05` on the *straight-through* side). An Inc 4
> that reads the shape as state prep turns **two loud declines into silence** —
> the class the Inc-2b clearance blocked on. So this increment ships **TWO** new
> fences: **F1** (seed identity, §7's) and **F2** (the equality-fold ambiguity,
> new). §7's bullet is corrected in place with a pointer here.
>
> **AND THE SHIPPED COMPILER ALREADY READS THAT SAME IR SHAPE THE OTHER WAY, FOR
> THE OTHER STEM.** `if (q == 0) q = cq_phi(q, .9)` reaches the pass as
> `cq_phi_si32(i32 0, 0.9)` and **ACCEPTS today**, emitting
> `cqrt_rz_i32_controlled(h1, h0, .9)` on **q's own rail** — `tryEqFoldArm`
> (`EqFoldArm.cpp` D1–D8) exists precisely to *undo* the fold and re-anchor onto
> the handle (probe `p08l`, measured accepting on both binaries). After Inc 4 the
> two stems read one IR construct two ways, and §14.2d states why that is sound
> rather than a contradiction.

### 14.1 The accept shape, and the physics

**The shape.** A flat `BranchRegion` — a **DIAMOND**, and only a diamond (§14.2a
explains why the shape restriction falls out of F1 rather than being added) —
whose single content arm is exactly one `@cq_theta_<sfx>` call `T` whose **arg-0
is a CLASSICAL `Constant`**, whose result is the merge φ's arm incoming, and
whose merge φ's **pred-edge incoming is a `Constant` bit-identical to that seed**.
From C:

```c
int r = SEED;  if (COND(q))  r = cq_theta(SEED, θ);   /* θ classical */
```

**The lowering.** Identical in every step to Increment 1 except that the arm gate
mints its own rail:

1. flag mint at `BI` — `cq_template_icmp_<pred>_<W>_hl(c, k)`, unchanged;
2. `cqrt_x(f)` if the arm is the FALSE successor (Rule 9), unchanged;
3. **hoist `T` to before `BI`** (move, never re-mint), record
   `taint.ControlledRotations[T] = f`, unchanged;
4. `lowerRotations` takes the `!Chained` arm — `cqrt_alloc_<W>(SEED)` at the
   theta's **hoisted** position — and then mints
   `cqrt_ry_<W>_controlled(f, h_new, θ)` instead of the unconditional gate;
5. `cqrt_x(f)` closing bracket, flag strip `…_hl_unc(f, c, k)`, `cqrt_free(f)`,
   unchanged;
6. merge φ RAUW → `T` (**M-β**), scrub, erase, `flattenRegion`, unchanged.

**Emitted trace order, and it is a design decision not an accident:**
`icmp_hl → [cqrt_x] → cqrt_alloc(SEED) → cqrt_ry_<W>_controlled → [cqrt_x] →
icmp_hl_unc → cqrt_free(f)`. The alloc lands **after** the flag mint and
**inside** a negated arm's `cqrt_x` bracket, because `lowerRotations` sets its
insert point at the (hoisted) theta (`RotationLowering.cpp:255`) and the emitter
put the theta there. Hoisting the alloc to the top of the pred instead is also
correct physics — a fresh-rail alloc commutes with every gate that does not name
its handle — but it **moves the golden**, so it is fixed here: **the alloc stays
at `lowerRotations`' natural position** and the goldens and the §14.8 reduction
are written to that.

**The physics.** Let `C` be the condition's register set and `R` the fresh rail.

* On the `f=0` component the rail is never touched, so it holds `|SEED⟩` — which
  is exactly the value the source's `r` has on the straight-through edge, **by
  F1**. That equivalence is the whole reason F1 exists; without it the merge is a
  data mux between a prepared rail and an unrelated constant.
* On the `f=1` component the rail holds `Ry(θ)|SEED⟩` — the source's arm value.
* The strip `…_hl_unc(f, C, k)` recomputes the predicate on `C` and XORs it back.
  **Valid because `R` is a rail the compiler minted inside this region: it is
  disjoint from every wire in `C` by construction, not by proof.** This is the
  one place Inc 4 is *easier* than Inc 1 rather than harder — R4's whole
  obligation is discharged structurally (§14.5).
* `cqrt_free(f)` on a provably-`|0⟩` flag (Rule 6), unchanged.
* `R` is **FROZEN** by Inc 1's structural freeze
  (`ChainWalk::railCarriesControlledRotation`, which asks the emitted gate's own
  arg-1 use). Measured in the twin: `h1` is never freed and stage 2b reports it
  `left allocated`. For state prep the frozen rail is one **the compiler itself
  allocated**, so the leak is O(1) per region and is the Rule-6-sanctioned
  fallback; a `cqrt_free` of it would be a dirty free of a
  condition-entangled rail.

No copy, no reverse-play, no work rail, no route. The swap route cannot carry
this either — `Ry(θ)|0⟩ ≠ |0⟩`, so an inactive routed work rail would be left
dirty and entangled (Rules 6/8, §2) — so control-in-place is again the MECHANISM,
not a peephole.

### 14.2 The two new fences

#### 14.2a F1 — SEED IDENTITY (the merge is faithful)

> **F1.** The region's merge φ must have a **Pred-edge incoming**, and that
> incoming must be a `ConstantInt` or `ConstantFP` **bit-identical** (same LLVM
> type AND same bit pattern) to `T`'s arg-0. Anything else declines
> `state prep seed does not match the merge incoming`.

Five things about the spelling, each of which a naive implementation gets wrong:

1. **It must be an EXPLICIT clause with its own string and its own fixtures.**
   Today the shape is refused twice over by *pointer identity on uniqued
   constants* — R3's `if (Routed && RotBase != Routed)`
   (`ArmClassify.cpp:2310-2313`) and the emitter's
   `T->getArgOperand(0) != Base` (`SwapRouteEmit.cpp:588-592`). LLVM uniques
   `ConstantInt`/`ConstantFP` by type+bits, so those two tests *already* enforce
   seed identity — **by accident of representation, with no comment saying so and
   no fixture pinning it**. That is the "passes for a reason nobody wrote down"
   shape this file keeps finding. F1 is written out, given its own message, and
   pinned; R3 and the emitter check keep their own strings for the shapes they
   are about (a cross-handle mux).
2. **`ConstantInt`/`ConstantFP` ONLY.** `undef`, `poison`, a `ConstantExpr`, a
   `GlobalVariable` address, a `ConstantAggregate` and a `BlockAddress` all
   decline. Two reasons, not one: a `ConstantExpr` is a **link-time** constant
   whose value this compiler cannot read (the Inc-2b round-2 finding, one family
   over), and `undef`/`poison` in two emitted gate slots is the bd `xy9n`
   literal-integrity defect (`LiteralIntegrity.cpp`) — a literal `undef` is read
   as **two different values** at the `-O0` stage 3, so "the rail starts at
   |SEED⟩" is not even a well-formed claim.
3. **Bit identity, spelled as bit identity.** `-0.0` vs `0.0` must decline, and
   it is **reachable from plain C in both directions** — probe `p07b`
   (`double r = -0.0;` with `cq_theta(0.0, θ)`) and `p07c` (the mirror), both
   measured surviving `-O1` with the two constants distinct in the IR. A pointer
   comparison happens to be correct here (LLVM uniques `ConstantFP` on the
   `APFloat` bits), but a hand-written `APFloat` comparison must use
   `bitwiseIsEqual`, **never `compare`/`==`**, which calls `-0.0 == 0.0`.
4. **A non-constant incoming is a DATA MUX and declines** — the same string.
   Measured: `int r = q; if (q > 5) r = cq_theta(0,.9);` keeps `%1` as the pred
   incoming (`prd/ir/q17`), and `int r = cc ? 0 : 3;` keeps a classical
   `select i32` (`p21b`). Both are muxes of two different registers.
5. **F1 REQUIRES A PRED EDGE, WHICH IS WHY THE ACCEPT IS DIAMOND-ONLY.** An
   if/else merge φ has no Pred incoming at all, so F1 cannot be satisfied and the
   if/else shape declines *without a separate clause*. It gets one anyway —
   §14.2e — because the owner ruled on it and because a fence that fires by
   absence is a fence nobody can find.

**The runtime-seed spelling is structurally the same shape and is DECLINED, as an
owner question** (§14.11 Q2). Probe `p16`: `int r = seed; if (q == 5) r =
cq_theta(seed, .9);` has the merge's pred incoming and the theta's arg-0 as **the
same SSA value** (`%0`, a classical function argument), and `cqrt_alloc_<W>`
takes a runtime value — so the fence spelled *"the pred incoming is the SAME
VALUE as `T`'s arg-0, and that value is classical"* would subsume it for free.
It ships **declined** because the owner's scope says `Constant`, and because the
`Constant` spelling is what makes `-0.0` a decline (value identity on a uniqued
constant already IS bit identity; SSA identity on a runtime value proves nothing
about `-0.0`, but there `-0.0` is not a compile-time fact either).

#### 14.2b F2 — THE EQUALITY-FOLD AMBIGUITY, and it is POLARITY-FREE

> **F2.** If the region's condition is an **equality** `icmp` (`eq`/`ne`) between
> a **tainted** operand and a `ConstantInt` `k` (position-free — `clang -O1`
> canonicalizes the constant to either side), and `k` is **bit-identical** (type
> AND value) to `T`'s seed, the region declines
> `state prep seed is proven equal to the condition register`.
> **There is no polarity clause.**

**Why there is no polarity clause, stated as a proof rather than a convenience,
because a polarity clause is exactly where bd `ogw2` put a wrong unitary.** On an
`icmp eq`/`ne` diamond the two successors are the arm and the straight-through,
and **exactly one of them is the edge on which the equality is a theorem**
(`eq` → successor 0; `ne` → successor 1). So there are exactly two physical
readings of a folded seed, and F2's single test covers both:

* **A1 — the ARM is the proving edge.** `clang -O1` replaces every use of the
  condition handle inside the arm by `k`, so `cq_theta(q, θ)` — an in-place Ry on
  the CONDITION REGISTER, which **R4 forbids** — arrives as `cq_theta(k, θ)`.
  Seed = `k`. Measured: `p08a`, `p08c`, `p08d`, `p08e`, `p08f`, `p08g`, `p08k`.
* **A2 — the STRAIGHT-THROUGH is the proving edge.** The same substitution
  applies to the merge φ's pred incoming, so `int r = q;` — an **alias of the
  quantum register**, which cannot be muxed against a fresh rail (Rule 8,
  no-cloning) — arrives as `int r = k`. Pred incoming = `k`, and **F1 forces
  seed = pred incoming**, so seed = `k`. Measured: `p23b ≡ p23d`, `p23a ≡ p23c`,
  and independently `prd/ir/q01 ≡ q04`, `q02 ≡ q05`.

Given F1, both readings collapse to the single condition **seed == k**, which has
no edge in it and therefore nothing to get backwards. That is the whole argument
for the spelling.

> **⚠ CORRECTED 2026-09-05 (round-1 Rule-13 review, lens L2 findings F-L2-1 /
> F-L2-2 / F-L2-5 — the first two graded CONFIRMED-MISCOMPILE and both reachable
> from ordinary `clang -O1` C). THE ALGEBRA ABOVE IS RIGHT AND THE ENUMERATION
> WAS THE DEFECT.** There is a **third** reading:
>
> * **A3 — either edge proves `H != k` (or any ORDERED relation), and `H`'s own
>   RANGE makes the surviving set a SINGLETON whose value is NOT `k`.** The A1/A2
>   argument silently assumed that only an equality-with-`k` can pin, which is
>   true of the mechanism the author had in front of him and false of the object.
>
> MEASURED (probe `k08`): `int t = q & 1; int r = 1; if (t) r = cq_theta(t, θ);`
> — an in-place Ry on the CONDITION REGISTER, the shape R4 forbids — reaches the
> pass as `%2 = and i32 %1, 1; %3 = icmp eq i32 %2, 0; br %3, merge, arm` with the
> arm folded to `cq_theta(i32 1, θ)`, because on the `!= 0` edge a 1-bit-masked
> value must be 1. Seed `1`, `k` `0` → the shipped literal test was silent BY
> DESIGN → the region ACCEPTED and `%2`'s rail was never rotated. **Nine distinct
> plain-C spellings accepted** (`q & 1`, `q % 2u`, `((unsigned)q) >> 31`, the
> `t != 0` and `switch (t)` forms, both polarities); the pre-Inc-4 binary declined
> every one.
>
> **F2 IS NOW RANGE-BASED, ON BOTH EDGES, AND ASKS THE QUESTION THE OBJECT ASKS:**
> for each of the branch predicate and its inverse, intersect
> `computeConstantRange(H) ∩ ConstantRange::fromKnownBits(computeKnownBits(H))`
> with `ConstantRange::makeExactICmpRegion(pred, k)`; if the result
> `isSingleElement()` and that element equals the seed, decline. That is the same
> arithmetic `clang`'s IPSCCP used to create the ambiguity
> (`SCCPInstVisitor::handleCallResult` intersects the operand's lattice range with
> `makeAllowedICmpRegion` and substitutes on `isSingleElement()`). The
> `isEquality()` gate is DROPPED (an ordered compare pins at an extremum exactly
> as an equality does; the shipped spelling declined `o01`–`o05` only because
> instcombine happened to canonicalize them into `icmp eq`, which is measured, not
> guaranteed). **The plain literal test is KEPT** — it is subsumed for `eq`/`ne`
> but it does not depend on ValueTracking at all, so the A1/A2 family stays
> refused even if a future LLVM weakens the range analysis.
>
> **IT IS MONOTONE**: this clause only ever declines, so a range that is too wide
> loses a decline and one that is too narrow costs an over-decline. That is also
> why `computeKnownBits`' modulo-poison guarantee (`PoisonFacts.h`) is admissible
> here where `QramLowering` had to refuse it.
>
> **RED-GREEN:** `..._reject_stateprep_range_mask1.ll` (the `k08` module),
> `..._range_a2_alias.ll` (the A2/`k06` side), `..._range_ordered.ll` (the pin for
> the dropped `isEquality()` gate) with its one-token accept twin
> `..._stateprep_range_ordered_seed0.ll`, `..._range_knownbits.ll` (the half
> `computeConstantRange` alone cannot see) and `..._range_i1_both_edges.ll`.
>
> **ONE SHIPPED ACCEPT FIXTURE FLIPPED TO A DECLINE, AND IT WAS AN OVER-ACCEPT:**
> `control_inplace_ry_stateprep_i1.ll` compared an `i1` register against `true`
> with an `i1 false` seed. At `i1` there are only two values, so BOTH edges pin,
> and the straight-through edge pins to `false` = the seed — i.e. the module was
> byte-identical to `i1 r = q; if (q == true) r = cq_theta(false, θ);`, the A2
> no-cloning shape. The whole "`i1` condition + `i1` seed" class is ambiguous by
> arithmetic. The `i1` WIDTH capability is untouched: that fixture now carries the
> same `i1` prep under an `i32` condition and still accepts.
>
> > **⚠ THAT LAST SENTENCE IS FALSE AS OF ROUND 3 (F-R3-8) — do not quote it.**
> > The semantic form asks about the BRANCH CONDITION itself, which is a tainted
> > `i1` pinned to `true` on one edge of its own branch and `false` on the other,
> > so an `i1` seed collides no matter what type the compare is at. The `i1`
> > STATE-PREP WIDTH IS OUT; see the round-3 block below and
> > `..._reject_stateprep_i1_{arm_flag,flag_pinned}.ll`.
>
> **⚠ CORRECTED 2026-09-05 (round-2 Rule-13 review, lens R1 finding F-R1-1,
> graded CONFIRMED-MISCOMPILE and reachable from SIX distinct plain-C spellings).
> THE ROUND-1 FIX WIDENED F2's *PREDICATE* AND KEPT F2's *SET*. That is the bd
> `8h7d.5` F-1/F-3 shape a third time, in the same file, and it is the sentence
> to carry out of this increment: when you widen a set, ask in writing what OTHER
> set is computed over the same closure.**
>
> The range test above is asked of `H` — the tainted operand of the compare CQ is
> handed. `clang -O1` does not leave that register where the theorem is. MEASURED
> with isolated `opt` pipelines on the `-O0` IR, not inferred:
>
> ```
> opt -passes='function(mem2reg),ipsccp'             x01 -> cq_theta_si32(i32 6, …)
>      …with the compare STILL `icmp ne (add (and q,1), 5), 5`
> opt -passes='function(mem2reg,instcombine)'        x23 -> the compare REWRITTEN
>      to `icmp sgt %1, -1`, the arm operand left alone
> opt -passes='function(mem2reg,instcombine),ipsccp' x23 -> no fold at all
> ```
>
> IPSCCP proves the pin about a register **X** whose edge range really IS a
> singleton and substitutes it into the arm's `cq_theta`; a **later** InstCombine
> rewrites the COMPARE downward onto an **ancestor** of X. So the `H` CQ sees is
> the ancestor and **X is a FORWARD USER of `H`**, which the round-1 fence never
> asked about. Six plain-C programs accepted that way **with X alive in the
> emitted circuit, measured by the source, and never rotated**:
>
> | probe | source | X in the lowered stream | round-1 HEAD |
> |---|---|---|---|
> | `x01` | `t = 5+(q&1)` | `cqrt_addc_i32(h1,5)` (in place on the condition rail) | ACCEPT |
> | `x05` | `t = (q&1)^7` | `cqrt_xorc_i32(h1,7)` (in place on the condition rail) | ACCEPT |
> | `x07` | `t = (q&1)-4` | `cq_template_or_i32_hl(h1,-4) -> h4` | ACCEPT |
> | `y05` | `t = (q&1)\|8` | `cq_template_or_i32_hl(h1,8) -> h4` | ACCEPT |
> | `x23` | `s = ((unsigned)q)>>31` | `cq_template_lshr_i32_hl(h0,31) -> h3` | ACCEPT |
> | `x22` | `s = q>>31` | `cq_template_ashr_i32_hl(h0,31) -> h3` | ACCEPT |
>
> The control that closes the argument, and it is CQ's own reading rather than a
> reviewer's: the same program with the guard removed emits
> `and_i32_hl(h0,1) -> h1 ; addc_i32(h1,5) ; ry_i32(h1,.9)` — **identically on the
> PRE-Inc-4 binary** — so `cq_theta(t,θ)` means an in-place Ry on `t`'s rail.
> Adding the guard moved the rotation onto a rail that did not exist before and
> left `h1` unrotated while the source measures it. **Different unitary.**
>
> **F2 NOW ASKS ITS QUESTION OF A BOUNDED FORWARD CLOSURE, NOT OF `H`.** Seeded
> with (`H`, `H`'s value set on this edge), the walk pushes forward through `H`'s
> **tainted** users that are **same-type integer `BinaryOperator`s with a
> `ConstantInt` in the other slot** (`add`/`sub`/`mul`/`and`/`or`/`xor`/`shl`/
> `lshr`/`ashr`/`udiv`/`sdiv`/`urem`/`srem` — all dispatched by
> `ConstantRange::binaryOp`, which returns a WIDER range for anything it cannot
> model precisely, never a narrower one), and every member is asked F2's own
> singleton question. Hand-checked and then measured on all six: `{1}+5={6}`,
> `{1}^7={6}`, `{1}|-4={-3}`, `{1}|8={9}`, `lshr([INT_MIN,0),31)={1}`,
> `ashr([INT_MIN,0),31)={-1}`.
>
> **IT IS A QUESTION ABOUT VALUES ON AN EDGE, NOT ABOUT A PROGRAM POINT** — which
> is why it does not matter that `%8 = add %2, 5` sits in the MERGE block, where
> its unconditional range is `[5,7)` rather than `{6}`. F2 asks whether the source
> could have been `cq_theta(t, θ)` with `t` the live register; on the arm edge `t`
> IS 6, wherever LLVM chose to schedule the `add`.
>
> **CASTS ARE NOT FOLLOWED**, and it is the SAME ruling as F2's same-type gate
> rather than a second one: a width- or type-changing cast of `H` is a different
> physical wire by construction, because every cast CQ can lower is OUT OF PLACE
> (§14.2c item 1, re-measured 2026-09-05 on `sext`/`zext`/`trunc`/`sitofp` and on
> a same-width `bitcast` reached through a `union`/`memcpy`). Following them would
> be a pure over-decline of the §14.2c derived-temp accept class.
> **φ AND `select` ARE NOT FOLLOWED EITHER**, and that one is a CQ semantics fact
> rather than a `ConstantRange` limitation (`ConstantRange` can union): under CQ a
> φ/`select` over tainted data is not a relabelling of one register —
> `declineClassicalMuxes` refuses a live classical mux outright, and the ones that
> survive are lowered by the 4.4 controlled-XOR copy merge into a **fresh** merged
> register. A value reached through a φ is therefore not the register the arm
> would have rotated, and a pinned φ is the 4.4 path's business.
>
> **BOUNDED, AND THE BOUND DECLINES.** Depth 8 / 64 values; exceeding either is a
> loud F2 decline rather than a silent truncation, because a truncated walk is
> exactly the "we stopped looking and accepted" shape this fence exists to stop.
> The counters are a cost bound and not a termination one — the forward-user graph
> over non-φ instructions is acyclic in SSA.
>
> **RED-GREEN:** six declines transcribed from the six C sources —
> `..._reject_stateprep_range_forward_{add,xor,sub,or,lshr,ashr}.ll` — plus the
> depth-0 control `..._range_mask1.ll` (same clause, no forward hop) and the
> untouched accept `..._stateprep_cond_derived.ll` (no tainted `op constant` user
> exists there at all). **MUTATION:** disabling the forward walk reddens **exactly
> those six and nothing else**, and all six ACCEPT (exit 0) under the mutant.
>
> **AND ONE FURTHER PIN THE ROUND ADDED** (lens R1 finding F-R1-5, WEAK-PIN):
> `clang` canonicalizes the literal to the RIGHT, so no fixture in the family
> exercised the literal-on-the-LEFT path and deleting
> `Rel = ICmpInst::getSwappedPredicate(Rel)` reddened nothing.
> `..._reject_stateprep_range_constleft_ugt.ll` reddens on exactly that deletion,
> `..._reject_stateprep_range_constleft_eq.ll` reddens on deleting the
> position-free `{K, H}` selection (an `eq` cannot discriminate the swap —
> `getSwappedPredicate(eq) == eq`, and the fixture header says so), and
> `..._stateprep_range_constleft_accept.ll` is the accept control that keeps the
> swap a discriminator rather than a blanket over-decline.

> **⚠ THE HULL IS AN OVER-ACCEPT, HAND-IR ONLY TODAY (round-2 review, lens R1
> finding F-R1-3, CONFIRMED-OVER-ACCEPT).** `ConstantRange::fromKnownBits` cannot
> represent `{0,4}`: for `%t = and %q, 4` it yields the hull `[0,5)`, so the
> `ne 0` edge gives `[1,5)` and not the true singleton `{4}` — a genuine A3 pin
> one bit up from `..._range_mask1.ll`'s, which F2 MISSES
> (`hb01_and4_seed4.ll`, `hb02_and8_seed8.ll` accept; `hb03` (`and q,5`, `ugt 4`,
> seed 5) and `hb04` (mask 1) still decline, so the fence is exact only where the
> hull happens to be tight). **It is not reachable from plain C at this clang, and
> the reason is load-bearing:** IPSCCP's lattice is a `ConstantRange` too, so it
> ALSO fails to pin `and q,4` and performs **no fold** — measured on `t01`/`t02`/
> `t03`, whose `-O1` IR keeps `cq_theta(i32 noundef %2, 0.9)` unfolded on both
> binaries. The two analyses currently fail *together*, which is exactly why the
> F-R1-1 class (fold succeeded, question asked of the wrong value) was a
> miscompile and this one is not. **RETIREMENT TRIGGER:** the day LLVM's SCCP
> gains a known-bits-aware lattice and pins `and q,4`, this becomes F-L2-1 again;
> the fix is to enumerate the ≤256 `Known`-consistent values when `Known` leaves
> ≤ 8 bits unknown and intersect those with `Edge`.

> **⚠ AND THE `CtxI`/`DT`/`llvm.assume` NOTES ARE CORRECTED (round-2 review, lens
> R1 finding F-R1-2).** With `AC = nullptr`, `CtxI` and `DT` are **inert**:
> LLVM 19's `computeConstantRange` consults the context only `if (CtxI && AC)`
> and `computeKnownBitsFromContext` returns immediately on `!Q.AC || !Q.CxtI`.
> The site comment is a forward-looking statement about the day an `AC` is
> passed, not a claim that the branch context is in use — stated as ANALYSIS from
> those two guards, since no CQ-reachable program was found whose disposition
> depends on it (every dominating tainted branch declines earlier). And the
> retirement trigger that actually bites is **`DomConditionCache`, not
> `AssumptionCache`**: the dominating-condition machinery InstCombine used to turn
> `icmp ne (lshr %q,31), 0` into `icmp sgt %q, -1` — the rewrite that CREATED the
> F-R1-1 class — is `DomConditionCache`, and F2 could adopt one today seeded with
> `Region.Pred->getTerminator()`. The `llvm.assume` trigger below stays; it is a
> different door into the same room.

> **THE RESIDUAL, STATED AS A BOUNDARY RATHER THAN AS A HOPE.** F2 can only ask
> about registers that STILL EXIST. When the rotated register's only readers were
> the arm and the branch, instcombine DELETES it, and then no analysis of the
> surviving IR can recover it.
>
> > **⚠ CORRECTED 2026-09-05 (round-2 review, lens R1 finding F-R1-2). THIS
> > PARAGRAPH USED TO SAY "instcombine DELETES it AND rewrites the compare onto an
> > ancestor", CONFLATING TWO INDEPENDENT EVENTS, and the conflation is what let
> > F-R1-1 hide inside a paragraph labelled "the residual".** InstCombine
> > **always** rewrites the compare onto the ancestor in this family; it only
> > **sometimes** additionally deletes the register. Only the second is beyond
> > this layer — the first is the forward closure's job and is now fenced. The
> > deletion half is also the only half that is *bounded*, and the argument is
> > worth stating because it is what makes Q3 a scope question rather than a fence
> > question (lens R1, F-R1-4): **a register is deleted only when nothing reads
> > it**, and if nothing reads it, the difference between "rotate that rail" and
> > "rotate a fresh rail prepared to the same pinned value" is confined to a
> > **leaked ancilla that no `cq_measure`, `ret` or tape write observes** —
> > dropping a dead tainted computation is the move the `fenv` ruling already
> > blesses. **That argument does not extend one inch to F-R1-1, where the
> > register IS read**, which is why F-R1-1 was fenced and this is filed. Four measured
> members, all ACCEPTING at HEAD: `k04` (`int b = (q!=0); if (b) r =
> cq_theta(b,θ);` → `icmp eq %q, 0` with `b` gone), `k03` (`(unsigned)q >> 31`),
> `r3` (`int t = q ? 1 : 0;`) and — the sharpest — `r4`
> (`int b = (q==5); int r = 0; if (!b) r = cq_theta(b, .9);`), whose `@slice` body
> is byte-identical to the shipped `_negated` accept fixture's, and `r6`
> (`int b = (q!=5); int r = 0; if (q==5) r = cq_theta(b, .9);`), whose `@slice`
> body is **BYTE-IDENTICAL TO THE FLAGSHIP SLICE'S** (measured with `diff`,
> 2026-09-05). Every one of those alternative sources is a **data mux** (the
> straight-through is a literal while the arm rotates a live derived rail), i.e. a
> program CQ has no lowering for and DOES refuse whenever the register survives —
> measured, `r5` (the same program with `b` kept live) declines
> `condition data use neither escaped nor measured` on BOTH binaries. So the
> residual is: *a program whose correct disposition is a decline for a Rule-8 / mux
> reason, made indistinguishable from the accept class by a fold that deleted the
> evidence.* That is exactly §14.11 Q3's shape, and it is filed there rather than
> fenced, because the only fence that reaches it is Q3's option (b) — decline every
> state prep whose condition is an equality on a tainted operand — which kills the
> flagship.
>
> **WHAT VALUETRACKING DOES NOT SEE, enumerated so the trigger is findable.**
> `computeConstantRange` is documented "cheap, non-recursive": it reads a
> `BinaryOperator`'s operand limits (`and`/`or`/`*rem`/shifts/`add`/`sub` with a
> constant), intrinsic ranges, `!range` metadata, call/argument `range` attributes
> and `select` arms; `computeKnownBits` adds the recursive bit reasoning
> (`zext`/`trunc`/`and`/`or`/`xor`/shifts/φ). Neither sees (i) a range implied by a
> DOMINATING branch other than this region's — IPSCCP's `PredicateInfo` does;
> measured, the C spelling `if (q<2){ if (q!=0) r=cq_theta(q,.9); }` does not reach
> the accept path at all because `-O1` merges the two conditions into an `and i1`
> and the region declines `control flow` on the non-`CmpInst` guard — or (ii)
> `llvm.assume`, because `AC` is deliberately null (see the F-L2-6 trigger below).

> ---
>
> **⚠ REWRITTEN 2026-09-05 (round-3 Rule-13 review, lens R3 — findings F-R3-1 /
> F-R3-2 / F-R3-3, **42 plain-C programs**, every one graded CONFIRMED-MISCOMPILE,
> every one ORACLE-decline / HEAD-accept, strict-2b clean, linked and RUN). F2 IS
> NO LONGER A SET. IT IS THE QUESTION.**
>
> **The three syntactic generations and their measured defeats, recorded because
> this is the memory the next widener needs and not as history.** F2's question is
> semantic — *after `clang -O1`, could the arm's constant SEED (or, equivalently
> under F1, the merge φ's constant PRED INCOMING) be the FOLD of a TAINTED
> register that the source rotated in place and that is still alive?* — and it was
> answered three times by enumerating syntax:
>
> | gen | the SET it asked about | defeated by | measured |
> |---|---|---|---|
> | 1 (shipped Inc 4) | the compare's LITERAL `k` | an edge that pins `H` to something *other* than `k` (A3) | round-1 lens L2, 9 plain-C |
> | 2 (round-1 fix) | `H`'s EDGE RANGE | InstCombine rewriting the compare **DOWNWARD** onto an ANCESTOR of the pinned register | round-2 lens R1, 6 plain-C |
> | 3 (round-2 fix) | `H`'s tainted FORWARD closure through same-type `op constant` | (i) the **SIDEWAYS** rewrite; (ii) the curated `llvm.*` rail family; (iii) the K/seed TYPE GATE one line above the walk | round-3 lens R3, **42** plain-C |
>
> The three round-3 holes in detail, because each is a different part of the
> enumeration and only the FIRST is what a reader expects:
>
> * **(i) DIRECTION — F-R3-1, 30 programs.** InstCombine does not only move the
>   compare *down*. For the division family it rewrites it **sideways, onto a
>   value that did not previously exist**: `icmp eq (sdiv X,C), K` becomes
>   `icmp eq (and X,-C), K*C`, and `icmp eq (div X,C), K` becomes
>   `icmp ult (add X, -K*C), C`. In both, `H` and the rotated register are
>   **SIBLINGS** — two users of the same taint root — so no forward walk from `H`
>   can ever reach it. Population measured by a generated 140-program sweep
>   (op × constant × signedness): **10 accept, 130 decline, all ten the division
>   family**; `mul`/`shl`/`add`/`sub`/`xor`/`or`/`and`/`rem`/`lshr`/`ashr` all
>   declined, which is what isolates the *direction* rather than the opcode as
>   the cause. It survived every variation probed: native `long long` root, the
>   `if/else` shape, two sequential regions, the condition also measured, a
>   two-level composition, seed `0`, a negative seed, `ret` instead of
>   `cq_measure`, the register read only through `z = t*2`, and — the exhibit
>   that needs no argument — `n07_sdiv_theta2`, whose own trace contains
>   `cqrt_ry_i32(h4, 0.5)`, an **in-place** rotation of the very rail the
>   conditional theta refused to rotate, two lines after the fresh prep.
> * **(ii) OPCODE CLASS — F-R3-3, 4 programs.** The walk enumerated
>   `BinaryOperator` users while `IntrinsicLowering.cpp:33-58` curates **16**
>   integer `llvm.*` intrinsics that lower to real rails. The four INVERTIBLE
>   members (`bswap`, `bitreverse`, `fshl`, `fshr`) are the ones InstCombine
>   relocates the compare across, so only they were reachable — an accident of
>   InstCombine, not a fence.
> * **(iii) THE TYPE GATE — F-R3-2, 8 programs.** `K->getType() ==
>   SeedI->getType()`, one line above the walk's caller, skipped the literal test,
>   the range test AND the walk **wholesale** the moment `-O1` narrowed the
>   compare to the root's width. That is what an ordinary `long long t = q;` does
>   (`foldICmpSExtConstant`), and the `sext`/`zext` rail was minted after the
>   region, measured, and never rotated.
>
> **WHAT F2 IS NOW** (`f2SeedPinnedByLiveRegister`, `ArmClassify.cpp`), in three
> pieces, none of which is an opcode list of ours:
>
> 1. **BACKWARD — `LazyValueInfo::getConstantRangeOnEdge`**, asked on **both**
>    edges of the region's branch about **every tainted integer value that is LIVE
>    ON THE EDGE**. LVI is a real edge analysis: it reads the branch itself, so it
>    recovers `(Val & Mask) == C` ⟹ KnownBits on `Val` and
>    `icmp ult (Val + Off), C` ⟹ a range on `Val` — precisely the two rewrites
>    F-R3-1 measured, by an analysis rather than by a preimage table the next
>    InstCombine can invalidate.
> 2. **FORWARD — an abstract evaluation over the tainted USER graph**, with no
>    opcode filter in the accept direction: `ConstantRange::binaryOp` / `castOp` /
>    `intrinsic` / `icmp` where a range models; **exact `ConstantFoldInstOperands`
>    / `ConstantFoldCall` the moment every operand is pinned** (which is what
>    answers `bswap`/`bitreverse`/`fshl`/`fshr`, every cast, and `sitofp` for an fp
>    seed, with no curated id list at all); a `KnownBits` refinement on every value
>    learned; and a `select`/φ hull. It is a FIXPOINT, not a sweep: a range that
>    narrows re-queues.
> 3. **THE TEST is `Constant *` POINTER IDENTITY against the seed.** LLVM uniques
>    `ConstantInt` on type+bits and `ConstantFP` on the `APFloat` BITS, so this is
>    F1's bit-identity discipline reused, it covers an fp seed for free
>    (`-0.0` vs `0.0` correctly stays a non-match), and **there is no type gate**:
>    a value of the SEED'S type is asked about wherever it lives and whatever
>    width the compare ended up at.
>
> **THE `LazyValueInfo` DOMINANCE FILTER IS AN API PRECONDITION, NOT AN
> OPTIMIZATION, and it is the reason the forward half is not redundant.**
> `LazyValueInfoImpl::solveBlockValueNonLocal` asserts `isa<Argument>` for a
> live-in of the ENTRY block and then `cast<Argument>`s it — in a Release build
> that assert is compiled out and the cast is a wild read. MEASURED 2026-09-05:
> asking LVI about `%8 = sdiv %1, 4` (defined in the MERGE block) at `Pred` = the
> entry block **SIGSEGVs `cq-opt` on the flagship**. So LVI is asked only about
> values it is contracted to answer for, and everything defined *after* the branch
> — which is where `-O1` schedules the rotated register in the whole F-R3-1 family
> — is reached by the forward half instead. A null `DominatorTree` (no caller has
> one today) is a loud F2 decline rather than a silently narrowed question.
>
> **THE ONE PLACE IT STILL SKIPS, AND THE ARGUMENT FOR IT** — stated plainly,
> because "not in my set ⇒ accept" is the exact default that lost three rounds. A
> tainted user whose value the evaluation cannot bound **and none of whose
> operands is exactly pinned** is skipped. The argument is not "we do not handle
> it": it is that the seed can only BE a fold if `clang` PERFORMED that fold;
> `clang`'s folds come from IPSCCP's `ConstantRange` lattice, InstCombine's
> `KnownBits`, and `ConstantFolding` — all three of which ARE the machinery above
> — so a value LLVM's own lattice reports overdefined is a value LLVM could not
> have substituted a constant for. `@cq_theta` / `@cq_phi` are the everyday
> members (opaque declarations, overdefined by construction), which is why a
> CHAINED rotation's result is not a fold candidate and
> `..._stateprep_post_region_theta_cond.ll` keeps accepting.
> **AND THE CONSERVATIVE HALF:** if an instruction HAS a tainted operand that is
> EXACTLY PINNED and we still produce no abstract value for it, F2 **declines** —
> "a function of a pinned register that we cannot evaluate". Red-green:
> `..._reject_stateprep_unevaluable_pinned_operand.ll` (an `llvm.fshl` with a
> second, unpinned tainted operand: not foldable, and not one of the intrinsics
> `ConstantRange::isIntrinsicSupported` models), whose one-token control is
> `..._intrinsic_fshl.ll`, where both data operands are the same pinned register
> and `ConstantFoldCall` evaluates the rotate exactly.
>
> **THE BOUND CHANGED SHAPE, AND ONE OVER-DECLINE WENT AWAY WITH IT.** The
> depth-8 / 64-value walk bound is gone; there is one total step cap
> (`kF2MaxSteps` = 4096) and exceeding it still DECLINES, for the same reason as
> before. R3 measured the old bound tripping on ordinary arithmetic —
> `bd_d09_mixed` / `bd_d11_mixed` (11-deep mixed chains, seed 999999) and
> `b05_fanout70_seed999` (70 fan-out users) all declined on the bound alone, with
> no member anywhere near the seed. All three now ACCEPT, correctly, and
> `control_inplace_ry_stateprep_deep_chain.ll` is the red-green for it. Nothing in
> the tree pins the step cap, because no measured program comes within two orders
> of magnitude of it; that is recorded rather than pretended away.
>
> **THE `fromKnownBits` HULL OVER-ACCEPT IS RETIRED (round-2 F-R1-3).** `f2Refine`
> enumerates the ≤ 256 `Known`-consistent values whenever `KnownBits` leaves ≤ 8
> bits unknown and intersects them with the range — the fix F-R1-3 itself named,
> now shipped because the semantic form applies it to every value it learns about
> rather than only to `H`. `hb01` (`and q,4`, seed 4) and `hb02` (`and q,8`, seed
> 8) FLIP from accept to decline; `hb03`/`hb04` were already declining and still
> do; `..._stateprep_cond_derived.ll` (5 unknown bits) still ACCEPTS. Red-green:
> `..._reject_stateprep_range_knownbits_enum.ll`. The fence is now STRONGER than
> the folder that creates the ambiguity, which is the safe direction.
>
> **⚠ THE `i1` STATE-PREP WIDTH IS OUT, AND IT IS A REAL NARROWING OF THE SHIPPED
> ACCEPT CLASS — the one thing in this round that costs capability.** The branch
> condition is itself a TAINTED `i1` value, pinned to exactly `true` on one edge
> of its own branch and `false` on the other; an `i1` seed is one of those two
> constants; so every `i1` state prep now collides on one edge or the other.
> `control_inplace_ry_stateprep_i1.ll` is re-homed as
> `..._reject_stateprep_i1_flag_pinned.ll` (the merge-edge half) and joined by
> `..._reject_stateprep_i1_arm_flag.ll` (the arm-edge half). **The two halves are
> not equally reachable, and the file says so:** the ARM half is measured
> reachable from plain C — `_Bool c = (q==5); _Bool r = 1; if (c) r =
> cq_theta(c, 0.9);` arrives as `cq_theta_i1(i1 true, …)`, an in-place Ry on the
> flag that the shipped type gate skipped F2 for — while three plain-C spellings
> of the MERGE half (`q/z01`, `q/z03`) are **not** folded by this clang and
> decline earlier anyway. The merge half is kept because "absence of evidence is
> not a fence" is this review's own standard and because carving the condition out
> of the test set would re-open the arm half. **The merge EDGE itself is not
> speculative:** `q/z05` and `q/z06` are plain-C programs where the
> straight-through incoming IS a live measured register that `-O1` folds to the
> seed on that edge (`..._reject_stateprep_merge_edge_sideways.ll`), which is why
> F2 asks both edges at all. This corrects the round-1 sentence "the `i1` WIDTH
> capability is untouched": as of round 3 it is not.
>
> **AND ONE MORE GATE WAS DOING THE SAME JOB AS THE TYPE GATE, FOUND WHILE
> CHECKING THAT THE NEW TEST REALLY COVERS AN fp SEED (F-R3-10, fix-agent).** The
> shipped clause opened with `SeedI = dyn_cast<ConstantInt>(RotBase)`, so **no fp
> seed was ever asked F2's question at all** — a second sufficient gate beside the
> type one. Measured from plain C: `double t = (double)q; double r = 5.0;
> if (q == 5) r = cq_theta(5.0, 0.9);` folds the arm's arg-0 to `double 5.0` and
> leaves `%7 = sitofp i32 %1 to double` **alive and MEASURED**, unrotated. The
> semantic form needs no fp arm — `Constant *` identity plus an exact
> `ConstantFoldInstOperands` of the `sitofp` — and the one-token control (seed
> `7.0`) still ACCEPTS. The `fcmp` CONDITION side is UNCHANGED and still declines
> unfolded on R4; what moved is the SEED side.
>
> **RED-GREEN, the whole round-3 batch (17 new files, 15 decline / 2 accept, one
> of the declines being an existing ACCEPT re-homed with its IR unchanged; family
> 85 → 101, corpus 1557 → 1573):** `..._sideways_sdiv.ll`,
> `..._sideways_offset.ll`, `..._cast_sext_live.ll`, `..._cast_zext_live.ll`,
> `..._cast_trunc_live.ll`, `..._intrinsic_bswap.ll`, `..._intrinsic_bitreverse.ll`,
> `..._intrinsic_fshl.ll`, `..._intrinsic_fshr.ll`,
> `..._range_knownbits_enum.ll`, `..._merge_edge_sideways.ll`,
> `..._unevaluable_pinned_operand.ll`, `..._fp_seed_sitofp.ll`,
> `..._i1_arm_flag.ll`, `..._i1_flag_pinned.ll` (the re-home), and the two accepts
> `control_inplace_ry_stateprep_deep_chain.ll` and
> `control_inplace_ry_stateprep_intrinsic_bswap_accept.ll`.
>
> **AND THE `..._cond_cast_seed.ll` RATIONALE IS RETIRED WITH THE TYPE GATE
> (F-R3-7 item 1).** The walk's header said *"a width- or type-changing cast of
> `H` is a DIFFERENT PHYSICAL WIRE …, so following casts would be a pure
> over-decline"*. Both halves of that premise are true and the conclusion does not
> follow: the cast rail being a **different** wire is exactly why preparing a
> **third** wire is wrong when the source rotates the second one and then reads it.
> What actually separates the two files is not the type at all — it is **whether
> the other wire EXISTS in the module**. `..._cond_cast_seed.ll` and
> `..._cond_bitcast_seed.ll` still ACCEPT because `-O1` folded their cast away
> entirely and no `sext`/`bitcast` instruction survives to be asked about;
> `g03_ll_eq5.c` declines because its `sext` is live and MEASURED. The fence asks
> about values that are IN THE FUNCTION, which is the honest form of that
> distinction — and the "MONOTONE … this walk can only ever ADD declines" header
> claim (F-R3-7 item 2) was true of the walk and misleading as a summary of F2,
> because the type gate above it could remove **every** decline the block would
> make. There is no such gate now.
>
> **`warnLiveRecordRotations` IS NOT A BACKSTOP FOR THIS CLASS, AND IT LOOKS LIKE
> ONE (F-R3-7 item 3).** The tree owns a diagnostic that names this hazard
> verbatim — `cq rotation lowering: non-diagonal gate over a live derived record`
> — and it FIRES on the unconditional twins (`u06`) while staying SILENT on every
> one of the 42 miscompiling state preps. The reason is structural and correct:
> the gate's wire is the fresh `cqrt_alloc` handle, whose record set is empty by
> `RecordSet::push` clause 5. "M-A would have caught it" is the natural wrong
> assumption for the next reader, so it is written here.

 (`tryEqFoldArm`'s D8 and `straightThroughConstFoldHandle`'s
`StraightProvesEq` each carry an explicit polarity test because each *re-anchors*
onto a specific edge; F2 only *refuses*, and refusing on both edges is free.)

**F2 is a decline-on-ambiguity, and that is the only order-insensitive fence
available.** Probe `p08s` is the proof: `if (q + 1 == 6) r = cq_theta(q, .9);`
has its compare canonicalized to `icmp eq %1, 5` **but leaves the arm's
`cq_theta(%1, .9)` UNFOLDED**, so the same source arrives folded (`p08h`) or
unfolded (`p08s`) depending on incidental pass order. An accept predicate that
reads "this *looks* like state prep" is therefore order-sensitive by
construction; a decline predicate that reads "this *could have been* the
condition register" is not. `p08s` goes in the decline table as the **unfolded
twin** of `p08h` for exactly that reason.

**F2 reads `ConstantInt` and that is COMPLETE for the floating-point family —
MEASURED, and the reason is an LLVM invariant rather than luck.** An `fcmp oeq`
edge does **not** fold: `double q = …; double r = 0.0; if (q == 0.0) r =
cq_theta(q, .9);` keeps `cq_theta_f64(double %1, 0.9)` in the arm
(`prd/ir/q32`), and so does the `5.0` spelling (`q34`); `diff` against the
genuine fp prep (`q33`) shows exactly that one line differing. LLVM's
`propagateEquality` will not substitute across `oeq` because `oeq` is not a
bitwise-equality proof — `+0.0 == -0.0` — which is the same fact F1 relies on in
the other direction. So the fp shapes reach the pass **unfolded** and decline on
**R4** (masked, today, as `condition predates a non-diagonal gate`; unmask with
`cq_phi`). Two consequences: F2 needs no `fcmp` arm, and the fp accept (`p07a`)
is unambiguous by construction rather than by fence.

> **CORRECTED 2026-09-05 (implementation).** The *completeness argument* above is
> unchanged and was re-measured: F2 reads `ConstantInt` and that is complete for
> the fp family. What is wrong is the parenthetical "unmask with `cq_phi`".
> **THERE IS NO UNMASKING MOVE FOR THIS ROW**, because the masking gate is the
> ARM ITSELF: the arm rotates the fp condition register, so the arm's own theta
> IS the non-diagonal gate on the condition's provenance wire, `condWireDisposition`
> adjudicates before the rotation clause runs, and `declineArm` re-spells. Changing
> the arm to `cq_phi` does not unmask it — it turns the program into the Rz
> path, which accepts. The shipped fixture
> (`control_inplace_ry_reject_stateprep_fcmp_oeq_unfolded.ll`) therefore asserts the
> MEASURED string `condition predates a non-diagonal gate`, and the same applies
> verbatim to §14.3 row F2-8 (`p08s`). Both were measured IDENTICAL on the
> pre-Inc-4 oracle, so both rows are pinning PRE-EXISTING behaviour. **Retirement trigger:** if
LLVM ever gains an `oeq`-edge substitution for non-zero, non-NaN constants, F2
owes an `fcmp`+`bitwiseIsEqual` arm and `q32`/`q34` become its red-green pair.

**What F2 does NOT need to do today, with its retirement trigger.** A compound
`&&`/`||` condition **also** folds — measured, `p08q`: `if (q == 5 && p == 3) r =
cq_theta(p, .9)` arrives as `cq_theta(i32 3, .9)`, i.e. a compound condition pins
a SECOND register too — but a compound condition reaches **no** control accept
path: `classifyArms` declines `!isa<CmpInst>(Region.Condition)` outright
(`ArmClassify.cpp:1566-1570`, re-measured 2026-09-05; measured on both binaries with a PHASE arm,
`prd/ir/q12` declines while its simple-condition sibling `q13` accepts and runs).
So F2 reads one compare and needs no `and`/`or` leaf walk.
> **RETIREMENT TRIGGER, written now rather than discovered later (the bd 8h7d.5
> F-1/F-3 discipline): the day compound conditions are admitted to any control
> accept path, F2 must be asked of EVERY LEAF of the flag network, and of every
> register any leaf pins — not just of the register the arm rotates.** `p08q` is
> the committed reproducer for that day.

> **SECOND RETIREMENT TRIGGER — `llvm.assume` (added 2026-09-05, round-1 review,
> lens L2 finding F-L2-6).** `__builtin_assume(q == 0); int r = 0; if (p > 5) r =
> cq_theta(q, .9);` folds the arm to `cq_theta_si32(i32 0, .9)` with a condition
> **on a different register**, i.e. F1 satisfied and F2 structurally vacuous (the
> fold's source is not the region's own compare). The ONLY thing that declines it
> today is `declineTaintEscapes` treating `llvm.assume` as an unknown callee — a
> guard written for a different purpose, mentioned nowhere in §14, and measured as
> the sole obstruction on both binaries. If `llvm.assume` is ever whitelisted (a
> plausible move for `__builtin_assume`-heavy injected libm bodies), **every
> dominating-equality fold becomes reachable and F2 covers none of it.** The first
> half of the fix is one line — F2's `computeConstantRange`/`computeKnownBits`
> calls already take an `AssumptionCache` and are passed `nullptr` — but the
> second half is not: an assume-pinned register need not be the compare's operand
> at all. `f05` is the committed reproducer for that day.

#### 14.2c What F2 costs, and the residual it deliberately does NOT fence

**The cost is a genuine over-decline, and it is the shipped disposition.**
`int r = 5; if (q == 5) r = cq_theta(5, .9);` (probe `p06a`) is an unambiguous,
well-formed state prep at the source level, and it declines — because its `-O1`
IR is **byte-identical** to `int r = 5; if (q == 5) r = cq_theta(q, .9);`
(`p08e`) and to `int r = 5; if (q > 4 && q < 6) r = cq_theta(q, .9);` (`p08c`),
both of which must decline. The same applies to `p23b`
(`int r = 5; if (q != 5) r = cq_theta(5, .9);`) on the A2 side. **Three genuine
programs over-decline; the fence is Prime-Directive-correct and the user's
workaround is one character** (any seed other than the compare literal).
Owner question §14.11 Q1.

**The DERIVED-TEMP fold is a documented ACCEPT, not a fence, and the argument is
narrower than it first looks.** `if (q == 5) r = cq_theta(q - 5, θ)` folds to
`cq_theta(0, θ)` (`p08b`, IR identical to the flagship `p01`), seed `0` ≠ `k` `5`,
so F1 and F2 both pass and Inc 4 **accepts** it. Three measured facts make that
faithful:

1. ~~**The folded value is `f(k)` for the function `f` the source wrote, and `f`
   is not the identity** (if it were, `f(k) == k` and F2 would have refused).
   `t = f(q)` in CQ's own semantics is an **out-of-place** derived rail — a
   different physical wire from `q` — so preparing a fresh rail is the right
   SHAPE; only its content off the `f=1` component could differ.~~
   **CORRECTED 2026-09-05 — BOTH HALVES OF THAT SENTENCE ARE FALSE** (round-1
   Rule-13 review, lens L2 finding F-L2-3 = lens L6 finding F-2, and lens L1
   finding F-L1-3):

   * *"`f` is not the identity (if it were, F2 would have refused)"* is false at a
     **width boundary**. `long long r = 5; if (q == 5) r = cq_theta((long long)q,
     .9);` folds to `cq_theta_sll(i64 5, .9)` against `k = i32 5`; `sext` IS
     numerically the identity, `f(k) == k` as a number, and F2 does **not**
     refuse — its SAME-TYPE gate keeps it silent. That gate is therefore the
     load-bearing CROSS-WIDTH DISCRIMINATOR, not the mechanical `APInt`
     precondition its shipped comment called it, and tidying it into a value-only
     comparison would silently flip this accept **and** a legitimate cross-width
     prep to declines. Pinned by `..._stateprep_cond_cast_seed.ll`.
   * *"`t = f(q)` is an out-of-place derived rail"* is false for
     `f ∈ {+k, −k, ^k}`, which is exactly CQ's **in-place** ABI. MEASURED:
     `int t = q+1; int u = cq_theta(t,.9);` with `q` dead emits
     `cqrt_addc_i32(h0,1); cqrt_ry_i32(h0,.9)` — `t` IS `q`'s rail. The pass's own
     wire doctrine says so at `ArmClassify.cpp`'s `railWireClosure` (`add`/`sub`/
     `xor` with one tainted operand are the SAME wire; `mul`/shift are not), and
     `railWireClosure` is what R4 — the fence F2 substitutes for — is built on.
     The `mul`/shift sub-family is genuinely out of place and the original
     argument is correct **for those**.

   **WHAT ACTUALLY CARRIES THE ACCEPT, then, is narrower and is stated as such:**
   for the cast sub-family, the WIRE argument (measured on all five spellings
   `-O1` can fold — `sext`, `zext`, `trunc`, `sitofp`, and the same-width
   `bitcast`, whose unfolded twin lowers to
   `cq_template_bitcast_i32_to_f32(%h) -> %h_cast`, a fresh handle); for the
   `+k`/`−k`/`^k` sub-family, **nothing** — the in-place/out-of-place choice is
   M-C's, made in `lowerOps` long after detection, and in the FOLDED module the
   op does not exist for M-C to decide about. Adding the second reader that would
   force the question also prevents the fold (measured, `n06`/`i02`), so the two
   questions are mutually exclusive by construction and the shape's correctness is
   **unproven in both directions**. It ships accepted per the owner's scoping
   example; §14.11 Q3 is where that decision lives, and this is the sub-family it
   is about.
2. **Nothing reads it off that component.** The merge's other incoming is the
   pred constant, and `t` has no other reader — **enforced by the fold itself**:
   measured (`prd/ir/q22`, `q23`), when the derived temp has a second reader
   `clang -O1` does **not** fold it at all; the `sub` survives, the arm's arg-0
   stays `%2`, and the region declines on R1/R4. `-O1` at this level folds a value
   everywhere-and-DCEs-the-definition, or nowhere.
3. **The fold is not restricted to the arm and not to the compare's operands** —
   `int t = q + 3;` defined *before* the region folds to `3` under `q == 0`
   (`prd/ir/q19`) and the `add` is deleted — so the residual is a property of
   value propagation generally, not of arm-local rewriting. `prd/ir/q24` sharpens
   it: a loop-carried `t` folds to `1`, so **the folded seed need not equal `k`
   and need not be `0`**; with a matching `int r = 1;` that shape passes both
   fences and is accepted on the same argument.

Two clean sub-families ride the same accept and are worth fixtures because they
show F2 is not over-broad: an **unconditional** identity fold —
`cq_theta(q * 0, θ)`, `cq_theta(q - q, θ)`, `cq_theta(q ^ q, θ)` under any
condition (`prd/ir/q28`, `q29`, `q30`) — folds to `0` with no edge reasoning at
all, and is *exactly* faithful (`q*0` is `|0⟩` for every `q`, unentangled).

> **Say the honest version, because the comfortable one is false:** F2 is **not**
> a semantic characterization of "the source meant a fresh rail". Every folded
> arm was, at the source level, a mux between a derived rail and a constant —
> which CQ declines when it can see it. F2 is a fence on the one sub-family where
> the folded constant is **indistinguishable from the condition register
> itself**; the derived-temp accepts are the sub-family where the folded value is
> provably a **different physical wire** from `q`. That distinction is real (it is
> the difference between violating R4 and not) but it is a distinction about
> WIRES, not about what the source "meant", and it is on the owner's desk as
> §14.11 Q3.

#### 14.2d The two stems now read ONE IR construct TWO ways — and why that is sound

After Inc 4, `cq_theta_si32(i32 0, θ)` inside an `if (q == 0)` arm **declines**
(F2), while `cq_phi_si32(i32 0, θ)` in the same position **accepts and
re-anchors onto `q`'s own rail** (`tryEqFoldArm`, measured today as `p08l`). One
construct, two readings. That is sound, and the reason is the stem's physics, not
a preference:

* **Rz.** `tryEqFoldArm` D1–D8 *proves* the equality on the arm edge and
  re-anchors the gate onto the handle `H`. The resulting circuit is
  `cqrt_rz_<W>_controlled(f, H, θ)` — a **diagonal** gate on the condition's own
  register, which §3 permits explicitly (it is why S8 accepts): the strip
  recomputes the predicate over a basis the arm did not move.
* **Ry.** The same re-anchor would put `cqrt_ry_<W>_controlled(f, H, θ)` on the
  condition register, which **R4 forbids** — an Ry relabels the basis, so the
  strip is computed over a register the arm moved and the flag does not return to
  `|0⟩`. There is no correct re-anchor for this stem, so the only two options are
  *accept as a fresh rail* (wrong whenever the source meant `q`) or *decline*.
  F2 declines.

**Pin it with a stem PAIR** so the asymmetry cannot be "tidied up" by someone who
notices the two spellings disagree.

> **⚠ CORRECTED 2026-09-05 (round-1 Rule-13 review, lens L7 finding F-L7-3).**
> The pair this section prescribed — `control_swap_eqfold_diamond.ll` (accept)
> and `control_inplace_ry_reject_stateprep_eqfold_coincidence.ll` "the same IR
> with the stem changed" (decline, on F2) — **IS NOT A PAIR**, and both halves of
> the claim were measured false on HEAD:
>
> | module | Rz spelling | Ry spelling |
> |---|---|---|
> | pred incoming = the live register `%q` (`control_swap_eqfold_diamond.ll`) | **ACCEPT** (`tryEqFoldArm` re-anchors onto `%q`) | **DECLINE** — `control flow`, because that arm has TWO gates; **F1** (`state prep merged with a quantum register`) is reached only after ALSO dropping the second gate ⚠ |
> | pred incoming = the CONSTANT `5` (`..._eqfold_coincidence.ll`) | **DECLINE** `control flow` (the re-anchor moves `Routed` to `%q`, which the constant incoming then does not match) | **DECLINE** on **F2** |
>
> So (i) the two shipped files are DIFFERENT modules, not one module with the stem
> changed — they differ in the merge's pred incoming, which is precisely what lets
> the second reach F2 at all; and (ii) the Ry twin of the *accept* dies at **F1**,
> not F2. **The honest pair is `control_swap_eqfold_diamond.ll` vs its own Ry
> twin WITH THE SECOND ARM GATE DROPPED, and the two fences are `tryEqFoldArm`'s
> accept (Rz) vs F1 (Ry)** — which
> is a better pair anyway, because the F1 string added in this round
> (`state prep merged with a quantum register`) names exactly the physics the
> asymmetry is about. The constant-incoming spelling has NO pair on the Rz side.
> Both fixture headers now say which fence each side dies on, verbatim; the
> physics argument above is unaffected, because it was always about the RE-ANCHOR
> and the re-anchor is what differs.
>
> > **⚠ CORRECTED AGAIN 2026-09-05 (round-2 Rule-13 review, lens R2 finding
> > F-R2-5, DOC-FALSE) — AND THE ERROR CLASS IS F-L7-3's OWN, SURVIVING ONE LEVEL
> > UP INSIDE THE FIX FOR F-L7-3.** The round-1 correction wrote *"its own Ry
> > twin"* and left out that a SECOND edit is needed. MEASURED on HEAD, all five
> > modules compiled through the pass: `control_swap_eqfold_diamond.ll` as shipped
> > ACCEPTS; the same file with `cq_phi` → `cq_theta` — its LITERAL "own Ry twin"
> > — declines **`control flow`**, because the arm carries two gates and the
> > second's arg-0 is the first's result; only with that second gate ALSO dropped
> > does it reach F1. The FIXTURE header stated the parenthetical correctly and
> > the PRD omitted it, so the same claim was true in one document and false in
> > the other. Both now carry it.**

#### 14.2e The if/else clause, and the second customer site

**Owner ruling: if/else with two preps DECLINES ("two rails").** It gets its own
clause and its own string — `if/else state prep allocates two rails` — rather
than riding F1's absence, for two reasons. First, F1 fires by *absence* of a Pred
edge, which is unfindable. Second, and this is the measured one: **R3 would let it
through.** With two arms whose seeds are the same constant, `Routed` is anchored
by the first arm to that `Constant` and the second arm's `RotBase` is the
pointer-identical `Constant`, so `RotBase != Routed` is FALSE and R3 passes. M-β
would then chain the two hoisted gates (`T_f`'s arg-0 := `T_t`'s result) and emit
ONE rail carrying `cRy(f, A)` and `x; cRy(f, B); x`.

> **THAT LOWERING IS PHYSICALLY CORRECT FOR THE SOURCE, AND THE OWNER RULED
> DECLINE ANYWAY.** One rail, prepared once at `|SEED⟩`, rotated by `A` on the
> `f=1` component and by `B` on the `f=0` component, is exactly
> `if (c) r = Ry(SEED, A); else r = Ry(SEED, B);` — the source allocates two rails
> only in a reading where SSA names are wires, and they are not. The observation
> goes on the owner's desk (§14.11 Q4) rather than into the increment.

**From plain C, though, the if/else does not reach `classifyArms` at all — and
this is the scope correction §7's bullet needs.** `clang -O1` (SimplifyCFG) merges
`if (c) r = cq_theta(0, A); else r = cq_theta(0, B);` into **ONE** theta with a
tainted-condition **angle `select`** (probe `p14a`), which lands in
`classifyAngleSelect`, is refused at **S3** (`ArmClassify.cpp:3832-3837`,
`!Taint.Tainted.count(RotBase)` → `NotApplicable`) and declines
**`rotation angle`** — measured. So:

> **Inc 4 has TWO customer sites**, and this increment ships only the first:
> `ArmClassify.cpp:745` (`inPlaceRotationArmTheta`'s classical-seed return) and
> `ArmClassify.cpp:3832` (`classifyAngleSelect` S3). **S3 stays declined**, as a
> recorded follow-on (`drbq.13`), with its shape sketched so the ruling is
> deliberate: the by-difference lowering on a fresh rail would be
> `cqrt_alloc_<W>(SEED); cqrt_ry_<W>(h, B); cqrt_ry_<W>_controlled(f, h, A−B)`,
> and it inherits **every** arithmetic concern §12.3 records — the difference is
> exact only in real arithmetic, `|δ| ≤ ½ ulp(A−B)` is unbounded in absolute
> radians, `fl(A−B)` can be non-finite from two finite arms, and the
> constant-arms-only narrowing (clearance finding F-11) applies verbatim. It also
> inherits the §12.3 fences S1–S10 wholesale, which is a second increment's worth
> of surface. Do not fold it in here.

The two remaining if/else spellings both decline today and keep their strings:
two preps with **different seeds** survives as a real if/else and declines
`impure phase arm` (`p14b`); a prep beside a **chained** arm declines
`impure phase arm` (`p05`). Both are pinned as declines.

> **⚠ AMENDED 2026-09-05 (round-1 Rule-13 review, lens L7 finding F-L7-8, owner
> approved in the fix brief). THE CLAUSE NOW HAS TWO STRINGS, because one of them
> was true of only one shape.** HEAD printed `if/else state prep allocates two
> rails` for `..._ifelse_mixed_chained.ll` and `..._ifelse_mixed_phase.ll`,
> **neither of which has two preps**: there the defect is a MIXTURE — one arm
> mints a rail, the other rotates a live register or applies a phase — and
> nothing allocates twice. The fourth `What` is
> **`if/else state prep beside a chained or phase arm`**, and the clause chooses
> by re-classifying the OTHER arm with the SAME `inPlaceRotationArmTheta`
> predicate it is already inside — never a second spelling of "is that a prep?",
> so the two cannot drift. `..._ifelse_two_preps.ll` and `..._ifelse_diff_seeds.ll`
> keep the two-rails wording, where it is true; `..._ifelse_phase_first.ll` is
> unaffected (it dies earlier, on the pre-existing homogeneity flag).

### 14.3 The decline partition

Every row is a **loud** `DiagnosticInfoUnsupported` with a negative fixture
mirroring the string character-for-character (Rule 12). Message grammar is
`cq controlled lowering: <What> under quantum control` unless another prefix is
shown. **Three new `What` strings**, and nothing else is added:

| new string | owner | why it needs its own words |
|---|---|---|
| `state prep seed does not match the merge incoming` | F1 | the merge is a data mux; `control flow` would hide the one thing the author must change |
| `state prep merged with a quantum register` | F1 (TAINTED incoming) | **added 2026-09-05, round-1 review lens L5 F-L5-1** — see below |
| `state prep seed is proven equal to the condition register` | F2 | names the physics (R4's register), not the syntax |
| `if/else state prep allocates two rails` | §14.2e (two PREP arms) | the owner's ruling, spelled |
| `if/else state prep beside a chained or phase arm` | §14.2e (MIXED arms) | **added 2026-09-05, round-1 review lens L7 F-L7-8** — see §14.2e |

> **⚠ FIVE STRINGS, NOT THREE (2026-09-05, round-1 Rule-13 review). BOTH
> ADDITIONS SPLIT A STRING THAT WAS TRUE OF PART OF ITS OWN CLASS.**
>
> **F1's split (lens L5, F-L5-1).** A TAINTED pred incoming is not a "seed
> mismatch": it is a NO-CLONING MUX between a prepared rail and a LIVE QUANTUM
> REGISTER (Rule 8), and "make the straight-through value the seed" is not the
> author's fix. The single string made the most ordinary R4 program a user writes
> — `for (…) { if (a == 5) a = cq_theta(a, .9); }`, an in-place Ry on the
> CONDITION register — print `state prep seed does not match the merge incoming`
> for a source containing **no state prep and no seed**: both words exist only
> because `-O1` substituted the literal on the proving edge. The verdict was right
> on both binaries and the words described the IR rather than the program. The
> split costs one predicate (`Taint.Tainted.count(incoming)`) and moves exactly
> four fixtures — `..._nonconst_incoming`, `..._prep_then_prep`,
> `..._inloop_carried`, `..._unrolled_k2` — plus two `loop_twin_matrix` rows,
> `m_none_rcond_none_none_none` (DECLINE-BOTH, both halves) and
> `m_ry_rprep_none_none_none` (DECLINE-BOTH-DIFFERENT, ROLLED half only), both
> regenerated from the tool's own `sources()` and MEASURED rather than edited by
> inference. **Rows F1-9, F1-11, L-1 and L-3 below carry the NEW string.**
>
> **§14.2e's split (lens L7, F-L7-8): see §14.2e.**

> ⚠ **`declineArm` re-spells all three** whenever `condWireDisposition` returned
> `ProvenPostRegion` (`ArmClassify.cpp:1655-1662`) — every state-prep probe that
> printed `condition predates a non-diagonal gate` printed it for that reason and
> not for the reason named. **No probe's printed string named
> its real clause** (probe agent's measurement, 3 of 70 masked; my `q25` is a
> fourth). Every fixture below must be written from a MEASURED message on a
> program whose condition wire carries no post-region non-diagonal gate, or must
> be unmasked by changing the wire gate's `cq_theta` to `cq_phi`.

**DECLINE table.** `C` = reachable from plain C (probe id given); `H` = hand IR
only. Fixture family `control_inplace_ry_reject_stateprep_*.ll` unless noted.

| # | shape | src | clause | exact string (`cq controlled lowering: … under quantum control`) | fixture |
|---|---|---|---|---|---|
| F1-1 | seed ≠ pred incoming (`r=7`, `cq_theta(0,θ)`) | C `p04b` | **F1** | `state prep seed does not match the merge incoming` | `..._seed_mismatch.ll` |
| F1-2 | `-0.0` incoming vs `0.0` seed | C `p07b` | F1 | same | `..._negzero_incoming.ll` |
| F1-3 | `-0.0` seed vs `0.0` incoming | C `p07c` | F1 | same | `..._negzero_seed.ll` |
| F1-4 | `undef` pred incoming | **H** | F1 | same | `..._undef_incoming.ll` |
| F1-5 | `poison` pred incoming | **H** | F1 | same | `..._poison_incoming.ll` |
| F1-6 | `ConstantExpr` seed (link-time constant) | **H** | F1 | same | `..._constexpr_seed.ll` |
| F1-7 | global-address seed | **H** | F1 | same | ⚠ **NO SUCH FILE — FOLDED INTO `..._constexpr_seed.ll`, whose header says so (annotated 2026-09-05, round-2 review lens R2 F-R2-4).** The fold is not laziness and a second file would be a FALSE COVERAGE CLAIM: `cq_theta_<sfx>` has no pointer-typed overload, so at every integer width a global's address can reach the seed slot ONLY as a `ptrtoint` `ConstantExpr` — the two rows are literally one `isa<ConstantInt>`/`isa<ConstantFP>` refusal on one IR shape |
| F1-8 | RUNTIME seed (`int r=seed; cq_theta(seed,θ)`) | C `p16` | F1 (`Constant` clause) | same | `..._runtime_seed.ll` — **§14.11 Q2** |
| F1-9 | non-constant incoming (`int r=q; if(q>5)`) | C `q17` | F1 | **`state prep merged with a quantum register`** (2026-09-05) | `..._nonconst_incoming.ll` |
| F1-10 | classical `select` incoming (`cc?0:3`) | C `p21b` | F1 | same | `..._select_incoming.ll` |
| F1-11 | prep then prep on the same `r` (region 2's incoming is region 1's φ) | C `p12c` | F1 | **`state prep merged with a quantum register`** (2026-09-05) | `..._prep_then_prep.ll` |
| **F2-1** | **seed == compare literal, `eq`, arm side** (`r=5; if(q==5) r=θ(5,θ)`) — and this fixture's IR is **BYTE-IDENTICAL** to the R4 program `r=5; if(q==5) r=θ(q,θ)`, which is the point | C `p06a` ≡ `p08e` | **F2 (A1)** | `state prep seed is proven equal to the condition register` | `..._eqfold_coincidence.ll` |
| F2-2 | same on the `ne`/straight-through side (`r=5; if(q!=5) r=θ(5,θ)`) ≡ `int r=q;` | C `p23b` ≡ `p23d` ≡ `q02` | **F2 (A2)** | same | `..._eqfold_coincidence_ne.ll` |
| F2-3 | singleton range `q>4 && q<6` → `icmp eq %q,5` | C `p08c` | F2 | same | ⚠ **NO SUCH FILE — FOLDED INTO `..._eqfold_coincidence.ll` (annotated 2026-09-05, round-2 review lens R2 F-R2-4).** RE-MEASURED: `-O1` collapses the conjunction to `icmp eq i32 %1, 5` with the arm folded to `cq_theta(i32 5, …)`, i.e. `p08c`'s `@slice` body is structurally the coincidence fixture's `@example` body; a committed second file would pin nothing the first does not. The row that is NOT a duplicate — an ORDERED compare whose RANGE pins without any `icmp eq` in sight — is `..._range_ordered.ll`, added by round 1 |
| F2-4 | unsigned `u < 1u` → `icmp eq %q,0` | C `p08g`/`q06` | F2 | same | `..._eqfold_ult.ll` |
| F2-5 | `q <= INT_MIN` / `q >= INT_MAX` → `icmp eq` at the extremum | C `q08`/`q09` | F2 | same | `..._eqfold_extremum.ll` |
| F2-6 | cast launder `(int)(signed char)q` under `q==0` | C `q27` | F2 | same | `..._eqfold_cast.ll` |
| F2-7 | `ne`-else fold (`if(q!=5){} else r=θ(q,θ)`) | C `p08k` | F2 (A1 on the `ne`-false edge) | same | `..._eqfold_ne_else.ll` — **SHIPPED WITHOUT A FIXTURE; added 2026-09-05 (round-1 review, L5 F-L5-3 = L7 F-L7-6). It differs from `..._eqfold_coincidence.ll` in exactly one thing, the merge φ's INCOMING ORDER, which is what pins F1's read-by-block** |
| **F2-8** | **the UNFOLDED twin** `if (q+1==6) r=θ(q,θ)` — compare canonicalized, arm NOT folded | C `p08s` | **R4**, re-spelled by `declineArm`'s `DeferredWireGate` wrapper | ~~`rotation arm on a condition wire`~~ → **`condition predates a non-diagonal gate`** (⚠ **CORRECTED 2026-09-05**, round-2 review lens R2 F-R2-8 — same correction as FP-1, and the fixture already asserted the printed string; a column headed "exact string" holding a designed-but-unprinted one is the drift Rule 12 exists to stop) | `..._unfolded_twin.ll` — the order-sensitivity witness (§14.2b) |
| **F2-9** | **FORWARD, `add`** — `int t = 5+(q&1); if (t!=5) r=θ(t,θ)`; `-O1` peels the `add` off the compare, so the pinned register is a USER of `H` and is ALIVE and MEASURED | C `x01` | **F2 (the forward closure)** | `state prep seed is proven equal to the condition register` | `..._range_forward_add.ll` — ⚠ **ADDED 2026-09-05, round-2 review lens R1 F-R1-1, CONFIRMED-MISCOMPILE** |
| F2-10 | FORWARD, `xor` (`(q&1)^7`) | C `x05` | F2 (forward) | same | `..._range_forward_xor.ll` (2026-09-05) |
| F2-11 | FORWARD, `sub` — the source subtracts and `-O1` canonicalizes to `or disjoint %t, -4` | C `x07` | F2 (forward) | same | `..._range_forward_sub.ll` (2026-09-05) |
| F2-12 | FORWARD, `or` (`(q&1)\|8`) | C `y05` | F2 (forward) | same | `..._range_forward_or.ll` (2026-09-05) |
| F2-13 | **FORWARD, the OTHER direction** — `-O1` rewrites the whole compare onto the ANCESTOR (`icmp ne (lshr q,31),0` → `icmp sgt q,-1`) and the pinned register hangs off it | C `x23` | F2 (forward) | same | `..._range_forward_lshr.ll` (2026-09-05) |
| F2-14 | the signed twin of F2-13 (`q>>31`, seed `-1`) — a different `ConstantRange` operation on the same edge | C `x22` | F2 (forward) | same | `..._range_forward_ashr.ll` (2026-09-05) |
| F2-15 | **literal on the LEFT, ORDERED** (`icmp ugt 1, %t`) — the ONLY row that pins `getSwappedPredicate` | **H** | F2 (range) | same | `..._range_constleft_ugt.ll` — ⚠ **ADDED 2026-09-05, round-2 review lens R1 F-R1-5, WEAK-PIN** (deleting the swap reddened NOTHING before it) |
| F2-16 | literal on the LEFT, EQUALITY (`icmp eq 5, %q`) — pins the position-free `{K,H}` SELECTION, and pins the swap NOT AT ALL (`getSwappedPredicate(eq) == eq`; the header says so) | **H** | F2 (literal) | same | `..._range_constleft_eq.ll` (2026-09-05) |
| IE-1 | if/else, two preps, IDENTICAL seed | **H** | §14.2e | `if/else state prep allocates two rails` | `..._ifelse_two_preps.ll` |
| IE-2 | if/else, two preps, from C | C `p14a` | `classifyAngleSelect` **S3** | `rotation angle` | `control_angle_select_reject_state_prep.ll` (⚠ **filename corrected 2026-09-05**, round-2 review lens R2 F-R2-4 — it was spelled `..._reject_stateprep.ll` here and nowhere on disk) |
| IE-3 | if/else, two preps, DIFFERENT seeds | C `p14b` | homogeneity | `impure phase arm` | `..._ifelse_diff_seeds.ll` |
| IE-4 | prep beside a CHAINED arm | C `p05` | §14.2e (MIXED) | **`if/else state prep beside a chained or phase arm`** (2026-09-05; the implementation measured `if/else state prep allocates two rails`, which was true of no shape in this row) | `..._ifelse_mixed_chained.ll` |
| IE-5 | prep beside a PHASE (`cq_phi`) arm, PREP FIRST | **H** | §14.2e (MIXED) | **`if/else state prep beside a chained or phase arm`** (2026-09-05) | `..._ifelse_mixed_phase.ll` |
| L-1 | in-loop, `r` LOOP-CARRIED (`int r=0;` outside the loop) | C `p18a` | **F1** — the merge's pred incoming is the loop-carried φ, not a `Constant` | **`state prep merged with a quantum register`** (2026-09-05) | `..._inloop_carried.ll` |
| L-2 | in-loop, ITERATION-LOCAL (`int r=0;` inside the body) | C `p18c` | **R7-loop (b)** | `control flow inside a loop body` | `..._inloop_iterlocal.ll` |
| L-3 | the hand-unrolled K=2 twin of L-1 (region 2's incoming is region 1's φ) | C `p18b` | F1 | **`state prep merged with a quantum register`** (2026-09-05; unmask from P1's re-spelling) | `..._unrolled_k2.ll` |
| R1-1 | stray op beside the theta in the arm | C `p08u` | R1 | `control flow` | `..._stray_op.ll` |
| R1-2 | fan-out of `T` (a second consumer) | **H** | R1 | `control flow` | `..._fanout.ll` |
| R1-3 | two thetas in one arm | **H** | R1 | `control flow` | `..._two_gates.ll` |
| R1-4 | theta + `cq_phi` in one arm | **H** | R1 | `control flow` | `..._theta_phi_arm.ll` |
| R2 | tainted angle | **H** | R2 | `rotation angle` | `..._tainted_angle.ll` |
| R7-1 | `ShareCondFlag` region | **H** | R7 ziov | `rotation arm shares the condition flag` | `..._sharecond.ll` |
| **RD-1** | `t = q & 1` under `if (t)` — the RANGE-pinned `ne` edge | C `k08` | **F2 (RANGE, A3)** | `state prep seed is proven equal to the condition register` | `..._range_mask1.ll` — **ACCEPTED at hand-back; a CONFIRMED silent miscompile (round-1 review, lens L2 F-L2-1)** |
| **RD-2** | `int r = q&1; if (!(q&1)) r = θ(1,·)` — the A2 side of the same | C `k06` | F2 (RANGE) | same | `..._range_a2_alias.ll` — same finding, F-L2-2 |
| **RD-3** | ORDERED compare pinning at a mask's top (`and q,3` / `sgt 2` / seed 3) | **H** | F2 (RANGE, no `isEquality` gate) | same | `..._range_ordered.ll`, with the one-token ACCEPT twin `..._stateprep_range_ordered_seed0.ll` (seed 0) |
| **RD-4** | a `zext` producer, which `computeConstantRange` alone cannot see | **H** | F2 (RANGE, known-bits half) | same | `..._range_knownbits.ll` — the only file whose red-green is the known-bits intersection |
| **RD-5** | `i1` condition + `i1` seed — BOTH edges pin at `i1` | **H** | F2 (RANGE) | same | `..._range_i1_both_edges.ll` — **this module was the shipped `..._stateprep_i1.ll` ACCEPT fixture, verbatim**. ⚠ **WIDENED 2026-09-05 (round 3, F-R3-8): it is no longer "at `i1`" — the BRANCH CONDITION is a tainted `i1` pinned on both of its own edges whatever width the compare is at, so EVERY `i1` seed collides and the `i1` state-prep width is OUT (`..._reject_stateprep_i1_{arm_flag,flag_pinned}.ll`)** |
| **RD-6** | UNRECOGNIZED theta suffix (`@cq_theta_si32x`) | **H** | **F1 clause 3** | `state prep seed does not match the merge incoming` | `..._unrecognized_suffix.ll`, with the one-token ACCEPT twin `..._stateprep_suffix_control.ll` (§14.4's retraction) |
| **RD-7** | `undef` in BOTH slots (seed AND incoming) | **H** | F1 clause 1 | same | `..._undef_seed.ll` — the shipped `_undef_incoming` pins clause 2, not clause 1 (lens L1 F-L1-2) |
| **RD-8** | `poison` in BOTH slots | **H** | F1 clause 1 | same | `..._poison_seed.ll` |
| R7-2 | depth-2 nest | **H** (`p19a` flattens to a compound cond from C) | `RegionTreeDetect` | ~~`nested control flow`~~ → **`impure phase arm`** (CORRECTED 2026-09-05, round-1 review lens L7 F-L7-7: MEASURED on HEAD and on the pre-Inc-4 oracle; the outer region's arm block holds the inner branch, so `armBlockIsPureSpine` adjudicates before `RegionTreeDetect` is ever consulted) | `..._nested.ll` |
| R7-3 | tainted `switch` | **H** (`p19b` becomes an angle mux from C) | `SwitchClassify` | existing | `..._switch.ll` |
| W-1 | unsupported controlled-rotation width (i128) | **H** | detection width gate | `controlled rotation width` | ⚠ **NO SUCH FILE, AND NONE CAN BE WRITTEN (annotated 2026-09-05, round-2 review lens R2 F-R2-4; the ground is round-1 lens L4 F-L4-5).** The 16 recognized `cq_theta_` suffixes are a SUBSET of the 9 controlled-rotation widths, so `abiWidthHasControlledRotation` cannot answer no for any module that reaches this gate; an `i128` theta is refused earlier, by F1's third clause, for having no recognized suffix at all. §14.9 already excludes this row from the fixture arithmetic |
| P1-1 | condition wire gains a NOT-provably-post-region non-diagonal gate | **H** | `condWireDisposition` → `DeclineNow` | `condition predates a non-diagonal gate` | `..._stalecond.ll` |
| FP-1 | `fcmp oeq` condition, arm rotates the fp condition register (`if (q == 0.0) r = cq_theta(q, θ)`) — **measured NOT to fold**, so it is R4's, not F2's | C `q32`/`q34` | R4 | ~~`rotation arm on a condition wire`~~ → **`condition predates a non-diagonal gate`** (⚠ **CORRECTED 2026-09-05**, round-2 review lens R2 F-R2-8: this column is headed "exact string" and held a string HEAD does not print. The clause really is R4 — control: the same diamond with the arm's arg-0 on a DISJOINT tainted register accepts and emits two `cqrt_ry_i32_controlled` — but `declineArm`'s `DeferredWireGate` wrapper re-spells it, and there is no unmasking move for THIS row because the masking gate is the arm itself, §14.2b) | `..._fcmp_oeq_unfolded.ll` |
| C-1 | compound `&&`/`\|\|` condition | C `p15d`/`p15e` | `!isa<CmpInst>(Region.Condition)` | `control flow` | `..._compound_cond.ll` |
| RZ-1 | `cq_phi(CONST, θ)` in the arm (the Rz "state prep" that does not exist) | C `p10` | Rule 3 / phase path | `control flow` | `..._rz_prep.ll` |

**ACCEPT list** (family `control_inplace_ry_stateprep_*.ll`), every one measured
as declining at HEAD, so every one is a red-green flip:

| # | shape | src | why it is in the list |
|---|---|---|---|
| A-1 | the flagship diamond, seed 0, `k=5` | `p01` | the target shape |
| A-2 | `!=` polarity (`cqrt_x` bracket, arm is the FALSE successor) | `p02` | Rule 9 |
| A-3 | non-zero seed, `k ≠ seed` | `p06b` | the seed is not privileged |
| A-4 | if/else collapsed to a diamond by `-O1` (`else r = 0;`) | `p03` | the C spelling users write |
| A-5..A-8 | i8 / i16 / i64 / i1 | `p17a`–`p17d` | width axis |
| A-9 | **f64** seed `0.0` | `p07a` | the merge φ is `double` and is a REGISTER, not an angle — `isFPOrFPVectorTy` decline sits on the VALUE-arm path only (`ArmClassify.cpp:2699`), and `prd/ir/t04` proves the analogous chained f64 region accepts and runs today |
| A-10 | derived condition `(q&6)==2` | `p15a` | measured NOT to fold (`p08r`) |
| A-11 | ordered condition `q > 5` | `p15b` | no equality ⇒ F2 vacuous |
| A-12 | Q+Q condition `q == p` | `p15c` | F2 needs a `ConstantInt` operand; a Q+Q compare has none |
| A-13..A-19 | consumers: `cq_measure` / `ret` / dtzb `r+1` / `printf` (7.6 tape) / chained theta after / no consumer / classical join φ then lift | `p13a`–`p13g` | the consumer axis is orthogonal; `p13f`'s helper must NOT measure (it declines `cq specialization: callee measures under quantum lift`, an unrelated fence) |
| A-20 | two independent regions, two preps on two registers | `p12a` | |
| A-21 | sequential: prep then CHAINED on the same `r` | `p12b` | region 2's base is region 1's merge, which M-β RAUWs to `T`; `RoutedBase` is a `WeakTrackingVH` and follows |
| A-22 | prep then an UNCONDITIONAL theta on `r` | `p12d` | |
| A-23 | P1: post-region `cq_theta` on the CONDITION register | `p22` | §14.5's P1 paragraph — §13.4b's argument holds verbatim |
| A-24 | the DERIVED-TEMP fold residual (`cq_theta(q-5,θ)` under `q==5`) | `p08b` | §14.2c, documented accept |
| A-25 | the UNCONDITIONAL identity fold (`q*0`, `q-q`, `q^q`) | `q28`–`q30` | exactly faithful; shows F2 is not over-broad |
| A-26 | **the seed literal has OTHER USERS in the same function** | `q31` | the §14.5 vacuity pin — this fixture reddens if R4/R6 are pointed at the Constant |
| **A-31** | **literal on the LEFT whose swapped relation pins NOTHING** (`icmp ugt 6, %t` over `and %q,6`, seed `0`) | **H** | the ACCEPT CONTROL for F2-15 — it keeps `getSwappedPredicate` a DISCRIMINATOR rather than a blanket over-decline. `..._stateprep_range_constleft_accept.ll`, ⚠ added 2026-09-05 (round-2 review lens R1 F-R1-5) |
| **A-27** | a LATER region whose CONDITION is read from the PREPPED rail (`if (r == 1) q = cq_theta(q,.2);`) | L3 `l48` | **ADDED 2026-09-05 (round-1 review, lens L3 F-1)** — the FIRST shape putting a freshly-minted, condition-entangled rail into another region's flag-mint slot. Sound because the mint is a basis-DIAGONAL read and region 2's arm never moves the prepped rail, so the strip recomputes over an unmoved register. `..._stateprep_feeds_later_cond.ll` |
| **A-28** | a SECOND state prep gated on the first one's rail (`int s = 0; if (r == 1) s = cq_theta(0,.4);`) | L3 `l49` | same finding; both Inc-4 mechanisms (hoisted alloc + freeze) on a rail whose control came from another controlled gate. NOT `..._prep_then_prep.ll`, which writes the SAME register and declines on F1. `..._stateprep_feeds_later_cond_prep.ll` |
| **A-29** | a FLAT prep followed by a classically-bounded loop that rotates the prepped register — **it ROLLS** | L6 `L2` | **ADDED 2026-09-05 (round-1 review, lens L6 F-3)** — `railPhiRootMint` claims a CONTROLLED mint because the flat `T` dominates the header; hand-unrolled K=3 twin byte-identical. CONTEXT-DEPENDENT (see §14.5's correction). `..._stateprep_then_rolled_loop.ll` |
| **A-30** | M-A still WARNS over a live derived record on a state-prep-rooted rail | L4 `L4_mA_prep_root` | **ADDED 2026-09-05 (round-1 review, lens L4 F-L4-3)** — the complementary direction M6 could not establish. `..._stateprep_warn_live_record.ll` |
| **A-31** | a CROSS-TYPE seed (`long long r = 5; if (q==5) r = cq_theta((long long)q,.9);`) | L1 `n02` | **ADDED 2026-09-05 (round-1 review, lenses L1 F-L1-3 / L6 F-L6-1 / L7 F-L7-5)** — pins F2's same-type gate as the SEMANTIC cross-width discriminator, not an `APInt` precondition. `..._stateprep_cond_cast_seed.ll` |
| **A-32** | the SAME-WIDTH cross-type seed (a `float` whose 32 bits are the compare literal, from a `union`/`memcpy`) | measured 2026-09-05 | the decisive case for A-31's rationale: the unfolded twin lowers to `cq_template_bitcast_i32_to_f32` — a FRESH handle — so no bit-pattern clause is owed. `..._stateprep_cond_bitcast_seed.ll` |

Counts: **26 accepts / 37 declines = 63 fixtures**, of which 13 declines and 0
accepts are hand-IR-only. (`control_angle_select_reject_state_prep.ll` sits
outside the family name, as the Inc-2b clearance's fourth decline did.)

### 14.4 The mechanism: what actually changes in the three files

**`ArmClassify.cpp` — `inPlaceRotationArmTheta` (`:721-752`, re-measured 2026-09-05) and the rotation
clause (`:1641-1975`).** The classical-seed `return nullptr` at `:725` becomes an
accept path carrying a `StatePrep` flag; R1's other three halves (defined in
`ArmBB`, sole user is the merge φ, nothing else in the block) are **unchanged and
still required**. Then, in the clause:

* the check at `:1690-1693` — `if (!Taint.Tainted.count(RotBase)) declineArm(…,
  "control flow")`, today commented **"STRUCTURALLY UNREACHABLE, kept as defence
  in depth"** — **BECOMES REACHABLE AND IS THE FIRST THING THAT FIRES.** It must
  be re-scoped, not deleted: for a state prep it becomes F1's `isa<Constant>`
  test, and for a chained arm it keeps its current meaning and its current
  comment. Deleting it silently is how a decline turns into a fall-through to a
  controlled rotation on an untainted value.
* R3 (`RotBase != Routed`, `:1678-1681`) keeps its string and its meaning, and
  **F1 is asked separately and first**, so the message names the seed rather than
  "control flow".
* R4 and R6 are **skipped entirely** for a state prep (§14.5) — not passed an
  empty set, *skipped*, with a comment saying why.
* R7's flat half is unchanged; R7's loop half (b)/(b′) is unchanged and refuses
  both in-loop spellings (§14.3 L-1/L-2).
* `Region.setRoutedBase(RotBase)` still records the `Constant`, because the
  emitter re-validates against it (below) and a `WeakTrackingVH` on a `Constant`
  is stable (constants are never erased).

**`SwapRouteEmit.cpp` — `emitInPlaceRotationRegion` (`:531-780`).** Three things,
and only three:

* the identity re-validation `T->getArgOperand(0) != Base` (`:588-592`) is
  **already correct** for a state prep — both are the same uniqued `Constant` —
  and must keep its comment updated to say that it is now *also* a seed check by
  representation, with the real seed check being F1 in the classifier.
* **M-β is REQUIRED, not an optimization.** `MergePhi->replaceAllUsesWith(
  Gates.back().first)` (`:774`) RAUWs the merge to the hoisted theta, which
  `lowerRotations` then RAUWs to the fresh alloc handle. **The Rz stem's M-α
  (RAUW to `Base`) would RAUW the merge to the CONSTANT SEED** and every consumer
  of `r` would become a classical `i32 0` — a silently classical program.
  Since the Ry stem already does M-β for every `InPlaceRotation` arm, **state prep
  rides it unchanged**; the site comment must say that for this arm class M-β is
  a correctness requirement and not the loop-bookkeeping convenience it is for
  Inc 3.
* nothing else. No new emission, no CFG surgery, no new symbol.

**`RotationLowering.cpp` — the theta loop (`:239-343`).** The `!Chained` +
`Ctrl` bail at `:296-299` (`cq rotation lowering: unsupported controlled theta
operand`) becomes the accept path: mint `cqrt_ry_<W>_controlled(f, Handle, θ)`
where `Handle` is the alloc.

> **⚠ AND THE ORDER IN THAT FUNCTION IS A DEFECT TODAY THAT INC 4 MUST FIX RATHER
> THAN INHERIT.** The `!Chained` arm at `:260-276` emits `cqrt_alloc_<W>(Op)`,
> inserts `H` into `taint.Tainted`, consumes a `BirthOrder` slot and writes
> `HandleWidth[H]` — **and only then** does `:284-299` look up
> `ControlledRotations` and bail. So the existing "controlled theta operand"
> decline is a **mid-emission bail**: on `continue` the module keeps a
> `cqrt_alloc` with zero users, a still-standing `@cq_theta_*`, and three live
> side-table entries keyed on the orphan. It is survivable only because
> `DS_Error` exits `opt` non-zero — exactly the shape `SwapRouteEmit.cpp:1072`
> describes moving *out* of `emitRegion`. Inc 4 removes the bail, so the residue
> goes away for the accept; the sibling bail two lines below
> (`controlled theta suffix/width`, `:303-306`) is left in the same position and
> **must be hoisted above the alloc** in the same edit. Rule 1: never emit half.

> **A second, pre-existing hazard in the same block, recorded because F1 is the
> natural place to close it.** The alloc symbol's width comes from the CALLEE
> NAME (`Abi = wd.abiWidthFor(suffixFromName(Theta, "cq_theta_"))`, `:241`) while
> the argument is `Op`'s actual LLVM type, and the two are never cross-checked
> (`HandleWidth[H] = abiWidthFromType(Op->getType())` at `:275` is the *other*
> derivation). A hand-written `cq_theta_f64` with an `fp128` arg-0 mints
> `@cqrt_alloc_f64(double)` with an `fp128` argument — ill-typed IR. **F1 should
> carry the third clause: the seed's type must equal `typeForAbiWidth(Abi)`** —
> one line, hand-IR-only reachability, and it is free while F1 is being written.

> ~~**CORRECTED 2026-09-05 (implementation): the clause SHIPPED and is
> STRUCTURALLY UNREACHABLE, not "hand-IR-only reachable".**~~ **RETRACTED
> 2026-09-05 (round-1 Rule-13 review, lens L1 finding F-L1-1). THE PRD'S
> ORIGINAL WORDING — "one line, HAND-IR-ONLY REACHABILITY" — WAS RIGHT, the
> implementation note that overwrote it was wrong in both its verdict and its
> mechanism, and the clause is LOAD-BEARING rather than defence in depth.**
>
> * **The mechanism was wrong.** "The LLVM verifier then forces the call's
>   argument to match its parameter type" is FALSE: LLVM 19 parses and verifies a
>   call whose `FunctionType` differs from its callee's (measured,
>   `opt -passes=verify` exit 0). What blocks THAT route is
>   `CallBase::getCalledFunction()`, which returns **null** in exactly that case,
>   so `isThetaCall` is false and the pass never sees a theta at all.
> * **The reachable route is an UNRECOGNIZED SUFFIX**, and it is the
>   sibling-spelling shape this file keeps finding: `isThetaCall` is a bare
>   NAME-PREFIX test (`starts_with("cq_theta_")`) while `resolveSources` — and
>   therefore `declMatchesPrototype` — only ever visits `wd.allSuffixes()`, whose
>   own comment says an unrecognized suffix "stays out of collection — and
>   validation — entirely". So `@cq_theta_si32x(i32 0, double)` IS a theta to the
>   classifier and has NO width: `abiWidthFor("si32x")` is `""` and
>   `llvmWidthType("")` is null, so the clause fires on its `!SeedTy` half.
> * **It is load-bearing.** `taint.ThetaCalls` is populated only from `ThetaFns`,
>   so an unrecognized-suffix theta is NEVER LOWERED. Without the clause that
>   module ACCEPTS (R3 passes by uniqued-constant identity, the `!StatePrep` taint
>   check is skipped, R4/R6 are skipped, and the detection width gate asks the
>   OTHER derivation `abiWidthFromType`, which answers `i32`), the emitter hoists
>   and flattens, and the module keeps a STANDING `@cq_theta_si32x` inside a
>   flattened region wrapped in a flag mint/strip/free around nothing.
>
> **A FIXTURE CAN BE WRITTEN AND NOW IS:**
> `control_inplace_ry_reject_stateprep_unrecognized_suffix.ll`, with the
> ONE-TOKEN accept twin `control_inplace_ry_stateprep_suffix_control.ll`
> (`si32x` → `si32`, nothing else changed). The `declMatchesPrototype` fact above
> is still true and still closes the `fp128` route; it simply never gets asked
> about an unrecognized name.
>
> **AND THE FOUR WIDTH FIXTURES DO NOT PIN THIS CLAUSE** (round-1 review, lens L4
> finding F-L4-2): `control_inplace_ry_stateprep_{i1,i8,i16,i64}.ll` all claimed
> to, and deleting the clause outright leaves all four GREEN — on every input they
> present, the seed's type already equals the name-derived width's type, so the
> clause is a no-op there. Their headers now say what they DO pin (the
> name-derived alloc/gate symbol and the alloc's position, at that width) and
> point here.

### 14.5 R3 / R4 / R6 / R7 on a `Constant` base — vacuous, reachable, and one trap

**R4 and R6 are VACUOUS for a state prep, and the reason is structural rather
than a proof about the program:** the rotated rail is minted by the hoisted `T`
itself, so **no pre-region SSA name for it exists**. There is no wire to
intersect with the condition's (R4) and no record that could be read after the
region (R6). Every SSA name for the rail after the region is `T`'s result
(RAUW'd to the alloc handle), which is the POST-gate name by construction. The
Inc-1 finding-K launder (a classical join φ over the register, RAUW'd to the base
by `liftOneRegisterMergePhi`) cannot reach a name that does not exist before the
region.

> **⚠ THE TRAP, AND IT IS MEASURED, NOT HYPOTHETICAL: DO NOT HAND THE `Constant`
> TO `railWireClosure`.** `railWireClosure` does `Out.insert(W)` **before** its
> taint gate (`ArmClassify.cpp:455-462`), so
> `railWireClosure(ConstantInt 0, BothWays, …)` returns `BaseWire =
> BaseWireOrder = { i32 0 }`. R6 then iterates `ConstantInt::get(i32, 0)->users()`
> — and **an LLVM `ConstantInt` is uniqued per `LLVMContext`, so its use list
> spans the whole module.** Measured (`prd/ir/q31`): in
> `int r=0; if(q==5) r=cq_theta(0,.9); int u=cq_theta(0,.7);` the literal `i32 0`
> has THREE users inside `@slice` — `T`, the merge φ, **and the second theta,
> which is after the region**. R6 would fail `provablyBefore` on it and decline
> `stale rail record read past a controlled Ry` on a program with no record at
> all. Users in OTHER functions (`ret i32 0` in `@main`) are skipped only because
> `DT->isReachableFromEntry` returns false for a block not in this function's
> tree — i.e. by accident of a guard written for a different purpose. R4 has the
> mirror hazard in the harmless direction: a degenerate `cq_phi(0, θ)` on the
> condition's provenance can put a `Constant` into `CondRails` (the closure's own
> comment says so at `:466-471`), so R4 would decline on a literal coincidence.
> **Skip both clauses; do not "pass an empty closure".** `q31` is the fixture
> that reddens if anyone re-points them.

**R3 is kept and is NOT the seed fence** — §14.2a item 1.

**R7-loop is unchanged and refuses both in-loop spellings, for two different
reasons, and they must both be pinned** (§14.3 L-1/L-2): the **loop-carried**
spelling (`int r = 0;` outside the loop) has the loop's header φ as the merge's
pred incoming, so it is a genuine data mux and **F1** kills it before R7 is
consulted (probe `p18a` — worth stating, because "in-loop state prep" sounds like
one thing and is two); the **iteration-local** spelling (`int r = 0;` inside the
body) is the real Inc-4 shape and dies at **R7-loop (b)**, because `BaseWire` is
skipped (above) so no member is a header φ. Even if (b) were satisfied, (b′) —
`railPhiRootMint`, `LoopLowering.cpp:319-345` — requires the header φ's EXTERNAL
incoming to peel to a **classical-arg-0 `cq_theta` mint** dominating the header;
the external incoming here is the `Constant` seed, `peelInPlaceBase` returns it
unchanged, `dyn_cast<CallInst>` is null, so (b′) returns null too.

> **What would have to be true for a future in-loop lift, as a deferred item and
> NOT a design.** `railPhiRootMint`'s mint vocabulary is *exactly* "a
> classical-arg-0 `cq_theta` in `GateCalls` dominating the header" — which is
> **precisely what a hoisted state-prep `T` is**. For a region INSIDE the loop the
> obstruction is positional: the hoisted `T` sits inside the body, so
> `DT.dominates(Mint, L->getHeader())` fails and the rail is re-minted every trip.
>
> > **⚠ CORRECTED 2026-09-05 (round-1 Rule-13 review, lens L6 finding F-3): THAT
> > IS TRUE ONLY WHEN THE REGION IS IN THE LOOP, AND `railPhiRootMint` CLAIMS A
> > CONTROLLED STATE-PREP MINT **TODAY**, AT HEAD, WITH R7 INTACT.** For a FLAT
> > prep followed by a classically-bounded loop that rotates the prepped register,
> > `T` DOMINATES the header, `railPhiRootMint` succeeds with a `Mint` that is a
> > CONTROLLED rotation — a shape that did not exist before Inc 4 —
> > `collapseFlattenedLoopRails` claims the rail φ, and the body ROLLS. MEASURED
> > (probe `L2`): HEAD rc=0, pre-Inc-4 oracle rc=1; the hand-unrolled K=3 twin
> > links and runs to a BYTE-IDENTICAL 24-line trace; strict stage 2b 0 violations
> > / 0 unproven. **No defect on this witness**, but it shipped with no fixture, no
> > slice, no golden and no matrix cell, and the row above predicted it could not
> > happen. Now pinned by
> > `control_inplace_ry_stateprep_then_rolled_loop.ll`.
> >
> > **AND IT IS CONTEXT-DEPENDENT, which is a PRE-EXISTING `LoopLowering` fact and
> > not an Inc-4 one:** `collapseFlattenedLoopRails` runs only when
> > `taint.InLoopFlattenedPreds` is non-empty, so removing the unrelated in-loop
> > region from that probe makes the identical prepped-rail loop DECLINE
> > (`cq taint escape: tainted value muxed by a classical-condition phi`, on BOTH
> > binaries). The disposition of a prepped rail's loop therefore depends on
> > whether some OTHER register has a region inside that loop. Recorded, not
> > fixed. A rolled in-loop state prep would
> therefore need the alloc hoisted out of the loop (a real transformation, with
> its own per-activation reset question: the second trip's `f=0` component would
> read a rail the first trip may have rotated) — a different capability, not a
> fence relaxation. File it; do not sketch it further here.

**P1 / `DeferredWireGate` — §13.4b's argument holds VERBATIM for a state prep,
and it is the one place this increment is strictly safer than Inc 3.** §13.4b
widened P1 to `(SawValueArm || !(SawPhaseArm || SawRotationArm))` on the ground
that an in-place rotation arm copies nothing, replays nothing and allocates no
work rail, so its **entire emitted stream** — `mint(f) ; [x(f)] cRy [x(f)] ;
strip(f) ; free(f)` — lands before `BI`, and `ProvenPostRegion` (`provablyBefore(
BI, G)`) therefore carries to every call in it. A state prep is that same stream
**plus one `cqrt_alloc_<W>(SEED)`**, which is also inserted before `BI` (at the
hoisted theta, §14.1) and which touches a rail nothing else names. The
`SawRotationArm` flag is set by the same clause, so P1 needs **no edit**.
The residual §13.4b records — a DERIVED condition leaves template rails
entangled with `C`, live past the strip, which a later Ry on `C` dephases — is a
property of the CONDITION's chain and is unchanged here. And Inc 4 is strictly
safer on R4's half: §13.4b needed R4 to have proved `R`'s wire disjoint from
`C`'s; here that disjointness is **structural** (the rail is minted inside the
region), so the argument does not depend on a fence at all. Measured: `p22`
(`prep; q = cq_theta(q, .3);`) declines today at P1's string on both binaries and
must ACCEPT after Inc 4 — it is accept fixture A-23, and its `cq_phi` twin
(`p22b`, which declines `control flow`) is what unmasks the string.

### 14.6 The set / walker audit — "what OTHER set is computed over the same closure"

The mandatory table. Pipeline positions are `CQLoweringPass::run`'s stage lines.
**READ** = the body was read for this PRD; **MEASURED** = a probe established it.

| reader (pipeline order) | what it decides | verdict for a controlled STATE PREP | how established |
|---|---|---|---|
| `inPlaceRotationArmTheta` (`ArmClassify.cpp:721`), callers `:1833` (the rotation clause) and `:1925` (⚠ **CORRECTED 2026-09-05, round-2 review lens R2 F-R2-6:** the row said "sole caller `:1641`", which was the wrong line AND the wrong count — `:1641` is `tryEqFoldArm`, and the SECOND caller is the §14.2e other-arm re-classification ADDED BY ROUND 1, i.e. this audit row went false about its own subject in the same round that refreshed it. The second caller is benign — it IS the "never a second spelling" discipline, commented as such at its site — but a row whose job is to answer *"what OTHER set is computed over the same closure"* must not be stale about its own callers. Line numbers re-measured 2026-09-05 after the round-2 forward-closure insertion) | is the arm one in-place theta? | **THE CHANGE.** Its `!Tainted(arg0)` return becomes the state-prep path; its other three halves unchanged | READ |
| R3's `Routed` / `Region.setRoutedBase` | the routed handle | now a `Constant`; the `WeakTrackingVH` is stable (constants are never erased) and the emitter's identity re-check still matches | READ |
| `emitInPlaceRotationRegion`'s `T->getArgOperand(0) != Base` (`:588`) | plan-vs-IR agreement | passes by uniqued-constant pointer identity — **correct, and now documented as also being a seed check** | READ |
| **`railWireClosure` → R4 / R6** | wire disjointness, stale records | **MUST BE SKIPPED** — see §14.5's trap | READ + **MEASURED** (`q31`) |
| `condProvenance` / `condWireDisposition` P4/P5 | condition-wire exposure | unchanged. P5's positional scan requires `Taint.Tainted.count(CI->getArgOperand(0))` (`ArmClassify.cpp:1275-1276`, re-measured 2026-09-05), and a state-prep theta's arg-0 is a `Constant` — so a HOISTED state-prep theta between some later region's compare and branch is **invisible** to P5, which is correct (it mints a wire, it stales none) | READ |
| `WireWalk::findNonDiagonalWireGate` (`:474-478`) / `collectWireValues` (`:106-110`) | is there a non-diagonal gate on this wire? | unchanged: both require `CI->getArgOperand(0) == V`, and a `Constant` arg-0 is on no wire. ⚠ `thetaOnPathToImpl`'s **wire-blind** mode (`Wire == nullptr`, `:147-151`) counts ANY `cq_theta_`, state prep included — it is documented as a cheap necessary condition and "never the answer", so this is a pre-filter widening only | READ |
| `WireWalk::phiTracksWire` | in-loop refresh | unreachable — the in-loop shape declines (§14.5) | READ |
| `declineStaleRecordOps` (stage 282) | pure op past a wire gate | unchanged — it runs BEFORE detection and sees the un-hoisted theta with a `Constant` arg-0, on no wire | READ |
| `ControlledRotations` — **THREE writers** (`SwapRouteEmit.cpp:675` the Inc-1/Inc-4 Ry arm, `SwapRouteEmit.cpp:1122` the Inc-2a Rz peephole, `AngleSelectEmit.cpp:325` the Inc-2b by-difference gate at **either** stem); reads `RotationLowering.cpp:258`/`:412`, `ArmClassify.cpp:3873`, `AngleSelectEmit.cpp:183`, `LoopLowering.cpp:469`, `TaintPropagation.cpp:959` (line numbers re-measured 2026-09-05, round-1 review lens L4 F-L4-4 — the shipped row named ONE writer and six drifted line numbers) | which gate fires under which flag | one more entry, same shape. `LoopLowering.cpp:469`'s reader additionally requires `cq_phi_` so a `cq_theta` entry cannot reach it — **but an Inc-2b Rz angle-select entry DOES**, under an argument written for a different emitter; `ArmClassify.cpp:3873` / `AngleSelectEmit.cpp:183` are the double-owner guards and are strengthened, not weakened, by the extra entry | READ |
| `TaintPropagation::resolveWireBase` (`:919`, sole caller `liftOneRegisterMergePhi`) | which RECORD does this name denote? | unchanged, **twice over**: the `ControlledRotations` stop (`:959`) fires, and the pre-existing `if (!taint.Tainted.count(Handle)) break; // classical-operand theta: the mint point IS the base` (`:962-963`) would fire anyway | READ |
| `liftOneRegisterMergePhi` / `repropagateControlMerges` (stage 356) | classical join φs | unchanged — `T` is a `CallInst`, never a lift candidate; as an INCOMING it resolves to itself | READ |
| `declineClassicalMuxes` (stage 399) | live φ/select over tainted data | the region's φ is erased by the emitter; no other φ is created | READ |
| `declineLiftedStaleRecordOps` (stage 409) | post-lift stale records | no lift is produced | READ |
| Phase-6 `specialize` (stage 418) | clone-on-taint arguments | keys on `taint.Tainted` per argument; the fresh handle is tainted | READ |
| `lowerRotations` `!Chained` arm (`:260-276`) | the alloc mint, `Tainted`, `BirthOrder`, `HandleWidth` | **all at the HOISTED position now** — after the flag mint, inside a negated arm's `cqrt_x` bracket. `HandleWidth[H] = abiWidthFromType(Op->getType())` reads the SEED's type, which is what a later Q+Q control condition wants | READ |
| **`UserSourceRotations`** (write `RotationLowering.cpp:334`) | which set the minted gate joins | **THE SET CHANGES.** `(Chained ? UserChainedRotations : UserSourceRotations)` puts the controlled state-prep gate in `UserSourceRotations`, not `UserChainedRotations`. Verdict per reader below | READ |
| ↳ `isRecordedUserRotation` (`:695`), sole caller `isTeardownUse` (`:755`) | user gate vs spine adjoint | **CORRECT**: the gate IS recorded, so it is not teardown — same answer as for a chained gate. ⚠ And it is **behaviour-neutral today**: `reachesObservingSink` `continue`s on `cqrt_ry_`/`cqrt_rz_` two lines below the `isTeardownUse` call (`:1277` and `:1281`), so recorded and unrecorded reach the same `continue`. Stated so nobody quotes this row as a live protection | READ |
| ↳ `warnLiveRecordRotations` (`:1465`) | M-A's live-record warning | **DOES NOT RUN on a state-prep gate**, because the guard keys on `UserChainedRotations` only (`:1466`, `:1481`). **SOUND, and for the reason the set's own comment gives** (`TaintPropagation.h:433-435`): *"a source theta mints its wire, so that wire can carry no record yet"* — which is literally true here, the rail is allocated three instructions earlier. This is a real argument, not an accident, and it is why the set choice needs no change | READ |
| ↳ `warnLiveRecordRotations`'s arg-slot decode (`:1492-1508`) | which arg is the wire | already handles the 3-arity `_controlled` spelling (arg 1). Unreached for this class, but unchanged | READ |
| `ChainWalk::isInPlaceGateOn` (`:218-220`) / `railCarriesControlledRotation` (`:305`) | THE FREEZE | **fires, structurally**: the alloc handle's first user is the `cqrt_ry_<W>_controlled` naming it at arg 1. Same predicate, same slot, no new site | READ + **MEASURED** in the twin (`prd/ir/t01`: the rotated rail is never freed) |
| `DagTraversal.cpp:100` / `:229`, `Uncomputation.cpp:1358` / `:1565` | the freeze cuts | unchanged — both ask `railCarriesControlledRotation` | READ |
| `FreePoint` | where to free | never reached for the frozen rail | READ |
| `EmitInverse` (`:209-217`) | the controlled adjoint | stays **unreachable** for this class, by the freeze — the Inc-1 finding-F claim, inherited | READ |
| `lowerIOSinks` lineage walk (stage 365) | tape sinks | keys on call-site name + `taint.Tainted` of the operand; the prepped handle is tainted. **Same disposition as Inc 3's F-L5-2** (a tape write after the region accepts; terminality is the live guard) | READ |
| `LoopLowering` `railPhiRootMint` / `peelInPlaceBase` / `collectRailGates` (stages 310, 340) | the rail chain, the MINT vocabulary | **a classical-arg-0 `cq_theta` IS their mint vocabulary** (`LoopLowering.cpp:339-341`), so a hoisted state-prep `T` is a mint to them — which is exactly why the IN-LOOP shape must decline at R7 (§14.5). ⚠ **CORRECTED 2026-09-05 (round-1 review, lens L6 F-3): for a FLAT prep followed by a loop, `T` DOMINATES the header and this set CLAIMS IT TODAY — the loop ROLLS, twin byte-identical, pinned by `..._stateprep_then_rolled_loop.ll`.** Not "would claim it if R7 were lifted" | READ + **MEASURED** |
| `free_pairing_check.py` `classify()` | Rule-6 pairing (e2e stage 2b) | **`cqrt_alloc_<W>` is classified by SYMBOL NAME ONLY — the seed argument is never read**, at any site in the file. So a non-zero seed is invisible to 2b, and the frozen rail lands in the "left allocated" census with **no finding**. Both facts must be quoted with the goldens rather than claiming 2b witnesses anything here | READ (subagent audit, `free_pairing_check.py:652-667`, `:686-702`, `:2146-2161`) |
| `tools/control_flag_order_check.py` | mint < gate < strip < free | **an alloc between the mint and the strip does NOT violate it** — allocs are not classified as mint/strip/free/gate, and every index shifts uniformly | READ (`:120-152`) |
| `tools/golden_multiset_audit.py` | no shipped golden may move | a new slice reports `NEW-FILE` (passes). ⚠ its work-rail matcher fences on the alloc literal being `0`/`0x0p+0` (`:223-229`), so a **non-zero-seed** rail is not a work rail to it — correct here, worth knowing | READ |
| `tools/inplace_twin_matrix.py` | Ry-vs-Rz arm twin | **STRUCTURALLY CANNOT SERVE THIS AXIS** — see §14.9 | READ |
| `tools/loop_twin_matrix.py` | rolled ≡ unrolled | one new DECLINE-BOTH **cell** (not a boundary control — controls must be `ACCEPT-IDENTICAL`, `:556-566`), which moves the asserted `(120, 36, 117)` sub-grid sizes at `:857-858` | READ |

> **CORRECTED 2026-09-05 (implementation) — two rows of this table were READ and
> are now MEASURED, and one of them was read from a stale sentence.**
>
> * **`warnLiveRecordRotations`.** §14.12 worry 6 is right that the row's argument
>   ("a source theta mints its wire, so that wire can carry no record yet") is a
>   header comment written about an UNCONTROLLED source theta, an epic before
>   controlled rotations existed. Re-derived from the code that exists now: the
>   guard builds its record set in three passes over the gate's wire `W` —
>   ancestors, descendants, and descendants of every ancestor. For a state prep
>   `W` is the `cqrt_alloc_<W>(SEED)` handle, and **every descendant is minted
>   strictly after the gate** (the controlled Ry is the handle's FIRST user by
>   construction), so `recordAbsentAt`'s acyclic form skips them all. `Records` is
>   empty after filtering. **MEASURED**: forcing the state-prep gate into
>   `UserChainedRotations` leaves the lit family green and produces ZERO warnings
>   on all three e2e slices. The set choice is behaviour-neutral TODAY — recorded
>   so nobody quotes it as a live protection.
>
>   > **⚠ CORRECTED 2026-09-05 (round-1 Rule-13 review, lens L4 finding F-L4-3) —
>   > THE CONCLUSION IS RIGHT AND THE STATED MECHANISM IS WRONG, in the one
>   > paragraph §14.12 worry 6 flagged as most likely to be quoted rather than
>   > derived.** "The ancestor pass returns nothing … no seed for pass 3" is
>   > false: `classifyRail` returns `RailKind::Record` for a `cqrt_alloc_*` call
>   > (`isAllocRail`), so `collectAncestorRecords` takes the `K != Opaque` branch
>   > on `W` ITSELF and executes `Seeds.push_back(V)` **before** reaching the
>   > alloc stop. `Seeds == { W }`, not empty. Pass 3 is a no-op for a DIFFERENT
>   > reason: pass 2 already inserted `W` into the shared `Seen` set, so pass 3's
>   > `if (!Seen.insert(Seed).second) return;` fires immediately. And `W` stays
>   > out of `Records` because `RecordSet::push` short-circuits on clause 5
>   > (`if (V == Wire) return;`) — that guard, not an absent seed.
>   >
>   > **AND M-A IS NOT BLINDED BY A STATE-PREP-ROOTED RAIL**, which mutation M6
>   > could not establish (it only showed the state-prep GATE warns nothing).
>   > MEASURED with a compiled reproducer: a record `add` off the prepped rail, a
>   > CHAINED `cq_theta` on that rail and an unobserved user `cq_phi` on the
>   > record emits `warning: cq rotation lowering: non-diagonal gate over a live
>   > derived record`, exit 0; the exempt control (record measured after the gate)
>   > warns nothing. Committed as
>   > `control_inplace_ry_stateprep_warn_live_record.ll`.
> * **`railWireClosure` → R4 / R6.** The trap is real and is **BROADER than the
>   one fixture §14.5 names**: removing the skip reddens FIVE fixtures
>   (`..._seed_other_users`, `..._prep_then_prep`, `..._unrolled_k2`,
>   `..._lifted_phi_after`, `..._two_regions`), because a module-uniqued
>   `ConstantInt`'s use list reaches every sibling region in the function, not just
>   an unrelated later theta.
>
>   > **⚠ PRECISION, 2026-09-05 (round-1 Rule-13 review, lens L6 finding F-4).
>   > THE FIVE ARE 3 ACCEPTS + 2 DECLINES, AND THE TWO DECLINES DO NOT PIN THE
>   > VACUITY AT ALL.** `..._prep_then_prep` and `..._unrolled_k2` red because
>   > region 1 (which accepts today) starts declining on R6's string, so their
>   > `CHECK` for the **F1** string fails — a STRING move, not a prevented
>   > over-accept. Of the three accepts, `..._lifted_phi_after` reds only by
>   > accident of an unrelated `icmp eq i32 %o, 0` guard in its merge (change that
>   > constant to `1` and a third of the pin disappears silently). **The sole
>   > DELIBERATE pin is `..._seed_other_users`.** Read the row as "3 accepts + 2
>   > declines-by-string-move", not as five fixtures pinning the vacuity.

### 14.7 Per-stem: state prep is **Ry-ONLY**, and the stem table gains NO row

There is no Rz state prep, and the reason is Rule 3 rather than scoping:
`cq_phi` on a classical operand **propagates no taint and is deleted at lowering**
— it never allocates. Measured (`p10`): `int r = 0; if (q == 5) r = cq_phi(0, .9);`
declines `control flow`, and its IR really does carry `cq_phi_si32(i32 0, 9.0e-01)`
in the arm, so the shape reaches the classifier and is refused there. The "phase
twin" of this increment therefore **does not exist**, which has two consequences
that must be stated rather than assumed:

1. **The §12.1 stem table and the §13.4 RAUW-target row gain NO new row.** The
   Ry row already says *link / never adjoint / frozen / relabelling gate /
   RAUW-to-`T`*, and state prep needs all five verbatim. Nothing about the Rz row
   changes.
2. **`tools/inplace_twin_matrix.py`'s SHIPPED method cannot witness this
   increment**, because that method is to emit the same cell twice with
   `cq_theta` and `cq_phi` in the arm (`gen(c, arm)`'s
   `.replace("ARM(", arm + "(")`) and compare — and the `cq_phi` spelling of a
   state prep is a **deleted gate**, not an oracle. So the witness must be the
   §14.8 CHAINED twin, on a separate pool with a separate reference build.

   > **CORRECTED 2026-09-04, BEFORE THIS SECTION WAS APPENDED — the instrument
   > ALREADY EXISTS in the working tree and this paragraph originally said to
   > build one.** The probe/matrix agent added a **`--stateprep` POOL** to the
   > same file while §14 was being written (§13.11 worry 5 verbatim, one epic
   > later: *the matrix moved under me*). Re-measured on the working tree:
   > `prep_cells()` yields **297 `sp_*` cells** (all-pairs over four axes —
   > `prep` ∈ {`s0`,`s5`}, `cond`, `cfg` minus `ifelse2`, `cons`, `width`;
   > `base` is gone by construction, a state prep has no derived base) against
   > the five-axis pool's 472 `c_*` cells. It takes its **own** `--prep-oracle`
   > (a PRE-Inc-4 `cq-opt`) rather than overloading `--route-oracle`, carries its
   > own `reduce_prep` (the §14.8 reduction, written out) and its own
   > `classify_prep` verdicts (`IDENTICAL` / `MISMATCH` / `DECLINE-BOTH` /
   > `DECLINE-BOTH-DIFF` / `SUBJECT-ACCEPTS-TWIN-DECLINES` /
   > `SUBJECT-DECLINES-TWIN-ACCEPTS` / `HARNESS-ERROR`), and the `sp_` name
   > prefix keeps it a separate pool rather than a sixth axis — which matters,
   > because `name()` is a hard-coded 5-segment format string and a sixth axis
   > would have renamed every committed `c_*` cell. **Adding a `prep` token to
   > `BASES` is still the wrong move and is still not what was done.**

### 14.8 The witness — the CHAINED twin, and its reduction

There is no `_unrolled` twin (this is flat-only) and **no golden can witness
"the fresh rail holds |SEED⟩ on the `f=0` branch"** — the trace prints symbols and
handles, and no ABI label answers a state question. So the witness is **BYTE
IDENTITY** with the manual twin

```c
int r = cq_theta(SEED, 0.0);   if (COND(q))  r = cq_theta(r, θ);
```

which the **pre-Inc-4 binary already lowers** — measured, four spellings, each
compiled, linked, run and strict-2b-clean (`prd/ir/t01`–`t04`, independently
reproducing the probe agent's `p09a`–`p09d`). `t01`'s raw trace:

```
cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1.3333333333333p-2)
cqrt_alloc_i32(0) -> h1
cqrt_ry_i32(h1, 0x0p+0)                        <-- (i) DELETE
cq_template_icmp_eq_i32_hl(h0, 5) -> h2
cqrt_ry_i32_controlled(h2, h1, 0x1.ccccccccccccdp-1)
cq_template_icmp_eq_i32_hl_unc(h2, h0, 5)
cqrt_free(h2)
cqrt_measure_i32(h1) -> 0
cqrt_measure_i32(h0) -> 0
```
strict stage 2b: `4 rail mint(s) of which 4 left allocated, 2 cqrt_free site(s):
2 verified, 0 violation(s), 0 unproven`.

**THE REDUCTION — two rewrites, each a physical identity, neither of them the
transformation under test:**

1. **delete** `cqrt_ry_<W>(h, 0x0p+0)` — `Ry(0) = I`;
2. **move** `cqrt_alloc_<W>(SEED) -> h` to immediately before the first
   `cqrt_ry_<W>_controlled(f, h, ·)` naming `h` — a fresh-rail alloc acts on a
   wire nothing else names, so it commutes with every gate that does not name its
   handle;
3. renumber handles by first appearance.

**Expected post-Inc-4 trace for the flagship (`p01`) — the implementer's target:**

```
cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1.3333333333333p-2)
cq_template_icmp_eq_i32_hl(h0, 5) -> h1
cqrt_alloc_i32(0) -> h2
cqrt_ry_i32_controlled(h1, h2, 0x1.ccccccccccccdp-1)
cq_template_icmp_eq_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h2) -> 0
cqrt_measure_i32(h0) -> 0
```

Seed-7 (`p06b`): identical with `cqrt_alloc_i32(7)`. f64 (`p07a`):
`cqrt_alloc_f64(0x0p+0) -> h2` / `cqrt_ry_f64_controlled` /
`cqrt_measure_f64(h2) -> 0x0p+0`. The `!=` polarity (`p02`) puts the alloc
**between** the two brackets, which is the §14.1 position decision made visible:

```
cq_template_icmp_eq_i32_hl(h0, 5) -> h1
cqrt_x(h1)
cqrt_alloc_i32(0) -> h2
cqrt_ry_i32_controlled(h1, h2, …)
cqrt_x(h1)
```

> **WHAT THIS WITNESS PROVES AND WHAT IT DOES NOT — the
> `by-difference-twin-blind-to-arithmetic` lesson applied to itself.** Byte
> identity with the reduced twin proves the **STRUCTURE**: the flag is minted from
> the same compare, the control polarity is the same, the strip and free are the
> same, and the freeze applies to the same rail. It does **not** prove the VALUE
> claim *"the fresh rail starts at |SEED⟩"*. That rests on two other things, and
> both must be named beside the golden: (a) `cqrt_alloc_<W>(SEED)` is the **same
> call the uncontrolled `cq_theta(SEED, θ)` mints today**, pinned by the existing
> runtime goldens and by `runtime/test_trace.c`; and (b) **F1**, which is what
> makes `|SEED⟩` the right thing for the `f=0` branch to hold.
> The witness is honest about not sharing the transformation: the twin performs a
> REAL `Ry(0)` on a REAL allocated rail and Inc 4 performs neither, so the
> reduction states exactly the two facts being claimed instead of hiding them.
> **And stage 2b witnesses neither**: `free_pairing_check.py` never reads the
> alloc's seed argument (§14.6), so a wrong seed is invisible to it, and the
> frozen rail lands in its "left allocated" census with no finding. Quoting a
> green 2b as evidence for this increment would be false.

### 14.9 Fixtures, slices and gates

**lit:** 26 accepts + 37 declines = **63 new fixtures** (§14.3), corpus
1474 → **1537**.

> **CORRECTED 2026-09-05 (implementation): the shipped numbers are 20 accepts +
> 39 declines = 59 files in the family, corpus 1474 → 1531, ctest 324 → 327.**
>
> > **⚠ SUPERSEDED THE SAME DAY BY THE ROUND-1 RULE-13 REVIEW: 28 accepts + 48
> > declines = 76 files in the family, corpus 1474 → 1548 (ctest unchanged at
> > 327 — the round added no slice).** +17 files: NINE declines
> > (`..._range_mask1`, `..._range_a2_alias`, `..._range_ordered`,
> > `..._range_knownbits`, `..._range_i1_both_edges`, `..._unrecognized_suffix`,
> > `..._eqfold_ne_else`, `..._undef_seed`, `..._poison_seed`) and EIGHT accepts
> > (`..._range_ordered_seed0`, `..._cond_cast_seed`, `..._cond_bitcast_seed`,
> > `..._suffix_control`, `..._feeds_later_cond`, `..._feeds_later_cond_prep`,
> > `..._then_rolled_loop`, `..._warn_live_record`), plus one EXISTING accept
> > rewritten (`..._stateprep_i1.ll`, whose old module became
> > `..._range_i1_both_edges.ll`).
> >
> > **ROUND-2 then added +9** (8 declines: the six `..._range_forward_*` and the two
> > `..._range_constleft_{ugt,eq}`; 1 accept: `..._range_constleft_accept`), family
> > 76 → 85, corpus 1548 → 1557.
> >
> > **ROUND-3 then added +16 net**, family 85 → **101 files (30 accept / 71
> > decline)**, corpus 1557 → **1573**: THIRTEEN declines —
> > `..._sideways_{sdiv,offset}` (F-R3-1), `..._cast_{sext,zext,trunc}_live`
> > (F-R3-2), `..._intrinsic_{bswap,bitreverse,fshl,fshr}` (F-R3-3),
> > `..._range_knownbits_enum` (F-R3-9), `..._merge_edge_sideways` (why both edges
> > are asked, from plain C), `..._unevaluable_pinned_operand` (the conservative
> > half) and `..._fp_seed_sitofp` (F-R3-10, the fp seed no gate ever asked about)
> > — TWO accepts, `..._stateprep_deep_chain` (the deleted walk bound) and
> > `..._stateprep_intrinsic_bswap_accept` (the only file that separates the EXACT
> > fold from the conservative decline, written because mutation M5 first measured
> > 0 red) — and ONE EXISTING ACCEPT RE-HOMED AS TWO DECLINES
> > (`..._stateprep_i1.ll` → `..._reject_stateprep_i1_flag_pinned.ll`, IR
> > unchanged, joined by `..._reject_stateprep_i1_arm_flag.ll`; F-R3-8).
> >
> > **AND THE ARITHMETIC BELOW DID NOT RECONSTRUCT, which is its own finding**
> > (round-1 review, lens L7 F-L7-6). Three things were unaccounted for: rows
> > **A-17 and A-22 SHARE ONE FILE** (`..._consumer_none.ll`); TWO declines added
> > during the build (`..._ifelse_phase_first`, `..._eqfold_derived_cond`) were
> > never added to the recipe; and row **F2-7** (the `ne`-else fold, probe `p08k`)
> > **shipped no fixture at all and was named nowhere** — a real Rule-12 gap, now
> > closed by `..._reject_stateprep_eqfold_ne_else.ll`. That file is NOT a
> > duplicate of `..._eqfold_coincidence.ll`: measured at `-O1`, the two bodies
> > differ in exactly one thing, the merge φ's INCOMING ORDER, and F1's second
> > sub-clause reads the pred incoming by `getBasicBlockIndex(Region.Pred)` — by
> > BLOCK, not by operand position — which is what the new file pins.
> >
> > > **⚠ SUPERSEDED AGAIN BY THE ROUND-2 RULE-13 REVIEW (2026-09-05): 29 accepts
> > > + 56 declines = 85 files in the family, corpus 1548 → 1557 (ctest unchanged
> > > at 327 — this round adds no slice either).** +9 files: EIGHT declines
> > > (`..._range_forward_{add,xor,sub,or,lshr,ashr}` for lens R1's F-R1-1
> > > CONFIRMED-MISCOMPILE, and `..._range_constleft_{ugt,eq}` for its F-R1-5
> > > WEAK-PIN) and ONE accept (`..._stateprep_range_constleft_accept`, the
> > > discriminator control for the predicate swap). No existing file was
> > > rewritten or re-homed; §14.3 gains rows F2-9 … F2-16 and A-31.
> > >
> > > **TWO §14.3 ROWS WERE ANNOTATED RATHER THAN GIVEN FILES, DELIBERATELY, AND
> > > THE MEASUREMENT IS WHY** (round-2 review lens R2 F-R2-4 offered either).
> > > **F1-7** (global-address seed): `cq_theta_<sfx>` has no pointer-typed
> > > overload, so a global's address can reach the seed slot ONLY as a `ptrtoint`
> > > `ConstantExpr` — a second file would be the same `isa<ConstantInt>` refusal
> > > on the same IR shape, and `..._constexpr_seed.ll`'s own header already calls
> > > that "a false coverage claim". **F2-3** (`q>4 && q<6`): RE-MEASURED at
> > > `-O1` — the conjunction collapses to `icmp eq i32 %1, 5` with the arm folded
> > > to `cq_theta(i32 5, …)`, i.e. `p08c`'s `@slice` body is structurally
> > > `..._eqfold_coincidence.ll`'s `@example` body. Committing either would raise
> > > the fixture count without raising the discrimination, which is the number
> > > this project keeps paying for. Both rows now say where they live.
> The accept count is lower because SIX design rows fold into other fixtures'
> headers (their `-O1` slice bodies are byte-identical, so a separate `.ll` would
> be a false coverage claim), one row (IE-2) REUSES the pre-existing
> `control_angle_select_reject_state_prep.ll` rather than adding a second file,
> one row (W-1) has no reachable fixture at all, one row (A-12) moved from accept
> to decline, and one NEW decline was added for §14.13. Details in §14.3's
> correction. **`e2e-loop-twin-matrix`'s expected table did NOT need the new cell
> §14.9 predicted**: the committed pre-Inc-4 record already carries
> `m_ry_rprep_none_none_none`, and it stays `DECLINE-BOTH-DIFFERENT` after Inc 4
> for the two independent reasons its own caveat gives (the wrapper seeds
> `r = cq_theta(r, 0.3)` before the loop, so the pred incoming is the loop-carried
> QUANTUM `r` — the loop AND F1's data mux). Family names `control_inplace_ry_stateprep_*.ll` /
`control_inplace_ry_reject_stateprep_*.ll`, plus **one outside the family**
(`control_angle_select_reject_state_prep.ll`, the S3 row) and **one paired with an
existing Rz fixture** (§14.2d). Every accept fixture must use the whole-file
`NOROUTE` prefix rather than trailing `CHECK-NOT`s — the Inc-3 F-L6-1 finding
(a trailing `CHECK-NOT` scans only from the last positive match to EOF, and a
`cqrt_cswap` injected earlier left five fixtures green).

> **⚠ THAT PRESCRIPTION WAS FOLLOWED IN NAME AND DEFEATED IN FACT — THE INC-3
> FINDING RECURRED (round-1 Rule-13 review, lens L7 findings F-L7-1 / F-L7-2,
> fixed 2026-09-05).** Eleven accepts put a POSITIVE `NOROUTE-COUNT-n:
> cqrt_free` INSIDE the NOROUTE prefix, and a positive directive WINDOWS every
> negative one after it: FileCheck scans a `-NOT` only between the previous and
> the next positive match. So the `_controlled_inv` negative never reached past
> the FLAG's free — which is exactly where the uncompute spine emits. **MEASURED
> at hand-back: an injected `_controlled_inv` after the free was caught by 0 of 20
> NOROUTE blocks, and by NO prefix at all in 7 of 20** (the width fixtures had no
> such negative in the first place). Nine of the twenty also named a handle `%h1`
> that does not exist in their own lowered output, making the M7 anti-mutation
> assertion vacuous.
>
> **FIXED, AND THE FIX IS MECHANICAL SO IT CANNOT ROT:** every count moved to its
> own prefix (`ACNT` allocs, `FCNT` frees, `XCNT` `cqrt_x`) — one prefix per count
> group, because FileCheck applies a prefix's directives in order and a lowered
> module may interleave allocs and frees (`..._two_regions.ll`); `NOROUTE` is now
> PURE-NEGATIVE and therefore whole-file; and every handle name is DERIVED from
> the pass output rather than typed. **RE-MEASURED after the fix: the three L7
> injections (a `_controlled_inv` after the free, a dirty `cqrt_free` of the
> prepped rail, a `cqrt_cswap` after the free) are caught by 28 of 28 accepts, on
> all three.**

**e2e:** three slices, all STRICT stage 2b (no `--allow-unproven`):

| slice | what it pins |
|---|---|
| `slice_control_inplace_ry_stateprep.c` | the flagship; golden argued line by line in the notes |
| `slice_control_inplace_ry_stateprep_negated.c` | `!=` polarity — **and the alloc's position inside the `cqrt_x` bracket** |
| `slice_control_inplace_ry_stateprep_twin.c` | **the CHAINED twin, committed as a slice in its own right**, so the §14.8 reduction can be re-derived by hand from two committed goldens rather than from a script nobody re-runs |

**+3 ctest entries** (305 → … → 324 → **327**). No `cmp` twin gate: the two
goldens differ by a *reduction*, not by identity, so a `compare_files` gate would
be wrong; the reduction belongs in the notes and in a reviewer's hands. (If the
owner wants it mechanized, `inc4-records/reduce_twin.py` already implements
the three rewrites and could become a fourth ctest entry — recorded, not
proposed.)

**`tools/loop_twin_matrix.py`: ALREADY DONE, and committed at the PRE-Inc-4
disposition, which is what makes its diff the witness** (the Inc-3 precedent
exactly). Re-measured on the working tree: cell `m_ry_rprep_none_none_none`,
verdict `DECLINE-BOTH-DIFFERENT` (rolled `cq controlled lowering: control flow
under quantum control`, flat `… condition predates a non-diagonal gate …`),
expected table **258 → 259**, the asserted sub-grid sizes now `(120, 36, 118)`,
quarantine unchanged at 15. It is a **cell**, not a boundary control — controls
must be `ACCEPT-IDENTICAL`, so a decline control cannot be one. **Read its own
in-file caveat with it:** the wrapper seeds `r = cq_theta(r, 0.3)` before the
loop on every `RY_REGION` cell, so this cell's pred incoming is the loop-carried
QUANTUM `r` and it therefore declines for **TWO** independent reasons (the loop
AND F1's data mux). A red there means "Inc 4 widened into a loop OR into a
non-constant pred incoming" and does **not** isolate which; the isolating cells
are the lit family (§14.3 L-1 vs L-2), not this file.

**`tools/inplace_twin_matrix.py --stateprep --prep-oracle <pre-4 cq-opt>`:**
297 `sp_*` cells, the chained-twin reference, its own reduction and verdicts —
see §14.7's correction. **Neither instrument is a ctest entry**, and that is the
same deliberate cost decision the Inc-1 and Inc-2b instruments were given; the
`e2e-loop-twin-matrix` entry does cover the one new `loop_twin_matrix` cell.

**Gates that must be re-run and must not move:** `golden_multiset_audit.py --all`
(no existing golden may move — this increment adds slices, it does not regenerate
any), `control_flag_order_check.py` (0 violations; §14.6 establishes the alloc
does not perturb it), `free_pairing_check_test.py`, `cq-opt-equivalence-full`, the
six 8h7d.5 `cmp` twin gates, the three Inc-2b angle-select gates, the six Inc-3
in-loop gates, `e2e-loop-twin-matrix` **and** `e2e-loop-twin-quarantine-selftest`.
Full `ctest -j6` before commit (Rule 19 moments 1 and 5 both apply).

### 14.10 Review lenses — ≥3 rounds, 7 lenses

Each lens compiles, links and RUNS every twin it cites, on **both** binaries, and
writes nothing into `ir-pass/test/`.

1. **F1 — seed identity and merge faithfulness.** `undef` / `poison` /
   `ConstantExpr` / global / runtime seed / `-0.0` in both directions / a
   non-constant incoming / a classical `select` incoming / an incoming of a
   different TYPE at the same bit width (`i32 0` vs `float 0.0` in hand IR) / the
   seed's type vs `typeForAbiWidth(Abi)`. Try to construct an accepted region
   whose `f=0` branch does not hold the source's pre-region value.
2. **F2 — THE LENS THAT MATTERS.** Try to build ANY `-O1` program that CQ
   declines at the source level and whose IR is a state-prep accept. Both folds;
   derived temps (including one that folds to a value that is neither `0` nor
   `k` — `prd/ir/q24`); SSA aliases; casts; compound conditions (`p08q`);
   `switch`-lowered singleton ranges; `select` conditions; an equality on a
   DERIVED condition wire; an `fcmp oeq` condition against a `ConstantFP` seed
   (F2 as specified reads `ConstantInt` — **is that a hole?**); a `zext`/`trunc`
   between the compare's operand and the rotated register. And the converse: any
   ACCEPT whose emitted circuit differs from its source's meaning.
3. **Freeze + spine on a rail whose ROOT is the controlled gate.** A dead prepped
   register; every post-region consumer kind; `EmitInverse` reachability (must
   stay unreachable, *by construction*); a Phase-6 Bennett wrap; a `cq_invert`
   bracket; strict stage 2b on all three slices. Confirm the O(1) leak is the
   only leak and that no `cqrt_free` names the prepped rail.

   > **⚠ TWO OF THOSE ARE NOT DISCHARGEABLE AT HEAD, and one of them was being
   > treated as if it had been (corrected 2026-09-05, round-1 Rule-13 review,
   > lens L3 findings F-2 and F-3).**
   >
   > * **The `cq_invert` item is VACUOUS.** `tools/inplace_twin_matrix.py` emits
   >   `__cq_invert_begin(); r = cq_phi(r,0.14); __cq_invert_end();` and 11
   >   `sp_*_invert_i32` cells read `IDENTICAL` — but **the pass has no handler
   >   for those markers at all** (`grep -rn '__cq_invert_begin\|InvertBegin'
   >   ir-pass/src ir-pass/include` → zero hits; manual inversion is Phase 8).
   >   MEASURED: the lowered module keeps `tail call void @__cq_invert_begin()`
   >   verbatim and emits the FORWARD gate, sign unchanged. So the `invert` column
   >   is not evidence about `EmitInverse` reachability and this item cannot be
   >   discharged until Phase 8. `EmitInverse`'s unreachability is established the
   >   other way — structurally, through
   >   `ChainWalk::railCarriesControlledRotation` — and MEASURED as zero
   >   `_controlled_inv` / zero negative controlled angle across every accept
   >   fixture and every probe trace.
   > * **"the O(1) leak is the only leak" is FALSE ONCE `r` HAS A DERIVED
   >   CONSUMER**, and stage 2b cannot see the difference. The freeze marks the
   >   whole DAG `NotClosed`, so `int s = r + 1;` leaks THREE rails (`q`, the
   >   prepped rail, and the `cq_template_add_i32_hl` rail) while
   >   `free_pairing_check.py` counts `cqrt_alloc_*` mints ONLY and never sees the
   >   third. The honest statement is *"O(1) rails MINTED BY THE REGION, plus the
   >   derived DAG hanging off the prepped register — exactly as for an Inc-1
   >   chained rail"*, and the chained twin leaks the same set, so this is
   >   inherited rather than introduced.
4. **`RotationLowering`'s state-prep path.** The alloc's position (before/after
   the flag mint, inside/outside the `cqrt_x` bracket) re-derived from the IR, not
   from this text; `Tainted` / `BirthOrder` / `HandleWidth` all written at the
   hoisted position; the `UserSourceRotations` landing and **every reader of both
   sets** (§14.6); the `controlled theta suffix/width` bail hoisted above the
   alloc (§14.4); the two width derivations reconciled.
5. **Polarity, emission order, plan lifetime.** `!=` canonicalization; sequential
   regions in both orders (prep-then-chained, chained-then-prep, prep-then-prep);
   a classical branch between two regions (the L4 `RoutedBase` shape, now with a
   `Constant` base across two regions); the hcrg Kahn sort; the if/else clause
   under both polarities in hand IR.
6. **Walker / set audit, re-derived independently.** Every row of §14.6. Mutation
   tests: point R4/R6 at the `Constant` and confirm `q31`'s fixture reddens;
   delete F2 and confirm the seven F2 fixtures redden and **nothing else does**;
   delete F1 and confirm the eleven F1 fixtures redden; swap M-β for M-α on the
   state-prep path and confirm the accepts go **classical** (this is the one
   mutation whose failure mode is silent — check the lowered IR, not the exit
   code).
7. **Fixture and doc truth.** Every `CHECK` line asserts what its header claims;
   every decline mutation-verified by relaxing its own clause; every number in
   §14 re-measured; and — the DER lesson — the `-O1` shape of every e2e slice
   actually contains the diamond it claims (a vacuous accept looks exactly like a
   capability). Re-derive the §14.8 reduction by hand from the two committed
   goldens.

### 14.11 Questions for the owner

**Q1 — the seed == compare-literal over-decline (F2's price).** `int r = 5;
if (q == 5) r = cq_theta(5, θ);` is a well-formed, unambiguous state prep at the
source level and it will **decline**, because its `-O1` IR is byte-identical to
`if (q == 5) r = cq_theta(q, θ)` (an R4-forbidden in-place Ry on the condition
register) and to `if (q > 4 && q < 6) r = cq_theta(q, θ)`. Three genuine programs
are affected (`p06a`, `p23a`, `p23b`); the workaround is any seed other than the
compare literal. **Shipped disposition: DECLINE** (Prime Directive; the
alternative is silence on two declines). *What would widen it:* a ruling that
**the post-`-O1` IR IS the program** — i.e. that CQ compiles the module it is
given and not the C the user wrote — at which point the ambiguous shape could be
read as state prep unconditionally. That ruling would also retire
`tryEqFoldArm`'s and `straightThroughConstFoldHandle`'s reason for existing, so
it is a project-level ruling, not a fence tweak.

**Q2 — the RUNTIME seed (`p16`), a free widening, shipped DECLINED.**
`int r = seed; if (q == 5) r = cq_theta(seed, θ);` has the merge's pred incoming
and the theta's arg-0 as **the same SSA value**, and `cqrt_alloc_<W>` takes a
runtime value, so F1 spelled *"the pred incoming is the SAME VALUE as `T`'s
arg-0, and that value is untainted"* picks it up with no new machinery and no new
symbol. It ships declined because the owner's scope says `Constant`. Note the
`Constant` spelling is **not** redundant even if Q2 is granted: it is what makes
`-0.0` vs `0.0` a decline, because value identity on a uniqued constant already
IS bit identity.

**Q3 — the derived-temp fold residual (§14.2c), shipped ACCEPTED and documented.**
`if (q == 5) r = cq_theta(q - 5, θ)` compiles to a fresh-rail state prep of
`|0⟩`. The circuit agrees with the source on every component anything reads, and
the "no other reader" premise is enforced by the fold itself (measured). But the
accept rests on a distinction about **wires** (`f ≠ identity` ⇒ a different
physical rail) rather than on what the source meant, and the pre-fold program is
itself a shape CQ would decline if it could see it. **Is accepting this the
intent?** The alternative is to widen F2 from "seed == `k`" to "the arm's seed is
any value the edge PROVES", which would decline `p08b`, `p08t`, `p08v`, `q19`,
`q20`, `q24` and cost the flagship nothing — a cheap, strictly-safer fence that
also declines nothing anyone has asked for.

> **CORRECTED 2026-09-04 (orchestrator review, before implementation): the
> alternative above is NOT IMPLEMENTABLE as stated, and the owner's real lever is
> narrower and dearer.** The pass cannot see what the edge proved about a value
> the fold has already erased: `p08b` (`cq_theta(q - 5, θ)` under `q == 5`) and
> the flagship `p01` (`cq_theta(0, θ)` under `q == 5`) reach the pass as
> **byte-identical modules** (§14, headline; RESULTS.md §3 row b). There is no
> `f` to inspect and no "value the edge proves" other than `k` itself. So the
> residual and the flagship are ONE accept, not two, and the only fence that
> refuses the residual is **"no state prep under ANY equality compare"** — which
> refuses `int r = 0; if (q == 5) r = cq_theta(0, θ)`, the owner's own scoping
> example (Rule 17). **Shipped: ACCEPT, documented (A-24 is the same IR as A-1
> and says so in its header).** The owner's choice is therefore binary:
> (a) keep the accept and the §14.2c wire argument, or (b) restrict state prep to
> ORDERED compares only, at the cost of the flagship spelling. No cheap option
> exists.

> **⚠ SHARPENED 2026-09-05 (round-1 Rule-13 review, lenses L2 F-L2-3 / L6 F-2 and
> lens L2 F-L2-1's residual). THE QUESTION IS BIGGER THAN "DERIVED TEMPS", AND ITS
> §14.2c GROUND IS GONE.**
>
> * **The wire argument in option (a) is FALSE for `+k`/`−k`/`^k`.** Those are
>   CQ's own IN-PLACE ABI (`cqrt_addc`/`cqrt_xorc`), and `railWireClosure` — the
>   walker R4 is built on — calls them the SAME wire, not a different one.
>   MEASURED both ways: `int t=q+1; int u=cq_theta(t,.9);` with `q` dead emits
>   `cqrt_addc_i32(h0,1); cqrt_ry_i32(h0,.9)`; with a second reader it is out of
>   place. The correctness of the accept for that sub-family is **unproven in both
>   directions**, because the in-place/out-of-place choice is M-C's, made in
>   `lowerOps` long after detection, and in the FOLDED module the op does not
>   exist for M-C to decide about — while adding the second reader that would force
>   the question also PREVENTS the fold. Option (a) therefore ships an accept whose
>   argument is "we cannot tell", not "it is a different wire". The CAST
>   sub-family keeps its wire argument, which was re-measured and holds (every
>   foldable cast lowers out of place, `bitcast` included).
> * **The same question now also owns F2's RESIDUAL.** F2's range spelling closes
>   every member where the pinned register SURVIVES. It cannot close the members
>   where instcombine DELETED the register and rewrote the compare onto an
>   ancestor: `k03` (`(unsigned)q >> 31`), `k04` (`int b=(q!=0); if (b) …`),
>   `int t = q ? 1 : 0;`, and — the sharpest —
>   `int b=(q!=5); int r=0; if (q==5) r=cq_theta(b,.9);`, whose `@slice` body is
>   **BYTE-IDENTICAL TO THE FLAGSHIP SLICE'S**. Every one of those alternative
>   sources is a data MUX that CQ refuses whenever the register survives (measured:
>   keep `b` live and it declines `condition data use neither escaped nor
>   measured` on BOTH binaries). So the residual is not a corner: **it reaches the
>   flagship's own module**, and the only fence that reaches it is option (b).
> * **Option (b) is therefore dearer than it looked, and cheaper than it looked, at
>   once.** Dearer: it must refuse the flagship. Cheaper: it is ONE clause
>   (`decline a state prep whose condition is an equality on a tainted operand`)
>   and it subsumes the whole range machinery. **The owner's choice is unchanged in
>   shape and better informed: (a) ship as-is with the residual written down, or
>   (b) narrow to ordered compares.** The range fix is worth having under either,
>   because under (a) it removes nine measured miscompiles and under (b) it is dead
>   code that costs nothing.

> **⚠ RE-SHARPENED 2026-09-05 (round-2 Rule-13 review, lens R1 findings F-R1-1 and
> F-R1-4). THE RESIDUAL IS SMALLER THAN THE ROUND-1 TEXT ABOVE SAYS, AND WHAT IS
> LEFT OF IT NOW HAS ITS BOUNDEDNESS ARGUMENT.**
>
> * **HALF OF WHAT WAS FILED HERE WAS A FENCE QUESTION, NOT A SCOPE QUESTION, AND
>   IT IS NOW FENCED.** The round-1 residual sentence — *"instcombine deleted the
>   register **and** rewrote the compare onto an ancestor"* — conflated two
>   independent events. InstCombine **always** rewrites the compare onto the
>   ancestor in this family and only **sometimes** additionally deletes the
>   register. Six plain-C programs sat in the "always, without the deletion" half
>   with the register **alive, lowered to a rail and MEASURED by the source while
>   receiving no rotation** — a CONFIRMED silent miscompile, now closed by F2's
>   forward closure (§14.2b). ⚠ **`k03` DOES NOT LEAVE THIS LIST, AND THE REASON
>   IS THE WHOLE DISTINCTION** — measured, after an earlier draft of this bullet
>   claimed it did. `k03` is `unsigned s = ((unsigned)q) >> 31;` with `s` **never
>   measured**, so instcombine DELETES it: the deleted half. `x23` is the same
>   expression with `cq_measure(s)` added, so the register survives: the fenced
>   half. One token apart, opposite dispositions, and asserting the wrong one in
>   the record of the fix would have re-created the very conflation the fix
>   corrects.
> * **WHAT REMAINS IS EXACTLY THE DELETED-REGISTER HALF, AND IT IS BOUNDED.** A
>   register is deleted only when **nothing reads it**. If nothing reads it, the
>   difference between "rotate that rail" and "rotate a fresh rail prepared to the
>   same pinned value" is confined to a **leaked ancilla that no `cq_measure`,
>   `ret` or tape write observes** — which is the same move the `fenv` ruling
>   already blesses for a dead `volatile` product. That is why this is a **scope**
>   question for the owner and not a fence the increment should have shipped.
>   Members re-measured at HEAD — **five, the round-1 list unchanged**: `k03`
>   (`((unsigned)q)>>31` with the result DEAD), `k04` (`int b=(q!=0); if (b) …`),
>   `r3` (`int t = q ? 1 : 0;`), `r4` (byte-identical `@slice` body to the
>   `_negated` accept fixture) and `r6` (byte-identical `@slice` body to the
>   FLAGSHIP slice's).
> * **THE ARGUMENT DOES NOT EXTEND ONE INCH TO THE FENCED HALF**, and saying so is
>   the point of writing it here: in F-R1-1's six the register is READ, so nothing
>   is confined to an unobservable ancilla and the leak argument is unavailable.
>   If a future agent quotes this bullet to reopen an accept, that is the sentence
>   they are quoting past.
> * **CQ HAS NO SIMULATOR (Rule 2), so "the leaked ancilla never interferes" is
>   ANALYTIC.** Every reproducer that could be written measures immediately. It is
>   recorded as an argument, not as a measurement.

> **⚠ RE-SHARPENED AGAIN 2026-09-05 (round-3 Rule-13 review, lens R3 finding
> F-R3-4). THE BOUNDEDNESS ARGUMENT IN THE BULLET ABOVE HAS A MEASURED
> COUNTEREXAMPLE, AND THIS IS THE FINAL BOUNDARY STATEMENT.**
>
> * **THE PREMISE HOLDS; THE CONCLUSION DOES NOT GENERALISE.** "A register is
>   deleted only when nothing reads it" is TRUE, and was re-verified by reading
>   the `-O1` module of every member. What does not follow is "therefore the
>   difference is confined to a leaked ancilla nothing observes":
>   `n03_k03_derived` is `k03` plus one line — `unsigned z = s*2u;` **after** the
>   region — and `-O1` rewrites `s*2` into `(q>>30)&2` and deletes `s`. The
>   *register* still has no reader, and a value **DERIVED FROM IT IS MEASURED**.
>   The emitted circuit computes `z` from `cq_template_lshr_i32_hl(h0,30)` /
>   `cq_template_and_i32_hl(h3,2)` — from `q`'s **unrotated** rail — while the
>   rotation went to a fresh `cqrt_alloc_i32(1)`. The difference is observable.
> * **THE SENTENCE, NARROWED:** *…confined to a leaked ancilla that no
>   `cq_measure`, `ret` or tape write observes — **ONLY WHEN no value derived from
>   the deleted register is observed either***. Eight members re-measured on the
>   round-3 binary (notes §12.2): `k03`, `k04`, `r3`, `r4`, `r6`, `n09`, `n10`,
>   `n11` are all case **(a)**, nothing derived is observed, and the argument
>   stands for them verbatim; `n03_k03_derived` is case **(b)** and the argument
>   is unavailable for it.
> * **THE BRIEF'S (a)/(b) QUESTION, ANSWERED FOR `n03`, AND IT IS (b).** `z` is
>   computed AFTER the region and reads `s` AFTER `s` was rotated — a stale-record
>   read of the pre-rotation name, not a value computed BEFORE the region that
>   legitimately holds the folded constant. **MEASURED, NOT ARGUED:** the unfolded
>   twin (the same module with the arm's theta taking `%s` and `z = mul %s, 2`)
>   declines on **BOTH** binaries with `cq opcode lowering: operand predates a
>   non-diagonal gate` — CQ's own pass-wide stale-record guard. So the source
>   spelling of this program is a shape CQ refuses outright, and the accept is
>   reachable **only through the fold**: the Inc-2b F-11 structure exactly.
> * **STILL FILED, STILL NOT FENCED, AND NOW FOR A MEASURED REASON.** F2 can only
>   ask about registers that EXIST, and the semantic form (§14.2b, round 3) does
>   not change that — with `s` gone there is no `X` to ask about. Every fence
>   proposed for it declines the flagship: `q` is pinned to `{5}` on the
>   flagship's own arm edge and is measured after the region, so "decline a state
>   prep whose condition pins a register that is live past the region" refuses
>   `p01`. **No fixture is added**, deliberately — a fixture pinning a known
>   over-accept as an ACCEPT blesses it, which is the `..._constexpr_seed.ll`
>   precedent (a false coverage claim is worse than a missing one).

> **⚠ WIDENED 2026-09-05 (round-4 Rule-13 review, lens R4, finding F-R4-2). THE
> VERDICT IS UNCHANGED; THE POPULATION IS SIX PROGRAMS, NOT ONE, AND IT IS A
> SHAPE THE OWNER CAN RECOGNISE ON SIGHT.**
>
> * **THE SHAPE, IN ONE SENTENCE:** *a sign or flag bit tested as the condition,
>   and then SCALED.* The round-3 text above reads as though case (b) were one
>   exotic program (`n03_k03_derived`). R4 wrote five fresh plain-C members, each
>   ORACLE-decline / HEAD-accept, strict-2b clean, LINKED and RUN, covering three
>   observation forms `n03` did not:
>
>   | program | deleted register | what is observed | how |
>   |---|---|---|---|
>   | `n03_k03_derived` (round 3) | `s = ((unsigned)q)>>31` | `z = s*2u` | `cq_measure` |
>   | `dr01_sign_x4` | `s = q>>31` | `z = s*4u` | `cq_measure` |
>   | `dr02_sign_shl` | `s = q>>31` | `z = s<<3` | `cq_measure` — a SHIFT |
>   | `dr09_sign_ret` | `s = q>>31` | `z = s*4u` | **`return z`** — the tainted handle ESCAPES |
>   | `dr10_sign_chain` | `s = q>>31` | `z = (s*4u)+7u` | `cq_measure`, TWO hops past the rotation |
>   | `dr12_sign_x4_meas_q` | `s = q>>31` | `z = s*4u` **and `q`** | `cq_measure` ×2 |
>
>   The whole family is one C line apart:
>   `unsigned q=cq_theta(3u,0.3); unsigned s=q>>31; unsigned r=1u; if(s) r=cq_theta(s,0.9); unsigned z=s*4u;`
>   — `-O1` rewrites `s*4` into `(q>>29)&4` and DELETES `s`, so the REGISTER has
>   no reader and F2 has nothing to ask about, while `z` reads the rail the source
>   says was rotated, through an UNROTATED derivation.
> * **`dr09` IS THE ONE THAT MOVES SOMETHING.** Every earlier member observed
>   through `cq_measure`; `dr09` observes through `return`. F-R1-4's sentence
>   already listed `ret` alongside `cq_measure` and a tape write — it had simply
>   never been MEASURED for this class, and now it has.
> * **THE BOUNDARY IS RE-DERIVED, NOT INHERITED.** R4 built the unfolded twin of
>   the widened shape (`h/hd01_dr01_unfolded.ll`) and ran it on BOTH binaries: it
>   declines with `cq opcode lowering: operand predates a non-diagonal gate`. So
>   the round-3 final sentence generalises VERBATIM over the six — reachable ONLY
>   through the fold, the Inc-2b F-11 structure exactly.
> * **STILL FILED, STILL NOT FENCED, STILL NO FIXTURE.** The round-4 review looked
>   for a fence that spares the flagship and found none (the flagship's own `q` is
>   pinned `{5}` on its arm edge and is measured after the region). **This is a
>   SEVERITY correction to Q3's record, not a demand for a patch** — and the
>   question the owner is being asked is unchanged in shape: (a) keep the accept
>   with the residual written down, or (b) narrow state prep to ORDERED compares
>   at the cost of the flagship spelling. What is better informed is the SIZE of
>   what (a) accepts.

> **CORRECTED 2026-09-05 (Rule-13 CLEARANCE review, finding OQ-1) — OPTION (b) IS
> NOT A LEVER, AND THE QUESTION IS NARROWER THAN IT READS.** The clearance
> reviewer compiled all eleven residual members and split them by whether a
> value DERIVED from the deleted register is observed: `k03`, `n03`, `dr01`,
> `dr02`, `dr09`, `dr10`, `dr12` — every one with an observed derived value —
> arrive at `-O1` with the condition `icmp sgt %1, -1`, an **ORDERED** compare.
> So "narrow state prep to ORDERED compares" would refuse the flagship and **leave
> all of those accepted**, closing only the four members whose difference is an
> unobservable leaked ancilla: maximum capability cost, zero coverage of the half
> that matters. **No costed narrowing that reaches the observed-derived half
> exists today.** The residual is graded AMBIGUITY (an undefined-in-CQ program
> compiled to the circuit of its C-literal reading, correct on every observable
> under that reading; every unconditional twin declines on BOTH binaries), not a
> confirmed wrong unitary — which is why the increment CLEARS with this on the
> desk rather than BLOCKING on it. The owner's real choices are: (a) keep the
> accept with the residual written down (shipped); or (c) refuse state prep
> outright until a fence that can see a DELETED register exists — which would
> need `-O1` to preserve the register or CQ to run before the fold, i.e. a
> pipeline change, not a clause. A second clearance note (OQ-2): F2 asks its
> question of every tainted register in the FUNCTION, so an unrelated tainted
> register pinned to the seed declines the prep — hand-IR only, safe direction.

**Q4 — the if/else observation, on the desk rather than in the increment.**
Owner ruled "two preps = two rails = decline", and Inc 4 ships that clause. The
measurement is that **M-β would already produce the correct one-rail lowering**:
R3 passes by pointer identity on the shared seed constant, the two hoisted gates
chain, and the emitted circuit is `alloc(SEED); cRy(f, A); x; cRy(f, B); x` —
which IS `if (c) r = Ry(SEED, A); else r = Ry(SEED, B);`. Nothing allocates two
rails except a reading in which SSA names are wires. **Say if the ruling should
move**; if it does, it moves to the S3 angle-select site as well (Q5) and both
need §12.3's arithmetic fences.

**Q5 — the SECOND customer site, `classifyAngleSelect` S3 (`drbq.13`).** From
plain C the if/else with two preps is not an if/else at all: `-O1` makes it ONE
theta with an angle `select` (`p14a`), refused at S3 with `rotation angle`. It is
an Inc-2b-shaped by-difference candidate on a fresh rail
(`alloc(SEED); ry(h, B); ry_controlled(f, h, A−B)`) and inherits every §12.3
concern including the constant-arms-only narrowing. **In scope or out?** Shipped
OUT.

**Q6 — `p11`, an FYI with a sharp edge.** `int r; if (q == 5) r = cq_theta(0, θ);`
with `r` read afterwards is UB, so `-O1` deletes the branch and emits
`llvm.assume(i1 %2)`: the Ry becomes **UNCONDITIONAL**. It declines today only
because `llvm.assume` consumes the tainted compare and trips
`declineTaintEscapes`. No action requested — but if `llvm.assume` is ever
whitelisted, that program compiles to an unconditional rotation, silently.

### 14.12 What worries me

1. **The increment was scoped with ONE fence and needs TWO, and the second was
   found by a probe rather than by reading.** §7's Inc-4 bullet is not wrong about
   F1; it simply never asked what `clang -O1` does to `cq_theta(q, θ)` on an
   equality edge. This is worry 1 of §13.11 one increment later — *when an
   increment's target shape is defined by what the source says, compile the
   ADVERSARIAL source first and diff the modules.* Two agents independently
   produced byte-identical modules for a decline and an accept before anyone
   wrote a line of the fence.
2. **F2 is a fence on a SYNTACTIC coincidence, and I cannot prove it complete.**
   Its soundness argument is "on an eq/ne diamond exactly one edge proves the
   equality, and F1 collapses both readings to seed == k" — which is airtight for
   the shapes measured. What is not proved is that `-O1` never produces a folded
   arm seed **without** an equality compare surviving to the pass. Four ordered
   spellings and one range were measured to canonicalize to `icmp eq` first, and
   108 probes produced no counterexample; that is evidence, not a proof. The
   `fcmp oeq` case — the one I expected to be the hole — was **measured closed**
   (`prd/ir/q32`/`q34`: an `oeq` edge does not substitute, because `oeq` is not a
   bitwise-equality proof), which removes the candidate I had and leaves me
   without one. That is a worse position than having a named suspect, not a
   better one: lens 2's job is to find the suspect I could not.
3. **The accept is DIAMOND-ONLY by a fence that fires through ABSENCE.** F1 needs
   a Pred edge; an if/else has none. I added an explicit if/else clause so the
   decline is findable, but the general shape "this accept class is bounded by a
   clause that cannot be satisfied rather than by a clause that refuses" is how a
   later widener removes the bound without noticing there was one.
4. **The flat twin matrix exists but its oracle is a REDUCTION, not an
   identity, and that is weaker than what Inc 1 had.** `--stateprep` compares the
   subject against a *reduced* chained twin (§14.8's two rewrites), so a defect
   in the reduction itself — or one shared by the subject and the twin — is
   invisible, and unlike the Rz-arm pool there is no second, independently-lowered
   spelling of the same unitary to fall back on (§14.7: the Rz spelling of a
   state prep is a deleted gate). It is also **not a ctest entry**. And I did not
   run it: it needs a pre-Inc-4 `--prep-oracle` and a lowering that does not
   exist yet, so every claim in §14.7/§14.9 about it is READ from the source at a
   moment the source was being written.
5. **I am relying on `railWireClosure` being SKIPPED, not on it being safe.** The
   measured trap (§14.5, `q31`) is that pointing it at a module-uniqued
   `ConstantInt` enumerates unrelated users across the function and — for
   cross-function users — is saved only by a `DominatorTree` query returning
   false for a foreign block. I have specified "skip", and `q31` reddens if
   anyone re-points it. I have **not** audited every other place that might come
   to hold a `Constant` in a rail-shaped slot now that `Region.RoutedBase` can be
   one.
6. **`warnLiveRecordRotations` will not run on these gates**, and the argument
   that this is right ("a source theta mints its wire, so that wire can carry no
   record yet") is a sentence in a header comment that predates controlled
   rotations by an epic. I believe it — the alloc is three instructions earlier —
   but it was written about an UNCONTROLLED source theta and I am re-using it for
   a controlled one, which is the "justification gone stale" shape this file keeps
   finding. Lens 4 must re-derive it rather than quote it.
7. **The fold is not deterministic across equivalent sources** (`p08h` folds,
   `p08s` does not, and they differ only in how the compare was written). Every
   fixture I have specified is written against ONE observed `-O1` output. A clang
   or `-O1` pipeline change moves the IR under all 62 of them, and the ones that
   would go silently WRONG rather than red are the F2 declines — because a shape
   that stops folding stops being ambiguous and starts declining on R4 instead,
   with a different string.
8. **Three of my accept rows are consumer-axis rows I did not compile as accepts,
   because none of them can compile until the fence exists.** `p13a`–`p13g`
   measured that the DIAMOND survives `-O1` for all seven consumers, which is the
   part that could be measured; that the region then lowers for all seven is
   inferred from Inc 1's identical consumer family. The DER lesson says that is
   exactly where a vacuous accept hides.

### 14.13 CORRECTED 2026-09-05 — the implementation's headline finding: `-O1` sinks post-region ops INTO the arm

**Written at implementation time, appended rather than woven in, because it is
the one thing this section did not and could not know.**

```c
int r = 0;  if (q == 5) r = cq_theta(0, .9);
int s = r * 3;                    /* ANY post-region op on r */
```

**declines.** The straight-through value of a state-prepped register is a
compile-time **constant**, so on that edge `r * 3` folds to `0`, the op has
exactly one live use left — *inside the arm* — and `clang -O1` sinks it there.
The module the pass sees is

```llvm
arm:   %rt = call cq_theta_si32(i32 0, .9)
       %rs = mul nsw i32 %rt, 3            ; SUNK
merge: %rm = phi [ %rs, %arm ], [ 0, %entry ]
```

which is not §14.1's accept shape at all: the merge's arm incoming is the `mul`,
not the theta, and the arm block holds two instructions. **R1's shape half refuses
it** — `RegionFlatten` erases the arm block, so a stray op would be silently
dropped and its taint work-list pointer would dangle.

**THE CHAINED TWIN IS IMMUNE, AND THAT IS WHY NOTHING IN THIS SECTION SAW IT.**
With `int r = cq_theta(0, 0.0);` the straight-through value is a live REGISTER,
`r * 3` does not fold on that edge, and `-O1` leaves the `mul` after the merge —
so the Inc-1 shape accepts. Every measurement in §14 that used the chained twin
as its reference inherits that asymmetry. The probe family could measure that the
DIAMOND survives `-O1` for each consumer; it could not measure what `-O1` does to
the ARM once the region became lowerable.

**Measured population:** 48 of the 297 `--stateprep` twin-matrix cells read
`SUBJECT-DECLINES-TWIN-ACCEPTS` with the `control flow` message on this class —
12 each of the consumers `mul3`, `spine`, `deadadd`, `deadmul` — **plus 3 more**
where the sunk op is a CAST rather than arithmetic and the string is `value-arm
swap-route` (`printf` at i8/i64/f64; `printf_i32` needs no cast and reads
`IDENTICAL`, which is the control that makes this a characterization rather than
a guess).

> **⚠ CORRECTED 2026-09-05 (round-1 Rule-13 review, lens L7 finding F-L7-4): NOT
> "across every cfg, cond and width".** Re-counted from the committed post-4
> table by message: the 48 sit at cfg `diamond` (40), `clsbefore` (4) and
> `negated` (4), and
>
> * **`clsbetween` contributes ZERO** — all four of its arithmetic cells read
>   `IDENTICAL`. That is the **POSITIVE CONTROL FOR THE MECHANISM**, not an
>   exception to it: a second region between the prep and the op makes `r`'s
>   straight-through value NON-CONSTANT, so nothing folds and nothing sinks. It is
>   the same discriminator the chained twin has, reached a different way, and it
>   belongs in the characterization rather than being papered over by "every cfg".
> * the four `ifelse` arithmetic cells DO decline, but on `rotation angle` (`-O1`
>   merges the two arms into one theta with an angle select, S3), so they are not
>   members of this class either.
>
> The number 48 is right; the quantifier was not, and it was hiding the one cfg
> that demonstrates the class's own boundary.

**§14.12 worry 8 predicted it exactly:** *"three of my accept rows are
consumer-axis rows I did not compile as accepts, because none of them can compile
until the fence exists … the DER lesson says that is exactly where a vacuous
accept hides."*

**Shipped disposition: DECLINE**, pinned by
`control_inplace_ry_reject_stateprep_sunk_arith.ll`. It is not a fence — R1 was
not widened or narrowed — it is the accept shape simply not being present. Rows
A-15 and A-18 are corrected; the two hand-IR fixtures that assert the post-merge
shape now say in their headers that they are hand IR and what the C does instead.

> **OWNER QUESTION (Q7).** Supporting this is a NEW CAPABILITY, not a fence
> relaxation: `arm = { state-prep theta, value-op chain }` is a **value arm whose
> base is minted inside the arm**, and F1 would have to read *"the Pred incoming
> is the arm's op chain CONST-FOLDED over the seed"* rather than *"the Pred
> incoming IS the seed"* — which is a constant-folding obligation inside a fence,
> with its own soundness argument about what the chain may contain. It also
> re-opens the F2 question one level down (the folded chain result could coincide
> with the compare literal). **Is it wanted, and is it its own increment?** The
> user-visible cost today is that any arithmetic on a state-prepped register in
> the same function declines; the workaround is to keep the register's
> straight-through value non-constant, i.e. to write the chained spelling
> `int r = cq_theta(SEED, 0.0);` — which is exactly the manual twin, and which
> compiles today.
