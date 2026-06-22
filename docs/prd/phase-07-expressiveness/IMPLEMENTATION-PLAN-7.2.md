# Implementation Plan 7.2 — Controlled function-`return` (reconverging early-exit) (DRAFT)

> **Status:** DRAFT, written at the start of Phase 7.2 (2026-06-22). This is the
> **execution layer** for [`PRD-7.2.md`](PRD-7.2.md) (the decision layer). It does
> **not** restate PRD rationale — it says *which lines change, in what order,
> behind which fixtures*, mirroring the house style of
> [`IMPLEMENTATION-PLAN-7.1.md`](IMPLEMENTATION-PLAN-7.1.md).
>
> **Provenance:** every file:line anchor and every claim flagged "verified" below
> was confirmed against the live tree on 2026-06-22 by a 15-agent grounding
> workflow (8 subsystem maps + 7 adversarial verifications, several running the
> real `clang -O1 | opt cq-lowering` pipeline against `build/ir-pass/libCQPass.so`
> dated 21 Jun). Where the workflow **contradicted** the PRD, the correction is in
> §2 (READ FIRST). 7.2 is a **core control change** (Rule 13): a green suite does
> **not** clear it.

---

## 0. Cross-cutting conventions

### 0.1 The per-increment loop (RED → IMPL → VERIFY → CLEAR)

Every increment follows the same cadence. **Note the absent step:** 7.2 reuses the
shipped emitters and mints **no new frozen ABI symbol** (verified — see §0.5), so
7.1's `REGEN` (edit-the-YAML / `gen_templates.py --check`) substep **collapses to
nothing**. The one contingency is the §2.8 abort-truncate symbol (§8 owner flag).

1. **RED** — write the failing fixture first (Rule 12). For an accept: the positive
   `.ll` (captured from **real** `clang -O1`, see §2-D) that currently declines or
   mis-lowers. For a decline: the mirror-exact `RUN: not … | FileCheck`.
2. **IMPL** — minimal change at the cited anchor; pure SSA analysis **before any
   mutation** in detection (Rule 9).
3. **VERIFY** — `ctest -R ir-pass-lit` green + the two-RUN verify guard on every new
   positive fixture + ≥1 e2e golden (Rule 16). Capture goldens from **real linked
   output**, never by hand.
4. **CLEAR** — independent adversarial Rule-13 review reading the **lowered IR**
   (analytic/trace reasoning, no simulation). Required for the detection widening,
   the arm-by-arm dispatcher, and the abort park **before commit**.

### 0.2 Fixture skeletons (copy these)

**Negative / decline** (one per §2.10 disposition row; mirror the `What`
character-for-character):
```llvm
; <name>.ll — <disposition>, PRD §2.10/§2.11(C).
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}<exact What substring> under quantum control
; CHECK-NOT: cqrt_cswap        ; nothing lowered
declare i32 @cq_theta_si32(i32, double)
... define with the surviving ret/unreachable/musttail shape ...
```
The emitted message is fixed by `diagnoseUnderControl` (`ControlDetect.cpp:47`):
`cq controlled lowering: <What> under quantum control`. The `error` token is
`opt`'s `DS_Error` rendering, not part of the message.

**Positive ir-pass** (always **two** RUN lines — the second is the cross-type
`iN→i32` RAUW verify guard, necessary-not-sufficient per Rule 2):
```llvm
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK: %[[CAP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_<...>(
; CHECK: ... ORDERED sequence ...
; CHECK-NOT: phi i32
; CHECK-NOT: br i1
```

**Ordered + independent COUNT scan** (for the abort graveyard cswap count / both-arm
I/O bracket span — a mis-bracket is **verify-clean-invisible**, identical symbol
multiset, wrong basis branch; only an ordered CHECK catches it):
```llvm
; RUN: %cq-opt ... | %filecheck %s --check-prefix=CNT
; CNT-COUNT-N: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
```

**Controlled tape write** (both-arm I/O §2.5 + abort flag record §2.8 — copy from
`lowering_io_controlled_printf_ne.ll`, pins the `¬flag` `cqrt_x` bracket **span** by
order):
```llvm
; CHECK: %[[TAPE:.+]] = call i32 @cqrt_tape_alloc()
; CHECK: %[[FLAG:.+]] = call i32 @cq_template_icmp_<pred>_i32_hl(i32 %[[H]], i32 K)
; CHECK: call void @cqrt_x(i32 %[[FLAG]])                       ; negated polarity ONLY
; CHECK: call i32 @cqrt_tape_write_i32_controlled(i32 %[[FLAG]], i32 %[[TAPE]], i32 %[[H]])
; CHECK: call void @cqrt_x(i32 %[[FLAG]])
; CHECK: call i32 @cq_template_icmp_<pred>_i32_hl_inv(i32 %[[H]], i32 K)
; CHECK: call void @cqrt_free(i32 %[[FLAG]])
; CHECK-NOT: call{{.*}}@printf
```

### 0.3 Diagnostic-literal table

All control declines route through the **one** primitive
`diagnoseUnderControl(Instruction*, StringRef What)` (`ControlDetect.cpp:47`) →
`cq controlled lowering: <What> under quantum control`. **Do not add a new
mechanism — pass a new `What`.**

| `What` string | status | site | fixture |
|---|---|---|---|
| `control flow` | EXISTING, ~60 sites (the generic catch-all) | `ControlDetect.cpp:173` (OffPattern) + everywhere | many |
| `arm rewrites a condition operand` | **EXISTING — reuse, NOT new** | `ArmClassify.cpp:930/1038`, `SwitchArmProve.cpp:220` | `control_swap_reject_clobber.ll` |
| `rotation angle` | EXISTING | `ArmClassify.cpp:748/983` | `control_swap_reject_select_angle*.ll` |
| `mixed phase/value arm` | EXISTING | `ArmClassify.cpp:779/837/845/1021` | — |
| `non-reconverging value exit` | **NEW (Inc 4)** | new, at `ControlDetect.cpp:173` partition | new |
| `phase-class value escaping` | **NEW (Inc 4)** | new, at `ControlDetect.cpp:173` partition + ArmClassify | new |
| `loop` | **NEW (Inc 4)** — defer to 7.3/7.4 | new, at `ControlDetect.cpp:173` partition | new |

