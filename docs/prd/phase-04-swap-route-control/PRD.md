# Phase 4 PRD — IR pass: RSSA swap-routed tainted control flow

Phase-specific design decisions, scope, and done criteria for lowering tainted
(quantum-dependent) `br` / `phi` by **routing data, not controlling gates**. This
PRD covers the **4.1 increment — phase arms (`Rz`)** in full (**Part I**, §§0–6 —
closed 2026-06-10, epic `e4baa67`), the **4.2 increment — value/permutation arms
(method-B)** in full (**Part II**, §§7–10 — written 2026-06-10 at 4.2 start,
Rule 16), the **4.3 increment — nested control (depth-2 homogeneous phase)** in
full (**Part III**, §§11–14 — closed 2026-06-15), and the **4.4 increment —
tainted `select` (controlled-XOR copy merge)** (**Part IV**, §§15–18 — written
2026-06-15 at 4.4 start, Rule 16); it further records the binding decisions for
**4.5 `switch`** so they survive between sessions and across the freeze. The old
**controlled-op** Phase 4 shipped and was removed wholesale (commit `7cde677`);
this PRD replaces its archived predecessor
([`docs/archive/old-design/phases/phase04-controlled-form/`](../../archive/old-design/phases/phase04-controlled-form/)).
It is a lean PRD — it memorializes the PRD-discovery decisions; the module-layout
/ fixture / commit-shape plans land as `IMPLEMENTATION.md` (4.1),
[`IMPLEMENTATION-4.2.md`](IMPLEMENTATION-4.2.md) (4.2), and
[`IMPLEMENTATION-4.3.md`](IMPLEMENTATION-4.3.md) (4.3) alongside it
(`IMPLEMENTATION-4.4.md` at 4.4 build kickoff).

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
> control. Coherence is established by analytic/trace reasoning, never by
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
- Adversarial review against analytic/trace reasoning clears the emitter
  (`CLAUDE.md` Rule 13) — a green suite alone does not clear a core change.
- Full suite (`ctest`) green; `gen_templates.py --check` clean (no ABI change in
  4.1).

---

## 5. Out of scope

- **Value / classical-permutation arms (method-B)** and the new `cqrt_copy_<W>`
  ABI — **4.2** (`swap_route_if_diamond_uncompute.ll` (B-keep); SCOPING §3a / §7
  item 6). *Promoted to a full treatment in Part II (§§7–10) at 4.2 start,
  2026-06-10.*
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
  a `phi` edge, or frees an entangled rail. Mitigation: analytic/trace reasoning +
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
  *(Recorded: bd memory `rz-diag-flag-strip-invariant` — DIAGONALITY, not the
  specific convention, is the load-bearing invariant; both conventions verified
  coherence-exact.)*

---
---

# Part II — the 4.2 increment: value/permutation arms (method-B)

Written 2026-06-10 at 4.2 start (Rule 16), after the status audit fixed the
entry gates: (i) this treatment; (ii) the SCOPING §7.6 `cqrt_copy_<W>`
resolution (§8.1 below); (iii) — the SCOPING §8 method-B demo obligation was
**struck by owner decision 2026-06-10** (no statevector simulations at this
stage); the B-keep boundary is documented analytically in §8.2 and the
clearance gate is the WI-7 independent adversarial review;
(iv) the §3c activation + the WI-1 Defect-2 string fix (bd memory
`swap-route-detect-known-limits`); (v) the first real `emitInverseChain`
invocation, discharging SCOPING §7.5. Module layout / fixtures / WI sequence:
[`IMPLEMENTATION-4.2.md`](IMPLEMENTATION-4.2.md).

Relevant bd memories (Rule 0/11 — verified against the live tree 2026-06-10):
`rz-diag-flag-strip-invariant` (diagonality invariant; method-B on a phase arm
dephases — verified P0 0.585→0.500), `swap-route-phase41-clearance` (the §8
probe-matrix precedent this Part mirrors), `swap-route-detect-known-limits`
(Defect-2; the one-tainted-region-per-fixture authoring rule — opt exits on the
FIRST diagnostic), `swap-route-ifelse-derived-base-boundary` (arm-block-bounded
spine walks), `rule13-no-backend-clearance-scope` (clearance =
analytic/trace-level review + lowered-IR reading, amended 2026-06-10; never
claim "statevector-verified output").

---

## 7. Scope (4.2)

**In scope.** Lower a tainted-condition `br i1` **diamond** (one content arm)
and **if/else** (two content arms) whose arm bodies are **classical-permutation
/ value ops** — linear chains of supported tainted integer `BinaryOperator`s
(`add`/`mul`/`xor`/…, the `OpcodeSupport` stems; the ROADMAP's "`x`/`toffoli`"
names this permutation *class* — user C can only reach it through stock
opcodes, there is no user `x` intrinsic) — by **method-B**
(SCOPING §3a, `swap_route_if_diamond_uncompute.ll` (B-keep)):

1. **Mint the flag** — `cq_template_icmp_<pred>_<W>_hl(q, lit)`, identical to
   4.1 step 1 (the condition register `q` is **disjoint** from the routed value
   register for every *accepted* region — §8.3 guarantees it).
2. **Route in** — `cqrt_alloc_<W>(0)` a `|0⟩` work rail; `cqrt_cswap(flag, p,
   rail)` (¬flag arms X-bracketed, as 4.1).
3. **Run the arm chain verbatim and uncontrolled on the rail** — each chain op
   re-emitted as its ordinary data template (`cq_template_<op>_<W>_hl/_lh`),
   base operand retargeted to the rail handle; fresh handles thread through the
   chain exactly as in straight-line code.
4. **Route back** — the same `cqrt_cswap(flag, p, railFinal)`; the routed
   register `p` now holds the muxed answer in place.
5. **Copy out** — `%out = cqrt_alloc_<W>(0)`; `cqrt_copy_<W>(p, out)` — the
   **basis-valued** answer is CNOT-copied into a fresh register (the design's
   only new ABI, §8.1). Sources stay live (Rule 8).
6. **Reverse-play `R†`** — route-back†, the chain's adjoint (`_inv` twins, via
   `emitInverseChain` — the **first real invocation**, §8.5), route-in†. This
   restores `p == p0` and returns the rail to `|0⟩` **on both branches**
   (analytic trace: §8.2).
7. **Free the rail** — now provably `|0⟩` (§3b: free follows the reverse-play
   for value arms; never before it).
8. **Strip the flag** — `icmp_inv(q)`: valid because the condition register is
   never routed or rewritten in an accepted value region (§8.3), so `q == q0`
   trivially. Then free the flag.
