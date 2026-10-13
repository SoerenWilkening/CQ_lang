// ClassicalRailMuxFence.cpp — bd dm7f.15 / dm7f.16. See ClassicalRailMuxFence.h
// (the contract) and ClassicalRailMux.h (why the contract is what it is).

#include "ClassicalRailMuxFence.h"

#include "ChainWalk.h"                  // railOf (the one "which rail a gate writes")
#include "ClassicalRailMux.h"           // terminatorIsClassical
#include "ControlShape.h"               // blockOnCycle
#include "OpcodeSupport.h"              // abiWidthFromType
#include "PredMuxFlatten.h"             // isMuxableType
#include "TaintPropagation.h"
#include "TaintedControlDependence.h"   // isTaintedBranchTerminator
#include "WireWalk.h"                   // findNonDiagonalWireGate

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/CFG.h"  // isPotentiallyReachable
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

// The LEAF records `R` may name: its tainted value operands, collected THROUGH
// nested router-shaped operands into `Routers`. False when an operand is outside
// the leaf vocabulary (a load, an argument, an on-cycle value, a non-router
// phi/select): the caller then declines as before.
bool collectLeaves(Instruction *R, const TaintSet &taint,
                   SmallPtrSetImpl<Instruction *> &Routers,
                   SmallVectorImpl<Instruction *> &Leaves) {
  if (!Routers.insert(R).second)
    return true;
  for (Value *V : classicalRailMuxValues(R)) {
    if (!taint.Tainted.count(V))
      continue;  // a classical arm: materialized by the rewrite.
    auto *I = dyn_cast<Instruction>(V);
    if (!I)
      return false;
    if (isa<SelectInst>(I) || isa<PHINode>(I)) {
      if (!isClassicalRailMuxShape(I, taint) ||
          !collectLeaves(I, taint, Routers, Leaves))
        return false;
      continue;
    }
    if (isa<LoadInst>(I) || blockOnCycle(I->getParent()))
      return false;
    Leaves.push_back(I);
  }
  return true;
}

// Does a loop-owned in-place rail op (`InPlaceRailOps`, bd dtzb) read `Leaf` or a
// router over it? WireWalk does not cross that op (WireWalk.cpp, the measured
// non-crossing), so it is asked here over the leaf's routed closure.
bool routedWireHasInPlaceRailOp(Instruction *Leaf, const TaintSet &taint) {
  SmallVector<Value *, 8> Work{Leaf};
  SmallPtrSet<Value *, 8> Seen;
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (!Seen.insert(V).second)
      continue;
    for (User *U : V->users()) {
      if (auto *BO = dyn_cast<BinaryOperator>(U))
        if (taint.InPlaceRailOps.count(BO))
          return true;
      if (isa<PHINode>(U))
        Work.push_back(U);
      else if (auto *S = dyn_cast<SelectInst>(U); S && S->getCondition() != V)
        Work.push_back(S);
    }
  }
  return false;
}

// (R4) Does emitted call `CI` WRITE alias member `A`?
bool callWrites(CallInst *CI, const Value *A) {
  if (railOf(CI) == A)
    return true;  // an in-place gate (or `cqrt_x`) on the member
  const Function *Callee = CI->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  if (N.starts_with("cqrt_cswap"))
    return true;  // the abort park routes its operands in place
  return N.starts_with("cqrt_copy_") && CI->arg_size() >= 2 &&
         CI->getArgOperand(CI->arg_size() - 1) == A;  // a copy INTO the member
}

}  // namespace

bool terminatorIsClassical(const Instruction *T, const TaintSet &taint) {
  if (!isa<BranchInst>(T) && !isa<SwitchInst>(T))
    return false;
  return !isTaintedBranchTerminator(T, taint);
}

