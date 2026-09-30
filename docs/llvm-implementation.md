# LLVM Substrate — What CQ Uses from Stock LLVM

A stage-by-stage reference for the LLVM C++ APIs the CQ compilation
pipeline relies on. Every transformation maps to a public, documented
extension point in upstream LLVM — no patched sources, no vendored
`llvm-project`, no per-release rebase. This is
[`../NORTHSTAR.md`](../NORTHSTAR.md) design principle 9 (no LLVM fork,
no MLIR dialect) seen from the API side. The API names below were
checked against `ir-pass/src/`; where a claim depends on a particular
file, the file is named.

Companion documents:
- [`frontend.md`](./frontend.md) — user-facing intrinsic surface
  (`cq_theta`, `cq_phi`, `cq_measure`, `cq_invert_*`) and the Stage 1
  Clang/`-O1` flow that prepares the IR
- [`backend.md`](./backend.md) — IR pass and runtime ABI; the
  load-bearing half of the pipeline
- [`quantum-classical-handling.md`](./quantum-classical-handling.md)
  — taint as the Q/C boundary

---

## 1. The no-fork constraint

CQ needs one thing from LLVM that it does not have out of the box:
tainted stock opcodes must be traced back to quantum-derived SSA
values and replaced with calls that emit reversible-gate sequences.
That is an IR-to-IR transformation, and LLVM provides a supported
place for one: an **out-of-tree, new-pass-manager module plugin**
loaded with `-load-pass-plugin`. No new instruction kind, type, calling
convention or optimization pass is required (§4). Out-of-tree projects
such as Polly and Enzyme use the same loading mechanism.

**LLVM 19 is mandatory.** The top-level `CMakeLists.txt` stops with a
`FATAL_ERROR` if `LLVM_VERSION_MAJOR` is not 19, and `LLVM_DIR` must be
passed explicitly.

The three stages (numbering follows [`frontend.md`](./frontend.md) §8;
the exact flags are in `tests/e2e/run_slice.sh`):

- **Stage 1.** `clang -I include -include CQ.h -O1 -emit-llvm -S example.c`
- **Stage 2.** `opt -load-pass-plugin libCQPass.so -passes=cq-lowering`
- **Stage 3.** `clang example.lowered.ll libcq_templates.a libcq_runtime.a`
  — the templates archive comes **before** the runtime archive
  (template bodies call `cqrt_*`, and single-pass `ld` needs the caller
  first).

## 2. Stage-by-stage substrate

Each stage is mapped to the specific LLVM C++ API surface it uses.

### 2.1 Source surface — `CQ.h`

The user writes plain C. `CQ.h` is a header-only intrinsic surface
declaring:

- `cq_theta_<sfx>(x, θ)` — Ry rotation; the only taint source. One
  declaration per scalar suffix, selected by a C11 `_Generic` macro,
  each carrying `__attribute__((nomerge))` (§3.2).
- `cq_measure_<sfx>(x)` — measurement; the only sink. Same suffix set
  and `_Generic` macro.
- `cq_phi(φ)` — the **branch phase**: a single register-free
  `void cq_phi(double)` with no suffix family and no `_Generic`. It
  neither introduces nor propagates taint. The old
  `cq_phi_<sfx>(x, φ)` family is not declared; a use of those names
  is a loud failure in the pass.
- `cq_ry(x, θ)` — a statement macro, exactly `x = cq_theta(x, θ)`.
- `cq_invert_begin()` / `cq_invert_end()` — bracket macros around bare
  externs `__cq_invert_begin` / `__cq_invert_end`, each pinned by an
  `asm volatile("" ::: "memory")` barrier so the optimizer cannot move
  bracketed code across the marker.

The declarations are ordinary C `extern` functions. The pass finds
them by **exact name** in a fixed suffix table
(`WidthDispatch::thetaFn` is `M.getFunction("cq_theta_" + sfx)`;
`cq_phi` is looked up by its exact name), never by name prefix — a
user function that merely starts with `cq_theta_` is an unknown
callee. There is no `quantum` keyword, no annotation attribute, no
Clang AST plugin, no rewriter. Stock Clang accepts the source
unchanged.

