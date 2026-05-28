# LLVM Substrate — What CQ Uses from Stock LLVM

A stage-by-stage reference for the LLVM C++ APIs the CQ compilation
pipeline relies on. Every transformation maps to a stable, documented
extension point in upstream LLVM — no patched sources, no vendored
`llvm-project`, no per-release rebase. The no-fork shape was validated
2026-05-22 by a working prototype against LLVM 19.1.7
([`../prototype/`](../prototype/)); this document records the substrate
the prototype and full pipeline depend on.

Companion documents:
- [`bennett-jl-comparison.md`](./bennett-jl-comparison.md) — design
  convergences with Sturm.jl / Bennett.jl / Orkan

The frontend and backend design guides are in preparation.

---

## 1. Background

Earlier project notes asked whether CQ would need to fork LLVM — patch
its sources, vendor a copy of `llvm-project`, maintain a rebase against
upstream — to enable the Stage 4 → 5 transition where tainted LLVM
opcodes are traced back to quantum variables and replaced with calls
that emit reversible-gate sequences. The answer is no: the pipeline was
designed against a no-fork constraint, every transformation maps to a
stable documented LLVM C++ API, and four production-quality precedents
(Enzyme, AddressSanitizer, OpenMP runtime, Polly) ship the same shape
without forking LLVM. The conclusion was validated against stock LLVM
19.1.7 by the prototype at [`../prototype/`](../prototype/).

The remainder of this document is the substrate reference: stage by
stage, the specific LLVM extension points and C++ APIs CQ uses.

## 2. Stage-by-stage substrate

Each stage is mapped to the specific LLVM C++ API surface it uses.

### 2.1 Stage 1 — Source surface (`quantum int x`)

The user-visible `quantum` qualifier needs to reach the AST as a signal
the rewriter can detect. Two stock mechanisms cover this:

