# Phase 6 PRD — IR pass: call-graph specialization (function lifting)

**Status (2026-06-18).** Written at the start of Phase 6 per Rule 16. Phase 6
productionizes the archived prototype's `cq-specialize` slice
([`archive/prototype/cq_pass.cpp:345-394`](../../../archive/prototype/cq_pass.cpp))
into a worklist-driven specialization synthesizer. The prototype validated only
the *mechanics* (`CloneFunction` + `ValueToValueMapTy` + `CallInst::setCalledFunction`,
internal-linkage clone) — keyed by the **retired `qint_mid_t` struct type**, with
no signature mask, no Bennett wrap, no pipeline recursion, no rejection set, and
no loud decline. Those mechanics carry forward unchanged (verified current against
LLVM 19 `Cloning.h:135-136`); **everything that decides *when* and *how* to clone
is net-new.** In the live pass this is greenfield: there is no `Specialization`
module, no `CloneFunction`/`setCalledFunction` call anywhere (only a `Plugin.cpp`
comment), and every tainted-argument call is currently declined loudly by
`declineTaintEscapes`.

**This PRD's scope was narrowed during planning (2026-06-18 owner dialogue)** from
the broad `backend.md §7` design. Four cuts: **(1) Path 1 (curated libm symbol
substitution) is deferred** — it depends on capabilities Phase 6 does not have
(controlled return, recursion) and on transcendental template symbols that do not
exist; **(2) recursion is rejected**, deferred with quantum-bounded loops;
**(3) `cq_*`-containing callees are rejected** — clone-on-taint targets purely
classical value functions only; **(4) the controlled-call specialization branch
of `backend.md §7.2/§8.3` is dropped** — swap-route (Phase 4) handles quantum
control by routing, so no controlled clone is ever synthesized.

**Design of record:** [`docs/backend.md`](../../backend.md) §7 (call-graph
specialization), §9.4 / §2 (the one load-bearing Bennett wrap), §13.2
(multi-file `llvm-link` flow); [`docs/frontend.md`](../../frontend.md) §8
(multi-file compilation); [`ROADMAP.md`](../../../ROADMAP.md) Phase 6.
**Authoritative status: ROADMAP.**

