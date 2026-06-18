// SpecializeSeed.cpp — the net-new param-root taint seed (C15 / C-Taint).

#include "SpecializeSeed.h"

#include "SpecializePlan.h"
#include "TaintPropagation.h"

#include "llvm/IR/Argument.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

#include <vector>

using namespace llvm;

namespace cq {

TaintSet seedClone(Function *Clone, SpecMask Mask) {
  TaintSet ct;
  std::vector<Value *> Worklist;

  // Seed each masked parameter (the insert-then-push idiom, mirroring
  // `collectAndSeed`). A classical pass-through param is NOT seeded.
  for (Argument &A : Clone->args()) {
    if (!(Mask & (SpecMask(1) << A.getArgNo())))
      continue;
    if (ct.Tainted.insert(&A).second)
      Worklist.push_back(&A);
  }

  // Forward propagation SCOPED to the clone body. The accepted body is pure
  // straight-line value code (no rotations → no arg-1-angle edge to skip, no
  // measure sink), so this is the plain transitive-user closure. Users live in
  // `Clone` (params are clone-local); the function-scope guard is defensive.
  while (!Worklist.empty()) {
    Value *V = Worklist.back();
    Worklist.pop_back();
    for (User *U : V->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I || I->getFunction() != Clone)
        continue;
      if (ct.Tainted.insert(I).second)
        Worklist.push_back(I);
    }
  }

  return ct;
}

}  // namespace cq
