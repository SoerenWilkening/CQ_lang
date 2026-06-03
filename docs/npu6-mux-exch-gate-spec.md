# npu.6 — MUX-EXCH uncompute safety gate (design spec)

**Status:** IMPLEMENTED (npu.5 + npu.6 landed atomically). A distinct-per-case-handle gated
switch that passes the conservative G0–G7 gate now lowers MUX-EXCH (`regOut = cqrt_alloc(0)` +
per-base `cqrt_cswap` MOVE + per-non-selected-source `cqrt_ry_<W>_controlled_inv` uncompute);
everything else still declines to the always-safe WP12 diagnostic. The detection gate lives in
`muxBasePreconditions`/`muxRegionGate` (`ControlDetection.cpp`), the lowering in `lowerGatedSwitch`
(`ControlledLowering.cpp`), and `region.MuxExch` carries the decision. **Implementation addendum
(adversarial review C1, 2026-06-03): G3 gained a per-arm-correspondence clause `G3b` — see §3.**

**Widening addendum (test_C_libtooling-5bl, 2026-06-03):** two §9 residual cases were promoted
from always-declined to lowering, each over-decline-safe and adversarially reviewed: **G5** now
admits a non-`ConstantFP` prep angle whose def **dominates** the merge uncompute anchor (not just
a literal), and **G4** now admits an **empty direct-to-merge default** (`SwitchDefaultDirect`) for
a distinct-base mux (the default base rides the `region.Pred` φ edge; its control is the existing
`¬OtherCaseOr` complement bracket). See §3 (G4/G5 rows), §9.

**Widening addendum (test_C_libtooling-u5f, 2026-06-03):** the **G2 (chained/multi-Ry)** and
**G3a (theta-then-cq_phi prep)** residual cases were promoted from always-declined to lowering by
generalizing the npu.6 single-`Ry†` uncompute to a **REVERSE-ORDER multi-op Bennett uncompute**
(`recoverPrepChain` + `emitChainInv`, `ControlledLowering.cpp`): a non-selected base's forward
prep — a sequence of uncontrolled `cqrt_ry` (one per chained `cq_theta` link) optionally followed
by uncontrolled `cqrt_rz` (one per UNCONDITIONAL prep `cq_phi`) — is disentangled by emitting the
`_controlled_inv` twin of each in **reverse program order** (`U†` undoes `U` innermost-last), each
controlled on `¬f_q`. G2 now walks the theta chain to a classical root (each link G5-angle-valid);
G3a now admits an unconditional prep `cq_phi`/theta that **dominates** the merge and is fully
consumed in-region, recording it as a chain node. The single-Ry happy path is a length-1 ry-only
chain (byte-identical output). **G6 (cross-φ-shared / post-merge-live base) stays PERMANENTLY
declined** — a `cqrt_cswap` destructive-move no-cloning hazard, NOT a deferred capability gap (§9).
See §3 (G2/G3 rows), §9.

**Provenance addendum:** an implementation-stage adversarial review (6 attackers, empirical via the
built pass) confirmed the lowering algebra, flag lifecycle, bookkeeping, and all regression paths
correct, and found ONE silent-miscompile hole (C1): the original G3 set-membership check admitted an
in-region gate body that mutates a mux base from a NON-selecting arm (a stray controlled-Rz the
single `Ry†` cannot undo). Closed by **G3b** below; regression fixtures
`lowering_control_switch_gated_distinct_wrongarmmut{,_default}.ll`.

**Provenance:** adversarial design review (2026-06-03) — 6 independent attackers each tried
to break a proposed 4-precondition gate from a distinct angle, then a synthesizer merged what
survived. (A 7th attacker on the liveness angle failed to return; its concern is fully covered
by **G6** below.)

---

## 1. The reframing (why this is a gate problem, not a simulation problem)

Uncomputation correctness is a **unitarity theorem**: a register prepared by `U` returns to
`|0⟩` exactly under `U†` (`U†U = I`). Bennett/Sturm is the ground-truth construction, and — as
for *every* gate this compiler emits — correctness is established **by construction + a
gate-sequence fixture**, never by simulation (the runtime is trace-only; there is no amplitude
model for any gate). So the **happy path is provably correct**; we do **not** need a simulator
to "confirm the inverse uncomputes."