> **Doc/phase numbering caveat.** `backend.md` internally calls this work
> "§7 / Phase 7" (old phase numbering; the doc's §-numbers run one ahead of
> ROADMAP phases — doc §8 control = ROADMAP Phase 4, doc §9 uncompute = ROADMAP
> Phase 5). This is **ROADMAP Phase 6**. Where this PRD cites `backend.md §7`, it
> means the design content, not a phase label. The closed bd issue
> `test_C_libtooling-mh3` ("Phase 7 prototype: validate call-graph
> specialization") is old numbering for this phase.

---

## 0. Invariant recap (not new — the ground Phase 6 stands on)

- **Rule 3 — taint is the only Q/C boundary.** A clone is synthesized because a
  call has ≥1 **tainted argument** (a value transitively derived from `@cq_theta`).
  Inside the clone, the same forward propagation runs: tainted parameters seed
  taint, classical parameters/locals stay classical and lower to nothing
  (`backend.md §4.3`).
- **Rule 5 / 6 — never insert a measurement; free only a proven-`|0⟩` rail.** The
  Bennett wrap's reverse returns every internal rail and the borrowed input to a
  provable `|0⟩`/pristine state *before* `cqrt_free` (`FreePoint` discipline). A
  rejected callee is a **loud compile error**, never a silent measurement bridge
  (the `-fcq-measurement-bridge` of `backend.md §7.4` is struck — §1, §2.11).
- **Rule 7 / 8 — method matches arm class; no-cloning.** A cloned classical body
  is **basis-valued by construction** (it contains no `cq_phi`/`cq_theta`), so the
  Bennett return-copy is `cqrt_copy_<W>` and never dephases a phase/superposition
  answer (the dephasing class that `cqrt_copy` is forbidden to touch —
  `cqrt-copy-abi-invariant`). Linear lineage is required for the whole-body
  reverse (Rule 8); fan-out inside the clone is handled by the existing whole-DAG
  reverse (`backend.md §9`), not re-derived.
- **Rule 2 / 13 — verify-clean is necessary, never sufficient.** The clone +
  Bennett wrap is a **core lowering change**; it clears via independent
  adversarial analytic/trace review + linked e2e golden diff, not a green suite
  (`no-simulations-at-this-stage`).
- **Rule 14 — reuse before reinvention.** The Bennett reverse **is** the existing
  `emit_inverse` spine ([`EmitInverse.cpp`](../../../ir-pass/src/EmitInverse.cpp));
  the copy is `cqrt_copy_<W>` (`WidthDispatch::copyFn`); rail cleanup is `FreePoint`.
  The clone is re-lowered by **re-entering the existing pipeline**, not a parallel
  lowering.
- **Prime Directive — when in doubt, DECLINE.** Every precondition Phase 6 cannot
  *prove* (visible body, purely classical, non-recursive, i32-ABI-compatible,
  reversibilizable) is a loud `DiagnosticInfoUnsupported`, `opt` exits non-zero,
  and **nothing is cloned**.

---

## 1. Scope

| | In scope |
|---|---|
| **Path 2 — clone-on-taint** | At a direct call to a **visible, purely-classical, non-recursive** body with ≥1 tainted argument: compute the per-parameter taint signature mask, look up `(callee, sig)` in the specialization cache, miss → `CloneFunction` + `ValueToValueMapTy`, mangle `__cq_q_<callee>_<mask>`, internal linkage, seed taint on tainted params, **re-enter the lowering pipeline on the clone**, retarget via `setCalledFunction` (Rule 3, 14). |
| **Bennett wrap** | At the clone's boundary, the **one load-bearing whole-call Bennett** (`backend.md §9.4`): forward (per-op uncompute suppressed) → `cqrt_copy_<W>` the return onto a fresh `\|0⟩` handle → `emit_inverse` whole-body reverse (restores borrowed inputs + zeroes scratch) → `cqrt_free` the now-`\|0⟩` internal rails. Reuses `emit_inverse`/`cqrt_copy`/`FreePoint` (Rule 14). |
| **Return-value taint** | The retargeted call's result is marked tainted iff the clone's return derives from a tainted parameter; the caller's propagation/lowering continues from it; the returned handle is owned by the caller's Phase-5 uncompute/escape logic (Rule 3; S5). |
| **Transitive worklist** | A clone whose body calls another visible classical fn with a tainted (post-seed) argument enqueues that inner call; `(callee, sig)` cache makes each distinct specialization synthesized once (`backend.md §7.3`). |
| **Rejection-set classifier** | A visible candidate that cannot be reversibilized declines **loudly at the rejecting instruction** with `!dbg` (Rule 1, 12): inline asm, syscall, `volatile`, atomics, EH, `setjmp`/`longjmp`, unresolvable indirect call, **recursion**, vector/SIMD, **any `cq_*` primitive**, fp quantum arg/return. |
| **Decline carve-out** | Split today's blanket `declineTaintEscapes` unknown-callee decline ([`TaintPropagation.cpp:412-420`](../../../ir-pass/src/TaintPropagation.cpp)): visible-pure-classical-reversibilizable → specialize; **everything else stays loud-decline** (extern/no-IR, indirect, `invoke`/`callbr`). |
| **Build path** | A multi-file harness (`llvm-link` per-`.c` bitcode → one module *before* `opt`) and a clean-slate **`cqc` driver** wrapping the multi-stage flow (`frontend.md §8`, `backend.md §13.2`). |
| **Call under quantum control (classical inputs)** | A pure classical call evaluated inside a swap-route arm whose inputs are classical (independent of the condition) runs **classically**, and its return value is fed into the controlled register via Phase-4 routing — **no clone** (6.5; owner decision 2026-06-18). |

| | Explicitly OUT |
|---|---|
| **Path 1 — curated libm substitution** | Deferred (owner). Needs controlled return + recursion; target templates (`cq_template_sin/cos/sqrt/fabs`) do not exist (only `fmod → cq_template_frem` is reachable). No `cq_curated_table.yaml` this phase. |
| **Recursion** | Rejected loudly (rejection set). Bounded-recursion-via-unroll is deferred with quantum-bounded loops ("Beyond the freeze"). |
| **`cq_*`-containing callees** | Rejected. Clone + Bennett-wrap **cancels** a phase/rotation effect (§2.5); they are unitary subroutines needing an apply-in-place path, deferred. `cq_measure` rejected unconditionally. |
| **Controlled-call specialization** | Dropped (`backend.md §7.2-step-4`/`§8.3` are stale post-`7cde677`). Swap-route routes the argument and calls unconditionally — one clone per `(callee, data-sig)`, never a controlled clone. |
| **Tainted-data call inside a quantum-branch shadow** | The clone × swap-route *composition* (quantum-data argument **and** quantum control). Deferred Phase 4×6 interaction. (Classical-input control is 6.5; quantum-data straight-line is the core.) |
| **fp quantum params/returns** | No `cqrt_copy_f32/_f64` exists (`cqrt-copy-abi-invariant`); an fp tainted arg/return declines. |
| **`-fcq-measurement-bridge`** | Struck (owner): measurement is never compiler-inserted (Rule 5). |
| **Memory/pointer arguments** | `load`/`store`/`getelementptr`/by-ref out-params — post-freeze memory model. |
| **Cross-language bitcode (Rust/Fortran)** | Mechanically identical once `.bc` is in the LTO link (`backend.md §13.3`); not a Phase-6 deliverable. The decline strings are written to be language-agnostic (S7). |

---

## 2. Design decisions

### 2.1 A clone is the quantum-lowered twin; the original is untouched
`CloneFunction` produces a copy of the callee that is re-lowered to the
`cqrt_*`/`cq_template_*` form, named `__cq_q_<callee>_<mask>`, internal linkage so
unused clones DCE away. The **original classical function is left intact** for
classical callers — both coexist in the final binary (`backend.md §7.2`,
`cq-architecture-decisions` item 9). There is **no second ("controlled") clone**:
the controlled-call branch of the design-of-record is dropped (§1, OUT).

### 2.2 Candidate detection — the taint signature mask
A specialization candidate is a **`CallInst` (never `InvokeInst`/`callbr`)** to a
**resolvable** `getCalledFunction()` whose body is **visible** (`!isDeclaration()`),
with **≥1 tainted argument**. The signature is a per-parameter bit-mask:
`bit i = 1` iff argument `i` is tainted, **LSB = parameter 0** (e.g.
`ipow(tainted, classical)` → mask `01` → `__cq_q_ipow_01`). The cache/dedup key is
`(callee, mask)`. Detection is **pure analysis by SSA identity before any
mutation** (Rule 9), mirroring `ControlDetect`. Indirect (null callee), opaque
extern (declaration-only), and `invoke`/`callbr` forms are **not candidates** —
they continue to decline loudly (§2.12).

### 2.3 Pure-classical-only scope; `cq_*` and `cq_measure` rejected
The clone body must contain **no `@cq_theta_*` / `@cq_phi_*` / `@cq_measure_*`
call** (scanned by exact-pointer membership against the resolved intrinsic set,
not name-prefix — `intrinsic-via-invoke-loud-decline`). Rationale: a clone +
Bennett wrap is correct only for a **deterministic basis-valued function**; a
`cq_phi`/`cq_theta` effect is *cancelled* by the whole-body reverse (§2.5), and
`cq_measure` collapses the caller's superposition. All three decline loudly. (A
`cq_*`-containing callee with *classical* args is not a candidate at all — no
tainted argument — and is lowered in place by the existing pipeline as today.)

