# Phase 4 PRD — IR pass: RSSA swap-routed tainted control flow

Phase-specific design decisions, scope, and done criteria for lowering tainted
(quantum-dependent) `br` / `phi` by **routing data, not controlling gates**. This
PRD covers the **4.1 increment — phase arms (`Rz`)** in full, and records the
binding decisions for the later increments (4.2 value arms, 4.3 nested, 4.4
`select`, 4.5 `switch`) so they survive between sessions and across the freeze.
The old **controlled-op** Phase 4 shipped and was removed wholesale (commit
`7cde677`); this PRD replaces its archived predecessor
([`docs/archive/old-design/phases/phase04-controlled-form/`](../../archive/old-design/phases/phase04-controlled-form/)).
It is a lean PRD — it memorializes the PRD-discovery decisions; the module-layout
/ fixture / commit-shape plan lands later as `IMPLEMENTATION.md` alongside it.

Companion documents:
- [`ROADMAP.md`](../../../ROADMAP.md) §Phase 4 — phase scope, increments, place in
  the sequence (revised 2026-06-09).
- [`docs/design/rssa-swap-control/SCOPING.md`](../../design/rssa-swap-control/SCOPING.md)
  — the detailed spec; §3a (flag-strip vs copy-out), §3b (free discipline), §3c
  (the rejection), §6a (control-in-place), §7 (open questions). Revised 2026-06-09.
- [`docs/design/rssa-swap-control/OVERVIEW.md`](../../design/rssa-swap-control/OVERVIEW.md)
  — the concise pitch.
- IR target fixtures: `swap_route_if_diamond.ll`, `swap_route_ifelse.ll`,
  `swap_route_if_diamond_uncompute.ll`, `swap_route_reject_clobber.ll` (under
  `docs/design/rssa-swap-control/`).
- [`docs/backend.md`](../../backend.md) §9–10 — the live `EmitInverse` / `FreePoint`
  uncompute spine this phase reuses (`CLAUDE.md` Rule 14).
- [`docs/quantum-classical-handling.md`](../../quantum-classical-handling.md) —
  taint as the Q/C boundary.

---

## 0. Invariant recap (not new — the ground Phase 4 stands on)

> **A quantum register reference is always an `i32` handle; a tainted `br i1`/`phi`
> is control over quantum state and must NEVER reach the backend as classical
> control. Coherence is established by statevector/trace reasoning, never by
> `opt -verify` (`CLAUDE.md` Prime Directive).**

Two physics facts pin the lowering and are stated once:

- **`Rz = diag(1, e^{iθ})`** (phase-gate convention; author decision 2026-06-09).
  `Rz|0⟩ = |0⟩` exactly, and `Rz` preserves a register's computational-basis
  **value** (it changes only phase).
- **`cqrt_free` is a reset = projective measurement on real hardware.** Freeing a
  rail not provably `|0⟩` is a hidden measurement that collapses `q` — forbidden by
  the "no added measurement" invariant.

---

## 1. Scope

**In scope — the 4.1 increment (phase arms).** Lower a tainted-condition `br i1`
diamond and `if/else` whose arm bodies are **phase rotations** (`cq_phi` → `Rz`),
by swap-routing:

1. **Mint the flag.** The `br` condition compare (e.g. `icmp sgt %q, 5`), today
   left untouched (Phase 3 §2.8), is lowered to its `_hl` **data** template,
   producing the `i32` flag handle.
2. **Route in.** `cqrt_alloc_<W>(0)` a `|0⟩` work rail per arm; `cqrt_cswap(flag,
   q, rail)` routes the operand in (the `if/else` else-arm uses a self-inverse
   `cqrt_x(flag)` bracket for the ¬flag control).
3. **Run the arm body verbatim and uncontrolled** on the rail (`cqrt_rz_<W>`).
4. **Route back.** `cqrt_cswap(flag, q, rail)` — the `phi` is the adjoint of the
   split, sharing `%flag`.
5. **Free the rail.** `Rz|0⟩ = |0⟩` ⇒ the rail is `|0⟩` unconditionally → clean
   `cqrt_free` (a no-op reset, not a measurement).
6. **Strip the flag.** `Rz` preserves `q`'s basis value, so `icmp(q) == icmp(q0)`;
   `cq_template_icmp_…_hl_inv(q, …)` returns the flag ancilla to `|0⟩`, then
   `cqrt_free` reclaims it. **Zero controlled gates, no preserved `q0`.** `q` is
   left with the conditional phase, disentangled and interference-safe.
