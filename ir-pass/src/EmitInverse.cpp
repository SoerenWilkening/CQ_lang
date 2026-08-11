// EmitInverse.cpp — see header. The per-call adjoint dispatch (PRD §2.3).
//
// Two cases need no symbol lookup: the rotation-negate case (re-emit the forward
// `cqrt_ry/rz_<W>` with a negated angle) and the self-adjoint involutions
// (`cqrt_x` / `cqrt_cswap`, emitted as-is). The uncontrolled DATA TEMPLATE case
// emits the VOID `_unc` form (`cq_template_…_unc(out, src…)`) — the inverse STEP
// (zero the rail in place by recomputing `f` from the live sources), NOT the
// fresh-minting inverse OPERATION `_inv` (which frees a dirty rail = a hidden
// measurement, Rule 6/8; DD-2). Any other primitive is un-invertible → `false`
// (the loud-decline signal, PRD §2.12).

#include "EmitInverse.h"

#include "ChainWalk.h"  // isAbiQramStore — the shared frozen-ABI store shape (Rule 14)

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
  StringRef Name = Callee->getName();
  // Uncontrolled rotation `cqrt_ry/rz_<W>(h, θ)` (arg_size 2): negated-angle
  // re-emit. The 3-arg controlled forms fail the arity/`_controlled` test.
  if ((Name.starts_with("cqrt_ry_") || Name.starts_with("cqrt_rz_")) &&
      !Name.contains("_controlled") && Forward->arg_size() == 2)
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
  // Phase 7.4 / issue dtzb (reachable ONLY via the 7.4 break whole-loop
  // reverse-play, y05j.2): the in-place value rail self-update
  // `cqrt_xorc_<W>(h, imm)` / `cqrt_addc_<W>(h, imm)` (arg_size 2, arg0 = the i32
  // handle, arg1 = the classical immediate). `xor` is self-inverse (re-emit as
  // is, like `cqrt_x`); `add` inverts by NEGATING the immediate (the integer twin
  // of the rotation-negate case). There is no `_controlled` / `_inv` twin — the
  // dtzb forward strategy mints only the void 2-arg gate. The `arg_size() == 2` is a
  // defensive arity check on the xorc/addc branch; the synthetic `cqrt_cnot`
  // uninvertible probe (lowering_uncompute_uninvertible.ll) declines because its
  // name fails the `cqrt_xorc_`/`cqrt_addc_` prefix test (it never reaches here),
  // NOT because of the arity gate.
  if ((Name.starts_with("cqrt_xorc_") || Name.starts_with("cqrt_addc_")) &&
      Forward->arg_size() == 2)
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
                     Value *CurHandle) {
  (void)wd;  // width is recovered from the forward call's own type; no lookup.

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
    return true;
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
    return true;
  }

  // Self-adjoint involutions: `cqrt_x` / `cqrt_cswap` are their own inverse, so
  // emit AS-IS (no `_inv` lookup). Void / in-place.
  //
  // GUARD — the swap-route seam (PRD Part II §8.5): `CurHandle` is threaded
  // into Args[0], and for `cqrt_cswap(flag, a, b)` arg 0 is the FLAG slot, not
  // a data operand. NEVER feed route cswaps through a threaded chain
  // (`emitInverseChain` passes CurHandle=nullptr, so this guard is moot for the
  // uncompute driver) — a rail handle in the flag slot is a verify-clean WRONG
  // UNITARY. The swap-route value-arm emitter brackets its R† route cswaps
  // itself via `emitRoute` (cswap is self-inverse) and hands this spine the
  // BODY CHAIN only.
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
    return true;
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
    return true;
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
    return true;
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
    return true;
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
    return true;
  }

  // Any other primitive (incl. controlled callees) has no correct in-place
  // uncompute → the un-invertible signal. The driver declines LOUDLY rather than
  // emitting a half-reversed chain (PRD §2.12, Rule 1).
  return false;
}

bool emitInverseChain(IRBuilder<> &B, ArrayRef<CallInst *> ForwardChain,
                      WidthDispatch &wd) {
  // Walk the chain in reverse program order: the adjoint of (g0 ∘ g1 ∘ … ∘ gN)
  // is (gN⁻¹ ∘ … ∘ g1⁻¹ ∘ g0⁻¹). Each void `_unc` reads its forward operands in
  // place; SSA dominance guarantees those sources are still live (a leaf is
  // zeroed before the source it reads — the source's own `_unc` follows). No
  // handle is threaded (the void uncompute mints nothing). Returns `true` iff
  // EVERY link inverted; `false` on the first un-invertible link (AND of all
  // per-link results) so the caller owns the loud decline (DD-1).
  bool OK = true;
  for (int i = (int)ForwardChain.size() - 1; i >= 0; --i)
    OK = emitInverseCall(B, ForwardChain[i], wd, /*CurHandle=*/nullptr) && OK;
  return OK;
}

}  // namespace cq
