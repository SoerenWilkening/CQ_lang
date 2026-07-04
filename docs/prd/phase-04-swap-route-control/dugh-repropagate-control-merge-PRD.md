# dugh — Re-propagate the untainted control-merge `%out` (Phase 4×6)

**Status:** in progress (branch `dugh-repropagate-control-merge`)
**Owner-directed accept-more-physics follow-on from `8mld` (2026-07-03).**
Requires its own Rule-13 clearance (core-lowering: a second propagation round).

## 1. Problem

A tainted-condition control region can produce a merge value that is
**DATA-untainted yet QUANTUM by control-dependence**:

```c
int y = 5;  if (q > 3) y = f(a);   // f pure, classical args
z = y + 1;  measure(z);            // y is {f(a) | q>3, 5 | q<=3}, entangled with q
```

Two accept paths build such an untainted-merge superposition register `%out`
(`cqrt_alloc_<W>`, an i32 handle) and RAUW the merge phi to it:

* **6.5 classical-call arm** — `emitClassicalCallArmRegion` (ClassicalCallArmEmit.cpp)
* **4.5 switch data-mux** — `emitSwitchDataMuxRegion` (SwitchDataMuxEmit.cpp)

Both emit **after** `propagate` (data-flow taint from `cq_theta`) has already
classified `%out`'s downstream consumers as **classical**, and there is **no
second propagation round**. So `z = y + 1`, `cq_phi(y, θ)`, and a local-array
(Shadow) store `arr[i] = y` — all physics-valid quantum-onward flows — read
`%out` (an i32 qubit handle) as if it were a value.

`8mld` made this a **safe interim decline**: the merge-out escape gate in
`classifyClassicalCallArm` (ArmClassify.cpp) and `proveSwitchDataMux`
(SwitchArmProve.cpp) requires every merge user to be a measure sink or an i32
`ret`, else loud-decline `control flow under quantum control`. This bead
**accepts** the onward-quantum (A2) subset.

## 2. Root cause & fix shape

Taint tracks **data-flow**, not **control-dependence**. The control emitter is
the thing that knows the merge is quantum, but it fires after
`propagate`/`declineTaintEscapes`/`lowerOps` and does not re-run them.

**Fix:** after `lowerControlRegions`, run a **second propagation round** seeded
from the untainted-merge out-rails, then re-run the existing taint-gated guards.
Because `%out` and its onward derivations become properly tainted, *every*
existing taint-gated net does the right thing with zero new per-carrier logic
(Rule 14 reuse — the `8mld` gate could not enumerate carriers, which is why it
was conservative):

