# Phase 2 PRD — IR pass: taint sources, gate-triggered allocation

Phase-specific design decisions, deliverables, and done criteria for the
first IR-pass workstream under the taint-driven design: re-point the
taint source set from the retired `@cq_init_*` family to `@cq_theta_*`,
introduce gate-triggered allocation at `@cq_theta` call sites, lower
`@cq_phi`, retire the mid-struct rebinding step, and stand up the first
end-to-end vertical slice (compile → pass → link → run against the trace
runtime).

Companion documents:
- [`ROADMAP.md`](../../../ROADMAP.md) §Phase 2 — phase scope and place in
  the sequence.
- [`docs/backend.md`](../../backend.md) §4 (taint propagation), §5
  (allocation lowering / the §5.1 dispatch rule), §6.1–6.4 (opcode
  lowering, width/signedness normalization), §11.2–11.4 (runtime ABI:
  alloc/measure/free, `cqrt_ry`/`cqrt_rz`, gate primitives).
- [`docs/quantum-classical-handling.md`](../../quantum-classical-handling.md)
  — taint as the Q/C boundary; `cq_phi` propagates but never sources.
- [`docs/frontend.md`](../../frontend.md) §8 — the Stage 1 / Stage 2 /
  Stage 3 pipeline these artifacts flow through.

---

## 1. Scope

**In scope.**
- Re-point `TaintPropagation`: source set becomes `{ return value of any
  @cq_theta_<sfx> call }`; `@cq_phi_<sfx>` and `@cq_measure_<sfx>` call
  sites are collected during the walk but are **not** taint sources.
- New `RotationLowering` module owning both rotation families:
  - `@cq_theta` — §5.1 dispatch (classical operand → `cqrt_alloc_<W>` +
    `cqrt_ry_<W>`; tainted operand → `cqrt_ry_<W>` only).
  - `@cq_phi` — tainted operand → `cqrt_rz_<W>`; classical operand →
    deleted (result RAUW'd to operand).
- Retire `MidHandleRebind` and the `qint_mid_t` mid-struct machinery
  outright; relocate `BirthOrder` (load-bearing for `OpcodeLowering`
  Q+Q canonicalization) into `TaintSet`.
- Re-point `MeasureLowering` onto plain tainted scalar handles (drop the
  struct-unwrapping patterns).
- Runtime: add `cqrt_ry_<W>` / `cqrt_rz_<W>` (7 widths each) plus the
  `cqrt_x` / `cqrt_h` / `cqrt_cnot` / `cqrt_toffoli` placeholders
  (§11.4); trace-only `void` bodies.
- Repoint the existing `ir-pass/test/*.ll` LIT fixtures to the new
  source/sink shape; add fixtures for the new behaviors.
- Pin the `-O1` survival of the chained / duplicate / dead-result
  `cq_theta` patterns (a frontend fixture across `-O0`..`-O3`).
- Stand up one end-to-end run-and-diff trace smoke for the canonical
  slice.

**Out of scope.** Listed in §5. Load-bearing exclusions: the 38-opcode
breadth beyond `add`/`fadd` (Phase 3), controlled-form lowering (Phase
4), uncomputation / `cqrt_free` emission (Phase 5), function lifting
(Phase 6), manual inversion (Phase 7).

---

## 2. Design decisions

Each decision below was resolved during the PRD-discovery discussion and
is binding for the implementation.

### 2.1 Reference lowering — the canonical slice

Every decision in this PRD keys off this worked artifact. Source:

```c
int slice(void) {
    int x = 3;
    x = cq_theta(x, 0.5);
    int y = x + 1;
    int z = cq_measure(y);
    return z;
}
```

**Stage 1** (real `clang-19 -O1 -emit-llvm -include CQ.h`, the pass input):

```llvm
define dso_local i32 @slice() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01)
  %2 = add nsw i32 %1, 1
  %3 = tail call i32 @cq_measure_si32(i32 noundef %2)
  ret i32 %3
}
```

**Stage 2** (after `cq-lowering`; names `h`/`h_sum`/`m` are IRBuilder
hints):

```llvm
define dso_local i32 @slice() local_unnamed_addr {
  %h     = call i32  @cqrt_alloc_i32(i32 3)
           call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h_sum = call i32  @cq_template_add_i32_hl(i32 %h, i32 1)
  %m     = call i32  @cqrt_measure_i32(i32 %h_sum)
  ret i32 %m
}
; @cq_theta_si32 / @cq_measure_si32 declarations erased by the dead-decl sweep
```

**Stage 3** (codegen + link `libcq_templates` + `libcq_runtime`, run):

```
cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0.500000)
cq_template_add_i32_hl(h0, 1) -> h1
cqrt_measure_i32(h1) -> 0
```

Reference variants (lowered-IR fragments) the implementation must also
produce:

- **Chained rotation** `x = cq_theta(x,0.1); x = cq_theta(x,0.2)` — the
  2nd theta's operand is the 1st's handle (tainted) ⇒ **no second
  alloc**: `cqrt_alloc_i32(..)` once, then `cqrt_ry_i32(%h, 0.1)` and
  `cqrt_ry_i32(%h, 0.2)` on the same handle.
- **`cq_phi` on a tainted operand** ⇒ `cqrt_rz_<W>(%h, φ)`, no alloc.
- **`cq_phi` on a classical operand** ⇒ the call is **deleted** and its
  result RAUW'd to its operand; no `cqrt_rz` emitted (Rz on a
  computational-basis state is unobservable global phase, §4.1).

