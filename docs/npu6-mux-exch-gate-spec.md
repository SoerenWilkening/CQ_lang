# npu.6 — MUX-EXCH uncompute safety gate (design spec)

**Status:** IMPLEMENTED (npu.5 + npu.6 landed atomically). A distinct-per-case-handle gated
switch that passes the conservative G0–G7 gate now lowers MUX-EXCH (`regOut = cqrt_alloc(0)` +
per-base `cqrt_cswap` MOVE + per-non-selected-source `cqrt_ry_<W>_controlled_inv` uncompute);
everything else still declines to the always-safe WP12 diagnostic. The detection gate lives in
`muxBasePreconditions`/`muxRegionGate` (`ControlDetection.cpp`), the lowering in `lowerGatedSwitch`
(`ControlledLowering.cpp`), and `region.MuxExch` carries the decision. **Implementation addendum
(adversarial review C1, 2026-06-03): G3 gained a per-arm-correspondence clause `G3b` — see §3.**

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

After this increment, the *only* distinct-base gated-switch multiplexer that lowers is:

> a tainted-scrutinee `switch` with a **distinct reconverging default block carrying a gate
> body** (`HasDefaultGate == true`, **not** `SwitchDefaultDirect`); **exactly one** mux φ in
> the merge whose **every distinct base is a direct `cq_theta` with a classical (untainted)
> arg-0** (a single `Ry` prep); a **`ConstantFP` or merge-dominating** prep angle; **no extra
> mutation** between prep and merge other than in-arm controlled gate bodies; **every mux base
> of one shared logical width**, **disjoint** from all sibling-φ bases and **dead after the
> merge**.

Everything else **declines** to WP12 (§5).

---

## 3. The gate (run in order; first failure ⇒ decline). Detection-time, in
`tryBuildGatedSwitchRegion` (`ir-pass/src/ControlDetection.cpp` ~725–738), where the form is
still pre-lowering (detection runs before `lowerRotations`, `CQLoweringPass.cpp:72` before `:76`).

