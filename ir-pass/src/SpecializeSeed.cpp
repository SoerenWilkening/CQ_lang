// SpecializeSeed.cpp — the net-new param-root taint seed (C15 / C-Taint).

#include "SpecializeSeed.h"

#include "SpecializePlan.h"
#include "TaintPropagation.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Argument.h"
#include "llvm/IR/Function.h"

using namespace llvm;

namespace cq {

TaintSet seedClone(Function *Clone, SpecMask Mask) {
  // Seed each masked parameter. A classical pass-through param is NOT seeded.
  // bd r2j3.19: the forward closure is main's own drain (`propagateFromParams`),
  // not a plain def-use closure. A clone body runs main's control chain (bd
  // p3kd.7.8), so an inner lift site whose callee provably returns a classical
  // value must stay classical here, as `specCallResultPredictedClassical` leaves
  // it at module level; the plain closure tainted it and the chain built gates on
  // the integer before the inner drain could scrub it.
  SmallVector<Argument *, 8> Params;
  for (Argument &A : Clone->args())
    if (Mask & (SpecMask(1) << A.getArgNo()))
      Params.push_back(&A);
  TaintSet ct;
  propagateFromParams(ct, Params);
  return ct;
}

}  // namespace cq