### 2.2 Taint source/sink re-point

`taint_sources = { ret-value of any @cq_theta_<sfx> call }`. The sink
set (`@cq_measure_<sfx>`) is unchanged from the current implementation.
`@cq_phi` is excluded from the source set on purpose (§4.1): an Rz on a
classical basis state is a no-op, so promoting a non-tainted variable to
a register because of a `cq_phi` call would over-allocate. The
propagation algorithm, worklist discipline, and `isMeasureSink` stop
condition are otherwise preserved verbatim.

### 2.3 `cq_phi` call sites are collected but not seeded

Forward propagation only reaches a `cq_phi` whose operand is *already*
tainted; a **classical-operand** `cq_phi` is never visited by
propagation, yet it must still be removed from the IR (an unlowered
`@cq_phi_si32` is an unresolved external at Stage 3 link). Therefore the
propagation walk collects **all** `@cq_phi_<sfx>` call sites into a new
`TaintSet::PhiCalls` list — symmetric with `ThetaCalls` and
`MeasureCalls` — without adding them to the source worklist.
`RotationLowering` then dispatches each by operand taint state.

### 2.4 `RotationLowering` — one dedicated module, both families

The `@cq_theta` and `@cq_phi` lowering live in a single new module
`RotationLowering` (`ir-pass/{src,include}/RotationLowering.{cpp,h}`).
This is the "dedicated module, not folded into `MeasureLowering`"
decision, extended to cover `cq_phi`: both families resolve
suffix → ABI width → runtime symbol and emit a `void` `cqrt_r{y,z}_<W>`
call, so the suffix-resolution and void-emission code is shared. The
two families differ only in (a) theta's classical-operand allocation
branch and (b) phi's classical-operand deletion branch. The module
absorbs the allocation-insertion and `BirthOrder`-seeding
responsibilities formerly carried by `MidHandleRebind`.

### 2.5 `cq_theta` lowering — the §5.1 dispatch

For each `@cq_theta_<sfx>(operand, θ)` call:

- **Classical operand** (not in `Tainted`): emit
  `%h = call i32 @cqrt_alloc_<W>(operand)` immediately before the theta
  call, then `call void @cqrt_ry_<W>(%h, θ)`. RAUW the theta call's
  result with `%h`; insert `%h` into `Tainted`; assign
  `BirthOrder[%h]`; erase the theta call.
- **Tainted operand** (already a handle): emit
  `call void @cqrt_ry_<W>(operand, θ)`; RAUW the theta result with
  `operand`; erase the theta call. No allocation, no new `BirthOrder`
  slot (the operand already carries one).

Because `cqrt_ry_<W>` returns `void`, the SSA carrier downstream is the
**handle** (the alloc result, or the tainted operand for a chained
rotation) — never the `ry` call. This is the first void-returning
lowering target placed in a value-producing source position;
implementers must RAUW to the handle, not to the `ry` call.

### 2.6 `cq_phi` lowering

For each `@cq_phi_<sfx>(operand, φ)` call in `PhiCalls`:

