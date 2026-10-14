// MergeRailDischarge.cpp — see header (bd test_C_libtooling-r2j3.32).

#include "MergeRailDischarge.h"
#include "MergeStreamPlan.h"     // MergePlan / planMerge

#include "EmitInverse.h"       // isInverseEmittable / emitInverseCall
#include "TaintPropagation.h"  // TaintSet
#include "WidthDispatch.h"     // freeFn

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

#include <utility>

using namespace llvm;

namespace cq {

namespace {

// Emit at the replay point: the M-C adjoints of %out (reverse order), the
// core's adjoint (the core reversed), the stream's own strip MOVED here (its
// flags stayed live and untouched across the window), and the free of %out.
// Returns {first emitted, the free}, or {null, null} with nothing emitted.
std::pair<Instruction *, Instruction *>
emitReplay(const MergePlan &P, TaintSet &taint, WidthDispatch &wd) {
  FunctionCallee FreeFn = wd.freeFn();
  if (!FreeFn)
    return {nullptr, nullptr};
  for (CallInst *G : P.InPlace)
    if (!isInverseEmittable(G))
      return {nullptr, nullptr};  // asked by planMerge; detect-before-mutate.
  // The group lands right after `Anchor`, which never moves: the last reader,
  // or — with no reader, when the replay point is the strip's own end — the
  // core's last instruction (the strip then moves past the core's adjoint).
  Instruction *Anchor = is_contained(P.Post, P.Last) ? P.Core.back() : P.Last;
  Instruction *At = P.Last->getNextNode();
  if (!At)
    return {nullptr, nullptr};
  IRBuilder<> B(At);
  for (CallInst *G : llvm::reverse(P.InPlace))
    emitInverseCall(B, G, wd, /*CurHandle=*/nullptr, &taint.SpineOps);
  for (CallInst *C : llvm::reverse(P.Core)) {
    if (P.SrcAllocs.count(C))
      continue;
    auto *K = cast<CallInst>(C->clone());
    B.Insert(K);
    taint.SpineOps.insert(K);
  }
  for (Instruction *I : P.Post)
    I->moveBefore(At);
  CallInst *Free = B.CreateCall(FreeFn, {P.Out});
  Free->setDebugLoc(P.Out->getDebugLoc());
  taint.SpineOps.insert(Free);
  return {Anchor->getNextNode(), Free};
}

}  // namespace

unsigned dischargeMergeRails(Function &F, TaintSet &taint, WidthDispatch &wd) {
  // Candidates in REVERSE program order, so an outer merge that reads an inner
  // one's rail as a copy source is replayed first and the inner replay then
  // follows it (LIFO, Bennett's reverse order).
  SmallVector<CallInst *, 8> Cands;
  for (BasicBlock &BB : F)
    for (Instruction &I : BB)
      if (auto *C = dyn_cast<CallInst>(&I))
        if (taint.ControlOwnedRails.count(C))
          Cands.push_back(C);
  DenseMap<const Instruction *, Instruction *> GroupEnd;
  unsigned N = 0;
  for (CallInst *Out : llvm::reverse(Cands)) {
    MergePlan P;
    if (!planMerge(Out, taint, GroupEnd, P))
      continue;  // left allocated: the pre-r2j3.32 disposition.
    auto [First, End] = emitReplay(P, taint, wd);
    if (!End)
      continue;
    for (Instruction *I = First; I; I = I->getNextNode()) {
      GroupEnd[I] = End;
      if (I == End)
        break;
    }
    ++N;
  }
  return N;
}

}  // namespace cq
