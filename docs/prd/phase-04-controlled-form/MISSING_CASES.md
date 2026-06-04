# Phase 4 — Tainted-conditional missing cases & boundaries

A companion to the Phase 4 [`PRD.md`](PRD.md) / [`IMPLEMENTATION.md`](IMPLEMENTATION.md)
that catalogues, for every **tainted conditional** (a `br i1` / `select` /
`switch` whose condition is quantum-tainted), exactly which shapes are **not**
lowered and **why** — separating the **permanent boundaries** (correct to reject
forever) from the **deferred capability gaps** (a later roadmap stage closes
them with a known technique).

This doc exists to answer one question precisely: *are only the desired
exceptions excluded?* The audited answer is **yes** — every exclusion is either
a permanent correctness boundary or a knowingly-deferred, over-decline-safe
reject. There is no silent-miscompile hole and no accidental gap.

Companion documents:
- [`PRD.md`](PRD.md) §8.6 — the quantum-controlled **escape** verdict
  (measurement / `return` / `break` / `goto`); the permanent-reject list.
- [`../../npu6-mux-exch-gate-spec.md`](../../npu6-mux-exch-gate-spec.md) §9/§10 —
  the MUX-EXCH residual + the G6 permanent no-cloning boundary.
- [`../../bennett-jl-comparison.md`](../../bennett-jl-comparison.md) — the
  Bennett/Sturm/Silq/QCM cross-check separating permanent rejects from deferred
  catch-up items.
- [`../../../ROADMAP.md`](../../../ROADMAP.md) — phase sequence; the post-freeze
  **Memory model** entry (out-of-scope-for-v1.0 section).

---

## 1. Conventions — the three outcomes

Every tainted conditional resolves to exactly one of:

| State | Meaning | Surface |
|---|---|---|
| **LOWERED** | rewritten to controlled-form (`cqrt_*_controlled`, controlled-rotation-by-difference, MUX-EXCH, …) | silent success, `opt -verify` clean |
| **DECLINED-PERMANENT** | a *desired exception* — correctness-by-construction; no unitary lowering exists | loud `DiagnosticInfoUnsupported(DS_Error)` |
| **DECLINED-DEFERRED** | a capability gap a later stage closes with a known technique | the **same** loud diagnostic |

Both declined states emit the same contract: a hard
`error: cq controlled lowering: <what> under quantum control` (the
`diagnoseEscape` family, [`ControlDetection.cpp:51`](../../../ir-pass/src/ControlDetection.cpp)),
never a silent fallthrough. **Over-decline discipline:** when a shape cannot be
*proven* safe to lower, it declines — over-declining only keeps a byte-identical
safe path, while wrongly admitting one input is a verify-clean miscompile
invisible to the trace runtime. This is why "deferred" and "permanent" share a
surface: from the user's seat both are a clean, source-located reject; the
distinction below is about *whether a future stage can ever turn it green.*

---

## 2. Permanent boundaries — desired exceptions (NOT backlog)

These are correct to reject **forever**. They are listed here only so the
backlog in §3 is unambiguous about what it does *not* contain. Each is backed by
a physics impossibility (no injective unitary), not an implementation limit.