Pre-`ControlDetect` taint-escape declines (owned by `declineTaintEscapes`,
`TaintPropagation.cpp:442`, run at `CQLoweringPass.cpp:78` — **before** detection;
**7.2 must NOT double-own these**):

| `What`/`kMsg` | string | site |
|---|---|---|
| `kMsgNonI32Return` | `cq taint escape: tainted value returned at non-i32 width` | `TaintPropagation.cpp:335`, fires `:611-615` |
| `kMsgStore` | `cq taint escape: tainted value stored to memory` | `:332`, fires `:650` |
| `kMsgUnknownCallee` | `cq taint escape: tainted value consumed by an unknown callee` | `:330`, fires `:566` |
| `kMsgOther` | `cq taint escape: tainted value reaches an unsupported instruction` | `:333`, fires `:650` |

### 0.4 Build / test

```bash
cmake --build build --target CQPass                          # just the pass
ctest --test-dir build -R ir-pass-lit  --output-on-failure   # all *.ll (GLOB auto-discovered)
ctest --test-dir build -R '^e2e-'      --output-on-failure   # linked goldens (NOT auto-discovered)
cd build && lit -v ir-pass/test --filter '<name>'            # one fixture
# by-hand single .ll (absolute tool path required):
/usr/local/opt/llvm@19/bin/opt -load-pass-plugin build/ir-pass/libCQPass.so \
    -passes=cq-lowering -S ir-pass/test/<name>.ll
```
`.ll` lit fixtures need **no registration** (GLOB at `ir-pass/test/CMakeLists.txt:80`,
single `ir-pass-lit` ctest entry at `:100`). e2e slices need a hand-written
`add_test` block in `tests/e2e/CMakeLists.txt` **and a cmake reconfigure** (NOT
auto-discovered). Link order is load-bearing: `cq_templates` **before** `cq_runtime`.

### 0.5 Baseline anchor facts (verified 2026-06-22)

1. **The catch-all is `ControlDetect.cpp:173`** (the `diagnoseUnderControl(BI,
   "control flow")` call); line **172** is the `case RegionShape::OffPattern:` label.
   PRD §1/§2.10 cite 172 — off by one.
2. **No `PostDominatorTree` in the detection path** (`ControlDetect`/`ArmClassify`/
   `RegionFlatten`/`SelectClassify`/`SwitchClassify`). The §2.11-A accept predicate
   is **purely structural** (`uncondSucc`/`soleMergePhi`). PDT exists only in the
   post-detection uncompute spine (`FreePoint`/`Uncomputation`). **Caveat:** a plain
   `DominatorTree` **is** present in detection at `RegionTreeDetect.cpp:140` (the
   nested-shape backedge guard) — so PRD prose must say "no **PostDominator**Tree",
   not "no dominator analysis".
3. **An `i32` reconverging return is the ONLY return shape that reaches the control
   recognizer.** Non-i32 tainted ret → `kMsgNonI32Return`; tainted store/sret →
   `kMsgStore`; a `q`-consuming impure call arm → `kMsgUnknownCallee` *regardless of
   return shape*; all fire in `declineTaintEscapes` at `CQLoweringPass.cpp:78`,
   strictly before `detectControlRegions` (`:109`). The width guard keys on **operand
   taint, not function return type** — `ret i64 %m` where `%m = cq_measure_…` is an
   **accept** (`lowering_taint_escape_return_measure_i64.ll`); preserve it.
4. **`uncondSucc==null` is the structural fence.** A `ret`/`unreachable`/cond-`br`/
   `switch`-terminated arm yields `uncondSucc==null` (`ControlDetect.cpp:60`), so
   `recoverRegion`'s three accept shapes (Diamond-A `:107`, Diamond-B `:121`, IfElse
   `:134`) all fail → `OffPattern` → decline `:173`. This is why a non-reconverging
   exit **cannot structurally match** the accept path (PRD §6 Risk-2 holds).
5. **`flattenRegion` is terminator-agnostic** (`RegionFlatten.cpp:46`, splice at
   `:73`): a merge ending in `ret` flattens green (verified on
   `control_swap_ifelse_escape.ll`). No change needed for reconverging returns.
6. **No new frozen symbol needed.** `cqrt_tape_write_i1` (`cq_runtime.h:343`,
   `.c:537`), `cqrt_tape_write_i1_controlled` (`:348`), and `cqrt_cswap`
   (`cq_runtime.h:233`, self-adjoint at `EmitInverse.cpp:47-48`) all exist. No
   tape-truncate symbol exists anywhere; "truncate-at-inspection" is a backend
   convention emitting nothing.
7. **Optimizer-cost-fragility (load-bearing for fixtures).** `clang -O1` folds
   *most* early-return diamonds to `select` (already accepted by 4.4) or to branchless
   arithmetic. A surviving `br`-diamond appears only when an arm busts the
   branch-speculation cost budget or carries a non-speculatable side effect. **Every
   Inc-1/Inc-2 positive `.ll` must be captured from real `clang -O1` output and
   re-verified** — a hand-written diamond risks pinning a shape clang no longer emits.

---

## 1. Landing order

```
Inc 1  exp2 br-diamond data-mux detection + emitter        (no ABI)   ─┐
       (shared-base reconverging return = regression-pin, already works)│
Inc 2  mixed-kind arm-by-arm dispatch + both-arm I/O        (no ABI)  ─┤── all four
Inc 3  abort/exit park cascade  (NEW emission; new do-not-uncompute set)│   touch
       (no new ABI unless §2.8 truncate symbol — owner flag §8)         │   handleBranchRegion
Inc 4  decline-diagnostic partition at ControlDetect.cpp:173 (no ABI) ─┘   / OffPattern
```
Increments may interleave at the fixture level, **but the detection widening (Inc 1),
the arm-by-arm dispatcher (Inc 2), and the abort park (Inc 3) each clear independent
Rule-13 review before commit.** Inc 3's abort recognizer and Inc 4's partition both
edit the `OffPattern` path in `handleBranchRegion` — coordinate (Inc 3 inserts a
recognizer **before** the `OffPattern` fall-through; Inc 4 partitions the residual
declines). **No freeze gating** (control work adds no frozen symbols) except the §2.8
contingency.

---

## 2. Adversarial-review resolutions (READ FIRST — these change the build)

> The grounding workflow **changed the build** vs. the PRD's stated approach in the
> following ways. Read these before touching code.