The danger is therefore **not** the inverse — it is the **gate** admitting a case where the
preconditions that make "apply the inverse" valid do **not** actually hold. That produces a
verify-clean **silent miscompile** — the exact cardinal-sin class this epic exists for, and one
the trace runtime cannot catch. **The gate is the entire safety argument.** When in doubt,
**decline** (the npu.1 path is always safe; over-declining only keeps a byte-identical decline).

---

## 2. The narrow happy-path that LOWERS

After this increment (with the 5bl G4/G5 widening), the distinct-base gated-switch multiplexer
that lowers is:

> a tainted-scrutinee `switch` with **either** a distinct reconverging default block carrying a
> gate body (`HasDefaultGate`) **or** an empty direct-to-merge default (`SwitchDefaultDirect`, the
> default base riding the `region.Pred` φ edge — 5bl); **exactly one** mux φ in the merge whose
> **every distinct base is a direct `cq_theta` with a classical (untainted) arg-0** (a single `Ry`
> prep); a **`ConstantFP`, or a non-tainted angle whose def dominates the merge uncompute anchor**
> (5bl); **no extra mutation** between prep and merge other than in-arm controlled gate bodies;
> **every mux base of one shared logical width**, **disjoint** from all sibling-φ bases and **dead
> after the merge**.

Everything else **declines** to WP12 (§5).

---

## 3. The gate (run in order; first failure ⇒ decline). Detection-time, in
`tryBuildGatedSwitchRegion` (`ir-pass/src/ControlDetection.cpp` ~725–738), where the form is
still pre-lowering (detection runs before `lowerRotations`, `CQLoweringPass.cpp:72` before `:76`).