| # | Shape | Diagnostic | Why permanent | Anchor |
|---|---|---|---|---|
| P1 | **Measurement** in a tainted-controlled arm | `measurement under quantum control` | A measurement gated on a superposed predicate is non-injective (QCM, arXiv:2304.15000); `-fcq-measurement-bridge` *demotes the region to classical* — a different program, not a lowering. | `ControlDetection.cpp:323,408`; PRD §8.6; `lowering_control_escape_measure.ll` |
| P2 | **`return`** in a tainted-controlled arm | `return under quantum control` | A `ret` is a zero-successor exit that can never reconverge → violates QCM synchronization; a superposed return is non-injective. | `ControlDetection.cpp:319,405`; `lowering_control_escape.ll` |
| P3 | **Non-reconverging escape** (`break`/`goto` out of region) | `control-flow escape under quantum control` | Reached only *after* the well-formed fall-through-to-merge is handled → by construction the non-reconverging exit. | `ControlDetection.cpp:327`; `lowering_control_escape_{break,goto}.ll` |
| P4 | **Classical side effect** in a flat-diamond arm | `classical side effect under quantum control` | CFGLinearization splices the arm body **unconditionally** (control is realized only by rewriting `cq_phi`→`cqrt_*_controlled`); a host effect would fire on every path. No `cqrt_*_controlled` exists for an arbitrary host effect, and it cannot be conditionalized on a quantum control without measuring (collapsing) it. (bd `npu.3`, locked permanent.) | `ControlDetection.cpp:352`; `lowering_control_escape_classical_sideeffect.ll` |
| P5 | **Classical side effect** in a nested-AND `Mid` guard | `classical side effect under quantum control` | The Mid-block twin of P4: `linearizeNested` erases the outer branch then splices `Mid` unconditionally into `Pred`. | `ControlDetection.cpp:614`; `lowering_control_escape_classical_sideeffect_nested.ll` |
| P6 | **G6 — cross-φ-shared / post-merge-live distinct-base mux** | `switch under quantum control` (WP12) | **No-cloning.** Mux bases are Ry superpositions ([`backend.md`](../../backend.md) §"Ry rotation; taint source"). The destructive-move lowering (`cqrt_cswap`, empties the source to \|0⟩) corrupts the live/shared use; the non-destructive additive-copy fan-out (`MergeDissolution.cpp:330`) *entangles* the surviving source `(α\|0⟩+β\|1⟩)\|0⟩→α\|0⟩\|0⟩+β\|1⟩\|1⟩`, decohering it **and injecting a spurious EPR correlation that corrupts joint measurement statistics even for basis-only consumers**. No coherence-preserving non-cloning copy exists or can exist. Locked in the same commit that *widened* G2/G3 (2826560). | spec §9:240–252; `ControlledSymbols.h:83`; `ControlDetection.cpp` `muxRegionGate`; `lowering_control_switch_gated_distinct_{crossphi_alias,postmergelive}.ll` |
| P7† | **Raw `load`/`store` dereferencing a bare handle pointer** | `memory addressing / load / store under quantum control` | A handle is an i32 *allocation-counter id*; dereferencing it indexes host memory at the counter → garbage. Permanent **under the v1.0 register-handle ABI** — an ABI invariant, not a physics theorem. | `ControlDetection.cpp:223` (`diagnoseTaintedMemoryEscape`) |

**† P7 is ABI-scoped, not physics-scoped.** Unlike P1–P6 it could change *if the
ABI changed* (a future quantum-memory model). The *structured* quantum-indexed
forms it currently catches alongside the raw deref are deferred — see D1. The
guard's comment (`ControlDetection.cpp:218`) should ideally be split to say
"permanent for raw handle-pointer dereference; deferred for structured
quantum-indexed tables (QROM/MUX-EXCH)" so it does not read as wholesale
permanent. (Comment precision only; no behavior change.)

---

## 3. Deferred capability gaps — the backlog

Every entry below is **declined-deferred**: a clean reject today, closeable later
by the named technique. Grouped by what unblocks it. Confidence is on the
*permanent-vs-deferred classification*, not on effort.

### D1 — Quantum-indexed memory (post-freeze **Memory model** stage)

