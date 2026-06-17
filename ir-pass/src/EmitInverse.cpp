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

#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"

using namespace llvm;

namespace cq {

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
  // Uncontrolled data template: its void `_unc` form. The `_inv`/`_unc` twins
  // and the `_controlled` forms are NOT re-invertible here.
  if (Name.starts_with("cq_template_") && !Name.contains("_controlled") &&
      !Name.ends_with("_inv") && !Name.ends_with("_unc"))
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
  if (Name == "cqrt_x" || Name == "cqrt_cswap") {
    SmallVector<Value *, 3> Args(Forward->args());
    if (CurHandle && !Args.empty())
      Args[0] = CurHandle;
    CallInst *Inv = B.CreateCall(Callee, Args);
    if (DebugLoc DL = Forward->getDebugLoc())
      Inv->setDebugLoc(DL);
    return true;
  }

  // Uncontrolled data template `cq_template_<op>_<W>[_hl|_lh|_qq]` → its VOID
  // `_unc` form. DD-3 slot convention: `out` (the forward call's OWN result
  // handle — the rail to zero) is arg 0, then the forward operands in their
  // ORIGINAL order. The `_unc` FunctionType is `void(out_ty, <forward param
  // types…>)`, matching the generated stub (e.g. forward `_hl(i32 h, iN lit)` →
  // `_hl_unc(i32 out, i32 h, iN lit)`). The void uncompute reads the live
  // sources directly and mints nothing — there is no handle to thread, so
  // `CurHandle` is ignored here (it only relabels in-place gates for Phase 7).
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
