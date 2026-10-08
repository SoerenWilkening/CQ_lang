// LiftedCallReads.cpp — see LiftedCallReads.h (bd test_C_libtooling-r2j3.6).

#include "LiftedCallReads.h"

#include "DeadValueLiveness.h"  // isRecordedDeadSlot
#include "SpecializeDetect.h"   // isProvenSpecSite (bd r2j3.6 R3-2)
#include "Specialization.h"     // shouldSpecialize
#include "TaintPropagation.h"

#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

bool liftedCallReads(const Instruction &I, const TaintSet &taint,
                     const SpecPlan *Plan, SmallVectorImpl<Value *> &Reads,
                     WidthDispatch *WouldLift) {
  const auto *CI = dyn_cast<CallInst>(&I);
  if (!CI)
    return false;
  const Function *Callee = CI->getCalledFunction();
  const bool Lifted =
      (Plan && shouldSpecialize(CI, *Plan)) ||
      (Callee && taint.SpecHandleArgMask.count(Callee)) ||
      (WouldLift &&
       isProvenSpecSite(*const_cast<CallInst *>(CI), taint, *WouldLift));
  if (!Lifted)
    return false;
  const size_t Before = Reads.size();
  for (unsigned A = 0, E = CI->arg_size(); A != E; ++A) {
    Value *Op = CI->getArgOperand(A);
    if (taint.Tainted.count(Op) && !isRecordedDeadSlot(*CI, A, taint))
      Reads.push_back(Op);
  }
  return Reads.size() != Before;
}

}  // namespace cq
