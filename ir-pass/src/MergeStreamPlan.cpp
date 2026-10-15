// MergeStreamPlan.cpp — see header (bd test_C_libtooling-r2j3.32).

#include "MergeStreamPlan.h"
#include "RailWindow.h"  // railWindowTripDistinctCells (bd 01po.19.17)
#include "MergeStreamGates.h"   // the stream gate vocabulary

#include "BirthFreeze.h"       // railBornZero — clause (a), "born |0⟩"
#include "ChainWalk.h"         // isInPlaceGateOn / preservesBasisUnderRecord
#include "EmitInverse.h"       // isInverseEmittable
#include "RailBankPromote.h"   // railStoredToRailBank
#include "TaintPropagation.h"  // TaintSet

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

bool between(const Instruction *I, const Instruction *Lo,
             const Instruction *Hi) {
  return I->getParent() == Lo->getParent() &&
         (I == Lo || Lo->comesBefore(I)) && (I == Hi || I->comesBefore(Hi));
}

// The rail's BIRTH. |0> (`railBornZero`), or a classical integer SEED — the
// 4.5 data-mux preload `cqrt_alloc_<W>(v_d)` — which `cqrt_xorc_<W>(out, seed)`
// returns to |0> once the replay has restored it: a Constant, or a classical
// caller Argument (immutable SSA: the same value XORed twice). Else refused.
bool bornState(CallInst *Out, const TaintSet &taint, Value *&Seed) {
  Seed = nullptr;
  if (!calleeName(Out).starts_with("cqrt_alloc_") || Out->arg_size() != 1)
    return false;
  if (railBornZero(Out, taint))
    return true;
  Value *S = Out->getArgOperand(0);
  if (!S->getType()->isIntegerTy() || isRegister(S, taint) ||
      isa<UndefValue>(S))
    return false;
  Seed = S;
  return true;
}

// The SINGLE-ENTRY / SINGLE-EXIT region from the stream's block `BB` to the
// replay block `PB`: `W` collects every block strictly between. Control that
// leaves `BB` reaches `PB` on every path without returning, leaving the
// innermost loop, or taking its back edge (so the replay runs once per run of
// the stream — per TRIP inside a loop), and nothing enters the region except
// through `BB`. The FreePoint discipline in its exact form: `PB` post-dominates
// and is dominated by the stream, with no repeat edge between them.
bool sese(BasicBlock *BB, BasicBlock *PB, LoopInfo &LI,
          SmallPtrSetImpl<BasicBlock *> &W) {
  if (PB == BB)
    return true;
  Loop *L = LI.getLoopFor(BB);
  if (L && (!L->contains(PB) || PB == L->getHeader()))
    return false;
  SmallVector<BasicBlock *, 8> Work(succ_begin(BB), succ_end(BB));
  if (Work.empty())
    return false;
  while (!Work.empty()) {
    BasicBlock *Y = Work.pop_back_val();
    if (Y == PB)
      continue;
    if (Y == BB || (L && (Y == L->getHeader() || !L->contains(Y))))
      return false;  // a back edge, or an exit from the trip, before PB.
    if (!W.insert(Y).second)
      continue;
    if (succ_empty(Y))
      return false;  // a function exit that never reaches PB.
    Work.append(succ_begin(Y), succ_end(Y));
  }
  W.insert(PB);
  for (BasicBlock *Y : W)
    for (BasicBlock *Pr : predecessors(Y))
      if (Pr != BB && !W.count(Pr))
        return false;  // a second entry into the region.
  W.erase(PB);
  return true;
}

}  // namespace