**LLVM API used:** none — stock C compilation.

### 2.2 Stage 1 — Clang codegen + `-O1` cleanup

Stock Clang lowers C to LLVM IR. Stock `mem2reg` and `SROA` flatten
stack slots to SSA values so the pass sees post-`mem2reg` / post-`SROA`
IR (the [`backend.md`](./backend.md) §3.1 input contract). The `@cq_*`
calls remain as opaque external calls because they have unknown side
effects by default; LLVM will not fold or eliminate them across
optimization passes.

`-O1` is the pipeline the pass is validated against: control-flow
recognition is written against the shapes `-O1` produces (branch
polarity, `select` and `phi` forms, hoisting and sinking). Other levels
are not the supported floor; the risks are listed in
[`frontend.md`](./frontend.md) §8 "Optimization-level guidance".

**LLVM API used:** stock `-O1` pipeline.

### 2.3 Stage 2 — The IR pass (`cq-lowering`)

`cq::CQLoweringPass` is a **module pass** (`run(Module &,
ModuleAnalysisManager &)`; it ignores the analysis manager). It is
registered by `ir-pass/src/Plugin.cpp`, which exports the weak C
symbol `llvmGetPassPluginInfo` returning a
`PassPluginLibraryInfo{LLVM_PLUGIN_API_VERSION, "cq-lowering", …}`
whose callback calls `PassBuilder::registerPipelineParsingCallback`.
That is the **only** registration: the pass runs when named in
`-passes=cq-lowering`. It is not attached to a pipeline extension
point, so `clang -fpass-plugin=libCQPass.so` loads the plugin but does
not run the pass. A module containing no call to `cq_theta`, `cq_phi`
or `cq_measure` gets `PreservedAnalyses::all()` back and is left
byte-identical.

Every operation the pass performs, with the LLVM API it uses:

| Operation | LLVM API | Where |
|---|---|---|
| Register as pass plugin | `PassPluginLibraryInfo`, `PassBuilder::registerPipelineParsingCallback` | `Plugin.cpp` |
| Find the front-end calls | `Module::getFunction(name)`, `Value::users()`, `CallBase` (so an `invoke` is seen too) | `WidthDispatch.cpp`, `TaintPropagation.cpp` |
| Forward taint propagation | `Value::users()` + a work list over SSA def-use | `TaintPropagation.cpp` |
| Replace an instruction with a runtime call | `IRBuilder::CreateCall`, `Value::replaceAllUsesWith`, `Instruction::eraseFromParent` | the `*Lowering.cpp` and `*Emit.cpp` files |
| Declare runtime symbols lazily | `Module::getOrInsertFunction` with a `FunctionType` built from the ABI width (no attributes, so LLVM must assume unknown side effects) | `WidthDispatch.cpp`, `ControlledSymbols.cpp` |
| Recognize a tainted `br i1` / `select` / `switch` | `BranchInst::getCondition()` etc. + taint-set membership | `ControlDetect.cpp` |
| Region shape, free points, loops | `DominatorTree DT(F)`, `PostDominatorTree PDT(F)`, `LoopInfo LI(DT)` — constructed directly per function, not fetched from an analysis manager | `FreePoint.cpp`, `Uncomputation.cpp`, `LoopLowering.cpp`, `PredMuxFlatten.cpp`, `QramLowering.cpp` |
| Trip counts | `ScalarEvolution SE(F, TLI, AC, DT, LI)` built by hand (`TargetLibraryInfoImpl(Triple(M.getTargetTriple()))`, `AssumptionCache`) | `LoopUnrollPrepass.cpp`, `OpcodeLowering.cpp` |
| Value-range facts | `LazyValueInfo`, `ConstantRange`, `KnownBits`, `simplifyInstruction` | `ArmClassify.cpp`, `PredMuxFlatten.cpp` |
| Fully unroll a proven-constant-trip loop | `simplifyLoop`, `formLCSSARecursively`, `UnrollLoop` | `LoopUnrollPrepass.cpp` |
| Clone a callee for a tainted-argument mask | `CloneFunction`, `CloneFunctionInto`, `ValueToValueMapTy`, `Function::Create(FunctionType, Linkage, Name, Module)`, `CallInst::setCalledFunction` | `SpecializeClone.cpp`, `Specialization.cpp` |
| Keep clone attributes honest | `Function::setMemoryEffects`, `removeFnAttr(WillReturn/NoFree)`, `removeRetAttr(Range)` — a lowered clone calls side-effecting runtime primitives | `SpecializeClone.cpp` |
| Recognize curated `llvm.*` intrinsics | `IntrinsicInst`, exact `Intrinsic::ID` | `IntrinsicLowering.cpp` |
| Membership records on instructions | `Instruction::setMetadata` with an empty `MDNode` (the `!cq.branchphase` tag) | `ChainWalk.cpp` |
| Self-cleaning pointer-keyed tables | `CallbackVH` / `WeakTrackingVH`, so a deleted `Value` drops out of every table | `ScrubOnDelete.h` |
| Emit adjoint sequences | `IRBuilder` constructing new `cqrt_*` / `cq_template_*_unc` calls in reverse program order | `EmitInverse.cpp`, `Uncomputation.cpp` |
| Preserve source locations | `Instruction::setDebugLoc(SourceInst->getDebugLoc())` | every emitter |
| Emit loud diagnostics | `LLVMContext::diagnose(DiagnosticInfoUnsupported(…, DS_Error))` carrying the offending instruction's `!dbg` | every decline site |
| Verify the output | not the pass: `opt` (and `cq-opt`) run `VerifierPass` after it | `ir-pass/tools/cq_opt_main.cpp` |

