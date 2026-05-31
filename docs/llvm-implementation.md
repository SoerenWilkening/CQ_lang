# LLVM Substrate — What CQ Uses from Stock LLVM

A stage-by-stage reference for the LLVM C++ APIs the CQ compilation
pipeline relies on. Every transformation maps to a stable, documented
extension point in upstream LLVM — no patched sources, no vendored
`llvm-project`, no per-release rebase. The no-fork shape was validated
2026-05-22 by a working prototype against LLVM 19.1.7
([`../archive/prototype/`](../archive/prototype/)); this document records the substrate
the prototype and full pipeline depend on.

Companion documents:
- [`frontend.md`](./frontend.md) — user-facing intrinsic surface
  (`cq_theta`, `cq_phi`, `cq_measure`, `cq_invert_*`) and the Stage 1
  Clang/`-O1` flow that prepares the IR
- [`backend.md`](./backend.md) — IR pass and runtime ABI; the
  load-bearing half of the pipeline
- [`quantum-classical-handling.md`](./quantum-classical-handling.md)
  — taint as the Q/C boundary
- [`bennett-jl-comparison.md`](./bennett-jl-comparison.md) — design
  convergences with Sturm.jl / Bennett.jl / Orkan

---

## 1. Background

Earlier project notes asked whether CQ would need to fork LLVM — patch
its sources, vendor a copy of `llvm-project`, maintain a rebase against
upstream — to enable the Stage 1 → Stage 2 transition where tainted
LLVM opcodes are traced back to quantum-derived SSA values and replaced
with calls that emit reversible-gate sequences. The answer is no: the
pipeline was designed against a no-fork constraint, every transformation
maps to a stable documented LLVM C++ API, and four production-quality
precedents (Enzyme, AddressSanitizer, OpenMP runtime, Polly) ship the
same shape without forking LLVM. The conclusion was validated against
stock LLVM 19.1.7 by the prototype at [`../archive/prototype/`](../archive/prototype/).

The remainder of this document is the substrate reference: stage by
stage, the specific LLVM extension points and C++ APIs CQ uses. Stage
numbering follows [`frontend.md`](./frontend.md) §8:

- **Stage 1.** `clang -O1 -emit-llvm -include CQ.h example.c -o example.bc`
- **Stage 2.** `opt -load-pass-plugin libCQPass.so -passes=cq-lowering example.bc -o example.lowered.bc`
- **Stage 3.** `clang example.lowered.bc -lcq_templates -lcq_runtime -o example`

## 2. Stage-by-stage substrate

Each stage is mapped to the specific LLVM C++ API surface it uses.

### 2.1 Source surface — `CQ.h`

The user writes plain C. `CQ.h` is a header-only intrinsic surface
declaring three primitive families plus an inversion bracket:

- `cq_theta_<sfx>(x, θ)` — Ry rotation; the only taint source.
- `cq_phi_<sfx>(x, φ)` — Rz rotation; propagates taint, does not
  introduce it.
- `cq_measure_<sfx>(x)` — measurement; the only sink.
- `cq_invert_begin()` / `cq_invert_end()` — bracket markers.

Each family has per-type specializations and a `_Generic` dispatch
macro (see [`frontend.md`](./frontend.md) §3). The declarations are
ordinary C `extern` functions — the IR pass identifies them later by
name prefix.

There is no `quantum` keyword, no annotation attribute, no Clang AST
plugin, no rewriter. Stock Clang accepts the source unchanged.

**LLVM API used:** none — stock C compilation.

### 2.2 Stage 1 — Clang codegen + `-O1` cleanup

Stock Clang lowers C to LLVM IR. Stock `mem2reg` and `SROA` flatten
stack slots to SSA values so the pass sees post-`mem2reg` / post-`SROA`
IR (the [`backend.md`](./backend.md) §3.1 input contract). The `@cq_*`
calls remain as opaque external calls because they have unknown side
effects by default; LLVM will not fold or eliminate them across
optimization passes.

`-O1` is the validated floor for Stage 1. Higher levels are not
prohibited but introduce risks documented in [`frontend.md`](./frontend.md)
§8 "Optimization-level guidance" (aggressive inlining pre-empting
clone-on-taint; IPSCCP rewriting signatures; SLPVectorize fusing
tainted + untainted scalars at `-O3`; etc.).

**LLVM API used:** stock `-O1` pipeline.

### 2.3 Stage 2 — The IR pass (`cq-lowering`)