| # | Check | Declines | Evidence |
|---|---|---|---|
| **G0** | **Structure/identity (shipped npu.1, kept verbatim, runs first).** Every non-angle φ incoming is `taint.Tainted`; `resolveGatedHandleBase(In)` is identical across one φ's edges. The mux fires only for a φ with **distinct** bases; uniform-base φ stays the step-4 RAUW path. | constant / `cq_measure` / all-classical incomings (fail the taint test) | `ControlDetection.cpp:725-737`; `TaintPropagation.cpp:135,152` |
| **G1** | **Base is a direct `cq_theta` prep.** Each distinct base `B = resolveGatedHandleBase(In)` must be a `CallInst` whose callee `starts_with("cq_theta_")` (≡ `B ∈ taint.ThetaCalls`). Reject `SelectInst`/`PHINode`/`Argument`/any non-theta tainted instruction. | dissolveSelect/branch-φ mux output, classical-data arm (`add`/`sub`/`zext` of handles), function-arg or any non-theta base | `resolveGatedHandleBase` only unwraps `cq_phi_` and returns the first non-`cq_phi` value with no Ry check (`:83-95`) |
| **G2** | **Invertible Ry prep CHAIN (WIDENED — u5f).** For each base `B` (a `cq_theta_` call), walk its `cq_theta_` arg-0 operand chain down to the root: admit iff EVERY link is a `cq_theta_` with a G5-valid angle AND the chain root's arg-0 is **non-tainted** (classical/fresh). A single `cq_theta(y0,a)` is a length-1 chain (one `cqrt_ry`, the npu.6 path); a chained `cq_theta(cq_theta(y0,a1),a2)` is N `cqrt_ry` on ONE handle, uncomputed by the REVERSE-order multi-op inverse (`emitChainInv`). Reject a chain whose descent stops at a non-theta TAINTED node (an entangled root the ry/rz-only inverse cannot undo). _Was: reject ANY tainted arg-0._ | chain root is a non-theta tainted value (`_chainresidual.ll`) | `RotationLowering.cpp:98-135` (chained theta lowers ry-only on the existing handle); `recoverPrepChain`/`emitChainInv` (`ControlledLowering.cpp`) |
| **G3** | **No NON-invertible mutation between prep and merge (WIDENED — u5f).** Grow a CHAIN-NODE set from the bases through (a) theta links below a base and (b) UNCONDITIONAL preps above it — a non-Gate `cq_phi_`/`cq_theta_` on the handle that **dominates** the merge anchor (a `theta-then-cq_phi` prep-Rz, now INVERTIBLE: its `cqrt_rz` is uncomputed by `cqrt_rz_<W>_controlled_inv` in the reverse chain). Every user of every chain node must be another chain node, an in-arm gate body, or the mux φ. Reject any out-of-region / **non-dominating (arm-local)** prep — and, because every chain node dominates the merge and every gate body is in-arm, ANY post-merge-live / cross-region use (the G6 hazard) falls out here. _Was: reject any out-of-`Gates` user._ | a NON-dominating prep, or a chain node read after the merge (`_postmergelive.ll`) | `recoverPrepChain` (`ControlledLowering.cpp`); `muxRegionGate` chain-node fixpoint (`ControlDetection.cpp`) |
| **G3b** | **Per-arm correspondence (ADDED — adversarial review C1, 2026-06-03).** Every in-region gate body that mutates a mux base `q` must live in an arm whose mux-φ edge actually CARRIES `q` (the φ-incoming from that block resolves to `q`). G3a's set-membership (`user ∈ Gates`) is too weak: it admits a gate on `q` sitting in a *non-`q`-selecting* arm, whose controlled `cqrt_rz` fires on a `¬f_q` branch — a stray Rz the single `cqrt_ry_<W>_controlled_inv(¬f_q, q, angle)` cannot undo, leaving `q` entangled with the scrutinee and decohering `regOut` (verify-clean, no diagnostic). | a stray `cq_phi(qy, …)` in the arm that selects `qx` (`wrongarmmut.ll`); the default-base variant `cq_phi(qx, …)` in a case arm (`wrongarmmut_default.ll`) | `muxRegionGate` G3b: `Mux->getBasicBlockIndex(G->getParent())` then `resolveGatedHandleBase(Mux->getIncomingValue(Idx)) == resolveGatedHandleBase(G)` |
| **G4** | **Default arm shape (WIDENED — 5bl).** Admit **either** `HasDefaultGate` (a distinct reconverging default block w/ gate body, controlled on `¬OrAll`) **or** an empty direct-to-merge default (`SwitchDefaultDirect`): the default-selected base's control is the `¬OtherCaseOr` complement bracket the mux already emits (the partition identity — exactly one arm fires per basis state — so no `¬OrAll` value is needed), and the default base rides the `region.Pred` φ edge instead of `region.Arm` (mirroring `reduceAngleSwitchPhi`). _Was: reject `SwitchDefaultDirect`._ | (now lowers — see `_distinct_emptydefault{,_distinctbase}.ll`) | `ControlledLowering.cpp` mux loop `DefaultEdge = SwitchDefaultDirect ? Pred : Arm`; `reduceAngleSwitchPhi` `MergeDissolution.cpp:605-609` |
| **G5** | **Variable-angle dominance (WIDENED — 5bl).** Let `Angle = B->getArgOperand(1)`. Accept if `isa<ConstantFP>(Angle)`. Else: reject a **tainted** angle (never single-`Ry†`-uncomputable); accept an `Argument`/`Constant` (dominates the whole function); accept an `Instruction` iff its def **dominates** `region.MergeBB->getFirstNonPHI()` (the npu.6 `UncomputeAt` anchor) per a detection-time `DominatorTree`. Rotation lowering does not alter the CFG nor move the classical angle def, so the detection-time tree predicts the lowered-form dominance exactly (resolves §8 open-risk #4). _Was: accept only `ConstantFP`._ | arm-local / otherwise non-dominating computed angle (`_distinct_varangle_armlocal.ll`); tainted angle | `cq_theta` arg-1 is an arbitrary `Value*` (`RotationLowering.cpp:112`; `TaintPropagation.cpp:137-151`) |
| **G6** | **Cross-φ base disjointness + region-wide liveness — PERMANENT safety boundary (u5f).** `cqrt_cswap` is a **destructive move** (empties the selected source to `|0⟩`). Compute `MuxBases` = all distinct bases of every mux φ. Decline if any base is also the resolved base of **another** φ in the merge (uniform/angle φ — the explicit cross-φ check), or is used by any instruction reachable from the merge (a downstream `cq_phi`/`cqrt_rz`/`cq_measure` — caught by the G3a chain-node user check, since no post-merge use is a chain node / in-arm gate / mux φ). This is a genuine **no-cloning / which-path hazard** the trace runtime cannot detect, NOT a deferred capability gap — it stays **permanently declined** (the u5f scoping decision; §9). | cross-φ shared-base aliasing (`_crossphi_alias.ll`); **any base live after the merge** (`_postmergelive.ll`) — no-cloning / live-use destruction | `cqrt_cswap` move semantics (`ControlledSymbols.h:74-81`); per-φ + chain-node user check (`ControlDetection.cpp` `muxRegionGate`) |
| **G7** | **Uniform width across mux bases.** Every distinct base of one mux φ must share `taint.HandleWidth`. `cqrt_cswap` is width-agnostic on i32 handle ids, but `cqrt_ry_<W>_controlled_inv` is **width-specialized** — a width mismatch would invert at the wrong width. | distinct bases of differing logical width | `taint.HandleWidth` seeded at `RotationLowering.cpp:134` |

---

## 4. Prerequisites (must exist before any lowering fires)

1. **7 inverse rotation symbols** `cqrt_ry_<W>_controlled_inv` (`i1,i8,i16,i32,i64,f32,f64`) —
   declared in `runtime/cq_runtime.h` and printf-trace-defined in `runtime/cq_runtime.c`,
   mirroring the existing `cqrt_rz_<W>_controlled_inv` block (`cq_runtime.h:145-151`). Today
   there are **0** ry inverses, 7 rz inverses.
2. **`WidthDispatch::ryControlledInvRtFn(StringRef abiWidth)`** next to `ryRtFn`
   (`WidthDispatch.cpp:131`), resolving the width from `taint.HandleWidth[B-handle]` (the
   `§5.6` side-table), **not** the i32-laundered type.
3. `cqrt_cswap(i32,i32,i32)` — already shipped (`ControlledSymbols::cswapFn`).
4. A **region-local `DominatorTree`** at npu.6 emit time for G5.

---

## 5. Atomic landing (non-negotiable)

The gate (G0–G7) **+** the mux (npu.5) **+** the uncompute (npu.6) **+** the 7 inverse symbols
are **one indivisible commit**. Reasons:

- **npu.5 alone is itself a silent miscompile.** `cqrt_cswap` frees only the *selected* source
  per branch; every *non-selected* prepared source stays entangled with the scrutinee
  (which-path garbage that decoheres `regOut` into a mixed state). Verify-clean, no diagnostic,
  invisible to the trace runtime.
- **The gate is part of the atomic unit.** The moment `lowerGatedSwitch` starts emitting
  `cqrt_cswap` for a distinct-base φ (replacing the npu.1 decline at `ControlDetection.cpp:736`
  / the step-4 RAUW at `ControlledLowering.cpp:348-359`), every §3 attack case stops being
  declined by npu.1 and becomes a live miscompile **unless its gate predicate is already
  enforced in the same change.**

Reverting any sub-part must revert to the always-safe npu.1 decline.

---

## 6. Implementation order

1. Add the 7 `cqrt_ry_<W>_controlled_inv` decls + printf-trace defs (mirror the rz block).
2. Add `WidthDispatch::ryControlledInvRtFn` (+ `ControlledSymbols` accessor if needed).
3. In `tryBuildGatedSwitchRegion` (`ControlDetection.cpp:725-738`), replace the bare distinct-base
   decline (`return false`) with: collect distinct bases per φ; when a φ has distinct bases, run
   **G1–G7**; any failure ⇒ `return false` (WP12 decline, unchanged behaviour). Keep **G0** as the
   first/cheapest filter.
4. In `lowerGatedSwitch`, add a distinct-base branch in the step-4 φ loop (replacing the RAUW at
   `:348-359` for the mux φ only): `regOut = cqrt_alloc_<W>(0)`; group incoming **values** by base
   (post-`substituteArm` each incoming is the base handle); `f_q = orFold(ArmFlags of q's selecting
   edges)` (reuse step-2 `ArmFlags`); `cqrt_cswap(f_q, regOut, q)`; RAUW the mux φ → `regOut`.
5. Emit npu.6 uncompute at `UncomputeAt = region.MergeBB->getFirstNonPHI()` (or `AngleAnchor`):
   for each base `q`, `control = ¬f_q` (OR of the *other* bases' selecting flags — see open risk
   on the default-selected base); recover `Angle` from `q`'s already-lowered `cqrt_ry` (the call
   whose arg-0 == `q`; G2 guarantees exactly one); G5 dominance; emit
   `cqrt_ry_<W>_controlled_inv(¬f_q, q, Angle)`.