**(A) BLOCKER — the abort graveyard needs a NEW do-not-uncompute set, subtracted at
TWO sites.** PRD §2.8 says the parked registers are "kept like an output rail, never
freed." But `OutputRails` is semantically tape entries and `ControlOwnedRails` is
Phase-4 routing rails — neither fits, and a parked **entangled** rail that the
uncompute spine reverse-plays or frees is a **hidden collapse** (Rule 6). The spine
subtracts its do-not-touch sets at **both** `Uncomputation.cpp:175-181` (terminal
selection) **and** `DagTraversal.cpp:107-119` (closure scan). **Inc 3 must add a
third sibling set (recommend `taint.GraveyardRails`) and subtract it at BOTH sites**
— missing the closure-scan site means a graveyard rail reached as a DAG ancestor is
still reversed/freed (the `TaintPropagation.h:150-155` "do not rely on incidental
closure-scan skip" discipline). Additionally, the park `cqrt_cswap`s must be
**self-bracketed** (`emitRoute` pattern) and **never** threaded through
`emitInverseChain` — `cqrt_cswap` arg-0 is the **flag slot** and the inverter threads
a handle there → verify-clean wrong unitary (`EmitInverse.cpp:99-116`,
`SwapRouteEmit.cpp:370-374`).

**(B) MAJOR — the common reconverging return is ALREADY handled; Inc 1's new code is
ONLY the exp2 gap.** At `-O1`, a *shared-base* early return (`if(q>5){p=op(p);}
return p;`) reconverges to a value Diamond/IfElse that `recoverRegion` **already**
accepts → `classifyArms` tags it `Value` → `emitRegion` forks to `emitValueRegion`
(`SwapRouteEmit.cpp:496-499`). This is the **same shape** already pinned by
`control_swap_value_ifelse.ll` / `control_swap_ifelse_escape.ll`. So the shared-base
reconverging return is a **regression-pin + e2e** (confirm-it-works), **not new
code**. The genuinely-new Inc-1 work is the narrow **exp2 gap**: a `br`-diamond whose
`soleMergePhi` has **two independent computed value arms, no shared base**, which
`classifyArms` declines today (`control_swap_reject_value_ifelse_two_bases.ll` is the
likely current-decline representative).

**(C) MAJOR — the data-mux emitter keys on a LITERAL `SelectInst`/`SwitchInst`, NOT a
generic merge-φ.** `classifySelectRegion` takes `SelectInst*` and reads
`getTrueValue()/getFalseValue()` (`SelectClassify.cpp:252`); `emitSwitchDataMuxRegion`
re-casts `R.Pred->getTerminator()` to `SwitchInst` and computes a **compile-time XOR
delta** that **requires `ConstantInt`** incomings (`SwitchArmProve.cpp:310-318`). So
the exp2 `br`-diamond merge-φ with two **computed** arms reaches **neither** emitter
today — it declines (does not miscompile). Inc 1 needs (1) a **new classifier** on the
recovered `BranchRegion`'s `soleMergePhi`, and (2) a **new br-diamond data-mux
emitter** built on the `emitSelectRegion` template (mint flag → alloc `|0>` out-rail →
controlled-copy TRUE-incoming on flag → `cqrt_x`-bracketed controlled-copy
FALSE-incoming on `¬flag` → `icmp_inv` strip → one `cqrt_free` → RAUW φ→out) **PLUS**
two things `emitSelectRegion` lacks because a `select` has no CFG: **`flattenRegion`**
and **hoisting the computed arm values into `Pred` before flatten** (else the copy
sources dangle into an erased arm block — the merge-block use-after-free family).
`materializeCopySource` (`SelectMergeEmit.cpp:66`) already passes a computed tainted
`i32` handle through as identity — that one piece needs **no** change.

**(D) MAJOR — fixtures must be captured from real `clang -O1`, never hand-written.**
The PRD's headline example `if(q>5) return q+1; return 3*q+7;` **folds to `select`**
and is **already accepted** by 4.4 (verified, `opt` exit 0). The surviving exp2
`br`-diamond is the rare pure-arithmetic (add/mul/xor/shl) chain long enough to bust
the speculation budget. The canonical both-arm I/O example
`if(q)printf("%d",q);else printf("%x",q);` **folds to one `printf` with a tainted
ptr-`select` format** (declines via `classifySelectRegion` over ptr data) — so Inc-2
I/O fixtures need non-foldable distinct sinks. **Capture from real `-O1`, re-verify.**

**(E) MAJOR — §2.5 single-arm I/O is enforced at TWO layers.** Not just
`ArmIsSoleSink` (`IOSinkLowering.cpp:416`) but **first** the diamond recognizer
(`:347-358`) that requires one successor to be the straight-through merge
(`uncondSucc(arm)==otherSucc`). A both-arm if/else has **no** straight-through edge, so
the candidate is **never even collected**. Inc 2 must widen the **recognizer** (add a
shape where both successors are single-pred sole-sink arms converging on one 2-pred
merge: `uncondSucc(S0)==uncondSucc(S1)==M`) **and** the `CtrlIOCandidate` struct
(`:304-312`, single `Sink/Arm/Negated` → per-arm), not just `ArmIsSoleSink`.

**(F) Minor — §2.10 clobber row is a REUSE.** The clobber `What` `arm rewrites a
condition operand` already exists (`ArmClassify.cpp:930/1038`). Its fixture is
**`control_swap_reject_clobber.ll`** — the PRD's `swap_route_reject_clobber.ll`
(§2.10/§5) **does not exist**. Inc 4 reuses the string; only `non-reconverging value
exit` / `phase-class value escaping` / `loop` are net-new.

**(G) Minor — §2.7 mechanism differs (conclusion holds).** The merged out-rail is kept
via **`ControlOwnedRails` subtraction** (`SwapRouteEmit.cpp:362` / `SelectMergeEmit.cpp:131`,
subtracted at `Uncomputation.cpp:175`), **not** via `FreePoint`'s ret-as-Escaped path
— it never becomes a Phase-5 terminal at all. Hazard (iii) does not arise, but the PRD
conflates two mechanisms; the plan keys on `ControlOwnedRails`.

**(H) Minor — §2.6 phase-class guard needs a φ-rooted analog.** The select path fences
dephasing with `operandCarriesPhase` (backward, `SelectClassify.cpp:145`) **and**
`hasCoherentDownstreamUse` (forward, `:176`) **and** the angle fence
`selReachesRotationArg1` (`:86`). The exp2 br-diamond classifier must run a
**`PHINode`-incoming analog of all three** on each computed arm value, or it re-opens
the verify-clean dephasing leak (P0 0.585→0.500).

**(I) Minor — e2e smoke must live in a NON-`main` function.** `main` →
whole-function Escaped (`FreePoint.cpp:122-123`): every handle is silently skipped, no
free/no adjoint. A smoke whose merged return lives in `main` proves nothing about the
free/uncompute path. Put the controlled return in `int slice(void)` and call it from a
trivial `main` (the existing slice convention).

**(J) Minor — the dead twin shim.** `runOnFunction` (`CQLoweringPass.cpp:165-250`) is
dead (`Plugin.cpp` registers only `run()`) but mirrors the entire step sequence. Per
WI-1.12 convention, any new step wired into `run()` must be mirrored into
`runOnFunction` at the same position (between `lowerControlledIOSinks` and
`lowerRotations`) or a future reviver silently diverges.

---

## 3. Increment 1 — exp2 br-diamond data-mux detection + dispatch

**Objective.** Accept the reconverging early-return diamond whose `soleMergePhi` has
**two independent computed value arms with no shared base** (the exp2 gap), lowering it
via a new br-diamond controlled-XOR-copy data-mux emitter. Confirm (regression-pin) the
shared-base reconverging return already lowers via the reused 4.2 route. Maps to PRD
Deliverable 1.

### Change-points

| Anchor (file:line) | Change |
|---|---|
| `ControlDetect.cpp:168` `handleBranchRegion` | After `classifyClassicalCallArm` / before-or-after `classifyArms`, call a new tri-state `classifyBranchDataMux(R, Taint)` (mirror the `ClassicalCallDisp::{Accept,Declined,NotApplicable}` pattern). On Accept, stamp a new `Kind` and push `R`. |
| `ControlPlan.h:139` `enum Kind` | Add enumerator `BranchDataMux` (mirrors how 6.5 added `ClassicalCallArm`). `R.Merge` = the 2-incoming `PHINode`. |
| **new** `ir-pass/src/BranchDataMuxClassify.cpp` (+ `.h`) | `classifyBranchDataMux`: read the two incomings of `soleMergePhi` already in `R.Merge`; require each an integer **basis/data** value (not necessarily `ConstantInt`); reject a single-shared-base shape (that is `classifyArms`' job → `NotApplicable`); run the φ-rooted angle + phase-dephasing + width + alias fences (see below). |
| **new** `ir-pass/src/BranchDataMuxEmit.cpp` (+ `.h`) | `emitBranchDataMuxRegion`: the `emitSelectRegion` 6-step template **+** hoist the two computed arm values into `Pred` **+** `flattenRegion(R, taint)`. Register `Out` in `ControlOwnedRails`. |
| `SwapRouteEmit.cpp:719` `lowerControlRegions` | New dispatch branch `case BranchDataMux: emitBranchDataMuxRegion(...)` (alongside `SelectRegion`/`SwitchRegion`/`ClassicalCallArm`). |
| `CQLoweringPass.cpp:109/227` | No new step — `detectControlRegions`/`lowerControlRegions` already run here. (Twin-shim parity: nothing to mirror; the new Kind flows through existing calls.) |

### Reuse — do not touch
- `materializeCopySource` (`SelectMergeEmit.cpp:66`) — already identity on a computed
  tainted `i32` handle. Use as-is.
- `recoverRegion` (`ControlDetect.cpp:91`) / `soleMergePhi` (`:75`) — already recover a
  2-incoming φ for a `br`-diamond into `R.Merge`/`R.Arm`/`R.ArmFalse`/`R.ArmNegated`.
  **Do not loosen `soleMergePhi`'s 2-incoming-only test** (a multi-phi / >2-incoming
  merge is a real multi-register mux — must stay declining; over-decline is safe).
- `flattenRegion` (`RegionFlatten.cpp:46`) — terminator-agnostic; reuse for the CFG
  collapse. **Do not fork.**
- The 4.2 `emitValueRegion` path (`SwapRouteEmit.cpp:204`) — the **shared-base**
  reconverging return rides this unchanged (regression-pin only).
- `lowerCompareToFlag`, the `cqrt_x` `¬flag` bracket, `cqrt_copy_<W>_controlled`,
  `icmp_inv` strip, `cqrt_free` — all exist; emit verbatim.

### Detection fences (the over-accept hazard is entirely on the new path)
The new `classifyBranchDataMux` must replicate the select path's gates, **generalized
from a `SelectInst` to a 2-incoming `PHINode`**:
1. **Angle fence** — a φ-rooted analog of `selReachesRotationArg1` (`SelectClassify.cpp:86`).
   No downstream backstop; an angle reaching a rotation arg-1 **must** be caught here.
2. **Phase-dephasing fence** — `operandCarriesPhase` (backward) **and**
   `hasCoherentDownstreamUse` (forward) on **each** computed incoming (§2-H). A
   phase-class arm value silently dephases under XOR-copy (Rule 7) — **decline** with
   `phase-class value escaping` (Inc 4 string).
3. **Width / type** — integer ABI width with `widthHasReversibleCopy`; FP merge-φ is an
   **angle, not data** (the f64 silent-miscompile family) — test `isFPOrFPVectorTy()`,
   **never** key on `abiWidthFromType` non-empty.
4. **Sink-only** — the merge result must be used only by a recognized measure sink or
   `ret` (mirror `proveSwitchDataMux`'s carrier-independent gate,
   `SwitchArmProve.cpp:333-363`); `%out` is a fresh alloc the forward propagation never
   saw, so the downstream angle/handle-misuse backstop never fires — restrict the
   consumer instead.
5. **Alias / clobber** — reuse `operandsAlias` + the §3c `diagonalAliasHit`
   (`ArmClassify.cpp:220`) so an arm value that rewrites a condition operand declines.

### Emitter ordering (silent-miscompile-fragile — pin by ORDERED CHECK)
Mirror `emitSelectRegion` §5a exactly, with the CFG additions:
1. mint flag from `R.Condition` compare; 2. `cqrt_alloc_<W>(0)` out-rail;
3. **hoist** both computed arm-value chains into `Pred` (before flatten — analogous to
`ClassicalCallArmEmit` hoisting the pure call); 4. `cqrt_copy_<W>_controlled(flag,
out, TRUE-src)`; 5. `cqrt_x(flag)` … `cqrt_copy_<W>_controlled(flag, out, FALSE-src)`
… `cqrt_x(flag)` (**bracket encloses ONLY the second copy** — mis-span is
verify-clean-invisible); 6. `icmp_inv` strip + one `cqrt_free(flag)`; 7. RAUW
`MergePhi→out`, scrub+erase φ; 8. `flattenRegion(R, taint)`. Register `out` in
`taint.Tainted + ControlOwnedRails + BirthOrder`; leave the materialized scratch
**untainted** so uncompute never selects it.

### TDD steps
1. **RED (capture, not hand-write — §2-D):** build the exp2 `.c` (two independent pure
   add/mul/xor/shl chains, measured, returned), `clang -O1 -emit-llvm -S`, confirm it
   survives as a `br`-diamond (`select` count 0, cond-`br` 2, φ 2), save the `.ll` as
   `control_swap_branch_datamux.ll`. It declines today with `control flow under quantum
   control` — pin that first.
2. **RED (regression-pin):** add `control_swap_value_early_return.ll` from real `-O1`
   output of a **shared-base** early return; confirm it **already** lowers via the 4.2
   route (this is the §2-B confirm-it-works pin, no code change).
3. **IMPL:** add `BranchDataMux` Kind, `classifyBranchDataMux`, `emitBranchDataMuxRegion`,
   the dispatch branch.
4. **RED→GREEN negatives:** φ-rooted analogs of every select reject —
   `control_swap_reject_branch_datamux_phase.ll` (phase-class incoming),
   `…_angle.ll`, `…_fpdata.ll`, `…_i128.ll`, `…_alias.ll`, `…_used_result.ll`
   (merge used by a non-sink). Each mirrors its `What` char-for-char.
5. **VERIFY:** `ir-pass-lit` green; two-RUN verify guard on the positive; e2e
   `slice_control_branch_datamux.c` (+ `.expected.log`, captured) in a **non-`main`**
   `slice()`; the existing 4.4/4.2/escape fixtures stay green.
6. **CLEAR:** Rule-13 review of the lowered IR — confirm the XOR-copy bracket span, the
   hoist-before-flatten ordering, the phase fence on **both** incomings, and that the
   shared-base case still routes to 4.2 (not the new emitter).

### Hazards → caught by
- Phase-class arm silently XOR-copied (Rule 7) → fence (2) above + reject fixture.
- Hoist-after-flatten / dangling copy source (use-after-free) → ordered emitter steps +
  `verify` RUN + e2e link.
- Loosening `soleMergePhi` to accept a multi-register mux → keep 2-incoming-only;
  decline fixture for a 3-incoming/multi-phi merge.
- Pinning a shape clang no longer emits → capture from real `-O1`, re-verify (§2-D).

> **§8 owner flag:** given the exp2 surface is narrow and optimizer-cost-fragile,
> building a whole new emitter vs. **conservatively declining** the surviving surface
> with a dedicated `non-reconverging value exit`/`exp2` diagnostic is a genuine
> cost/benefit choice (over-decline is always safe). PRD §2.3 commits to building it;
> flag for confirmation before Inc-1 code lands.

---

## 4. Increment 2 — Mixed-kind arm-by-arm dispatch + both-arm I/O

**Objective.** One diamond, one flag, each **arm-effect** routed to its own coherent
mechanism (value → 4.2/4.4; append-only I/O → 7.6 controlled tape; the abort sink
joins in Inc 3). Generalize the single-arm I/O recognizer to both arms. Maps to PRD
Deliverable 2.

### Change-points

| Anchor (file:line) | Change |
|---|---|
| `IOSinkLowering.cpp:347-358` recognizer | Add a **third orientation**: both successors single-pred sole-sink arms with `uncondSucc(S0)==uncondSucc(S1)==M`. Today neither `uncondSucc(S0)==S1` test matches a both-arm diamond, so it is never collected (§2-E). |
| `IOSinkLowering.cpp:304-312` `CtrlIOCandidate` | Widen `Sink/Arm/Negated` → per-arm `(sink, arm-block, polarity)` so each arm emits under its own flag polarity into the **shared** tape. |
| `IOSinkLowering.cpp:363` `armIOSink` call | Call on **both** successor blocks; confirm each is a `{sink, br}` sole-sink arm. |
| `IOSinkLowering.cpp:416-419` `ArmIsSoleSink`/`MergeIsCleanJoin` | Apply `ArmIsSoleSink` **per-arm**; the merge still has exactly 2 preds with no phi (printf results discarded) so `MergeIsCleanJoin` holds unchanged. Key on "both successors are single-pred sole-sink arms converging on one 2-pred merge" — **not** merely "2-pred no-phi merge" (else over-accept a partial nest). |
| `IOSinkLowering.cpp:501-509` emit 7c | TRUE-arm targets under `flag`; FALSE-arm targets under the `cqrt_x`-bracketed `¬flag`. Mint the flag **once** from the one compare. All writes target the shared `ioTapeFor` tape. |
| `IOSinkLowering.cpp:525-531` flatten | Set `R.ArmFalse` to the else arm so `flattenRegion` erases **both** arms and splices the merge tail once. Verify it handles a phi-less both-arm void region. |
| `IOSinkLowering.cpp:182` `collectTapeTargets` | Pass `C.Cond` as `allowedExtraUser` for **both** arms (the same compare may be read by both arms' taped values → else the second arm trips `kMsgIOFanout`). |
| **(arm-by-arm value+I/O):** `ControlDetect.cpp:168` / `ControlPlan.h:52` | For a mixed value+I/O diamond, record a **per-arm effect** (extend `ArmClass` past `{Phase,Value}` or add a parallel per-arm effect `SmallVector`). The single-`ArmClass` dispatch would silently lower only one effect. Dispatch each effect to its emitter under the one minted flag. |

### Reuse — do not touch
- `isRecognizedIOSink` (`IOSinkLowering.cpp:80/94`) — exact-name `printf`/`putchar`,
  direct call to an extern decl, no operand bundles. Reuse per-arm verbatim.
- `tapeWriteControlledFn` (`ControlledSymbols.cpp:82`), the `cqrt_x` bracket,
  `ioTapeFor` (`:158`, one lazy tape per function), the `OutputRails` keep-discipline
  (`DagTraversal.cpp:116` / `FreePoint.cpp:72` / `ChainWalk.cpp:39`) — **unchanged**.
- The whole decline/passthrough matrix (`lowering_reject_io_*`) — reuse per-arm.

### Tape-length determinism
Both arms **unconditionally append exactly one entry**; only **content** is gated
(`¬flag` bracket). Tape length stays classical/deterministic (fixed 2 entries, no
superposition over N vs N+1). **Do not allocate two tapes** — the one-tape-per-function
invariant (`lowering_io_controlled_shared_tape.ll`). Rule-13 trace note: a both-arm
if/else records **2** entries where the classical program prints **1** — the inactive
arm's entry is committed as `|0>` content (accepted Bennett-tape semantics; pin in the
golden).

### TDD steps
1. **RED (capture, §2-D):** hand-build a both-arm I/O `.c` with **non-foldable distinct
   sinks** (e.g. `printf("%d",q)` vs `putchar(q)`), confirm it survives as a `br`-diamond
   at `-O1` (the same-typed-arg version folds to one printf — useless). Save
   `lowering_io_controlled_both_arm.ll`; it declines today via the generic catch-all.
2. **IMPL:** the recognizer + `CtrlIOCandidate` + per-arm emit + flatten changes.
3. **RED (mixed):** `control_mixed_value_io.ll` — one arm returns a value, one arm
   prints; each effect under the one flag.
4. **RED→GREEN negatives:** keep `lowering_reject_io_controlled_compound_cond.ll`
   (select-i1 compound cond, no single flag) and `…_nested.ll` (3-pred merge) **still
   declining** — the both-arm widening must not over-accept a 3-pred merge.
5. **VERIFY:** e2e `slice_io_both_arm.c` (+ golden, both polarities, shared tape) in a
   non-`main` `slice()`; uncontrolled + single-arm I/O baselines stay green.
6. **CLEAR:** Rule-13 — bracket span per arm (ordered CHECK), one tape, deterministic
   length, mixed-effect both lowered.

### Hazards → caught by
- `¬flag` bracket span wrong on the false arm → ordered CHECK (`…_ne.ll` template).
- Over-accept a partial nest (3-pred merge) → key on the precise both-arm converging
  shape + keep `…_nested.ll` declining.
- Mixed diamond silently lowering only one effect → per-arm effect record + a
  value+I/O positive fixture.
- Second arm trips fan-out on the shared condition → `allowedExtraUser=C.Cond` on both.

---

## 5. Increment 3 — `abort`/`exit` park cascade (the one new emission)

**Objective.** Accept a tainted-condition `br` whose arm is a recognized noreturn sink
(`@abort`/`@exit`/`@_exit`/`@__assert_fail`/`@llvm.trap`/`@llvm.ubsantrap`/`noreturn`
call + `unreachable`, **no value, no merge φ**), with the sibling being the ordinary
uncontrolled remainder. Mint flag → `cqrt_cswap` live regs into a graveyard → downstream
runs uncontrolled → record flag on the tape → truncate-at-inspection. Maps to PRD
Deliverable 3 / §2.8 / §2.11-B.

### Verified shape (the recognizer's exact SSA signature)
`-O1` IR of `if(q>5) abort();` (verified):
```llvm
%2 = tail call i32 @cq_theta_si32(i32 %0, double 5.0e-01)
%3 = icmp sgt i32 %2, 5
br i1 %3, label %4, label %5
4:  tail call void @abort() #4        ; #4 = cold noreturn nounwind
    unreachable
5:  ret i32 %2                        ; ordinary uncontrolled remainder
```
The arm ends in `unreachable` (→ `uncondSucc==null` → would hit `OffPattern`); **no
merge φ, no returned value**. This structurally **kills the §2.8↔§2.10 collision**: the
colliding value-exit `if(q>5)return 99;return q;` does **not** survive as a diamond —
clang folds it to `select`, already accepted by 4.4. So an `unreachable`-after-noreturn
arm is unmistakable.

### Change-points

| Anchor (file:line) | Change |
|---|---|
| `ControlDetect.cpp:168` `handleBranchRegion`, **before** the `OffPattern` fall-through | Add `classifyAbortPark(R, Taint)` (tri-state). Match: tainted-condition `br`; exactly one arm single-pred + `unreachable` immediately preceded by a noreturn-sink `Call`/`Invoke` (by callee name set **AND/OR** the `noreturn` attribute — `@llvm.trap`'s call site carries no explicit attr, only the decl, so check both); the call carries no returned value; the sibling is the ordinary remainder. **Must run before** `recoverRegion`'s `OffPattern` decline pre-empts it (parallel to how `lowerControlledIOSinks` pre-peels the merge-φ-less void-I/O diamond). |
| `ControlPlan.h:139` `enum Kind` | Add `AbortPark`. Populate `Pred`/`Arm`(sink arm)/`ArmFalse`(remainder)/`Condition` so the cross-region block-lifetime pre-flight (`SwapRouteEmit.cpp:747-773`) covers it (a Kind that leaves `Condition`/`Merge` null bare-returns past both diagnose arms = **silent accept**, the one unforgivable bug). |
| **new** `ir-pass/src/AbortParkEmit.cpp` (+ `.h`) | `emitAbortParkRegion`: mint flag; `cqrt_cswap` each live reg into a freshly `cqrt_alloc`'d **graveyard** rail (self-bracketed — never through `emitInverseChain`, §2-A); record the abort flag via `cqrt_tape_write_i1(tape, flag)`; let the sibling/downstream run **uncontrolled** (do **not** gate every downstream op on `¬flag` — that is the 7.6 Tier-0 non-terminating case, drastically too costly and pointless here since abort terminates). Register graveyard rails in the **new `taint.GraveyardRails`**. |
| `TaintPropagation.h:160` (beside `OutputRails`) | Add `GraveyardRails` set. |
| `Uncomputation.cpp:175-181` **AND** `DagTraversal.cpp:107-119` | Subtract `GraveyardRails` at **BOTH** sites (§2-A — missing the closure-scan site = hidden collapse of a parked entangled rail). |
| `SwapRouteEmit.cpp:719` `lowerControlRegions` | New dispatch branch `case AbortPark: emitAbortParkRegion(...)`. |
| `CQLoweringPass.cpp` run()/shim | If the abort recognizer is a pre-detection pre-pass (like `lowerControlledIOSinks`), wire it at `:97`-adjacent in **both** `run()` and the dead shim (§2-J). If it lives inside `handleBranchRegion`, no new step. **Recommend inside `handleBranchRegion`** (the arm has a tainted `br`, so detection already visits it) to avoid a new pre-pass and twin-shim drift. |

### Reuse — do not touch
- `cqrt_cswap` (self-adjoint, `EmitInverse.cpp:47-48`) — the park primitive; no new
  adjoint rule.
- `cqrt_tape_write_i1` (`cq_runtime.h:343`) — record the flag; **no new symbol**.
- `MergeIsTail`'s `UnreachableInst` recognition (`IOSinkLowering.cpp:420`) — existing
  precedent for an `unreachable` tail; reuse the pattern.
- The phase-class arm-class guard (§2-H / Inc 1 fence 2) — apply to the **sibling**
  `ret` operand: a phase-class value escaping beside the park arm is the §2.6 deferred
  interaction → **conservatively decline** with `phase-class value escaping` (do NOT
  route onto the in-place phase-escape path until park-coherence is proven).

### Why abort is correct and cheap (Rule-13 must confirm, not assume)
abort **terminates** → there is **no coherent downstream** → the branch-correlated
tail-garbage of hazard (i) is never observed and never dephases (the same cost already
accepted from swap-route arms). The graveyard is **kept** (escaped-class via
`GraveyardRails`), never `cqrt_free`'d (Rule 6 — a parked entangled rail freed dirty is
a hidden measurement).

### TDD steps
1. **RED:** `control_swap_abort_park.ll` (captured from `if(q>5)abort();` `-O1`; needs
   `#include <stdlib.h>` — implicit decl is a hard `-O1` error). Declines today with
   `control flow under quantum control`. Add `exit`/`__llvm.trap__` variants.
2. **IMPL:** `classifyAbortPark`, `AbortPark` Kind, `GraveyardRails` + both subtraction
   sites, `emitAbortParkRegion`, dispatch.
3. **RED→GREEN negatives:** a lookalike non-noreturn call arm (`if(q)foo();` where `foo`
   is not noreturn → must still decline, not park); the §2.6 phase-class sibling beside
   an abort arm (`phase-class value escaping`).
4. **VERIFY:** ordered + CNT scan — exact graveyard `cqrt_cswap` count, the
   `cqrt_tape_write_i1(flag)`, and **`CNT-NOT: cqrt_free`** of the graveyard handle (it
   is **never** freed). e2e `slice_control_abort.c` golden showing the parked graveyard
   + recorded flag, in a non-`main` `slice()`.
5. **CLEAR:** Rule-13 — confirm both spine subtraction sites, the self-bracketed park
   cswaps (flag-slot seam), the graveyard never freed, and the sibling phase guard.

### Hazards → caught by
- Parked entangled rail reverse-played/freed → `GraveyardRails` subtracted at **both**
  `Uncomputation.cpp:175` and `DagTraversal.cpp:107` (§2-A) + `CNT-NOT: cqrt_free`.
- Park cswap threaded through the inverter (flag-slot seam → wrong unitary) →
  self-bracket via `emitRoute` pattern; never call `emitInverseChain` on it.
- A non-noreturn call mis-parked → recognizer matches name-set **and/or** `noreturn`
  attr only; lookalike reject fixture.
- A new Kind that leaves `Condition`/`Merge` null → silently accepts quantum control →
  populate the anchors so the pre-flight covers it.

### Freeze contingency (§8)
Truncation reuses `cqrt_tape_write_i1` + a backend truncate-at-inspection convention →
**no new frozen symbol** (verified, §0.5-6). **Only** if implementation proves a
dedicated on-tape truncate/marker symbol is genuinely needed for backend
disambiguation does the (frozen) 7.6 tape ABI reopen — owner pre-approved, but it must
be flagged **loudly** in the Rule-13 clearance as a freeze-scope change.

---

## 6. Increment 4 — Decline-diagnostic partition

**Objective.** Replace the generic `control flow under quantum control` at the
`OffPattern` site with per-disposition, source-located messages, each with a
mirror-exact negative fixture. Maps to PRD Deliverable 4 / §2.10.

### Change-points

| Anchor (file:line) | Change |
|---|---|
| `ControlDetect.cpp:173` (the `OffPattern` `diagnoseUnderControl(BI,"control flow")` call) | Replace with a small **disposition classifier** (pure SSA, no mutation, by arm-terminator kind) that selects the `What`. **Scope it to this structural site** — `control flow` is the `What` at ~60 sites, so the partition CANNOT key on the message; it keys on the OffPattern path (§2-F / V3). |

Disposition logic at the partition (each → `diagnoseUnderControl(BI, <What>)`):
- An arm ends in `ret` with a **value**, not a noreturn sink (`musttail` return; two
  un-merged value rets) → **`non-reconverging value exit`** (§2.11-C-i;
  reopenable tooling boundary — 7.2 does **not** synthesize the merge).
- The escaping `ret` operand is **phase-class** (`cq_phi` lineage) → **`phase-class
  value escaping`** (§2.11-C-iii; conservative decline pending the §2.6 park-coherence
  proof).
- A divergent arm = self-`br` infinite loop, **no** recognized noreturn sink →
  **`loop`** (§2.11-C-ii; **defer to 7.3/7.4**).
- §3c clobber → `arm rewrites a condition operand` (**already exists**,
  `ArmClassify.cpp:930` — reuse, §2-F).
- Anything else → keep the generic `control flow`.

### Reuse — do not touch
- `diagnoseUnderControl` (`ControlDetect.cpp:47`) — the single primitive. **Pass a new
  `What`; do not add a mechanism.**
- The pre-`ControlDetect` `kMsg*` escape family (`TaintPropagation.cpp`) — runs first;
  `non-i32`/store/opaque-call already decline upstream. **7.2 must not double-own them**
  (§0.5-3 / PRD §2.10 last two rows).

### TDD steps
1. **RED:** one mirror-exact `RUN: not … | FileCheck` per new `What` —
   `control_swap_reject_nonreconverging_value_exit.ll` (a `musttail`/two-un-merged-rets
   shape — note these essentially never survive `-O1` for non-`musttail` code, so use
   `musttail` or a hand-written `.ll`), `control_swap_reject_phase_value_escaping.ll`,
   `control_swap_reject_loop_under_control.ll` (self-`br` arm).
2. **IMPL:** the disposition classifier at `:173`.
3. **VERIFY:** `control_swap_reject_clobber.ll` and all existing `control flow` rejects
   (the ~60 other sites) **stay green** (their `What` is unchanged); the new messages
   fire only on the OffPattern path.
4. **CLEAR:** Rule-13 — confirm mutual exclusivity (a shape matches exactly one
   disposition; abort+value is Inc 3's `AbortPark`, never `non-reconverging value
   exit`), and that the classifier is pure SSA before any mutation.

### Hazards → caught by
- Keying the partition on the message string (would mis-fire at the ~60 generic sites)
  → scope to the OffPattern structural site only.
- Re-owning `non-i32`/store/opaque-call (duplicate/shadowing diagnostics) → those
  decline upstream in `declineTaintEscapes`; the partition only sees i32 control shapes.
- A shape matching two dispositions → Inc-3 `AbortPark` recognizer runs first; the
  partition handles only residual `OffPattern`.

---

## 7. Done criteria (roll-up — maps to PRD §4)

- [ ] Shared-base reconverging early-`return` lowers via the reused 4.2 route
  (regression-pin, `opt -verify` clean, golden e2e clean). *(Inc 1 — confirm-it-works.)*
- [ ] exp2 two-independent-computed-arm `br`-diamond lowers via the new data-mux emitter
  (`cqrt_copy_<W>_controlled` + `¬flag` bracket + `icmp_inv` strip + one `cqrt_free`,
  CFG flattened), captured-from-`-O1` fixture + e2e. *(Inc 1.)*
- [ ] Mixed value+I/O diamond dispatches arm-by-arm; `if/else`-both-`printf` lowers to
  two `cqrt_tape_write_<W>_controlled` into one shared tape, deterministic length.
  *(Inc 2.)*
- [ ] Controlled `abort`/`exit` lowers to the park cascade with the pre-abort state
  preserved in the graveyard and the abort flag recorded on the tape; graveyard
  **never freed**. *(Inc 3.)*
- [ ] Every off-pattern/irreversible shape declines **loudly** with its own
  source-located diagnostic (non-reconverging value exit, §3c clobber, measurement
  under control, opaque escape, loop), each with a mirror-exact negative fixture.
  *(Inc 4 + pre-existing escape guards.)*
- [ ] **A phase-class return/merge value reaching a data-copy path declines** (Rule 7
  guard) — pinned by an adversarial probe (a silent XOR-copy of a phase is verify-clean
  and trace-plausible). *(Inc 1 fence 2 + Inc 3 sibling guard.)*
- [ ] **No new frozen runtime symbol** minted (verify against `cq_runtime.h`); if the
  §2.8 truncate symbol is forced, it is called out as a freeze-scope change. *(All.)*
- [ ] **Rule-13 clearance** of the detection widening, the arm-by-arm dispatcher, and
  the abort park by independent adversarial review reading the **lowered IR** — the
  review explicitly checks ROADMAP hazards (i)/(ii)/(iii) are discharged as argued in
  PRD §2.6/§2.7/§2.9, **not merely hidden**.

---

## 8. Open owner-decision flags

1. **exp2 build vs. decline (Inc 1).** The surviving `br`-diamond surface is narrow and
   optimizer-cost-fragile (§2-D). PRD §2.3 commits to building the new data-mux emitter;
   the cheaper, always-safe alternative is to **conservatively decline** it with a
   dedicated diagnostic. Confirm before Inc-1 code lands.
2. **PRD §2.11 confirmations (verbatim from PRD).** (i) noreturn-sink + value sibling =
   **park-accept** (not decline); (ii) `musttail`/un-merged value rets = **decline**,
   7.2 does not synthesize a merge; (iii) phase value escaping beside a park arm =
   **conservative decline**; (iv) non-`abort` divergence = **defer to 7.3/7.4**. Each
   flips a disposition.
3. **`GraveyardRails`: new set vs. reuse `OutputRails` (Inc 3).** A new set is
   semantically clearer; reusing `OutputRails` is functionally identical (kept, never
   freed/reversed, already subtracted at both sites). Plan recommends the **new set**;
   either way both subtraction sites are mandatory.
4. **§2.8 truncate symbol (freeze contingency).** Reuse `cqrt_tape_write_i1` +
   inspection convention by default (no new symbol). Owner pre-approved reopening the
   frozen 7.6 tape ABI **only** if a dedicated truncate/marker is proven necessary —
   flag loudly in Rule-13 if taken.

---

## 9. PRD corrections to fold back (housekeeping)

The grounding workflow found these PRD inaccuracies; fold them into PRD-7.2 when
convenient (they do not change the PRD's conclusions):
- Catch-all is `ControlDetect.cpp:**173**`, not 172 (172 is the `case` label). (§1, §2.10)
- "no dominator analysis" → "**no PostDominatorTree** in detection" (a plain
  `DominatorTree` is at `RegionTreeDetect.cpp:140`). (§2.11, §6 Risk-2)
- §3c clobber fixture is **`control_swap_reject_clobber.ll`**, not the nonexistent
  `swap_route_reject_clobber.ll`. (§2.10, §5)
- The §2.10 clobber row reuses an **existing** `What`; only 3 messages are net-new. (§2.10)
- §2.7 mechanism: the merged out-rail is kept via **`ControlOwnedRails`** subtraction,
  not `FreePoint`'s ret-as-Escaped path (conclusion — hazard iii does not arise —
  holds). (§2.7)

---

*Drafted 2026-06-22 at the start of Phase 7.2. Grounds [`PRD-7.2.md`](PRD-7.2.md).
All file:line anchors verified against the live tree (plugin dated 21 Jun) by a
15-agent grounding workflow on 2026-06-22; corrections vs. the PRD are isolated in §2
(READ FIRST) and §9. This is the execution layer — Rule 13 (core control change) gates
every increment regardless of a green suite.*