### 2.4 The clone's handle ABI
**Tainted parameters become `i32` handles**; **classical parameters keep their
original `iN`/`fN` type and pass through** unchanged (the `(tainted, classical)`
`ipow` precedent, `backend.md §7.2`). The return becomes an `i32` handle iff it
derives from a tainted parameter (S5). **fp tainted params/returns decline**
(no `cqrt_copy_f*`). Handles are always `i32`, signedness stripped (Rule 15).

### 2.5 The Bennett wrap = compute → copy → uncompute (the core correctness decision)
The clone realizes `(x_in, 0) → (x_in, f(x))` — input **preserved**, output a
fresh handle, no leaked scratch — via Bennett's construction
(`backend.md §9.4`; owner-confirmed 2026-06-18):

1. **Forward.** Re-lower the clone body per-op, with **Phase-5 per-op
   uncomputation suppressed** for this body (its rails are subtracted from the
   uncompute target set, the DD-4 `ControlOwnedRails` precedent). Produces the
   result rail + internal scratch rails; tainted input handles are *borrowed*.
2. **Copy out.** `out = cqrt_alloc_<W>(0)`; `cqrt_copy_<W>(result_rail, out)` —
   the keep-sources-live basis copy onto a fresh `|0⟩` (`cqrt-copy-abi-invariant`).
