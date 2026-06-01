// ControlledSubstitution.cpp — see header. Collection-before-mutation (§1.6):
// emit each controlled Rz, RAUW the `cq_phi` result to its in-place handle,
// and erase — over a snapshot of `region.Shadow` so the walk is stable.

#include "ControlledSubstitution.h"

#include "ControlPlan.h"
#include "RotationLowering.h"  // emitRz
#include "TaintPropagation.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

void substituteControlled(ControlRegion &region, WidthDispatch &wd,
                          TaintSet &taint) {
  Value *Flag = region.Flag;
  if (!Flag)
    return;  // ControlFlag failed/wasn't run; nothing safe to substitute.

  SmallVector<Instruction *, 4> ToErase;
  for (Instruction *S : region.Shadow) {
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

  for (Instruction *I : ToErase)
    I->eraseFromParent();
}

}  // namespace cq