| | |
|---|---|
| **Shape** | A tainted value as a `getelementptr` index / `load`/`store` pointer — most importantly the `-O1` handle-indexed table `arr[q]` (constant or runtime array) that is *not* the already-handled constant-`double` angle-table shape. |
| **Diagnostic** | `memory addressing / memory load / memory store under quantum control` |
| **Anchor** | `ControlDetection.cpp:223`; declines locked by `lowering_control_switch_jumptable_{nonconst,sideeffect,loadreuse}.ll` |
| **Closing technique** | **QROM** for constant tables, **MUX-EXCH** for runtime tables (Babbush et al. 2018, arXiv:1805.03662; [`bennett-jl-comparison.md`](../../bennett-jl-comparison.md)). |
| **Already closed sub-case** | The canonical constant-`double` angle table `arr[q]` **already lowers today**, pre-detection, via `normalizeJumpTableAngle` ([`SwitchNormalization.cpp:171`](../../../ir-pass/src/SwitchNormalization.cpp); fixture `lowering_control_switch_jumptable.ll`). This is the proof D1 is progressive lowering, not a wall. |
| **Unblocked by** | Post-freeze **Memory model** phase — `load`/`store`/`getelementptr` lowering + QRAM/QROM/Shadow/MUX template selection ([`ROADMAP.md`](../../../ROADMAP.md), "Beyond the freeze"). Needs the runtime template surface (Phase 8) frozen first. |
| **Confidence** | high |

### D2 — Angle-completeness (Phase 4.x, pass-side, WP16 extension)

| Gap | Shape | Current diagnostic | Closing technique | Conf |
|---|---|---|---|---|
| **D2a** Non-mutually-exclusive angle if-else-if chain | A clean angle select-chain whose false-arm conditions are **not** eq-on-one-scrutinee-with-distinct-constants, so `base + Σ fₖ·(aₖ−base)` is invalid without guards | `rotation angle under quantum control` (`ControlDetection.cpp:1158`, guarded by `isMutuallyExclusiveAngleChain`; `lowering_control_angle_chain_nonexcl.ll`) | Generalize `reduceAngleSelectChain` to emit cumulative AND-NOT (`¬prior-cases`) guards per case; or normalize to mutually-exclusive eq-flags upstream | high |
| **D2b** Mixed / ≥3-way angle merge φ | A diamond/nested-AND angle φ whose two `flag==0` edges carry **different** base angles (cannot collapse to base + single controlled difference) | `rotation angle under quantum control` (`ControlDetection.cpp:939,1250,1424`; `lowering_control_angle_diamond_mixed_reject.ll`) | N-way controlled-difference: treat the multi-base angle φ as nested 2-way dispatches, one `Rz_controlled` per `(flag, aₖ−base)` — the gated-switch angle machinery generalized to br-diamond | medium |

Note: unlowerable-*type* angle φ (vector / i128 / ptr / `cq_theta` operand) is a
distinct sub-case of the same diagnostic site and is closer to a permanent typing
limit than a deferred shape — track separately if pursued.

### D3 — Switch-completeness (Phase 4.x, pass-side, WP18 extension)

| Gap | Shape | Current diagnostic | Closing technique | Conf |
|---|---|---|---|---|
| **D3a** Gated-switch non-tainted-incoming value merge | A gated `switch` whose value-merge φ has any non-tainted incoming (all-classical data mux, or a handle/constant mix) — step-4 RAUW-to-handle would silently drop the non-handle edges, so it declines | `switch under quantum control` (`ControlDetection.cpp:919`→`1215`; `lowering_control_switch_gated_{shared,shared_angle,mixedphi}.ll`) | A gated-switch data-mux lowering analogous to the br-diamond `reduceClassicalMux` (per-case controlled add of case-value−base); requires distinguishing a value-propagated-constant-equal-to-handle from a genuine distinct value | medium |
| **D3b** Raw tainted `switch` with no gated shape | A tainted-scrutinee `switch` matching no gated-switch shape (WP12 fallback) | `switch under quantum control` (`ControlDetection.cpp:1215`) | `-lowerswitch` / closed-diamond decomposition into the existing gated-switch path | medium |

### D4 — Escape-lowering, bounded+reconverging subset (Phase 4.1 `-aht.2` follow-up)

