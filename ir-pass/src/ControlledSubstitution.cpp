// ControlledSubstitution.cpp — see header. Collection-before-mutation (§1.6):
// emit each controlled Rz, RAUW the `cq_phi` result to its in-place handle,
// and erase — over a snapshot of `region.Shadow` so the walk is stable.

#include "ControlledSubstitution.h"

#include "ControlPlan.h"
#include "ControlledSymbols.h"  // xFn (¬flag bracket)
#include "RotationLowering.h"   // emitRz
#include "TaintPropagation.h"

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

// Substitute one arm's in-shadow `cq_phi` gate bodies with their controlled
// `cqrt_rz_<W>_controlled(flag, handle, angle)` forms. When `Negate` (the WP8
// false arm), wrap the whole arm in a self-inverse `cqrt_x` flag bracket so the
// gates fire on ¬flag: `X(flag)` before the first gate, the controlled gates,
// then `X(flag)` before the arm's terminator. The pair is self-inverse, so the
// flag is restored for the standard compare-uncompute downstream (§2.5/§2.9).
void substituteArm(ArrayRef<Instruction *> Shadow, Value *Flag, bool Negate,
                   BasicBlock *ArmBlock, WidthDispatch &wd, TaintSet &taint) {
  if (Shadow.empty())
    return;

  FunctionCallee X;
  if (Negate) {
    ControlledSymbols csyms(*ArmBlock->getModule(), wd);
    X = csyms.xFn();
    if (!X)
      return;  // unsupported — leave the gates for the verifier.
    // Leading `X(flag)` before the first gate body.
    IRBuilder<> B(Shadow.front());
    B.CreateCall(X, {Flag});
  }

  SmallVector<Instruction *, 4> ToErase;
  for (Instruction *S : Shadow) {
    auto *Phi = dyn_cast<CallInst>(S);
    if (!Phi)
      continue;
    Value *Handle = Phi->getArgOperand(0);  // the in-place gate-body handle.
    Value *Angle = Phi->getArgOperand(1);

    // Emit `cqrt_rz_<W>_controlled(flag, handle, angle)`. On unsupported width
    // `emitRz` diagnoses and returns false — leave the `cq_phi` standing for
    // the verifier (do NOT RAUW/erase a half-lowered op).
    if (!emitRz(Phi, Handle, Angle, wd, /*controlled=*/true, Flag))
      continue;

    // The controlled Rz mutated `Handle` in place; the `cq_phi` value is that
    // same handle. RAUW the result so the downstream merge `φ` sees the handle
    // (MergeDissolution then RAUWs the merge to it), and record the control
    // flag on the handle for any downstream controlled consumer (PRD §2.10).
    Phi->replaceAllUsesWith(Handle);
    taint.ControlFlag[Handle] = Flag;
    ToErase.push_back(Phi);
  }

  // Trailing `X(flag)` after the last gate (before the arm terminator), closing
  // the ¬flag bracket. Emitted before erasing so the arm still has its `br`.
  if (Negate && X)
    IRBuilder<>(ArmBlock->getTerminator()).CreateCall(X, {Flag});

  for (Instruction *I : ToErase)
    I->eraseFromParent();
}

}  // namespace

void substituteControlled(ControlRegion &region, WidthDispatch &wd,
                          TaintSet &taint) {
  Value *Flag = region.Flag;
  if (!Flag)
    return;  // ControlFlag failed/wasn't run; nothing safe to substitute.

  // The primary gate arm. Normally the TRUE successor (fires on `flag`), but a
  // swapped branch (`if (u != 5)` → `icmp eq; br eq, Merge, Arm`) puts it on the
  // FALSE successor, where the gates fire on ¬flag (`region.ArmNegated`) via the
  // self-inverse `cqrt_x` bracket.
  substituteArm(region.Shadow, Flag, /*Negate=*/region.ArmNegated, region.Arm,
                wd, taint);
  // WP8 symmetric: the false arm fires on ¬flag (a self-inverse cqrt_x bracket).
  if (region.ArmFalse)
    substituteArm(region.ShadowFalse, Flag, /*Negate=*/true, region.ArmFalse, wd,
                  taint);
}

}  // namespace cq
