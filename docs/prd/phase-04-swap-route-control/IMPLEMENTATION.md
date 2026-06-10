# Phase 4.1 IMPLEMENTATION — RSSA swap-routed phase-arm control flow

Module layout, signatures, and the **test-driven** work-item sequence for the
4.1 increment defined by [`PRD.md`](PRD.md). Companion to the PRD (which fixes
*scope* and *binding decisions*); this file fixes *how the code is built*. Every
signature below was extracted verbatim from the live tree (branch
`swap-route-control`) — see the per-symbol `file:line` citations. Nothing here
adds runtime ABI (PRD §1, §3); 4.1 reuses existing `cqrt_*` / `cq_template_*`
symbols only.

**Authoritative contracts** this plan is built against (FileCheck specs):
`docs/design/rssa-swap-control/swap_route_if_diamond.ll` (accept, one-content-arm
phase diamond), `…/swap_route_ifelse.ll` (accept, two-arm phase if/else),
`…/swap_route_reject_clobber.ll` (§3c permanent decline). The target symbol
sequences in §5 are transcribed from those files; **symbol order IS the
contract** (CHECK-pinned), plus the two hard postconditions `CHECK-NOT:
_controlled` and `CHECK-NOT: phi i32`.

---

## 0. Accept criterion (the one definition everything keys on)

> **4.1 lowers a tainted-condition region iff ALL hold; otherwise it declines
> loudly and lowers nothing (Prime Directive):**
>
> 1. **(shape)** a `BranchInst` that `isConditional()` whose condition is in
>    `taint.Tainted`, forming either a **clean diamond** (one arm block + a
>    straight-through edge, reconverging at a single 2-incoming merge `PHINode`)
>    or an **if/else** (two arm blocks, single 2-incoming merge phi);
> 2. **(phase arm)** each arm's contribution to the merge phi is a **pure phase
>    chain** — its def-use lineage from the merge back to a base value contains
>    **only `@cq_phi_<sfx>` calls** (Rz), no value-changing op;
> 3. **(quantum base)** that base value is a **tainted quantum handle** (in
>    `taint.Tainted`, lineage bottoms at a `@cq_theta_<sfx>` source);
> 4. **(no clobber, §3c)** no arm value-rewrites a register in the condition's
>    transitive taint provenance (vacuous for pure-phase arms, but checked and
>    fixtured per Rule 12).

This criterion makes the three pinned fixtures fall out exactly, and it keeps the
existing `control_tainted_diag.ll` a **decline** (its arm rotates the *classical*
arg `%y0`, failing (3)) so that fixture stays green with no edit — verify, don't
repoint.

> **Addendum (2026-06-10, test_C_libtooling-9hh — derived base accepted).**
> Criterion 3's "tainted quantum handle" explicitly includes a **derived** base:
> a pre-region, unconditional `cq_phi` result (`%qd = cq_phi(%q,·)` before the
> branch, shared by the arm spines). WI-3 shipped a stricter SSA-conservative
> decline (`isPhiCall(Base)` → `control flow`) as crash-containment; that guard
> is now removed. Soundness: `cq_phi` is an Rz — **diagonal**, so it is a leaf
> by opcode in `isValueChangingOp` (basis value preserved ⇒ the flag minted from
> `icmp(q)` stays recoverable by `icmp_inv(q)`), and rotation lowering RAUWs
> `%q` and `%qd` to the **same** i32 handle, so routing the live SSA register is
> identical at the handle level. The WI-3 double-erase family stays foreclosed
> by the arm-block-bounded spine walks (the shared pre-region phi is never
> collected as an arm gate). A derived base that does **not** equal the routed
> handle (diamond stale straight-through; mixed-depth if/else arms) still
> declines `control flow`. Statevector clearance:
> `docs/design/rssa-swap-control/clearance_derived_base.py` (coherence-exact
> under both Rz conventions, 1-qubit AND 2-bit-register models; the two-arm
> stream is convention-independent up to global phase). Fixtures:
> `control_swap_{diamond,ifelse}_derived*.ll`,
> `control_swap_reject_{diamond_derived_crosshandle,ifelse_derived_mixed}.ll`;
> e2e: `slice_control_phase_ifelse_derived` (asymmetric arms — symmetric
> one-gate arms fold to the 4.4-deferred tainted **angle select** at `-O1`).
>
> The §8 adversarial clearance of this change added three guards to the accept
> predicate (each with its own decline string + fixtures):
> 1. **Angle classicality** (`taintedAngleGate`) — every arm-spine gate's arg-1
>    angle, and a derived base's own angle, must be **untainted**; a
>    quantum-derived angle has no fixed unitary and would lower verbatim to a
>    handle-tag read (verify-clean silent miscompile, confirmed live for both
>    derived and un-derived bases) → `rotation angle`
>    (`control_swap_reject_tainted_angle{,_underived,_prebase}.ll`).
> 2. **Sequential regions** — an if/else MERGE hosting the next tainted branch
>    declines as `nested control flow` while blocks are still valid (an
>    accepted region's flatten erases its merge = the next region's Pred —
>    SIGSEGV; pre-existing at WI-3, reach widened by the derived accept). The
>    emitter also pre-flights cross-region block aliasing and made every
>    defensive bail **loud** (`control_swap_reject_seq_ifelse.ll`).
> 3. **Compare/branch gap** (`nonDiagonalGateBeforeBranch`) — a tainted-operand
>    `cq_theta` (non-diagonal Ry) between the compare and the branch makes the
>    branch-position flag mint read the wrong basis (verify-clean wrong-arm +
>    clean flag, fidelity 0.848 vs source in the oracle; pre-existing) →
>    `condition predates a non-diagonal gate`
>    (`control_swap_reject_stalecond_chained_theta.ll`). The principled
>    mint-at-compare design is a deferred follow-up.

