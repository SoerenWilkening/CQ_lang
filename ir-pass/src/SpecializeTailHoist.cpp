// SpecializeTailHoist.cpp — see the header (bd test_C_libtooling-r2j3.37).

#include "SpecializeTailHoist.h"

#include "ArmAnalysis.h"        // isFrontEndThetaCall
#include "InPlaceQQ.h"          // isQQStemOpcode / qqDeadRecordBits
#include "SpecializeDetect.h"   // isProvenSpecSite
#include "SpecializeTailPlan.h"  // the return-chain plan
#include "TaintPropagation.h"   // TaintSet

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/AttributeMask.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Metadata.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/IR/Module.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/Local.h"

#include <map>
#include <memory>
#include <optional>
#include <vector>

using namespace llvm;

namespace cq {

const char kMsgLiftTailUnhoisted[] =
    "cq specialization: a lifted call overwrites a dead quantum argument, which "
    "is not lowered in place across the call";

using namespace tailhoist;

namespace {

// E2 AS STOCK IR CAN ANSWER IT: is the DEAD tainted `V` a user register's value
// that main's in-place rounds keep on that register's rail? A front-end
// `cq_theta` result; a φ the record proved one wire of such a chain (bit 1 on a
// φ is `singleWirePhiDeadAfter`); or an xor/add/sub whose own dead operand is
// one (`t ^= a; r = f(t, b)`: the first op converts onto `t`'s rail because its
// result lives on). A derived value (`t * 3`) is a temporary the spine returns to
// |0>, as the inlined op's operand would be: hoisting it would only trade the
// clone consumer the M-B plan reasons about for a template reader (measured:
// spec_accept_clone_two_components_both_discharged.ll leaked).
bool userRegisterValue(Value *V, const DominatorTree &DT, const LoopInfo &LI,
                       const TaintSet &taint, unsigned Depth = 0) {
  if (isFrontEndThetaCall(V) || isa<PHINode>(V))
    return true;  // a φ is asked only when the record called it dead (bit 1).
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || Depth > 16 || !isQQStemOpcode(BO->getOpcode()))
    return false;
  for (Value *X : BO->operands())
    if (taint.Tainted.count(X) && (qqDeadRecordBits(X, BO, DT, LI) & 1u) &&
        userRegisterValue(X, DT, LI, taint, Depth + 1))
      return true;
  return false;
}

// THE GATE (header): the chain parameters receiving a tainted operand that is
// DEAD at the call (`qqDeadRecordBits` bit 1) and a user register's value
// (`userRegisterValue`), bit i = argument i. `UnprovenPhi` collects the
// arguments the record calls a dead φ NOT provably one wire (bit 4): never
// hoisted; the backstop asks the exact E2 of them late.
uint64_t owes(CallInst &CI, const Plan &P, const TaintSet &taint,
              const DominatorTree &DT, const LoopInfo &LI,
              uint64_t *UnprovenPhi = nullptr) {
  if (!P.hoistable() || CI.isMustTailCall())
    return 0;
  SmallVector<unsigned, 4> Args;
  argNos(P, P.Root, Args);
  uint64_t Mask = 0;
  for (unsigned A : Args) {
    Value *V = CI.getArgOperand(A);
    if (A >= 64 || !taint.Tainted.count(V))
      continue;
    const unsigned Bits = qqDeadRecordBits(V, &CI, DT, LI);
    if ((Bits & 1u) && userRegisterValue(V, DT, LI, taint))
      Mask |= uint64_t(1) << A;
    else if ((Bits & 4u) && UnprovenPhi)
      *UnprovenPhi |= uint64_t(1) << A;
  }
  return Mask;
}

Value *emit(Planner &PL, Plan &P, int I, CallInst &Site, IRBuilder<> &B,
            unsigned &Leaves) {
  Node &Nd = P.N[I];
  switch (Nd.K) {
  case Node::Arg:
    return Site.getArgOperand(Nd.ArgNo);
  case Node::Const:
    return Nd.C;
  case Node::Leaf: {
    ++Leaves;
    Function *S = PL.srcFor(P, I);
    CallInst *NC = B.CreateCall(S, SmallVector<Value *, 8>(Site.args()));
    NC->setCallingConv(S->getCallingConv());
    return NC;
  }
  case Node::Op: {
    Value *L = emit(PL, P, Nd.L, Site, B, Leaves);
    Value *R = emit(PL, P, Nd.R, Site, B, Leaves);
    return B.CreateBinOp(Nd.Opc, L, R);
  }
  }
  return nullptr;
}

}  // namespace