Every operation the pass performs, with the specific LLVM C++ API it
uses:

| Operation | LLVM API | Notes |
|---|---|---|
| Register as pass plugin | `llvm::PassPluginLibraryInfo`, `PassBuilder::registerPipelineParsingCallback` | New PM, stable since LLVM 13 |
| Iterate functions/blocks/instructions | `Module::functions()`, `Function::begin()/end()`, `BasicBlock::begin()/end()` | |
| Identify `@cq_*` calls | `CallInst::getCalledFunction()`, `Function::getName()` (string prefix match) | |
| Forward taint propagation | `Value::users()`, `Instruction::operand_values()`, set-based work queue | Bog-standard SSA dataflow |
| Read function-parameter types | `Function::arg_begin()`, `Argument::getType()` | |
| Build call graph | `llvm::CallGraphAnalysis` (analysis pass, new PM) | |
| Clone function for specialization | `llvm::CloneFunction`, `CloneFunctionInto`, `ValueToValueMapTy` | Same mechanism as Enzyme |
| Create function with rewritten signature | `Function::Create(FunctionType, Linkage, Name, Module)` | |
| Replace instruction with new call | `IRBuilder::CreateCall`, `Instruction::replaceAllUsesWith`, `Instruction::eraseFromParent` | |
| Identify tainted `br i1` for controlled-form | `BranchInst::getCondition()` + taint-set membership | Stock SSA |
| Post-dominator analysis for controlled-region merge / uncomputation | `PostDominatorTreeAnalysis` via `FunctionAnalysisManagerModuleProxy`, `findNearestCommonDominator` | Same API as uncompute last-use |
| Emit adjoint sequences | `IRBuilder` constructing new `cqrt_*` calls in reverse order | |
| Preserve source locations | `Instruction::setDebugLoc(SourceInst->getDebugLoc())` | |
| Emit user diagnostics | `LLVMContext::diagnose(DiagnosticInfo&)`, `OptimizationRemark*` | |
| Mark `cqrt_*` calls side-effecting | `Function::addFnAttr(Attribute::NoUnwind)`; deliberately not `ReadNone`/`ReadOnly` | |
| Run at a specific pipeline position | `PassBuilder::registerOptimizerLastEPCallback` (and phase callbacks) | |

Every entry is a stock LLVM C++ API.

**The specific Stage 1 → 2 transformation** — tracing opcodes back to
quantum-derived SSA values and inserting emission-function calls —
decomposes into:

1. Forward taint propagation (SSA walk): stock `Value::users()` +
   dataflow, seeded from `@cq_theta_*` return values.
2. Identify tainted `add`/`mul`/`icmp`/etc.: stock
   `Instruction::getOpcode()`.
3. Build a new `CallInst` to `@cq_template_<opcode>_<width>` with
   handle SSA values as args: stock `IRBuilder::CreateCall`.
4. `oldInst->replaceAllUsesWith(newCall); oldInst->eraseFromParent()`:
   stock.

This is the same shape used by Enzyme (cloning functions and emitting
derivative versions), AddressSanitizer (inserting instrumentation calls
before/after memory ops), ThreadSanitizer, MSan, UBSan, and GCOV — all
out-of-tree or in-tree pass plugins against stock upstream LLVM.

### 2.4 Stage 3 — Lowered IR → object code → binary

Post-pass, the IR contains only stock LLVM opcodes + extern `cqrt_*`
and `cq_template_*` calls. Standard `clang -c` backend codegen handles
it. The linker (preferably `ld.lld` for LTO) links against
`libcq_runtime.{a,so}` and `libcq_templates.{bca,a,so}`.

Everything past Stage 2 is plain C-toolchain operation. The Stage 3
`-O` level can be any of `-O0`–`-O3` without risk; the IR contains no
tainted ops for stock optimizations to miscompile
([`frontend.md`](./frontend.md) §8).

**LLVM API used:** stock `clang -c`, stock linker.

### 2.5 Runtime (`libcq_runtime`)

Stock C library, compiled with stock Clang, no LLVM dependency at all.
Implements `cqrt_*` functions; emits OpenQASM strings, builds in-memory
`Circuit` structs, or drives a simulator/hardware backend. Not an LLVM
consumer.

## 3. Edge cases and clarifications

A few patterns can look like they would require modifying LLVM
sources; this section explains why each is covered by stock extension
points.

### 3.1 "Don't intrinsics need registration in LLVM's intrinsic table?"