3. **Reverse.** `emit_inverse` over the forward gate sequence — restores every
   borrowed input to pristine **and** zeroes every scratch rail (including
   `result_rail`). This is the step per-op uncompute *cannot* do: it restores the
   **borrowed input**, which is not dead.
4. **Free.** `cqrt_free` each internal rail (now provably `|0⟩` post-reverse,
   via `FreePoint`); `out` is the clone's return.

The copy-out (step 2) is the lynchpin — it preserves the answer before the
reverse wipes the computation. **Because the body is purely classical (§2.3), the
return is basis-valued and `cqrt_copy_<W>` is always correct** (no Rz/Ry answer to
dephase — Rule 7). Reuses `emit_inverse` + `cqrt_copy` + `cqrt_alloc`/`cqrt_free`
+ `FreePoint` end-to-end (Rule 14). **No new runtime ABI.**

### 2.6 Re-entering the lowering pipeline on the clone
The clone is lowered by re-running the pipeline stages, **not** a parallel lowerer
(Rule 14). The hard constraints, from the re-entrancy analysis of
[`CQLoweringPass.cpp`](../../../ir-pass/src/CQLoweringPass.cpp):
- **Clone before rotation lowering.** Taint is seeded only at `@cq_theta`
  (`TaintPropagation.cpp`); `lowerRotations` (`:110`) RAUWs thetas to `i32`
  handles. A clone must be produced while its source-level structure is still
  taint-recoverable, and its taint **recomputed** — the original run's `TaintSet`
  holds `Value*` into the original function and is useless for the clone.
- **`TaintSet` is rebuilt per clone, never reused.** Per-function analyses
  (`DominatorTree`/`PostDominatorTree`) are already rebuilt locally inside every
  stage — a clone gets correct trees for free; only taint must be recomputed.
- **`runOnFunction` ([`CQLoweringPass.cpp:121-177`](../../../ir-pass/src/CQLoweringPass.cpp))
  is the existing template** for "rebuild taint, scope work to one function"
  (`onlyInF`, `:136-148`). The specializer drives a clone through the same
  guards → control → rotations → ops → measures → (suppressed uncompute) → Bennett
  wrap discipline. The exact integration point in `CQLoweringPass::run` (a new
  `specialize(...)` stage vs. a fixpoint around the existing stages) is an
  IMPLEMENTATION_PLAN decision; the **invariant** is: taint recomputed for the
  clone, clone lowered before its own rotation/uncompute, Bennett wrap applied at
  its boundary, then caller propagation continues from the (now tainted) call
  result.

