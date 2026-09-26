// EmitInverse.cpp — see header. The per-call adjoint dispatch (PRD §2.3).
//
// Two cases need no symbol lookup: the rotation-negate case (re-emit the forward
// `cqrt_ry/rz_<W>`, or since bd drbq its `_controlled` twin, with a negated
// angle — the control threads through unchanged) and the self-adjoint involutions
// (`cqrt_x` / `cqrt_cswap`, emitted as-is). The uncontrolled DATA TEMPLATE case
// emits the VOID `_unc` form (`cq_template_…_unc(out, src…)`) — the inverse STEP
// (zero the rail in place by recomputing `f` from the live sources), NOT the
// fresh-minting inverse OPERATION `_inv` (which frees a dirty rail = a hidden
// measurement, Rule 6/8; DD-2). Any other primitive is un-invertible → `false`
// (the loud-decline signal, PRD §2.12).

#include "EmitInverse.h"

#include "ChainWalk.h"  // isAbiQramStore — the shared frozen-ABI store shape (Rule 14)
                        // isBranchPhaseGate — the kickback-gate record (bd 3qlq F-L7-1)

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"

using namespace llvm;

namespace cq {

// WI-0 (§6.0): the compare-as-data flag producers `cq_template_icmp_*` /
// `cq_template_fcmp_*` are now part of the reversibilizable data-template family.
// The embedded compare `|a,b,c⟩ → |a,b, c ⊕ (a<b)⟩` is a self-inverse permutation;
// its void `_unc` recomputes-and-XORs the flag from the still-live sources, exactly
// like every other binary op's `_unc`. The `tools/opcode_table.yaml` compare grid
// now carries `unc_qq`/`unc_hl` (no `_lh` — a lhs-literal compare canonicalizes by
// predicate flip), so the generic mint path below resolves a real symbol, NOT a
// dangling one. Pre-WI-0 these were excluded and declined loudly; that exclusion is
// gone.

bool isInverseEmittable(const CallInst *Forward) {
  const Function *Callee = Forward ? Forward->getCalledFunction() : nullptr;
  if (!Callee)
    return false;
  // ---- THE BRANCH-PHASE (KICKBACK) GATE IS NOT INVERTIBLE, ASKED FIRST (bd
  // 3qlq Inc 1 part A, Rule-13 round-1 F-L7-1). Not "the recipe is unknown" — the
  // recipe is obvious and that is the problem: the negated-angle re-emit below
  // would produce `cqrt_rz_i1(f, -θ)`, which cancels the user's phase EXACTLY and
  // compiles the program to the identity. This gate is the ANSWER, not a step
  // toward one; nothing may adjoint it.
  //
  // DEFENCE IN DEPTH, stated exactly: at HEAD this arm cannot fire, because every
  // caller (`Uncomputation`'s terminal-group and interior-group pre-scans,
  // `BreakReversePlay`'s rail-gate pre-scan, `BennettWrap`'s forward-stream scan)
  // only ever asks about a gate `ChainWalk::isInPlaceGateOn` accepted, and that
  // predicate refuses this one first. It is written here because this function is
  // the CANONICAL accept set (see the header): a set that answers `true` about a
  // gate no caller may invert is a trap for the next caller, not a spare.
  if (isBranchPhaseGate(Forward))
    return false;
  StringRef Name = Callee->getName();
  // Uncontrolled rotation `cqrt_ry/rz_<W>(h, θ)` (arg_size 2): negated-angle
  // re-emit. The 3-arg controlled forms fail the arity/`_controlled` test.
  if ((Name.starts_with("cqrt_ry_") || Name.starts_with("cqrt_rz_")) &&
      !Name.contains("_controlled") && Forward->arg_size() == 2)
    return true;
  // CONTROLLED rotation `cqrt_{ry,rz}_<W>_controlled(f, h, θ)` (control-in-place
  // PRD §5, bd test_C_libtooling-drbq Inc 0): the SAME negated-angle recipe, with
  // the control threaded unchanged through arg 0 and the handle at arg 1. Sound
  // for both stems and for both branches of the flag: on `f=0` forward and
  // adjoint are each the identity, on `f=1` they are `R(θ)` and `R(-θ)`, so the
  // composition is the identity unconditionally — no assumption about the flag's
  // value is needed, which is why the control is a plain read-only thread rather
  // than something that must be re-derived.
  //
  // THREE FENCES, all load-bearing:
  //  * `ends_with("_controlled")`, NOT `contains` — the `_controlled_inv`
  //    spelling is a DIFFERENT, older family (the npu.6 MUX-EXCH prep-uncompute
  //    for Ry; the Phase-4 region-inversion reserve for Rz) whose adjoint is NOT
  //    "itself with -θ", and admitting it here would silently invert one symbol
  //    with another symbol's semantics.
  //  * VOID, and
  //  * arity EXACTLY 3 — the bd 1fim fence, verbatim: a hand-written non-void or
  //    off-arity same-named fake is a call this recipe cannot invert (it mints a
  //    rail the recipe never zeroes), and a bare prefix match would claim it.
  if ((Name.starts_with("cqrt_ry_") || Name.starts_with("cqrt_rz_")) &&
      Name.ends_with("_controlled") && Forward->getType()->isVoidTy() &&
      Forward->arg_size() == 3)
    return true;
  // Self-adjoint involutions: emitted as-is.
  if (Name == "cqrt_x" || Name == "cqrt_cswap")
    return true;
  // `cqrt_toffoli(l,r,g)` / `cqrt_cnot(l,g)` join the involution family (5po2 I2):
  // the compound-condition conjunction network a clone's controlled-return mux
  // mints (`g ^= l&r` / `g ^= l`) is captured FORWARD-ONLY into the Bennett
  // stream, and both are their own inverse — re-emitting the SAME call under the
  // still-live controls returns the ancilla to |0>. Controls are read-only; the
  // slots are control/data, so like `cqrt_cswap` they must never be fed a threaded
  // `CurHandle` (moot — every direct caller passes CurHandle=null). The EXACT arity
  // (3 / 2) is required — it fences the real VOID network gates from a synthetic
  // NON-void same-named fake (`lowering_uncompute_uninvertible.ll`'s 1-arg i32
  // `cqrt_cnot`), which stays un-invertible so the top-level uncompute still
  // declines. Top-level SAFE regardless: the real gates are void, never tainted,
  // never a data producer (`Uncomputation::isDataProducer`), so they never enter a
  // recovered whole-DAG chain — this only enables the clone Bennett reverse.
  if ((Name == "cqrt_toffoli" && Forward->arg_size() == 3) ||
      (Name == "cqrt_cnot" && Forward->arg_size() == 2))
    return true;
  // Phase 7.4 / issue dtzb, and since the M-C widening (bd 6uqc Inc 2a) ALSO the
  // top-level straight-line spine path: the in-place value rail self-update
  // `cqrt_xorc_<W>(h, imm)` / `cqrt_addc_<W>(h, imm)` (VOID, arg_size 2, arg0 =
  // the i32 handle, arg1 = the classical immediate). `xor` is self-inverse
  // (re-emit as is, like `cqrt_x`); `add` inverts by NEGATING the immediate (the
  // integer twin of the rotation-negate case). There is no `_controlled` / `_inv`
  // twin — both emitters mint only the void 2-arg gate. VOID is the load-bearing
  // fence (bd 1fim; the arity alone would admit a hand-written non-void
  // same-named fake, i.e. a rail-minting call this recipe cannot invert). The
  // synthetic `cqrt_cnot` uninvertible probe (lowering_uncompute_uninvertible.ll)
  // declines because its name fails the prefix test (it never reaches here).
  if ((Name.starts_with("cqrt_xorc_") || Name.starts_with("cqrt_addc_")) &&
      Forward->getType()->isVoidTy() && Forward->arg_size() == 2)
    return true;
  // Uncontrolled data template (incl. compares post-WI-0): its void `_unc` form.
  // The `_inv`/`_unc` twins and the `_controlled` forms are NOT re-invertible
  // here. A compare-as-data flag (`cq_template_icmp_*`/`fcmp_*`) IS now
  // reversibilizable — the §6.0 compare `_unc` grid recomputes-and-XORs from the
  // live sources, so it is no longer excluded.
  if (Name.starts_with("cq_template_") && !Name.contains("_controlled") &&
      !Name.ends_with("_inv") && !Name.ends_with("_unc"))
    return true;
  // Phase 7.5 QRAM load `cqrt_qram_load_<W>(arr, idx)` — an ordinary reversible
  // data producer (Toffoli-copy-out): inverted by its void `_unc` twin, the SAME
  // out-first slot convention as a data template. The `_unc` form ends `_unc` and
  // is excluded (never a forward link).
  if (Name.starts_with("cqrt_qram_load_") && !Name.ends_with("_unc"))
    return true;
  // Phase 7.5 QRAM store `cqrt_qram_store_<W>(arr, idx, val)` — a VOID in-place
  // mutation on the array handle (Inc 2): inverted by its void `_unc` twin, which
  // POPS the backend's per-store tape. UNLIKE every other `_unc` above, the store
  // `_unc` takes the SAME args (arr, idx, val), NOT out-first — a store mints no
  // rail to zero. The `_unc` forms are excluded (never a forward link).
  //
  // THE ARITY IS LOAD-BEARING, and asking `isAbiQramStore` is how it stays that way
  // (bd test_C_libtooling-1fim). This clause used to be a bare PREFIX match at ANY
  // arity while `ChainWalk::isInPlaceGateOn` demanded the frozen 3/4 — so an
  // off-ABI-arity store was invertible HERE and not an in-place gate THERE. Because
  // the store `_unc` is the one same-args (not out-first) adjoint in this function,
  // an off-ABI store that MINTS a value got an adjoint naming only its operands: the
  // minted rail was never zeroed, and the spine still freed the register the store
  // read. MEASURED silent — `opt` rc=0, `opt -verify` clean, and stage 2b reports
  // "2 verified, 0 violation(s)" on the broken module
  // (`lowering_reject_uncompute_offabi_qram_store.ll`). Do NOT re-spell the arity
  // test here; that re-spelling IS the bug.
  if (isAbiQramStore(Forward))
    return true;
  // Phase 6.3 transitive: a call to a specialization CLONE `@__cq_q_<callee>_<mask>`
  // (a Bennett-wrapped reversible body `|x⟩|0⟩ → |x⟩|f(x)⟩`) is inverted by its
  // void `_unc` twin `@__cq_q_..._unc(out, args…)` (`out ^= f(args)` zeroes the
  // out rail and restores the borrowed inputs). The twin is synthesized by the
  // specializer BEFORE the enclosing clone's wrap reverses this call, so the
  // symbol resolves to a real definition (DD-2 nested-wrap; the two clone bodies'
  // `cloneTaint` sets stay disjoint, so no gate is double-adjointed). The twin
  // itself ends `_unc` and is excluded — it is never a forward link.
  if (Name.starts_with("__cq_q_") && !Name.ends_with("_unc"))
    return true;

  // Phase 6 (5po2): the 4.4 controlled-XOR copy `cqrt_copy_<W>_controlled(ctrl,
  // src, dst)` is self-inverse — XOR applied twice is identity — so a clone body
  // that lifts a tainted `select` (`out = ctrl ? src : 0`) reverses it by
  // re-emitting the SAME call under the still-live flag, zeroing the `dst` (out)
  // rail before free. The uncontrolled Bennett copy-out `cqrt_copy_<W>` (no
  // `_controlled` suffix) is deliberately NOT a forward link (it copies the
  // escaping basis value out; it is never reversed) and is excluded by the suffix.
  if (Name.starts_with("cqrt_copy_") && Name.ends_with("_controlled"))
    return true;

  return false;
}

bool emitInverseCall(IRBuilder<> &B, CallInst *Forward, WidthDispatch &wd,
                     Value *CurHandle,
                     SpineOpSet *Rec) {
  (void)wd;  // width is recovered from the forward call's own type; no lookup.

  // M-A Inc 1 (bd test_C_libtooling-6uqc): record EVERY adjoint minted here into
  // the caller's spine-op set, so the late live-record guard can tell a re-emitted
  // SELF-INVERSE gate from a forward one (they are the same call — see
  // EmitInverse.h). One helper, applied at every return-true site, so a new
  // inversion recipe cannot forget to record (Rule 14).
  auto minted = [Rec](CallInst *Inv) {
    if (Rec)
      Rec->insert(Inv);
    return true;
  };

  // Single ACCEPT gate (Rule 14): the branches below are guaranteed-reachable
  // refinements of this predicate. An un-invertible primitive returns the
  // loud-decline signal here; the driver pre-scans with the SAME predicate, so
  // emit and decline can never drift.
  if (!isInverseEmittable(Forward))
    return false;
  Function *Callee = Forward->getCalledFunction();
  StringRef Name = Callee->getName();

  // Uncontrolled rotation: `cqrt_ry_<W>(h, θ)` / `cqrt_rz_<W>(h, θ)`. The
  // inverse is the SAME forward symbol with a negated angle — there is no
  // `cqrt_ry/rz_<W>_inv` symbol. Void / in-place: it acts on this gate's handle
  // (a threaded `CurHandle` for a Phase-7 relabeled register, else forward arg 0).
  if ((Name.starts_with("cqrt_ry_") || Name.starts_with("cqrt_rz_")) &&
      !Name.contains("_controlled") && Forward->arg_size() == 2) {
    Value *Handle = CurHandle ? CurHandle : Forward->getArgOperand(0);
    Value *NegAngle = B.CreateFNeg(Forward->getArgOperand(1));
    CallInst *Inv = B.CreateCall(Callee, {Handle, NegAngle});
    if (DebugLoc DL = Forward->getDebugLoc())
      Inv->setDebugLoc(DL);
    return minted(Inv);
  }

  // CONTROLLED rotation: `cqrt_{ry,rz}_<W>_controlled(f, h, θ)` → the SAME
  // symbol with a negated angle. Slot discipline (control-in-place PRD §5):
  // arg 0 is the CONTROL and is threaded VERBATIM — a `CurHandle` relabel is a
  // statement about the register this gate acts on, which here is arg 1, so
  // feeding it into arg 0 would put a data rail in the flag slot (the
  // verify-clean wrong-unitary the `cqrt_cswap` guard below warns about, one
  // slot over). arg 2 is the classical angle.
  if ((Name.starts_with("cqrt_ry_") || Name.starts_with("cqrt_rz_")) &&
      Name.ends_with("_controlled") && Forward->arg_size() == 3) {
    Value *Ctrl = Forward->getArgOperand(0);
    Value *Handle = CurHandle ? CurHandle : Forward->getArgOperand(1);
    Value *NegAngle = B.CreateFNeg(Forward->getArgOperand(2));
    CallInst *Inv = B.CreateCall(Callee, {Ctrl, Handle, NegAngle});
    if (DebugLoc DL = Forward->getDebugLoc())
      Inv->setDebugLoc(DL);
    return minted(Inv);
  }

  // Phase 7.4 / issue dtzb in-place value rail self-update (reachable only via
  // the 7.4 break whole-loop reverse-play). `cqrt_xorc_<W>(h, imm)` is self-inverse
  // → re-emit AS-IS (like `cqrt_x`, but it carries the immediate). `cqrt_addc_<W>
  // (h, imm)` inverts by NEGATING the immediate (`CreateNeg` — the integer twin of
  // the rotation `CreateFNeg`). Void / in-place on the arg-0 handle (a threaded
  // `CurHandle` relabels it for a Phase-7 caller; `emitInverseChain` passes null).
  if ((Name.starts_with("cqrt_xorc_") || Name.starts_with("cqrt_addc_")) &&
      Forward->arg_size() == 2) {
    Value *Handle = CurHandle ? CurHandle : Forward->getArgOperand(0);
    Value *Imm = Forward->getArgOperand(1);
    if (Name.starts_with("cqrt_addc_"))
      Imm = B.CreateNeg(Imm);  // add(-imm) is the adjoint of add(imm).
    CallInst *Inv = B.CreateCall(Callee, {Handle, Imm});
    if (DebugLoc DL = Forward->getDebugLoc())
      Inv->setDebugLoc(DL);
    return minted(Inv);
  }

  // Self-adjoint involutions: `cqrt_x` / `cqrt_cswap` are their own inverse, so
  // emit AS-IS (no `_inv` lookup). Void / in-place.
  //
  // GUARD — the swap-route seam (PRD Part II §8.5): `CurHandle` is threaded
  // into Args[0], and for `cqrt_cswap(flag, a, b)` arg 0 is the FLAG slot, not
  // a data operand. NEVER feed route cswaps through a threaded chain
  // (`emitInverseChain` passes CurHandle=nullptr, so this guard is moot for the
  // uncompute driver) — a rail handle in the flag slot is a verify-clean WRONG
  // UNITARY. The emitter that routes brackets its R† route cswaps itself via
  // `emitRoute` (cswap is self-inverse) and hands this spine the BODY CHAIN
  // only. ⚠ THE VALUE-ARM EMITTER IS NOT IT (bd test_C_libtooling-3qlq Inc 2,
  // round-1 fix): `emitValueRegion` emits no route at all — it hoists the chain
  // and merges with two controlled copies — so do not read this guard as being
  // about it. ⚠ AND AS OF THE INC-2 REBASE ONTO THE LANDED INC 1 (2026-09-06)
  // THERE IS EXACTLY ONE ROUTING EMITTER LEFT, so read this sentence in the
  // singular: Inc 1 DELETED `NestedRouteEmit` (the 4.3 depth-2 PHASE nest) and
  // took the 4.5 PHASE switch (`SwitchRouteEmit`) off the route onto the
  // kickback, and Inc 2 took the value path off it, leaving the 7.2 abort park
  // (`AbortParkEmit`) as the sole `emitRoute` caller — MEASURED,
  // `grep -rn 'emitRoute(' ir-pass/src ir-pass/include` = the definition, the
  // declaration and ONE call site, `AbortParkEmit.cpp:396`. So this guard now
  // guards exactly the park.
  //
  // The 4.4 controlled-XOR copy `cqrt_copy_<W>_controlled(ctrl, src, dst)` joins
  // this involution family (5po2): re-emitting the SAME call under the still-live
  // flag XOR-copies `src` into `dst` a second time, zeroing `dst`. Like
  // `cqrt_cswap`, its arg 0 is the FLAG/ctrl slot, so `CurHandle` must never be
  // threaded into it — moot for the uncompute driver (`emitInverseChain` passes
  // CurHandle=nullptr), the only caller that reaches a controlled copy.
  // `cqrt_toffoli`/`cqrt_cnot` (5po2 I2) join this involution family: the
  // compound-condition conjunction network minted forward-only in a clone's
  // controlled-return mux is self-inverse (re-emit as-is under the live controls,
  // zeroing the ancilla). Arg 0 is a control slot — never fed `CurHandle` (moot;
  // the uncompute driver passes null).
  if (Name == "cqrt_x" || Name == "cqrt_cswap" || Name == "cqrt_toffoli" ||
      Name == "cqrt_cnot" ||
      (Name.starts_with("cqrt_copy_") && Name.ends_with("_controlled"))) {
    SmallVector<Value *, 3> Args(Forward->args());
    if (CurHandle && !Args.empty())
      Args[0] = CurHandle;
    CallInst *Inv = B.CreateCall(Callee, Args);
    if (DebugLoc DL = Forward->getDebugLoc())
      Inv->setDebugLoc(DL);
    return minted(Inv);
  }

  // Uncontrolled data template `cq_template_<op>_<W>[_hl|_lh]` (incl. compares
  // post-WI-0, §6.0) → its VOID `_unc` form. DD-3 slot convention: `out` (the
  // forward call's OWN result handle — the rail to zero) is arg 0, then the
  // forward operands in their ORIGINAL order. The `_unc` FunctionType is
  // `void(out_ty, <forward param types…>)`, matching the generated stub (e.g.
  // forward `_hl(i32 h, iN lit)` → `_hl_unc(i32 out, i32 h, iN lit)`; a compare
  // `icmp_slt_i32_hl(i32 h, i32 lit)` → `icmp_slt_i32_hl_unc(i32 out, i32 h, i32
  // lit)`). The void uncompute reads the live sources directly and mints nothing
  // — there is no handle to thread, so `CurHandle` is ignored here (it only
  // relabels in-place gates for Phase 7).
  if (Name.starts_with("cq_template_") && !Name.contains("_controlled") &&
      !Name.ends_with("_inv") && !Name.ends_with("_unc")) {
    SmallVector<Value *, 4> Args;
    SmallVector<Type *, 4> ParamTys;
    Args.push_back(Forward);              // out = the rail to zero in place.
    ParamTys.push_back(Forward->getType());
    for (Value *Op : Forward->args()) {   // forward operands, original order.
      Args.push_back(Op);
      ParamTys.push_back(Op->getType());
    }
    FunctionType *FT =
        FunctionType::get(Type::getVoidTy(Forward->getContext()), ParamTys,
                          /*isVarArg=*/false);
    FunctionCallee Unc =
        Forward->getModule()->getOrInsertFunction((Name + "_unc").str(), FT);
    CallInst *UncCall = B.CreateCall(Unc, Args);
    if (DebugLoc DL = Forward->getDebugLoc())
      UncCall->setDebugLoc(DL);
    return minted(UncCall);
  }

  // Phase 7.5 QRAM load `cqrt_qram_load_<W>(arr, idx)` → its void `_unc` twin
  // `cqrt_qram_load_<W>_unc(out, arr, idx)`. SAME out-first slot convention as the
  // data-template case: `out` (this load's OWN result handle — the dead value rail
  // to zero) is arg 0, then the forward operands (arr, idx) in order. The `_unc`
  // un-copies `out` back to |0> using the (preserved) cell; the borrowed inputs
  // (the classical array handle, the still-live index) are untouched. The minted
  // FunctionType `void(i32 out, i32 arr, i32 idx)` matches the hand-written runtime
  // body (cq_runtime.c) and WidthDispatch::qramLoadUncFn. `CurHandle` is ignored.
  if (Name.starts_with("cqrt_qram_load_") && !Name.ends_with("_unc")) {
    SmallVector<Value *, 4> Args;
    SmallVector<Type *, 4> ParamTys;
    Args.push_back(Forward);              // out = the rail to zero in place.
    ParamTys.push_back(Forward->getType());
    for (Value *Op : Forward->args()) {   // forward operands (arr, idx), in order.
      Args.push_back(Op);
      ParamTys.push_back(Op->getType());
    }
    FunctionType *FT =
        FunctionType::get(Type::getVoidTy(Forward->getContext()), ParamTys,
                          /*isVarArg=*/false);
    FunctionCallee Unc =
        Forward->getModule()->getOrInsertFunction((Name + "_unc").str(), FT);
    CallInst *UncCall = B.CreateCall(Unc, Args);
    if (DebugLoc DL = Forward->getDebugLoc())
      UncCall->setDebugLoc(DL);
    return minted(UncCall);
  }

  // Phase 7.5 QRAM store `cqrt_qram_store_<W>(arr, idx, val)` → its void `_unc`
  // twin `cqrt_qram_store_<W>_unc(arr, idx, val)`. UNLIKE the data-template / load
  // cases, the store `_unc` takes the SAME args in the SAME order (NOT out-first):
  // a store is a void in-place mutation that mints NO rail to zero, so there is no
  // `out` handle to prepend. The `_unc` body POPS the backend's per-store tape,
  // restoring the cell's old value (the IR pass owns only that the `_unc` twins
  // fire in strict reverse program order — LIFO — §2.8(ii)). The minted
  // FunctionType `void(i32 arr, i32 idx, i32 val)` matches the hand-written
  // runtime body and WidthDispatch::qramStoreUncFn. `CurHandle` is ignored.
  if (isAbiQramStore(Forward)) {
    SmallVector<Value *, 3> Args(Forward->args());  // (arr, idx, val), as-is.
    SmallVector<Type *, 3> ParamTys;
    for (Value *Op : Forward->args())
      ParamTys.push_back(Op->getType());
    FunctionType *FT =
        FunctionType::get(Type::getVoidTy(Forward->getContext()), ParamTys,
                          /*isVarArg=*/false);
    FunctionCallee Unc =
        Forward->getModule()->getOrInsertFunction((Name + "_unc").str(), FT);
    CallInst *UncCall = B.CreateCall(Unc, Args);
    if (DebugLoc DL = Forward->getDebugLoc())
      UncCall->setDebugLoc(DL);
    return minted(UncCall);
  }

  // Phase 6.3 transitive: a specialization CLONE call `@__cq_q_<callee>_<mask>`
  // → its void `_unc` twin `@__cq_q_..._unc(out, args…)`. Slot convention mirrors
  // the data-template case: `out` (this forward call's OWN result handle — the
  // entangled rail to zero) is arg 0, then the forward operands in their original
  // order. The twin runs `out ^= f(args)`, zeroing `out` (it held `f(args)`) and
  // leaving the borrowed inputs pristine. Its FunctionType is
  // `void(i32 out, <forward arg types…>)`, matching the specializer-synthesized
  // body, so `getOrInsertFunction` resolves the existing definition (never a
  // dangling decl — the twin is synthesized first, depth-first). `CurHandle` is
  // ignored: the twin reads the live sources and mints nothing.
  if (Name.starts_with("__cq_q_") && !Name.ends_with("_unc")) {
    SmallVector<Value *, 4> Args;
    SmallVector<Type *, 4> ParamTys;
    Args.push_back(Forward);              // out = the rail to zero in place.
    ParamTys.push_back(Forward->getType());
    for (Value *Op : Forward->args()) {   // forward operands, original order.
      Args.push_back(Op);
      ParamTys.push_back(Op->getType());
    }
    FunctionType *FT =
        FunctionType::get(Type::getVoidTy(Forward->getContext()), ParamTys,
                          /*isVarArg=*/false);
    FunctionCallee Unc =
        Forward->getModule()->getOrInsertFunction((Name + "_unc").str(), FT);
    CallInst *UncCall = B.CreateCall(Unc, Args);
    if (DebugLoc DL = Forward->getDebugLoc())
      UncCall->setDebugLoc(DL);
    return minted(UncCall);
  }

  // Any other primitive (incl. every remaining controlled callee — the
  // controlled DATA templates, and the `_controlled_inv` rotation reserve) has
  // no correct in-place uncompute → the un-invertible signal. The driver
  // declines LOUDLY rather than emitting a half-reversed chain (PRD §2.12,
  // Rule 1).
  return false;
}

bool emitInverseChain(IRBuilder<> &B, ArrayRef<CallInst *> ForwardChain,
                      WidthDispatch &wd,
                      SpineOpSet *Rec) {
  // Walk the chain in reverse program order: the adjoint of (g0 ∘ g1 ∘ … ∘ gN)
  // is (gN⁻¹ ∘ … ∘ g1⁻¹ ∘ g0⁻¹). Each void `_unc` reads its forward operands in
  // place; SSA dominance guarantees those sources are still live (a leaf is
  // zeroed before the source it reads — the source's own `_unc` follows). No
  // handle is threaded (the void uncompute mints nothing). Returns `true` iff
  // EVERY link inverted; `false` on the first un-invertible link (AND of all
  // per-link results) so the caller owns the loud decline (DD-1).
  bool OK = true;
  for (int i = (int)ForwardChain.size() - 1; i >= 0; --i)
    OK = emitInverseCall(B, ForwardChain[i], wd, /*CurHandle=*/nullptr, Rec) &&
         OK;
  return OK;
}

}  // namespace cq