No. Real LLVM intrinsics (`@llvm.memcpy`, `@llvm.ctpop`) are registered
in `Intrinsics.td` and *would* require LLVM source modifications to
add. But `@cq_theta_*`, `@cq_phi_*`, `@cq_measure_*` are **not LLVM
intrinsics in the technical sense** — they are ordinary external
function declarations whose names happen to start with `cq_`. The IR
pass pattern-matches by string name. Same trick Enzyme uses with
`__enzyme_autodiff` and ASan uses with `__asan_*`.

The CQ vocabulary's use of "intrinsic" is informal — it means
"function the IR pass treats specially," not `llvm::Intrinsic::ID`.

### 3.2 "Won't LLVM's optimizer CSE/DCE our `cq_*` calls into oblivion?"

No, provided we don't mark them `readnone`/`readonly`. By default,
external function calls have unknown side effects and LLVM will not
fold or eliminate them. The required behavior comes from attribute
discipline on the declarations — a property of how we declare the
functions, not of LLVM.

### 3.3 "What about `__cq_q_<f>_<mask>` mangled names? Does the C++ name mangler need extending?"

No. We choose the mangling. They are plain C identifiers with `_`
separators. No Itanium mangler involvement.

### 3.4 "What if a stock LLVM pass folds across our intrinsic in a way we can't prevent?"

Attribute discipline plus pipeline ordering handle this. Worst case
(not expected for any Phase 1–11 case): register our pass
`EP_EarlyAsPossible` to run before problematic passes. Stock
pipeline-extension-point API.

### 3.5 "Will `!dbg` survive enough opt passes for usable diagnostics?"

`!dbg` survives the standard `-O1` pipeline. Some aggressive late
passes can drop it, but our pass runs before those and attaches `!dbg`
to its own emitted instructions. If a specific opt pass turns out to
be lossy, we either re-attach `!dbg` afterwards (our responsibility)
or disable that pass at our pipeline position — stock mechanisms
either way.

### 3.6 "What about cross-language input — Rust/Fortran needing IR?"

Stock LLVM linker handles `.bc` from any frontend. Polyglot LTO is
exactly what `clang`, `rustc --emit=llvm-bc`, `flang -emit-llvm` are
designed for. No CQ-side involvement.

### 3.7 "What about MLIR?"

Explicitly rejected for Phases 1–10. If ever adopted, MLIR is *part
of* upstream LLVM — not a separate substrate.

## 4. Operations CQ deliberately avoids

The following operations would require modifying LLVM sources rather
than extending stock LLVM. CQ's design avoids all of them.

| Operation requiring LLVM source modification | CQ's approach |
|---|---|
| Adding a new IR instruction kind (modify `Instruction.def`) | Avoided — tainted `add i32` *is* the quantum add |
| Changing semantics of an existing IR opcode | Avoided — semantics unchanged; we just lower differently |
| Adding a new fundamental `Type` (e.g. a qubit-IR-type that isn't a struct or pointer) | Avoided — `i32` handles suffice |
| Modifying Clang's lexer/parser to recognize a new keyword | Avoided — no source-level keyword; user writes plain C and calls extern `cq_*` functions declared in `CQ.h` |
| Adding a new ABI calling convention | Avoided — stock C calling convention works |
| Modifying an existing optimization pass to know about quantum semantics | Avoided — pass ordering + attributes are sufficient |

If any of these became necessary in some far-future phase, the
substrate question would warrant re-evaluation. None are on the
horizon.

## 5. Precedent — pass-plugin projects on stock LLVM

All four ship the same architectural shape CQ uses, against stock
upstream LLVM:

| Project | What it does | Shipping shape |
|---|---|---|
| **Enzyme** | Reverse-mode automatic differentiation at LLVM IR level. Clones functions, transforms bodies, emits derivative versions. | Out-of-tree pass plugin |
| **AddressSanitizer** | Instruments memory accesses with shadow-memory checks; inserts intrinsic-style calls. | In-tree pass shipping as `libclang_rt.asan.so` |
| **OpenMP runtime lowering** | Lowers `#pragma omp parallel` to `@__kmpc_*` runtime calls; brackets regions. | In-tree but uses the same intrinsic-call + region-bracket mechanism |
| **Polly** | Polyhedral optimization with custom analysis and IR transformation. | Pass plugin |

CQ's extension surface (~7 intrinsic families, no new types, no new
opcodes) is *smaller* than any of these.

## 6. What this means in practice