### 2.7 Return-value taint and ownership
After retarget, the call result SSA value is **tainted iff the clone returns a
tainted handle** (§2.4) and the caller's propagation continues from it (S5). The
returned `i32` handle is an ordinary tainted handle in the caller: owned by the
caller's Phase-5 uncompute (a terminal if it escapes via `ret`/`cq_invert`/
`measure`; otherwise uncomputed at its last use). Borrowed argument handles stay
tainted (preserved by the Bennett reverse, still `@cq_theta`-derived).

### 2.8 The worklist + cache
`worklist = { CallInst with ≥1 tainted arg }`; `visited`/`cache` keyed by
`(callee, mask)`; per `backend.md §7.3`: curated (OUT this phase) → no-body
diagnostic → rejection-classifier diagnostic → clone+lower+cache+retarget → push
inner tainted calls in the clone. Recursive call graphs do **not** reach the
convergence argument because recursion is rejected up front (§2.11); the worklist
terminates on the finite `(callee, mask)` key space for the accepted (acyclic)
subset.

### 2.9 Mangling and linkage
`__cq_q_<callee>_<mask>` (mask = binary string, LSB = param 0; §2.2), internal
linkage. Uniqueness is per `(callee, mask)`; cross-TU name collisions after
`llvm-link` are resolved by the linker's renaming, and internal linkage keeps the
clone private to the linked module.

### 2.10 Carve the specializable subset out of `declineTaintEscapes`
Today every tainted-reading call declines with `kMsgUnknownCallee`
(`"cq taint escape: tainted value consumed by an unknown callee"`,
[`TaintPropagation.cpp:327-328,412-420`](../../../ir-pass/src/TaintPropagation.cpp);
the lift point is flagged in-source at `:412-417`). Phase 6 splits this: a
**direct call to a visible, pure-classical, reversibilizable body** routes to the
specializer; **extern/no-IR, indirect, `invoke`/`callbr`, and rejection-set
matches keep declining loudly** (the `CallInst`-vs-`CallBase` and
exact-pointer-not-prefix discipline of `intrinsic-via-invoke-loud-decline` is
load-bearing). These declines are documented as the cross-language boundary (S7).

### 2.11 The rejection set — loud, source-located, pinned
A visible candidate is rejected (loud `DiagnosticInfoUnsupported`, `DS_Error`,
`!dbg` at the **rejecting instruction**, `opt` non-zero) on any of:
inline asm · syscall · `volatile` load/store · atomics · EH
(`invoke`/`landingpad`/`catchpad`/`resume`) · `setjmp`/`longjmp` · unresolvable
indirect call · **recursion** · vector/SIMD · **`cq_theta`/`cq_phi`** ·
**`cq_measure`** · **fp quantum arg/return**. The classifier returns *which*
instruction rejected (not a bare bool) so `!dbg` points precisely. Per Rule 12
each entry ships a `RUN: not … | FileCheck` negative fixture mirroring the message
character-for-character. **Proposed `kMsg*` family** (final spellings + fixtures
fixed in the IMPLEMENTATION_PLAN):
- no IR: `"cq specialization: no IR available for callee, cannot specialize"`
- recursion: `"cq specialization: recursive callee has no static depth bound"`
- non-reversibilizable: `"cq specialization: callee contains a non-reversibilizable construct under quantum lift"` (carrying the construct kind)
- quantum primitive: `"cq specialization: callee contains a quantum primitive (cq_*); only classical functions are lifted"`
- measurement: `"cq specialization: callee measures under quantum lift"`
- fp ABI: `"cq specialization: floating-point quantum argument or return has no reversible copy"`

`-fcq-measurement-bridge` is **not implemented** (struck).