bool isClassicalRailMuxShape(Instruction *I, const TaintSet &taint) {
  Type *Ty = I->getType();
  if (!isMuxableType(Ty) || abiWidthFromType(Ty).empty())
    return false;
  if (blockOnCycle(I->getParent()))
    return false;  // the loop-rail machinery's population, not this file's.
  if (auto *S = dyn_cast<SelectInst>(I)) {
    if (taint.Tainted.count(S->getCondition()))
      return false;  // a tainted-condition select is ControlDetect's.
    return taint.Tainted.count(S->getTrueValue()) ||
           taint.Tainted.count(S->getFalseValue());
  }
  auto *P = dyn_cast<PHINode>(I);
  if (!P || P->getNumIncomingValues() < 2)
    return false;
  if (taint.PromotedCarriedHandlePhis.count(P))
    return false;  // bd zujr's own accept, never re-owned here.
  bool AnyTainted = false;
  for (unsigned K = 0, N = P->getNumIncomingValues(); K < N; ++K) {
    if (!terminatorIsClassical(P->getIncomingBlock(K)->getTerminator(), taint))
      return false;
    if (taint.Tainted.count(P->getIncomingValue(K)))
      AnyTainted = true;
  }
  return AnyTainted;
}

SmallVector<Value *, 4> classicalRailMuxValues(Instruction *R) {
  SmallVector<Value *, 4> Ops;
  if (auto *S = dyn_cast<SelectInst>(R)) {
    Ops.push_back(S->getTrueValue());
    Ops.push_back(S->getFalseValue());
  } else {
    for (Value *V : cast<PHINode>(R)->incoming_values())
      Ops.push_back(V);
  }
  return Ops;
}

bool classicalRailMuxFenceHolds(Instruction *Mux, const TaintSet &taint) {
  if (!isClassicalRailMuxShape(Mux, taint))
    return false;
  SmallPtrSet<Instruction *, 4> Routers;
  SmallVector<Instruction *, 4> Leaves;
  if (!collectLeaves(Mux, taint, Routers, Leaves) || Leaves.empty())
    return false;
  // (R1) no non-diagonal gate, no loop-owned in-place op, on any leaf wire.
  for (Instruction *L : Leaves) {
    Value *Seed = L;
    if (findNonDiagonalWireGate(Seed, /*CrossValueRouting=*/true,
                                /*EmitPoint=*/nullptr, /*DT=*/nullptr, &taint))
      return false;
    if (routedWireHasInPlaceRailOp(L, taint))
      return false;
  }
  // (R2) every router user only reads it.
  for (Instruction *R : Routers)
    for (User *U : R->users()) {
      if (isa<CallInst>(U) || isa<BinaryOperator>(U) || isa<UnaryOperator>(U) ||
          isa<CmpInst>(U) || isa<CastInst>(U) || isa<ReturnInst>(U))
        continue;
      if (auto *S = dyn_cast<SelectInst>(U))
        if (S->getCondition() != R && isClassicalRailMuxShape(S, taint))
          continue;
      if (auto *P = dyn_cast<PHINode>(U);
          P && isClassicalRailMuxShape(P, taint))
        continue;
      return false;
    }
  // The ALIAS SET: the router closure plus each leaf's wire names.
  SmallPtrSet<const CallInst *, 16> ThetaSet(taint.ThetaCalls.begin(),
                                              taint.ThetaCalls.end());
  SmallPtrSet<const CallInst *, 8> MeasureSet(taint.MeasureCalls.begin(),
                                               taint.MeasureCalls.end());
  SmallPtrSet<Value *, 8> Alias;
  for (Instruction *R : Routers)
    Alias.insert(R);
  for (Instruction *L : Leaves)
    for (Value *V = L;;) {
      Alias.insert(V);
      auto *CI = dyn_cast<CallInst>(V);
      if (!CI || !ThetaSet.count(CI) || CI->arg_size() < 1 ||
          !taint.Tainted.count(CI->getArgOperand(0)))
        break;
      V = CI->getArgOperand(0);
    }
  // (R4) no emitted write on a member; collect (R3)'s measurements and reads.
  SmallVector<Instruction *, 4> Measures, Reads;
  for (Value *A : Alias)
    for (User *U : A->users()) {
      auto *UI = dyn_cast<Instruction>(U);
      if (!UI || Routers.count(UI))
        continue;
      auto *CI = dyn_cast<CallInst>(UI);
      if (CI && callWrites(CI, A))
        return false;
      if (CI && MeasureSet.count(CI))
        Measures.push_back(UI);
      else
        Reads.push_back(UI);
    }
  // (R3) no measurement of a member reaches a non-measure read of one.
  if (!Measures.empty() && !Reads.empty()) {
    DominatorTree DT(*Mux->getFunction());
    for (Instruction *M : Measures)
      for (Instruction *U : Reads)
        if (isPotentiallyReachable(M, U, nullptr, &DT))
          return false;
  }
  return true;
}

}  // namespace cq
