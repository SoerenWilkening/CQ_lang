// MergeCarriedFenceFresh.cpp — see header (bd test_C_libtooling-r2j3.36).

#include "MergeCarriedFenceFresh.h"
#include "MergeStreamGates.h"  // calleeName / readsState / isRegister /
                               // handleAliases
#include "RailBankPromote.h"   // railBankOfPointer / bankStoreRailValue

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"

using namespace llvm;

namespace cq {

namespace {

bool isRuntime(StringRef N) {
  return N.starts_with("cqrt_") || N.starts_with("cq_template_");
}

bool isCarrier(const Value *U) {
  return isa<PHINode>(U) || isa<SelectInst>(U) || isa<CastInst>(U) ||
         isa<FreezeInst>(U);
}

// Is user `I` of a member of class `Cls` a COUPLING use (header)? A store is
// skipped only when `SkipStores`: the `handleAliases` class, whose memory
// clause has already refused every store but a proven bank park (header ⚠).
bool isCouplingUse(Instruction *I, const SmallPtrSetImpl<Value *> &Cls,
                   bool SkipStores, const TaintSet &taint) {
  if (Cls.count(I))
    return false;  // a carrier inside the class.
  if (isa<StoreInst>(I))
    return !SkipStores;
  if (auto *K = dyn_cast<CallInst>(I); K && isRuntime(calleeName(K))) {
    SmallVector<Value *, 4> H;
    carriedFenceHandlesOf(K, taint, H);
    return H.size() >= 2;
  }
  return true;  // a lifted / unknown call, a ret, a compare, …: fail closed.
}

// ALLOCATION freshness (header, first producer).
bool freshAlloc(CallInst *A, const Instruction *C, const TaintSet &taint,
                const DominatorTree &DT) {
  SmallPtrSet<Value *, 8> Cls;
  // The store skip below (`SkipStores`) is sound ONLY because this call has
  // already refused every store that is not a park into a proven rail bank
  // and put that bank's cell loads into `Cls` (reviewer A, R11 round 1).
  if (!handleAliases(A, taint, DT, Cls))
    return false;
  for (Value *M : Cls)
    for (User *U : M->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I)
        return false;
      if (isCouplingUse(I, Cls, /*SkipStores=*/true, taint) &&
          runsWithoutRedef(A, I, A) && runsWithoutRedef(I, C, A))
        return false;
    }
  return true;
}

// Clause (a), asked OVER RailBankPromote's one address-tree walk (Rule 14, no
// second spelling; owner ruling ruling-r2j336-round1-qs-2026-10-15 Q2): the
// walk itself, `forEachBankCellMemop`, is file-local (an anonymous namespace
// in RailBankPromote.cpp, so not linkable from here); its two exported
// wrappers are the hop into it — `railBankParkedRails(L)` yields every rail
// any store into L's bank parks, `railBankCellReadsOf(R)` every cell load of
// that bank. Each parked rail must be a `cqrt_alloc_*` mint whose every use is
// a park into this bank (directly or through one storage cast). Carve clause
// C1 makes every DIRECT user of the bank alloca a canonical cell address, a
// lifetime marker or the initializer; the initializer is refused here (only
// GEPs and lifetime markers pass), since it parks no fresh mint.
// RESIDUAL, stated: `railBankParkedRails` drops CONSTANT stores (uniqued
// literals, see its definition), so a constant cell store through a GEP is not
// seen; the pipeline declines it upstream (`declineNonHandleBankStores`).
// RETIREMENT TRIGGER: when the S4 lane exports `forEachBankCellMemop` from
// RailBankPromote.h, ask "every store parks a fresh mint" over it directly
// and drop the residual.
bool materializedBank(LoadInst *L, AllocaInst *B,
                      SmallVectorImpl<LoadInst *> &Loads) {
  for (User *U : B->users()) {
    if (isa<GetElementPtrInst>(U))
      continue;
    if (auto *II = dyn_cast<IntrinsicInst>(U); II && II->isLifetimeStartOrEnd())
      continue;
    return false;  // the initializer, or anything C1 did not admit.
  }
  SmallVector<Value *, 8> Parked;
  if (!railBankParkedRails(L, Parked) || Parked.empty())
    return false;
  auto isPark = [&](User *U) {
    auto *SI = dyn_cast<StoreInst>(U);
    return SI && railBankOfPointer(SI->getPointerOperand()) == B;
  };
  for (Value *R : Parked) {
    auto *A = dyn_cast<CallInst>(R);
    if (!A || !calleeName(A).starts_with("cqrt_alloc_"))
      return false;
    for (User *U : A->users())
      if (!isPark(U) && (!isa<CastInst>(U) || !llvm::all_of(U->users(), isPark)))
        return false;
  }
  return railBankCellReadsOf(Parked.front(), Loads);
}

// CELL-LOAD freshness (header, second producer; clauses (a)–(c)).
bool freshCellLoad(LoadInst *L, const Instruction *C, const Loop *TL,
                   const TaintSet &taint, const DominatorTree &DT,
                   ScalarEvolution &SE) {
  AllocaInst *B = railBankOfPointer(L->getPointerOperand());
  SmallVector<LoadInst *, 8> Loads;
  if (!B || !TL || TL->getParentLoop() || !materializedBank(L, B, Loads))
    return false;
  const auto *AR = dyn_cast<SCEVAddRecExpr>(SE.getSCEV(L->getPointerOperand()));
  if (!AR || AR->getLoop() != TL || !AR->isAffine() ||
      !AR->getNoWrapFlags(SCEV::NoWrapMask) ||
      !SE.isKnownNonZero(AR->getStepRecurrence(SE)))
    return false;
  // Entering TL's header from its top is the next trip: a different cell.
  const Instruction *NextTrip = &TL->getHeader()->front();
  for (LoadInst *Lj : Loads) {
    bool Same = SE.getSCEV(Lj->getPointerOperand()) == AR;
    // Lj's LOCAL class: Lj and its forward carriers (no memory hop: the bank's
    // other loads are enumerated here themselves).
    SmallPtrSet<Value *, 8> Cls;
    SmallVector<Value *, 8> WL{Lj};
    while (!WL.empty()) {
      Value *V = WL.pop_back_val();
      if (!Cls.insert(V).second)
        continue;
      for (User *U : V->users())
        if (isCarrier(U))
          WL.push_back(U);
    }
    for (Value *M : Cls)
      for (User *U : M->users()) {
        auto *I = dyn_cast<Instruction>(U);
        if (!I)
          return false;
        if (!isCouplingUse(I, Cls, /*SkipStores=*/false, taint))
          continue;
        if (Same ? runsWithoutRedef(I, C, NextTrip)
                 : isPotentiallyReachable(I, C, nullptr, &DT))
          return false;
      }
  }
  return true;
}

}  // namespace

