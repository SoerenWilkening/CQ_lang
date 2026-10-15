// ArmAngleHoist.cpp — see ArmAngleHoist.h (bd test_C_libtooling-dm7f.77).

#include "ArmAngleHoist.h"

#include "ArmAnalysis.h"       // isFrontEndThetaCall (the one named spelling)
#include "TaintPropagation.h"  // TaintSet

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/ValueTracking.h"  // isSafeToSpeculativelyExecute
#include "llvm/IR/CFG.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"

using namespace llvm;

namespace cq {

namespace {

bool isThetaCall(const Instruction &I) {
  return isFrontEndThetaCall(&I) && cast<CallInst>(I).arg_size() >= 2;
}

// The angle cone of the arm's one theta, or false when the arm is not exactly
// "one theta plus (H1)-(H3) instructions". `Cone` is in program order.
bool armAngleCone(BasicBlock *Arm, const TaintSet &Taint,
                  SmallVectorImpl<Instruction *> &Cone) {
  CallInst *T = nullptr;
  SmallVector<Instruction *, 8> Others;
  for (Instruction &I : *Arm) {
    if (I.isTerminator() || isa<DbgInfoIntrinsic>(I))
      continue;
    if (isThetaCall(I)) {
      if (T)
        return false;  // two gates: not this shape.
      T = cast<CallInst>(&I);
      continue;
    }
    if (isa<PHINode>(I) || Taint.Tainted.count(&I) ||
        !isSafeToSpeculativelyExecute(&I))
      return false;  // (H1)/(H2).
    Others.push_back(&I);
  }
  if (!T || Others.empty())
    return false;
  // (H3), asked backward from the angle: the cone is what the angle reaches
  // through in-arm operands, and it must be ALL of `Others`.
  SmallPtrSet<Instruction *, 8> InCone;
  SmallVector<Value *, 8> Work{T->getArgOperand(1)};
  while (!Work.empty()) {
    auto *I = dyn_cast<Instruction>(Work.pop_back_val());
    if (!I || I->getParent() != Arm || I == T || !InCone.insert(I).second)
      continue;
    for (Value *Op : I->operands())
      Work.push_back(Op);
  }
  for (Instruction *I : Others) {
    if (!InCone.count(I))
      return false;
    for (User *U : I->users()) {
      auto *UI = dyn_cast<Instruction>(U);
      if (!UI || (UI != T && !InCone.count(UI)))
        return false;
      if (UI == T && T->getArgOperand(0) == I)
        return false;  // read as the REGISTER, not the angle.
    }
  }
  Cone.assign(Others.begin(), Others.end());
  return true;
}

}  // namespace

bool hoistArmAngleCones(Module &M, const TaintSet &taint) {
  bool Changed = false;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      auto *Br = dyn_cast<BranchInst>(BB.getTerminator());
      if (!Br || !Br->isConditional() || !taint.Tainted.count(Br->getCondition()))
        continue;
      for (BasicBlock *Arm : successors(Br)) {
        if (Arm->getSinglePredecessor() != &BB)
          continue;
        SmallVector<Instruction *, 8> Cone;
        if (!armAngleCone(Arm, taint, Cone))
          continue;
        // Every operand from outside the arm is defined in a block dominating
        // the arm's sole predecessor or in it, so it dominates the branch.
        for (Instruction *I : Cone)
          I->moveBefore(Br);
        Changed = true;
      }
    }
  }
  return Changed;
}

}  // namespace cq