`opt -verify` clean shows the IR is well typed; it says nothing about
whether the emitted unitary is right.

**The specific Stage 1 → 2 transformation** — tracing opcodes back to
quantum-derived SSA values and inserting emission-function calls —
decomposes into:

1. Forward taint propagation (SSA walk): stock `Value::users()` +
   a work list, seeded from `@cq_theta_*` return values.
2. Identify tainted `add`/`mul`/`icmp`/etc.: stock
   `Instruction::getOpcode()`.
3. Build a new `CallInst` to `@cq_template_<opcode>_<width>` with
   handle SSA values as args: stock `IRBuilder::CreateCall`.
4. `oldInst->replaceAllUsesWith(newCall); oldInst->eraseFromParent()`:
   stock.

### 2.4 Stage 3 — Lowered IR → object code → binary

Post-pass, the IR contains only stock LLVM opcodes + extern `cqrt_*`
and `cq_template_*` calls. Standard `clang` codegen handles it and the
link resolves the externs against `libcq_templates.a` and
`libcq_runtime.a`.

The e2e harness links at clang's **default `-O0`, deliberately**: the
lowered IR is the verified artifact, and an optimized Stage 3 could
constant-fold or reorder the classical remainder and desynchronize the
trace from the golden. Other Stage 3 levels are not exercised.

**LLVM API used:** stock `clang`, stock linker.

### 2.5 Runtime (`libcq_runtime`, `libcq_templates`)

Stock C libraries, built by CMake with the platform C compiler, with no
LLVM dependency at all. Today they are a **trace backend**: each
`cqrt_*` and `cq_template_*` call prints one line
(`symbol(args) -> ret`), `cqrt_measure_*` returns 0, and there is no
simulation. The golden trace is the contract. `cq_templates.{h,c}` are
generated from `tools/opcode_table.yaml`. Not an LLVM consumer.

## 3. Edge cases and clarifications

A few patterns can look like they would require modifying LLVM
sources; this section explains why each is covered by stock extension
points.

### 3.1 "Don't intrinsics need registration in LLVM's intrinsic table?"

No. Real LLVM intrinsics (`@llvm.memcpy`, `@llvm.ctpop`) are registered
in `Intrinsics.td` and *would* require LLVM source modifications to
add. But `@cq_theta_*`, `@cq_phi`, `@cq_measure_*` are **not LLVM
intrinsics in the technical sense** — they are ordinary external
function declarations whose names the pass looks up (§2.1). The CQ
vocabulary's use of "intrinsic" is informal — it means "function the IR
pass treats specially," not `llvm::Intrinsic::ID`. (The pass *does*
also recognize a curated set of real `llvm.*` intrinsics, by exact
`Intrinsic::ID`, to lower them to templates.)

