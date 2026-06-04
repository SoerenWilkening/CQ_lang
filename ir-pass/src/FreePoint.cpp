// FreePoint.cpp — see header. Step-1 basic single-block last-use computation,
// productionizing the prototype (`archive/prototype/cq_pass.cpp:305-329`).

#include "FreePoint.h"

#include "TaintPropagation.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"

using namespace llvm;

namespace cq {

FreePoint computeFreePoint(Value *Terminal, Function &F,
                           PostDominatorTree &PDT, const TaintSet &taint) {
  (void)F;      // Step 3 uses `F` for loud DiagnosticInfoUnsupported emission.
  (void)taint;  // Step 3 uses `taint` for the `cqrt_measure_` sink exclusion.

  // Collect the in-function instruction users. A `ret` operand escapes (the
  // handle outlives the function) → no free. Step 3 adds main / cq_invert /
  // unrecognized-escape and measure classification here.
  SmallVector<Instruction *, 8> Users;
  for (User *U : Terminal->users()) {
    auto *I = dyn_cast<Instruction>(U);
    if (!I)
      continue;
    if (isa<ReturnInst>(I))
      return {FreePointKind::Escaped, nullptr};
    Users.push_back(I);
  }
  if (Users.empty())
    return {FreePointKind::Escaped, nullptr};

  // Nearest common post-dominator of every user block — the earliest block that
  // is guaranteed reached after all uses. A null common post-dominator (a
  // non-reconverging CFG) becomes a loud diagnostic in Step 3; Step 1 skips it.
  BasicBlock *Common = Users[0]->getParent();
  for (size_t i = 1; i < Users.size(); ++i) {
    Common = PDT.findNearestCommonDominator(Common, Users[i]->getParent());
    if (!Common)
      return {FreePointKind::Escaped, nullptr};
  }

  // Latest in-block user → insert right after it; else after the block's
  // φ-nodes (`getFirstInsertionPt`). `getNextNode()` is non-null for any user
  // that is not a terminator (a rotation/template handle's last use never is).
  Instruction *Latest = nullptr;
  for (Instruction *U : Users)
    if (U->getParent() == Common && (!Latest || Latest->comesBefore(U)))
      Latest = U;

  Instruction *At =
      Latest ? Latest->getNextNode() : &*Common->getFirstInsertionPt();
  if (!At)
    return {FreePointKind::Escaped, nullptr};
  return {FreePointKind::Insert, At};
}

}  // namespace cq