6. Replace the negative fixture with the positive gate-sequence fixture; add the decline fixtures.
7. Run LIT; confirm all existing gated/multihandle/emptydefault/shared fixtures pass unchanged.

---

## 7. Fixtures

**Positive (gate sequence):**
- `lowering_control_switch_gated_distinct.ll` (**replace** the interim negative): two clean
  single-Ry handles `qx`/`qy`, distinct reconverging default with a gate body. CHECK
  `cqrt_alloc_i32(0)` for `regOut`; per-arm eq-flags; `cqrt_cswap(f_qx, regOut, qx)` +
  `cqrt_cswap(f_qy, regOut, qy)`; `cqrt_ry_i32_controlled_inv(¬f_qx, qx, 5.0e-01)` +
  `cqrt_ry_i32_controlled_inv(¬f_qy, qy, 5.0e-01)`; reverse-LIFO flag uncompute; `CHECK-NOT: switch`,
  `CHECK-NOT: = phi`.
- `lowering_control_switch_gated_distinct_3way.ll`: `case0→qx, case1→qy, case2→qz, default(block)→qx`
  — asserts `f_qx = OR(f0, f_default)` grouping and that `¬f_q` uncompute fires on exactly the
  non-selecting branches.
- `_distinct_varangle.ll` (**5bl, replace the interim negative**): `%a = fadd … ` in `entry`
  (dominates the merge), `%qx = cq_theta(x0, %a)` → **G5 widened, LOWERS**; the qx uncompute
  `cqrt_ry_i32_controlled_inv(¬f_qx, qx, %a)` reuses the same `%a` as the forward prep.