bool hoistLiftedTailChains(Module &M, const TaintSet &taint, WidthDispatch &wd) {
  if (!kLiftTailHoistEnabled) {  // THE INTERIM (header): strip the tags only.
    for (Function &F : M)
      for (Instruction &I : instructions(F))
        I.setMetadata(kLiftTailOwedTag, nullptr);
    return false;
  }
  Planner PL;
  SmallVector<std::pair<CallInst *, Plan *>, 4> Sites;
  SmallPtrSet<Function *, 32> Before;  // `isProvenSpecSite` may declare.
  for (Function &F : M)
    Before.insert(&F);
  for (Function &F : M) {
    for (Instruction &I : instructions(F))  // only `specialize()` writes it (r2j3.22)
      I.setMetadata(kLiftTailOwedTag, nullptr);
    if (F.isDeclaration())
      continue;
    std::optional<DominatorTree> DT;
    std::optional<LoopInfo> LI;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        Function *Callee = CI ? CI->getCalledFunction() : nullptr;
        if (!Callee || Callee->isDeclaration() || Callee->isIntrinsic() ||
            CI->getFunctionType() != Callee->getFunctionType())
          continue;
        Plan *P = PL.planFor(Callee);
        if (!P || !P->hoistable())
          continue;
        if (!DT) {
          DT.emplace(F);
          LI.emplace(*DT);
        }
        if (owes(*CI, *P, taint, *DT, *LI) &&
            isProvenSpecSite(*CI, taint, wd))
          Sites.push_back({CI, P});
      }
  }
  for (Function &F : make_early_inc_range(M))
    if (!Before.count(&F) && F.isDeclaration() && F.use_empty())
      F.eraseFromParent();  // never leave a phantom declaration (n0ui).
  for (auto &[CI, P] : Sites) {
    IRBuilder<> B(CI);
    B.SetCurrentDebugLocation(CI->getDebugLoc());
    unsigned Leaves = 0;
    Value *V = emit(PL, *P, P->Root, *CI, B, Leaves);
    if (!Leaves && !wouldInstructionBeTriviallyDead(CI) && !effectFree(*P->F)) {
      Function *Z = PL.zeroSrc(*P->F);
      B.CreateCall(Z, SmallVector<Value *, 8>(CI->args()))
          ->setCallingConv(Z->getCallingConv());
    }
    CI->replaceAllUsesWith(V);
    if (P->N[P->Root].K == Node::Op)
      V->takeName(CI);  // never rename an argument the identity chain returns.
    CI->eraseFromParent();
  }
  return !Sites.empty();
}

void tagUnhoistedLiftTail(CallInst &CI, const TaintSet &taint) {
  Function *Callee = CI.getCalledFunction();
  if (!Callee || Callee->isDeclaration() || Callee->isIntrinsic() ||
      CI.getFunctionType() != Callee->getFunctionType())
    return;
  Planner PL;
  Plan *P = PL.planFor(Callee);
  if (!P || !P->hoistable())
    return;
  DominatorTree DT(*CI.getFunction());
  LoopInfo LI(DT);
  uint64_t Phi = 0, Chain = 0;
  const uint64_t Mask = owes(CI, *P, taint, DT, LI, &Phi);
  SmallVector<unsigned, 4> Args;
  argNos(*P, P->Root, Args);
  for (unsigned A : Args)
    if (A < 64)
      Chain |= uint64_t(1) << A;
  LLVMContext &Ctx = CI.getContext();
  auto K = [&](uint64_t X) {
    return ConstantAsMetadata::get(ConstantInt::get(Type::getInt64Ty(Ctx), X));
  };
  CI.setMetadata(kLiftTailOwedTag,
                 MDNode::get(Ctx, {K(Mask), K(Phi), K(Chain)}));
}

}  // namespace cq