| | |
|---|---|
| **Shape** | A **bounded, reconverging** quantum-controlled `break`/`goto`/`return` — i.e. the subset of P2/P3 that *does* synchronize at the post-dominator join (as opposed to the non-reconverging exits, which are permanent). |
| **Diagnostic** | `control flow under quantum control` (`ControlDetection.cpp:1389`) |
| **Closing technique** | **Done-flag (guard-qubit) predication**: predicate the reversible register writes on a `¬done` ancilla so the construct reconverges (PRD §8.6; classical if-conversion / QCM Tower analogue). Strictly the bounded+reconverging slice — the non-reconverging exit stays P2/P3. |
| **Unblocked by** | A guard-qubit ancilla mechanism; pass-side but design-gated. |
| **Confidence** | high (that the *bounded* slice is deferrable; the non-reconverging complement is permanent) |

### D5 — Region orchestration: shared-merge UAF (Phase 4.x, pass-side)

| | |
|---|---|
| **Shape** | Two tainted if-diamonds reconverging on **one shared merge block**, or a controlled region whose `Pred` is another region's `MergeBB` (nested-in-merge). Sequential linearization frees the shared/`Pred` block → use-after-free. |
| **Diagnostic** | `control flow / switch under quantum control` (`ControlDetection.cpp:1486`, the `IsNestedInMerge` over-decline) |
| **Status** | **Safe over-decline**, not a miscompile — it rejects a shape that would otherwise crash (UAF), and is carefully scoped to **not** reject the legitimate nested-AND shared-merge `if(a){if(b)}`, which lowers correctly. Locked by commit `22fcc16`; fixtures `lowering_control_diamond_shared_merge.ll`, `lowering_control_switch_gated_distinct_nestedmerge{,_branch}.ll`. |
| **Closing technique** | Order-independent / clone-or-defer linearization of the shared merge block, or extend matchDiamond/matchSymmetricDiamond with the merge extra-predecessor check the gated-switch path already has. |
| **Confidence** | high |

---

## 4. Two narrow carve-outs (precision footnotes)

These keep §2/§3 from over-claiming at the edges:

1. **Memory model (D1) vs the raw-deref invariant (P7).** The same
   `diagnoseTaintedMemoryEscape` guard fires for two physically different things:
   structured quantum-indexed tables `arr[q]` (**deferred** — D1, has QROM/MUX-EXCH)
   and a raw dereference of a bare handle pointer (**permanent under v1.0 ABI** —
   P7). The roadmap reserves the former; only the latter is by-construction. A
   one-sentence comment split at `ControlDetection.cpp:218` would remove the
   ambiguity.

2. **G6 (P6) vs the basis-state degenerate slice.** G6 is permanent for
   superposition bases (the default and every current fixture, `Ry(0.5)`). A base
   *provably* in a computational-basis state at the merge (just-measured, or
   `Ry(0)`/`Ry(π)` only) would make the additive-copy fan-out a legitimate
   reversible copy — a **hypothetical** future capability gap gated on a
   basis-state-provability static analysis the project does not have and which
   matches **no** current G6 fixture. If ever pursued it belongs here in §3 under
   that predicate; it is **not** the locked G6 region, which stays in §2.

---

## 5. Sequencing note

Per the audit conclusion, none of §3 is blocking and none is a correctness risk
today — each is a clean reject waiting for the stage that supplies its technique:

- **Pass-side incremental (Phase 4.x), any time:** D2, D3, D5.
- **Design-gated, pass-side:** D4 (needs the guard-qubit ancilla mechanism).
- **Post-freeze infrastructure:** D1 (needs the Memory model phase + frozen
  runtime template surface).

The natural order is to close the pass-side angle/switch/region gaps (D2/D3/D5)
opportunistically alongside later phases, take D4 when the ancilla mechanism
lands, and leave D1 for the post-freeze Memory model phase as the roadmap already
schedules.

---

*Audit basis: 7-reader shape map (308 records → 115 lowered / 193 declined) with
per-decline adversarial classification, plus a prosecutor/defender/judge
resolution of the two contested calls (memory-address → deferred; G6 →
permanent), 2026-06-04. Verdicts cross-checked against the live fixtures under
`ir-pass/test/lowering_control_*.ll`.*
