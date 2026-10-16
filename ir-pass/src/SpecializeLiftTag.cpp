// SpecializeLiftTag.cpp — see the header (bd test_C_libtooling-r2j3.37.1).

#include "SpecializeLiftTag.h"

#include "InPlaceQQ.h"          // kConsumeDstAttr
#include "SpecializeConsume.h"  // kConsumeAuxAttr
#include "SpecializeChainReach.h"  // chainReachSlots

#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"

using namespace llvm;

namespace cq {

const char kMsgLiftTailUnhoisted[] =
    "cq specialization: a lifted call overwrites a dead quantum argument, which "
    "is not lowered in place across the call";

void tagLiftSite(CallInst &CI, const TaintSet &) {
  Function *Callee = CI.getCalledFunction();
  if (!Callee || Callee->isDeclaration() || Callee->isIntrinsic() ||
      CI.getFunctionType() != Callee->getFunctionType())
    return;
  SmallPtrSet<const Function *, 8> Stack;
  const uint64_t Chain = tailhoist::chainReachSlots(*Callee, Stack);
  if (!Chain)
    return;
  LLVMContext &Ctx = CI.getContext();
  CI.setMetadata(kLiftTailOwedTag,
                 MDNode::get(Ctx, {ConstantAsMetadata::get(ConstantInt::get(
                                      Type::getInt64Ty(Ctx), Chain))}));
}

void stripForgedConsumeMarks(Module &M) {
  for (Function &F : M) {
    F.removeFnAttr(kConsumeDstAttr);
    F.removeFnAttr(kConsumeAuxAttr);
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        I.setMetadata(kLiftTailOwedTag, nullptr);
  }
}

}  // namespace cq