- **Tainted operand**: emit `call void @cqrt_rz_<W>(operand, φ)`; RAUW
  the phi result with `operand`; erase the phi call.
- **Classical operand**: RAUW the phi result with `operand`; erase the
  phi call. No `cqrt_rz` emitted.

### 2.7 Retire `MidHandleRebind`; `BirthOrder` moves to `TaintSet`

`MidHandleRebind.{cpp,h}` is deleted. The `qint_mid_t` machinery in
`WidthDispatch` (`kMidRows`, `MidRow`, `midStructToSuffix`,
`initFn`) and the `RebindMap` struct are removed. The
`extractvalue`/`insertvalue` struct-walk has no inputs under the new
plain-SSA contract (§3.3) and is gone. `BirthOrder` (and `NextBirth`),
which `OpcodeLowering` reads for stable Q+Q operand canonicalization,
relocates into `TaintSet`; `RotationLowering` and `OpcodeLowering` seed
it as they mint handles. `TaintSet::InitCalls` becomes `ThetaCalls`;
`eraseDeadInits` becomes a theta/phi sweep (or is subsumed by erasing
the lowered calls directly).

### 2.8 `MeasureLowering` re-point — pattern (c) only

The current three operand patterns collapse to one. Patterns (a)
`StructToHandle` map and (b) `insertvalue` extraction are removed with
the mid-struct surface. Only pattern (c) survives: the measure operand
is a plain tainted `i32` handle (a `cq_theta`/template result). Suffix →
ABI width → `cqrt_measure_<W>` resolution is unchanged. The "operand not
recognized" diagnostic is retained for a measure on a non-tainted
operand.

### 2.9 `WidthDispatch` resolver changes

- `initFn(sfx)` → `thetaFn(sfx)` (`@cq_theta_<sfx>` lookup); add
  `phiFn(sfx)` (`@cq_phi_<sfx>` lookup).
- Add `ryRtFn(abiWidth)` / `rzRtFn(abiWidth)`: signature
  `void(i32 handle, double angle)`, mirroring `cqrt_ry_<W>` /
  `cqrt_rz_<W>`.
- `frontEndIntrinsicNames()` dead-decl table: the `cq_init_*` entries
  become `cq_theta_*`; add the `cq_phi_*` entries. `cq_measure_*`
  entries unchanged.
- `allocFn` / `measureRtFn` / `addTemplate` / `abiWidthFor` /
  `llvmTypeFor` / `allSuffixes` unchanged.

### 2.10 Driver order

`CQLoweringPass::run`: `propagate` → `lowerRotations` (new; theta then
phi, or BB-order — equivalent) → `lowerOps` → `lowerMeasures` →
dead-decl sweep. The early-out predicate becomes "no `ThetaCalls`, no
`PhiCalls`, and no `MeasureCalls`" (a purely classical module stays
byte-identical and leaks no `cqrt_*` decls — the `passthrough_no_quantum`
fixture continues to pin this). The `runOnFunction` compatibility shim
is updated symmetrically.

### 2.11 Test strategy — two layers