9. **Rewire + flatten** — RAUW the merge `phi` → `%out`; erase the arm chain,
   the `br`/`phi`; flatten (4.1's `RegionFlatten`). The user's
   `cq_measure(phi)` becomes `cq_measure(out)`.

Targets: a regenerated, CHECK-pinned `swap_route_if_diamond_uncompute.ll`
(B-keep graduates from "sketched" to pinned) and the new
`control_swap_value_diamond.ll` / `control_swap_value_ifelse.ll` lit contracts
(IMPLEMENTATION-4.2 §5d/§5e).

**Also in 4.2 — the §3c reject goes ACTIVE** (§8.3): 4.1 shipped it vacuously
(phase arms never value-write); 4.2 is where it does real discriminating work,
including the Defect-2 string fix.

**Out of scope (4.2)** — see §10: QQ-operand chain links, mixed phase/value
arms, heterogeneous if/else (one phase arm + one value arm), FP-typed merges
(categorically an *angle*, never data — the f64 miscompile family), nested
(4.3), `select` (4.4), `switch` (4.5).

---

## 8. Design decisions (4.2)

Each resolved 2026-06-10 at 4.2 PRD time and binding.

### 8.1 §7.6 RESOLUTION — `cqrt_copy_<W>`: width set, semantics, placement

This resolves SCOPING §7 item 6 (the design's **only** new ABI).

**Semantics (binding).** `cqrt_copy_<W>(src, dst)` is the **keep-sources-live
reversible basis copy**: one transversal CNOT per bit of the width-`<W>`
register pair, `|x⟩_src |0⟩_dst → |x⟩_src |x⟩_dst`. Precondition: `dst` is a
fresh `|0⟩` register (the emitter always allocates it immediately before the
copy). It copies a computational-basis *label*, **not** a state — it is not
cloning, and it is **wrong for any phase/superposition carrier** (a CNOT copy
of an `Rz`/`Ry` answer dephases it — verified P0 0.585 → 0.500; SCOPING §3a,
bd `rz-diag-flag-strip-invariant`). It is a **transversal-CNOT involution**:
applying it twice on the same pair returns `dst` to `|0⟩` — so there is **no
`cqrt_copy_<W>_inv` twin** (same class as `cqrt_x`/`cqrt_cswap`).

**Rule 8 boundary (binding).** The copy **never frees, consumes, or
disentangles its source.** Freeing a source that carries superposition remains
`cqrt_cswap`-only (move, not copy). The emitter leaves the source register
allocated after the copy — for the routed value register that is deliberate
(§8.2: it is restored to `p0` by reverse-play and stays entangled with `out`
as program data; freeing it would be a hidden measurement, Rule 6).

**Width set (binding): the 5 integer widths — `cqrt_copy_i1/_i8/_i16/_i32/_i64`.**
Justification against the 7 allocator widths (`runtime/cq_runtime.h` —
`cqrt_alloc_i{1,8,16,32,64}` + `f{32,64}`):
- The copy's operand is always a **merge value the pass routes as data**, and a
  **floating-point merge `φ` under tainted control is categorically an angle,
  never data** (the f64 silent-miscompile family; CLAUDE.md correctness-risk
  block: never key data-mux lowering on `abiWidthFromType()` non-empty — f64
  has a valid width yet is an angle). The pass can therefore never legitimately
  mint an FP copy; declaring `cqrt_copy_f32/_f64` would be dead ABI whose only
  possible caller is exactly that bug. Omit them.
- The 5 integer widths mirror the integer subset of the allocator family
  one-for-one (the copy target is allocated by `cqrt_alloc_<W>`, so copy width
  ≡ alloc width by construction). `i1` is kept for allocator symmetry (a
  tainted `i1` chain is degenerate but representable).
- Width at emit time is read from the chain op's **integer SSA type** via
  `abiWidthFromType` (`OpcodeSupport.h:69`) — pre-RAUW the chain ops still
  carry `iN` types, so this is reliable for value arms (unlike 4.1's phase
  arms, which had to read the `cq_phi` suffix because `taint.HandleWidth` is
  not yet populated at emit time). Acceptance itself never keys on width
  validity (the f64 trap); it keys on the integer-typed-merge + chain-class
  predicate (§8.3).

**Placement (binding): hand-written `cqrt_*` core ABI**, declared in
`runtime/cq_runtime.h` and defined in `runtime/cq_runtime.c` — **not** in
`tools/opcode_table.yaml`. The naming grammar splits the two families:
`cqrt_*` = the hand-written core (allocators, measure, rotations, gate
primitives, `cqrt_cswap`, `cqrt_free`); `cq_template_*` = the YAML-generated
reversible bodies for *stock opcodes*. The copy is a gate **primitive** (like
`cqrt_cswap`, which landed hand-written in `555091e`/npu.4), not a stock-opcode
template; the YAML schema has no slot for it and must not grow one.
Consequence: `gen_templates.py --check` is **unaffected** (still run in the
done criteria; it must stay clean because the YAML is untouched).

**Signature + trace (binding, trace-only contract).**
```c
void cqrt_copy_i1 (int32_t src, int32_t dst);   /* … i8/i16/i32/i64 */
```
Handles are always `i32` regardless of width (Rule 15). Void → no-arrow trace,
args as `h<N>`, matching the `cqrt_cswap` convention exactly:
`cqrt_copy_i32(h<src>, h<dst>)`.

**Freeze re-opening note.** The Phase-8/10 ABI freeze re-opens for **exactly
this one family — 5 symbols** (the ROADMAP principle-7 note already reserves
it: "the per-width reversible copy `cqrt_copy_<W>` (Phase 4.2)"). No other
symbol is added; the generated `cq_template_*` surface is untouched.

### 8.2 Method-B is the value-arm method — stream soundness + the coherence contract

Rule 7: method matches arm class. The B-keep stream (§7 steps 1–9) is sound by
the register-threading trace (one physical rail register threaded through
fresh handle versions — the same Phase-5 axiom as straight-line uncompute,
R-template-inv-fresh-handle):

- `flag=1`: route-in `p↔rail` (rail=p₀, p=0) → chain (rail=f(p₀)) → route-back
  (p=f(p₀), rail=0) → copy (out=f(p₀)) → R† route-back† (p=0, rail=f(p₀)) →
  chain† (rail=p₀) → route-in† (p=p₀, rail=0).
- `flag=0`: rail=0 → chain (rail=f(0), the inactive-branch garbage) →
  no-op swaps (p=p₀ throughout) → copy (out=p₀) → chain† (rail=0).

After R†: **`p == p₀` and `rail == |0⟩` on BOTH branches** — the rail free is a
clean reset (§3b satisfied), and without the reverse-play the rail would be
`f(0)`-vs-`0` **entangled with the flag (hence with `q`)** — freeing it dirty
is the hidden-measurement bug. `out` holds the basis-valued answer; the merge
`phi` RAUWs to it.

**Why the flag-strip stays valid for value arms:** the condition register is
**never routed and never rewritten** in an accepted region (§8.3 makes the
routed register and the condition provenance disjoint), so `icmp_inv(q)` reads
the same basis as the mint — no reliance on the reverse-play for the flag (the
SCOPING §3a "makes the trailing `icmp_inv` trivially valid" remark covers the
general case; in 4.2's accepted subset it is valid outright).

**The coherence contract (honest boundary — TWO observable deviation
channels, derived by independent review, 2026-06-10, with the analytic
closed forms below).** B-keep is
**measurement-correct** (the `out` distribution equals the controlled-op
in-place reference exactly, always) and **undo-correct**
(B-undo composes). The rails and the flag are **exactly `|0⟩`** after R† +
strip, so the garbage-dephasing assertions are **exact-zero**; and in the
**basis-`p₀` regime every observable delta is exactly zero**. It is **not**
interference-equivalent to the in-place reference: the restored source
register `p₀` survives entangled with `out` (`|q⟩|p₀⟩|f_q(p₀)⟩` vs the
in-place `|q⟩|f_q(p₀)⟩`), and that kept-source correlation is observable on
**two** channels:

- **Channel A — control visibility** (the downstream Hadamard-test on `q`):
  the in-place reference's control coherence is `Σ_p b_p b*_{f(p)}`; B-keep's
  is `Σ_p |b_p|² · [f(p)=p]` — reduced whenever `p₀`'s coherences between `x`
  and `f(x)` matter.
- **Channel B — answer-register coherence**: with a superposed `p₀` and even a
  **basis-state** condition (arm always taken — channel A's delta is exactly
  zero there), `out` itself loses `p`-coherence, visible to a plain downstream
  `cq_theta(out, t)` + measure (witness numbers recorded by the independent
  review, 2026-06-10: 2-bit registers, `f = +1 mod 4` — reference distribution
  `[.5, 0, 0, .5]` vs B-keep flat `[.25, .25, .25, .25]`).

A review covering only channel A could honestly record ~0 (basis condition)
and bless an understated boundary — hence the boundary is documented on
**BOTH channels** (binding documentation, the closed forms above). *The demo
deliverable that originally enforced this bar was struck by owner decision
2026-06-10 (no simulations at this stage):* clearance is the WI-7 independent
adversarial review, reasoning analytically against these closed forms on both
channels (plus the exact-zero observation in the basis-`p₀` regime). The
boundary itself is deliberately *not* "deviation must be zero" (that would
relitigate Rule 7 and make 4.2 unshippable). The kept-source correlation is
inherent to Bennett-keep and is the documented boundary, not a 4.2 bug.

*Channels A and B are named **witnesses**, not an exhaustive enumeration*
(clarification, WI-7 review 2026-06-11): the **single root cause** is that
the restored source `p₀` stays entangled with `out` — globally B-keep is
**bit-for-bit** the in-place reference plus a retained source copy,
`Σ_q Σ_{p₀} c |q⟩|p₀⟩|h_q(p₀)⟩_out`. By purification/Schmidt uniqueness every
observable deviation is a **marginal shadow of that one entanglement**: the
`q`-marginal is channel A, the `out`-marginal is channel B, and the joint
`q`-`out` cross-coherence block (also non-zero, and reachable since reads of
the live condition are permitted) carries **no information beyond** the same
kept-source correlation — it is not a third independent channel. The boundary
is therefore characterized at the **mechanism** level (the kept-source
entanglement) and witnessed by A and B; B-keep remains **measurement-correct**
on `out` (the computational-basis `out` and joint `(q,out)` distributions are
*exact* against the in-place reference), which is what the lowering promises.

**Two-arm (§5e if/else) generalization** *(WI-5 §8 review, 2026-06-11)*: the
closed forms above are the one-content-arm specialization (else = identity).
For the dual-rail if/else the B-keep final state is
`Σ c_{q,p₀} |q⟩|p₀⟩|h_q(p₀)⟩_out` with `h_q = f` (then) or `g` (else), so
channel A's overlap factor generalizes from `[f(p)=p]` to `[f(p)=g(p)]`
(in-place reference coherence `Σ_{p,p'} b*_p b_{p'} · [f(p')=g(p)]`); channel
B is unchanged per branch. **No new channel exists**: the second rail returns
exactly to `|0⟩` on every basis branch and factors out (the per-arm grouped
R† equals the literal global adjoint — arm streams commute: disjoint rails,
route cswaps on complementary flag values).

**What restores fidelity — scoped honestly.** B-undo / `cq_invert` (SCOPING
§3b: "value-arm / whole-region coherence by on-demand reverse-play") restores
full interference fidelity **only for compute→use→uncompute patterns** (the
oracle/Grover-bracket shape — the Phase-7 `cq_invert` territory): it
*uncomputes* `out`, so it **cannot** deliver a coherent **in-place** answer
for keep-and-continue use of the result. The only candidate mechanism for
that is §6a control-in-place (consistent with the §8.3 mixed-arm row, which
already points there). **No future increment may cite this section as proof
the B-keep boundary is fully dischargeable at Phase 7** — for
keep-and-continue value regions the boundary remains open until a §6a
treatment lands.

**Never apply B to a phase arm** (Rule 7): the dephasing probe stays —
every phase-arm accept fixture keeps `CHECK-NOT: cqrt_copy`; the recorded
P0 0.585 → 0.500 dephasing (2026-06-09) stands as the negative-control
evidence.

### 8.3 The §3c reject goes ACTIVE — predicate, strings, Defect-2 fix

4.1 shipped §3c vacuously. The 4.2 classification of a value-arm region
(pure SSA analysis before any mutation, Rule 9):

- **ChainBase** := the value the arm's merge contribution bottoms at, walking
  the arm-block-bounded **linear chain** of supported tainted integer
  `BinaryOperator`s, each link consuming the threaded value as its **sole
  quantum operand** (the other operand classical — the `_hl`/`_lh` shapes).
- **Routed** := the diamond's straight-through (Pred-edge) incoming / the
  if/else arms' shared base (same anchoring as 4.1 phase arms; a derived
  pre-region `cq_phi` base is permitted iff identical to the routed slot, the
  9hh discipline).
- **Routable** iff `ChainBase == Routed`, `Routed` tainted, the merge type
  integer, and the arm block pure (no fan-out, no strays — the
  `armBlockIsPureSpine` analog over the value chain; Rule 8 linear lineage).

**[WI-3 landing amendments — §8 adversarial review, 2026-06-10. Three
hardenings beyond the letter above, all fixtured:** (i) *"merge type integer"
is enforced positively* — an integer VECTOR (`<2 x i32>`, reachable via the
escape-whitelisted bitcast) or a non-ABI-width integer (`i128`) merge declines
`control flow`; the width check is necessary-not-sufficient and runs only
AFTER the FP fence (never a classifying signal — the f64 trap stands).
(ii) *Provenance disjointness is checked through the routed base's
DIAGONAL-ALIAS closure*: `%qd = cq_phi(%q,·)` aliases `%q`'s physical wire
post-RAUW (rotation lowering RAUWs both to one handle), so a value arm routed
over `%qd` under `cond(q)` declines `control flow` — without the closure, the
§8.2 "no reliance on the reverse-play" rationale would be FALSE for that
member (mid-stream the shared wire holds the muxed value; only the §4
strip-after-R† order would save it). A derived base disjoint from the
condition stays accept-class. (iii) *The PERMANENT §3c string fires only on
the PROVEN diamond identity* (straight-through == direct provenance member);
an if/else-anchored base hitting provenance — the fresh-value read mux
`t=q+1 else t=q+2`, including the no-hint Q+Q thread — declines generic
`control flow`, never §3c (the Defect-2 lesson inverted: never brand a
possibly-read shape information-theoretically impossible on an anchoring
heuristic).**]**

| shape (example) | verdict | diagnostic `What` |
|---|---|---|
| routable AND `Routed ∈ condProvenance` — `if(q>5){q=q+3}`, `if(q+1>5){q=q+3}` (transitive) | **permanent §3c reject** | `arm rewrites a condition operand` *(PRD-pinned string, unchanged from 4.1)* |
| routable AND `Routed ∉ condProvenance` — `if(q>5){p=p+3}` | **ACCEPT** (lowers per §7) | — |
| phase op on a condition register — `if(q>5){rz(q,a)}` | **ACCEPT** (4.1 behavior, unchanged) | — |
| chain link with a tainted second operand (QQ) — `if(q>5){p=p+r}` | defer (recognized value shape, not yet routable) | `value-arm swap-route` *(string retained for the still-deferred subset)* |
| mixed `cq_phi` + value links in one chain — `if(q>5){rz(p,a); p=p+3}` | decline (the answer carries both phase and a changed basis: copy dephases it, strip is invalid — §6a territory) | `mixed phase/value arm` *(new string, new fixture pair)* |
| impure value arm: fan-out or stray op in the arm block — expression DAG `if(q>5){p=(p+3)*(p^5);}`, stray op beside the chain | decline (Rule 8 linear lineage — the pure-chain predicate, the `armBlockIsPureSpine` analog) | `impure value arm` *(new string, mirrors `impure phase arm`; new fixture pair)* |
| `ChainBase != Routed` — **Defect-2** (`t=q+7; if(q>5) t=q+3`), fresh-value mux (`if(q>5){p=q+1}`) | decline (a data **mux** of independently-derived values, the 4.4-`select` family — not routable, not §3c) | `control flow` *(generic — this IS the Defect-2 fix, see below)* |
| FP-typed merge `φ` | decline (an angle, never data) | `control flow` |

**The Defect-2 fix (entry gate iv).** bd memory
`swap-route-detect-known-limits` records Defect-2: the derived-straight-through
clobber-ish diamond declined as the 4.2-deferrable `value-arm swap-route`. With
4.2 un-deferring value arms, that label would become an over-accept hazard;
the chain-walk predicate above reclassifies it as **not routable** (its chain
bottoms at `%q`, not at the straight-through `%q+7`). The fix also
**supersedes the memory's "§3c clobber" framing**: in that shape the condition
register `q` is never overwritten (it stays live; the flag is strippable), so
it is *not* information-theoretically unfixable — it is a value **mux** of two
`q`-derived values, deferred to the `select`-style machinery (4.4), declined
`control flow` meanwhile. Equally binding: the memory's warning stands — do
**not** "fix" the diamond test by switching to `readsProvenance(armBase)`
(that wrongly §3c-rejects the legitimate `if(q>5){p=q+1}` read). The if/else
`readsProvenance` *fallback* in `ArmClassify.cpp` is **retired** by the
base-identity predicate (the if/else routed base is now resolved exactly like
the diamond's). The bd memory is updated when WI-3 lands.

**SCOPING §3c table reading (binding clarification).** The §3c table's
"accept" column means "**not rejected by §3c**", not "routable in 4.2":
`if(q>5){p=q+1}` is not a §3c clobber AND not 4.2-routable — it declines
`control flow` until a mux-capable increment. Both directions are fixtured
(no §3c string on it; no acceptance of it).

### 8.4 The `-O1` shape reality — what value arms actually reach the pass (measured 2026-06-10)

Rule 9/11 — measured against `clang -O1` on this tree, not guessed:

- A **single-op or short (≲4 cheap ops) value arm folds to a tainted
  `select`** at `-O1` (SimplifyCFG speculation): `if(q>5){p=p+3;}` reaches the
  pass as `%5 = select i1 %3, i32 %4, i32 %2` — **4.4 territory, not a
  `br`-diamond**. (4.1 phase arms never hit this because `cq_phi` is an opaque
  call — unspeculatable.)
- A **longer linear chain survives** as a clean `br`-diamond: the 6-op
  `if(q>5){p=p+3; p=p*5; p=p^9; p=p+1; p=p*7; p=p^2;}` compiles to a
  one-arm-block diamond whose arm is a pure linear `mul/add/xor` HL chain
  bottoming at the straight-through incoming (clang reassociates the constants
  — `p+3; p*5` → `p*5; +15` — still a linear chain). Chains containing a
  division/remainder also survive (expensive-op speculation cutoff).
- A `br`-surviving **expression DAG** (`p = (p+3)*(p^5) + p*9`) **fan-outs the
  base** — correctly declined by the pure-chain predicate (Rule 8).

Consequences (binding): the primary 4.2 contracts are **hand-written `.ll`
fixtures** (the Phase-3 `sub_hl` precedent — a shape unreachable from C is
pinned by `.ll`, ROADMAP Phase-3 note); the **e2e golden is still C-sourceable**
via the verified 6-op linear chain (IMPLEMENTATION-4.2 §7 WI-6); and the
select-folded short arms stay loudly declined as `select` until 4.4 — document,
don't fight, the canonicalizer.

### 8.5 Reverse-play reuses the `EmitInverse` spine — §7.5 discharged with one seam

SCOPING §7 item 5 asked to confirm the region-local reverse-play reuses
`EmitInverse` cleanly and that the §3b free point is the `FreePoint`
post-dominator. Resolution (binding):

- **`emitInverseChain` reverses the BODY CHAIN ONLY** — the forward template
  calls in program order, `Terminal` = the forward chain's final rail handle.
  It threads `_inv` twins exactly per its contract (`EmitInverse.h:67`) and
  returns the final threaded handle, which **is** the handle the rail free
  consumes. This is the first real invocation (it has been wired-not-invoked
  since Phase 5).
- **The route cswaps are NOT fed through `emitInverseChain`.** The discovered
  seam (read, not guessed — `EmitInverse.cpp:67-75`): `emitInverseCall`
  threads `CurHandle` into **`Args[0]`** for the `cqrt_x`/`cqrt_cswap`
  involution case, and `cqrt_cswap`'s arg 0 is the **flag**, not the data
  handle — threading a rail handle into the flag slot would be a verify-clean
  wrong unitary. The emitter therefore emits the R† route-back†/route-in†
  brackets itself via 4.1's `emitRoute` (cswap is self-inverse, so the adjoint
  bracket is the identical helper call), with `emitInverseChain` between them.
  WI-4 adds a guard comment at the seam so no future caller threads a cswap.
- **Free point ≡ `FreePoint` discipline.** The flattened region is
  single-block, so the post-route-in† point trivially post-dominates every
  rail use — the same "this point IS the post-dominator" argument as 4.1 step
  6 (`computeFreePoint` generalization stays wired for 4.3, not invoked here).
  `out` is owned by its consumer (`Measured` by the user's measure, or
  `Escaped` via `ret`) — the region code **never frees `out`** (a free of the
  answer is a hidden measurement of the result), and the later `uncompute`
  pass must add nothing (no-spurious-free probe, IMPLEMENTATION-4.2 §8).

### 8.6 Reversibility axiom — shared with Phase 5, not new

The chain adjoint rests on the same per-op axiom the Phase-5 straight-line
uncompute already ships: every `cq_template_<op>` has a declared `_inv` twin
realizing its adjoint (runtime is trace-only through the freeze). The known
model caveat — a non-injective stem instance (e.g. `mul` by an even literal,
mod 2^W) has no mathematical inverse — is **pre-existing and shared** with
straight-line lowering (which emits the same `_inv` symbols); 4.2 neither
widens nor narrows that exposure. Carried as an open item for the real-body
phase (§10), with the same disposition in both code paths (consistency over
special-casing). Note: the §8.2 free/strip soundness trace assumes every
chain link is a true **permutation**; for the non-injective subset the trace —
like straight-line uncompute — inherits this shared Phase-5 axiom *fictionally*
until real template bodies land.

**The non-injective subset enumerated (binding, completed at WI-7).**
`walkValueChain` (`ArmClassify.cpp:262`) admits **every** integer stem
`binaryStem` names — it does **not** filter on injectivity, by design (parity
with straight-line uncompute). Of those, the maps that are NOT bijections on
`Z/2^W` are: the **div/rem family** (`sdiv`/`udiv`/`srem`/`urem` — lossy), an
**even-literal `mul`** (the literal is a zero divisor, not a unit mod 2^W), a
**`and`/`or` with a non-trivial literal** (a mask clears/forces bits — a
witness probe `if(q>5){p=p&7}` lowers verify-clean with a
`cq_template_and_i32_hl_inv` adjoint), and the **shift stems** `shl`/`lshr`/
`ashr` (each discards bits off one end). The bijections — `add`/`sub`/`xor` by
any literal, `mul` by an **odd** literal — have honest inverses and are not
affected. (Both e2e/lit golden chains use only bijective stems —
`mul 5`/`mul 7`/`add`/`xor` — so no golden exercises a fictional adjoint; the
fixtures' adjoints are mathematically real.) Exposure + disposition are
**identical** to straight-line uncompute, which emits the same `_inv` symbols
on the same non-injective stems; 4.2 adds no new exposure. See **§0
criterion 2**, which is read through this subsection.

### 8.7 Composition with the three guards landed 2026-06-10 (binding)

How a value-arm region composes with the hardening guards now in the
orchestrator (each gets a probe fixture, IMPLEMENTATION-4.2 §8):

- **`declineTaintEscapes`** (runs first, pure analysis): an accepted region's
  arm `BinaryOperator`s and merge `phi` are owned/supported consumers — the
  guard must not fire on them (the 4.1 accept fixtures already prove this for
  phase shapes; a value accept fixture proves it for chains). Probe: the
  accept fixture itself is the witness (it would exit non-zero otherwise).
- **`declineStaleRecordOps`** (runs before detection): in 4.2 the arm's chain
  ops ARE in its purview (tainted `BinaryOperator`s — new vs 4.1, where arm
  bodies were opaque `cq_phi` calls). A wire that genuinely gains a
  non-diagonal gate must keep declining (over-decline safe; either guard may
  fire first). Interlock: the emitter erases chain ops, so the region scrub
  must also clear `taint.StaleDeclined` (IMPLEMENTATION-4.2 §6) — and
  `ArmClassify`'s own `nonDiagonalGateBeforeBranch` stale-condition guard runs
  **before arm classification**, so it covers value regions identically
  (probe: a chained-theta value-arm variant of
  `control_swap_reject_stalecond_chained_theta.ll`).
- **`declineClassicalMuxes`** (runs after `lowerControlRegions`): an accepted
  value region **erases its merge phi** (RAUW → `out`) before the guard runs,
  and a declined region has already exited `opt` — so the guard sees no
  region-owned mux. Probe: the accept fixture passes it by construction; a
  classical-condition value diamond stays byte-untouched (passthrough).

---

## 9. Done criteria (4.2)

> **STATUS: ALL MET — 4.2 DONE (2026-06-11, WI-1..WI-7, branch
> `swap-route-control`).** The §8.2 two-channel boundary and the emitter were
> cleared by the WI-7 independent adversarial review (4/4 lenses, 0 confirmed
> defects, 0 silent-miscompiles — IMPLEMENTATION-4.2 §8.10). Full `ctest`
> green (11 entries incl. the value-diamond e2e); `gen_templates.py --check`
> clean. Each criterion below is satisfied.

- A tainted value-arm `if`-diamond and `if/else` (linear HL/LH chains) lower to
  the routed B-keep stream the fixtures pin (mint → rail → route-in → verbatim
  chain templates → route-back → `alloc`+`cqrt_copy_<W>` → route-back† →
  `_inv` chain → route-in† → rail free → `icmp_inv` strip → flag free; merge
  `phi` RAUW'd to `out`), `CHECK-NOT: _controlled`, `CHECK-NOT: phi i32`,
  **exactly two `cqrt_free` for the diamond** (rail-final + flag) and
  **exactly three for the if/else** (two rail-finals + flag —
  IMPLEMENTATION-4.2 §5e `CHECK-COUNT-3`); `out` and the restored source
  register are NEVER freed; `opt -verify` clean.
- `cqrt_copy_i{1,8,16,32,64}` land in the hand-written core ABI with the
  pinned signature/trace; the runtime trace test covers them;
  `gen_templates.py --check` stays clean (YAML untouched).
- The §8.2 B-keep two-channel boundary is cleared by **independent adversarial
  review** reasoning **analytically** against the closed forms (channels A and
  B; exact-zero deltas in the basis-`p₀` regime; the phase-arm dephasing
  negative stands as recorded evidence) — the oracle-demo obligation was
  **struck by owner decision 2026-06-10** (no simulations at this stage).
- §3c active: the full §8.3 matrix is fixtured — `q=q+3` rejects with the
  exact PRD-pinned string (+ transitive variant), `p=p+3` **accepts**,
  `p=q+1` and Defect-2 decline `control flow` (NOT §3c, NOT accepted), QQ
  defers `value-arm swap-route`, mixed arm declines `mixed phase/value arm`,
  fan-out/stray declines `impure value arm`; decline fixtures mirror strings
  character-for-character (Rule 12).
- The first real `emitInverseChain` invocation lands (§7.5 discharged); the
  cswap-seam guard noted at `EmitInverse`.
- ≥1 e2e trace golden links and diffs clean (`slice_control_value_diamond` —
  the only layer proving `cqrt_copy_i32` resolves + signature-matches).
- 4.1 regression floor: every phase-arm fixture stays green and keeps
  `CHECK-NOT: cqrt_copy` (no method-B leakage into phase arms).
- §8 adversarial review (IMPLEMENTATION-4.2 §8) clears the emitter change
  (Rule 13) — a green suite alone does not.
- Full `ctest` green; bd memory `swap-route-detect-known-limits` updated
  (Defect-2 disposition superseded).

---

## 10. Out of scope / open questions (4.2)

Honestly listed; each currently (or will, via WI-3) declines loudly:

- **QQ chain links** (`p = p + r`, a second live quantum register read, not
  rewritten): method-B plausibly sound (the second operand is read-only on
  both R and R†), but unanalyzed — requires its own deliberate analytic
  clearance before any accept. Deferred; declines `value-arm swap-route`.
- **Mixed phase/value arms** (`rz(p,a); p=p+3` in one chain): the answer
  carries both a phase and a changed basis — copy dephases the phase part,
  strip is invalid for the value part. No B-variant fixes this; the candidate
  is §6a control-in-place. Declines `mixed phase/value arm`.
- **Heterogeneous if/else** (one phase arm, one value arm): the per-branch
  answer lives in different places (in-place phase on `p` vs new value) — no
  single merge register is coherent under both. Declines
  `mixed phase/value arm` (region-level).
- **Value arm reading-but-not-writing a condition register** (`p = q + 1`):
  not a §3c clobber (the §3c table's "accept" = not-rejected-by-§3c), but not
  routable either (`ChainBase != Routed` — a fresh-value mux, the 4.4
  family). Declines `control flow`. Whether 4.4's controlled-XOR merge can
  absorb the with-arm-ops mux generalization is a 4.4 question.
- **Fan-out of `out` downstream**: after the region, `out` is an ordinary
  tainted handle owned by straight-line rules (Phase 3/5); no region-specific
  obligation is claimed. Verified by the no-spurious-free probe + e2e.
- **Multi-op chain length**: in scope (linear lineage, Rule 8 enforced by the
  pure-chain predicate — violations decline `impure value arm`, §8.3); the
  only cap is the `-O1` select-folding boundary on the C side (§8.4), which
  shortens *real-world* chains reaching the pass to ≥~5 ops or expensive-op
  chains — `.ll` fixtures cover the short forms.
- **Non-injective stem instances** (even-literal `mul`): shared Phase-5 axiom
  (§8.6); disposition deferred to the real-body phase, kept consistent across
  straight-line and region paths.
- **B-keep interference boundary** (kept-source correlation, §8.2 —
  **two channels**: control visibility + answer-register coherence): inherent
  to Bennett-keep; cleared by the WI-7 independent adversarial review
  reasoning analytically against the §8.2 closed forms on both channels (the
  demo obligation was struck — owner decision 2026-06-10). B-undo /
  `cq_invert` (Phase 7) restores fidelity
  only for compute→use→uncompute patterns; the keep-and-continue boundary
  stays open pending §6a control-in-place (§8.2 — it is NOT fully
  dischargeable at Phase 7). If the review's reasoning contradicts the §8.2
  closed forms, the emitter does NOT ship until the discrepancy is resolved
  (Rule 13).
- **`select`-folded short value arms** (§8.4): the dominant C-level shape for
  small arms reaches the pass as a tainted `select` — 4.4's scope. 4.2 does
  not attempt partial select handling.

---
---

# Part III — the 4.3 increment: nested control (phase arms)

Written 2026-06-12 at 4.3 start (Rule 16), after a planning dialogue
(owner + agent) that re-grounded the increment against **real `clang -O1`
output** rather than the hand-stacked `control_swap_defer_nested.ll` shape.
Two author decisions from that dialogue are binding and fold in below:
**(1)** 4.3 goes **straight to the same-qubit nest** — the realistic shape
where an inner tainted branch reads what the outer arm just gated (`%7` on the
outer rail) — not a disjoint-qubit warm-up; the IR hands us the routing
(§12.2), so the disjoint case is a strict sub-case, not a cheaper first step.
**(2)** 4.3 stays **phase-only and depth-2**, mirroring how 4.1 (phase)
deliberately preceded 4.2 (value): the genuinely new plumbing (region-tree
walk, parent-rail threading, coordinated flatten, LIFO rail frees) is built
against the *easiest* data case before value-arm subtlety (the copy-out /
reverse-play composition across levels) is layered on. Module layout /
fixtures / WI sequence land as `IMPLEMENTATION-4.3.md` at build kickoff.

**The dialogue's load-bearing correction (binding framing).** The earlier
"nested reverse-play is a new uncomputation hazard" worry was **overstated and
is retracted**: the full faithful adjoint uncomputes unconditionally (`R†R = I`),
and for **phase arms 4.3 emits no reverse-play at all** — coherence is the
composed `icmp_inv` flag-strip (§12.3). The historical divergent-arm bug
(`divergent-arm-uncompute-soundness-guard`, reverted `543bd85`) was a
*single-register merge-point shortcut*, not the honest adjoint; swap-route
keeps exclusive arms on disjoint rails so that shortcut never forms (SCOPING
§3). The **quantum-correctness layer** for 4.3 is small and is settled (the
`c1∧c2`-no-Toffoli routing and the LIFO strip-order are cleared, §12.2/§12.3,
adversarial pre-clearance below). But the **emission STRUCTURE is genuinely
new** — not "one wire": the symbol set is unchanged from 4.1, yet 4.3 adds
(1) `ControlRegion` parent/child tree fields + a region-tree *builder* in
`ControlDetect`; (2) a recursive/scoped emitter that threads the parent rail as
the child's routed base; (3) a `lowerCompareToFlag` variant minting from a
rail-substituted operand; (4) a coordinated *whole-tree* flatten helper
(the per-region `flattenRegion` double-erases a shared merge — §12.4). Each is
verify-clean-invisible if wrong and so earns the Rule-13 written trace, not just
the per-fixture CHECK.

Relevant bd memories (Rule 0/11 — to be re-verified against the live tree at
build kickoff): `swap-route-detect-known-limits` (the nested decline is the
deferral this Part lifts; the one-tainted-region-per-fixture authoring rule —
`opt` exits on the FIRST diagnostic, so a nest's fixtures must pin the intended
level's string), `divergent-arm-uncompute-soundness-guard` (the shortcut this
design structurally avoids — see above), `swap-route-phase41-clearance` (the §8
probe-matrix precedent), `swap-route-derived-base-clearance` (block-lifetime
hole 2; the sequential-region SIGSEGV family §12.4 must not re-open),
`cwk-merge-phi-discriminator` (any new merge-φ-building path inherits the
discriminator gate), `mint-at-compare-decline-permanent` (the stale-condition
purity theorem the inner flag must respect across the nesting boundary),
`no-simulations-at-this-stage` (clearance = analytic/trace review, not
statevector).

**Adversarial pre-clearance (2026-06-12, Rule 13 — pre-code).** This PRD was
run through a 5-lens hostile adversarial review (routing-trace / strip-order /
detection-structural / classify-3c / completeness) + skeptic adjudication
*before* any implementation. **Verdict: the depth-2 homogeneous-phase nest
PHYSICS is CLEARED** — the §12.2 four-row `c1∧c2`-no-Toffoli routing and the
§12.3 LIFO strip-order survived independent statevector adjudication, matching
the controlled-in-place reference bit-for-bit (a phase nest copies nothing out,
so there is no §8.2-style kept-source deviation channel; coherence is exact).
**The accept-PREDICATE was `NOT-CLEARED`** on one false-accept silent miscompile
+ five spec-gaps; **all six are folded into §§11–14 below** (every fix is an
over-decline-safe guard or a factual correction — no design change). The blocker
was the **multi-register nest** (§12.4, the inner-condition-operand guard); the
others were the `declineClassicalMuxes` order (§12.6, corrected), the depth-3 /
both-arm decline strings (§12.7, corrected), the N-incoming RAUW collapse
precondition (§11 step 6 / §12.4), the temporal strip-misorder proof + ordered
CHECK (§12.3 / §13), and the dominator discriminator + coordinated-flatten
helper (§12.4).

**Re-clearance (2026-06-12, same day).** The amended predicate was then run
through a focused delta re-clearance (4 verifiers extracting real `-O1` IR +
fact-checking every citation against the live tree + a vacuity check on the
intended accept shape). **Verdict: `CLEARED-WITH-AMENDMENTS`.** All six defects
confirmed **closed**; the intended §11 same-qubit nest **survives every conjoined
guard** (verified byte-for-byte against real `-O1` — 4.3 is **not vacuous**); **no
surviving silent-miscompile, false-accept, or false-decline.** Four over-decline-
safe residuals were folded in: a §12.6 citation drift (`773`→`775`); the
symmetric-both-arm is a 3-incoming hoisted merge (declined by §12.4 invariant-(i),
not the §12.7 >3 cap — §12.7/§13 corrected); the §12.4 relaxation must keep the
**exactly-one-phi** discipline (real `-O1` emits two phis when inner cond/arm
touch different registers — §12.4/§13); and tree-homogeneity must **suppress §3c
emission** until the tree is proven homogeneous (else the inner-clobber fixture
reds — §12.5/§13). The **physics and the accept-predicate design are now
Rule-13-cleared**; the only clearance still owed is the **implementation-time §13
gate** (the written `(f1,f2)` trace + the linked e2e golden + green `ctest`, when
the emitter lands).

---

## 11. Scope (4.3)

**In scope — the depth-2 homogeneous-phase nest.** Lower a tainted-condition
`br i1` **diamond** whose single content arm itself contains a tainted-condition
`br i1` **diamond**, both arm bodies **phase rotations** (`cq_phi` → `Rz`),
reconverging at one shared merge — the shape `clang -O1` actually emits for
`if (cond1(q)) { q = cq_phi(q, b); if (cond2(q)) { q = cq_phi(q, a); } }`
(measured §12.1):

```
Pred:  %f1 = icmp …(q)           ; outer condition, tainted
       br i1 %f1, Mid, Merge
Mid:   %g  = cq_phi(q, b)        ; outer-arm intervening phase gate(s)
       %f2 = icmp …(%g)          ; inner condition — reads the GATED value %g
       br i1 %f2, Arm, Merge
Arm:   %h  = cq_phi(%g, a)       ; inner-arm phase gate(s)
       br Merge
Merge: %m  = phi [%h, Arm], [%g, Mid], [%q, Pred]   ; 3-incoming
```

Emission is the **same emitter applied as a region-tree walk**, the inner level
routing on the **outer arm's live rail** (§12.2):

1. **Outer mint + route-in.** `%f1 = icmp_hl(q, …)`; `rail1 = alloc(0)`;
   `cqrt_cswap(%f1, q, rail1)` (¬flag arms X-bracketed, as 4.1).
2. **Replay the outer arm body on `rail1`.** The intervening `cq_phi` →
   `cqrt_rz(rail1, b)` verbatim/uncontrolled (the 4.1 phase replay).
3. **Recurse into the inner region with base := `rail1`.** Inner mint
   `%f2 = icmp_hl(rail1, …)` — **from the rail, not the original `q`** (§12.2);
   `rail2 = alloc(0)`; `cqrt_cswap(%f2, rail1, rail2)`; replay inner arm
   `cqrt_rz(rail2, a)`; `cqrt_cswap(%f2, rail1, rail2)` route-back.
4. **Inner clean-up, inside the outer bracket (LIFO).** `cqrt_free(rail2)`
   (`Rz|0⟩=|0⟩` ⇒ `rail2` is `|0⟩`); strip the inner flag
   `icmp_hl_inv(rail1, …)` **against `rail1`, before the outer route-back**
   (§12.3); `cqrt_free(%f2)`.
5. **Outer route-back + clean-up.** `cqrt_cswap(%f1, q, rail1)`;
   `cqrt_free(rail1)`; strip the outer flag `icmp_hl_inv(q, …)`;
   `cqrt_free(%f1)`.
6. **Rewire + flatten.** RAUW the 3-incoming merge `phi` → `q`'s final handle;
   erase both `br`s, both compares, the `phi`; flatten `Pred`/`Mid`/`Arm`/`Merge`
   into one straight-line block in **one coordinated inner→outer pass** (§12.4).
   **Binding precondition (the N-incoming RAUW-collapse gate, `cwk-merge-phi-
   discriminator`):** a single-value RAUW of an N-incoming `phi` is the classic
   dropped-edge silent miscompile *unless every incoming resolves — post-rotation-
   lowering, through the `cq_phi` diagonal-alias closure — to the SAME `i32` base
   handle*. That holds for the §11 shape only because every gate is diagonal `Rz`
   (basis-preserving), so all three incomings (`%h`, `%g`, `%q`) collapse to `q`'s
   one handle. Any nested merge with an incoming carrying a *distinct* base handle
   **declines `control flow`**, never RAUW-to-first-incoming (the npu.1 collapse
   bug). This is a homogeneity check on the **value** domain, distinct from
   §12.5's phase/value-**class** homogeneity; both must pass.

The conditional phase lands on `q` iff `f1 ∧ f2` — **no conjunction ancilla, no
`cqrt_toffoli`** (§12.2). **No new runtime ABI** — reuses every symbol 4.1 used.

Targets: new `.ll` contracts pinned from real `-O1` output
(`control_swap_nested_phase_diamond.ll` and its polarity/derived-base/decline
siblings — IMPLEMENTATION-4.3 §5) and ≥1 C-sourced e2e golden.

**Out of scope (4.3) — see §14:** outer `if/else` nesting (else-nest / both-arm
nest), depth > 2, **any** value arm in the tree (pure-value or mixed-with-phase),
multi-register nests (route `q`, gate a disjoint `p`), nested `select`/`switch`.
Each declines loudly.

---

## 12. Design decisions (4.3)

Each resolved 2026-06-12 at 4.3 PRD time (owner dialogue) and binding.

### 12.1 The `-O1` shape reality — nesting exists ONLY with an intervening tainted op (measured 2026-06-12)

Rule 9/11 — measured against `clang -O1` on this tree, not guessed. The
scope-defining fact, and the reason `control_swap_defer_nested.ll`'s hand-stacked
3-incoming merge is **not** what real source produces:

- **`if (q>5) { if (q<9) { φ } }`** (no code between the branches) **folds to a
  single flat diamond** — `%c = icmp ult (q-6), 3; br %c, …` — one `icmp`, one
  content arm. **Already lowered by 4.1.** Not a nest.
- **`if (q>5 && q<9) { φ }`** — **identical fold.** Not a nest.
- **`if (q>5) { φ_a } else { if (q<3) { φ_a } }`** (same gate both sides) —
  **folds to one diamond** (OR-combined range). Not a nest.
- **`if (q>5) { φ_b; if (q<9) { φ_a } }`** (a tainted gate **between** the
  branches) — **stays a true nest**, and the inner condition is `icmp slt %7, 9`
  where `%7 = cq_phi(%4, b)` is the **outer arm's gate output**, at a 3-incoming
  merge (the §11 shape).

Consequence (binding): the **trigger for 4.3 is a non-foldable tainted op
between an outer tainted branch and an inner one** — which is the *normal* shape
of quantum code ("rotate, then branch again on the result"). The "obvious"
nested sources are a 4.1 concern, already green. 4.3's accept-fixtures are
therefore pinned from **real `-O1` output** (the §8.4 precedent — document, don't
fight, the canonicalizer); a hand-authored 3-incoming merge whose inner condition
reads the *un-gated* `q` is rejected at authoring time as a shape `-O1` never
emits (it would have folded).

### 12.2 The one new mechanism — route on the enclosing rail; mint the inner flag from it; `c1∧c2` falls out

This is the whole of 4.3's novelty over 4.1, and it is a **wire, not a physics
problem**. Today the emitter is a flat loop over independent regions
(`SwapRouteEmit.cpp` — `Q` is read from the merge `phi`/chain base and routed by
`emitRoute`); the inner flag would be minted from a `CmpInst` operand by SSA
identity (`lowerCompareToFlag`). Under the §11 shape that operand is `%g` (the
gated value), whose amplitude — after the outer route-in `cqrt_cswap(%f1, q,
rail1)` — physically lives on **`rail1`**, not on the original `q` register
(which holds `|0⟩` on the `f1=1` path). Therefore:

> **The inner region's routed base IS the outer arm's live rail.** The inner
> flag is minted `icmp(rail1, …)`, the inner route-in cswaps `rail1`, and the
> inner flag is stripped against `rail1` (§12.3). The emitter threads the
> parent rail down a **region-tree walk** as the child's base.

The SSA already names this for us *when the inner condition reads the gated
value*: `%g` is the outer-arm gate result, and the emitter has just placed that
value on `rail1` (step 2). So the emitter is not inventing a routed value — it
follows the edge `-O1` drew, onto the rail it just used. A `lowerCompareToFlag`
variant that mints from a substituted (rail) operand is the concrete new code.

**Binding precondition — the mint-from-rail guard (§12.4; adversarial
pre-clearance, the multi-register false-accept).** The above is sound ONLY when
the inner condition operand IS the parent-routed base (`%g`'s lineage). It is
**not** automatic: `if(q>5){ p=cq_phi(p,b); if(q<9){ p=cq_phi(p,a); } }` —
condition on `q`, arms gating `p` — compiles under real `-O1` to a 3-incoming
merge over `p` whose skip edges are all `p`-lineage (passing the §12.4 merge
check) **yet the inner condition reads `q`, which is not on `rail1` (which holds
`p`)**. Minting the inner flag from `rail1` there computes the wrong predicate →
verify-clean silent miscompile. So 4.3 **requires the inner tainted-condition
operand to lie in the diagonal-alias closure of the value the parent routed onto
`rail1`**; any inner branch reading a register outside that closure **declines
`nested control flow`** (the multi-register nest, §14). This guard, not the
merge-edge agreement, is the load-bearing accept signal (§12.4 makes it binding).
**Companion constraint:** every intervening outer-arm gate (step 2) must be a
`cq_phi` (diagonal `Rz`); a non-`cq_phi` intervening gate (a `cq_theta`/`Ry`, or
a value op) breaks both basis-preservation and mint-from-rail and **declines**
(string per the arm-class / stale-condition guard that fires, §12.5/§12.6).

**`c1 ∧ c2` with no conjunction ancilla (binding correctness claim — Rule 13
trace owed).** Because the inner route-in operates on `rail1`, the inner cswap
only moves a non-`|0⟩` value within the `f1=1` sub-population:

| `(f1,f2)` | `rail1` after step 2 | inner route+gate+route-back | reaches `q` |
|---|---|---|---|
| `(0,·)` | `\|0⟩` (q never routed in) | cswaps move `\|0⟩↔\|0⟩`, `rz(\|0⟩)=\|0⟩` | nothing — `q` keeps `%q` |
| `(1,0)` | `g(q)` | `%f2=0`: no inner swap; `rail1` keeps `g(q)` | `g(q)` — outer phase only |
| `(1,1)` | `g(q)` | `%f2=1`: route to `rail2`, `rz`, route back | `h(g(q))` — both phases |

The inner effect lands on `q` iff `f1 ∧ f2`, the conjunction implicit in the
data dependency (`%f2` is computed from `rail1`, which carries the value only
when `f1` fired). This is precisely SCOPING §6a's "no flag-conjunction Toffoli."
The `_controlled`/conjunction path is the **control-in-place** alternative
(§6a), which 4.3 does **not** take — confirmed by the owner: keep the routing.
The four-row table is the **adversarial trace** §13 requires written and
reviewed before emission ships (the rows are `(f1,f2)` basis combinations; Rule
13, no simulation).

### 12.3 No reverse-play for phase nests — flag-strip composition, and the strip ORDER is load-bearing

For phase arms 4.3 emits **no per-rail adjoint / reverse-play** (SCOPING §3, the
4.1 inheritance): each rail is `|0⟩` for free (`Rz|0⟩=|0⟩`) and coherence is the
composed `icmp_inv` flag-strip. The uncompute "ordering hazard" raised in
planning is therefore **not present for phase nests** — there is nothing to
reverse-play. Reverse-play returns only with value nests (out of 4.3 scope,
§14) and with user `cq_invert` (Phase 7), where it is the honest full adjoint
(LIFO by construction — no shortcut).

What **is** load-bearing is the **flag-strip order**, and it is the one place a
flat-loop emitter (stripping each region's flag at its own merge) silently
miscompiles:

> **The inner flag must be stripped against `rail1` BEFORE the outer
> route-back `cqrt_cswap(%f1, q, rail1)`.**

Proof obligation — the **temporal** misorder, witnessed on the `f1=1`,
`c2(k)≠c2(0)` population (corrected per pre-clearance; the realistic flat-loop
bug is *temporal*, not a wrong-register substitution — the mint-from-rail design
§12.2 never strips against `q`). The inner flag is minted `%f2 = icmp(rail1)`
while `rail1` holds the routed value `g(q)`. A flat-loop emitter that strips
`%f2` against the **correct** register `rail1` but **after** the outer route-back
`cqrt_cswap(%f1, q, rail1)` reads a different value: the route-back empties
`rail1` to `|0⟩` on the `f1=1` path, so `icmp_inv(rail1=|0⟩)` recomputes
`c2(0)`, leaving `%f2 = c2(k) ⊕ c2(0)`. For any `k` with `c2(k) ≠ c2(0)` (e.g.
`k=7, c2 = ·<9`: `c2(7)=1, c2(0)=1` — pick `c2 = ·>3`: `c2(7)=1, c2(0)=0`) the
flag is left **`1` — dirty** → `cqrt_free(%f2)` is a hidden measurement
collapsing `q` (Rule 6). The two binding sub-constraints, both owned by the
emitter (not the flat loop): **(i)** inner *route-back* before inner *strip*
(restores `rail1`'s mint value), and **(ii)** inner *strip* before the outer
*route-back* (`rail1` not yet emptied). The strip-correctness invariant is
verified on **all four `(f1,f2)` rows** (the §12.2 table) — every rail/flag
provably `|0⟩` in population, every `cqrt_free` a clean reset. This order is the
§13 Rule-13 trace's second obligation, and because it is **order-blind to the
symbol multiset** (the misordered emitter produces the identical four `cqrt_free`
/ zero `_controlled` / zero `phi i32` / `opt -verify`-clean output), it also
needs a **targeted ordered FileCheck** (§13), not just the structural CHECKs.

### 12.4 The N-incoming merge, coordinated flatten, and the block-lifetime SIGSEGV

Two live single-region assumptions break under nesting and must be lifted
deliberately:

- **`soleMergePhi` 2-incoming cap** (`ControlDetect.cpp:76`) rejects the §11
  3-incoming merge outright. 4.3 relaxes it to recognize the **specific**
  `{[%h, Arm], [%g, Mid], [%q, Pred]}` triple: the arm edge (inner-gate value)
  plus **two skip edges** that must each be the *identity straight-through* of
  their level's base. Edge-structure: the outer-skip (`[%q, Pred]`) and
  inner-skip (`[%g, Mid]`) must carry the **same routed lineage** (`%g` is `%q`'s
  rail value after the outer gate — a diagonal-alias of `%q`); a merge whose
  edges carry *distinct independently-derived* bases is **declined `control
  flow`** (the §11-step-6 N-incoming RAUW-collapse gate, `cwk-merge-phi-
  discriminator`; the old 3-distinct-angle dangling-φ bug). **This merge-edge
  agreement is NECESSARY-NOT-SUFFICIENT** (mirroring §8.3's f64 fencing — it is
  never the sole accept signal): the multi-register false-accept
  (`if(q>5){ p=cq_phi(p,b); if(q<9){ p=cq_phi(p,a); } }`) passes it (all skip
  edges are `p`-lineage) yet must decline. **The relaxation also carries forward
  `soleMergePhi`'s existing exactly-one-phi discipline** (`ControlDetect.cpp:72`):
  a 3-incoming merge block with **>1 `phi`** — which real `-O1` emits when the
  inner condition and the inner arm touch *different* registers
  (`if(q>5){ q=cq_phi(q); if(q<9){ r=cq_phi(r); } }` → a `q`-lineage phi **and** an
  `r`-lineage phi) — **declines `control flow`**. (Routing only the first phi
  would strand the second as a dangling 3-incoming tainted phi → `kMsgClassicalPhi`
  on a mutated module, §12.6.) A two-phi decline probe pins it (§13).
- **The mint-from-rail / inner-condition-operand guard (BINDING — the
  pre-clearance blocker, the actual accept signal).** Accept a nested region
  ONLY when the **inner tainted-condition operand lies in the diagonal-alias
  closure of the value the parent routes onto `rail1`** (i.e. the inner condition
  reads the same lineage the outer level threads down — `%g`, an `Rz`-alias of
  `%q`). An inner branch whose condition reads a register *outside* that closure
  (the multi-register nest: condition on `q`, data on `p`) **declines `nested
  control flow`** — `classifyArms` today keys solely on the merge-phi incomings
  and never ties the inner condition operand to the routed base, so without this
  guard the wrong inner predicate is minted (verify-clean). A real-`-O1`
  distinct-register decline fixture pins it (§13).
- **`flattenRegion` double-erases a shared merge** (`RegionFlatten.cpp:86`
  unconditionally `eraseFromParent()`s `Merge`). In a nest `Mid`, `Arm`, `Merge`
  are shared across the two levels; calling the **per-region** helper once per
  region erases `Merge` on the first call and **dereferences freed memory on the
  second** (the documented sequential-region SIGSEGV, `swap-route-derived-base-
  clearance` hole 2, `mux-exch-5bl-widening-nested-merge-guard`). So 4.3 **does
  NOT reuse `flattenRegion` per-region** (correcting the earlier "reuse in one
  coordinated pass"): it adds a **new whole-tree coordinated flatten helper**
  that captures every block identity before the first erase, splices the single
  shared `Merge` **exactly once**, and erases `{Pred-chain, Mid, Arm, Merge}`
  each exactly once.
- **Nest-vs-sequential discriminator (self-sufficient — corrected).** The
  dominator check (inner `Pred` dominated by the outer arm) is **necessary-not-
  sufficient**: the both-arm nest passes it too (each inner `Pred` *is* an outer
  arm) yet must decline. The coordinated-pair permit therefore **conjoins three
  invariants, all captured before any mutation**: (i) the outer region is a
  **one-content-arm diamond** (NOT `if/else` — both-arm/else nesting is §14
  out-of-scope, excluded *here*, not incidentally); (ii) the standard diamond
  single-predecessor invariants hold at **both** levels
  (`Arm->getSinglePredecessor()==Mid`, `Mid->getSinglePredecessor()==Pred`); and
  (iii) the inner `Pred` is dominated by the outer arm (not post-dominating the
  outer `Merge`, which is the sequential-overlap SIGSEGV shape → decline). **Do
  not blanket-decline shared merges** (the legitimate nest shares its merge and
  lowers correctly); decline only what fails (i)–(iii). A both-arm-nest decline
  fixture and a double-erase regression probe pin both (§13).

Rail frees follow the same LIFO as the flag strip (§12.3): `rail2` freed inside
the inner bracket, `rail1` after the outer route-back. `computeFreePoint`'s
naive post-dominator would push the inner-rail free to the *outer* merge
(strictly too late); 4.3 frees by **region-tree scope-exit**, emitter-driven,
not by post-dom reuse (for a phase rail the late free is `|0⟩`-clean and only
wasteful, but the discipline is fixed now so it stays correct when value nests —
where the late point is *dirty* — land).

### 12.5 §3c across the region tree — cross-region union provenance + tree-level homogeneity

The §3c clobber check is single-condition today (`condProvenance` over one
`Region.Condition`, `ArmClassify.cpp`). Nesting adds two cross-level hazards;
both are resolved conservatively:

- **Inner arm clobbers the OUTER condition's data.** If an inner arm
  value-changes a register the *outer* condition transitively reads, the outer
  flag-strip `icmp_inv(q)` reads a different basis than the mint → outer flag
  left dirty → hidden-measurement free. **Resolution (binding):** the cross-tree
  §3c check evaluates against the **union of every condition in the region tree**
  (enclosing + enclosed); an arm whose value-write hits that union is a clobber.
  **But in 4.3 this check is computed-but-VACUOUS** and is *not the gate that
  fires*: an inner value-write **is a value arm**, and tree-level homogeneity
  (below) declines **any** value arm in the tree **first** — so a 4.3 fixture for
  this shape declines with the homogeneity string (`mixed phase/value arm` /
  `value-arm swap-route`), **not** `arm rewrites a condition operand` (§13 pins
  the string that actually fires — pre-clearance OD). The union-§3c provenance is
  built now (so it is ready and correct) but goes *active* only with the
  value-nest increment, where a value arm can legitimately survive homogeneity.
- **Tree-level homogeneity.** `SawPhaseArm`/`SawValueArm` are per-region.
  A tree mixing a phase level and a value level has no single coherent merge
  (a CNOT copy of the value level dephases the phase level, Rule 7). **4.3
  requires every arm in the tree to be phase-class**; any value arm anywhere in
  the tree declines (string per §8.3 — `mixed phase/value arm` for a mixed
  tree, `value-arm swap-route` for a pure-value tree deferred to a value-nest
  increment). Homogeneity is hoisted from a per-region to a **tree** invariant.
  **Binding emission-ordering obligation (pre-clearance):** the tree-homogeneity
  gate must run as a SEPARATE, EARLIER step than per-region §3c *emission* —
  class-determination decides each arm's class **without emitting** the §3c
  `arm rewrites a condition operand` diagnostic (`ArmClassify.cpp:715`), which is
  gated behind the tree being homogeneous. Otherwise a genuinely-nested inner
  *value* clobber (`if(q>5){ q=cq_phi(q,b); if(q<9){ q=q*7; q=q+3; } }`, real
  `-O1`) classified per-region in isolation has `SawPhaseArm == false` *within the
  inner region* (the outer `cq_phi` lives in `Mid`, not an arm of the inner
  region), so the per-region mixed guard (`ArmClassify.cpp:634`) never fires,
  classification reaches the inline §3c emission, and fires
  `arm rewrites a condition operand` instead of the `mixed phase/value arm` the
  §13 fixture pins. So `classifyArms` must be refactored to split
  class-determination from §3c emission.

### 12.6 Guard interactions and per-level polarity (Rule 9)

- **`declineClassicalMuxes`** (corrected order — pre-clearance DEFECT). It runs
  **AFTER** `detectControlRegions` **and** `lowerControlRegions`
  (`CQLoweringPass.cpp` ~line 96), **not** before detection. So today a nest
  declines *inside detection* (`recoverRegion` → `RegionShape::Nested` → `opt`
  exits at the `DS_Error` before the guard runs) and the guard is never reached
  for a nest — the earlier "it passes the phi through" reasoning was vacuous, and
  the `liftOneRegisterMergePhi` exemption is **2-incoming-only**
  (`TaintPropagation.cpp:616` hard-returns at `getNumIncomingValues()!=2`) so it
  **cannot** lift the 3-incoming triple — *that sentence is struck.* The real
  **binding accept-path obligation:** the nested emitter is the **sole owner** of
  the 3-incoming merge `phi` and must RAUW→final handle + `scrubTaint` + erase it
  **before** `declineClassicalMuxes` runs; a surviving 3-incoming tainted `phi`
  would hit `diagnoseEscape(Phi, kMsgClassicalPhi)` (`TaintPropagation.cpp:775`;
  773 is the preceding `liftOneRegisterMergePhi` call)
  → a spurious `classical phi` decline on an already-mutated module (a
  half-lowered crash-equivalent). Probe: a `kMsgClassicalPhi`-never-fires
  assertion on an accepted nest. **Do NOT reorder the guard before detection**
  (it would decline the live 3-incoming nested phi outright).
- **Stale-condition guard** (`nonDiagonalGateBeforeBranch`) hard-requires
  `Cond->getParent() == R.Pred`. For the inner region `Pred == Mid`, and a
  non-diagonal gate in the outer arm before the inner compare sits in a
  different block. 4.3 keeps the conservative `Cond->getParent() != Pred →
  decline` posture for the inner level **unless** the inner compare and its
  `br` are co-located in `Mid` (they are, in the §11 shape), in which case the
  guard runs normally on `Mid`; an outer-arm non-diagonal (non-`Rz`) gate that
  rebases the inner condition's wire is caught by the **mint-from-rail**
  invariant (§12.2 — the inner flag is minted from `rail1`'s *current* value, so
  a diagonal `Rz` is transparent and a non-diagonal op on that wire would have
  made the arm non-phase, declined by homogeneity §12.5).
- **Per-level polarity.** `clang -O1` may make either level's gate arm the
  **false** successor (`ArmNegated`, the `cqrt_x` ¬flag bracket). Outer and
  inner negate independently; the straight-through edge selection
  (`getBasicBlockIndex`) must be applied per level against the 3-incoming phi,
  not the 2-edge assumption. Fixtures cover all four (outer-neg × inner-neg)
  combinations (§13).

### 12.7 Depth cap — depth-2 only

4.3 accepts **exactly one level of nesting**; the deeper / both-arm shapes are
declined by **two distinct prongs** (measured against real `-O1`, not assumed —
pre-clearance correction; the earlier "both-arm produces a 4-incoming merge"
framing was wrong for the symmetric case):

- **Depth-3** and the **asymmetric** both-arm nest (distinct gates per side)
  each produce a genuine **4-incoming merge**. Once recursion is enabled the
  outer matcher no longer short-circuits on "successor has a tainted br", and a
  4-incoming `phi` matches neither the 2- nor the relaxed-3-incoming shape → it
  would fall to `RegionShape::OffPattern` → the **generic `control flow`** string
  (`ControlDetect.cpp:164`). So 4.3 adds an explicit **depth cap** — *inner arm
  itself ends in a tainted `br`* **or** *the shared merge has >3 incomings* —
  emitting **`nested control flow`** **before** `soleMergePhi` and **before any
  inner-region emission** (also required to avoid the §12.4 block-lifetime hazard
  of descending into a sub-region whose blocks the outer flatten erases).
- The **symmetric** both-arm nest is **not** 4-incoming: `clang -O1` **hoists the
  shared outer gate** out of both branches → a **3-incoming i32 merge** (+ a
  separate FP angle phi), so the `>3-incoming` prong does **not** fire. It is
  declined instead by **§12.4 invariant-(i)** — the outer region is not a
  one-content-arm diamond (both successors carry tainted branches) → `nested
  control flow`.

The §13 fixtures are each pinned (Rule-12) to the string confirmed by **running
the real `-O1` IR** — depth-3 / asymmetric-both-arm (4-incoming, the cap) and
symmetric-both-arm (3-incoming + FP angle phi, §12.4 invariant-(i)). The cap is
**principled-for-now**: the §12.2/§12.3 traces are carried for **two** flags;
they generalize by the same parent-rail wire but are not auto-proven, so depth-3
accept waits on extending the trace (a recorded deferral, not a physics wall).

---

## 13. Done criteria (4.3)

- A tainted **depth-2 homogeneous-phase nest** (the §11 shape, pinned from real
  `-O1` output) lowers to the region-tree routed stream: outer mint/route-in →
  outer-arm `rz` on `rail1` → inner mint **from `rail1`** → inner route/`rz`/
  route-back on `rail2` → inner `free` + inner `icmp_inv` strip (against
  `rail1`, **before** the outer route-back) → outer route-back → outer `free` +
  outer strip, with `CHECK-NOT: _controlled`, `CHECK-NOT: cqrt_toffoli`,
  `CHECK-NOT: phi i32`, **exactly four `cqrt_free`** (`rail2`, `%f2`, `rail1`,
  `%f1`), and `opt -verify` clean.
- **A TARGETED ordered FileCheck pins the load-bearing strip sub-order**
  (§12.3 — the structural CHECKs above are order-blind: the temporal-misorder
  emitter produces the identical symbol multiset yet dirty-frees `%f2`). Pin
  *only* the one sub-order — the inner `cq_template_icmp_…_hl_inv` (strip of
  `%f2` against `rail1`) appears **before** the outer route-back
  `cqrt_cswap(%f1, q, rail1)` — with ordered `CHECK:`/`CHECK:` (do **not** pin
  the full sequence; the rail/flag frees float and a full-sequence pin
  over-constrains).
- The conjunction `f1∧f2` is implicit (no `cqrt_toffoli`, no conjunction
  ancilla); the four-row `(f1,f2)` basis trace (§12.2) and the strip-order proof
  (§12.3) are **written and cleared by independent adversarial review** (Rule
  13, analytic/trace — no simulation) **before** the emitter ships. A green
  suite alone does not clear it.
- **Decline fixtures** (each `not … | FileCheck`, mirroring the string
  character-for-character against the string that ACTUALLY fires — confirmed by
  running the real `-O1` IR through the pass, not assumed; one tainted region
  per fixture, `swap-route-detect-known-limits`):
  - **multi-register nest** (cond on `q`, arms gate `p`; the pre-clearance
    blocker, pinned from real `-O1` `/tmp/cq43_distinct.ll`-shape) →
    `nested control flow` (the §12.4 inner-condition-operand guard);
  - **depth-3** and **asymmetric both-arm nest** (genuine 4-incoming merges) →
    `nested control flow` (the §12.7 active cap);
  - **symmetric both-arm nest** (real `-O1` hoists the shared gate → 3-incoming
    i32 merge **+ FP angle phi**, NOT 4-incoming) → `nested control flow` (the
    §12.4 invariant-(i) "outer not a one-content-arm diamond" check, NOT the
    >3-incoming cap — pin from the real shape);
  - **two-phi merge** (`if(q>5){ q=cq_phi(q); if(q<9){ r=cq_phi(r); } }` — inner
    condition and inner arm on different registers; real `-O1` emits a q-phi AND
    an r-phi at the 3-incoming merge) → `control flow` (the §12.4 exactly-one-phi
    discipline);
  - **any value arm in the tree** → `mixed phase/value arm` (mixed) /
    `value-arm swap-route` (pure-value);
  - **inner-arm-clobbers-outer-condition** → **`mixed phase/value arm`** (the
    homogeneity string that fires first — an inner value-write is a value arm;
    §12.5 — **not** `arm rewrites a condition operand`, which is dead-in-4.3);
  - **non-`cq_phi` intervening outer-arm gate** (a `cq_theta`/value op between
    the branches) → the arm-class / stale-condition string that fires (§12.2);
  - **distinct-base merge edges** → `control flow` (the N-incoming RAUW-collapse
    gate, §11 step 6);
  - **nested `select`/`switch`** → the inner `select`/`switch` string (fired
    before nested-region recovery).
- **Adversarial probes:** all four (outer-neg × inner-neg) polarity combinations
  (§12.6); a derived-base outer condition that **provably survives `-O1`** as a
  real derived compare — an **FP carrier `q + 1.0 > 5.0`** (verified to emit
  `fadd`; note an *integer* `q+1 > 5` folds to `icmp sgt q, 4` and exercises
  nothing — document, don't fight, the canonicalizer, §12.1) — to drive the
  diagonal-alias closure; a same-merge **sequential** `if/else; if` that must
  still decline (the §12.4 dominator discriminator); and a **double-erase
  regression probe** asserting the coordinated whole-tree flatten erases the
  shared `Merge` exactly once (no SIGSEGV — §12.4).
- The `declineClassicalMuxes` pass-through is verified (§12.6) so the fixtures
  exercise live code.
- ≥1 **e2e trace golden** (C-sourced through the 4-stage pipeline, linked) diffs
  clean against its `.expected.log` — the only layer proving every emitted
  symbol resolves + signature-matches across two routing levels.
- 4.1/4.2 regression floor green (single-region phase and value fixtures
  unchanged; no nesting leakage into flat regions).
- Full `ctest` green; `gen_templates.py --check` clean (**no ABI change in
  4.3** — reuses 4.1's symbol set entirely).
- bd memory updated: `swap-route-detect-known-limits` (nested no longer a
  blanket decline — depth-2 phase accepted; depth-3 / if-else-nest / value-nest
  still declined), and a new memory for the **mint-from-rail + strip-order**
  invariant (the verify-clean-invisible 4.3 core rule).

---

## 14. Out of scope / open questions (4.3)

Honestly listed; each declines loudly until its increment.

- **Outer `if/else` nesting** — an inner diamond in the `else` arm, or in
  **both** arms (`if(c){if(a)}else{if(b)}` — two parent-flag subtrees, a
  4-incoming merge, doubled rail bookkeeping). The §12.2 routing trace and
  §12.4 flatten are framed for nesting in **one** arm; both-arm nesting waits on
  extending them to two sibling subtrees. Declines `nested control flow`.
- **Depth > 2** (§12.7) — principled-for-now deferral; the two-flag traces
  generalize but are not auto-proven. Declines `nested control flow`.
- **Value arms anywhere in the tree** — pure-value nest or mixed phase/value
  across levels (§12.5). The value path needs the copy-out / reverse-play
  composition over the region tree (the honest full adjoint as a genuine
  stack-unwind, §12.3) — sound in principle (LIFO by construction) but its own
  increment with its own §8.2-style boundary + Rule-13 clearance. Declines
  `mixed phase/value arm` (mixed) / `value-arm swap-route` (pure-value).
- **Multi-register nests** — any nest where the **inner condition operand is not
  in the diagonal-alias closure of the value the parent routed** (e.g. conditions
  on `q`, arms gating a disjoint `p`; or route `q`, inner condition on `p`).
  **Now actively DECLINED `nested control flow` by the §12.4 mint-from-rail
  guard** (the pre-clearance blocker — §12 supplies the recognizer, no longer a
  bare §14 assertion), with a real-`-O1` decline fixture (§13). (The
  **disjoint-qubit** nest where the inner condition reads a register never
  touched by the outer routing is a *strict sub-case* of §11 with a trivial
  parent-rail wire; it could lower under the same emitter, but the 4.3 contract
  and fixtures target the same-lineage shape per the owner's "go straight to
  same-qubit" decision, and the guard declines it conservatively until a
  multi-lineage increment proves it.)
- **Nested `select` / `switch`** — `select`/`switch` lowering does not exist
  (4.4/4.5); nesting an unbuilt construct declines on the inner construct's
  string, before any nested-region recovery.
- **Control-in-place §6a peephole for the nest** — the no-rail alternative
  (controlling the inner `Rz` on `f1∧f2` in place) reintroduces the
  `cqrt_toffoli` conjunction + ordered uncompute (the old bug class); explicitly
  **not** the 4.3 mechanism, reserved as the later footprint optimization.
- **Open question — depth-N generalization proof.** Whether the
  no-conjunction-ancilla routing and the strip-order LIFO compose to arbitrary
  depth by a single induction (almost certainly yes — each level is the same
  parent-rail wire) or hide a depth-dependent entanglement subtlety. Resolved
  before any depth>2 accept, not assumed.

---
---

# Part IV — the 4.4 increment: tainted `select` (controlled-XOR copy merge)

Written 2026-06-15 at 4.4 start (Rule 16), after an owner+agent design dialogue
that re-grounded the increment and **retracted two over-cautious framings** that
the 4.1/4.2/SCOPING text had carried for `select`. The dialogue's binding
conclusions fold in below; each is an over-*accept*-shrinking simplification, not
a new mechanism.

**The dialogue's two load-bearing corrections (binding).**

1. **There is no coherence decline forced by the merge itself.** SCOPING §7.1's
   residual worry — that copying a coherent operand "interfered downstream" (the
   old Phase-4 P6 rejection) — was the *teeth of freeing a dirty entangled rail*,
   which the swap-route never-free-dirty discipline (§3b, Rule 6) removes: the
   merge leaves operands **allocated**, never freed, so no hidden measurement
   forms. A `select` has **no arm operations** — it is a pure data merge
   `out = c ? a : b`, always a valid unitary (controlled-XOR copy into a `|0⟩`
   target; CNOT-copy is entanglement, **not** cloning). The §3c clobber is
   **structurally vacuous** (a `select` writes nothing). Downstream coherent
   re-use of an operand *separately from* the result is the user's own physics
   (design principle 10), not a compiler decline. **Net: the merge mechanism
   forces no rejection** — the SCOPING "P6 may relax for classical operands" hedge
   is resolved to "the *principle* is relaxation for all data operands." (The
   *shipped* 4.4 default is conservative — coherent operands decline; the §16.7
   clearance (WI-5, §8.11, 2026-06-16) confirmed that default and authorized **no**
   widening. The rejections that remain come from the angle/width gates and that
   conservative default, never from the merge itself.)

2. **The discriminator is the result's USE, not its type** — but the angle decline
   is a **NEW detection-time check 4.4 must add, not a pre-existing guard it
   inherits.** A `double` `select` is an *angle* only when its result reaches a
   rotation's **arg-1** slot (`cq_phi`/`cq_theta`); fed anywhere else
   (`fadd`/`fmul`/`fcmp`/`measure`/`ret`) it is ordinary fp **data**. The angle
   case's correct lowering is a controlled rotation (the §6a/rotation path), not a
   merge — so the principle "no FP *type*-guard in the merge" stands. **What the
   first PRD draft got WRONG (pre-clearance blocker, empirically verified):** the
   existing `declineTaintedAngle` (`RotationLowering.cpp:74`) keys on
   `taint.Tainted` membership and runs at `CQLoweringPass.cpp:110`, *after* control
   lowering at `:84` has already RAUW'd the tainted `%sel` to a **fresh untainted**
   `cqrt_alloc` handle — so it **cannot** backstop a merged angle-select; the angle
   position would leak into a handle (the f64/angle silent miscompile). Therefore
   4.4 **adds its own transitive, pre-mutation arg-1 detector check** (§16.2), and
   the `control_swap_defer_select_angle.ll` fixture **must be re-pinned** to the new
   string — it does *not* "stay green unchanged."

Consequently 4.4 is the **simplest** Phase-4 increment: a `select` is a single
SSA instruction inside one basic block — **no CFG diamond, no blocks to erase, no
`RegionFlatten`, no rail, no arm replay, no reverse-play, no flag-conjunction**.
The block-lifetime SIGSEGV family (§6 risk, §12.4) **does not apply**. The only
genuinely new surface is one ABI primitive (the controlled copy, §16.4); the rest
reuses the 4.1 flag mint/strip and free discipline verbatim.

Relevant bd memories (Rule 0/11 — re-verify against the live tree at build
kickoff): `swap-route-detect-known-limits` (the `select` decline at
`ControlDetect.cpp:229` is the deferral this Part lifts; the one-tainted-region-
per-fixture authoring rule — `opt` exits on the FIRST diagnostic);
`cwk-merge-phi-discriminator` (the classical-condition tainted-data `select` —
the SSA-untaken-incoming silent-miscompile class — is a **different** decline path
in `TaintPropagation::declineClassicalMuxes`, NOT touched by 4.4 — §16.8);
`rz-diag-flag-strip-invariant` (the flag-strip reuse — here even simpler: the
merge writes only the fresh `out`, never the condition lineage, §16.5);
`no-simulations-at-this-stage` (clearance = analytic/trace review, not
statevector); the f64/angle miscompile lesson (the angle-use decline, §16.2).

**Adversarial pre-clearance (2026-06-15, Rule 13 — pre-code).** This PRD was run
through a 5-lens hostile review (coherent-physics / angle-leak / ABI-emitter /
detection-fixtures / consistency) + skeptic adjudication that **empirically** lifted
the `ControlDetect.cpp` select decline, rebuilt the pass, and ran the angle fixture.
**Verdict: `CLEARED-WITH-AMENDMENTS`** — the controlled-XOR-copy *shape* is sound
(a `select` is a pure merge, §3c vacuous, leave-allocated is correct), but **one
BLOCKER + several MAJOR amendments are folded into §§15–18 below** (every one is an
over-decline-safe guard or a factual correction — no shape change). The **blocker**:
the angle-use decline is NEW detection-time logic with **no downstream backstop**
(the empirical finding above) — rewritten into §16.2 as a transitive pre-mutation
arg-1 detector check, with the angle fixture **re-pinned**. Folded MAJORs:
(a) a positive **scalar-ABI-width gate** + vector/i128/aggregate declines (else a
non-ABI select mints a null callee *after* acceptance — §16.9/§17); (b) the §16.5
"escaped" mechanism replaced by the **real use-based `isTerminalHandle`/`ChainWalk`**
behavior; (c) the new **fp-accepting `WidthDispatch` controlled-copy minter** (the
existing `copyFn` returns null for fp — §16.4); (d) the f32/f64 controlled-copy
**reverses the binding `cq_runtime.h` no-FP-copy invariant** — resolved by shipping
**5 integer widths first, fp-data declining** until the arg-1 gate is independently
cleared (§16.4); (e) a **concrete pre-mutation aliasing predicate** (or conservative
blanket decline — §16.9); (f) the **fan-out rule** (any transitive arg-1 use declines
the *whole* select — §16.2); (g) the **ROADMAP "no flag bracket"** contradiction
reconciled (§16.3). The two residual lenses that **must still clear before the
emitter ships** are the §16.7 coherent-operand boundary (is `%out` ever *wrong*, not
merely entangled?) and the §16.2 angle gate (is the transitive walk airtight?). The
**§16.7 conservative fallback is the DEFAULT** until cleared: accept classical/basis
operands; decline coherent (`Ry`/phase-carrying) operands.

---

## 15. Scope (4.4)

**In scope — the tainted-condition integer-data `select`.** Lower
`%sel = select i1 %c, T %a, T %b` where `%c` is **tainted** (derived from a
`cq_theta`, typically `%c = icmp <pred> %qc, K`), `%sel` is used as **data**, and
`T` is an **ABI-width integer** (`i1`/`i8`/`i16`/`i32`/`i64`) — into a controlled-XOR
copy merge into a fresh `|0⟩` result register. The merge is width-parametric within
that set. **fp-data widths (`f32`/`f64`) are staged out of this increment** (decline
until the §16.2 angle gate is cleared — §16.4 amendment d); the *principle* is
fp-as-data (type ≠ use), but the implementation ships integer-first for the
Prime-Directive-safe surface. The `select` arises from a C ternary `?:` or from an
`if/else` whose arms have **no side effects** and SimplifyCFG flattened to a `select`
(the dominant small-arm shape — §8.4, the 4.2-deferred "select-folded" form, §18).

**Two binding preconditions, both pure-SSA before any mutation (Rule 9):**
(1) the **angle gate** — `%sel` must not transitively reach a rotation arg-1, else
decline (§16.2, the blocker — there is no downstream backstop); (2) the **width
gate** — the result must be a non-vector ABI-width integer, else decline (§16.9,
the null-callee trap). Both run before the merge emits.

The lowered stream (canonical, the graduated `control_swap_defer_select.ll` shape
`select i1 %c, i32 %q, i32 %x` — one quantum-handle operand `%q`, one classical
operand `%x`):

1. **Mint the flag** from the condition: `%f = icmp_<pred>_<Wc>_hl(%qc, K)`
   (`Wc` = the *condition* operand width; the flag is the `i1` boolean handle).
   The original `%c` `icmp` becomes dead → erased.
2. **Alloc the result rail** `%out = cqrt_alloc_<Wd>(0)` (`Wd` = the *data*
   width; `|0⟩`).
3. **Copy the true-value on the flag.** Quantum-handle operand → directly
   `cqrt_copy_<Wd>_controlled(%f, %q, %out)`. (Classical operand → materialize
   first, step 4 form.)
4. **Copy the false-value on ¬flag**, X-bracketed (the 4.1 ¬flag convention):
   `cqrt_x(%f)`; (classical `%x`:) `%xh = cqrt_alloc_<Wd>(%x)`;
   `cqrt_copy_<Wd>_controlled(%f, %xh, %out)`; `cqrt_x(%f)`. The two copies write
   **disjoint branches** (f=1 vs f=0) → no double-write; `%out = c ? a : b`.
5. **Strip the flag** `%f0 = icmp_<pred>_<Wc>_hl_inv(%qc, K)`; `cqrt_free(%f)`.
   Structurally valid because the merge never wrote `%qc`'s lineage (§16.5).
6. **Rewire.** RAUW `%sel` → `%out`; erase the `select`. **No `phi`, no CFG
   edit, no `_controlled` rotation, no `cqrt_cswap`, no reverse-play.**

Operands (`%q`, the materialized `%xh`) are **left allocated** (no-cloning / §0
leak, §16.5); `%out` is the live result owned by Phase-3/5 straight-line rules
downstream. **Exactly ONE `cqrt_free`** (the flag).

Targets: graduate `control_swap_defer_select.ll` (decline → accept), plus new
`.ll` accept/probe contracts pinned from real `-O1` output (constant-operand,
runtime-classical-operand, polarity, quantum-operand) and ≥1 C-sourced e2e golden
(IMPLEMENTATION-4.4 §5).

**Out of scope (4.4) — see §18, each declines loudly:** angle-use `select`
(result transitively reaches a rotation arg-1 — the f64/angle family, §16.2);
**fp-data widths** (`f32`/`f64`, staged — §16.4); **vector / `i128` / pointer /
aggregate** result types (the width gate, §16.9); classical-**condition**
tainted-data `select` (the `declineClassicalMuxes` path, untouched); tainted
`switch` (4.5); a `select` operand that **aliases** the other's post-lowering
register (the hoisted-in-place-arithmetic corner); nested control containing a
`select` (declines on the `select` string, as today). A `select` has no arm ops,
so there is **no value-arm / mixed-arm / §3c-clobber sub-case** to classify.

---

## 16. Design decisions (4.4)

Each resolved 2026-06-15 at 4.4 PRD time (owner dialogue) and binding.

### 16.1 A `select` is a pure merge — strictly simpler than 4.1–4.3

No arm body (operands are already-computed values), so **nothing runs on a
rail** — there is no route-in/replay/route-back, no `Rz`-rail-clean, no method-B
copy-out, no reverse-play, no flag-conjunction. A `select` is also a **single SSA
instruction within one basic block** — there is **no control-flow diamond**, so
no block erasure, no `RegionFlatten`, and the block-lifetime SIGSEGV family (§6,
§12.4) is structurally absent. The merge is `out = c ? a : b` realized as two
controlled copies into a fresh `|0⟩` register. This is the SCOPING §5 "one or two
controlled-XOR copies into a fresh register," now committed.

### 16.2 The discriminator is USE not type — the NEW transitive arg-1 gate (BLOCKER)

A `double` `select` is an **angle** iff `%sel` reaches a rotation's **arg-1** slot
(`cq_phi`/`cq_theta`); then its lowering is a controlled rotation
(`Rz(u,θ_false)` then `cRz(c,u,θ_true−θ_false)` — the §6a/rotation path, not a
merge). Merging it as a data copy leaks the angle position into a handle — the
**f64/angle miscompile family**. The principle "no FP *type*-guard in the merge"
is correct; what is **wrong** is the first draft's claim that a *pre-existing*
guard catches it.

> **There is no downstream backstop (empirically verified, the pre-clearance
> blocker).** Lifting the `ControlDetect.cpp:226–229` select decline and rebuilding
> shows the angle fixture firing `declineTaintedAngle`'s
> "unsupported quantum-derived rotation angle" — **only because no select emitter
> exists yet** (the `cq_phi` survives to `lowerRotations`). `declineTaintedAngle`
> (`RotationLowering.cpp:74`) tests `taint.Tainted` membership of the arg-1 value
> and runs at `CQLoweringPass.cpp:110`. The select merge runs at `:84` and **RAUWs
> the tainted `%sel` to a fresh untainted `cqrt_alloc` handle `%out`** — so by `:110`
> the arg-1 test is false and the angle silently leaks. A green `opt -verify`
> proves nothing.

Therefore 4.4 **adds its own check** (binding):

- **Where:** in the select detector inside `detectControlRegions` — **pure SSA
  analysis, strictly before `lowerControlRegions` mutates** (Rule 9, detect-before-
  mutate, survives RAUW-to-handle).
- **What:** walk **all transitive users** of `%sel` through **value-preserving
  carriers** (`fpext`/`fptrunc`/`bitcast`/nested `select`/`phi`); if **any** reaches
  a rotation **arg index 1** (`@cq_phi_*`/`@cq_theta_*`), **decline the WHOLE
  select** — never merge for the data uses and rotate for the angle use (the
  **fan-out rule**: `%sel` can be tainted-as-data *and* feed arg-1 at once, because
  the arg-1 angle exclusion is per-operand-use, `TaintPropagation.cpp:298`; splitting
  it double-realizes the value = silent miscompile).
- **String:** the detector owns its diagnostic; `control_swap_defer_select_angle.ll`
  **must be re-pinned** to whatever string actually fires (confirmed against real
  `-O1` IR, not assumed — Rule 11). Re-pinning is an explicit §17 done-criterion, a
  deliberate baseline action (Rule 12); leaving the now-unreachable
  "select under quantum control" CHECK in place would mask a non-firing gate.
- **Probe:** a cast between select and arg-1 (`%w = fpext %sel; cq_phi(%qd, %w)`)
  proves the transitive (not just direct-user) walk; a `CHECK-NOT` asserts **no
  `cqrt_copy`/`cqrt_alloc` is emitted** for any angle-fed select; a dual-use fixture
  (`%sel` feeding both `cq_phi` arg-1 **and** a `measure`) pins the fan-out decline.

An **integer** `select` can never be an angle, so it always merges (subject to the
§16.9 width gate, §16.7 coherence boundary, §16.8 condition partition, §18).

### 16.3 The controlled-XOR-copy stream and the two widths

`out = c ? a : b` with `out = |0⟩`: `out ^= a` controlled on `f`, then `out ^= b`
controlled on `¬f`. The branches are disjoint (only one fires per basis branch of
`c`), so `out` ends as `c?a:b` with no collision. `¬flag` control reuses the
self-inverse `cqrt_x(%f)` bracket (the 4.1 convention). **Two widths are in play
and must not be conflated:** the **condition width `Wc`** keys the `icmp` flag
mint/strip (`cq_template_icmp_<pred>_<Wc>_hl[_inv]`); the **data width `Wd`** keys
the copies and the `out` alloc (`cqrt_copy_<Wd>_controlled`, `cqrt_alloc_<Wd>`).
They are equal only by coincidence (e.g. `select i1 (icmp i64 q), i8 a, i8 b` →
`Wc=i64`, `Wd=i8`).

**ROADMAP reconciliation (supersedes the "no flag bracket" shorthand).** The
ROADMAP 4.4 entry reads "no cswap routing, no flag bracket." The "no cswap routing"
half holds; the "no flag bracket" half is **stale and superseded here**: the ¬flag
false-value copy *requires* the self-inverse `cqrt_x(%f)` bracket because
`cqrt_copy_<Wd>_controlled` fires on `f=1`. The ROADMAP entry is updated to
"one self-inverse `cqrt_x` bracket for the ¬flag false-value copy (reused from
4.1)"; the PRD is authoritative for the mechanism.

**Bracket scope is order-sensitive (ordered CHECK, §17).** The merge's whole
correctness is the `dst=|0⟩` precondition (§16.4) **plus** the bracket tightly
enclosing **only** the second copy. A mis-bracketed emitter (e.g. `cqrt_x` before
*both* copies) double-writes `a` then `b` on the same basis branch yet produces the
identical symbol *multiset* — invisible to a count-only CHECK. §17 pins an **ordered
FileCheck** (`copy(f,a,out)` → `cqrt_x(f)` → `copy(f,b,out)` → `cqrt_x(f)`), the
4.3 §12.3 strip-order precedent.

### 16.4 New ABI — `cqrt_copy_<W>_controlled` (integer widths first; fp staged)

The merge needs a **flag-controlled** register copy; today `cqrt_copy_<W>`
(4.2) is **uncontrolled and integer-only** (`i1`/`i8`/`i16`/`i32`/`i64`):

```c
void cqrt_copy_<W>_controlled(int32_t ctrl, int32_t src, int32_t dst);
```

A **hand-written `cqrt_*` core ABI** addition (the `cqrt_copy`/`cqrt_cswap`
precedent), in `runtime/cq_runtime.{h,c}` — **not** the autogenerated template
surface, so `gen_templates.py --check` stays clean (YAML untouched), exactly as
4.2's `cqrt_copy` landed. Trace mirrors `cqrt_cswap` (no-arrow void, leading
`ctrl`): `cqrt_copy_<W>_controlled(h<ctrl>, h<src>, h<dst>)`. Self-inverse class
(transversal Toffoli, `dst` starts `|0⟩`) → **no `_inv` twin**; never frees,
consumes, or disentangles its source (Rule 8). It is the merge analogue of
`cqrt_cswap` (a controlled primitive that IS the mechanism — consistent with "zero
controlled *gates* on arm bodies," which is about arm replay, not merges).

**Width set — integer-5 first, fp deferred (amendment d, Prime-Directive-safe).**
4.4 ships `cqrt_copy_{i1,i8,i16,i32,i64}_controlled` and **declines fp-data
selects** (`value-arm swap-route`-class string) initially. Declaring
`cqrt_copy_{f32,f64}_controlled` **reverses the binding 4.2 §8.1 /
`cq_runtime.h:235–237` invariant** ("declaring `cqrt_copy_f32/f64` would be dead
ABI whose only possible caller is exactly the f64-as-data bug"). That reversal is
defensible *only* once the §16.2 transitive arg-1 gate is proven airtight (an fp
`select` that is data, not a leaked angle); until then fp-data declines, keeping the
two copy families width-symmetric and shrinking the false-accept surface. fp widths
are added in a follow-on once the fp-data accept path is independently cleared.

**The IR-side minter is genuinely new (amendment c).** `WidthDispatch::copyFn`
(`WidthDispatch.cpp:119–136`) is `void(i32 src, i32 dst)` — **no ctrl** — and
hard-returns `FunctionCallee()` for any non-integer width (`:129`). 4.4 adds a
**new minter** (e.g. `copyControlledFn`, or an extension of `ControlledSymbols`
which already mints `cswapFn`) producing `void(i32 ctrl, i32 src, i32 dst)`. **Do
NOT copy `copyFn`'s integer-only guard** — but with the deferral above the minter
need only cover the 5 integer widths in this increment; the fp-accepting form lands
with the fp-data clearance.

**Operand materialization.** A **quantum-handle** operand is copied directly
(it is already a register). A **classical** operand (compile-time constant **or**
runtime classical value — both lack a qubit register) is materialized first via
`%h = cqrt_alloc_<Wd>(value)` (`cqrt_alloc` already takes any `i32` init), then
copied. **Recommended (option A):** materialize and leave the scratch allocated
(a benign classical-valued §0 leak — trace-only runtime, qubits not scarce).
*Alternative (option B):* a controlled XOR-by-literal template
`cq_template_xor_<Wd>_hl_controlled(f, out, K)` avoids the scratch but reintroduces
a `_controlled` member of the autogenerated template family (touches the YAML /
SHA gate). **Default to A** — minimal ABI, all-core, no template `_controlled`
reuse. The PRD pins A unless the e2e/footprint argues otherwise.

### 16.5 Frees, leaks, and the structurally-valid flag-strip

**Exactly ONE `cqrt_free`** — the flag, freed after the strip (provably `|0⟩`).
Compare: phase/value diamonds free two (rail+flag), this frees one (no rail).
`%out`, both operands, and any materialized classical scratch are **NEVER freed**:
`%out` is the live result; operands and scratch are left allocated (freeing an
operand entangled with `%out` via the copy would be a hidden measurement —
Rule 6/8).

**The no-free behavior is use-based, not a mark (amendment b — the first draft's
"marked escaped-into-the-merge" mechanism does not exist).** `TaintPropagation` has
no `Escaped`/`Measured` set; escape is pure SSA-use analysis. The correct mechanism:
`cqrt_copy_<Wd>_controlled` is a **non-benign `CallInst` user** of its `src`, so
`isTerminalHandle(src)` (`ChainWalk.cpp:84–107`) is **false** and the Phase-5 spine
never selects `src` for `inverse + free`. **Binding obligation:** the controlled
copy **must be added to `ChainWalk`'s recognized user set** so
`forwardConsumerCount`/`recoverForwardChain` (`ChainWalk.cpp:131–159`) treat it
consistently — otherwise an operand that is *also* an upstream lineage handle of
another terminal trips the `forwardConsumerCount > 1` **fan-out bail** (`:137`) and
**silently drops that unrelated chain's uncompute** (a §17 no-spurious-free probe
pins this: an operand whose lineage also feeds a downstream rotation).

**Operand-disposition matrix** (the copy is an *additional* consumer of each
operand — for `(q>5)?q:x`, `%q` is read by the mint, the strip, **and** the copy):
(i) operand also **Measured** downstream → the measure owns it, no free (FreePoint's
domain); (ii) operand also **Escaped** (`ret`/`cq_invert`) → the caller owns it;
(iii) operand with a **live downstream rotation/use** → the §16.7 channel-B
coherence-loss case (covered by the §16.7 clearance / conservative fallback).

**The flag-strip is structurally valid**, not merely "Rz-preserves-basis" valid as
in 4.1: the merge writes **only** the fresh `%out` and never touches `%qc`'s
lineage, so `icmp_<pred>_<Wc>_hl_inv(%qc, K)` recomputes the same boolean and returns
the flag to `|0⟩` unconditionally — the cleanest strip in Phase 4.

### 16.6 §3c is structurally vacuous

The §2.5/§8.3 clobber rejection — an arm performing a value-changing write to a
quantum variable the condition reads — **cannot fire** for a `select`: a `select`
has no arm operations and writes nothing; it only reads its operands and produces
`%sel`. There is no clobber predicate to evaluate and **no §3c decline fixture**
for 4.4 (its absence is itself the contract — a `CHECK-NOT` on the clobber string
in an operand-is-the-condition fixture, §17).

### 16.7 The coherent-operand boundary — accept, with the §8.2-analogue clearance owed

A **classical/basis-valued** operand copies non-destructively, leaves no
entanglement of concern, and is **unconditionally fine**. A **coherent**
(`Ry`-superposition / phase-carrying) operand, CNOT-copied, leaves `%out`
**entangled** with the operand (`α|0⟩_a|0⟩_out + β|1⟩_a|1⟩_out`). The claim 4.4
makes: **`%out` is the correct `c?a:b` in the computational-basis / reversible
model** (each basis branch holds the right value), the leftover operand is
**left allocated** (no-cloning forbids a disentangled copy; SWAP-move is the only
reclaim and is reserved for the dead-operand `cqrt_cswap` path, not the keep-live
merge — Rule 8).

**Two channels, exactly as 4.2 §8.2 (amendment, sharpened).** The hazard is not
only the cross-term between `%out` and the operand. CNOT-copying a coherent operand
also **kills the off-diagonal of the operand's OWN marginal** — so a *standalone*
downstream use of that operand (one the user never connects to `%out`) is dephased
(channel B), not just `%out`-vs-operand interference (channel A). The clearance must
reason against **both** channels, the same root cause as 4.2 §8.2.

**Conservative fallback is the DEFAULT until cleared.** Per the Prime Directive,
4.4 **ships accepting classical/basis-valued operands only and declining coherent
(`Ry`/phase-carrying) operands** (`value-arm swap-route`-class string), widening to
full coherent accept **only after** an independent Rule-13 clearance answers the
hostile question — whether any basis/phase combination makes `%out` *wrong* (not
merely entangled). The dialogue's position is full accept; the clearance adjudicates
the widening. `cq_invert` (Phase 7) restores fidelity only for
compute→use→uncompute, not keep-and-continue, so it does not discharge the boundary.
A §17 probe pins a coherent operand whose lineage also feeds a downstream `cq_phi`
(asserting the conservative decline until widened).

### 16.8 The classical-CONDITION tainted-data `select` is a different path — untouched

4.4 lowers only **tainted-condition** selects. A `select` with a **classical**
condition over **tainted data** (`select i1 %classical, %tainted_a, %tainted_b`)
is the `TaintPropagation::declineClassicalMuxes` path
(`kMsgClassicalSelect` — "cq taint escape: tainted value muxed by a classical-
condition select"), declined for the SSA-untaken-incoming silent-miscompile class
(`lowering_reject_classical_mux_select_*.ll`, the `*_onereg` one-register-lift
guard). That is **not** quantum control — there is no quantum flag to route — and
**stays declined**. 4.4 must not relax it; the two paths share the `SelectInst`
opcode and nothing else (a regression fixture pins it green, §17).

### 16.9 Width gate, polarity (Rule 9), detection-before-mutation, distinct operands

**Positive scalar-ABI-width gate (amendment, the null-callee trap).** Today the
select detector (`ControlDetect.cpp:227–229`) inspects **only** the condition's
taint — never the operand/result type. With the decline lifted, a tainted-condition
**vector / `i128` / pointer / aggregate** select would be **accepted at detection**
and then mint `cqrt_copy_<empty>_controlled` — a **null `FunctionCallee` minted
after the mutation commits** (crash-on-valid-input, a detect-before-mutate
violation). 4.4 adds a positive gate **mirroring the `ArmClassify.cpp:820–838`
ordering**: the §16.2 **FP-USE fence first**, then require a **non-vector scalar
result with non-empty `abiWidthFromType`** (and, per §16.4, an **integer** width
this increment) — decline otherwise. The width check is necessary-not-sufficient and
runs only **after** the FP-use fence. Vector / pointer / aggregate / `i128` selects
are §18 out-of-scope with explicit decline fixtures.

Detection is pure analysis by SSA-value identity **before any mutation** (survives
rotation lowering's RAUW). A `select` has **no successor blocks** to swap, but `-O1`
still canonicalizes the `icmp` predicate / operand order — the flag mint uses the
**actual emitted predicate**, and the select's true-value (operand 1) maps to `f=1`,
false-value (operand 2) to `f=0`; a polarity probe pins it.

**Distinct-operand / aliasing guard — concrete predicate (amendment).** The two
operands must resolve to **disjoint post-lowering qubit registers**; an operand that
aliases the other's register (the hoisted-in-place-arithmetic corner, §18) would make
one copy read a register the merge is muxing against. The dangerous alias only
becomes literal *after* rotation lowering's RAUW-to-handle, which pre-mutation SSA
cannot see directly, so the guard is one of:
- **Conservative (recommended, Prime-Directive-safe):** accept only when each operand
  is a **constant** or an SSA value with **provably-disjoint post-lowering handle
  identity** — in practice declining the whole hoisted-in-place-arithmetic family. A
  fresh **out-of-place** template result (e.g. `q+1` → a new `cq_template_add` handle,
  distinct from `q`) satisfies this, so the common `(q>5)?q:q+1` form accepts.
- **Concrete (if the conservative form proves too tight):** compute each operand's
  **diagonal-alias closure** (the 4.3 §12.4 `diagonalAliasHit` machinery,
  `ArmClassify.cpp:219–228`) — the registers rotation/template lowering will collapse
  — and decline when the two closures **intersect**.

The §17 decline fixture is pinned to **whichever predicate is chosen** (no
done-criterion fixture for a guard with no defined predicate), with a matching accept
fixture (distinct closures) and decline fixture (intersecting closures).

---

## 17. Done criteria (4.4)

- A tainted-condition **integer-data `select`** lowers to the merge stream the
  regenerated `.ll` fixtures pin (`icmp_<Wc>_hl` flag → `alloc <Wd>(0)` →
  `copy_<Wd>_controlled` on flag → `cqrt_x` / `copy` / `cqrt_x` on ¬flag →
  `icmp_<Wc>_hl_inv` strip → `cqrt_free`), `%sel` RAUW'd to `%out`, with the
  **narrowed** `CHECK-NOT: cqrt_{rz,ry}{{.*}}_controlled` (the bare
  `CHECK-NOT: _controlled` used in Parts I–III **cannot** be reused — it would
  collide with the intended `cqrt_copy_<W>_controlled`), plus
  `CHECK-NOT: cqrt_cswap`, `CHECK-NOT: phi i32`, **exactly ONE `cqrt_free`** (the
  flag — `CHECK-COUNT-1` + `CHECK-NOT` for a second), `%out`/operands/scratch
  never freed, and `opt -verify` clean.
- An **ordered FileCheck** pins the bracket scope (§16.3): `copy(f,a,out)` →
  `cqrt_x(f)` → `copy(f,b,out)` → `cqrt_x(f)` (a count-only CHECK passes a
  mis-bracketed double-write — the 4.3 §12.3 ordered-CHECK precedent).
- `cqrt_copy_<W>_controlled` lands for the **5 integer widths** in the
  hand-written core ABI with the pinned signature/trace; the runtime trace test
  covers them; the **new `WidthDispatch` controlled-copy minter** (not a clone of
  the fp-rejecting `copyFn`) mints them; `gen_templates.py --check` stays clean
  (YAML untouched). fp widths are deferred (§16.4).
- **`%out` carries no measurement and no `phi`** — the select step emits zero
  `cqrt_measure`; any measure in a fixture is the user's own `cq_measure`
  lowering (Rule 5 — a fixture variant that `ret`s `%sel` proves no measure
  appears).
- **Decline fixtures** (each `not … | FileCheck`, mirroring the string
  character-for-character **against the string that ACTUALLY fires** — confirmed
  by running real `-O1` IR through the pass, not assumed; one tainted region per
  fixture):
  - **angle-use `select`** (`%sel` transitively feeds a `cq_phi`/`cq_theta`
    arg-1) → declines via the **new §16.2 detector check**;
    `control_swap_defer_select_angle.ll` is **RE-PINNED** to the string the
    detector emits (a deliberate baseline action, Rule 12 — *not* "stays green");
    a `CHECK-NOT` asserts **no `cqrt_copy`/`cqrt_alloc`** is emitted for it;
  - **transitive-cast angle** (`%w = fpext %sel; cq_phi(%qd, %w)`) → same decline
    (proves the walk follows value-preserving carriers, not just direct users);
  - **dual-use fan-out** (`%sel` feeds a `cq_phi` arg-1 **and** a `measure`) →
    declines the whole select (§16.2 fan-out rule — never split);
  - **fp-data `select`** (`f64` result feeding `fadd`/`measure`) → declines
    (staged out, §16.4) — re-pinned to accept once fp is cleared;
  - **vector / `i128` / aggregate** result → the width-gate string (§16.9);
  - **classical-condition tainted-data `select`** → the `declineClassicalMuxes`
    string, untouched (`lowering_reject_classical_mux_select_*.ll` stay green —
    §16.8);
  - **aliasing operand** (intersecting diagonal-alias closures / not provably
    disjoint) → the §16.9 aliasing guard string (pinned to the chosen predicate);
  - **coherent operand** (`Ry`/phase-carrying) → declines under the §16.7
    conservative default (until the boundary is cleared);
  - **nested `select`** → the inner-`select` string (as today).
- **Adversarial probes:** a polarity-canonicalized `icmp` (true/false-operand
  mapping, §16.9); a **constant-operand** `select` (`(q>5)?5:7` — materialize
  path, §16.4); a **runtime-classical-operand** `select` (the first
  `cqrt_alloc_<Wd>(<runtime i32>)` emission — every existing emit site allocs a
  null constant only; confirm the value-literal trace line, §16.4); an
  **out-of-place-arithmetic operand** `select` (`(q>5)?q:q+1` — distinct closures,
  **accepts**, §16.9); a **no-spurious-free** probe (an operand whose lineage also
  feeds a downstream rotation — asserts the unrelated chain keeps its uncompute,
  §16.5); an **operand-is-the-condition-register** `select` (`(q>5)?q:x` — the
  structurally-valid strip + `CHECK-NOT` on the §3c clobber string, §16.5/§16.6).
- ≥1 **e2e trace golden** (`tests/e2e/slice_control_select*.c`, C-sourced through
  the 4-stage pipeline, **linked**) diffs clean against its `.expected.log` — the
  only layer proving `cqrt_copy_<W>_controlled` resolves + signature-matches.
- The **§16.7 coherent-operand boundary** (both channels) and the **§16.2 angle
  gate** are **cleared by independent Rule-13 adversarial review** (analytic/trace,
  no simulation) **before** the coherent/fp accept widens; a green suite alone does
  **not** clear it. **The shipped 4.4 default is the conservative form** (classical/
  basis integer operands accept; coherent + fp-data decline); the clearance gates
  each widening.
- 4.1/4.2/4.3 regression floor green (diamond/if-else/nested phase+value fixtures
  unchanged; no `cqrt_copy_<W>_controlled` leakage into non-`select` paths).
- Full `ctest` green; bd memory updated: `swap-route-detect-known-limits`
  (`select` no longer a blanket decline — tainted-condition data selects
  accepted; angle-use / classical-condition selects still decline), and a new
  memory for the **use-not-type discriminator + coherent-operand leave-allocated**
  invariant (the verify-clean-invisible 4.4 rules).

---

## 18. Out of scope / open questions (4.4)

Honestly listed; each declines loudly until its increment.

- **Angle-use `select`** — `%sel` *transitively* reaching a rotation arg-1
  (§16.2). Its lowering is a controlled rotation (§6a/rotation path), not a merge.
  Declined by the **new 4.4 detector check** (NOT a pre-existing guard — there is no
  downstream backstop once the merge RAUWs `%sel` to an untainted handle); the
  fan-out form (also feeding data) declines the whole select.
- **fp-data `select`** (`f32`/`f64` result not used as an angle) — *in principle*
  data (type ≠ use), but **staged out of 4.4** (§16.4): shipping
  `cqrt_copy_{f32,f64}_controlled` reverses the binding `cq_runtime.h` no-FP-copy
  invariant and is safe only once the §16.2 angle gate is independently cleared.
  Declines until the fp-data accept path lands.
- **Vector / `i128` / pointer / aggregate result types** — the §16.9 width gate;
  no `abiWidthFromType`, so a merge would mint a null callee. Declines.
- **Classical-condition tainted-data `select`** (§16.8) — the
  `declineClassicalMuxes` path; not quantum control, stays declined.
- **Tainted `switch`** — 4.5 (per-case routing / `icmp eq`-flag chain).
- **Aliasing operands** (§16.9) — an operand sharing the other's post-lowering
  qubit register (e.g. hoisted in-place arithmetic feeding one arm of the mux).
  Declines via the aliasing guard until a fan-out/aliasing analysis proves the
  copy-source and the muxed register are disjoint. The common out-of-place form
  (`(q>5)?q:q+1`, distinct result handles) is in scope.
- **`select`-folded short value arms** (the 4.2 §8.4 / §10 deferral) — a value
  `if`-arm whose ops SimplifyCFG hoisted to unconditional arithmetic + a mux
  reaches 4.4 as `select c, %computed, %orig`. The arithmetic is plain Phase-3
  lowering (unconditional); 4.4 merges the mux **iff** `%computed` and `%orig` are
  distinct live handles (§16.9). The case where the hoist made the arithmetic
  alias `%orig`'s register is the aliasing decline above. No `select`-specific
  arm-op handling is added.
- **Coherent-operand interference boundary** (§16.7) — inherent to keep-live
  copy (the §8.2 B-keep analogue): `%out` is faithful in the reversible model and
  the leftover is left allocated, but coherent re-use of an operand *apart from*
  `%out` decoheres under the entanglement (principle 10). Cleared by Rule-13
  adversarial review before ship; conservative fallback declines coherent
  operands. `cq_invert` (Phase 7) restores fidelity only for
  compute→use→uncompute patterns, not keep-and-continue.
- **One-copy degenerate merge** (an operand trivially `|0⟩`) — a footprint
  optimization (one controlled copy instead of two); out of scope, always emit
  two for correctness-first uniformity.
- **Open question — does the controlled copy want an `_hl` literal twin
  (option B)?** §16.4 defaults to materialize-then-copy (option A, all-core ABI).
  If the e2e footprint or a later phase wants no classical scratch, the
  `cq_template_xor_<W>_hl_controlled` family is the alternative (touches the YAML
  / SHA gate). Resolved at IMPLEMENTATION-4.4 kickoff against the real linked
  trace, not assumed.