- **Build dependency:** Stock upstream LLVM, version-pinned (LLVM 19
  per project memory). When upstream releases LLVM 20, we update our
  pass plugin to the new PassPlugin API revision (usually a one-day
  port). No patch maintenance.
- **Plugin shipping:** `libCQPass.so` (the pass),
  `libcq_templates.{bca,a,so}` (templates), `libcq_runtime_<variant>.{a,so}`
  (runtime). All consumable by stock `opt` / `clang`.
- **User-facing command:** the three stages from §1 run as a pipeline:
  `clang -O1 -emit-llvm -include CQ.h | opt -load-pass-plugin
  libCQPass.so -passes=cq-lowering | clang -lcq_templates -lcq_runtime`.
  Or equivalently `clang -fpass-plugin=libCQPass.so` on a single line
  (see [`frontend.md`](./frontend.md) §8 for the canonical invocation).
- **Distribution:** Same shape as Polly, Enzyme, AddressSanitizer when
  shipped out-of-tree.

## 7. Prototype validation

The substrate claims above are not paper-only. A working prototype
exercises every architecturally novel mechanism against stock LLVM
19.1.7.

### 7.1 Validation status

**VALIDATED 2026-05-22** across the architecturally novel LLVM C++
APIs the pass relies on. A working prototype lives at
[`../archive/prototype/`](../archive/prototype/) and exposes four passes
(`cq-lowering`, `cq-uncompute`, `cq-specialize`, `cq-control`) — one
per validation slice.

**Important caveat on source/sink set.** The prototype was built
against the **old-design** IR shape (`@cq_init_<sfx>` as taint source,
`qint_mid_t` struct wrapper, `cq_when_*` bracket calls). The new
design retires those surfaces in favor of `@cq_theta_<sfx>` as taint
source, plain SSA scalars, and post-dominator-driven controlled-region
detection. **The LLVM C++ APIs the prototype exercised are identical
under both designs** — only the IR shape the pass walks changes. The
findings below note explicitly where the new design re-uses the same
mechanism vs. where a new-design slice is still pending validation.

#### cq-lowering findings

| Claim | Validation | New-design status |
|---|---|---|
| Pass plugin builds against stock LLVM 19 | ✓ — clean build against LLVM 19.1.7, no LLVM source modifications | Same APIs; carries over unchanged |
| Pass loads via `opt -load-pass-plugin` and runs without crash | ✓ | Carries over unchanged |
| Output IR passes `opt -verify` | ✓ | Carries over unchanged |
| Forward taint propagation works on stock SSA APIs | ✓ — `Value::users()` + worklist | Carries over; only the source-set predicate changes (`@cq_init_*` → `@cq_theta_*`) |
| Old-design source `@cq_init_i32` → `@cqrt_alloc_classical_i32` lowering | ✓ | Replaced under new design by `@cq_theta_<sfx>` → `cqrt_alloc_<W>` + `cqrt_ry_<W>` ([`backend.md`](./backend.md) §5.1). Same `IRBuilder::CreateCall` mechanism; pending new-design fixture |
| Tainted `add i32` → `@cqrt_template_add_i32` lowering | ✓ | Carries over; opcode lowering map unchanged |
| `@cq_measure` → `@cqrt_measure` lowering | ✓ | Carries over unchanged |
| Front-end intrinsic declarations erased after lowering | ✓ — module-level cleanup works on stock `Module::getFunction()` | Carries over unchanged |

The `qint_mid_t` struct rebinding step (validated as
`extractvalue` / `insertvalue` cleanup) is **retired** under the new
design — the IR contains plain SSA scalars from the start, so the
rebinding module has no inputs and is removed.

#### cq-uncompute findings (Phase 5 / post-dom)

| Claim | Validation |
|---|---|
| `PostDominatorTreeAnalysis` accessible from a Module pass via `FunctionAnalysisManagerModuleProxy` | ✓ |
| `findNearestCommonDominator` over user blocks gives the right insertion BB | ✓ — handles single-BB and multi-BB |
| `IRBuilder::SetInsertPoint` at post-dominating last use works | ✓ — `cqrt_free` emitted at correct point for each handle |
| `ReturnInst` escape detection (skip uncomputation when handle is returned) | ✓ |
| Composes with `cq-lowering` in the same pipeline | ✓ — `-passes='cq-lowering,cq-uncompute'` works end-to-end |

