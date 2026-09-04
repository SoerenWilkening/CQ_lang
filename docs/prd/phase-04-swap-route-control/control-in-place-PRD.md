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
- **Inc 4 — controlled state-prep (S5).** `T` with a CLASSICAL arg-0 in the
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