- `_distinct_emptydefault.ll` (**5bl, replace the interim negative**): a direct-to-merge empty
  default distinct mux (`case0→qx, case1→qy`, the `entry`/`Pred` edge carrying default base `qx`)
  → **G4 widened, LOWERS** with no default-gate Rz.
- `_distinct_emptydefault_distinctbase.ll` (**5bl, new**): direct default whose `Pred` edge carries
  a *genuinely default-only* third base `qz` → moves on `¬OtherCaseOr` (the `¬OR` fold), uncomputes
  on the positive fold.

- `_chainedtheta.ll` (**u5f, now POSITIVE**): `qy = cq_theta(cq_theta(y0,.3),.7)` → **G2 widened,
  LOWERS** with a two-element reversed Ry-inverse chain (`ry_inv(qy,.7)` BEFORE `ry_inv(qy,.3)`).
- `_thetathenphi.ll` (**u5f, now POSITIVE**): `qy = cq_phi(cq_theta(y0,.5),.7)` (Ry then Rz) →
  **G3a widened, LOWERS** with a reversed Rz-then-Ry inverse chain (`rz_inv(qy,.7)` BEFORE
  `ry_inv(qy,.5)`).

**Decline (one per gate check):**
- `_selectbase.ll` — a mux edge base `%w = select i1 %c, %qy, %qz` → **G1**.
- `_databasearm.ll` — a mux edge base `%sum = add i32 %qx, %qy` → **G1**.
- `_distinct_varangle_armlocal.ll` (**5bl, new**) — `%b = fadd …` and `%qy = cq_theta(y0,%b)` BOTH
  in case arm `c1` (so `%b` does **not** dominate the merge) → **G5 boundary, DECLINES**.