1. **FileCheck-on-IR (primary).** The `ir-pass/test/` LIT suite is the
   detailed regression net: it asserts the exact lowered call sequence
   **and** the negatives FileCheck does trivially and a trace cannot
   ("no `add i32` remains", "no `cq_theta_si32` decl leaked", "the
   chained 2nd rotation emits no second `cqrt_alloc`"). Fast, hermetic,
   no link step.
2. **End-to-end run-and-diff (one fixture).** Only this proves every
   symbol the pass emits actually **resolves and is signature-correct**
   against the runtime — FileCheck never links, so it cannot catch a
   missing/mis-signatured `cqrt_ry_<W>`. This satisfies the ROADMAP
   done-when's "runs against the trace runtime". It is the Phase 2
   vertical slice, not the Phase 9 harness (which expands it to the full
   feature surface).

### 2.12 `-O1` survival fixture (pin the input contract)

The chained / duplicate / dead-result `cq_theta` shapes survive `-O1`
because the externs carry no `memory(...)`/`readonly`/`readnone`
attribute (verified empirically against clang-19; see §7.1). A frontend
LIT fixture (`tests/frontend/cq_theta_o1_survival.c`, run across
`-O0`/`-O1`/`-O2`/`-O3` like `cq_invert_markers_survive.c`) pins this so
a future `CQ.h` edit that adds a purity attribute — silently dropping a
qubit the user asked for — is caught immediately.

### 2.13 Fixture repointing — hand-write

The `ir-pass/test/*.ll` inputs are hand-rewritten to the new shape
(`call i32 @cq_theta_si32(i32 …, double …)`, plain SSA, no
`%qint_mid_t`, no `extractvalue`/`insertvalue`). Hand-written keeps the
unit fixtures stable and decoupled from clang's codegen across versions;
real `clang`-generated IR is reserved for the §2.11-layer-2 e2e smoke.

### 2.14 End-to-end smoke shape

The slice lives in a dedicated `slice()` function called from a thin
`main`. The expected trace log is a **living baseline**: Phase 2 captures
the four-line lowering above; later phases that add emission (Phase 5
`cqrt_free`/adjoints, etc.) **extend** it rather than rewrite it. Phase 2
emits no uncomputation, so the baseline is exactly the §2.1 Stage 3
block. Void rotation calls print args-only with no `-> hN` arrow,
matching the established `cqrt_free` convention.

---

## 3. Deliverables

### 3.1 `TaintPropagation` re-point
`ir-pass/src/TaintPropagation.cpp` + `.h`: source predicate → `@cq_theta_*`;
collect `PhiCalls`; `InitCalls` → `ThetaCalls`. Header contract comment
updated off the `cq_init`/mid-struct narrative.

### 3.2 `RotationLowering` — new module
`ir-pass/{src,include}/RotationLowering.{cpp,h}`: the §2.5 theta dispatch
and §2.6 phi dispatch; allocation insertion; `BirthOrder` seeding.

### 3.3 `MidHandleRebind` removal
`git rm ir-pass/src/MidHandleRebind.cpp ir-pass/include/MidHandleRebind.h`;
strip `qint_mid_t` tables and `RebindMap` from `WidthDispatch` /
`TaintSet`; remove the `#include` and call from the driver.

### 3.4 `MeasureLowering` re-point
`ir-pass/src/MeasureLowering.cpp`: drop patterns (a)/(b) and the
`RebindMap` parameter; keep pattern (c).

### 3.5 `WidthDispatch` updates
Per §2.9: `thetaFn`/`phiFn`, `ryRtFn`/`rzRtFn`, dead-decl table,
removal of mid-struct resolvers.

### 3.6 `CQLoweringPass` driver
Per §2.10: new module order, early-out predicate, `runOnFunction` shim.

### 3.7 Runtime additions
- `runtime/cq_runtime.h` + `.c`: 7× `cqrt_ry_<W>` + 7× `cqrt_rz_<W>`
  (`void (int32_t, double)`); `cqrt_x` / `cqrt_h` / `cqrt_cnot` /
  `cqrt_toffoli` (§11.4 placeholders). Trace-only `void` bodies, no-arrow
  format. Header preamble + symbol-count comment updated (15 → 15 + 14
  rotations + 4 gates).
- These gate/rotation symbols are **declared and defined** but only
  `cqrt_ry`/`cqrt_rz` are emitted by the pass in Phase 2; `cqrt_x` etc.
  are placeholders for later phases.

### 3.8 LIT fixture repointing (`ir-pass/test/`)
- **Shape repoint** across every quantum-touching fixture: `cq_init_si32`
  + struct + extractvalue/insertvalue → `cq_theta_si32` plain scalar;
  add `cqrt_ry_<W>` to the expected sequences.
  Affected: `lowering_basic`, `lowering_add_qc_*` (7),
  `lowering_add_qq_*` (7), `lowering_measure_*` (7),
  `lowering_q_plus_arg`, `lowering_q_plus_c`, `lowering_sub_negative`,
  `lowering_taint_mixed_suffix`, `lowering_taint_ui32`, `measure_only`.
- **`lowering_rebind_*` (7) repurposed** to `lowering_theta_alloc_*`:
  one tainted `cq_theta` with a classical operand per ABI width →
  `cqrt_alloc_<W>` + `cqrt_ry_<W>`.
- **New fixtures:** `lowering_theta_chained` (alloc once, ry twice),
  `lowering_phi_tainted` (`cqrt_rz`), `lowering_phi_classical`
  (phi deleted, result RAUW'd, no `cqrt_rz`).
- `passthrough_no_quantum` unchanged (still must leave a classical
  module byte-identical).

### 3.9 `-O1` survival fixture
`tests/frontend/cq_theta_o1_survival.c` per §2.12.

### 3.10 End-to-end trace smoke + harness
- `tests/e2e/slice_theta_add_measure.c` (the §2.1 slice + thin `main`).
- `tests/e2e/slice_theta_add_measure.expected.log` (the four-line trace).
- Build/run wiring: clang `-O1 -emit-llvm` → `opt -load-pass-plugin
  libCQPass.so -passes=cq-lowering` → clang codegen → link
  `libcq_runtime` + `libcq_templates` → run → byte-diff stdout against
  the golden. A new `tests/e2e/CMakeLists.txt` exposing a `check-e2e`
  target; root `CMakeLists.txt` wires the subdir. Phase 9 expands this
  directory to the full feature surface.

### 3.11 Documentation cross-links
- `docs/prd/README.md` index: add the Phase 2 row.
- `ROADMAP.md` §Phase 2: one-line pointer to this PRD.

---

## 4. Done criteria

Phase 2 is complete when ALL of the following hold:

1. `TaintPropagation` seeds from `@cq_theta_*` returns; `@cq_phi_*` and
   `@cq_measure_*` are collected but not sources.
   `grep -rn 'cq_init\|qint_mid_t\|RebindMap' ir-pass/src ir-pass/include`
   returns no hits.
2. `MidHandleRebind.{cpp,h}` absent; `BirthOrder` lives in `TaintSet`;
   the mid-struct resolvers are gone from `WidthDispatch`.
3. The §2.1 reference slice lowers exactly to the Stage 2 IR shown (one
   `cqrt_alloc_i32`, one `cqrt_ry_i32`, one `cq_template_add_i32_hl`, one
   `cqrt_measure_i32`; no `cq_theta`/`cq_measure` decls remain).
4. The three reference variants (chained, phi-tainted, phi-classical)
   lower as specified in §2.1.
5. Runtime declares + defines `cqrt_ry_<W>`/`cqrt_rz_<W>` (7 each) and
   the four gate placeholders; void trace lines carry no `-> hN`.
6. `ir-pass/test/` LIT suite is green: all fixtures repointed per §3.8,
   new fixtures green, `passthrough_no_quantum` byte-identical.
7. `tests/frontend/cq_theta_o1_survival.c` green at `-O0`/`-O1`/`-O2`/`-O3`.
8. `check-e2e` builds the slice through clang → `opt` → clang → link, runs
   it, and the stdout matches `slice_theta_add_measure.expected.log`
   byte-for-byte.
9. The Phase 1 `tests/frontend/` suite and the existing
   `runtime_trace_test` golden remain green (the latter extended with
   `cqrt_ry`/`cqrt_rz` exercise lines if `test_trace.c` is widened;
   optional).
10. `docs/prd/README.md` and `ROADMAP.md` §Phase 2 cross-link this PRD.

---

## 5. Out of scope

Deferred to subsequent phases per `ROADMAP.md`:

- **Opcode breadth beyond `add`/`fadd`.** The 38-opcode surface
  (`sub`, `mul`, bitwise, `icmp`, casts, …) is Phase 3.
  `OpcodeLowering` keeps its current `add`/`fadd`-only coverage and its
  "no template for opcode" diagnostic for everything else; the
  `lowering_sub_negative` fixture continues to pin the loud-failure path.
- **Controlled-form lowering.** Tainted `br i1` shadow recovery is
  Phase 4. `cq_phi`/`cq_theta` inside a control region lower as plain
  forward calls in Phase 2.
- **Uncomputation / `cqrt_free` emission.** Phase 5. No adjoint or free
  is emitted; the e2e baseline carries none.
- **Function lifting / specialization.** Phase 6. Tainted-argument calls
  are not yet cloned or substituted.
- **Manual inversion brackets.** Phase 7. `__cq_invert_*` markers pass
  through untouched.
- **`cqc` driver.** The archived driver is not revived; the e2e harness
  invokes the clang/`opt` pipeline directly (§3.10). A productionized
  multi-file driver is later work.
- **`-O2`/`-O3` at Stage 1.** `-O1` is the validated floor; the pass is
  exercised against `-O1` IR only this phase.

---

## 6. Sequencing and commit shape

Single PR, six commits in this order:

1. **PRD commit** — this file + `docs/prd/README.md` row +
   `ROADMAP.md` pointer. Lands first so review starts from the design.
2. **Runtime symbols** — `cqrt_ry`/`cqrt_rz` + gate placeholders
   (decls + trace bodies). Independent, no pass dependency; lands early
   so the e2e link target resolves.
3. **`TaintSet` + `WidthDispatch` re-point** — `ThetaCalls`/`PhiCalls`,
   `BirthOrder` relocation, `thetaFn`/`phiFn`/`ryRtFn`/`rzRtFn`,
   dead-decl table; remove the mid-struct resolvers. Compiles with the
   old modules still referencing the removed pieces only after step 4,
   so steps 3–4 may land as one commit if the build won't bisect.
4. **`RotationLowering` + `MidHandleRebind` removal + driver rewire +
   `MeasureLowering` re-point** — the load-bearing change. The pass now
   lowers the new surface end-to-end.
5. **LIT fixture repoint** — §3.8. With this commit the `ir-pass/test/`
   suite is green against the new pass.
6. **Survival fixture + e2e smoke** — §3.9, §3.10, including the
   `tests/e2e/` scaffold and `check-e2e` wiring.

Steps 3 and 4 may merge if the intermediate state does not build (the
removed `RebindMap` is referenced by both the old `MidHandleRebind` and
`OpcodeLowering`/`MeasureLowering` until the rewire lands).

---

## 7. Risks

### 7.1 `cq_theta` `-O1` survival regression
Gate-triggered allocation depends on `clang -O1` preserving the chained
data dependency, not CSE-ing duplicate theta calls, and not DCE-ing a
dead-result theta. Verified against clang-19: the declarations carry no
`memory(...)`/`readonly`/`readnone` attribute, so LLVM treats the calls
as may-read/write memory and cannot eliminate or merge them — robust
across `-O` levels and under LTO (the trace bodies call `printf`).
Mitigation: the §2.12 survival fixture converts this from "verified
once" to a standing regression guard.

### 7.2 `BirthOrder` relocation breaks Q+Q canonicalization
`OpcodeLowering`'s clang-version-stable Q+Q operand order depends on
`BirthOrder`, formerly seeded by `MidHandleRebind`. If the relocation to
`TaintSet` misses a seeding site (alloc handle, chained-rotation handle,
template result), Q+Q ordering becomes nondeterministic. Mitigation: the
repointed `lowering_add_qq_*` fixtures (7 widths) pin the canonical order
and fail loudly on a missed seed.

### 7.3 Classical-operand `cq_phi` left in the IR
If `RotationLowering` only handles tainted phis (the ones propagation
reaches), a classical-operand phi survives to Stage 3 as an unresolved
`@cq_phi_si32` external — a link error, not a pass error. Mitigation:
§2.3 collects *all* phi sites independent of propagation; the
`lowering_phi_classical` fixture asserts the call is gone.

### 7.4 e2e harness is the first compile→opt→link→run path
The `tests/e2e/` harness introduces toolchain wiring the project has not
exercised (the archived `cqc` did the equivalent). Risk of brittle
`opt`/`clang`/plugin-path plumbing in CMake. Mitigation: model the
golden-diff on the existing `runtime_trace_test`; keep exactly one
fixture this phase; the LIT-on-IR layer (§2.11.1) remains the primary
correctness signal independent of the e2e plumbing.

---

## 8. Open items to resolve before merge

- **`bd` issue granularity.** One umbrella Phase 2 issue with the six
  commits as closing notes, vs. per-commit issues. Decide before
  implementation begins (mirrors the Phase 1 open item).
- **`runtime_trace_test` widening.** Whether to extend `test_trace.c` +
  golden with `cqrt_ry`/`cqrt_rz`/gate lines now (locks the new trace
  formats byte-exact at the runtime layer) or defer to Phase 8. Lean:
  add the `cqrt_ry`/`cqrt_rz` lines now since the pass emits them this
  phase; leave the never-emitted gate placeholders for Phase 8.
- **Module naming.** `RotationLowering` (chosen) vs. retaining the
  earlier `ThetaLowering` name with phi as a second entry point. Cosmetic;
  settle at file-creation time.