Decline dispositions for everything else (each a loud `DiagnosticInfoUnsupported`
via the shared `diagnoseUnderControl`, `opt` exits non-zero):

| Shape | Disposition | Diagnostic `What` (→ `…: <What> under quantum control`) |
|---|---|---|
| §3c value-clobber of a condition operand | **permanent reject** | `arm rewrites a condition operand` *(PRD-pinned, char-for-char)* |
| value/permutation arm on a non-condition register | defer to **4.2** | `value-arm swap-route` |
| nested tainted control | defer to **4.3** | `nested control flow` |
| tainted `select` | defer to **4.4** | `select` *(existing string)* |
| tainted `switch` | defer to **4.5** | `switch` *(existing string)* |
| merge selects a non-quantum value under quantum control; any off-pattern CFG | **reject** | `control flow` *(existing generic string)* |

---

## 1. Module map

New modules follow the house rule — **one width-parametric concern per
translation unit, `namespace cq`, ≤300 LOC** (current max is `WidthDispatch.cpp`
at 284). Targets are budgets, not minimums.

### New translation units (`ir-pass/src/` + `ir-pass/include/`)

| Module | LOC (cpp / h) | Concern | Mutates IR? |
|---|---|---|---|
| **`ControlDetect`** | ~190 / ~45 | Pure analysis. Recognize the §0 diamond / if-else shape, resolve arm polarity (Rule 9), verify pure-phase-chain-over-tainted-handle arms, populate `ControlPlan.Regions`. Owns the new `detectControlRegions` (moved out of `ControlStub`) and the decline dispatch. | **No** |
| **`ArmClassify`** | ~140 / ~30 | Per-arm lineage classification (phase / value / clobber) **and** the §3c condition-provenance backward walk + reject. Called by `ControlDetect`. | No |
| **`SwapRouteEmit`** | ~230 / ~35 | The new mutating step `lowerControlRegions`. Per accepted region: flag mint → rail alloc → `cswap` route-in (+`cqrt_x` ¬flag bracket) → verbatim `rz` on rail → `cswap` route-back → rail free → `icmp_inv` flag-strip → flag free; then erase originals + scrub taint sets; calls `RegionFlatten`. | **Yes** |
| **`RegionFlatten`** | ~120 / ~30 | CFG flatten for one region: capture block identities *before* erasing (block-lifetime hazard), RAUW merge phi → routed handle, splice arm/merge instructions into the pred block, erase the `br`/merge-phi/dead-`icmp`/now-empty blocks. Reused recursively by 4.3. | **Yes** |

### Edits to existing files

