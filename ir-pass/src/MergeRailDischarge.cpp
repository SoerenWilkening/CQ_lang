// MergeRailDischarge.cpp — see header (bd test_C_libtooling-r2j3.32).

#include "MergeRailDischarge.h"
#include "MergeCarriedFence.h"   // fenceCarriedMergeLeaks (decision (b))
#include "MergeStreamGates.h"    // calleeName
#include "MergeStreamPlan.h"     // MergePlan / planMerge

#include "EmitInverse.h"       // isInverseEmittable / emitInverseCall
#include "TaintPropagation.h"  // TaintSet
#include "WidthDispatch.h"     // freeFn / xorcFn

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DepthFirstIterator.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

// Emit before `P.At`: the M-C adjoints of %out (reverse order), the replayed
// core reversed, the stream's own strip MOVED here (its flags stayed live and
// untouched across the window), the seed un-XOR of a preloaded rail, and the
// free of %out. Every instruction a later merge could read (the clones and the
// moved strip) is appended to `Group`; returns the free, or null with nothing
// emitted.
Instruction *emitReplay(const MergePlan &P, TaintSet &taint, WidthDispatch &wd,
                        SmallVectorImpl<Instruction *> &Group) {
  FunctionCallee FreeFn = wd.freeFn();
  FunctionCallee XorC;
  if (P.Seed) {
    StringRef W = calleeName(P.Out).drop_front(strlen("cqrt_alloc_"));
    XorC = wd.xorcFn(W);
    if (!XorC)
      return nullptr;
  }
  if (!FreeFn)
    return nullptr;
  for (CallInst *G : P.InPlace)
    if (!isInverseEmittable(G))
      return nullptr;  // asked by planMerge; detect-before-mutate.
  IRBuilder<> B(P.At);
  for (CallInst *G : llvm::reverse(P.InPlace))
    emitInverseCall(B, G, wd, /*CurHandle=*/nullptr, &taint.SpineOps);
  for (CallInst *C : llvm::reverse(P.Replay)) {
    auto *K = cast<CallInst>(C->clone());
    B.Insert(K);
    taint.SpineOps.insert(K);
    Group.push_back(K);
  }
  for (Instruction *I : P.Post) {
    I->moveBefore(P.At);
    Group.push_back(I);
  }
  if (P.Seed) {
    CallInst *X = B.CreateCall(XorC, {P.Out, P.Seed});
    X->setDebugLoc(P.Out->getDebugLoc());
    taint.SpineOps.insert(X);
  }
  CallInst *Free = B.CreateCall(FreeFn, {P.Out});
  Free->setDebugLoc(P.Out->getDebugLoc());
  taint.SpineOps.insert(Free);
  Group.push_back(Free);
  return Free;
}

}  // namespace

unsigned dischargeMergeRails(Function &F, TaintSet &taint, WidthDispatch &wd) {
  SmallVector<CallInst *, 8> Cands;
  for (BasicBlock &BB : F)
    for (Instruction &I : BB)
      if (auto *C = dyn_cast<CallInst>(&I))
        if (taint.ControlOwnedRails.count(C))
          Cands.push_back(C);
  if (Cands.empty())
    return 0;
  // The analyses are computed once: the stage moves and inserts instructions
  // but never changes the CFG.
  DominatorTree DT(F);
  PostDominatorTree PDT(F);
  LoopInfo LI(DT);
  // REVERSE DOMINANCE ORDER, so a merge that reads another's rail as a copy
  // source (it is dominated by that merge) is undone FIRST and the inner
  // replay then follows its whole group (LIFO, Bennett's reverse order).
  DenseMap<const BasicBlock *, unsigned> Pre;
  for (BasicBlock *BB : depth_first(&F.getEntryBlock()))
    Pre.try_emplace(BB, Pre.size());
  llvm::stable_sort(Cands, [&](CallInst *A, CallInst *B) {
    if (A->getParent() != B->getParent())
      return Pre.lookup(A->getParent()) > Pre.lookup(B->getParent());
    return B->comesBefore(A);
  });
  DenseMap<const Instruction *, Instruction *> GroupEnd;
  PlanContext Ctx{taint, DT, PDT, LI, GroupEnd};
  unsigned N = 0;
  SmallVector<CallInst *, 8> Left;
  for (CallInst *Out : Cands) {
    MergePlan P;
    SmallVector<Instruction *, 16> Group;
    Instruction *End = planMerge(Out, Ctx, P)
                           ? emitReplay(P, taint, wd, Group)
                           : nullptr;
    if (!End) {
      Left.push_back(Out);  // left allocated: the pre-r2j3.32 disposition.
      continue;
    }
    for (Instruction *I : Group)
      GroupEnd[I] = End;
    ++N;
  }
  // A LEFT loop-carried rail (through a header φ or a rail-bank cell) is an
  // accepted leak (decision (b), bd 8h7d.20) only while no gate its record can
  // precede — after the loop, or inside it on a later trip or later in the
  // same trip (bd r2j3.36) — acts non-diagonally on a register entangled with
  // it (the hazard set: MergeCarriedFence.h).
  fenceCarriedMergeLeaks(F, taint, Left, DT, LI);
  return N;
}

}  // namespace cq