All APIs here carry over directly. The new design re-uses
`PostDominatorTree` for **two** purposes — uncomputation last-use (this
slice) and controlled-region merge detection (§8.2 of `backend.md`) —
on the same analysis infrastructure.

#### cq-specialize findings (Phase 7 / function lifting)

| Claim | Validation |
|---|---|
| `CloneFunction` + `ValueToValueMapTy` clones a function with full body fidelity | ✓ — clone has matching `extractvalue + add + insertvalue + ret` shape |
| Mangled-name renaming via `Function::setName` works | ✓ — `__cq_q_<orig>_q1` |
| `Function::setLinkage(InternalLinkage)` works (DCE-eligible) | ✓ |
| `CallInst::setCalledFunction` retargets call sites | ✓ — original `@example` now calls `@__cq_q_double_it_q1` |
| Pre-existing front-end intrinsics (`@cq_*`) correctly skipped, not re-cloned | ✓ |

All APIs here carry over directly to the new design's clone-on-taint
path ([`backend.md`](./backend.md) §7.2). The body fidelity check
exercised an old-design body shape (with `extractvalue`/`insertvalue`
on the mid-struct); under the new design the body is plain SSA, which
is simpler — strictly less to validate.

#### Multi-BB post-dom findings

| Claim | Validation |
|---|---|
| `PostDominatorTree::findNearestCommonDominator` returns the merge block when uses span both arms of an `if` | ✓ |
| `getFirstInsertionPt()` correctly places `cqrt_free` between `phi` and `ret` in the merge block | ✓ |
| `cqrt_free` is emitted **exactly once** (not duplicated into either arm) | ✓ |
| No code changes were needed — original `computeFreePoint()` already correct for non-trivial CFG | ✓ |

#### cq-control findings (retired bracket mechanism)

| Claim | Validation | New-design status |
|---|---|---|
| Region detection via `cq_when_begin`/`cq_when_end` bracket walking works | ✓ | **Retired** — bracket calls are no longer in the input IR |
| `cqrt_template_*` calls inside a region are substituted with the `_controlled` variant | ✓ — control handle prepended as first arg | **Mechanism carries over** — same `_controlled` template substitution + control-handle prepending |
| `cqrt_template_*` calls **outside** any region are left alone | ✓ | Same under new design |
| Bracket call sites and declarations erased after substitution | ✓ | N/A — no brackets to erase |
| `Module::getOrInsertFunction` with dynamically-built `FunctionType` works for variant declarations | ✓ | Carries over unchanged |

**The new-design controlled-region detection is pending prototype
validation.** Under the new design, controlled regions are identified
structurally from a tainted `br i1` plus `PostDominatorTree` to find
the merge block ([`backend.md`](./backend.md) §8). The substitution
step inside the region — replace each gate with its `_controlled`
variant, prepend control handle — is **identical** to the validated
prototype. Only the trigger differs (was bracket pair, now tainted
branch). The prerequisite APIs (`PostDominatorTreeAnalysis`,
`BranchInst::getCondition()`, taint-set membership) are all exercised
elsewhere in the prototype.

#### Overall

| Claim | Result |
|---|---|
| "Lightweight extension" claim quantitatively defensible | ✓ — 525 LOC C++ for all four prototype passes combined |
| All checks pass on stock LLVM 19.1.7 | ✓ — no LLVM source patches anywhere in the dependency chain |
| Every architecturally novel LLVM-API mechanism that carries over to the new design is demonstrated working | ✓ — taint propagation, post-dominator analysis (linear + branched), function cloning, controlled-variant substitution |
| New-design slices pending validation | One: tainted-`br i1`-driven controlled-region trigger (the substitution step is already validated; only the trigger is new) |

### 7.2 What the prototype slices prove

The prototype passes collectively exercise every architecturally novel
LLVM C++ API the new-design IR pass needs. Specifically:

