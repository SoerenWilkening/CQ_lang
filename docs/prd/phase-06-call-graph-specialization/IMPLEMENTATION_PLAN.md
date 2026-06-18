# Phase 6 IMPLEMENTATION_PLAN — call-graph specialization (function lifting)

**Status (2026-06-18).** Companion to
[`PRD.md`](PRD.md) (same directory), authored per Rule 16 immediately after it.
The PRD fixes *scope* and *design decisions*; this plan fixes the **WI
decomposition, the resolved DDs, the verified current-state map, and the
dependency-ordered red→green→clear work items** that PRD §7 explicitly defers
"to a companion `IMPLEMENTATION_PLAN.md`" (PRD.md:414-418). It does **not**
restate scope already settled in the PRD; it specifies *how* and *how it is
verified*. **Authoritative status: [`ROADMAP.md`](../../../ROADMAP.md) Phase 6**,
not this file.

> **Doc/phase numbering caveat (carried from PRD.md:33-39).** `backend.md`
> internally calls this work "§7 / Phase 7" (old numbering: doc §-numbers run one
> ahead of ROADMAP phases — doc §8 control = ROADMAP Phase 4, doc §9 uncompute =
> ROADMAP Phase 5). This is **ROADMAP Phase 6**. The closed bd issue
> `test_C_libtooling-mh3` ("Phase 7 prototype: validate call-graph
> specialization") is the *old* numbering for this phase. Where this plan or the
> in-source comments cite "IMPLEMENTATION §6.5" (e.g.
> `CQLoweringPass.cpp:150-161`), that is the *twin-pipeline-trap* section of this
> document, **not** ROADMAP increment 6.5 (the classical-call-under-control
> slice). The two collide textually; they are unrelated.

---

## 1. How to read this plan

The plan is grounded in a **verified current-state map** (§2) — every concrete
file:line / symbol / message-text claim the PRD makes was re-checked against the
live tree; corrections are in **bold**. §3 fixes the module decomposition. §4
resolves the seven DDs the PRD leaves open. §5 is the red→green→clear WI ladder
per increment. §6 is the fixture/golden catalog. §7 is the build infra. §8 ties
PRD §6 risks to closing WIs. §9 is the strict landing order.

The two unforgivable bug classes shape every WI: **over-accept** at the carve-out
(an `invoke`/indirect/`cq_*`/recursive/fp callee slipping into the
specializer — a silent miscompile, Rule 1/11) and **double-uncompute** (the
per-op Phase-5 `_unc` *and* the whole-body Bennett reverse both adjointing the
same gate — use-after-free + double-free, Rule 8). Over-decline is always safe
(Prime Directive).

Two contracts pinned up front because every over-accept / double-uncompute
argument below depends on them (the four review lenses converged here):

- **C-Plan (decline-by-default carve-out).** `detectSpecializations` is a
  pure-analysis **pre-pass that runs BEFORE `declineTaintEscapes`** in *both*
  entry points (before `:64` in `run()`, before `:154` in `runOnFunction`). It
  runs the FULL `classifyCandidate` rejection set and enters **only proven-Accept
  sites** into `SpecPlan.Pending` (plan membership ⇔ proven specializable). The
  `:419` carve-out then suppresses `kMsgUnknownCallee` **only** for a site present
  in `SpecPlan.Pending`; every candidate-shaped-but-rejected site (invoke,
  indirect, no-IR, recursion, `cq_*`, measure, fp/i128/vector) is
  **absent from the plan and therefore STILL fires its loud decline at `:419`**.
  The default is decline; suppression is the proven exception. (Rule 1, Prime
  Directive.)
- **C-Taint (disjoint TaintSets).** A clone is lowered under a **fresh
  `cloneTaint`** whose `Value*` are **NEVER unioned into the original module
  `taint`**. The only original-`taint` member the clone produces is the
  **retargeted call RESULT in the caller**, which becomes tainted by the existing
  worklist (`TaintPropagation.cpp:305-306`, a tainted-arg call result is a user of
  a tainted value) and is owned by the caller's existing `:115` uncompute. Because
  clone-internal handles live only in `cloneTaint` and `uncompute`'s terminal gate
  reads the ORIGINAL `taint.Tainted` (`Uncomputation.cpp:173`), the clone's rails
  are **categorically invisible** to the `:115` uncompute — the disjoint-TaintSet
  boundary, **not** `ControlOwnedRails`, is what prevents double-uncompute
  (DD-1/DD-2). (Rule 8.)

---

## 2. Verified current-state map

Every concrete claim the PRD anchors on, re-verified against the live tree
(`HEAD` at `8517a4e`). Corrections are in **bold**.

| # | PRD claim (location) | Symbol / text | Status | Real location / correction |
|---|---|---|---|---|
| C1 | `lowerRotations` at `CQLoweringPass.cpp:110`, runs before its rotations (PRD:174,287) | `lowerRotations(M, wd, taint, &plan)` | confirmed | `ir-pass/src/CQLoweringPass.cpp:110` in `run()`. **The per-function twin calls it again at `:169`** — the only stage taking the `ControlPlan` (`RotationLowering.h:54`, by pointer `*plan`). |
| C2 | `runOnFunction` at `CQLoweringPass.cpp:121-177` (PRD:179) | `bool CQLoweringPass::runOnFunction(Function&)` | confirmed | Opens `:121`, `return true;` at `:176`, close `:177`. It is a **"compatibility shim"** (its own comment `:122-126`); the canonical loop is `run()` at `:45`, **not** `runOnFunction`. |
| C3 | `onlyInF` scoping at `:136-148` (PRD:182) | `auto onlyInF = [&F](auto &Calls){…}` | confirmed | Lambda `:136-142`, applied to `Theta/Phi/MeasureCalls` `:143-145`, re-check early-out `:146-148`. **`onlyInF` filters ONLY the three intrinsic work lists that `lowerRotations`/`lowerMeasures` read.** It does **not** scope `lowerOps` — see C25. It does **not** recompute taint. Partial template only. |
| C4 | `lowerControlRegions` at `:84`, before `lowerRotations` (PRD:73-84) | `detectControlRegions` `:83` / `lowerControlRegions` `:84` | confirmed | Control regions lowered strictly before rotations so they read the still-present `@cq_theta` result (in-source rationale `:77-82`). Same order in the twin (`:162-163` control, `:169` rotations). |
| C5 | CLAUDE.md "8-stage" pipeline matches code | stage list | **corrected** | **The CLAUDE.md summary is a simplification; the real `run()` is 12 numbered steps** (`:45-119`): propagate `:47` · passthrough early-out `:54-56` · `declineTaintEscapes` `:64` · `declineStaleRecordOps` `:71` · `detectControlRegions` `:83`+`lowerControlRegions` `:84` · `declineClassicalMuxes` `:96` · `declineLiftedStaleRecordOps` `:106` (a SECOND post-lift stale-record re-sweep, NOT in the CLAUDE.md list) · `lowerRotations` `:110` · `lowerOps` `:111` · `lowerMeasures` `:112` · `uncompute` `:115` · `eraseDeadDecls` `:116` (module-level intrinsic-decl cleanup, NOT in the list). **Phase 6 inserts a 13th step (`detectSpecializations`) BEFORE `declineTaintEscapes` `:64`, and a 14th (`specialize()`) between `declineLiftedStaleRecordOps` `:106` and `lowerRotations` `:110` — both mirrored in the twin (C-Plan / DD-1).** |
| C6 | Carve-out at `declineTaintEscapes`, lift point `TaintPropagation.cpp:412-417`, msg `:327-328` (PRD:87,214-216) | `kMsgUnknownCallee` | confirmed | `kMsgUnknownCallee = "cq taint escape: tainted value consumed by an unknown callee"` at `:327-328`. Decline branch `:409-419`; comment `:412-417` literally names "Phase 6 clone-on-taint is NOT implemented; a visible body is exactly as un-lowered as a declaration"; prefix skip `:409-411`; `if (readsTaintedValue(I, taint))` at `:418`, `diagnoseEscape(&I, kMsgUnknownCallee);` at **`:419`**. `declineTaintEscapes` takes **`const TaintSet&`** (`TaintPropagation.h:168`, impl `:357`) with **no `WidthDispatch&` in scope** — pure analysis, unlike every mutable stage. The carve-out therefore cannot consult `wd` or re-derive acceptance; it can only do a `SpecPlan` membership test (C-Plan, DD-1). |
| C7 | Live pass is greenfield; archived mechanics at `archive/prototype/cq_pass.cpp:345-394` (PRD:5-15) | `CQSpecializePass` | confirmed | grep across `ir-pass/` for `CloneFunction`/`setCalledFunction`/`ValueToValueMap` = **zero hits**. No `Specialization` module. Plugin registers exactly `cq-lowering` (`Plugin.cpp:26`). Prototype `cloneAndMangle` at `:387` (`CloneFunction(Orig,VMap)` `:389`, `setName("__cq_q_"+name+"_q1")` `:390`, `InternalLinkage` `:391`), `setCalledFunction` `:373`, `SpecCache` `DenseMap<Function*,Function*>` `:368` (**keyed on `Function*` only — collapses distinct signatures, must NOT carry forward**), candidate key `hasQintMidArg` `:378` (**the retired `qint_mid` struct-name test — must NOT carry forward**), intrinsic skip by **name-prefix** `:358-361` (**must NOT carry forward — Phase 6 mandates exact-pointer membership**). |
| C8 | `CloneFunction` verified against LLVM 19 `Cloning.h:135-136` (PRD:10-11) | `Function *CloneFunction(Function*, ValueToValueMapTy&, ClonedCodeInfo* = nullptr)` | confirmed | `/usr/local/opt/llvm@19/include/llvm/Transforms/Utils/Cloning.h:135-136`, exact. Precondition (`:133`): VMap has no non-identity GlobalValue mappings. `CloneFunctionInto` (full-control, args-via-VMap, NameSuffix) at `:145-169` if a pre-shaped i32-handle shell is ever needed. |
| C9 | `cqrt_copy_<W>` via `WidthDispatch::copyFn`, integer-only (PRD:68,98,284) | `FunctionCallee copyFn(StringRef) const` | confirmed | `WidthDispatch.cpp:119-136`, mints `void cqrt_copy_<W>(i32 src, i32 dst)`; **returns a NULL `FunctionCallee` for non-integer / unknown width (`:129-130`)** — the fp-decline gate. Runtime declares only `cqrt_copy_i1/i8/i16/i32/i64` (`cq_runtime.h:241-245`); **no `cqrt_copy_f32/_f64` exists** (grep = 0). **The Rule-7 hazard is in-source**: `cqrt_copy` "copies a computational-basis *label*, not a state — WRONG for any phase/superposition carrier (Rule 7)" (`cq_runtime.h:225-227`). `allocFn` `:107-117`, `freeFn` `:257-264` (width-agnostic `void(i32)`). |
| C10 | `abiWidthFromType` is the width gate (PRD:141,284) | `StringRef abiWidthFromType(Type*)` | confirmed | `OpcodeSupport.cpp:148-164`; returns `i1/i8/i16/i32/i64/f32/f64` or **`{}` for half/i128/vector**. **DO NOT gate fp acceptance on non-empty width** — f32/f64 yield a valid string yet `copyFn` returns null (the f64-angle trap). The real fp guard is the null `copyFn`. |
| C11 | Bennett reverse IS `emit_inverse` (PRD:67,154-157,283) | `emitInverseChain` / `emitInverseCall` / `isInverseEmittable` | confirmed | `EmitInverse.cpp:145-158` (chain, walks `ForwardChain` in reverse `:155`, ANDs per-link `:156`), `:61-143` (single), `:37-59` (pure ACCEPT predicate). **The chain does NOT pre-scan — it emits each adjoint as it walks and ANDs the bool (`:155-156`); a `false` on link k leaves links N..k+1 already emitted (a half-reversed chain).** Already driven over a whole forward body stream by `SwapRouteEmit.cpp:377` (whose `false` branch is documented "unreachable" `:379` because the stream was just minted) and `SwitchValueEmit.cpp:252`. **`isCompareTemplate` (`EmitInverse.cpp:33-35`) forces `isInverseEmittable=false` for any `cq_template_icmp_*`/`fcmp_*` — compares have NO `_unc` grid AS OF HEAD. WI-0 (§6.0) ADDS the compare `_unc` grid (the `opcode_table.yaml` uncompute axis) and drops this exclusion, so compare-as-data becomes reversibilizable — a prerequisite that lands BEFORE 6.1.** |
| C12 | DD-4 `ControlOwnedRails` is the suppress-uncompute precedent (PRD:149-151,369-370) | `SmallPtrSet<Value*,8> ControlOwnedRails` | confirmed | Declared `TaintPropagation.h:143` (rationale `:129-142`). **Populated per-individual-rail-`Value*` at each emitter's alloc site** (`SwapRouteEmit.cpp:310,361`; `SwitchValueEmit.cpp:200,240`; `SelectMergeEmit.cpp:136`; `SwitchDataMuxEmit.cpp:144`) — **there is NO "subtract all rails of function F" bulk primitive**. Consumed by `uncompute` at `Uncomputation.cpp:175` (skipped before terminal selection) and defensively `DagTraversal.cpp:107-110` (NotClosed-on-ancestor). **For Phase-6 clones this set is the 6.5 mechanism only; the clone-body double-uncompute is closed by C-Taint, not by this set (DD-2).** |
| C13 | `uncompute` is the whole-DAG LIFO driver, runs last (PRD:59-61,159) | `void uncompute(Module&, WidthDispatch&, TaintSet&)` | confirmed | `Uncomputation.cpp:157-285`, wired LAST in BOTH entry points (`:115`/`:174`). **Module-scoped — iterates `for (Function &F : M)` (`:161`)**; terminal selection gates on **`taint.Tainted.count(H)` (`:173`)** and skips `ControlOwnedRails` (`:175`). A clone body lowered under a disjoint `cloneTaint` has NO handle in the original `taint.Tainted`, so it is never selected as a terminal (C-Taint). `recoverDataDag` (`DagTraversal.cpp:43-141`) is fan-out/QQ-safe; `emitDagReversal` (`:134-153`) adjoints each gate once via a `Seen` set; the per-terminal invertibility pre-scan is `Uncomputation.cpp:219-236`. |
| C14 | `computeFreePoint` returns `{Insert,Measured,Escaped}`; ret → Escaped (PRD:53,159) | `FreePoint computeFreePoint(Value*, Function&, PostDominatorTree&, const TaintSet&)` | confirmed | `FreePoint.h:34-45`, impl `FreePoint.cpp:102-254`. **A ret-consumed handle classifies as `Escaped` (no free — caller owns it)** (`:125-128,184-188`); owns `kMsgPostMeasure`/`kMsgUnrecognized`/`kMsgLoopBackedge` (`FreePoint.h:36-41`). The Bennett `out` handle escapes via the clone's `ret` → `Escaped` → the wrap must NOT rely on FreePoint to free it. |
| C15 | No parameter-seeding path exists (PRD:82,173-177) | (taint root seeding) | **not_found — net-new** | **There is NO existing path to seed taint on a Function `Argument`.** `collectAndSeed` (`TaintPropagation.cpp:76-119`) seeds ONLY `@cq_theta` call results (`:108-111`); the worklist (`:281-308`) propagates only from already-tainted SSA, marking each user `I` at `:305-306`. `propagate` SKIPS declarations (`:270-273`). **A tainted-arg call result is already tainted as a user of the tainted arg at `:305-306`** — this is the caller-side return-taint seed (C-Taint, §2.7). Phase 6 must additionally ADD a per-clone param-root seed into a FRESH `cloneTaint`. The arg-1-angle skip (`:298-303`, keys on `getArgOperand(0)!=V`) already handles a param-used-as-angle correctly. |
| C16 | `scrubTaint` (PRD §2.9 indirect) | `scrubTaint(Instruction*, TaintSet&)` | **corrected** | **`TaintPropagation.cpp` does NOT define `scrubTaint`.** The canonical reusable helper lives at `SwapRouteEmit.cpp:61-75` (and is duplicated per-TU in `RegionFlatten`/`SelectMergeEmit`/`SwitchRouteEmit`/`SwitchValueEmit`/`SwitchDataMuxEmit` — established "house style"). It erases `Tainted`/`BirthOrder`/`StaleDeclined` and `std::remove`s a CI from `PhiCalls`. The one-register-lift's cleanup (`TaintPropagation.cpp:706-708`) does it inline. The 6.5 TU follows the per-TU copy convention. |
| C17 | 6.5 materialization "by the existing Phase-4 routing" (PRD:266-268) | `materialize` | **corrected** | **The ONLY existing "classical operand → rail" materializer is the file-local `static materialize()` in `SelectMergeEmit.cpp:70-78`** (tainted → unchanged; classical → `%h=cqrt_alloc_<Wd>(v)` left UNTAINTED), paired with `ControlledSymbols::copyControlledFn` (`ControlledSymbols.cpp:56-76`, `cqrt_copy_<W>_controlled(ctrl,src,dst)`, integer-only) + the `cqrt_x` ¬flag bracket. **The cswap-route arm emitters (`emitValueRegion`, `SwapRouteEmit.cpp:203`) have NO materialize-classical path.** So 6.5 reuses the **4.4 select-style controlled-copy *mechanics*** (materialize + controlled-copy + bracket + strip), NOT the cswap route — **but uses the value-arm/RegionFlatten Pred-insertion + flatten discipline, NOT the select's no-CFG inline insertion** (DD-7). `SwitchDataMuxEmit.cpp:176` already flags `SelectMergeEmit::materialize` as the canonical reuse target for promotion (Rule 14). |
| C18 | Build is 100% single-TU; no `llvm-link` anywhere (PRD:245-246) | `tests/e2e/run_slice.sh` | confirmed | Single `SRC` positional (`run_slice.sh:10`, args `CLANG OPT PASS INC SRC RT TPL GOLDEN`); 4 stages; repo-wide grep for `llvm-link` = 0. **`-include CQ.h` is hardcoded on the single SRC (`:12`)** — a multi-file harness must NOT apply it to classical libs. **Stage-3 link order puts `$TPL` ($7) BEFORE `$RT` ($6) on the clang line (`:14`)** — load-bearing. `llvm-link` confirmed present at `/usr/local/opt/llvm@19/bin/llvm-link`. |
| C19 | e2e CMake tools from `LLVM_TOOLS_BINARY_DIR` (PRD:251) | `_E2E_CLANG`/`_E2E_OPT` | confirmed | `tests/e2e/CMakeLists.txt:8-9` set both from `${LLVM_TOOLS_BINARY_DIR}`; **there is no `_E2E_LLVM_LINK`** — must be added. `add_test` pattern `:12-18` uses `$<TARGET_FILE:CQPass/cq_runtime/cq_templates>` generator expressions; `check-e2e` DEPENDS those three targets (`:263-267`). **There are 16 `add_test(NAME e2e-slice-*)` entries + 16 `slice_*.c` files** (verified) — Phase 6 ADDS goldens, never regenerates the 16 baselines by reflex (Rule 12). |
| C20 | Suite enforces `gen_templates.py --check` via ctest (PRD:325) | drift gate | **corrected** | **`gen_templates.py --check` is NOT a ctest entry.** The `runtime` ctest filter matches only `runtime_trace_test` + `runtime_header_compile` (`runtime/CMakeLists.txt:31-64`). `--check` is exercised only by the by-hand `tools/gen_templates_test.py` (`:182,190`), which has NO ctest/cmake wiring. **WI-0 adds ONE runtime-ABI extension (the compare `_unc` grid, §6.0); after its `gen_templates.py` regen + acceptance-count update the gate is clean again** (6.2–6.5 add no further ABI). The gate is satisfied by-hand at session-close, **not** by the ctest "Full suite green" (PRD §4 done-criterion is therefore read as "suite green AND `--check` clean by hand"; §9). |
| C21 | `archive/cqc` reuse skeleton; transpiler path forbidden (PRD:254-255) | `pick_bin`/`find_artifact`/arg-parse/`run_stage` | confirmed | `archive/cqc` present (executable, 6896 B). REUSABLE: `pick_bin()` `:52-62`, `find_artifact()` `:88-95`, arg parser `:64-81`, `run_stage()` `:128-131`, `--emit-ll`/`--keep-intermediates`/`--opt=`/`--clang=` flags. **FORBIDDEN — must be DELETED, not commented:** `quantum_transpiler` discovery `:97`, Stage-1 rewriter `:133-135`, `-include cq_mid.h` injection `:137-142` (`qint_mid_t`/`cq_init_si32`). `archive/cqc` has NO `llvm-link` step and NO multi-positional support — net-new. `cq_mid.h` does not exist (only `include/CQ.h`). |
| C22 | The in-module-body decline fixture flips deliberately (PRD:297) | `lowering_reject_taint_escape_inmodule_body.ll` | confirmed | Exists; CHECK `error{{.*}}cq taint escape: tainted value consumed by an unknown callee` (`:35`). Its own header (`:12-15`) states "When Phase 6 lands, the clone-on-taint accept must flip THIS fixture deliberately (regenerate-by-decision, Rule 12) — never by reflex." This is the precise fixture the carve-out inverts. **The sibling declaration-only fixtures `lowering_reject_taint_escape_opaque_call.ll` / `_deep_arg.ll` pin `kMsgUnknownCallee` for `declare`-only callees and MUST stay green** (no-IR keeps declining loudly — see DD-2/no-IR contract). |
| C23 | CMake source list is an explicit list (module conventions) | `add_library(CQPass MODULE …)` | confirmed | `ir-pass/CMakeLists.txt:43-78` enumerates every `src/*.cpp` by hand. **The list is grouped/near-alphabetical, NOT strict ASCII order** (`CQLoweringPass.cpp:53` sits after `ControlledSymbols.cpp:51`/`DagTraversal.cpp:52`). **A forgotten `.cpp` links cleanly as if the module does not exist (silent vanish).** Insert the new files grouped with their siblings, lexically consistent with the existing list (not blind strict-alpha). MODULE lib does NOT link LLVM (`:40-42`); on macOS `LINKER:-undefined,dynamic_lookup` (`:91-93`) → an unexported LLVM symbol fails at **dlopen, not link**. Headers under `ir-pass/include/` need no CMake edit (`:80-82`). |
| C24 | Phase-4 module-size precedent (≤300 LOC soft norm) | (LOC table) | confirmed | Leaf concerns stay 78–300 (`ControlledSymbols` 78, `SelectMergeEmit` 180, `RegionFlatten` 221, `SwitchValueEmit` 300); only detection/classification cores exceed it (`ArmClassify` 1056, `SwapRouteEmit` 836, `TaintPropagation` 783). **≤300 LOC is a soft norm.** Convention: detect/classify modules separate from emit modules, one emitter per content class. |
| C25 | `lowerOps` scoping (PRD:182, "onlyInF-scoped lowering") | `lowerOps(Module&, WidthDispatch&, TaintSet&)` | **corrected** | **`lowerOps` (`OpcodeLowering.cpp:135,194`) iterates `for (Function &F : M)` UNCONDITIONALLY and gates purely on `taint.Tainted.count(&I)` (`:73,:199`) — it NEVER consults `onlyInF` or any per-function list.** "lowerOps onlyInF-scoped" is **mechanically impossible**. The ONLY thing that scopes `lowerOps` to a clone is **which `Value*` are in the `TaintSet` it is handed** (C-Taint). `lowerRotations`/`lowerMeasures` self-scope by the (onlyInF-filtered) intrinsic work lists; `lowerOps` self-scopes by TaintSet membership. The clone is isolated because its handles live only in `cloneTaint` and the original function's tainted ops live only in the original `taint` — so the `:111` main `lowerOps` lowers the original's ops EXACTLY ONCE and `specialize()`'s scoped `lowerOps(M,wd,cloneTaint)` lowers only the clone's. |

---

## 3. Module decomposition

### 3.1 New modules (DD-4 split)

One width-parametric module per concern, `cq` namespace, header under
`ir-pass/include/`. All leaf modules ≤300 LOC; the two concerns that legitimately
concentrate (rejection classification, the Bennett synthesizer) sit at the
boundary. Each `.cpp` is added by hand to `ir-pass/CMakeLists.txt` (grouped with
its siblings, lexically consistent — C23; a forgotten line silently vanishes).

| Path | Responsibility | est LOC | Public API | Deps |
|---|---|---|---|---|
| `include/SpecializePlan.h` | Shared vocabulary (the `ControlPlan.h` analog): `SpecKey{Function* Callee; uint64_t Mask;}` + `DenseMapInfo<SpecKey>`, `SpecCandidate{CallInst* Site; Function* Callee; uint64_t Mask;}`, `SpecRecord{Function* Clone; bool ReturnTainted;}`, `SpecPlan{SmallVector<SpecCandidate,4> Pending; DenseMap<SpecKey,SpecRecord> Cache;}`, mangle/mask helper decls. Header-only; guard `CQ_IRPASS_SPECIALIZE_PLAN_H_`; forward-decl `llvm::Function`/`CallInst`/`Module`, `struct TaintSet`. | 80 | `struct SpecKey/SpecCandidate/SpecRecord/SpecPlan; using SpecMask=uint64_t; std::string mangleSpecName(const Function*, uint64_t); uint64_t taintArgMask(const CallInst*, const TaintSet&); template<> struct llvm::DenseMapInfo<cq::SpecKey>` | (leaf) |
| `src/SpecializeDetect.cpp` (+ `include/SpecializeDetect.h`) | **Pure analysis by SSA identity, no IR mutation (mirrors `ControlDetect`); runs as the pre-`:64`/`:154` pre-pass (C-Plan).** Walk `M` for tainted-arg direct `CallInst` sites, compute the LSB=param0 mask by `taint.Tainted` membership (arg-1-angle-only uses excluded, Rule 3), build a `SpecCandidate`, then run `classifyCandidate` and enter ONLY `Accept` candidates into `SpecPlan.Pending` — **plan membership ⇔ proven-Accept**. Skips intrinsics by **exact-pointer** membership vs `taint.{Theta,Phi,Measure}Calls` (never name-prefix). | 200 | `void detectSpecializations(Module&, const TaintSet&, WidthDispatch&, SpecPlan& out)` | `SpecializePlan.h`, `SpecializeReject.h`, `TaintPropagation.h`, `WidthDispatch.h` |
| `src/SpecializeReject.cpp` (+ `.h`) | The rejection classifier (PRD §2.11 + DD-3 additions) + the `kMsg*` family (own header-side `constexpr` so the negative fixtures mirror char-for-char, Rule 12). Returns `Accept` or a rejecting `Instruction*`+`kMsg`. Rejects loud: non-`CallInst` (invoke/callbr; the `dyn_cast<CallInst>` narrowing), null `getCalledFunction()` (indirect), `isDeclaration()` (no-IR — see DD-2 contract), recursion, fp/i128/vector/half param-or-return (`abiWidthFromType` empty **OR** `copyFn` null — the f64 trap), any `cq_*` in body by exact-pointer `FnSet` membership, any `cq_measure`, any non-reversibilizable construct (inline-asm/volatile/atomic/EH/setjmp-longjmp/vector-SIMD/**syscall**), **and any forward gate failing `isInverseEmittable` (a `_controlled` form or other un-adjointable primitive; post-WI-0 compares PASS this check — they are reversibilizable and NOT a reject, §6.0)**, **and any tainted `br`/`select`/`switch` in the body (in-body control flow — declined for the 6.1–6.4 window pending the open Rule-13 item, §8)**. The single authoritative accept predicate (Rule 14) — consulted by both `detectSpecializations` and the driver. | 230 | `enum class SpecReject{Accept,Recursion,FpAbi,QuantumPrimitive,Measurement,NonReversibilizable,InBodyControl}; SpecReject classifyCandidate(const SpecCandidate&, const TaintSet&, WidthDispatch&, Instruction*& whereOut)` | `SpecializePlan.h`, `TaintPropagation.h` (`diagnoseEscape` idiom, `FnSet`), `EmitInverse.h`, `OpcodeSupport.h`, `WidthDispatch.h` |
| `src/SpecializeClone.cpp` (+ `.h`) | Clone mechanics, lifted **verbatim** from archived `cloneAndMangle` (`CloneFunction`+`ValueToValueMapTy`+`setLinkage(InternalLinkage)`) with two net-new changes: mangle `__cq_q_<callee>_<mask>` (replacing `_q1`) and the `(callee,mask)` cache key (replacing per-`Function*`). `setCalledFunction(clone)` retargets. No taint, no lowering, no wrap. | 120 | `Function* cloneFor(const SpecCandidate&, SpecPlan& cache)` | `SpecializePlan.h`, `llvm/Transforms/Utils/Cloning.h` |
| `src/SpecializeSeed.cpp` (+ `.h`) | The net-new param-root seed (C15). `seedClone` builds a **FRESH `cloneTaint`** (NEVER unioned into the original `taint`, C-Taint): inserts each `clone->getArg(i)` whose mask bit is set into `cloneTaint.Tainted`+worklist (the `collectAndSeed` insert-then-push idiom), then runs the forward worklist **scoped to the clone body** so only the clone's reachable SSA enters `cloneTaint`. Does NOT re-walk the original module (clone-scoped, not module-wide `propagate`). | 120 | `TaintSet seedClone(Function* clone, SpecMask)` | `SpecializePlan.h`, `TaintPropagation.h` |
| `src/BennettWrap.cpp` (+ `.h`) | The thin Bennett synthesizer (Rule 14, no new ABI). Over the clone's **captured-at-mint** forward `CallInst*` stream (forward program order, the `ValueArmStream::Fwd` pattern). **The result rail is the output of the LAST forward call (the `ret` value), so its `_unc` runs FIRST in the reverse with all sources still live (DD-3).** Emit order: (0) pre-scan all with `isInverseEmittable` → loud decline at the offending `!dbg` on first failure, **no emission**; (b) `out=cqrt_alloc_<W>(0)`; (c) `cqrt_copy_<W>(result_rail,out)` (null `copyFn` → fp-ABI decline; Rule-7 copy-out sound iff the body is basis-valued — guaranteed by the `cq_*` rejection, DD-3); (d) `emitInverseChain(B, Fwd, wd)`, **check bool, return `false` BEFORE any free** (unreachable-by-construction after the step-0 pre-scan over the SAME predicate, but defends against a half-reversed chain); (e) `cqrt_free` each `ScratchRails` entry — the exact set whose `_unc` ran — only AFTER the full chain returned true (never interleaved); `out` escapes via `ret` (Escaped — not freed). **Clone rails go into `cloneTaint.ControlOwnedRails` (6.5/defense-in-depth); the clone-body double-uncompute is closed by C-Taint, not this insertion (DD-2).** | 240 | `bool emitBennettWrap(Function& Clone, ArrayRef<CallInst*> ForwardStream, Value* ResultRail, ArrayRef<Value*> ScratchRails, StringRef RetAbiWidth, WidthDispatch&, TaintSet& cloneTaint)` | `EmitInverse.h`, `WidthDispatch.h`, `FreePoint.h`, `TaintPropagation.h` |
| `src/Specialization.cpp` (+ `include/Specialization.h`) | The driver + the single `specialize()` stage (runs at step 14, AFTER detection has populated `SpecPlan`). **Drains** the already-classified `SpecPlan.Pending`; for each Accept candidate: `cloneFor` → `seedClone` (fresh `cloneTaint`) → drive the clone through the scoped lowering substages (`lowerControlRegions`/`lowerRotations`/`lowerMeasures` onlyInF-filtered to the clone; `lowerOps(M,wd,cloneTaint)` self-scopes by `cloneTaint` membership, C25; uncompute SUPPRESSED — never called here) capturing the forward stream → `emitBennettWrap`. **Transitive worklist**: re-scan each freshly lowered clone for inner tainted-arg calls, classify, dedup via `SpecPlan.Cache`. After all clones drain, record `SpecRecord.ReturnTainted` and re-mark the caller's retargeted call result into the ORIGINAL `taint.Tainted` if the clone returns a tainted handle (§2.7, C-Taint). Exposes `shouldSpecialize(const CallInst*, const SpecPlan&)` — the thin pure-membership predicate the `:419` carve-out consults. Does NOT call `uncompute`. | 230 | `void detectSpecializations(...)` (re-exported); `void specialize(Module&, WidthDispatch&, TaintSet&, SpecPlan&); bool shouldSpecialize(const CallInst*, const SpecPlan&)` | all of the above + `CQLoweringPass.h`, `TaintPropagation.h`, `WidthDispatch.h` |
| `src/ClassicalCallArmEmit.cpp` (+ `.h`) — **6.5 only** | Hoist a pure classical call (all-classical-args) out of a swap-route arm into Pred (runs unconditionally, inert because pure); mint flag (`lowerCompareToFlag`); alloc `|0⟩` out rail (into `Tainted`+`ControlOwnedRails`); run the SelectMergeEmit controlled-copy *mechanics* (`materialize(call-result)` + `q`, `copyControlledFn`, ¬flag `cqrt_x` bracket, `icmp_inv` strip, one `cqrt_free`) but **inserting in Pred and capturing block identities before the first erase, then `RegionFlatten` the diamond (value-arm discipline, NOT the select's no-CFG inline path — DD-7)**; RAUW phi→out; scrub+erase. **No clone, no cswap, no reverse-play, no input-tainting.** | 160 | `void emitClassicalCallArmRegion(const ControlRegion&, WidthDispatch&, ControlledSymbols&, TaintSet&)` | shared `materialize`, `ControlledSymbols`, `lowerCompareToFlag`, `WidthDispatch`, `RegionFlatten`, per-TU `scrubTaint` |

### 3.2 Edits to existing files

| File | Surface touched |
|---|---|
| `ir-pass/src/CQLoweringPass.cpp` | **TWO new calls, mirrored in BOTH `run()` and `runOnFunction` (twin-pipeline parity mandatory, C5/C2):** (1) `detectSpecializations(M, taint, wd, plan6)` as a pure-analysis pre-pass **BEFORE** `declineTaintEscapes` (`:64` / `:154`), populating a stack-local `SpecPlan plan6` with proven-Accept sites only; (2) `specialize(M, wd, taint, plan6)` between `declineLiftedStaleRecordOps` (`:106` / `:168`) and `lowerRotations` (`:110` / `:169`), which drains the plan. Add `#include "Specialization.h"`. |
| `ir-pass/include/CQLoweringPass.h` | No member-signature change — `detectSpecializations`/`specialize`/`shouldSpecialize` are free functions in `cq`. |
| `ir-pass/src/TaintPropagation.cpp` | **Carve-out at the `:409→:418` boundary** (decline-by-default, C-Plan): the carve-out is a **pure `SpecPlan` membership test** — `if (cq::shouldSpecialize(CI, plan6)) continue;` — inserted strictly between the `cqrt_/cq_template_/cq_invert_` prefix skip (`:409-411`) and the `readsTaintedValue` decline (`:418`). **It does NOT take or re-derive from `wd`** (none in scope, C6) and does NOT re-classify (classification already happened in `detectSpecializations`). **Signature ripple is real and accepted:** `declineTaintEscapes` must receive the `const SpecPlan& plan6` (it stays `const TaintSet&` — the SpecPlan is the new param), mirrored in both `run()` and `runOnFunction`. A site reaching `:418` that is candidate-shaped but NOT in `plan6` (rejected) STILL fires `kMsgUnknownCallee` at `:419`. **Preserve verbatim** the `IntrinsicCalls`/`IntrinsicInvokes`/prefix skips and the `kMsgStore`/`kMsgOther`/`kMsgNonI32Return` branches. §2.7 return-taint re-seed (caller's call result into the original `taint.Tainted`) is performed by `specialize()` after the clone is lowered, reusing the `out.Tainted.insert(I)` worklist idiom (`:305-306`). |
| `ir-pass/CMakeLists.txt` | Add the 7 (6.1–6.4) + 1 (6.5) new `.cpp` to `add_library(CQPass MODULE …)`, grouped with their siblings and lexically consistent with the existing (non-strict-alpha) list (C23). |
| `ir-pass/test/lowering_reject_taint_escape_inmodule_body.ll` | **Flip decline→accept by-decision** (Rule 12, C22) when 6.1 lands — never silently delete; relocate any still-rejected sub-case to its own negative fixture. |
| `ir-pass/test/lowering_reject_taint_escape_opaque_call.ll` · `_deep_arg.ll` | **MUST stay green** — declaration-only callees keep firing `kMsgUnknownCallee` (DD-2 no-IR contract). Re-run in WI-4.4's carve-out-preservation list. |
| `ir-pass/src/ControlDetect.cpp` · `ArmClassify.cpp` · `include/ControlPlan.h` — **6.5** | New region `Kind` (`ClassicalCallArm`) + classifier (all-classical-args + purity + non-clobber proof by SSA identity, before RegionFlatten mutates); dispatch case in `lowerControlRegions` (`SwapRouteEmit.cpp:~782-832`). |
| `ir-pass/src/SelectMergeEmit.cpp` · `include/SelectMergeEmit.h` — **6.5** | Promote the file-local `static materialize` (`:70-78`) to a shared header (C17) so the select emitter and `ClassicalCallArmEmit` share ONE implementation (Rule 14). **Same edit retires the second known duplication: `SwitchDataMuxEmit.cpp:176` consumes the promoted `materialize` (its in-source recommendation).** Pure code-motion; keep existing select **and** switch-datamux fixtures green. |
| `tests/e2e/CMakeLists.txt` · `tests/e2e/run_slice_multi.sh` (new) · `tools/cqc` (new) | §7. |

---

## 4. Design Decisions

### DD-1 — Pipeline re-entry: a detection pre-pass + a draining `specialize()` stage (PRD §2.6)

- **Question.** A new `specialize()` stage vs. a fixpoint around the existing
  `run()` stages vs. a recursive `runOnFunction`-per-clone? And where does
  detection run relative to the `:64`/`:154` carve-out?
- **Decision.** **Two insertion points, both mirrored in the twin (C-Plan).**
  (1) `detectSpecializations` is a **pure-analysis pre-pass placed BEFORE
  `declineTaintEscapes`** (before `:64` in `run()`, before `:154` in
  `runOnFunction`) — it reads only SSA/pointer identity (valid pre-mutation),
  runs the full `classifyCandidate`, and fills a stack-local `SpecPlan plan6`
  with **proven-Accept candidates only**. The `:419` carve-out then suppresses
  `kMsgUnknownCallee` solely by `shouldSpecialize(CI, plan6)` membership.
  (2) The **draining `specialize()` stage** is placed as **step 14 between
  `declineLiftedStaleRecordOps` (`:106`/`:168`) and `lowerRotations`
  (`:110`/`:169`)**, owning an **internal clone-only worklist** that drives
  lowering OVER CLONE BODIES ONLY by reusing the individual stage functions
  (scoped by the disjoint `cloneTaint`, C-Taint/C25), never the orchestrator. The
  single module-wide `uncompute` at `:115`/`:174` runs ONCE at the end; it never
  sees a clone-internal handle because those live only in `cloneTaint`
  (`Uncomputation.cpp:173` reads the original `taint.Tainted`).
- **Rationale.** Four verified facts force it. (1) `lowerRotations` (`:110`)
  RAUWs every theta to an i32 handle → taint no longer source-recoverable; the
  clone must exist *and be lowered* before `:110` in the same run. The narrowest
  legal slot is `:106→:110` (control already adjudicated `:83-84`, both
  stale-record guards + classical-mux fired `:96/:106`, thetas still un-RAUW'd).
  (2) `uncompute` is module-scoped and gates on the original `taint.Tainted`
  (`:161,:173`, C13) → a whole-run fixpoint or recursive `runOnFunction` would
  invoke `uncompute` multiple times → forbidden; a single end-of-run uncompute
  over disjoint TaintSets is the only safe shape. (3) `propagate` skips
  declarations, seeds only thetas, has no param-root seed (C15); `seedClone`
  builds a fresh clone-scoped `cloneTaint` and never re-walks the original.
  (4) For the carve-out at `:419` to suppress correctly, `plan6` MUST be
  populated before `:64`/`:154` — hence detection is a strictly-earlier pre-pass,
  not part of the step-14 driver (which would leave `plan6` empty at `:64` and
  loud-decline every candidate). A pure-analysis pre-pass invokes neither
  `uncompute` nor the guards, so it does not re-trigger any stage.
- **Affected modules.** `CQLoweringPass.cpp` (both entry points, two slots each),
  `SpecializeDetect.cpp`, `Specialization.cpp`, `SpecializeSeed.cpp`,
  `TaintPropagation.cpp` (carve-out + `SpecPlan` param).
- **Risk.** Twin-pipeline divergence (both pre-pass AND driver must be mirrored —
  WI-1.11 probe (f), WI-1.12 ordering probe); order-of-lowering within the clone
  (each clone must be fully theta-free before `:110` — tested in WI-1.7).

### DD-2 — Preventing double-uncompute: disjoint TaintSets, not `ControlOwnedRails` (PRD §2.5 step 1, §6)

- **Question.** How to stop the Phase-5 per-op `_unc` and the whole-body Bennett
  reverse from double-adjointing the same gates?
- **Decision.** **The disjoint-TaintSet boundary (C-Taint) is the mechanism.**
  The clone is lowered under a fresh `cloneTaint` whose `Value*` are NEVER
  unioned into the original `taint`. The end-of-run `uncompute` at `:115`/`:174`
  selects terminals by `taint.Tainted.count(H)` (`Uncomputation.cpp:173`); a
  clone-internal handle is in `cloneTaint`, NOT the original `taint`, so it is
  **never selected as a terminal** and never adjointed by the module-wide
  uncompute. The ONLY clone-derived value in the original `taint` is the caller's
  retargeted call RESULT (tainted as a user of the tainted arg at `:305-306`),
  which the caller's existing `:115` uncompute legitimately owns. **`cloneTaint`
  is categorically never merged into the original `taint`** (WI-1.8 asserts the
  clone's rails are absent from `taint.Tainted` after `specialize()` returns).
  Inserting clone rails into `cloneTaint.ControlOwnedRails` is defense-in-depth
  (and the live mechanism for the 6.5 in-place merge, which DOES share the
  original `taint`); it is **not** what closes the clone-body double-uncompute.
- **Rationale.** `Uncomputation.cpp:173` gates on `taint.Tainted`, and
  `ControlOwnedRails` is only consulted (`:175`) *after* a handle is already a
  `taint.Tainted` member — so for a disjoint clone the `ControlOwnedRails`
  insertion would be redundant if it landed in `cloneTaint`, and load-bearing-
  but-pointed-at-the-wrong-set if a future implementer ever merged `cloneTaint`
  into `taint`. Pinning "never union" makes the safety argument exact and
  removes the hidden miscompile vector (a merged set would make every
  un-registered clone rail a live terminal → double-adjointed → UAF + double-free,
  Rule 8).
- **Affected modules.** `SpecializeSeed.cpp` (builds the disjoint `cloneTaint`),
  `Specialization.cpp` (never merges), `BennettWrap.cpp` (populates
  `cloneTaint.ControlOwnedRails` as defense-in-depth), `Uncomputation.cpp` /
  `DagTraversal.cpp` (consumers, unchanged).
- **Risk.** A future implementer merging `cloneTaint` into `taint` to make the
  call-result terminal visible would re-open the double-uncompute. Mitigation:
  the call-result is *already* tainted via the caller's worklist (`:305-306`) —
  no merge is needed; WI-1.8 asserts non-merge as an invariant.

### DD-3 — The Bennett-wrap emission API and its correctness invariants (PRD §2.5)

- **Question.** Where is the forward stream captured, what is the exact emit
  order, what is the synthesizer signature, can `emit_inverse` restore a borrowed
  input, and what makes the copy-out and the free sound?
- **Decision.** **Capture at re-lowering time** (one `CallInst*` appended per
  minted lowering call, the `SwapRouteEmit.cpp:340` `ValueArmStream::Fwd`
  pattern) into a `SmallVector<CallInst*>` in forward program order — NOT
  post-hoc via `recoverDataDag` (that reintroduces the double-uncompute coupling).
  Signature: `bool emitBennettWrap(Function&, ArrayRef<CallInst*> ForwardStream,
  Value* ResultRail, ArrayRef<Value*> ScratchRails, StringRef RetAbiWidth,
  WidthDispatch&, TaintSet& cloneTaint)` → `true`=wrapped, `false`=loud-declined.
  Emit order and the four load-bearing invariants:
  - **(a) `isInverseEmittable` pre-scan over the whole stream before any
    mutation** (mirrors `Uncomputation.cpp:219-236`): a genuinely un-invertible
    primitive (a `_controlled` form) declines with NO emission and NO
    half-reversed chain (C11). Post-WI-0 a compare is invertible (its `_unc`
    exists, §6.0) and passes the scan — no longer a reject.
  - **(b) `out=cqrt_alloc_<W>(0)`; (c) `cqrt_copy_<W>(result_rail,out)`.** The
    copy MUST precede the reverse (the reverse zeroes `result_rail` in place;
    copy-after-reverse copies `|0⟩` — PRD:161). **Result-rail ordering invariant:
    the result rail is the output of the LAST forward call (it is the return
    value, so it post-dominates the body), therefore `emitInverseChain`'s
    reverse-program-order walk (`EmitInverse.cpp:155`) zeroes it FIRST with all
    its sources still live (SSA dominance, `EmitInverse.cpp:148-150`).** No rail
    is freed while a later-in-reverse gate still reads it.
  - **(c′) Rule-7 copy-out precondition.** `cqrt_copy` copies a computational-
    basis *label*, not a state — WRONG for any phase/superposition carrier
    (`cq_runtime.h:225-227`, Rule 7). The copy-out is valid **iff the clone return
    is basis-valued**, which is GUARANTEED by the §2.3/WI-1.5 `cq_theta`/`cq_phi`
    rejection: a pure-classical body produces no phase. **The `cq_*` body
    rejection is therefore a CORRECTNESS gate for copy-out, not merely a scope
    limit** — any future widening of the accepted body set MUST re-prove the
    return carries no phase before reusing `cqrt_copy` (the P0 0.585→0.500
    dephasing family).
  - **(d) `emitInverseChain` reverse; check bool and RETURN `false` BEFORE
    emitting any free.** The `false` is unreachable-by-construction after the
    step-(a) pre-scan over the SAME predicate (as `SwapRouteEmit.cpp:379`
    documents), so the check is defense-in-depth — but it must abort ahead of
    step (e) so no `ScratchRails` entry is freed off a half-reversed chain
    (Rule 6).
  - **(e) `cqrt_free` each `ScratchRails` entry, ONLY after (d) returned true,
    never interleaved.** `ScratchRails` = **exactly** the set whose `_unc` ran
    (every `cqrt_alloc_<W>` result the forward stream produced, including the
    result rail itself, which (d) zeroed in place). This is sound — and **more
    aggressive than the value-arm precedent** (`SwapRouteEmit.cpp:394-398` frees
    ONLY route-proven-`|0⟩` work rails and leaves intermediate chain rails as an
    "accepted leak ... NEVER freed dirty") — **because a clone body has no
    route/cswap, only data templates whose `_unc` zeroes their own output rail to
    `|0⟩`; there is no dirty intermediate.** `out` escapes via `ret` (Escaped, C14)
    — not in `ScratchRails`, never freed; not a borrowed input. (f) `ret out`.
  - **Borrowed inputs.** `emit_inverse` CANNOT actively restore a borrowed input
    — the PRD's "restores the borrowed input" (PRD:156-157) is
    *preserve-by-not-touching*: the void `_unc` reads source operands and zeroes
    the OUTPUT rail, never writes the input. The wrap is correct for read-only
    borrowed inputs (the only pure-classical shape). Add a **defensive
    precondition** that no captured forward call writes back over a borrowed-input
    handle; decline loudly if violated (Rule 1/13).
- **Rationale.** Each invariant closes one half of a known silent-miscompile
  family: pre-scan ⇒ no half-reversed chain (C11); copy-before-reverse ⇒ no `|0⟩`
  result; result-rail-is-last ⇒ reverse-then-free dominance is safe; Rule-7 gate
  ⇒ no dephased label copy; free-only-after-true-and-only-the-`_unc`'d set ⇒ no
  dirty/double free. `RetAbiWidth` from `abiWidthFromType` on the clone return
  type, gated on the null `copyFn` not on non-empty width (C10).
- **Affected modules.** `BennettWrap.cpp/.h`, reusing
  `EmitInverse`/`WidthDispatch`/`FreePoint` verbatim.
- **Risk.** Forward-stream ordering (append-only at mint, never iterate the
  module); result rail not the last forward call (assert in WI-1.8); fp/i128 return
  (null `copyFn`); free off a half-reversed chain (WI-1.11 probe (b)). (Compare-in-
  body is no longer a risk — WI-0 makes it reversibilizable, §6.0.)

### DD-4 — Module split (PRD §3 "split by concern")

- **Question.** One monolith or N modules?
- **Decision.** 6 `.cpp` + 1 shared header for 6.1–6.4 (§3.1), + 1 `.cpp` for 6.5,
  mirroring the Phase-4 detect-vs-emit split: detect (`SpecializeDetect`),
  reject-classify (`SpecializeReject`), clone-mechanics (`SpecializeClone`),
  param-seed (`SpecializeSeed`), Bennett synthesizer (`BennettWrap`), driver
  (`Specialization`). 6.5 is its own emitter (`ClassicalCallArmEmit`).
- **Rationale.** C24 precedent: leaf concerns stay ≤300; only classification
  cores exceed. Every leaf here is ≤240. Concern boundaries map 1:1 to the DD's
  named pieces; `SpecializeSeed` is its own module because param-root seeding is a
  net-new capability (C15) that must not live in the clone module. Reuse-over-
  reinvention throughout (Rule 14): `SpecializeClone` lifts archived mechanics
  (qint_mid key → mask; `_q1` → `__cq_q_<callee>_<mask>`); `BennettWrap` composes
  existing primitives, mints no ABI; the carve-out splits ONLY the `:418-419`
  branch. `SpecializeReject` is the *single* accept predicate (no parallel
  classifier — Rule 14). If the 6.4 matrix grows past 300 LOC, fold the `kMsg*`
  family into `SpecializePlan.h` to keep the classifier under cap.
- **Affected modules.** As §3.
- **Risk.** A forgotten `.cpp` in the explicit CMake list silently vanishes
  (C23) — add each grouped-with-siblings and rebuild `CQPass`.

### DD-5 — Mask encoding, mangling, and `(callee,mask)` cache key (PRD §2.2/§2.8/§2.9)

- **Question.** Bit order, mangle format, key representation, where the
  return-taint bit lives.
- **Decision.** Mask = **`uint64_t`, bit `i` = arg `i` tainted, LSB=param0**
  (PRD §2.2, computed by `taint.Tainted` membership at detection, pre-RAUW).
  Mangle = `__cq_q_<callee>_<binary>` where `<binary>` is **zero-padded MSB-first
  to `callee->arg_size()`, param0 the RIGHTMOST char** (so `ipow(tainted,classical)`
  → `01` → `__cq_q_ipow_01`, matching PRD's example). Cache key = a typed
  `SpecKey{Function* Callee; uint64_t Mask;}` via a custom
  `DenseMapInfo<SpecKey>` composing the stock `Function*`+`uint64_t` infos —
  **NOT** the prototype's `Function*`-only key (C7, which silently collapses
  distinct signatures). Return-taint is **NOT in the key** (unknown until the
  clone is lowered) — recorded as `SpecRecord.ReturnTainted` post-lowering, read
  by §2.7 to decide whether to insert the retargeted call result into the
  ORIGINAL `taint.Tainted` (C-Taint). **Cap `arg_size()` at 64; arity>64 → loud
  reject** (truncation would alias two signatures — the over-accept class).
  `mask==0` is not a candidate and never reaches the key.
- **Rationale.** Unpadded `to_string` would collide `0b001` and `0b1` both as
  `"1"` (different-arity clones aliased under `llvm-link`). Key-at-detection
  requires the mask be argument-only (stable before cloning) — return taint is
  post-lowering, so it cannot be in the key. `uint64_t` keeps the key trivially
  hashable; arity≤64 makes 64 bits sufficient.
- **Affected modules.** `SpecializePlan.h` (key + mangle + mask), `Specialization.cpp`
  (mask compute, cache, return-taint re-seed via the `out.Tainted.insert(I)`
  worklist idiom `:305-306`).
- **Risk.** Bit-order inversion in the mangle (pin the `_01` example
  char-for-char, WI-2.2); arity>64 truncation (loud reject + fixture, message
  pinned in §6.2); `DenseMapInfo` sentinels must derive from stock `Function*`
  empty/tombstone and `mask==0` is never keyed.

### DD-6 — Multi-file build harness + `cqc` driver (PRD §2.12)

- **Question.** Generalize `run_slice.sh` or sidecar; how is `cqc` built.
- **Decision.** **SIDECAR** `tests/e2e/run_slice_multi.sh` (do NOT touch
  `run_slice.sh` — it is the baseline for the existing e2e golden baselines, C18).
  Contract: `run_slice_multi.sh CLANG OPT LLVMLINK PASS INC CQSRC LIBSRCS RT TPL
  GOLDEN` (`LIBSRCS` = single space-separated string, word-split, may be empty).
  Stages: per-`.c` `clang -O1 -emit-llvm` (**only `CQSRC` gets `-include CQ.h`**;
  classical libs do NOT — the C18 trap) → `$LLVMLINK -S … -o combined.ll` →
  `opt cq-lowering` → `clang combined-lowered.ll $TPL $RT` (**templates before
  runtime**, C18) → run + `diff`. `set -euo pipefail` + mktemp/EXIT trap from
  `run_slice.sh`. CMake: add `set(_E2E_LLVM_LINK ${LLVM_TOOLS_BINARY_DIR}/llvm-link)`
  after `:9`; parallel `add_test` entries calling the sidecar. **Live `tools/cqc`**:
  clean-slate, reuse ONLY `pick_bin`/`find_artifact`/arg-parse/`run_stage` + the
  flag UX from `archive/cqc`; add a `--link=`/`llvm-link` picker + N positionals +
  the `llvm-link` stage; **DELETE** (not comment) the transpiler/`cq_mid.h`/
  `qint_mid_t` path (C21). `cqc` is NOT wired into ctest (the goldens drive the
  sidecar); optional `tools/CMakeLists.txt` only if a `cqc` smoke is wanted.
- **Rationale.** `llvm-link` (not multi-input `clang`) gives the specializer the
  visible, un-inlined callee body; independent per-TU `-O1` compilation means no
  cross-TU inlining before `opt` (the structural satisfaction of the
  opt-before-inlining constraint — Rule 9 / `test_C_libtooling-abd`). Sidecar
  avoids reflex churn of the existing e2e golden baselines (Rule 12).
- **Affected modules.** `run_slice_multi.sh`, `tests/e2e/CMakeLists.txt`,
  `tools/cqc`, the new slice `.c`/`.expected.log`.
- **Risk.** `-include CQ.h` trap (apply to `CQSRC` only); link-order regression
  (templates before runtime); `-O2/-O3` inlining pre-emption (hard-pin `-O1`);
  reviving forbidden surfaces in `cqc` (delete, never comment); ctest re-configure
  needed for new `add_test` entries (lit `.ll` auto-discover; e2e does not).

### DD-7 — 6.5 routing (PRD §2.13)

- **Question.** How does a pure classical call inside a swap-route arm with
  classical inputs lower?
- **Decision.** ACCEPT as a NEW swap-route arm shape lowered by the **4.4
  SELECT-style controlled-copy *mechanics*** (`materialize` +
  `cqrt_copy_<W>_controlled` + ¬flag `cqrt_x` bracket + `icmp_inv` strip),
  **NOT** the cswap route (C17). **Two distinct reuses, kept separate:**
  (1) the controlled-copy *merge mechanics* (`materialize`, `copyControlledFn`,
  `cqrt_x` bracket, `icmp_inv` strip, single `cqrt_free`) are reused verbatim
  from `SelectMergeEmit`; (2) the **insertion point and CFG handling follow the
  VALUE-ARM / `RegionFlatten` precedent — insert in Pred, capture block
  identities BEFORE the first erase (the block-lifetime SIGSEGV class,
  `SwapRouteEmit.cpp:~742` pre-flight), then flatten the diamond — NOT the
  select's inline `IRBuilder<>(Sel)` no-flatten path** (`SelectMergeEmit.cpp:115,160`
  insert before a `SelectInst` with no CFG; the 6.5 region is a real diamond with
  a merge PHI). Detect (pure analysis, before any mutation): an if-diamond/if-else
  merge phi with exactly two incomings — the routed base `q` (tainted,
  straight-through) and a direct-`CallInst` result `c` whose callee is non-null +
  pure + **every argument classical** (none in `taint.Tainted`) + non-empty
  INTEGER result `abiWidthFromType` + `copyControlledFn(W)` non-null + `c` not in
  the condition's lineage (§3c). HOIST the pure call into Pred (runs
  unconditionally, inert because pure); mint flag; alloc `|0⟩` out rail (into
  `Tainted`+`ControlOwnedRails`); run the controlled-copy merge with
  `materialize(c)` and `q` (orientation by `ArmNegated`); RAUW phi→out;
  scrub+erase; flatten. **No clone, no input-tainting** (only the `|0⟩` out rail
  joins `Tainted`); the `cqrt_alloc_<W>(c)` handle is an UNTAINTED basis-valued
  classical copy-source, not a qubit (Rule 6/8 untouched). Any off-pattern →
  `diagnoseUnderControl(Cond, "control flow")`.
- **Interaction with the `:64`/`:154` carve-out.** A 6.5 in-arm call has
  **all-classical args**, so `readsTaintedValue` is **false** at `:418` and
  `declineTaintEscapes` leaves it untouched — **no carve-out / no `SpecPlan`
  membership needed for 6.5** (it is route-merged, never cloned). `ControlDetect`
  / `ArmClassify` owns the all-classical-args + purity + non-clobber proof by SSA
  identity before `RegionFlatten` mutates. (WI-5.2 asserts the call is in no
  `SpecPlan` candidate set and is not declined at `:64`.)
- **Rationale.** The cswap route path routes a *tainted* base and replays binary
  chains (`emitValueRegion`, C17) — a classical call result is not a binary chain,
  so the route cannot ingest it; the controlled-copy merge is built exactly for
  "materialize a classical value into a `|0⟩` rail under a flag" (PRD:266-268
  word-for-word). All-classical-args is why this is NOT clone-on-taint and never
  trips `declineTaintEscapes`. Purity → the unconditional hoist is observationally
  inert. The Pred-insertion + flatten discipline (not the select's inline path) is
  mandatory because the 6.5 region is a real CFG diamond, not a `SelectInst`.
- **Affected modules.** `ControlDetect.cpp`, `ArmClassify.cpp`, `ControlPlan.h`,
  `SwapRouteEmit.cpp` (dispatch), `SelectMergeEmit.cpp/.h` (`materialize`
  promotion, also consumed by `SwitchDataMuxEmit:176`), new
  `ClassicalCallArmEmit.cpp/.h`.
- **Risk.** §3c clobber over-accept (run `diagonalAliasHit`/`condProvenance`);
  impurity over-accept (the pure predicate is load-bearing); fp/i128 result (gate
  on `copyControlledFn(W)` non-null, never `abiWidthFromType` non-empty);
  tainted-argument leak (exact `taint.Tainted` membership); block-lifetime SIGSEGV
  if a 6.5 Pred is another region's merge block (WI-5.8 probe, mirror
  `SwapRouteEmit.cpp:~742`); `materialize` promotion must not change select- or
  switch-datamux-emitter behaviour (regression-guard both fixture families).

---

## 5. Work items by increment

Each WI is red→green: write the lit fixture(s) FIRST (positive `CHECK` + each
negative `RUN: not … | FileCheck` mirroring the `kMsg` char-for-char), watch it
fail, implement minimally. Each increment ends with an e2e golden + a Rule-13
adversarial clearance scoped below. Decline fixtures + probes ride EVERY
increment (PRD:392).

### 6.0 — Compare `_unc` grid (Rule-13: core — Phase-5 uncompute ABI; lands BEFORE 6.1)

**Goal.** Add the void in-place uncompute axis for `icmp`/`fcmp` so a
compare-as-data flag uncomputes by recompute-and-XOR exactly like `add`/`mul`.
The embedded compare `|a,b,c⟩ → |a,b, c ⊕ (a<b)⟩` is a self-inverse permutation;
its `_unc` reads the **live** sources and zeroes the flag rail (the whole-DAG
LIFO reverse already guarantees source liveness, `EmitInverse.cpp:148-150`). The
bare compare is NOT injective — the *embedded* form is what is reversible, and the
adjoint needs the inputs present, identical to every other binary op's `_unc`.
This DELETES the compare-in-body rejection (WI-1.6 becomes an accept) and ALSO
un-blocks compare-as-data uncompute in **Phase 5** generally — a scope expansion
beyond Phase 6, hence its own clearance.
**Touches.** `tools/opcode_table.yaml` (compare uncompute variants), regenerated
`runtime/cq_templates.{h,c}` (Rule 15 — edit the YAML, never the generated
files), `ir-pass/src/EmitInverse.cpp` (drop the `isCompareTemplate` exclusion at
`:54-56,119`), the two existing Phase-5 fixtures
`lowering_uncompute_compare_{icmp,fcmp}.ll`. **No IR-pass logic beyond the
exclusion drop** — the generic `cq_template_..._unc` mint path
(`EmitInverse.cpp:117-137`) handles compares once the symbols exist.

| WI | red→green→clear |
|---|---|
| 0.1 | **flip** `lowering_uncompute_compare_icmp.ll` / `_fcmp.ll` from the current `kMsgUninvertible` decline (`"cq uncompute: dead chain contains an un-invertible primitive"`) to **accept** — CHECK the compare's `cq_template_<cmp>_<W>[_hl|_lh]_unc` adjoint in the reverse (regenerate-by-decision, Rule 12; these two fixtures currently PIN the decline). |
| 0.2 | **green** add the `unc_qq`/`unc_hl`/`unc_lh` variants to `compare_opcodes` in `opcode_table.yaml`; regenerate via `gen_templates.py`; update the acceptance-count assertion; `gen_templates.py --check` clean (the SHA drift gate). The `_unc` body is trace-only (print + zero the flag rail). |
| 0.3 | **green** drop the `!isCompareTemplate(Name)` exclusion (`EmitInverse.cpp:54-56,119`) so `isInverseEmittable` returns true for an uncontrolled compare template and the generic `_unc` path mints `void(out, src…)`. |
| 0.4 | **e2e/lit** none new beyond the flipped Phase-5 fixtures; 6.1's golden exercises a compare-as-data clone body end-to-end once 6.1 lands. |
| 0.5 | **Rule-13 clearance (core — touches the cleared Phase-5 uncompute core + a runtime ABI change).** Independent adversarial review on extracted IR: the compare `_unc` is recompute-and-XOR (zeroes the flag, leaves inputs intact — a permutation, never a phase, so no dephasing); it is emitted ONLY with live sources (whole-DAG LIFO); a measured/escaped flag is NOT uncomputed (FreePoint discipline); no new over-accept in Phase-5 terminal selection (`Uncomputation.cpp:173` unchanged); `fcmp` rides along but fp tainted data is already rejected, so it is exercised only via Phase 5. A green suite alone does NOT clear it. |

WI-0 **gates 6.1**: the Bennett wrap's `isInverseEmittable` pre-scan must accept
compares before a compare-as-data clone body can be wrapped.

### 6.1 — Single-function core (Rule-13: core, deepest — the Bennett wrap)

**Goal.** One visible pure-classical callee, single tainted arg, straight-line
caller: detect (pre-pass) → clone → mangle/seed → re-enter pipeline → **Bennett
wrap** → retarget → return-taint propagation. Multi-file harness + `cqc` + first
linked golden land here.
**Touches.** `SpecializePlan.h`, `SpecializeDetect.cpp`, `SpecializeReject.cpp`
(minimal: no-IR, `cq_*` body, invoke, callbr), `SpecializeClone.cpp`,
`SpecializeSeed.cpp`, `BennettWrap.cpp`, `Specialization.cpp`,
`CQLoweringPass.cpp` (both entry points, both slots), `TaintPropagation.cpp`
(carve-out + `SpecPlan` param), `CMakeLists.txt`, `run_slice_multi.sh`,
`tests/e2e/CMakeLists.txt`, `tools/cqc`.

| WI | red→green→clear |
|---|---|
| 1.1 | **red** `spec_accept_single.ll` (positive): tainted-arg call to a 1-arg pure classical `@helper` → CHECK the retarget to `@__cq_q_helper_1`, the clone's `cqrt_alloc`/`cq_template_*`, and the wrap `cqrt_copy_i32` + adjoint + `cqrt_free`. **green** `SpecializeDetect`(pre-pass)+`SpecializeClone`+`SpecializeSeed`+`Specialization` minimal path. |
| 1.2 | **red** `spec_reject_no_ir.ll`: a declaration-only (`declare`) tainted-arg callee → **MUST fire the EXISTING `error{{.*}}cq taint escape: tainted value consumed by an unknown callee`** (DD-2 no-IR contract: a no-IR callee is NEVER routed to the specializer — it is never in `plan6`, so `:419` fires `kMsgUnknownCallee`; this keeps `lowering_reject_taint_escape_opaque_call.ll`/`_deep_arg.ll` green). **green** `detectSpecializations` enters no `isDeclaration()` callee into the plan (no new `kMsg`, no `SpecReject::NoIR` — folded into "not a candidate"). |
| 1.3 | **red** `spec_reject_invoke.ll`: a tainted-arg `invoke` of a visible body → STILL `error{{.*}}cq taint escape: tainted value consumed by an unknown callee` (the carve-out narrows to `CallInst` via `dyn_cast`; invoke is never in `plan6`, C6). **green** `dyn_cast<CallInst>` narrowing in detection. |
| 1.3b | **red** `spec_reject_callbr.ll`: a tainted-arg `callbr` (a `CallBase` that is not a `CallInst`) → STILL `kMsgUnknownCallee` (proves `dyn_cast<CallInst>` excludes `CallBrInst`, like invoke). **green** same narrowing. |
| 1.4 | **red** `spec_reject_indirect.ll`: tainted call through a function pointer (null `getCalledFunction()`) → `kMsgUnknownCallee` (never in `plan6`). **green** non-null callee check before any body inspection (null-deref guard). |
| 1.5 | **red** `spec_reject_cq_primitive.ll`: callee body contains `@cq_phi_*` → `error{{.*}}cq specialization: callee contains a quantum primitive (cq_*); only classical functions are lifted`. **green** `SpecializeReject::QuantumPrimitive` by exact `FnSet` membership (this is ALSO the Rule-7 copy-out correctness gate, DD-3 (c′) — a body with `cq_*` could carry phase). |
| 1.6 | **green** `spec_accept_compare_body.ll`: a callee body that combines comparison results AS DATA (e.g. `return (a > 5) + (a > 10);`, tainted `a`) → CHECK the clone lowers the `cq_template_icmp_*` forward calls AND the Bennett reverse emits their `cq_template_icmp_*_unc` adjoints (DEPENDS on WI-0's compare `_unc` grid, §6.0). Proves compare-as-data is reversibilizable, not rejected. **(Was a loud reject in the pre-WI-0 plan; the `_unc` grid lifts it. A compare driving CONTROL FLOW is a separate path — consumed by `detectControlRegions`/swap-route before `lowerOps`, never a `cq_template_icmp` data op; see the open Rule-13 item in §8.)** |
| 1.6b | **red** `spec_reject_inbody_control.ll`: a pure-classical callee whose tainted parameter reaches a `br`/`select`/`switch` in the body → `error{{.*}}cq specialization: callee contains tainted control flow under quantum lift`. **green** `classifyCandidate` declines a candidate whose tainted lineage reaches in-body control (the open Rule-13 item §8 — straight-line value bodies only for 6.1–6.4). |
| 1.7 | **green** the clone-lowers-its-own-rotations-internally invariant: assert no un-RAUW'd theta remains in the clone when control returns to `:110` (DD-1 risk). Fixture inspects the post-`specialize` IR. |
| 1.8 | **green** `spec_single_adjoint.ll`: assert (a) **exactly one** adjoint per clone gate (DD-2/DD-3) — CHECK-COUNT the `_unc`/negated-angle emissions equals the forward gate count; (b) the clone's rails are **absent from the original `taint.Tainted`** after `specialize()` (C-Taint non-merge invariant) and never selected by the `:115` whole-DAG terminal walk; (c) the result rail is the LAST forward call and every `ScratchRails` free follows the COMPLETE reverse chain (DD-3 ordering). |
| 1.9 | **green** `spec_result_propagates.ll` (return-value taint, §2.7, PRD Done): caller consumes the retargeted call result in a FURTHER tainted op (`%r = call @__cq_q_helper_1(...); %s = add %r, %q2`) → CHECK `%s` lowers to a `cq_template_*` (proving `specialize()` re-marked the result into the ORIGINAL `taint.Tainted`). Paired edge fixture `spec_result_classical.ll`: a clone whose return derives from a CLASSICAL param only (`ReturnTainted=false`) → CHECK the call result is NOT tainted and the caller op stays classical. **green** the post-drain `SpecRecord.ReturnTainted` re-seed (`out.Tainted.insert(I)` worklist idiom). |
| 1.10 | **flip** `lowering_reject_taint_escape_inmodule_body.ll` decline→accept by-decision (C22, Rule 12). |
| 1.11 | **e2e golden** `e2e-slice-specialize-2file`: `specialize_caller.c` (tainted-arg call into) + `specialize_lib.c` (pure i32 body), through `run_slice_multi.sh` (llvm-link → opt → link), byte-diff `specialize_caller.expected.log`. The only layer that link-proves `__cq_q_helper_1` + `cqrt_copy_i32` resolve and signature-match. |
| 1.12 | **green** ordering/twin-parity probe: a fixture proving (a) a candidate detected by the pre-pass is suppressed at `:64` (no `kMsgUnknownCallee`) yet a rejected candidate at the same seam still fires it; (b) the pass behaves identically through `run()` and `runOnFunction` (both pre-pass AND driver mirrored). |
| 1.13 | **Rule-13 clearance.** Independent adversarial reviewer over the *extracted lowered IR* (no sims): actively try to break — (a) borrowed input NOT preserved (a forward call writes back over a borrowed-input handle); (b) scratch rail freed off a half-reversed chain / a non-`|0⟩` rail; (c) result dephased (copy AFTER reverse, or a `cq_*`/non-basis return slipping past WI-1.5 — the Rule-7 copy-out gate); (d) double-uncompute (`cloneTaint` merged into `taint`, or a clone rail in `taint.Tainted`); (e) over-accept of a `cq_*`/recursive/fp/invoke/callbr/indirect callee at the carve-out (decline-by-default: every non-`plan6` candidate fires `kMsgUnknownCallee`); (f) twin-pipeline divergence (pre-pass or driver wired in `run()` but not `runOnFunction`). Green suite alone does NOT clear. |

### 6.2 — Signatures, cache, multiplicity (Rule-13: light)

**Goal.** Multi-parameter masks (LSB=param0), `(callee,mask)` cache, multiple
call sites / multiple distinct clones, classical pass-through params.
**Touches.** `SpecializePlan.h` (mask/mangle/key), `Specialization.cpp` (cache).
The wrap is unchanged from 6.1.

| WI | red→green→clear |
|---|---|
| 2.1 | **red** `spec_accept_two_arg_mask.ll`: `ipow(tainted, classical)` → CHECK retarget to `@__cq_q_ipow_01` and the classical param passes through at its original `iN` (DD-5). **green** `taintArgMask`+`mangleSpecName`. |
| 2.2 | **red** `spec_mangle_padding.ll`: a 3-arg arg0-only call → CHECK `@__cq_q_f_001` (NOT `_1`); pin the bit-order char-for-char (DD-5 risk). **green** zero-pad to `arg_size()`, param0 rightmost. |
| 2.3 | **red** `spec_reject_arity_64.ll`: a >64-arg callee → `error{{.*}}cq specialization: callee arity exceeds the 64-parameter specialization mask limit` (DD-5; mask truncation = over-accept). **green** arity cap; message pinned char-for-char here and in §6.2. |
| 2.4 | **green** `spec_cache_two_masks.ll`: two sites `f(t,c)` and `f(c,t)` synthesize `__cq_q_f_01` and `__cq_q_f_10` (distinct, not collapsed — the prototype's coarse-key bug, C7). |
| 2.5 | **green** `spec_cache_hit.ll`: two identical `(callee,mask)` sites share ONE clone (CHECK-COUNT one clone definition, two retargets). |
| 2.6 | **e2e golden** `e2e-slice-specialize-multiarg`: caller with two distinct masks + one repeated site; byte-diff. |
| 2.7 | **Rule-13 (light).** Reviewer confirms the cache key is `(callee,mask)` not `callee`; mangle padding/bit-order matches the fixtures; no wrap change regressed 6.1; return-taint re-seed still fires per-clone. |

### 6.3 — Transitive worklist (Rule-13: medium — inner-vs-own ordering)

**Goal.** A clone whose body calls another pure-classical fn with a tainted
(post-seed) argument specializes the inner call; convergence on the
`(callee,mask)` key space (acyclic subset). **Touches.** `Specialization.cpp`
(re-scan each lowered clone, dedup), `SpecializeReject.cpp` (recursion).

| WI | red→green→clear |
|---|---|
| 3.1 | **red** `spec_reject_recursion.ll`: a self-recursive (or mutually recursive) candidate → `error{{.*}}cq specialization: recursive callee has no static depth bound`. **green** `SpecializeReject::Recursion` (callgraph cycle on the accepted subset). |
| 3.2 | **red** `spec_accept_transitive.ll`: `outer(t)` calls `inner(post_seed_tainted)` → CHECK both `@__cq_q_outer_1` and `@__cq_q_inner_1` synthesize and the inner retarget is INSIDE the outer clone. **green** push inner tainted calls (detected on the inner clone's `cloneTaint`) after the outer clone is lowered, classify, dedup. |
| 3.3 | **green** ordering invariant: the inner specialization completes (clone + wrap, captured under its OWN disjoint `cloneTaint`) BEFORE the outer clone's Bennett wrap captures its forward stream (so the inner retargeted call is in the outer's stream as an ordinary handle op, not a dangling `cq_*`). Fixture asserts the outer wrap's reverse covers the inner call and the two `cloneTaint` sets stay disjoint. |
| 3.4 | **green** convergence: a fixture with a repeated inner `(callee,mask)` across two outer clones synthesizes the inner clone once (cache shared across the drain). |
| 3.5 | **e2e golden** `e2e-slice-specialize-transitive`: 3-file (caller + outer lib + inner lib) byte-diff. |
| 3.6 | **Rule-13 (medium).** Reviewer probes inner-vs-own ordering (inner wrapped before outer captures), double-uncompute across nested wraps (each level's rails in its OWN `cloneTaint`, none in the original `taint`), and worklist termination on the acyclic subset. |

### 6.4 — Rejection-set hardening (Rule-13: core — the over-accept class)

**Goal.** The full decline matrix (PRD §2.11 + the DD-3 fp addition +
syscall/callbr) with pinned messages, per-entry negative fixtures, and an
adversarial over-accept probe family. **Touches.** `SpecializeReject.cpp`
(complete the matrix).

| WI | red→green→clear |
|---|---|
| 4.1 | **red** the remaining rejection-set negatives, each `RUN: not … | FileCheck` mirroring its `kMsg` char-for-char: `spec_reject_measurement.ll` (`cq specialization: callee measures under quantum lift`), `spec_reject_fp_abi.ll` (`cq specialization: floating-point quantum argument or return has no reversible copy`), and the non-reversibilizable family `spec_reject_{asm,volatile,atomic,eh,setjmp,vector,syscall}.ll`. **The non-reversibilizable message embeds the construct kind** so each fixture mirrors char-for-char: `cq specialization: callee contains a non-reversibilizable construct under quantum lift (<kind>)` where `<kind>` ∈ {`inline assembly`,`volatile`,`atomic`,`exception handling`,`setjmp/longjmp`,`vector SIMD`,`syscall`}. **green** complete `classifyCandidate` with the kind-bearing suffix. (No `compare` kind — WI-0 makes compares reversibilizable, §6.0.) |
| 4.2 | **green** `spec_reject_fp_abi_return.ll`: an f64 return — assert it rejects via the **null `copyFn`** path, NOT via `abiWidthFromType` (the f64-angle trap, C10/DD-3 risk). |
| 4.3 | **green** the **over-accept probe family** (the silent-miscompile class): each probe is a tainted-arg call that LOOKS specializable but must decline — invoke-of-visible-body, callbr, indirect-through-tainted-ptr, declaration-only-after-link, recursion-via-mutual-cycle, fp-arg, i128-return, a body whose result feeds a `cq_measure`. Assert each declines loudly (rejected ⇒ absent from `plan6` ⇒ `kMsgUnknownCallee` or its specialization `kMsg`) and `opt` exits non-zero. |
| 4.4 | **green** carve-out preservation: re-run the existing `lowering_reject_taint_escape_{store_global,gep,return_*,indirect_call,opaque_call,deep_arg}.ll` — all stay green (the carve-out touched ONLY the `:418-419` in-module-body branch; declaration-only callees keep `kMsgUnknownCallee`, DD-2). |
| 4.5 | **e2e golden** none required (decline matrix is opt-stage); reuse 6.1's golden as the link regression. |
| 4.6 | **Rule-13 (core).** Reviewer's sole charge is over-accept: enumerate every `CallBase` subclass and operand shape, confirm only `CallInst`+non-null+`!isDeclaration()`+full-matrix-pass enters `plan6`; the default at `:419` stays `kMsgUnknownCallee`. Confirm `readsTaintedValue` (`:348-353`) is unweakened (indirect-call decline depends on the called operand being an operand) and that `shouldSpecialize` is a pure plan-membership lookup (no second classifier — Rule 14). |

### 6.5 — Call under quantum control, classical inputs (Rule-13: medium — reuses swap-route mechanics, no clone)

**Goal.** A pure classical call inside a swap-route arm with classical inputs runs
classically; its i32 result routes into the controlled register via the 4.4
controlled-copy merge mechanics over a flattened diamond (DD-7). No clone.
**Touches.** `ControlDetect.cpp`, `ArmClassify.cpp`, `ControlPlan.h`,
`SelectMergeEmit.cpp/.h` (`materialize` promotion, also consumed by
`SwitchDataMuxEmit`), new `ClassicalCallArmEmit.cpp/.h`, `SwapRouteEmit.cpp`
(dispatch).

| WI | red→green→clear |
|---|---|
| 5.1 | **green** promote `materialize` to a shared header (pure code-motion); wire `SwitchDataMuxEmit:176` onto it too; re-run all existing `select`-merge AND switch-datamux fixtures as the regression guard (no behaviour change). |
| 5.2 | **red** `control_classical_call_arm_accept.ll` (positive): a pure classical call with classical args inside a tainted-condition diamond → CHECK the call hoisted to Pred, the flag mint, two `cqrt_copy_<W>_controlled` (one `cqrt_x`-bracketed), `icmp_inv` strip, one `cqrt_free`, **the merge phi RAUW'd to the out rail and the arm blocks FLATTENED**; CHECK-NOT any clone (`@__cq_q_`) and CHECK-NOT the call arg in `taint`; assert the call is in no `SpecPlan` candidate set and not declined at `:64` (DD-7). **green** `ClassicalCallArmEmit` (Pred-insertion + RegionFlatten, NOT inline) + the new region Kind + dispatch. |
| 5.3 | **red** `control_classical_call_arm_reject_clobber.ll`: the call result feeds the condition's lineage (§3c) → `error{{.*}}… under quantum control`. **green** `diagonalAliasHit`/`condProvenance` disjointness check. |
| 5.4 | **red** `control_classical_call_arm_reject_impure.ll`: a callee with a side effect → loud decline (the unconditional hoist would not be inert). **green** the pure predicate. |
| 5.5 | **red** `control_classical_call_arm_reject_fp_result.ll`: an fp call result (valid `abiWidthFromType`, null `copyControlledFn`) → loud decline (the f64 trap, DD-7 risk). **green** gate on `copyControlledFn` non-null. |
| 5.6 | **red** `control_classical_call_arm_reject_tainted_arg.ll`: a call argument is tainted → this is clone-on-taint or a decline, NOT 6.5 → loud decline (Rule 3 under-taint). **green** exact `taint.Tainted` membership on every arg. |
| 5.7 | **e2e golden** `e2e-slice-classical-call-under-control`: `classical_call_under_control_caller.c` + `_lib.c` through `run_slice_multi.sh`, byte-diff. |
| 5.8 | **Rule-13 (medium).** Reviewer's probe family: clobber, impure, fp-result, tainted-arg, multi-user (call result also reaches a non-phi in-arm user), both arm polarities (`ArmNegated` true/false), and a **block-lifetime probe** (a 6.5 region whose Pred is another region's merge block — mirror the `SwapRouteEmit.cpp:~742` pre-flight, the dangling-work-list SIGSEGV class). Confirm the `materialize` promotion did not regress the select OR switch-datamux emitter. |

---

## 6. Test & fixture catalog

### 6.1 ir-pass lit fixtures (positive)

| Fixture | Increment | Asserts |
|---|---|---|
| `spec_accept_single.ll` | 6.1 | retarget `@__cq_q_helper_1` + clone lowering + Bennett wrap |
| `spec_single_adjoint.ll` | 6.1 | one adjoint per clone gate; clone rails absent from original `taint.Tainted`; result-rail-last + free-after-reverse (DD-2/DD-3) |
| `spec_result_propagates.ll` | 6.1 | caller op on the retargeted result lowers to `cq_template_*` (§2.7 return-taint) |
| `spec_result_classical.ll` | 6.1 | `ReturnTainted=false` → caller op stays classical |
| `spec_accept_compare_body.ll` | 6.1 | compare-as-data body lowers + Bennett reverse emits `cq_template_icmp_*_unc` (needs WI-0, §6.0) |
| `spec_accept_two_arg_mask.ll` | 6.2 | `@__cq_q_ipow_01`, classical pass-through |
| `spec_mangle_padding.ll` | 6.2 | `@__cq_q_f_001` (zero-pad, bit-order) |
| `spec_cache_two_masks.ll` | 6.2 | distinct clones `_01`/`_10` |
| `spec_cache_hit.ll` | 6.2 | one clone, two retargets |
| `spec_accept_transitive.ll` | 6.3 | nested `@__cq_q_outer_1` / `@__cq_q_inner_1` |
| `control_classical_call_arm_accept.ll` | 6.5 | hoist + controlled-copy merge + phi RAUW + flatten, no clone, no taint of args |

### 6.2 ir-pass lit fixtures (negative — `RUN: not … | %filecheck`, kMsg char-for-char)

| Fixture | Increment | Pinned `error{{.*}}` text |
|---|---|---|
| `lowering_reject_taint_escape_inmodule_body.ll` (**flipped to accept**) | 6.1 | (was `cq taint escape: tainted value consumed by an unknown callee`) |
| `spec_reject_no_ir.ll` | 6.1 | `cq taint escape: tainted value consumed by an unknown callee` (declaration-only is never a candidate — DD-2) |
| `spec_reject_invoke.ll` | 6.1 | `cq taint escape: tainted value consumed by an unknown callee` |
| `spec_reject_callbr.ll` | 6.1 | `cq taint escape: tainted value consumed by an unknown callee` |
| `spec_reject_indirect.ll` | 6.1 | `cq taint escape: tainted value consumed by an unknown callee` |
| `spec_reject_cq_primitive.ll` | 6.1 | `cq specialization: callee contains a quantum primitive (cq_*); only classical functions are lifted` |
| `spec_reject_arity_64.ll` | 6.2 | `cq specialization: callee arity exceeds the 64-parameter specialization mask limit` |
| `spec_reject_recursion.ll` | 6.3 | `cq specialization: recursive callee has no static depth bound` |
| `spec_reject_inbody_control.ll` | 6.1 | `cq specialization: callee contains tainted control flow under quantum lift` (deferred — open Rule-13 item §8) |
| `spec_reject_measurement.ll` | 6.4 | `cq specialization: callee measures under quantum lift` |
| `spec_reject_fp_abi.ll` | 6.4 | `cq specialization: floating-point quantum argument or return has no reversible copy` |
| `spec_reject_fp_abi_return.ll` | 6.4 | `cq specialization: floating-point quantum argument or return has no reversible copy` (via null `copyFn`) |
| `spec_reject_asm.ll` | 6.4 | `cq specialization: callee contains a non-reversibilizable construct under quantum lift (inline assembly)` |
| `spec_reject_volatile.ll` | 6.4 | `… non-reversibilizable construct under quantum lift (volatile)` |
| `spec_reject_atomic.ll` | 6.4 | `… non-reversibilizable construct under quantum lift (atomic)` |
| `spec_reject_eh.ll` | 6.4 | `… non-reversibilizable construct under quantum lift (exception handling)` |
| `spec_reject_setjmp.ll` | 6.4 | `… non-reversibilizable construct under quantum lift (setjmp/longjmp)` |
| `spec_reject_vector.ll` | 6.4 | `… non-reversibilizable construct under quantum lift (vector SIMD)` |
| `spec_reject_syscall.ll` | 6.4 | `… non-reversibilizable construct under quantum lift (syscall)` |
| `spec_overaccept_probe_*.ll` (family) | 6.4 | each declines loudly, `opt` non-zero |
| `control_classical_call_arm_reject_clobber.ll` | 6.5 | `… under quantum control` (`diagnoseUnderControl`) |
| `control_classical_call_arm_reject_impure.ll` | 6.5 | `… under quantum control` |
| `control_classical_call_arm_reject_fp_result.ll` | 6.5 | `… under quantum control` |
| `control_classical_call_arm_reject_tainted_arg.ll` | 6.5 | `… under quantum control` |

All negatives use the bundled `not` wrapper (lit prepends the llvm bin dir to
PATH, `lit.cfg.py:36-44`); the CHECK mirrors the `constexpr kMsg*` char-for-char
after `error{{.*}}`. Define the new `kMsg*` family in `SpecializeReject.h` (or
alongside `TaintPropagation.cpp:327-333`) so code and fixture cannot drift
(Rule 12). The non-reversibilizable message embeds the construct kind (the `(<kind>)`
suffix) so each fixture distinguishes asm/atomic/volatile/EH/setjmp/vector/syscall;
the arity-cap and recursion/measure/fp/`cq_*` strings are pinned above.
The carve-out negatives `_invoke`/`_callbr`/`_indirect`/`_no_ir` reuse the EXISTING
`kMsgUnknownCallee` (the carve-out keeps them firing it — they are never in
`plan6`, C6/DD-2).

### 6.3 e2e goldens

| ctest name | Increment | Files | Proves |
|---|---|---|---|
| `e2e-slice-specialize-2file` | 6.1 | `specialize_caller.c` + `specialize_lib.c` + `.expected.log` | `__cq_q_helper_1` + `cqrt_copy_i32` + adjoint resolve & signature-match through llvm-link |
| `e2e-slice-specialize-multiarg` | 6.2 | caller + lib (two masks, one repeat) + `.expected.log` | distinct clones + cache hit at link |
| `e2e-slice-specialize-transitive` | 6.3 | caller + outer lib + inner lib + `.expected.log` | nested clones link & trace |
| `e2e-slice-classical-call-under-control` | 6.5 | caller + lib + `.expected.log` | controlled-copy merge of a classical call result links & traces |

(6.4 adds no golden; it reuses 6.1's as the link regression.) The 4 new goldens
ADD to the existing 16 e2e baselines (C19) — the 16 stay byte-identical (never
regenerated by reflex, Rule 12). Existing `frontend-lit`/`runtime` suites stay
green; `gen_templates.py --check` clean after WI-0's compare-`_unc` regen + count update — the one ABI extension this phase (§6.0/C20).

---

## 7. Build-infra plan (DD-6)

### 7.1 Multi-file harness — `tests/e2e/run_slice_multi.sh` (new, sidecar)

Modeled on `run_slice.sh` (idiom only — `set -euo pipefail`, mktemp/EXIT trap).
**Reuse:** the Stage-2/3/4 shape verbatim. **Forbidden:** modifying
`run_slice.sh` in place (C18 baseline). Contract:

```
run_slice_multi.sh CLANG OPT LLVMLINK PASS INC CQSRC LIBSRCS RT TPL GOLDEN
  1a (CQ TU):  $CLANG -I$INC -include CQ.h -O1 -emit-llvm -S $CQSRC -o $TMP/cq.ll
  1b (libs):   for lib in $LIBSRCS: $CLANG -I$INC -O1 -emit-llvm -S $lib -o $TMP/lib_N.ll   # NO -include CQ.h
  2  (link):   $LLVMLINK -S $TMP/cq.ll $TMP/lib_0.ll … -o $TMP/combined.ll
  3  (lower):  $OPT -load-pass-plugin $PASS -passes=cq-lowering -S $TMP/combined.ll -o $TMP/s2.ll
  4  (link):   $CLANG $TMP/s2.ll $TPL $RT -o $TMP/slice                                     # templates BEFORE runtime
  5  (diff):   $TMP/slice | diff -u - $GOLDEN
```

Empty `LIBSRCS` must still produce a valid `llvm-link` (just `cq.ll`) — pin a
zero-lib path as a fixture. `-O1` on every per-TU clang (never `-O0/-O2/-O3`).

### 7.2 CMake/ctest wiring — `tests/e2e/CMakeLists.txt`

- After `:9`: `set(_E2E_LLVM_LINK "${LLVM_TOOLS_BINARY_DIR}/llvm-link")` (mirrors
  `_E2E_CLANG/_E2E_OPT`, C19; resolves to `/usr/local/opt/llvm@19/bin/llvm-link`).
- Parallel `add_test(NAME e2e-slice-<name> COMMAND bash run_slice_multi.sh …)`
  passing `_E2E_CLANG _E2E_OPT _E2E_LLVM_LINK $<TARGET_FILE:CQPass>
  ${CMAKE_SOURCE_DIR}/include <caller>.c "<lib0>.c [<lib1>.c …]"
  $<TARGET_FILE:cq_runtime> $<TARGET_FILE:cq_templates> <name>.expected.log`.
  Keep the `$<TARGET_FILE:…>` generator expressions (track just-built artifacts);
  `llvm-link` is an external tool, no new build-target dep on `check-e2e`
  (`:263-267` unchanged). **New `add_test` entries require a `cmake` re-configure**
  (e2e does not auto-discover; lit `.ll` does, C20-context).

### 7.3 Live `tools/cqc` (new, clean-slate)

**Reuse from `archive/cqc` verbatim:** `pick_bin` (`:52-62`, add an `llvm-link`
picker the same way), `find_artifact` (`:88-95`) for `libCQPass.so`/
`libcq_runtime.a`/`libcq_templates.a` + `include/`, the arg-parse while-loop
(`:64-81`), `run_stage` (`:128-131`), `--keep-intermediates`/`--emit-ll`/
`--cq-prefix=`/`--opt=`/`--clang=`. **Net-new:** N input positionals (first =
CQ-using, gets `-include CQ.h`; rest do not), a `--link=`/`pick_bin llvm-link-19
llvm-link`, the `llvm-link` stage, templates-before-runtime final link.
**DELETE entirely (C21, Key Prohibitions):** `quantum_transpiler` discovery
(`:97`), Stage-1 rewriter (`:133-135`), `-include cq_mid.h` injection (`:137-142`).
`cqc` is NOT ctest-wired (goldens drive the sidecar); add `tools/CMakeLists.txt`
only if a `cqc` smoke is later wanted. `cqc` runs `opt cq-lowering` on the freshly
`llvm-link`ed module with NO inlining pass before it; never emits `-O2/-O3`.

---

## 8. Risk → mitigation

| PRD §6 risk | Closing WI / fixture |
|---|---|
| Verify-clean Bennett miscompile (input un-preserved / scratch dirty / result dephased) | DD-3 copy-before-reverse order + result-rail-is-last + free-after-complete-reverse + Rule-7 copy-out gate + read-only-input precondition; WI-1.8 ordering asserts; WI-1.13 clearance probes (a)(b)(c); the wrap reuses already-cleared `emit_inverse`. |
| Double-uncompute (per-op `_unc` + whole-body reverse) | **DD-2 disjoint-TaintSet boundary (C-Taint), NOT `ControlOwnedRails`** — `cloneTaint` never unioned into `taint`; `spec_single_adjoint.ll` (WI-1.8) asserts one adjoint per gate AND clone rails absent from `taint.Tainted`; WI-1.13 probe (d); WI-3.6 nested-wrap check (each level its own `cloneTaint`). |
| Over-accept at the carve-out (invoke/callbr/indirect/`cq_*`/recursive/fp slips in) | **Decline-by-default C-Plan**: detection enters only proven-Accept sites into `plan6`; the `:419` carve-out suppresses by membership only; every rejected candidate STILL fires `kMsgUnknownCallee`. WI-1.3/1.3b/1.4/1.5 negatives; WI-1.12 ordering probe; WI-4.3 over-accept probe family; WI-4.6 clearance (enumerate every `CallBase` shape; confirm `shouldSpecialize` is pure membership, Rule 14). |
| Pipeline re-entrancy state (stale TaintSet / clone after rotation lowering) | DD-1 step-14 placement (pre-RAUW) + pre-`:64`/`:154` detection pre-pass; `SpecializeSeed` returns a FRESH clone-scoped `cloneTaint` (C15/C-Taint); WI-1.7 clone-theta-free-before-`:110` invariant; WI-1.12/1.13 probe (f) twin-pipeline. |
| Build-flow inlining pre-emption | DD-6 per-TU `-O1` + `llvm-link`-before-`opt` (structural); `cqc` never `-O2/-O3`, never an inline pass before `opt`; the 6.1 golden exercises the real multi-file path. |
| `cqc` driver scope creep (reviving forbidden surfaces) | DD-6: reuse only `pick_bin`/`find_artifact`/arg-parse/`run_stage`; DELETE the transpiler/`cq_mid.h`/`qint_mid_t` path (C21). |

Additional risks surfaced by the map (not in PRD §6 but load-bearing):
**mangle collision from unpadded mask** (DD-5; WI-2.2);
**arity>64 truncation** (DD-5; WI-2.3); **fp false-accept via non-empty width**
(C10/DD-3; WI-4.2, WI-5.5); **§3c clobber / impurity in 6.5** (DD-7; WI-5.3/5.4);
**block-lifetime SIGSEGV in 6.5** (DD-7; WI-5.8 probe).

**Const-fold re-anchor class — cleared by construction (not a gap).** The named
verify-clean-invisible blocker (`clang -O1` folds an arm gate to
`cq_phi(i32 const, theta)`, arg0=literal, RAUW'd to a constant) **CANNOT arise in
an accepted Phase-6 clone body or 6.5 arm**: the trap requires a folded
`cq_phi`/`cq_theta` gate, but the clone-body `cq_*` rejection (WI-1.5, exact-FnSet
membership) declines any body containing a rotation — folded or not — so no
rotation gate survives into a clone, and the 6.5 arm is a *classical* call, not a
rotation. Data-template const-folding (e.g. `add` of two constants) folds to a
plain `ConstantInt` with no taint and is simply never enqueued by `lowerOps`
(gated on `taint.Tainted`), so it produces no dangling `_unc`. Tracked here
explicitly rather than left as an untracked omission of the project's defining
hazard.

**Open Rule-13 item — in-body control flow × the Bennett reverse (NOT closed by
this plan).** WI-0 lifts compare-AS-DATA, and a compare-AS-CONTROL is consumed by
`detectControlRegions`/swap-route before `lowerOps` (never a `cq_template_icmp`
data op). But a clone body that contains tainted **control flow** then routes
through the Phase-4 swap-route emitter (DD-1 drives the clone through
`lowerControlRegions`), whose region emission does its OWN internal rail cleanup
(the uncontrolled `icmp_inv` flag-strip returns its rails to `|0⟩` *within* the
region). The Bennett whole-body reverse must therefore reverse ONLY the data
gates and NOT re-adjoint swap-route's already-balanced control machinery — the
boundary between the captured forward DATA stream and the region-internal
balanced CONTROL gates is a genuine correctness hazard this plan does **not**
prove. **Scope decision (Prime Directive):** 6.1's accepted body set is
**straight-line value functions (no in-body tainted control flow)**, where this
cannot arise. `SpecializeDetect`/`classifyCandidate` must **loudly decline** a
clone candidate whose tainted lineage reaches a `br`/`select`/`switch` in the
body (a new reject reason, e.g. `… contains tainted control flow under quantum
lift`), until in-body control × Bennett composition lands as its own
red→green→clear WI with independent Rule-13 clearance. This tightens DD-1's
"drive the clone through `lowerControlRegions`" to "for straight-line bodies
only" for the 6.1–6.4 window.

---

## 9. Dependency-ordered sequencing

Strict landing order; each WI gates the next. A WI is "landed" only when its lit
fixtures are green AND (per increment) the e2e golden diffs clean AND the
Rule-13 clearance for that increment is recorded.

1. **WI-0 — compare `_unc` grid** (§6.0) — extend `opcode_table.yaml` with the
   compare uncompute axis, regenerate, drop the `EmitInverse` `isCompareTemplate`
   exclusion, flip the two Phase-5 compare-uncompute fixtures. A core + ABI change
   with its own Rule-13 clearance (it touches the already-cleared Phase-5
   uncompute core). *Gates 6.1 — the Bennett wrap's `isInverseEmittable` pre-scan
   must accept compares before a compare-as-data body can be wrapped.*
2. **SpecializePlan.h** — the shared vocabulary (`SpecKey`/`DenseMapInfo`/mask/
   mangle). Nothing compiles against the concern without it. *Gates everything.*
3. **DD-6 build harness** (`run_slice_multi.sh` + `_E2E_LLVM_LINK` + `tools/cqc`)
   — independent of the pass; land early so 6.1's golden has a path to run.
   *Gates every e2e golden.*
4. **WI-1.1–1.6, 1.12** — `SpecializeReject` → `SpecializeDetect` (the pre-pass)
   → `SpecializeClone` → `SpecializeSeed` → `BennettWrap` → `Specialization`
   driver, with the carve-out. **Both insertion points land in the same commit
   in BOTH entry points** (the pre-`:64`/`:154` `detectSpecializations` AND the
   step-14 `specialize()`), with the `SpecPlan` threaded into `declineTaintEscapes`
   — twin-pipeline parity is mandatory and the accept/decline boundary is never
   half-wired (WI-1.12 pins the ordering). Reject-classify lands first because
   detection enters only proven-Accept sites. *Gates 6.2–6.5.*
5. **WI-1.7, 1.8, 1.9** — the correctness invariants (clone-theta-free,
   single-adjoint + non-merge + ordering, return-value-taint propagation). Must
   pass before the golden is trusted. *Gates WI-1.11.*
6. **WI-1.10** — flip `lowering_reject_taint_escape_inmodule_body.ll`
   (by-decision). Lands WITH the carve-out (same commit as step 4) so the
   accept/decline boundary is never half-flipped. *Gates the full ir-pass-lit re-run.*
7. **WI-1.11 + 1.13** — the 6.1 golden and the deepest Rule-13 clearance. **No
   later increment lands until 6.1 is cleared** (the Bennett wrap is the core all
   else reuses).
8. **WI-2.1–2.7** — mask/cache/multiplicity. Depends on the cleared 6.1 wrap
   (unchanged here). *Gates 6.3.*
9. **WI-3.1–3.6** — transitive worklist. Depends on the `(callee,mask)` cache
   (6.2) and the cleared wrap (6.1); the nested-wrap double-uncompute check (3.3,
   3.6) depends on DD-2 (disjoint TaintSets) being proven at 6.1. *Must precede
   6.4's over-accept matrix if recursion fixtures share the classifier.*
10. **WI-4.1–4.6** — rejection-set hardening + the over-accept clearance. Completes
   `SpecializeReject`; depends on every accept path existing (so the negatives are
   genuine declines, not unimplemented-path failures). Independent of 6.5.
11. **WI-5.1–5.8** — 6.5. `materialize` promotion (5.1) FIRST (regression-guard the
    select AND switch-datamux emitters) before the new emitter; depends on the
    cleared swap-route Phase-4 path, NOT on clone-on-taint (orthogonal). Lands last.

**Session-close (CLAUDE.md):** run the full `ctest` suite (the 16 existing + the
new e2e goldens, ir-pass-lit, frontend-lit, runtime) + `gen_templates.py --check`
by hand. **Done-criteria-coverage note:** the PRD's `gen_templates.py --check`
done-criterion is satisfied by-hand (C20 — it is NOT a ctest entry), is trivially
clean after WI-0's compare-`_unc` regen + acceptance-count update (the one ABI extension this phase, §6.0), and is NOT part of the ctest "Full suite green";
read the PRD §4 wording as "suite green AND `--check` clean by hand." Record each
increment's Rule-13 clearance, then `git pull --rebase && git push` on a feature
branch (not `main`).
