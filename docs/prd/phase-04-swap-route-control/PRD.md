# Phase 4 PRD — IR pass: RSSA swap-routed tainted control flow

Phase-specific design decisions, scope, and done criteria for lowering tainted
(quantum-dependent) `br` / `phi` by **routing data, not controlling gates**. This
PRD covers the **4.1 increment — phase arms (`Rz`)** in full (**Part I**, §§0–6 —
closed 2026-06-10, epic `e4baa67`), the **4.2 increment — value/permutation arms
(method-B)** in full (**Part II**, §§7–10 — written 2026-06-10 at 4.2 start,
Rule 16), and records the binding decisions for the later increments (4.3
nested, 4.4 `select`, 4.5 `switch`) so they survive between sessions and across
the freeze. The old **controlled-op** Phase 4 shipped and was removed wholesale
(commit `7cde677`); this PRD replaces its archived predecessor
([`docs/archive/old-design/phases/phase04-controlled-form/`](../../archive/old-design/phases/phase04-controlled-form/)).
It is a lean PRD — it memorializes the PRD-discovery decisions; the module-layout
/ fixture / commit-shape plans land as `IMPLEMENTATION.md` (4.1) and
[`IMPLEMENTATION-4.2.md`](IMPLEMENTATION-4.2.md) (4.2) alongside it.

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
  *(Recorded: bd memory `rz-diag-flag-strip-invariant` — DIAGONALITY, not the
  specific convention, is the load-bearing invariant; both conventions verified
  coherence-exact.)*

---
---

# Part II — the 4.2 increment: value/permutation arms (method-B)

Written 2026-06-10 at 4.2 start (Rule 16), after the status audit fixed the
entry gates: (i) this treatment; (ii) the SCOPING §7.6 `cqrt_copy_<W>`
resolution (§8.1 below); (iii) the SCOPING §8 method-B oracle demo, owed
**before/with** the core emitter change per Rule 13 (it has never been
simulated, and §8 records a path-B demo "would have caught the §3a inversion");
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
spine walks), `rule13-no-backend-clearance-scope` (clearance = design-level
oracle modeling; never claim "statevector-verified output").

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
   (statevector trace: §8.2).
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
channels, proved by the independent review oracle, 2026-06-10; the WI-2 demo
asserts both against the analytic closed forms below).** B-keep is
**measurement-correct** (the `out` distribution equals the controlled-op
in-place reference exactly, always — the demo asserts it) and **undo-correct**
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
  `cq_theta(out, t)` + measure (review-oracle witness, 2-bit registers,
  `f = +1 mod 4`: reference distribution `[.5, 0, 0, .5]` vs B-keep flat
  `[.25, .25, .25, .25]`).

A demo recording only channel A could honestly record ~0 (basis condition) and
bless an understated boundary — hence the adjudicated bar (binding; shared
verbatim with IMPLEMENTATION-4.2 §8.1(c) and bd paj.2): **the documented
deviation is asserted against the analytic closed form on BOTH channels, plus
exact-zero deltas on all observables in the basis-`p₀` regime.** The bar is
deliberately *not* "deviation must be zero" (that would relitigate Rule 7 and
make 4.2 unshippable) and *not* bare "quantify + record" (under-specified —
see the channel-A-only failure mode above). The kept-source correlation is
inherent to Bennett-keep and is the documented boundary, not a 4.2 bug. The
verdict and both numbers are recorded in SCOPING §8 before the emitter ships
(Rule 13).

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
every phase-arm accept fixture keeps `CHECK-NOT: cqrt_copy`, and the demo
reproduces the P0 0.585 → 0.500 dephasing as its negative control.

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
chain link is a true **permutation**; for the non-injective subset (the
`sdiv`/`udiv`-class stems, even-literal `mul`) the trace — like straight-line
uncompute — inherits this shared Phase-5 axiom *fictionally* until real
template bodies land.

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
- The method-B oracle demo (path B, **measuring the output register**, plus
  the **two-channel** interference probes — §8.2 channels A and B, asserted
  against the analytic closed forms, exact-zero deltas in the basis-`p₀`
  regime — and the phase-arm dephasing negative) passes and its verdict is
  recorded in SCOPING §8 — **before or with** the emitter change (Rule 13).
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
  both R and R†), but unmodeled — requires its own oracle demo before any
  accept. Deferred; declines `value-arm swap-route`.
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
  to Bennett-keep; asserted by the oracle demo against the analytic closed
  forms on both channels. B-undo / `cq_invert` (Phase 7) restores fidelity
  only for compute→use→uncompute patterns; the keep-and-continue boundary
  stays open pending §6a control-in-place (§8.2 — it is NOT fully
  dischargeable at Phase 7). If the demo's numbers contradict the §8.2 closed
  forms, the emitter does NOT ship until the discrepancy is resolved
  (Rule 13).
- **`select`-folded short value arms** (§8.4): the dominant C-level shape for
  small arms reaches the pass as a tainted `select` — 4.4's scope. 4.2 does
  not attempt partial select handling.