1. **Incremental forward propagate** from `taint.UntaintedMergeRails` (the two
   emitters' `%out`). Skips already-lowered runtime scaffolding
   (`cqrt_*` / `cq_template_*` — the emitted controlled-copy calls, so uncompute
   parity with the tainted-merge case is preserved) and obeys the same
   measure-sink / arg-1-angle exclusions as the first `propagate`.
2. **`declineReClassifiedControl`** — decline any surviving tainted-condition
   `br`/`switch`/`select` on `%out` (a *new* control region on the merge — out
   of dugh scope; over-decline, Prime Directive). This closes the one hole the
   escape net does not (a tainted `br`/`switch` condition is "ControlDetect's",
   skipped by `declineTaintEscapes`; a tainted-condition `select` is skipped by
   `declineClassicalMuxes`).
3. **`declineTaintEscapes`** (re-run) — the onward **classical** escapes
   (opaque-ptr store `kMsgStore`, opaque call `kMsgUnknownCallee`, non-i32 `ret`
   `kMsgNonI32Return`) decline via the existing precise net. Onward arith is
   carved (owned by ArithLowering), onward `cq_phi` is carved (intrinsic), onward
   local-array store is carved by `qramCarveVerdict` (owned by lowerShadowMemory).
4. **`declineStaleRecordOps`** (re-run) — a stale-record hazard in the onward
   flow declines (mirrors the `declineLiftedStaleRecordOps` re-sweep precedent).

Then the **existing** downstream stages run once and pick up the newly-tainted
onward ops: `lowerIOSinks`/`lowerQramReads`/`lowerShadowMemory` (onward
QRAM/Shadow/IO), `declineClassicalMuxes` (a classical-condition mux over a
derived `%out` value), `lowerRotations` (+ `declineTaintedAngle`, which now
fires because a `%out`-derived rotation **angle** is tainted — the former sole
job of the merge-out gate's angle backstop), `lowerOps`, `lowerMeasures`,
`uncompute` (`%out` is a `ControlOwnedRail` → left allocated, its onward add
rail / shadow stores reverse via the standard Phase-5 spine).

**`diagnose(DS_Error)` calls `exit(1)`** (LLVMContext), so an emit-then-decline
of an A1 escape exits the process before the transiently-broken IR
(`ret iN <i32 handle>`) is ever verified — a clean loud decline, not a SIGABRT.

## 3. Scope boundary (unchanged from 8mld)

* **(A1) stays declined forever** — opaque/classical-ptr store, opaque classical
  call, non-i32 raw return (physics/ABI-forced; non-i32 return is `jx32`).
* **(A2) decline → accept** — onward QUANTUM flow (arith / phase / local-array
  Shadow store) that stays quantum until an eventual measure or i32 `ret`.
* A **new** tainted-condition `br`/`switch`/`select` on `%out` (nested onward
  control) declines (over-decline; future capability).

## 4. Implementation

| File | Change |
|---|---|
| `ir-pass/include/TaintPropagation.h` | Add `SmallPtrSet<Value*> UntaintedMergeRails` to `TaintSet`; declare `repropagateControlMerges`. |
| `ir-pass/src/TaintPropagation.cpp` | Extract `propagateWorklist` (shared core, `skipRuntimeCalls` flag); add anon `declineReClassifiedControl`; add public `repropagateControlMerges`. |
| `ir-pass/src/ClassicalCallArmEmit.cpp` | `taint.UntaintedMergeRails.insert(Out)`. |
| `ir-pass/src/SwitchDataMuxEmit.cpp` | `taint.UntaintedMergeRails.insert(Out)`. |
| `ir-pass/src/ArmClassify.cpp` | Remove the `8mld` merge-out escape gate (decline now post-emit). |
| `ir-pass/src/SwitchArmProve.cpp` | Remove the `8mld` merge-out escape gate. |
| `ir-pass/src/CQLoweringPass.cpp` | Call `repropagateControlMerges` right after `lowerControlRegions`, in **both** entry points (twin-pipeline parity). |

## 5. Fixtures (red-green, Rule 12)

**New accept** (the A2 targets): classical-call arm + {arith, phase,
local-array store} → measure; switch data-mux + arith → measure (converted from
`reject_switch_datamux_datause`).

**Reject message re-route** (A1 stays declined, more-precise message):
`reject_escape_leak` → `kMsgStore`; `reject_nonI32_ret` (both paths) →
`kMsgNonI32Return`; `reject_switch_datamux_spoof_sink` → `kMsgUnknownCallee`.
`reject_switch_datamux_angle` keeps `control flow under quantum control` (now via
`declineReClassifiedControl` on the tainted-condition select).

**New reject** (hole close): classical-call arm + onward tainted `br` on `%out`
→ `control flow under quantum control`.

## 6. Rule-13 adversarial findings (both FOUND by the sweep, FIXED, regression-pinned)

The second-propagation round re-taints `%out`, which then flows into stages that
were previously gated out — surfacing two latent defects:

**D1 — flatten block-lifetime crash (SIGSEGV on valid input, Rule-1).** `%out`
feeding a DOWNSTREAM classical `if`-diamond (`if (q>k) y=f(a); if (cc) y=cq_phi(y,θ);
measure y`) makes the merge block end in `br i1 %cc`, with the downstream join's phi
listing the merge block as a predecessor. `flattenRegion` splices that terminator
into `Pred` and erases the merge block — but a PHI incoming BLOCK is not an
operand-use, so the erase left a dangling `<badref>` predecessor → the
`declineClassicalMuxes` one-register lift dereferenced the freed block → crash. Pre-
dugh this shape declined at the retired merge-out gate, so the bug was latent. FIX:
`Pred->replaceSuccessorsPhiUsesWith(Merge, Pred)` before the erase, in ALL THREE
flatten functions (`flattenRegion` / `flattenSwitchRegion` / `flattenRegionTree` —
the last had the same latent bug for a nested-phase merge feeding a downstream if).
Pinned: `control_classical_call_arm_accept_onward_phase_downstream_if.ll`.

**D2 — spec-clone silent miscompile (verify-clean wrong unitary).** `%out` passed
to a ROUND-1 Phase-6 specialization clone whose per-arg MASK was frozen at
`detectSpecializations` (step 5, pre-emit) when the merge was untainted → the clone
treats that arg as classical and lowers the body's `base+exp` as
`cq_template_add_<W>_hl(base, exp)` with `exp` a LITERAL, reading the `%out` qubit
handle's tag instead of its superposed value. The `declineTaintEscapes`
`shouldSpecialize` carve let it through. FIX: `declineReseedIntoSpecCalls` — decline
a pending-clone call reading any round-2 reseed value, BEFORE the carve. Verified the
intrinsic/libm/cast/arith/phase/QRAM/IO lowerings are NOT affected (they run after
repropagate and re-taint correctly); specialization is the unique frozen-plan hole.
Pinned: `control_classical_call_arm_reject_onward_spec_call.ll`.

**D3 — by-ref-math frozen-plan crash (broken module on valid input, a D2 sibling).**
Found by the round-2 sweep on the D1+D2-fixed build. By-ref math (frexp/modf/remquo)
is another frozen-plan lowering: `lowerByRefMath` (g387) runs at step 2 and rewrites
only TAINTED by-ref math to `@cq_byref_*` markers; a round-1-untainted call is left
raw. dugh re-taints a `%out`-derived arg (`sitofp %out → frexp`), but `lowerByRefMath`
already ran and the `declineTaintEscapes` `isByRefMathCall` carve waves it through —
leaving an un-lowered `frexp(i32 <handle>, ptr)` (its `double` arg is the lowered i32
handle) → a type-mismatched broken module. FIX: generalized D2's guard to
`declineReseedIntoFrozenPlan`, declining a call that is EITHER a `shouldSpecialize`
candidate OR an `isByRefMathCall` when it reads a reseed value. Verified the other
frozen-plan candidates are safe: g7ip (`lowerByRefInline`) INLINES its producer (no
carved call) and declines cleanly; a loop reading `%out` declines; direct-libm
(cbrt), curated intrinsics (bswap), casts, arith, phase, QRAM, and I/O all run AFTER
repropagate and re-taint correctly. Pinned:
`control_classical_call_arm_reject_onward_byref_math.ll`.

## 7. Done criteria

Both lit fixtures + ≥1 e2e golden smoke; full ctest green; `gen_templates.py
--check` clean (no new ABI); independent Rule-13 adversarial clearance (two defects
found + fixed above; re-cleared on the fixed build).