7. **Flatten.** Erase the tainted `br`, the merge `phi`, and the arm/merge blocks;
   emit the stream into one straight-line block (provenance in value names —
   `%arm.t`, `%else.e`). The pass flattens itself (the `-O0` link will not).

Targets: the regenerated coherent `swap_route_if_diamond.ll` /
`swap_route_ifelse.ll`. **No new runtime ABI** — reuses `cqrt_cswap`,
`cqrt_alloc_<W>`, `cqrt_free`, `cqrt_rz_<W>`, `cqrt_x`, and the `icmp`
`_hl`/`_hl_inv` templates.

**Also in 4.1 — the §3c reject** (decision 2.5): a value-clobber of a condition
operand declines loudly. Vacuous for phase arms, but shipped with its decline
fixture + adversarial probe (Rule 12).

**Out of scope (later increments / §5).** Value-/permutation-arm method-B +
`cqrt_copy_<W>` (4.2); nested control (4.3); `select` (4.4); `switch` (4.5);
control-in-place §6a peephole; controlled `return`/`break`; `Ry` coherent reuse.

---

## 2. Design decisions

Each was resolved in PRD-discovery (2026-06-09, statevector-checked) and is binding.

### 2.1 Phase-arm coherence is a flag-strip, not method-A, not reverse-play