### 2.12 Multi-file build path + `cqc` driver
Clone-on-taint needs the callee body in the module `opt` sees; today the build is
100% single-TU (`tests/e2e/run_slice.sh` is one `SRC`; no `llvm-link` anywhere).
Phase 6 adds:
- A multi-source harness: per-`.c` `clang -O1 -emit-llvm` (only the CQ-using TU
  gets `-include CQ.h`) → `llvm-link … -o combined.bc` **before** `opt cq-lowering`
  → link `libcq_templates.a` **before** `libcq_runtime.a` (`frontend.md §8`,
  `backend.md §13.2`). `llvm-link` must be threaded into the e2e CMake tool set.
- A clean-slate **`cqc` driver** (live `tools/cqc`) wrapping the stages under one
  `clang -flto`-style invocation. It **reuses the archived driver's
  tool/artifact-discovery + flag skeleton** ([`archive/cqc`](../../../archive/cqc))
  but **none of its Stage-1 transpiler / `cq_mid.h` / `qint_mid_t`** path (those
  are forbidden, Key Prohibitions). It accepts multiple positionals + the
  `llvm-link` step. Sequencing constraint: `opt cq-lowering` runs **before** any
  inlining pass touches the combined module (`-O2+` inlining pre-empts
  clone-on-taint — Rule 9 / `-O`-matrix `test_C_libtooling-abd`).

### 2.13 Call under quantum control with classical inputs (6.5) — run classically, route the result
When a **pure classical** function is called inside a swap-route arm and its
inputs are **classical** (independent of the condition), it runs **as a classical
call** (it is pure — the rejection set guarantees no side effect — so running it
unconditionally and discarding on the inactive branch is observationally inert).
Its classical `i32` result is fed into the controlled register by the existing
Phase-4 routing (the 4.4-style controlled-copy merge materializes a classical
operand into a rail). **No clone, no input-tainting, no qubit allocation for
classical data** (owner decision 2026-06-18). This is a swap-route arm capability
reused under the Phase-6 umbrella; the clone-on-taint mechanism is not involved.
Quantum-data inputs under control (the clone × route composition) remain OUT (§1).

---

## 3. Deliverables

- **New `Specialization` module(s)** in [`ir-pass/src/`](../../../ir-pass/src/)
  (candidate detection §2.2, signature/mask §2.2/§2.9, worklist+cache §2.8,
  `CloneFunction`/`ValueToValueMapTy`/`setCalledFunction` mechanics, rejection
  classifier §2.11). Hand-written-module size discipline (split by concern, the
  Phase-4/5 convention).
- **Bennett-wrap emission** (§2.5) — a thin synthesizer over the existing
  `emit_inverse` ([`EmitInverse.cpp`](../../../ir-pass/src/EmitInverse.cpp)),
  `cqrt_copy_<W>` (`WidthDispatch::copyFn`), and `FreePoint`. No new runtime ABI;
  `gen_templates.py --check` stays clean (Rule 15).
- **Pipeline re-entry wiring** (§2.6) in
  [`CQLoweringPass.cpp`](../../../ir-pass/src/CQLoweringPass.cpp) — recompute taint
  per clone, lower the clone before its rotations, apply the Bennett wrap, continue
  caller propagation from the tainted call result.
- **`declineTaintEscapes` carve-out** (§2.10) in
  [`TaintPropagation.cpp`](../../../ir-pass/src/TaintPropagation.cpp) — route the
  specializable subset out; keep every other shape loud.
- **Build infrastructure** (§2.12) — multi-source `run_slice` path threading
  `llvm-link`; live `tools/cqc` driver; e2e CMake entries for multi-`.c` fixtures.
- **Lit fixtures** — positive `CHECK` per accepted shape (mangled-call → clone →
  template-call) **and** negative `RUN: not … | FileCheck` per rejection-set entry
  (§2.11), each mirroring its diagnostic character-for-character (Rule 12).