### 3.2 "Won't LLVM's optimizer CSE/DCE our `cq_*` calls into oblivion?"

No, provided the declarations carry no `readnone`/`readonly`-style
attributes. By default, external function calls have unknown side
effects and LLVM will not fold or eliminate them; the required
behavior comes from how the functions are declared, not from LLVM.

One optimization needed a second, explicit answer. `SimplifyCFG` can
hoist or merge two *identical* calls from the arms of a branch, and
for `cq_theta(5, .9)` on two arms that turns a register seeded under a
condition into an unconditional one. `CQ.h` therefore marks every
`cq_theta_*` call `nomerge` (`__attribute__((nomerge))`, and the header
refuses to compile on a compiler without it). This covers direct calls
only: a call through a function pointer does not carry the attribute
(see the header comment for the residual cases).

### 3.3 "What about `__cq_q_<callee>_<mask>` mangled names? Does the C++ name mangler need extending?"

No. We choose the mangling: the specialization clone for a callee is
named `__cq_q_<callee>_<binary>`, where `<binary>` renders the
tainted-argument mask MSB-first, zero-padded to the argument count
(`ipow(tainted, classical)` → `__cq_q_ipow_01`). They are plain C
identifiers with `_` separators; no Itanium mangler involvement.

### 3.4 "Will `!dbg` survive enough opt passes for usable diagnostics?"

Diagnostics carry the offending instruction's `DebugLoc`, and every
emitter copies the source instruction's `DebugLoc` onto the
instructions it creates, so a decline is source-located whenever the
input was compiled with debug info. Whether a given `-O1` transform
preserves the location is an LLVM property the pass does not control.

### 3.5 "What about MLIR?"

Not used. Re-evaluating MLIR is an owner decision
([`../NORTHSTAR.md`](../NORTHSTAR.md) principle 9). If it were ever
adopted, MLIR is part of the upstream LLVM project, not a separate
substrate.

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
| Modifying an existing optimization pass to know about quantum semantics | Avoided — `nomerge` on the `cq_theta` calls (§3.2) and the `-O1` pipeline are sufficient |

If any of these became necessary, the substrate question would warrant
re-evaluation as an owner decision.

## 5. Build, load, ship

- **Build dependency:** stock upstream LLVM, exactly major version 19
  (§1). Moving to a newer LLVM means re-checking the API names in
  §2.3 against the new headers; there is no patch maintenance.
- **The pass:** `libCQPass.so`, a CMake `MODULE` library that does
  **not** link LLVM — symbols resolve from the host `opt` at `dlopen`
  time (on macOS, `-undefined dynamic_lookup`). It is loaded with the
  new-PM `-load-pass-plugin`, never the legacy `-load`.
- **`cq-opt`:** a purpose-built driver (`build/ir-pass/cq-opt`, from
  `ir-pass/tools/cq_opt_main.cpp`) compiled from the **same** pass
  sources and linking only the LLVM libraries the pass needs. It
  accepts and ignores `-load-pass-plugin`, accepts only
  `-passes=cq-lowering`, and runs `VerifierPass` after the pass exactly
  as `opt` does. It exists so the test suite does not pay stock `opt`'s
  per-spawn start-up cost; it is a test-harness tool, not part of the
  user pipeline.
- **Runtime archives:** `libcq_templates.a` and `libcq_runtime.a`
  (static), consumable by stock `clang`.
- **User-facing command:** the three stages of §1 run as a pipeline:
  `clang -O1 -emit-llvm -include CQ.h | opt -load-pass-plugin
  libCQPass.so -passes=cq-lowering | clang … libcq_templates.a
  libcq_runtime.a`. See [`frontend.md`](./frontend.md) §8 for the
  canonical invocation.

## 6. References

- LLVM new pass manager: https://llvm.org/docs/NewPassManager.html
- Writing an LLVM pass: https://llvm.org/docs/WritingAnLLVMPass.html
- Enzyme (out-of-tree LLVM autodiff pass plugin): https://enzyme.mit.edu/
- Polly (polyhedral optimization, loadable as a plugin): https://polly.llvm.org/