| File | Change |
|---|---|
| `ir-pass/src/CQLoweringPass.cpp` | Insert `lowerControlRegions(M, wd, taint, plan)` **after** `detectControlRegions` and **before** `lowerRotations` — at **both** call sites: `run()` between lines 63 and 67, and `runOnFunction()` between lines 109 and 110 (the twin-pipeline trap — both or neither, see §6). |
| `ir-pass/CMakeLists.txt` | Add the 4 new `src/*.cpp` to `add_library(CQPass MODULE …)` (lines 43–61); remove `src/ControlStub.cpp` (retired). |
| `ir-pass/include/ControlPlan.h` | Promote `diagnoseUnderControl` to a declared shared helper (see §2). Add one `enum ArmClass` + routed-handle/`AngleList` fields to `ControlRegion` **only if** reusing the existing fields proves insufficient (prefer reuse — the header already says the swap emitter "reshapes" these). |
| `ir-pass/src/RotationLowering.cpp` + `.h` | Retarget the stale `lowerControlledRegions` / `ControlledSubstitution` comments (cpp 150-153; header 47, 60) to name the swap-route emitter. **No behavior change** — see InShadow decision in §3. |
| `ir-pass/src/ControlStub.cpp` | **Retire.** `detectControlRegions` body moves to `ControlDetect`; `diagnoseUnderControl` is promoted (shared). |

`ControlPlan.h` (238 LOC, the shared header, guard `CQ_IRPASS_CONTROL_PLAN_H_`)
**survives** — it is the region vocabulary both detection and emission read.

---

## 2. Shared diagnostic helper (reused by every decline path)

The existing loud-decline primitive (`ControlStub.cpp:43-48`) is exactly what 4.1
needs, including for the §3c reject — its `"cq controlled lowering: " + What + "
under quantum control"` form matched against `CHECK: error{{.*}}arm rewrites a
condition operand under quantum control` resolves because `{{.*}}` absorbs the
`cq controlled lowering: ` prefix. **Promote it** from the anonymous namespace to
a declared `cq` function so `ControlDetect`/`ArmClassify` share one copy:

```cpp
// ControlPlan.h (declaration), defined once in ControlDetect.cpp
namespace cq {
void diagnoseUnderControl(llvm::Instruction *Where, llvm::StringRef What);
}
```

Body is the verbatim existing construction (`DiagnosticInfoUnsupported(
*Where->getFunction(), Msg, Where->getDebugLoc())` → `…getContext().diagnose(…)`,
`DS_Error`, `!dbg` attached). The §3c call is literally
`diagnoseUnderControl(armWriteInst, "arm rewrites a condition operand")`.

---

## 3. Detection & classification (pure analysis, before any mutation — Rule 9)

`detectControlRegions(Module &M, TaintSet &taint) → ControlPlan` keeps its exact
signature (`ControlPlan.h:234`; the orchestrator calls it unchanged). New body:

```
for each non-declaration F, each BB:
  Term = BB.getTerminator()
  if BranchInst BI, BI.isConditional(), taint.Tainted.count(BI->getCondition()):
      region = recoverRegion(BI, taint)        // ControlDetect: shape + polarity
      if !region:               diagnoseUnderControl(BI, "control flow"); continue
      classifyArms(region, taint)              // ArmClassify: phase/value/clobber + §3c
      if region.declined:       (diagnostic already fired); continue
      plan.Regions.push_back(region)           // ACCEPT: pure-phase, quantum base
  else if SwitchInst SI, tainted cond:  diagnoseUnderControl(SI, "switch")
  else for SelectInst with tainted cond: diagnoseUnderControl(Sel, "select")
return plan
```

**`recoverRegion` (ControlDetect)** — resolve the diamond/if-else by **SSA-value
identity**, never block names or successor index:
- read the merge phi as the join (single `PHINode`, 2 incomings); both predecessor
  edges trace back to the same conditional `br`;
- **polarity (Rule 9):** `clang -O1` often makes the gate arm the *false*
  successor and value-propagates the straight-through edge. Resolve each arm by
  *which incoming the merge phi takes from which edge*, recording
  `ControlRegion::ArmNegated` for the ¬flag (else/false) arm — do **not** assume
  successor 0 is the taken arm;
- bail (`return {}`, caller declines generic) on: >2 incomings, non-phi join,
  arm with side exits, a merge block shared with another region (nested → 4.3
  defer), or any edge not reconverging.