- **≥1 e2e golden per increment** — a linked `caller.c` + `lib.c` (and per 6.5 a
  classical-call-under-control slice) diffed byte-for-byte against an
  `.expected.log` — the only layer that proves every `__cq_q_<callee>_<mask>` and
  `cqrt_copy_<W>`/adjoint symbol resolves and signature-matches (Rule 2).

---

## 4. Done criteria

- A 2-file program (`caller.c` with a tainted-argument call into a pure classical
  `lib.c`) builds through the multi-file path (`llvm-link` → `opt cq-lowering` →
  link), runs against the trace runtime, and diffs clean against its golden:
  the call retargets to `__cq_q_<callee>_<mask>`, the clone lowers to
  `cqrt_*`/`cq_template_*`, and the Bennett wrap emits forward → `cqrt_copy_<W>`
  → reverse → `cqrt_free` with the input handle preserved (Rule 2).
- Multi-argument signatures synthesize distinct clones per `(callee, mask)`;
  repeated identical call sites share one clone (cache hit). Transitive tainted
  calls inside a clone specialize recursively and converge (§2.8).
- Every rejection-set entry (§2.11) fires a loud, source-located diagnostic with
  the pinned message and `opt` exits non-zero; each has a green negative fixture
  (Rule 12).
- The `declineTaintEscapes` carve-out preserves all existing decline behavior for
  extern/no-IR, indirect, and `invoke`/`callbr` (their fixtures stay green).
- 6.5: a pure classical call inside a quantum-controlled arm with classical inputs
  runs classically and feeds its result into the routed register; e2e golden
  clean (§2.13).
- Full suite green (`ir-pass-lit`, `frontend-lit`, `e2e-*`, `runtime`,
  `gen_templates.py --check`); no new GitHub CI (Build & Test).
- **Rule 13 clearance:** the clone + Bennett wrap (compute-copy-uncompute, the one
  load-bearing whole-call Bennett) and the `declineTaintEscapes` carve-out are
  **core lowering changes** — cleared by an independent adversarial reviewer using
  analytic/trace reasoning over the *extracted lowered IR* (no statevector sims —
  owner 2026-06-10), actively constructing miscompile attempts (input not
  restored; scratch left dirty; result dephased; over-accept of a `cq_*`/recursive/
  fp/`invoke` callee; double-uncompute from un-suppressed per-op uncompute inside a
  wrapped clone). A green suite alone does **not** clear it.

---

## 5. Out of scope

- **Path 1 — curated libm symbol substitution** — deferred (owner); re-opens once
  controlled return + recursion exist and the transcendental template surface
  (Phase 8) lands. No `cq_curated_table.yaml` this phase.
- **Recursion** (Phase: post-freeze loops/unroll) — rejected loudly now.
- **`cq_*`-containing callees / unitary-subroutine (apply-in-place) lifting**
  (later) — Bennett-wrap cancels their effect (§2.5); deferred to an apply-in-place
  / force-inline mechanism.
- **Tainted-data call inside a quantum-branch shadow** (Phase 4×6 composition) —
  the clone × swap-route interaction; deferred.
- **fp quantum params/returns** (with `cqrt_copy_f*`, post-freeze) — decline now.
- **`-fcq-measurement-bridge`** — ~~opt-in boundary measurement~~ — **struck**
  (Rule 5; owner 2026-06-18). A rejected boundary is a loud error, full stop.
- **Controlled-call specialization** — ~~controlled clone per `backend.md §7.2/§8.3`~~
  — **superseded** by swap-route (Phase 4); no controlled clone is synthesized.
- **Memory/pointer arguments, cross-language `.bc`** — post-freeze / not a Phase-6
  deliverable (the decline strings are written language-agnostic for the latter).

---

## 6. Risks