void carriedFenceHandlesOf(CallInst *C, const TaintSet &taint,
                           SmallVectorImpl<Value *> &H) {
  for (unsigned S = 0, E = C->arg_size(); S != E; ++S) {
    Value *Op = C->getArgOperand(S);
    if (Op->getType()->isIntegerTy(32) && readsState(C, S) &&
        isRegister(Op, taint))
      H.push_back(Op);
  }
  StringRef N = calleeName(C);
  if (C->getType()->isIntegerTy(32) && !N.starts_with("cqrt_measure") &&
      (isRuntime(N) || N.starts_with("__cq_q_")))
    H.push_back(C);
}

// Block-level search through LLVM's `isPotentiallyReachableFromMany` with
// `Redef`'s block excluded (entering it from the top runs `Redef`), no DT/LI
// shortcut (both would answer "yes" past the exclusion); its block budget
// answers "yes" when exceeded — the conservative side here.
bool runsWithoutRedef(const Instruction *From, const Instruction *To,
                      const Instruction *Redef) {
  const BasicBlock *FB = From->getParent(), *TB = To->getParent(),
                   *RB = Redef->getParent();
  // Straight down one block.
  if (FB == TB && From->comesBefore(To))
    return !(RB == FB && From->comesBefore(Redef) && Redef->comesBefore(To));
  // Otherwise the path leaves `From`'s block by its tail and enters `To`'s
  // block from its top.
  if (RB == FB && From->comesBefore(Redef))
    return false;
  if (RB == TB && Redef->comesBefore(To))
    return false;
  SmallVector<BasicBlock *, 8> WL;
  for (const BasicBlock *S : successors(FB))
    WL.push_back(const_cast<BasicBlock *>(S));
  if (WL.empty())
    return false;
  SmallPtrSet<BasicBlock *, 1> Ex;
  Ex.insert(const_cast<BasicBlock *>(RB));
  return isPotentiallyReachableFromMany(WL, TB, &Ex, nullptr, nullptr);
}

bool carriedFenceFreshAt(Value *V, const Instruction *C, const Loop *TL,
                         const TaintSet &taint, const DominatorTree &DT,
                         ScalarEvolution &SE) {
  if (auto *A = dyn_cast<CallInst>(V);
      A && calleeName(A).starts_with("cqrt_alloc_"))
    return freshAlloc(A, C, taint, DT);
  if (auto *TR = dyn_cast<TruncInst>(V))  // a `_Bool` cell's storage trunc.
    V = TR->getOperand(0);
  if (auto *L = dyn_cast<LoadInst>(V))
    return freshCellLoad(L, C, TL, taint, DT, SE);
  return false;
}

}  // namespace cq
