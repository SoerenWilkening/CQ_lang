// EmitInverse.cpp — see header. The per-call adjoint dispatch (PRD §2.3).
//
// Step 1 implements the two uncontrolled cases that need no symbol lookup: the
// rotation-negate case (re-emit the forward `cqrt_ry/rz_<W>` with a negated
// angle) and the self-adjoint involutions (`cqrt_x` / `cqrt_cswap`, emitted
// as-is). Template `_inv` (Step 2) and controlled `_controlled_inv` (Step 4)
// extend the dispatch below.

#include "EmitInverse.h"

#include "ControlledSymbols.h"
#include "WidthDispatch.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/Function.h"

using namespace llvm;

namespace cq {

Value *emitInverseCall(IRBuilder<> &B, CallInst *Forward, WidthDispatch &wd,
                       ControlledSymbols &csyms, Value *Flag) {
  (void)wd;     // Step 2 (template `_inv`) resolves widths via `wd`.
  (void)csyms;  // Step 4 (controlled `_controlled_inv`) mints via `csyms`.
  (void)Flag;   // Step 4 supplies the control flag; unused for Step-1 cases.

  Function *Callee = Forward ? Forward->getCalledFunction() : nullptr;
  if (!Callee)
    return nullptr;
  StringRef Name = Callee->getName();

  // Uncontrolled rotation: `cqrt_ry_<W>(h, θ)` / `cqrt_rz_<W>(h, θ)`. The
  // inverse is the SAME forward symbol with a negated angle — there is no
  // `cqrt_ry/rz_<W>_inv` symbol. Void / in-place: the "current handle" the next
  // reversed link consumes is the input handle (arg 0), threaded unchanged.
  if ((Name.starts_with("cqrt_ry_") || Name.starts_with("cqrt_rz_")) &&
      !Name.contains("_controlled") && Forward->arg_size() == 2) {
    Value *Handle = Forward->getArgOperand(0);
    Value *NegAngle = B.CreateFNeg(Forward->getArgOperand(1));
    CallInst *Inv = B.CreateCall(Callee, {Handle, NegAngle});
    if (DebugLoc DL = Forward->getDebugLoc())
      Inv->setDebugLoc(DL);
    return Handle;
  }

  // Self-adjoint involutions: `cqrt_x` / `cqrt_cswap` are their own inverse, so
  // emit AS-IS (no `_inv` lookup). Void; return the handle operand (arg 0) for
  // chain threading.
  if (Name == "cqrt_x" || Name == "cqrt_cswap") {
    SmallVector<Value *, 3> Args(Forward->args());
    CallInst *Inv = B.CreateCall(Callee, Args);
    if (DebugLoc DL = Forward->getDebugLoc())
      Inv->setDebugLoc(DL);
    return Forward->getArgOperand(0);
  }

  // Template `_inv` (Step 2) and controlled `_controlled_inv` (Step 4) are not
  // yet handled. The conservative Step-1 Uncomputation only feeds rotations, so
  // this is unreachable today; returning nullptr keeps it loud if it ever is.
  return nullptr;
}

void emitInverseChain(IRBuilder<> &B, ArrayRef<CallInst *> ForwardChain,
                      WidthDispatch &wd, ControlledSymbols &csyms, Value *Flag) {
  // Walk the chain in reverse program order: the adjoint of (g0 ∘ g1 ∘ … ∘ gN)
  // is (gN⁻¹ ∘ … ∘ g1⁻¹ ∘ g0⁻¹). Thread each produced SSA value forward (a
  // no-op for in-place rotations; the fresh template result once Step 2 lands).
  for (int i = (int)ForwardChain.size() - 1; i >= 0; --i)
    (void)emitInverseCall(B, ForwardChain[i], wd, csyms, Flag);
}

}  // namespace cq