| Mechanism | LLVM API exercised | Demonstrated by | Carries to new design? |
|---|---|---|---|
| Taint propagation across stock SSA | `Value::users()` + worklist | cq-lowering | ✓ source predicate changes; algorithm unchanged |
| Opcode substitution with runtime calls | `IRBuilder::CreateCall`, `Instruction::eraseFromParent` | cq-lowering | ✓ unchanged |
| Module-level cleanup of unused declarations | `Module::getFunction`, `Function::eraseFromParent` | cq-lowering | ✓ unchanged |
| SSA last-use analysis | `PostDominatorTreeAnalysis`, `findNearestCommonDominator`, `Instruction::comesBefore` | cq-uncompute | ✓ unchanged; same API reused for controlled-region merge |
| Cross-pass analysis-manager access | `FunctionAnalysisManagerModuleProxy` | cq-uncompute | ✓ unchanged |
| Function cloning with full body fidelity | `CloneFunction`, `ValueToValueMapTy` | cq-specialize | ✓ unchanged (plain-SSA bodies are strictly simpler) |
| Function attribute manipulation | `Function::setName`, `Function::setLinkage` | cq-specialize | ✓ unchanged |
| Call-site retargeting | `CallInst::setCalledFunction` | cq-specialize | ✓ unchanged |
| Controlled-variant template substitution | `Module::getOrInsertFunction` with dynamic `FunctionType`, control-handle prepending | cq-control | ✓ substitution step unchanged; only the region-trigger mechanism differs |
| Cross-pass composition | `opt -passes='cq-lowering,cq-uncompute'` runs end-to-end | cq-lowering + cq-uncompute | ✓ unchanged |

The remaining unbuilt items reuse these same APIs — no new substrate
required:

- **Multi-width** (`i1`/`i8`/`i16`/`i64`/`f32`/`f64`) — parametrize
  the existing `i32` pattern over `Type::getIntNTy(Ctx, W)`. No new
  mechanism.
- **Real adjoint gate-sequence emission** — replace the `cqrt_free`
  placeholder with the actual reverse-order template calls before the
  free. Pure IR construction; uses already-validated `IRBuilder` API.
- **Bennett wrap-around for specializations** — replace the
  signature-preserving clone with a `Function::Create` + new
  `FunctionType` + body migration via `CloneFunctionInto`. Adds
  forward-CNOT-copy + reverse on top, both reusing already-validated
  IR construction.
- **Tainted-`br i1`-driven controlled-region detection** — read the
  branch condition, check membership in the taint set, recover the
  merge block via the already-validated `PostDominatorTree` API. New
  trigger, validated mechanism.
- **Real template body implementation** — runtime/library C code that
  calls `cqrt_x` / `cqrt_cnot` / `cqrt_toffoli` to implement reversible
  gate sequences. Not an LLVM extension question at all.

None of these involves an LLVM API the prototype has not already
demonstrated working. They are downstream implementation work, not
substrate-level validation.

### 7.3 When the substrate question would warrant re-evaluation

Re-evaluate only if one of the §4 scenarios becomes plausible. The
plausible trigger conditions: Phase 11 (optimization passes) needs
cross-region quantum/classical reasoning the intrinsic shape can't
express; a second frontend (Rust/Python) makes a richer substrate
worthwhile; a community quantum-MLIR dialect ratifies. Even then, the
alternative would be MLIR adoption (which is part of upstream LLVM) —
not a separate substrate.

## 8. Summary

CQ runs on stock LLVM. Validated 2026-05-22 by working prototype
against stock LLVM 19.1.7, covering the architecturally novel LLVM C++
APIs the IR pass relies on: forward lowering, per-op auto-uncomputation
via post-dominator analysis, call-graph specialization via function
cloning, and controlled-variant template substitution.

Every architecturally novel transformation in the pipeline maps to a
stable, documented LLVM C++ API. Four precedents prove the pattern
works at scale; the prototype proves it works for *this* project
across the load-bearing mechanism families. The one slice still
pending validation under the new design — tainted-`br i1`-driven
controlled-region detection — re-uses APIs (`PostDominatorTree`,
`BranchInst::getCondition()`) the prototype has already demonstrated
working in other contexts.

What remains is implementation engineering against the same already-
validated extension surface — multi-width parametrization, real
adjoint gate-sequence emission, Bennett wrap-around for
specializations, tainted-branch controlled-region detection, real
template bodies. None of these introduce LLVM API surface not already
exercised by the prototype.

## 9. References

- LLVM PassPlugin documentation:
  https://llvm.org/docs/WritingAnLLVMPass.html (legacy PM) and
  https://llvm.org/docs/NewPassManager.html (current)
- Clang plugin attributes:
  https://clang.llvm.org/docs/ClangPlugins.html
- Enzyme: https://enzyme.mit.edu/ — out-of-tree LLVM autodiff pass
  plugin
- AddressSanitizer:
  https://clang.llvm.org/docs/AddressSanitizer.html — intrinsic-call +
  pass-plugin pattern
- Polly: https://polly.llvm.org/ — pass-plugin polyhedral optimization