| # | Check | Declines | Evidence |
|---|---|---|---|
| **G0** | **Structure/identity (shipped npu.1, kept verbatim, runs first).** Every non-angle φ incoming is `taint.Tainted`; `resolveGatedHandleBase(In)` is identical across one φ's edges. The mux fires only for a φ with **distinct** bases; uniform-base φ stays the step-4 RAUW path. | constant / `cq_measure` / all-classical incomings (fail the taint test) | `ControlDetection.cpp:725-737`; `TaintPropagation.cpp:135,152` |
| **G1** | **Base is a direct `cq_theta` prep.** Each distinct base `B = resolveGatedHandleBase(In)` must be a `CallInst` whose callee `starts_with("cq_theta_")` (≡ `B ∈ taint.ThetaCalls`). Reject `SelectInst`/`PHINode`/`Argument`/any non-theta tainted instruction. | dissolveSelect/branch-φ mux output, classical-data arm (`add`/`sub`/`zext` of handles), function-arg or any non-theta base | `resolveGatedHandleBase` only unwraps `cq_phi_` and returns the first non-`cq_phi` value with no Ry check (`:83-95`) |
| **G2** | **Single-Ry prep (classical arg-0).** For each base `B` (a `cq_theta_` call): require `taint.Tainted.count(B->getArgOperand(0)) == false`. A tainted arg-0 is a **chained theta-of-theta** → two `cqrt_ry` on one handle → a single `Ry†` leaves residual `Ry`. | chained `cq_theta(cq_theta(...))` multi-Ry prep | `RotationLowering.cpp:98-118` (chained theta lowers ry-only on the existing handle; classical arg-0 mints a fresh handle + one `cqrt_ry` at `:119-135`) |
| **G3** | **No extra mutation between prep and merge.** Every user of `B` and of every node on the unwrap chain (φ-incoming → … → `B`) must be either an in-arm gate body (`cq_phi_` in `region.Shadow`/`SwitchArm.Shadow`/`AngleConsumers`) or the φ-incoming itself. Reject a `theta-then-cq_phi` prep (`Ry` then `Rz` — `cq_phi` lowers to `cqrt_rz`, leaving Rz garbage the Ry† won't undo) or any out-of-region mutation. | `cq_phi(cq_theta(y0,a),c)` (Ry then Rz) prep; out-of-region mutation of the base | `resolveGatedHandleBase` unwraps `cq_phi` which lowers to `cqrt_rz` (`:89`) |
| **G3b** | **Per-arm correspondence (ADDED — adversarial review C1, 2026-06-03).** Every in-region gate body that mutates a mux base `q` must live in an arm whose mux-φ edge actually CARRIES `q` (the φ-incoming from that block resolves to `q`). G3a's set-membership (`user ∈ Gates`) is too weak: it admits a gate on `q` sitting in a *non-`q`-selecting* arm, whose controlled `cqrt_rz` fires on a `¬f_q` branch — a stray Rz the single `cqrt_ry_<W>_controlled_inv(¬f_q, q, angle)` cannot undo, leaving `q` entangled with the scrutinee and decohering `regOut` (verify-clean, no diagnostic). | a stray `cq_phi(qy, …)` in the arm that selects `qx` (`wrongarmmut.ll`); the default-base variant `cq_phi(qx, …)` in a case arm (`wrongarmmut_default.ll`) | `muxRegionGate` G3b: `Mux->getBasicBlockIndex(G->getParent())` then `resolveGatedHandleBase(Mux->getIncomingValue(Idx)) == resolveGatedHandleBase(G)` |
| **G4** | **No direct-to-merge default for a distinct-base mux φ.** Reject if `SwitchDefaultDirect` (compute `DefaultDirect` locally — `region.SwitchDefaultDirect` is set later) and the merge has a distinct-base φ. Admit only when `HasDefaultGate` (distinct default block w/ gate body) so `OrAll` and the `¬OrAll` bracket exist. | direct-to-merge (empty) default distinct-handle multiplexer (a default-selected base with no flag) | `ControlledLowering.cpp:327-333` (`OrAll` stays null when `!HasDefaultGate`) |
| **G5** | **Variable-angle dominance.** Let `Angle = B->getArgOperand(1)`. Accept if `isa<ConstantFP>(Angle)`; else require `Angle`'s def to **dominate** `region.MergeBB->getFirstNonPHI()` (the npu.6 `UncomputeAt` anchor), via `DominatorTree`. | arm-local / computed prep angle not dominating the merge uncompute point | `cq_theta` arg-1 is an arbitrary `Value*` (`RotationLowering.cpp:112`; `TaintPropagation.cpp:137-151`) |
| **G6** | **Cross-φ base disjointness + region-wide liveness.** `cqrt_cswap` is a **destructive move** (empties the selected source to `|0⟩`). Compute `MuxBases` = all distinct bases of every mux φ. Decline if any base is also the resolved base of **another** φ in the merge (uniform/angle φ), or is used by any instruction reachable from `region.MergeBB->getFirstNonPHI()` (a downstream `cq_phi`/`cqrt_rz`/`cq_measure`). | cross-φ shared-base aliasing; **any base live after the merge** (no-cloning / live-use destruction) — **this is the liveness angle** | `cqrt_cswap` move semantics (`ControlledSymbols.h:74-81`); the shipped gate is per-φ (`ControlDetection.cpp:725`) |
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

**Decline (one per gate check):**
- `_chainedtheta.ll` — `qy = cq_theta(cq_theta(y0,0.3),0.7)` → **G2**.
- `_thetathenphi.ll` — `qy = cq_phi(cq_theta(y0,a),c)` (Ry then Rz) → **G3**.
- `_selectbase.ll` — a mux edge base `%w = select i1 %c, %qy, %qz` → **G1**.
- `_databasearm.ll` — a mux edge base `%sum = add i32 %qx, %qy` → **G1**.
- `_distinct_emptydefault.ll` — distinct multiplexer with default routed straight to merge → **G4**.
- `_varangle.ll` — `%a = fadd …` in a case arm, `%qx = cq_theta(x0, %a)` → **G5**.
- `_crossphi_alias.ll` — merge with mux φ `%r` (bases `qx`/`qy`) **and** uniform φ `%sm` (`qy`),
  `%o2` reads `%sm` → **G6**.
- (a differing-width mux φ → **G7**.)

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

Everything outside §2 stays declined to WP12 (the always-safe npu.1 path): direct-to-merge default
with distinct handles (G4), chained/multi-Ry or theta-then-gate preps (G2/G3), select/branch-φ/data-op/
argument bases (G1), variable non-dominating angles (G5), cross-φ-shared or post-merge-live bases (G6),
mixed-width muxes (G7). This boundary is **over-decline-safe**: every excluded shape is either
ill-defined for the single-`Ry†` inverse or carries a register-aliasing/which-path hazard the trace
runtime cannot detect. The most notable deferral is the **direct-default-with-distinct-handles** case
— it needs the `reduceAngleSwitchPhi`-style unconditional-base asymmetry (`MergeDissolution.cpp:605-609`)
ported to handles, a separate follow-on.
