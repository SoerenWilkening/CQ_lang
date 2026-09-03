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
