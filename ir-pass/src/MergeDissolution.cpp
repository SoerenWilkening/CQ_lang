// MergeDissolution.cpp — see header. WP3 `[modified, original]` `br` case.
//
// The merge `φ[rotated_y, y]` has one incoming value per predecessor: the
// MODIFIED arm comes in from `region.Arm`; the ORIGINAL (in-place) handle
// comes in from `region.Pred` (the diamond predecessor's fall-through edge to
// the merge). The in-place handle is the original arm's value — RAUW the whole
// merge to it and erase. Classifying by predecessor edge (rather than by raw
// arm taint) is robust to the substitution RAUW having already rewritten the
// modified arm's value to the same handle (risk R2): the `region.Pred` edge is
// definitionally the unmodified path.

#include "MergeDissolution.h"

#include "ControlPlan.h"
#include "TaintPropagation.h"

#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

void dissolveMerge(ControlRegion &region, TaintSet &taint) {
  (void)taint;
  auto *Merge = dyn_cast_or_null<PHINode>(region.Merge);
  if (!Merge || !region.Pred)
    return;

  // The original/in-place handle is the value flowing in from the diamond
  // predecessor's direct edge to the merge (the "else fell straight through"
  // path). For the `[modified, original]` shape this is the register the
  // controlled gate mutated in place; the modified arm (from `region.Arm`) was
  // already RAUW'd to it by ControlledSubstitution.
  int PredIdx = Merge->getBasicBlockIndex(region.Pred);
  if (PredIdx < 0)
    return;  // not the expected diamond wiring; leave it for the verifier.
  Value *InPlace = Merge->getIncomingValue(PredIdx);

  Merge->replaceAllUsesWith(InPlace);
  Merge->eraseFromParent();
  region.Merge = nullptr;  // dissolved; linearization must not touch it again.
}

}  // namespace cq