- **Macro form (current plan):** `#define quantum
  __attribute__((annotate("quantum")))` in `CQ.h`. After preprocessing,
  the user's `quantum int x` becomes `__attribute__((annotate("quantum")))
  int x`. The rewriter sees an `AnnotateAttr("quantum")` on the
  `VarDecl`.
- **Clang attribute plugin:** If we ever want richer semantics than a
  string annotation, Clang has a `PluginASTAction` + `ParsedAttrInfo`
  registration API (stable since Clang 12) for registering custom
  attributes as plugins.

Promoting `quantum` to a true C keyword would require modifying
`TokenKinds.def`, `Sema`, and the parser — out of scope by design.
The annotation attribute carries the same signal without touching
Clang sources.

**LLVM API used:** `clang::AnnotateAttr` (stock libtooling).

### 2.2 Stage 2 — Libtooling rewriter

The rewriter is a separate tool linked against `libclangTooling`,
`libclangAST`, `libclangFrontend`. It walks the AST via
`RecursiveASTVisitor`, rewrites source via `clang::Rewriter`, and emits
a `.transpiled.c` file.

Libtooling is a stock LLVM/Clang library with a published API. The
exact mechanism used by `clang-tidy`, `clangd`, `include-what-you-use`,
and `clang-format`.

**LLVM API used:** `clang::tooling::CommonOptionsParser`,
`clang::Rewriter`, `clang::RecursiveASTVisitor`, `clang::ASTConsumer`.

### 2.3 Stage 3 — Clang frontend on rewritten C

The rewritten file is plain C99 with `qint_mid_t` struct declarations
and extern `@cq_*` function declarations. Stock Clang parses it. There
is no CQ-specific behavior at this stage — it is plain C compilation.

**LLVM API used:** `clang -emit-llvm -c`.

### 2.4 Stage 4 — Clang codegen + `-O1` cleanup

Stock Clang lowers C to LLVM IR. Stock `mem2reg` and `SROA` passes
flatten the `q*_mid_t` struct inside function bodies while preserving
it at signatures (SROA does not cross function boundaries by
construction). The `@cq_*` calls remain as opaque external calls
because they have unknown side effects by default.

The fact that mem2reg/SROA don't lose the quantum signal at function
boundaries is a *property of how SROA is defined upstream*, not
something we need to enforce — SROA only operates within a function,
documented and stable.

**LLVM API used:** Stock `-O1` pipeline.

### 2.5 Stage 4 → Stage 5 — The IR pass

Every operation the pass performs, with the specific LLVM C++ API it
uses:

| Operation | LLVM API | Notes |
|---|---|---|
| Register as pass plugin | `llvm::PassPluginLibraryInfo`, `PassBuilder::registerPipelineParsingCallback` | New PM, stable since LLVM 13 |
| Iterate functions/blocks/instructions | `Module::functions()`, `Function::begin()/end()`, `BasicBlock::begin()/end()` | |
| Identify `@cq_*` calls | `CallInst::getCalledFunction()`, `Function::getName()` (string prefix match) | |
| Forward taint propagation | `Value::users()`, `Instruction::operand_values()`, set-based work queue | Bog-standard SSA dataflow |
| Read function-parameter types | `Function::arg_begin()`, `Argument::getType()`, `Type::isStructTy()` | |
| Build call graph | `llvm::CallGraphAnalysis` (analysis pass, new PM) | |
| Clone function for specialization | `llvm::CloneFunction`, `CloneFunctionInto`, `ValueToValueMapTy` | Same mechanism as Enzyme |
| Create function with rewritten signature | `Function::Create(FunctionType, Linkage, Name, Module)` | |
| Replace instruction with new call | `IRBuilder::CreateCall`, `Instruction::replaceAllUsesWith`, `Instruction::eraseFromParent` | |
| Erase `q*_mid_t` struct types from signatures | Build new `FunctionType`, migrate body, update call sites | |
| Controlled-variant substitution in `cq_when_*` regions | Walk CFG between marker calls, replace each gate's call with controlled variant | Uses `DominatorTree`, `LoopInfo` if needed |
| Live-range / last-use for uncomputation | `Value::users()` + dominator analysis, or `LivenessAnalysis` | |
| Emit adjoint sequences | `IRBuilder` constructing new `cqrt_*` calls in reverse order | |
| Preserve source locations | `Instruction::setDebugLoc(SourceInst->getDebugLoc())` | |
| Emit user diagnostics | `LLVMContext::diagnose(DiagnosticInfo&)`, `OptimizationRemark*` | |
| Mark `cqrt_*` calls side-effecting | `Function::addFnAttr(Attribute::NoUnwind)`; deliberately not `ReadNone`/`ReadOnly` | |
| Run at a specific pipeline position | `PassBuilder::registerOptimizerLastEPCallback` (and phase callbacks) | |

Every entry is a stock LLVM C++ API.

**The specific Stage 4 → 5 transformation** — tracing opcodes to
quantum variables and inserting emission-function calls — decomposes
into:

1. Forward taint propagation (SSA walk): stock `Value::users()` +
   dataflow.
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

### 2.6 Stage 5 → Stage 6 — Lowered IR → object code → binary

Post-pass, the IR contains only stock LLVM opcodes + extern `cqrt_*`
calls. Standard `llc` / `clang -c` backend codegen handles it. The
linker (preferably `ld.lld` for LTO) links against `libcq_runtime.so`
and `libcq_templates.{bca,a,so}`.

Everything past Stage 5 is plain C-toolchain operation.

**LLVM API used:** Stock `llc`, stock linker.

### 2.7 Runtime (`libcq_runtime`)

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
add. But `@cq_*` functions are **not LLVM intrinsics in the technical
sense** — they are ordinary external function declarations whose names
happen to start with `cq_`. The IR pass pattern-matches by string
name. Same trick Enzyme uses with `__enzyme_autodiff` and ASan uses
with `__asan_*`.

The CQ vocabulary's use of "intrinsic" is informal — it means
"function the IR pass treats specially," not `llvm::Intrinsic::ID`.

### 3.2 "Won't LLVM's optimizer CSE/DCE our `cq_init` calls into oblivion?"

No, provided we don't mark them `readnone`/`readonly`. By default,
external function calls have unknown side effects and LLVM will not
fold or eliminate them. The required behavior comes from attribute
discipline on the declarations — a property of how we declare the
functions, not of LLVM.

### 3.3 "What about `__cq_q_<f>_<mask>` mangled names? Does the C++ name mangler need extending?"

No. We choose the mangling. They are plain C identifiers with `_`
separators. No Itanium mangler involvement.

### 3.4 "Doesn't Clang need to know about `quantum` for the parser to accept it?"

Only if `quantum` is a true keyword. With the macro-or-annotation
approach (§2.1), Clang parses `int x` and attaches an annotation —
both stock behaviors.

### 3.5 "What if a stock LLVM pass folds across our intrinsic in a way we can't prevent?"

Attribute discipline plus pipeline ordering handle this. Worst case
(not expected for any Phase 1–11 case): register our pass
`EP_EarlyAsPossible` to run before problematic passes. Stock
pipeline-extension-point API.

### 3.6 "Will `!dbg` survive enough opt passes for usable diagnostics?"

`!dbg` survives the standard `-O1` pipeline. Some aggressive late
passes can drop it, but our pass runs before those and attaches `!dbg`
to its own emitted instructions. If a specific opt pass turns out to
be lossy, we either re-attach `!dbg` afterwards (our responsibility)
or disable that pass at our pipeline position — stock mechanisms
either way.

### 3.7 "What about cross-language input — Rust/Fortran needing IR?"

Stock LLVM linker handles `.bc` from any frontend. Polyglot LTO is
exactly what `clang`, `rustc --emit=llvm-bc`, `flang -emit-llvm` are
designed for. No CQ-side involvement.

### 3.8 "What about MLIR?"

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
| Modifying Clang's lexer/parser to recognize a new keyword | Avoided — annotation attribute carries the signal |
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

CQ's extension surface (~7 intrinsics, no new types, no new opcodes)
is *smaller* than any of these.

## 6. What this means in practice

- **Build dependency:** Stock upstream LLVM, version-pinned (Clang 19
  per project memory). When upstream releases LLVM 20, we update our
  pass plugin to the new PassPlugin API revision (usually a one-day
  port). No patch maintenance.
- **Plugin shipping:** `libcq_pass.so` (the pass),
  `libcq_templates.{bca,a,so}` (templates), `libcq_runtime_<variant>.so`
  (runtime). All consumable by stock `opt` / `clang`.
- **User-facing command:** A thin wrapper script `cq` that runs
  `clang -emit-llvm | opt -load-pass-plugin libcq_pass.so
  -passes=cq-lowering | clang -c -o`. Or equivalently
  `clang -fpass-plugin=libcq_pass.so` on a single line.
- **Distribution:** Same shape as Polly, Enzyme, AddressSanitizer when
  shipped out-of-tree.

## 7. Prototype validation

The substrate claims above are not paper-only. A working prototype
exercises every architecturally novel mechanism against stock LLVM
19.1.7.

### 7.1 Validation status

**VALIDATED 2026-05-22** across the three architecturally novel
mechanisms. A working prototype lives at
[`../prototype/`](../prototype/) and exposes three passes
(`cq-lowering`, `cq-uncompute`, `cq-specialize`) — one per validation
slice.

#### Phase 2 (cq-lowering) findings

| Claim | Validation |
|---|---|
| Pass plugin builds against stock LLVM 19 | ✓ — clean build against LLVM 19.1.7, no LLVM source modifications |
| Pass loads via `opt -load-pass-plugin` and runs without crash | ✓ |
| Output IR passes `opt -verify` | ✓ |
| Forward taint propagation works on stock SSA APIs | ✓ — `Value::users()` + worklist |
| `q*_mid_t` struct dissolves into `i32` handles | ✓ — `extractvalue` / `insertvalue` cleanup works as designed |
| `@cq_init_i32` → `@cqrt_alloc_classical_i32` lowering | ✓ |
| Tainted `add i32` → `@cqrt_template_add_i32` lowering | ✓ |
| `@cq_measure` → `@cqrt_measure` lowering | ✓ |
| Front-end intrinsic declarations erased after lowering | ✓ — module-level cleanup works on stock `Module::getFunction()` |

#### Phase 5 (cq-uncompute) findings

| Claim | Validation |
|---|---|
| `PostDominatorTreeAnalysis` accessible from a Module pass via `FunctionAnalysisManagerModuleProxy` | ✓ |
| `findNearestCommonDominator` over user blocks gives the right insertion BB | ✓ — handles single-BB and would handle multi-BB |
| `IRBuilder::SetInsertPoint` at post-dominating last use works | ✓ — `cqrt_free` emitted at correct point for each handle |
| `ReturnInst` escape detection (skip uncomputation when handle is returned) | ✓ |
| Composes with `cq-lowering` in the same pipeline | ✓ — `-passes='cq-lowering,cq-uncompute'` works end-to-end |

#### Phase 7 (cq-specialize) findings

| Claim | Validation |
|---|---|
| `CloneFunction` + `ValueToValueMapTy` clones a function with full body fidelity | ✓ — clone has matching `extractvalue + add + insertvalue + ret` shape |
| Mangled-name renaming via `Function::setName` works | ✓ — `__cq_q_<orig>_q1` |
| `Function::setLinkage(InternalLinkage)` works (DCE-eligible) | ✓ |
| `CallInst::setCalledFunction` retargets call sites | ✓ — original `@example` now calls `@__cq_q_double_it_q1` |
| Pre-existing front-end intrinsics (`@cq_*`) correctly skipped, not re-cloned | ✓ |

#### Phase 5 multi-BB findings

| Claim | Validation |
|---|---|
| `PostDominatorTree::findNearestCommonDominator` returns the merge block when uses span both arms of an `if` | ✓ |
| `getFirstInsertionPt()` correctly places `cqrt_free` between `phi` and `ret` in the merge block | ✓ |
| `cqrt_free` is emitted **exactly once** (not duplicated into either arm) | ✓ |
| No code changes were needed — original `computeFreePoint()` already correct for non-trivial CFG | ✓ |

#### Phase 4 (cq-control) findings

| Claim | Validation |
|---|---|
| Region detection via `cq_when_begin`/`cq_when_end` bracket walking works | ✓ |
| `cqrt_template_*` calls inside a region are substituted with the `_controlled` variant | ✓ — control handle prepended as first arg |
| `cqrt_template_*` calls **outside** any region are left alone | ✓ |
| Bracket call sites and declarations erased after substitution | ✓ |
| `Module::getOrInsertFunction` with dynamically-built `FunctionType` works for variant declarations | ✓ |

#### Overall

| Claim | Result |
|---|---|
| "Lightweight extension" claim quantitatively defensible | ✓ — 525 LOC C++ for all four passes combined |
| All five checks pass on stock LLVM 19.1.7 | ✓ — no LLVM source patches anywhere in the dependency chain |
| Every architecturally novel LLVM-API mechanism in the design demonstrated working | ✓ — taint propagation, mid→handle rebinding, post-dominator analysis (linear + branched), function cloning, region substitution |

### 7.2 What the prototype slices prove

The three prototype passes (Phase 2 / 5 / 7) collectively exercise
every architecturally novel mechanism the IR pass needs. Specifically:

| Mechanism | LLVM API exercised | Demonstrated by |
|---|---|---|
| Taint propagation across stock SSA | `Value::users()` + worklist | Phase 2 |
| Mid-struct → handle rebinding | `ExtractValueInst` / `InsertValueInst` cleanup, `replaceAllUsesWith` | Phase 2 |
| Opcode substitution with runtime calls | `IRBuilder::CreateCall`, `Instruction::eraseFromParent` | Phase 2 |
| Module-level cleanup of unused declarations | `Module::getFunction`, `Function::eraseFromParent` | Phase 2 |
| SSA last-use analysis | `PostDominatorTreeAnalysis`, `findNearestCommonDominator`, `Instruction::comesBefore` | Phase 5 |
| Cross-pass analysis-manager access | `FunctionAnalysisManagerModuleProxy` | Phase 5 |
| Function cloning with full body fidelity | `CloneFunction`, `ValueToValueMapTy` | Phase 7 |
| Function attribute manipulation | `Function::setName`, `Function::setLinkage` | Phase 7 |
| Call-site retargeting | `CallInst::setCalledFunction` | Phase 7 |
| Cross-pass composition | `opt -passes='cq-lowering,cq-uncompute'` runs end-to-end | Phases 2 + 5 |

The remaining unbuilt items reuse these same APIs — no new substrate
required:

- **Multi-width** (`i1`/`i8`/`i16`/`i64`) — parametrize the existing
  `i32` pattern over `Type::getIntNTy(Ctx, W)`. No new mechanism.
- **Real adjoint gate-sequence emission** — replace the `cqrt_free`
  placeholder with the actual reverse-order template calls before the
  free. Pure IR construction; uses already-validated `IRBuilder` API.
- **Bennett wrap-around for specializations** — replace the
  signature-preserving clone with a `Function::Create` + new
  `FunctionType` + body migration via `CloneFunctionInto`. Adds
  forward-CNOT-copy + reverse on top, both reusing already-validated
  IR construction.
- **Phase 4 region handling** (`cq_when_*` spanning complex CFG) —
  walks between bracket calls via stock `BasicBlock` iteration +
  `DominatorTree`. No new mechanism.
- **Rewriter → prototype integration** — uses stock Clang libtooling
  to produce the Stage 4 IR that the prototype currently writes by
  hand. Separate validation axis from this document; the LLVM API
  surface is what `clang-tidy` and `clang-format` already exercise at
  scale.
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
against stock LLVM 19.1.7, covering all three architecturally novel
mechanisms: forward lowering (Phase 2), per-op auto-uncomputation via
post-dominator analysis (Phase 5), and call-graph specialization via
function cloning (Phase 7).

Every architecturally novel transformation in the pipeline maps to a
stable, documented LLVM C++ API. Four precedents prove the pattern
works at scale; the prototype proves it works for *this* project
across the three load-bearing mechanism families.

What remains is implementation engineering against the same already-
validated extension surface — multi-width parametrization, real
adjoint gate-sequence emission, Bennett wrap-around for
specializations, region handling, rewriter integration, real template
bodies. None of these introduce LLVM API surface not already
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
