// LoopAccumulatorFacts.cpp — the CFG/SCEV questions the dead-accumulator
// postcondition (LoopAccumulatorDead.cpp) asks; contracts in LoopAccumulator.h
// (bd test_C_libtooling-01po.19.18.6 / .9 / .10, R11 rounds 1-2b).

#include "LoopAccumulator.h"

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"

using namespace llvm;

namespace cq {

// May an EARLIER trip's step have recorded the cell `G`'s target load reads?
// Fails closed (true) unless SCEV proves, for every step source cell read `S`,
// that ptr_G(k) == ptr_S(j) has no solution with j < k.
bool cellMayBeRecorded(const Value *Target, ArrayRef<const Value *> SrcCells,
                       const Loop *L, ScalarEvolution &SE) {
  auto *GL = dyn_cast<LoadInst>(Target);
  if (!GL || !L)
    return true;
  const SCEV *PG = SE.getSCEV(const_cast<Value *>(GL->getPointerOperand()));
  for (const Value *S : SrcCells) {
    auto *SL = dyn_cast<LoadInst>(S);
    if (!SL)
      return true;
    const SCEV *PS = SE.getSCEV(const_cast<Value *>(SL->getPointerOperand()));
    auto *AR = dyn_cast<SCEVAddRecExpr>(PS);
    if (!AR || AR->getLoop() != L || !AR->isAffine())
      return true;
    auto *Step = dyn_cast<SCEVConstant>(AR->getStepRecurrence(SE));
    auto *D = dyn_cast<SCEVConstant>(SE.getMinusSCEV(PS, PG));  // same trip
    if (!Step || !D || Step->getAPInt().isZero())
      return true;
    // ptr_S(j) == ptr_G(k)  <=>  (k - j) * step == D(k)  (D constant).
    int64_t St = Step->getAPInt().getSExtValue(), Dv = D->getAPInt().getSExtValue();
    if (Dv % St == 0 && Dv / St >= 1)
      return true;
  }
  return false;
}

// Does any use of array `A`'s address leave the load/store addressing the
// lineage can see (a call, a stored pointer, an integer cast)?
bool arrayEscapes(const Value *A) {
  SmallVector<const Value *, 8> W{A};
  SmallPtrSet<const Value *, 16> Seen;
  while (!W.empty()) {
    const Value *P = W.pop_back_val();
    if (!Seen.insert(P).second)
      continue;
    for (const User *U : P->users()) {
      if (isa<GetElementPtrInst>(U) || isa<BitCastInst>(U) ||
          isa<SelectInst>(U) || isa<PHINode>(U)) {
        W.push_back(U);
        continue;
      }
      if (auto *LD = dyn_cast<LoadInst>(U); LD && LD->getPointerOperand() == P)
        continue;
      if (auto *St = dyn_cast<StoreInst>(U); St && St->getPointerOperand() == P &&
                                             St->getValueOperand() != P)
        continue;
      if (auto *II = dyn_cast<IntrinsicInst>(U); II && II->isLifetimeStartOrEnd())
        continue;
      return true;
    }
  }
  return false;
}

// Does a path from one of `L`'s exits reach block `Mint` without passing an
// instruction in `Reads` (a read of the register)?
bool reachesAvoiding(const Loop *L, const BasicBlock *Mint,
                     const SmallPtrSetImpl<const Instruction *> &Reads) {
  SmallVector<BasicBlock *, 4> Exits;
  L->getExitBlocks(Exits);
  SmallVector<const BasicBlock *, 16> W(Exits.begin(), Exits.end());
  SmallPtrSet<const BasicBlock *, 16> Seen;
  while (!W.empty()) {
    const BasicBlock *B = W.pop_back_val();
    if (!Seen.insert(B).second)
      continue;
    if (B == Mint)
      return true;
    if (any_of(*B, [&](const Instruction &I) { return Reads.count(&I) != 0; }))
      continue;
    W.append(succ_begin(B), succ_end(B));
  }
  return false;
}

// R11 round 2b rA2b-F2 — contract in the header.
bool cellsDisjointAcrossEntries(const Value *Target,
                                ArrayRef<const Value *> SrcCells, const Loop *L,
                                ScalarEvolution &SE) {
  auto *GL = dyn_cast<LoadInst>(Target);
  const Loop *P = L ? L->getParentLoop() : nullptr;
  unsigned TC = L ? SE.getSmallConstantTripCount(L) : 0;
  if (!GL || !P || TC == 0)
    return false;
  // Peel `L`'s recurrence: the per-entry start (a recurrence over `P`) and the
  // in-loop stride; a value outside `L` is its own start, stride 0.
  auto split = [&](const SCEV *X, const SCEV *&Start, int64_t &Stride) {
    Stride = 0;
    Start = X;
    if (auto *AR = dyn_cast<SCEVAddRecExpr>(X); AR && AR->getLoop() == L) {
      auto *St = dyn_cast<SCEVConstant>(AR->getStepRecurrence(SE));
      if (!AR->isAffine() || !St)
        return false;
      Stride = St->getAPInt().getSExtValue();
      Start = AR->getStart();
    }
    return true;
  };
  const SCEV *GStart = nullptr, *SStart = nullptr;
  int64_t GStride = 0, SStride = 0;
  if (!split(SE.getSCEV(const_cast<Value *>(GL->getPointerOperand())), GStart,
             GStride))
    return false;
  for (const Value *S : SrcCells) {
    auto *SL = dyn_cast<LoadInst>(S);
    if (!SL || !split(SE.getSCEV(const_cast<Value *>(SL->getPointerOperand())),
                      SStart, SStride) ||
        SStride <= 0 || (GStride != 0 && GStride != SStride))
      return false;
    auto *PR = dyn_cast<SCEVAddRecExpr>(SStart);
    if (!PR || PR->getLoop() != P || !PR->isAffine())
      return false;
    auto *Sp = dyn_cast<SCEVConstant>(PR->getStepRecurrence(SE));
    auto *D = dyn_cast<SCEVConstant>(SE.getMinusSCEV(GStart, SStart));
    if (!Sp || !D)
      return false;
    // Entry e records [S(e), S(e) + SStride*(TC-1)]; a gate d >= 1 entries
    // later sits in G(e) + d*sp + [0, SStride*(TC-1)]. Disjoint for every
    // d >= 1 when sp > 0 and D + sp > SStride*(TC-1).
    int64_t SpV = Sp->getAPInt().getSExtValue();
    int64_t DV = D->getAPInt().getSExtValue();
    if (SpV <= 0 || DV + SpV <= SStride * int64_t(TC - 1))
      return false;
  }
  return true;
}

// Some path from `G` to a function exit reads `H` nowhere (never entering
// `Excl`).
// `Cut` is the register's mint block: reaching it re-mints the name, so the
// register `G` saw is dead there whatever the next entry reads (rA2b-F1).
bool deadAfter(Instruction *G, const SmallPtrSetImpl<const Instruction *> &Reads,
               const BasicBlock *Excl, const BasicBlock *Cut) {
  for (Instruction *I = G->getNextNode(); I; I = I->getNextNode())
    if (Reads.count(I))
      return false;
  SmallVector<BasicBlock *, 16> BW(succ_begin(G->getParent()),
                                   succ_end(G->getParent()));
  if (BW.empty())
    return true;
  SmallPtrSet<BasicBlock *, 16> BSeen;
  while (!BW.empty()) {
    BasicBlock *B = BW.pop_back_val();
    if (B == Excl || !BSeen.insert(B).second)
      continue;
    if (B == Cut)
      return true;
    if (any_of(*B, [&](Instruction &I) { return Reads.count(&I) != 0; }))
      continue;
    if (succ_empty(B))
      return true;
    BW.append(succ_begin(B), succ_end(B));
  }
  return false;
}

}  // namespace cq