**`classifyArms` (ArmClassify)** — for each arm, walk the arm's *contribution to
the merge phi* backward through its def-use lineage:
- **only `@cq_phi_<sfx>` calls + a tainted-handle base** → `PhaseArm`; record the
  base handle (the register to route) and the **ordered** `cq_phi` list into
  `ControlRegion::Shadow` / `ShadowFalse`;
- **a value-changing op (add/mul/sub/`cqrt_x`/toffoli/non-rotation) on a register
  in `condProvenance`** → **§3c reject**: `diagnoseUnderControl(op, "arm rewrites
  a condition operand")`, mark `region.declined`;
- **a value-changing op on a non-condition register** → `ValueArm`: decline
  `"value-arm swap-route"` (4.2), mark declined;
- **base not tainted** (e.g. `control_tainted_diag.ll`'s classical `%y0`) →
  decline generic `"control flow"`, mark declined.

**`condProvenance` (ArmClassify, ~30 LOC, no existing helper — there is NO
backward-slice API in the tree).** Backward operand walk from
`BI->getCondition()`, collecting tainted values, **replicating the per-use arg-1
angle exclusion verbatim** (`TaintPropagation.cpp:145-151`): when threading
through a `@cq_theta`/`@cq_phi` call, skip the operand-edge that is *only* arg 1
(the angle) and not arg 0 (the handle). Stop at `@cq_theta` sources and measure
sinks. Missing this exclusion would mis-flag an angle as a condition operand
(false §3c reject).

**InShadow decision (binding for 4.1).** `SwapRouteEmit` runs **before**
`lowerRotations` and **erases** each arm `cq_phi` (and **scrubs** them from
`taint.PhiCalls` and `taint.Tainted` — §6). Therefore the arm phis are gone
before `lowerRotations` iterates `taint.PhiCalls`, so **`plan.InShadow` stays
empty** for 4.1 and `RotationLowering.cpp:154`'s skip never fires (correct — there
is no in-place gate to skip). The only `RotationLowering` change is the **comment
retarget** (the named `lowerControlledRegions`/`ControlledSubstitution` were
excised in `7cde677`). This is the simplest correct wiring; do not populate
InShadow without also owning emit+erase (the dangling-phi trap).

---

## 4. Emission — `lowerControlRegions` (SwapRouteEmit)

New signature (mirrors the module-per-concern convention; takes the shared `wd`
and live `taint`):

```cpp
// SwapRouteEmit.h
namespace cq {
void lowerControlRegions(llvm::Module &M, WidthDispatch &wd,
                         TaintSet &taint, const ControlPlan &plan);
}
```

Construct **one** `ControlledSymbols csyms(M, wd)` (reusing the pass's `wd`, never
a second `WidthDispatch`). Per region, emit into the **pred block before the
conditional `br`**, in this exact order (the §5 contract):

1. **Flag mint** — `Value *flag = lowerCompareToFlag(condCmp, wd, taint,
   /*qqWidth=*/{}, /*inverse=*/false, /*before=*/br)` (`CompareLowering.h:110`).
   Returns the `i32` flag (`cq_template_icmp_<pred>_<W>_hl(handle, literal)`),
   handles operand classification + literal-on-left predicate flip + HL width
   recovery, and **does not** RAUW/erase the compare (we own that). Null return ⇒
   it already fired `diagnoseNoTemplate`; abort the region.
2. **Rail alloc** — `wd.allocFn(abi)` (`WidthDispatch.h:69`) with
   `abi = abiWidthFromType(routedHandle’s register type)` or `abiWidthFor(sfx)`
   off the arm `cq_phi` suffix (`OpcodeSupport.h:69` / `WidthDispatch.h:47`). One
   rail per arm (`%arm.t`; if/else allocs `%then.t` **and** `%else.e`).
3. **Route-in** — `csyms.cswapFn()` (`ControlledSymbols.h:90`):
   `cqrt_cswap(flag, routedHandle, rail)`. For the ¬flag (else/`ArmNegated`) arm,
   bracket with `csyms.xFn()`: `cqrt_x(flag); cqrt_cswap(flag, q, else.e);
   cqrt_x(flag)`.
4. **Arm body verbatim, uncontrolled** — for each recorded arm `cq_phi`, emit
   `cqrt_rz_<W>(rail, angle)` (reuse `RotationLowering::emitRz(..., controlled=
   false, flag=nullptr)`, `RotationLowering.h:61`, or a direct `wd` rotation
   callee). Angle is the `cq_phi` arg-1 (classical, confirmed not tainted).