- **Verify-clean Bennett miscompile (Rule 10/13).** The deepest hazard: a wrapped
  clone that leaves the borrowed input un-restored, scratch dirty, or the result
  dephased passes `opt -verify` and prints a plausible trace. Mitigation: the
  whole-body reverse is `emit_inverse` (already cleared for the data DAG); the
  clearance (§4) specifically probes input-restoration and the copy-before-reverse
  ordering on extracted IR.
- **Double-uncompute (Rule 8).** If per-op Phase-5 uncomputation is *not*
  suppressed inside a wrapped clone, the per-op `_unc` and the whole-body reverse
  both adjoint the same gates → use-after-free / double-free. Mitigation: the
  clone's rails are subtracted from the uncompute target set (§2.5, DD-4
  precedent); a fixture asserts exactly one adjoint per gate.
- **Over-accept at the carve-out (Rule 1/11).** Splitting `declineTaintEscapes`
  risks letting an `invoke`/`callbr`/indirect/`cq_*`/recursive/fp callee slip into
  the specializer (the silent-miscompile class). Mitigation: detection is
  prove-or-decline by SSA/pointer identity before mutation; every off-pattern shape
  has a negative fixture (Rule 12); the carve-out keeps the existing decline as the
  default branch.
- **Pipeline re-entrancy state (Rule 9/10).** Reusing a stale `TaintSet` or
  cloning after rotation lowering corrupts the clone. Mitigation: taint is
  recomputed per clone, the clone is produced pre-rotation, following the
  `runOnFunction` discipline (§2.6).
- **Build-flow inlining pre-emption (Rule 9).** `-O2+` (or a stray inline pass on
  the `llvm-link`ed module) inlines a callee before clone-on-taint sees it.
  Mitigation: `-O1` floor; `cqc` runs `opt cq-lowering` before any inlining (§2.12).
- **`cqc` driver scope creep.** A full driver risks reviving forbidden old-design
  surfaces. Mitigation: clean-slate, reuse only the tool-discovery/flag skeleton of
  `archive/cqc`, never its transpiler/`cq_mid.h` stage (Key Prohibitions).

---

## 7. Increments (staged by capability; each is red→green→clear, Rule 12/13)

Decline fixtures + adversarial probes ride **every** increment, not a final one.

- **6.1 — Single-function core.** One visible pure-classical callee, single
  tainted arg, straight-line caller: detect → clone → mangle/seed → re-enter
  pipeline → **Bennett wrap** → retarget; the multi-file harness + `cqc` driver +
  first linked e2e golden land here. Carries the first decline fixtures (no-IR,
  `invoke`, `cq_*` body). **Rule-13: core, deepest** (the Bennett wrap).
- **6.2 — Signatures, cache, multiplicity.** Multi-parameter masks (LSB=param0),
  `(callee, mask)` cache, multiple call sites / multiple distinct clones, classical
  pass-through params. **Rule-13: light** (mask/cache are structural; the wrap is
  unchanged from 6.1).
- **6.3 — Transitive worklist.** A clone whose body calls another pure-classical fn
  with a tainted argument specializes the inner call; convergence on the
  `(callee, mask)` key space (acyclic subset). **Rule-13: medium** (ordering of
  inner specialization vs. the clone's own lowering/wrap).
- **6.4 — Rejection-set hardening.** The full decline matrix (§2.11) with pinned
  messages + per-entry negative fixtures + an adversarial over-accept probe family.
  **Rule-13: core** (the over-accept class).
- **6.5 — Call under quantum control (classical inputs).** Run the pure classical
  call classically, route its result into the controlled register via Phase-4
  routing (§2.13); e2e golden. **Rule-13: medium** (reuses swap-route; no clone).

> A companion `IMPLEMENTATION_PLAN.md` (per Rule 16, authored next) will fix the
> WI decomposition, DDs (re-entry integration point, suppress-uncompute mechanism,
> module split, mask encoding, `cqc` flag set), the verified current-state map
> (PRD-claim corrections in **bold**), and the dependency-ordered red→green→clear
> work items.