The earlier "method-A" (route uncontrolled, then **controlled-adjoint** clean the
inactive rail) is **dropped**: emitting a controlled gate to clean a rail buys
nothing over controlling the op in place (§6a). Instead, for a phase arm the rail
is `|0⟩` for free (`Rz|0⟩ = |0⟩`) and the flag is stripped with the **uncontrolled**
`icmp_inv(q)` (valid because `Rz` preserves `q`'s basis value, so `icmp(q) ==
icmp(q0)`). The whole 4.1 lowering emits **no controlled gate and no eager
reverse-play**. Statevector check (`if(q==1) rz(q,θ)`): `(|0⟩+|1⟩)/√2 ⊗ |0⟩_f →
(|0⟩|0⟩_f + e^{iθ}|1⟩|1⟩_f)/√2 →[icmp_inv] (|0⟩ + e^{iθ}|1⟩)/√2 ⊗ |0⟩_f`.

### 2.2 No measurement added — enforced by "never free a non-`|0⟩` rail"

`cqrt_free` is emitted **only** where the rail is provably `|0⟩` (phase arm:
immediately after route-back; value arm: after method-B reverse-play). A rail not
provably `|0⟩` is **left allocated** (a qubit leak, accepted in the §0 qubits-not-
scarce regime), never freed. This inverts the struck "v1" bug, which freed dirty
rails. The `FreePoint` post-dominator discipline (never on `Escaped`/`Measured`)
gates the free, reusing the live Phase-5 spine.

### 2.3 Reverse-play is the on-demand undo, not an eager step

The full-region adjoint (via `emitInverseChain`) restores `q0` and zeros every
ancilla exactly, for *any* arm. It is emitted when the user inverts the region
(`cq_invert`, Phase 7) or an oracle uncomputes — **not** by the forward lowering.
This supersedes the 2026-06-08 "reverse-play mandatory in every increment." A
useful corollary: because reverse-play restores `q0` *before* the flag uncompute,
the data-derived `icmp_inv` is valid there for any arm — dissolving the
2026-06-08 `Ry` §7.3 worry.

### 2.4 The flag is a data `_hl` template result; the emitter owns the arm gates

The `br`-condition compare is lowered to its `_hl` template **by the control
emitter**, reversing the Phase-3 §2.8 "leave `br`-feeding compares untouched" rule
for tainted conditions. Detection is **pure SSA-value analysis before any
mutation** (Rule 9), so region/clobber membership survives the rotation lowering's
RAUW-to-handle.

**Ordering + the `InShadow` seam (binding).** A new mutating control step
(`lowerControlRegions`) runs **after `detectControlRegions`, before
`lowerRotations`/`lowerOps`**. Detection populates `plan->InShadow` with the arm
`cq_phi` calls — the single `ControlPlan` field the live pipeline already reads
(`RotationLowering.cpp` skips any in-shadow gate), reused per Rule 14. The control
step emits each arm rotation **verbatim on the routed rail** (`cqrt_rz_<W>(rail,
θ)`, reading θ from the original `cq_phi`) and **erases the originals**, so they
never reach `lowerRotations` as uncontrolled rotations on `q`; `InShadow` is the
belt-and-suspenders guard against a stray survivor. The flag compare is likewise
minted by this step, so `lowerOps` neither double-lowers nor strands it. (The
`RotationLowering` `InShadow`-skip comment still describes the deleted
controlled-op path — `lowerControlledRegions` / `ControlledSubstitution`, both
excised in `7cde677` — and must be retargeted to this swap-route semantics when
4.1 lands; `IMPLEMENTATION.md`.)

### 2.5 The §3c rejection — clobbering the control's own data

> **Reject (loud `DiagnosticInfoUnsupported`, `!dbg`-located) iff an arm performs
> a value-changing write to a quantum variable the branch condition transitively
> reads.**

Model-independent (control-in-place hits the same bind) and
information-theoretically unfixable for non-injective maps (`if(q==1) x(q)` → `q`
becomes constant `|0⟩`, the flag holds the last copy of the branch bit; no copy
disentangles it). The true options are *reject* or *don't-uncompute*; the author
chose **reject**. Diagnostic string (matched character-for-character by the
decline fixture, Rule 12):

```
cq controlled lowering: arm rewrites a condition operand under quantum control
```

**Not rejected:** phase ops on a condition variable; value ops on non-condition
registers; reads of condition variables (`swap_route_reject_clobber.ll` lists the
contrast set). Detection is pure SSA: the arm defines a value-changing
redefinition (non-rotation) of a register in the condition's transitive taint
provenance.

### 2.6 The tainted CFG is flattened; classical control is untouched

The tainted `br i1 %flag` and merge `phi i32` are **erased** (branching/muxing on
a qubit handle at runtime is the silent miscompile the design prevents) and the
diamond is flattened into one block by the pass. This is *not* a contradiction of
"conserve classical control flow": untainted branches are left byte-identical, and
the "phi on both splits and joins" claim is the *algebraic* split-is-adjoint-of-
join structure (the two `cqrt_cswap`s), not literal `br`/`phi` preservation.
Block-lifetime hazard (erasing a block another region still references) is handled
by capturing identities before the first erase (`CLAUDE.md` "block lifetime under
sequential lowering"); 4.1 is single-region, so the hazard is latent until 4.3.

### 2.7 Provenance via value names, not comments or kept blocks

LLVM has no programmatic free-form `;` comments; the routed rails/gates are
**named** after their origin (`%arm.t`, `%then.t`, `%else.e`, `%merge.cswap`) so
the lowered IR reads back to the source `if`. No empty cosmetic blocks (the `-O0`
link would not merge them, and a permanent block labelled `arm:` that always runs
misleads).

---

## 3. Deliverables

- **New control-emitter module(s)** in `ir-pass/src/` replacing the
  `ControlStub.cpp` loud-decline for the accepted shapes (the stub's diagnostic is
  retained for the §3c reject and for not-yet-supported shapes). Reuses
  `EmitInverse` (reverse-play / `icmp_inv`), `FreePoint` (clean-rail free),
  `ControlledSymbols` (`cqrt_cswap`/`cqrt_alloc`/`cqrt_free` callees),
  `WidthDispatch`/`TemplateName` (the `icmp` `_hl`/`_hl_inv` symbols).
- **Detection** (pure analysis): recognize a tainted-condition `br` diamond /
  `if-else`; classify each arm (phase / value / reject); record the condition's
  taint provenance for the §3c check. No IR mutation in detection.
- **Emission**: flag mint, per-arm rail alloc + route-in `cqrt_cswap` (+ `cqrt_x`
  ¬flag bracket for `if/else`), verbatim arm `Rz`, route-back, clean rail free,
  `icmp_inv` flag-strip + free, CFG flatten.
- **LIT fixtures** (`ir-pass/test/`): graduate `swap_route_if_diamond.ll` and
  `swap_route_ifelse.ll` (positive `CHECK` for the routed stream + `CHECK-NOT:
  _controlled` / `CHECK-NOT: phi i32`); a `not … | FileCheck` **decline fixture**
  for the §3c clobber mirroring the diagnostic character-for-character; adversarial
  probes (a `br`-polarity-swapped diamond per Rule 9; a condition over a derived
  value `q+1 > 5` for the transitive-provenance check; a value op on a
  *non*-condition var that must still lower / not falsely reject).
- **≥1 e2e trace golden** (`tests/e2e/`): a phase-arm `if`-diamond C program that
  builds through the 4-stage pipeline, links, runs, and diffs clean against its
  `.expected.log` — the only layer that proves every emitted symbol resolves and
  signature-matches.
- **Doc cross-links**: ROADMAP 4.1 done-criteria coverage; the `docs/prd/README.md`
  index row for Phase 4.

---

## 4. Done criteria

- A tainted phase-arm `if`-diamond and `if/else` lower to the routed stream the
  regenerated `.ll` fixtures pin (`icmp_hl` flag → `alloc` → `cswap` → verbatim
  `rz` → `cswap` → clean `free` → `icmp_hl_inv` → `free`), with `CHECK-NOT:
  _controlled` and `CHECK-NOT: phi i32` green, and `opt -verify` clean.
- A classical-condition `br`/`if-else` is left byte-untouched (passthrough
  fixtures stay green).
- The §3c clobber shape emits the loud `DiagnosticInfoUnsupported` with the exact
  diagnostic string and a source location; the decline fixture is green; the
  not-clobber contrast cases do **not** falsely reject.
- The phase-arm e2e trace smoke diffs clean against its golden.
- Adversarial review against statevector/trace reasoning clears the emitter
  (`CLAUDE.md` Rule 13) — a green suite alone does not clear a core change.
- Full suite (`ctest`) green; `gen_templates.py --check` clean (no ABI change in
  4.1).

---

## 5. Out of scope

- **Value / classical-permutation arms (method-B)** and the new `cqrt_copy_<W>`
  ABI — **4.2** (`swap_route_if_diamond_uncompute.ll` (B-keep); SCOPING §3a / §7
  item 6).
- **Nested tainted control** — **4.3** (the same emitter recursively; the
  block-lifetime hazard activates here).
- **Tainted `select`** — **4.4** (controlled-XOR copy, not cswap routing).
- **Tainted `switch`** — **4.5** (per-case routing / `icmp eq`-flag chain).
- **Control-in-place §6a peephole**, **controlled `return`/`break`** (§4),
  **coherent `Ry` reuse** — deferred (reverse-play / §6a meanwhile).
- **`_controlled` template family** — retained-but-unused reserve for §6a; not the
  4.x control mechanism.
- **Real template bodies / simulation** — runtime stays trace-only (post-freeze).

---

## 6. Risks

- **Verify-clean silent miscompile (the project hazard).** A routing that passes
  `opt -verify` and prints a plausible trace yet computes the wrong unitary, drops
  a `phi` edge, or frees an entangled rail. Mitigation: statevector reasoning +
  e2e golden diff + adversarial review (Rule 13), never the verifier alone.
- **`br` polarity inversion (Rule 9).** `clang -O1` canonicalizes `if(u!=k)` to
  `icmp eq; br eq, Merge, Arm`, so the gate arm is often the **false** successor.
  Detection must key on SSA-value identity and resolve the arm by taint, not by
  the Pred edge; the ¬flag `cqrt_x` bracket polarity must follow. Mitigation: a
  polarity-swapped adversarial fixture.
- **Flag-mint ordering.** The condition compare must be lowered to its `_hl` flag
  exactly once — not double-lowered by `lowerOps`, not stranded. Mitigation:
  emitter owns the mint; the orchestrator skips a compare already claimed as a
  flag (pinned by a fixture that also has the same compare feeding data, if such
  a shape is in scope; else a decline).
- **§3c false-accept / false-reject.** Missing a transitive clobber (e.g. the
  condition is `q+1 > 5` and the arm rewrites `q`) is a silent miscompile;
  over-rejecting a value op on a *non*-condition var needlessly declines valid
  programs. Mitigation: provenance computed from the condition's taint set;
  fixtures for both the derived-condition clobber and the non-condition value op.
- **Block-lifetime SIGSEGV under flatten (latent until 4.3).** Erasing a merge
  block another region references dereferences freed memory on valid input.
  Mitigation: 4.1 single-region; capture identities before erasing; nested case
  declines until 4.3.
- **Convention coupling.** The flag-strip's correctness depends on `Rz` preserving
  basis value (`Rz = diag(1,e^{iθ})`). If the runtime/template `Rz` body ever
  realizes the symmetric `diag(e^{∓iθ/2})` convention, the inactive rail picks up
  a flag-relative phase and the "rail `|0⟩` for free" claim weakens. Bodies are
  trace-only stubs through the freeze, so this is a documentation invariant to
  carry into the real-body work (`bd remember`), not a 4.1 blocker.