5. **Route-back** — the **same** `cqrt_cswap(flag, q, rail)` (and the same
   X-bracket for the else arm). The join is the literal adjoint of the split,
   sharing `flag` — the two cswaps capture-match the same `%[[F]]/%[[Q]]/%[[T]]`.
6. **Rail free** — `wd.freeFn()` (`WidthDispatch.h:116`): `cqrt_free(rail)`. The
   rail is `|0⟩` for free (`Rz|0⟩=|0⟩`), so this is a clean reset, not a
   measurement (§3b). Single-region/single-block ⇒ this point *is* the
   post-dominator; emit directly. (`computeFreePoint` is the generalization for
   when arms span blocks — wire it in 4.3, not 4.1.)
7. **Flag-strip** — `lowerCompareToFlag(condCmp, wd, taint, {}, /*inverse=*/true,
   /*before=*/postRouteBack)` → `cq_template_icmp_<pred>_<W>_hl_inv(q, literal)`.
   Valid because `Rz` preserves `q`'s basis value (`q == q0`), so `icmp(q)` still
   equals the flag → strips it to `|0⟩` with **zero controlled gates**. Call this
   **before** erasing `condCmp` (it reads the cmp's operands/predicate).
8. **Flag free** — `cqrt_free(flag)`.
9. **Rewire + erase** — RAUW `mergePhi → routedHandle`; then **erase** in
   safe order (merge phi first, then arm `cq_phi` in reverse lineage, then `br`s,
   then dead `condCmp`); **scrub** each erased instruction from `taint.Tainted` /
   `taint.PhiCalls` (§6). Call `RegionFlatten` to splice + delete the arm/merge
   blocks. The user's `cq_measure(mergePhi)` becomes `cq_measure(q)` via the RAUW
   and is lowered later by `lowerMeasures`.

**Width source (Rule 9).** At emit time (before `lowerRotations`) the routed
handle is still the `@cq_theta` result and `taint.HandleWidth` is **not yet
populated**. Recover the ABI width from the **intrinsic suffix** (`cq_phi_si32` →
`si32` → `abiWidthFor` → `i32`), never from the SSA type after lowering. `cswap`,
`cqrt_x`, `cqrt_free` are width-agnostic (`i32` handles); only `allocFn` and the
`rz` name carry `<W>`.

**RAUW flow-through (why the emitter precedes `lowerRotations`).** The emitter
references the `@cq_theta` result `%q` in the flag/cswap/strip calls; when
`lowerRotations` later lowers `@cq_theta → cqrt_alloc_<W> + cqrt_ry_<W>` and RAUWs
`%q →` the `i32` handle (`RotationLowering.cpp:121-144`), every emitter call
updates automatically. This is exactly the "detection/emission by SSA identity
that survives RAUW-to-handle" discipline — and why the §5 CHECK lines use
`%[[Q]]` captures.

---

## 5. Target symbol sequences (the FileCheck contract)

### 5a. Diamond — `if (q>5) { rz(q,a); rz(q,b); }` (one content arm)

```
%flag  = call i32  @cq_template_icmp_sgt_i32_hl(i32 %q, i32 5)   ; 1 mint
%arm.t = call i32  @cqrt_alloc_i32(i32 0)                        ; 2 |0> rail
         call void @cqrt_cswap(i32 %flag, i32 %q, i32 %arm.t)    ; 3 route in
         call void @cqrt_rz_i32(i32 %arm.t, double %a)           ; 4 body
         call void @cqrt_rz_i32(i32 %arm.t, double %b)           ; 4 body
         call void @cqrt_cswap(i32 %flag, i32 %q, i32 %arm.t)    ; 5 route back
         call void @cqrt_free(i32 %arm.t)                        ; 6 clean free
%flag0 = call i32  @cq_template_icmp_sgt_i32_hl_inv(i32 %q, i32 5) ; 7 strip
         call void @cqrt_free(i32 %flag)                         ; 8 free flag
%m     = call i32  @cq_measure_si32(i32 %q)                      ; (lowered later)
```
Hard postconditions: `CHECK-NOT: _controlled`, `CHECK-NOT: phi i32`. Both cswaps
match the same `%[[F]]/%[[Q]]/%[[T]]`.

### 5b. If/else — `if (q>5) { rz(q,a); } else { rz(q,b); }`

Split routes **both** rails (then unbracketed under flag; else X-bracketed under
¬flag); arm bodies; join repeats the **identical** two cswap-pairs (adjoint of
split); free both rails; strip; free flag:

```
%flag   = call i32 @cq_template_icmp_sgt_i32_hl(i32 %q, i32 5)
%then.t = call i32 @cqrt_alloc_i32(i32 0)
%else.e = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_cswap(i32 %flag, i32 %q, i32 %then.t)      ; split: then (flag)
  call void @cqrt_x(i32 %flag)                               ; split: else (¬flag)
  call void @cqrt_cswap(i32 %flag, i32 %q, i32 %else.e)
  call void @cqrt_x(i32 %flag)
  call void @cqrt_rz_i32(i32 %then.t, double %a)             ; bodies
  call void @cqrt_rz_i32(i32 %else.e, double %b)
  call void @cqrt_cswap(i32 %flag, i32 %q, i32 %then.t)      ; join = adjoint split
  call void @cqrt_x(i32 %flag)
  call void @cqrt_cswap(i32 %flag, i32 %q, i32 %else.e)
  call void @cqrt_x(i32 %flag)
  call void @cqrt_free(i32 %then.t)
  call void @cqrt_free(i32 %else.e)
%flag0 = call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %q, i32 5)
  call void @cqrt_free(i32 %flag)
```

### 5c. §3c reject — `if (q>5) { q = q+3; }`

Pure-SSA: the arm's merge contribution is `%q1 = add i32 %q, 3` (value-changing),
and `%q` ∈ `condProvenance(icmp sgt %q,5)` → loud decline, lower nothing:
```
error: …: cq controlled lowering: arm rewrites a condition operand under quantum control
```
Contrast set that must **not** reject: phase op on the condition var (5a);
value op on a non-condition var (→ 4.2 decline, *different* string); a mere read
of the condition var.

---

## 6. Interlock hazards (Rule 10 / Rule 13 — the silent-miscompile surface)

These are the cross-module couplings where a green suite would still hide a bug;
each ships with a verification in §8.

1. **Dangling work-list pointers.** `taint.PhiCalls` / `taint.Tainted` are
   collected at `propagate` time and **iterated later** by `lowerRotations` /
   `uncompute`. The emitter erases arm `cq_phi` and the merge phi → it **must
   scrub every erased instruction** from `taint.PhiCalls` and `taint.Tainted`, or
   `lowerRotations`/`uncompute` dereference freed memory (SIGSEGV on valid input).
2. **`uncompute` must add nothing for the region.** The routed rail and flag are
   **not** tainted-data terminals: their users include `cqrt_cswap` /
   `cq_template_*_hl_inv` / `cqrt_free`, so `isTerminalHandle`
   (`ChainWalk.cpp:84`) returns false and `uncompute` skips them; `q` is consumed
   by `cq_measure` so `computeFreePoint(q)` returns `Measured` (no free). **Net:
   the swap-route region must produce exactly two `cqrt_free` (rail + flag) — no
   third.** Verify by counting (§8).
3. **`br` polarity (Rule 9).** Gate arm is often the *false* successor; resolve
   arms by merge-phi incoming identity and set `ArmNegated`; the else `cqrt_x`
   bracket follows polarity. Adversarial: a successor-swapped diamond fixture.
4. **Width from suffix, not type.** `HandleWidth` is empty at emit time; read the
   `cq_phi`/`cq_theta` suffix. A wrong width mints a nonexistent symbol → link
   error (caught only at e2e/link, not `opt -verify`).
5. **Twin-pipeline drift.** `run()` and `runOnFunction()` are independent copies;
   the new step goes in **both** or unit-level callers silently diverge.
6. **Block lifetime under flatten.** Capture block identities *before* the first
   erase (`RegionFlatten`); 4.1 is single-region so the cross-region case is
   latent until 4.3 (decline nested meanwhile).
7. **`Rz` convention coupling.** Flag-strip correctness needs `Rz =
   diag(1,e^{iθ})` (`Rz|0⟩=|0⟩`). Trace-only bodies through the freeze; carry as a
   `bd remember` invariant for the real-body work (PRD §6).

---

## 7. Test-driven work-item sequence

Red-green per Rule 12: write the fixture first, watch it fail, implement
minimally. New `*.ll` fixtures are auto-discovered (`config.suffixes=['.ll']`,
`lit.cfg.py:10`); use the verbatim RUN lines
`; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s`
(+ the verify second-RUN line) for accepts and
`; RUN: not %cq-opt … -S %s 2>&1 | %filecheck %s` for declines. Land each
not-yet-green accept fixture with `; XFAIL: *` and remove the line when it
XPASSes — keeps `ctest` green mid-development.

| WI | Goal (observable) | Lands | Red→Green fixtures |
|---|---|---|---|
| **WI-1** | **Detection + §3c reject** (no emission). `detectControlRegions` recognizes the shapes; §3c clobber + all deferred shapes decline with precise strings; recognized phase regions decline *transitionally* (`"phase-arm swap-route emission pending"`) so nothing mis-lowers. | `ControlDetect`, `ArmClassify`, shared `diagnoseUnderControl`; retire `ControlStub`; CMake. | **green:** `control_swap_reject_clobber.ll` (§3c), `control_swap_reject_derived.ll` (cond `q+1>5`, arm rewrites `q` — transitive provenance), `control_swap_defer_valuearm.ll` (value op on non-cond var → 4.2 string, **not** §3c), `control_tainted_diag.ll` (still declines, criterion 3). **XFAIL:** the two accepts. |
| **WI-2** | **Emit diamond.** Remove the transitional decline for diamonds; wire `lowerControlRegions` into both orchestrator sites; retarget `RotationLowering` comments; taint-scrub. | `SwapRouteEmit`, `RegionFlatten`; `CQLoweringPass`/`RotationLowering` edits. | **green (un-XFAIL):** `control_swap_diamond.ll` (5a) + `control_swap_diamond_polarity.ll` (successor-swapped, Rule 9). |
| **WI-3** | **Emit if/else.** Two-arm detection + `cqrt_x` ¬flag bracket + dual rails. | `ControlDetect` (two-arm), `SwapRouteEmit` (bracket). | **green (un-XFAIL):** `control_swap_ifelse.ll` (5b). |
| **WI-4** | **e2e golden** (Rule 16, Rule 2 — the only layer that links + proves symbols resolve). | `tests/e2e/slice_control_phase_diamond.c` + `.expected.log` + explicit `add_test` (e2e is **not** auto-globbed). | **green:** `ctest -R e2e-slice-control-phase-diamond`. |
| **WI-5** | **Adversarial verification + docs + cleanup** (Rule 13). | §8 verification; doc cross-links; `bd remember`; remove residual XFAIL; graduate fixtures. | full `ctest` green; `gen_templates.py --check` clean (no ABI change). |

Each WI is one commit. WI-2 is the core-lowering change → **does not ship on a
green suite alone** (Rule 13); it clears only after §8.

---

## 8. Adversarial verification plan (Rule 13 — clears the core change)

A green suite does not clear `SwapRouteEmit`. Before committing WI-2/WI-3, clear
against statevector/trace reasoning:

1. **Statevector witness (diamond).** `(|0⟩+|1⟩)/√2 ⊗ |0⟩_f` →[route+Rz+route]
   `(|0⟩|0⟩_f + e^{iθ}|1⟩|1⟩_f)/√2` →[`icmp_inv`] `(|0⟩ + e^{iθ}|1⟩)/√2 ⊗ |0⟩_f`.
   Confirm the rail returns to `|0⟩` unconditionally and `q` is disentangled
   (interference-safe). Cross-check the if/else against
   `docs/design/rssa-swap-control/prototype_semantics.py` **Demo A** (the
   `swap_route_ifelse.ll` source intent matches it to 3e-16).
2. **No-spurious-free probe.** Adversarial fixture asserting **exactly two**
   `cqrt_free` for the diamond region (`CHECK-COUNT-2: @cqrt_free` + a guard) —
   proves `uncompute` added no third (hazard §6.2).
3. **Polarity probe.** Successor-swapped diamond lowers to the identical routed
   stream (arms resolved by SSA identity, not edge order).
4. **Transitive §3c probe.** `if (q+1 > 5) { q = q+3; }` rejects (condition reads
   `q` through a derived value); `if (q>5) { p = p+3; }` does **not** hit §3c (it
   defers to 4.2 with the value-arm string).
5. **Dephasing guard (negative).** Confirm 4.1 emits **no** `cqrt_copy_*` and
   **no** `_controlled` for a phase arm — method-B/copy on a phase arm dephases
   (verified P0 0.585→0.500); `CHECK-NOT` both.
6. **e2e trace diff** (WI-4) — the linking proof every symbol resolves and
   signature-matches.

---

## 9. Done criteria (maps PRD §4) — **all met; 4.1 closed 2026-06-10** (epic
closed `e4baa67`; §8 clearance `c3359d2`; derived-base addendum `9786cef`)