- `_chainresidual.ll` (**u5f, new**) — `qy = cq_theta(cq_phi(cq_theta(z0,.9),.3),.7)`: the theta
  chain descent stops at a non-theta **tainted** root (`cq_phi(%qz,.3)`) → **G2 boundary, DECLINES**
  (proves the widening did not over-accept).
- `_crossphi_alias.ll` — merge with mux φ `%r` (bases `qx`/`qy`) **and** uniform φ `%sm` (`qy`),
  `%o2` reads `%sm` → **G6 (permanent)**.
- `_postmergelive.ll` (**u5f, new**) — mux base `qy` read DIRECTLY after the merge
  (`%live = cq_phi(qy,.6)`) → **G6 (permanent), DECLINES** (locks the destructive-move /
  post-merge-live boundary the G3a chain-node user check catches).
- (a differing-width mux φ → **G7**.)

Note: the former G4/G5 decline fixtures (`_distinct_emptydefault.ll`, `_distinct_varangle.ll`)
became POSITIVE per the 5bl widening; the former G2/G3 declines (`_chainedtheta.ll`,
`_thetathenphi.ll`) became POSITIVE per the u5f widening. The **G6** declines (`_crossphi_alias.ll`,
`_postmergelive.ll`) are PERMANENT (§9).

**Regression (must still lower / decline byte-identically):**
`_multihandle.ll` (disjoint bases on *separate* uniform φs → step-4 RAUW, no mux), `_emptydefault.ll`,
`_shared.ll`, `_shared_angle.ll`, `_datamux.ll`, `_mixedphi.ll`, `_extrapred.ll`.

---

## 8. Open risks (resolve during implementation)

1. **G3 ordering.** `region.Shadow`/`SwitchArm.Shadow` are populated *after* the discriminator
   loop. Either move the discriminator after shadow collection, or re-check G3 in
   `lowerGatedSwitch`, so an out-of-region mutation can't slip the detection-time check.
2. **G6 SSA identity.** Compute disjointness/liveness on the **pre-substitution** SSA (detection
   time) where bases are still distinct `cq_theta` calls — two genuinely distinct thetas can never
   alias one register, but one base *can* feed two φs; confirm the use-list walk sees the sibling φ.
3. **`¬f_q` for the default-selected base.** For the admitted distinct-reconverging-default case, a
   base selected by the **default** arm is controlled by `¬OrAll`, not by any case eq-flag — ensure
   `¬f_q` references `¬OrAll` for that base so it isn't wrongly uncomputed (the same asymmetry G4
   declines for the direct-default case).
4. **G5 dominance stability.** The lower-vs-decline decision is made at detection time, before a
   `DominatorTree` over the lowered form exists; pin the check to the post-rotation-lowering form and
   decline conservatively if the analysis is unavailable.

---

## 9. Residual general case (stays declined — the spike boundary)

Everything outside §2 stays declined to WP12 (the always-safe npu.1 path). After the **5bl
widening** (G4 direct-default + G5 dominating-variable angle) and the **u5f widening** (G2
chained/multi-Ry preps + G3a theta-then-`cq_phi` preps now lower via the reverse-order multi-op
Bennett uncompute — §3), the residual declined set is: select/branch-φ/data-op/argument bases
(G1), arm-local **non-dominating** or **tainted** angles (G5), chained preps rooted in a non-theta
**tainted** value (G2, `_chainresidual.ll`), cross-φ-shared or post-merge-live bases (G6/G3),
mixed-width muxes (G7). This boundary is **over-decline-safe**: every still-excluded shape is
either ill-defined for the (now multi-op) inverse — an entangled-rooted prep chain has no
classical `U†` — or carries a register-aliasing/which-path hazard the trace runtime cannot detect
(G6/G3). The G1/G5/G2-tainted-root cases are genuine capability gaps; **G6 is a PERMANENT boundary**
(next paragraph), not a deferred quick win.