bool planMerge(CallInst *Out, const PlanContext &Ctx, MergePlan &P) {
  const TaintSet &taint = Ctx.taint;
  BasicBlock *BB = Out->getParent();
  if (!bornState(Out, taint, P.Seed) || railStoredToRailBank(Out))
    return false;
  // 1. Writers (in the merge block), readers, in-place gates of %out.
  SmallVector<CallInst *, 4> Writers, Readers;
  for (User *U : Out->users()) {
    auto *C = dyn_cast<CallInst>(U);
    if (!C)
      return false;  // ret / φ / store: an escape, not provable here.
    if (isMergeWrite(C, Out)) {
      if (C->getParent() != BB)
        return false;
      Writers.push_back(C);
    } else if (isInPlaceGateOn(C, Out)) {
      if (!preservesBasisUnderRecord(C) || !isInverseEmittable(C))
        return false;
      for (Value *Op : C->args())
        if (Op != Out && !isa<Constant>(Op))
          return false;  // a borrowed operand would need its own window.
      P.InPlace.push_back(C);
      Readers.push_back(C);  // the replay must also follow it.
    } else if (onlyReads(C, Out, taint)) {
      Readers.push_back(C);
    } else {
      return false;  // measured, taped, copied out, freed, …: leave it.
    }
  }
  if (Writers.empty())
    return false;
  // 2. The closed stream: grow [Lo, Hi] from {alloc .. last writer} until every
  //    value it WRITES is minted inside it, every control it reads that a
  //    `cqrt_free` releases is minted inside it, and every value it mints but
  //    %out is either NET (freed exactly once inside it) or KEPT (never freed,
  //    only ever read inside it: classical source loads, XOR-delta rails).
  Instruction *Lo = Out, *Hi = Out;
  for (CallInst *W : Writers)
    if (Hi->comesBefore(W))
      Hi = W;
  SmallPtrSet<Value *, 8> Net, Kept;
  for (bool Grew = true; Grew;) {
    Grew = false;
    for (Instruction *I = Lo;; I = I->getNextNode()) {
      auto *C = dyn_cast<CallInst>(I);
      SmallVector<unsigned, 2> W;
      if (!C || !streamGateWrites(C, W))
        return false;  // a foreign instruction inside the stream.
      for (unsigned S : W) {
        auto *V = dyn_cast<Instruction>(C->getArgOperand(S));
        if (!V || V->getParent() != BB)
          return false;
        if (V == Out) {
          if (!isMergeWrite(C, Out))
            return false;
          continue;
        }
        if (V->comesBefore(Lo)) {
          Lo = V;  // the stream writes a rail it must have minted.
          Grew = true;
        }
      }
      // A CONTROL the stream reads that some `cqrt_free` releases is a flag of
      // the stream's own network: pull its mint in. A user's rail leaf is never
      // freed and stays a read register; a foreign freed control drags foreign
      // traffic in and fails the closure — a leak.
      for (unsigned S : controlSlots(C)) {
        auto *V = dyn_cast<Instruction>(C->getArgOperand(S));
        if (!V || V->getParent() != BB || !V->comesBefore(Lo) ||
            none_of(V->users(), [](User *U) {
              return calleeName(dyn_cast<CallInst>(U)) == "cqrt_free";
            }))
          continue;
        Lo = V;
        Grew = true;
      }
      if (!C->getType()->isVoidTy() && C != Out && !Net.count(C) &&
          !Kept.count(C)) {
        CallInst *Free = nullptr;
        for (User *U : C->users()) {
          auto *K = dyn_cast<CallInst>(U);
          if (!K || K->getParent() != BB)
            return false;
          if (calleeName(K) == "cqrt_free") {
            if (Free)
              return false;
            Free = K;
          }
        }
        if (!Free) {
          Kept.insert(C);  // vetted after the closure settles.
        } else {
          Net.insert(C);
          if (Hi->comesBefore(Free)) {
            Hi = Free;
            Grew = true;
          }
        }
      }
      if (I == Hi)
        break;
    }
  }
  // 3. Every user of a minted rail lies inside the stream; a KEPT one is never
  //    in a written slot (its state at the replay is its state at its mint).
  for (Value *V : Net)
    for (User *U : V->users())
      if (!between(cast<Instruction>(U), Lo, Hi))
        return false;
  for (Value *V : Kept)
    for (User *U : V->users()) {
      auto *K = dyn_cast<CallInst>(U);
      SmallVector<unsigned, 2> W;
      if (!K || !between(K, Lo, Hi) || !streamGateWrites(K, W))
        return false;
      for (unsigned S : W)
        if (K->getArgOperand(S) == V)
          return false;
    }
  // 4. The CORE: first write .. last write of %out plus the `cqrt_x` brackets
  //    that close it. Its REPLAYED subsequence S is every write and every
  //    `cqrt_x` on a network flag; the rest of the core (mints, the spine's
  //    adjoints of a hoisted chain, flag mints) stays put. Sound because
  //    nothing the rest of the core writes is read by an S gate EARLIER in the
  //    core: at the replay point each S gate then sees exactly the inputs it
  //    saw forward, so S reversed is the adjoint of S, and S is the only part
  //    of the core that touched %out.
  CallInst *C1 = Writers.front(), *CEnd = Writers.front();
  for (CallInst *W : Writers) {
    if (W->comesBefore(C1))
      C1 = W;
    if (CEnd->comesBefore(W))
      CEnd = W;
  }
  while (CEnd != Hi) {
    auto *X = dyn_cast<CallInst>(CEnd->getNextNode());
    if (!X || calleeName(X) != "cqrt_x" || !Net.count(X->getArgOperand(0)))
      break;
    CEnd = X;
  }
  DenseMap<Value *, unsigned> XCount;
  SmallPtrSet<Value *, 8> ReadByS;
  for (Instruction *I = C1;; I = I->getNextNode()) {
    auto *C = cast<CallInst>(I);
    bool IsX = calleeName(C) == "cqrt_x" && Net.count(C->getArgOperand(0));
    if (IsX || isMergeWrite(C, Out)) {
      if (IsX)
        ++XCount[C->getArgOperand(0)];
      P.Replay.push_back(C);
      for (Value *Op : C->args())
        ReadByS.insert(Op);
    } else {
      SmallVector<unsigned, 2> W;
      streamGateWrites(C, W);
      for (unsigned S : W)
        if (ReadByS.count(C->getArgOperand(S)))
          return false;  // the core changes an input of an earlier S gate.
    }
    if (I == CEnd)
      break;
  }
  for (auto &KV : XCount)
    if (KV.second % 2)
      return false;
  for (Instruction *I = CEnd; I != Hi;) {
    I = I->getNextNode();
    P.Post.push_back(I);
  }
  // 5. The REGION: readers anywhere on the single-entry/single-exit region
  //    from BB to the nearest common post-dominator of BB and their blocks.
  BasicBlock *PB = BB;
  for (CallInst *R : Readers) {
    if (R->getParent() == BB) {
      if (!Hi->comesBefore(R))
        return false;
      continue;
    }
    PB = Ctx.PDT.findNearestCommonDominator(PB, R->getParent());
    if (!PB)
      return false;
  }
  SmallPtrSet<BasicBlock *, 8> Region;
  if (!sese(BB, PB, Ctx.LI, Region))
    return false;
  for (CallInst *R : Readers)
    if (R->getParent() != BB && R->getParent() != PB &&
        !Region.count(R->getParent()))
      return false;
  for (CallInst *G : P.InPlace)
    if (G->getParent() != BB && G->getParent() != PB)
      return false;  // a conditional in-place gate: no single adjoint.
  // 6. The replay point: after the last reader in PB (a reader inside an
  //    earlier replay group is passed by the whole group — LIFO nesting); the
  //    stream's own end when PB is BB; else PB's first insertion point.
  Instruction *Last = PB == BB ? Hi : nullptr;
  for (CallInst *R : Readers) {
    if (R->getParent() != PB)
      continue;
    Instruction *At = Ctx.GroupEnd.lookup(R);
    if (!At || At->getParent() != PB)
      At = R;
    if (!Last || Last->comesBefore(At))
      Last = At;
  }
  // A last reader that is ANOTHER merge's write (this rail is its copy source)
  // sits inside that merge's core: step to the core's end so the replay never
  // lands inside a foreign core (cosmetic; the window covers the steps).
  if (auto *LC = dyn_cast_or_null<CallInst>(Last); LC && isControlledCopy(LC)) {
    Value *Flag = LC->getArgOperand(0), *Dst = LC->getArgOperand(2);
    auto inCore = [&](CallInst *X) {
      if (isControlledCopy(X))
        return X->getArgOperand(2) == Dst && X->getArgOperand(0) == Flag;
      if (calleeName(X) == "cqrt_x")
        return X->getArgOperand(0) == Flag;
      auto *U = X->hasOneUse() ? dyn_cast<CallInst>(*X->user_begin()) : nullptr;
      return calleeName(X).starts_with("cqrt_alloc_") && U &&
             isControlledCopy(U) && U->getArgOperand(2) == Dst;
    };
    while (auto *X = dyn_cast_or_null<CallInst>(Last->getNextNode())) {
      if (!inCore(X))
        break;
      Last = X;
    }
  }
  P.At = Last ? Last->getNextNode() : &*PB->getFirstInsertionPt();
  // 7. The WINDOW (Hi .. At) over the region: every register the stream reads
  //    — through every alias of its handle (φ / select / cast, and the rail-
  //    bank park/reload hop; any other load or store refuses) — is touched
  //    there only by pure reads (a control slot included). Fails closed: any
  //    operand that is not a Constant or a classical caller Argument counts.
  auto inWindow = [&](const Instruction *I) {
    const BasicBlock *B = I->getParent();
    bool AfterHi = B != BB || Hi->comesBefore(I);
    bool BeforeAt = B != PB || I->comesBefore(P.At);
    if (B == BB || B == PB)
      return AfterHi && BeforeAt;
    return Region.count(B) != 0;
  };
  SmallPtrSet<Value *, 8> Ext;
  for (Instruction *I = Lo;; I = I->getNextNode()) {
    auto *C = cast<CallInst>(I);
    for (unsigned S = 0, E = C->arg_size(); S != E; ++S) {
      Value *Op = C->getArgOperand(S);
      if (readsState(C, S) && isRegister(Op, taint) && Op != Out &&
          !Net.count(Op) && !Kept.count(Op))
        Ext.insert(Op);
    }
    if (I == Hi)
      break;
  }
  for (Value *X : Ext) {
    SmallPtrSet<Value *, 8> Alias;
    if (!handleAliases(X, taint, Ctx.DT, Alias))
      return false;
    // bd 01po.19.17: a quantum-array class is array-granular; a read of a
    // provably DIFFERENT cell in X's own trip (the window one activation of
    // X's loop body) is another rail (`railWindowTripDistinctCells`).
    SmallVector<Value *, 8> AliasV(Alias.begin(), Alias.end());
    SmallPtrSet<const Value *, 8> OtherCells;
    railWindowTripDistinctCells(X, AliasV, Hi, P.At, OtherCells);
    for (Value *A : Alias) {
      if (OtherCells.count(A))
        continue;
      for (User *U : A->users()) {
        auto *I = dyn_cast<Instruction>(U);
        if (!I)
          return false;
        if (!inWindow(I))
          continue;
        if (auto *C = dyn_cast<CallInst>(I); C && !onlyReads(C, A, taint))
          return false;
      }
    }
  }
  llvm::sort(P.InPlace, [&](CallInst *A, CallInst *B) {
    return A->getParent() != B->getParent() ? A->getParent() == BB
                                            : A->comesBefore(B);
  });
  P.Out = Out;
  P.Lo = Lo;
  P.Hi = Hi;
  return true;
}

}  // namespace cq