- [x] Diamond (5a) + if/else (5b) lower to the pinned routed streams;
      `CHECK-NOT: _controlled` and `CHECK-NOT: phi i32` green; `opt -verify`
      clean (second-RUN line).
- [x] Classical-condition `br`/if-else left byte-identical (passthrough fixtures
      stay green; `control_tainted_diag.ll` still declines).
- [x] §3c clobber emits the exact string with a source location; decline +
      derived-condition probes green; contrast cases do **not** false-reject.
- [x] Phase-arm e2e trace diffs clean against its golden
      (`slice_control_phase_diamond` + `slice_control_phase_ifelse_derived`).
- [x] §8 adversarial review clears `SwapRouteEmit` (statevector + no-spurious-free
      + dephasing guard), not just green tests.
- [x] Full `ctest` green; `gen_templates.py --check` clean (no 4.1 ABI change).

---

## 10. Reuse map (Rule 14 — every need resolves to an existing symbol)

| Need | Existing symbol (file:line) |
|---|---|
| Mint flag from tainted `icmp` (and `_hl_inv` strip) | `lowerCompareToFlag` (`CompareLowering.h:110`), `inverse=true` for the strip |
| Find control-feeding compares the data path left alone | `isDataPositionCompare` (`CompareLowering.h:77`) |
| Route in/out (Fredkin) | `ControlledSymbols::cswapFn` (`ControlledSymbols.h:90`) |
| ¬flag bracket | `ControlledSymbols::xFn` (`ControlledSymbols.h:81`) |
| `|0⟩` work rail | `WidthDispatch::allocFn` (`WidthDispatch.h:69`) |
| Clean rail/flag free | `WidthDispatch::freeFn` (`WidthDispatch.h:116`) |
| Verbatim arm `Rz` | `RotationLowering::emitRz(…,false,nullptr)` (`RotationLowering.h:61`) |
| ABI width from suffix / type | `WidthDispatch::abiWidthFor` (`WidthDispatch.h:47`) · `abiWidthFromType` (`OpcodeSupport.h:69`) |
| Loud decline (incl. §3c) | `diagnoseUnderControl` (promoted from `ControlStub.cpp:43-48`) |
| Q/C test for a condition | `taint.Tainted.count(cond)` (`TaintPropagation.h:51`) |
| Arg-1 angle exclusion (copy into `condProvenance`) | `TaintPropagation.cpp:145-151` |
| Free-point discipline (4.3 generalization) | `computeFreePoint` (`FreePoint.h:44`) |
| Reverse-play engine (4.2 / `cq_invert`) | `emitInverseChain` (`EmitInverse.h:67`) — **wired, not invoked in 4.1** |

Deliberately **not** used in 4.1: `_controlled` template family
(`controlledRotationFn`, etc. — §6a reserve, Rule 7 method-A dropped),
`cqrt_copy_<W>` (4.2 only ABI), `recoverForwardChain`/`ChainWalk` for arms (the
uncompute target is the verbatim forward stream; disjoint rails avoid the
single-register divergent-arm hazard).

---

## 11. Out of scope (declines wired in WI-1, implemented in later increments)

Value/permutation arms + `cqrt_copy_<W>` (**4.2**,
`swap_route_if_diamond_uncompute.ll` B-keep); nested control (**4.3**, activates
the block-lifetime hazard + `computeFreePoint` wiring); tainted `select`
(**4.4**); tainted `switch` (**4.5**); §6a control-in-place peephole; controlled
`return`/`break`; coherent `Ry` reuse. Each currently declines loudly — that is a
feature, not a gap (Prime Directive).