**G6 is a PERMANENT safety boundary, not a deferred capability gap (u5f scoping decision,
2026-06-03).** Unlike G2/G3 (a missing multi-op uncompute, now supplied) or G1/G5/G7 (analysis
gaps a future increment could close), the G6 decline — a mux base that is **also read by a sibling
φ** (cross-φ-shared) or **live after the merge** (post-merge-live) — is a genuine **no-cloning /
which-path hazard with no correct lowering**. `cqrt_cswap` is a DESTRUCTIVE MOVE: it empties the
selected source to `|0⟩`, so a base also consumed elsewhere would be read as garbage. There is no
uncompute or gate sequence that can both move a register's state out AND leave it intact for a
second consumer (that is precisely the no-cloning theorem). Lowering G6 would be the exact
verify-clean silent-miscompile cardinal sin this subsystem exists to prevent. G6 therefore stays
declined **permanently** — it is locked by two regression fixtures (`_crossphi_alias.ll`,
`_postmergelive.ll`) and is **not** tracked as deferred work. The u5f widening deliberately drew
the line: an unconditional prep op BEFORE/dominating the merge and fully consumed inside the region
is INVERTIBLE (accept); a use AFTER the merge or shared with a sibling φ is the G6 hazard (decline).

---

## 10. Cross-region nested-merge safety guard (5bl adversarial-review fallout)

`lowerControlledRegions` lowers the detected `ControlRegion`s **sequentially**, and a region's
linearization **erases its `MergeBB`**. A controlled region whose **`Pred` block IS another
region's `MergeBB`** — a controlled construct nested directly in an enclosing controlled region's
merge block (back-to-back quantum-controlled `switch`es, or a gated switch in a tainted-`if` merge;
the shape clang `-O1` emits for consecutive controlled statements) — therefore has its `Pred` freed
when the enclosing region linearizes, and lowering it next **dereferences a stale block** → a hard
use-after-free **SIGSEGV on valid input**. This is **pre-existing** (uniform / branch nestings hit
it too), but the G4 direct-default widening **newly routed** a distinct-base mux into it (the
distinct-base `SwitchDefaultDirect` shape was previously declined outright at G4, so the second
region was never built).

Because over-declining is always safe but a crash regression is not, `detectControlRegions` ends
with a guard: collect **every** region's `MergeBB`; for any region whose `Pred` is in that set,
fire the loud WP12 `...under quantum control` diagnostic and **drop it from the plan** (done while
all blocks are still valid). The key is over EVERY region kind (branch + switch), not just
SwitchRegions, since the widening's new mux region can be **either** the inner (its `Pred` = an
enclosing region's merge) **or** the enclosing one (its merge = an inner region's `Pred`) — the same
`inner.Pred == outer.MergeBB` relation, caught from the inner by the one `Pred ∈ {merges}` test.
Regressions: `lowering_control_switch_gated_distinct_nestedmerge{,_branch}.ll`. A future increment
could lower these by inner-first region ordering or post-linearization region re-discovery.

**Scope boundary — what this guard does NOT cover (intentionally).** The 5bl re-review surfaced a
**separate, pre-existing** UAF (issue `test_C_libtooling-ehf`, **not** a 5bl regression — it
reproduces on baseline and involves no mux/G4/G5): two tainted `if`-diamonds reconverging on ONE
**shared** merge block (`matchDiamond`/`matchSymmetricDiamond` lack the merge extra-predecessor check
the gated-switch path has, so they admit a shared merge; the first lowered erases it, the second
dereferences it). It is deliberately **not** folded into this guard: a `MergeBB`-shared-by-≥2-regions
test would wrongly decline the legitimate **nested-AND** (`if(a){if(b)…}`), which detection
represents as a *coordinated* region pair — the inner diamond's `Pred` equals the outer region's
`Mid` — that shares its merge yet lowers correctly (`lowering_control_angle_nested_and.ll`). The
proper fix (mirror the switch extra-predecessor check into the diamond paths) is tracked in `ehf`. A
distinct-base mux can never *share* a merge (the switch path rejects extra merge predecessors), so
the G4 widening cannot reach the shared-merge UAF — only the `Pred == MergeBB` nesting this guard
covers.
