// MergeStreamPlan.cpp — see header (bd test_C_libtooling-r2j3.32).

#include "MergeStreamPlan.h"
#include "MergeStreamGates.h"   // the stream gate vocabulary

#include "BirthFreeze.h"       // railBornZero — clause (a), "born |0⟩"
#include "ChainWalk.h"         // isInPlaceGateOn / isInteriorConsumer / ...
#include "EmitInverse.h"       // isInverseEmittable / emitInverseCall
#include "RailBankPromote.h"   // railStoredToRailBank
#include "TaintPropagation.h"  // TaintSet

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

bool between(const Instruction *I, const Instruction *Lo,
             const Instruction *Hi) {
  return (I == Lo || Lo->comesBefore(I)) && (I == Hi || I->comesBefore(Hi));
}

// The STRAIGHT-LINE CHAIN from `BB`, block -> position: each block ends in an
// unconditional `br` to a block whose ONLY predecessor it is. Control entering
// `BB` runs the whole chain once, without leaving it, so program order along it
// is a total order and nothing outside it runs in between (the flattened-region
// shape: `br label %merge`). A reader anywhere on it can be followed.
DenseMap<const BasicBlock *, unsigned> straightChain(BasicBlock *BB) {
  DenseMap<const BasicBlock *, unsigned> Chain;
  for (unsigned N = 0; BB && Chain.insert({BB, N++}).second;) {
    auto *Br = dyn_cast<BranchInst>(BB->getTerminator());
    BasicBlock *S = Br && Br->isUnconditional() ? Br->getSuccessor(0) : nullptr;
    BB = S && S->getSinglePredecessor() == BB ? S : nullptr;
  }
  return Chain;
}
}  // namespace

// Recover the closed stream around `Out` (see the header) and prove the
// replay sound. False ⇒ leave `Out` allocated.
bool planMerge(CallInst *Out, const TaintSet &taint,
               const DenseMap<const Instruction *, Instruction *> &GroupEnd,
               MergePlan &P) {
  BasicBlock *BB = Out->getParent();
  if (!calleeName(Out).starts_with("cqrt_alloc_") || !railBornZero(Out, taint) ||
      railStoredToRailBank(Out))
    return false;
  const auto Chain = straightChain(BB);
  auto before = [&](const Instruction *A, const Instruction *B) {
    unsigned IA = Chain.lookup(A->getParent()), IB = Chain.lookup(B->getParent());
    return IA != IB ? IA < IB : A->comesBefore(B);
  };
  // 1. Writers, readers, in-place gates of %out — all calls in BB.
  SmallVector<CallInst *, 4> Writers, Readers;
  for (User *U : Out->users()) {
    auto *C = dyn_cast<CallInst>(U);
    if (!C || !Chain.count(C->getParent()))
      return false;  // ret / φ / store / off the chain: not provable here.
    if (isControlledCopy(C) && C->getArgOperand(2) == Out) {
      if (C->getArgOperand(0) == Out || C->getArgOperand(1) == Out ||
          C->getParent() != BB)
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
  //    value it WRITES is minted inside it and every value it mints (but %out
  //    and the classical source loads) is freed inside it.
  Instruction *Lo = Out, *Hi = Out;
  for (CallInst *W : Writers)
    if (Hi->comesBefore(W))
      Hi = W;
  SmallPtrSet<Value *, 8> Net;
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
          if (!isControlledCopy(C))
            return false;
          continue;
        }
        if (V->comesBefore(Lo)) {
          Lo = V;  // the stream writes a rail it must have minted.
          Grew = true;
        }
      }
      // A CONTROL the stream reads that some `cqrt_free` releases is a flag
      // of the stream's own network (a compare leaf, read only as a control
      // until its strip): pull its mint in. A user's rail leaf is never freed
      // and stays a read register. A freed control that is NOT the network's
      // drags foreign traffic in and fails the closure below — a leak.
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
      if (!C->getType()->isVoidTy() && C != Out) {
        bool Src = calleeName(C).starts_with("cqrt_alloc_") &&
                   !C->use_empty() &&
                   all_of(C->users(), [&](User *U) {
                     auto *K = dyn_cast<CallInst>(U);
                     return K && is_contained(Writers, K) &&
                            K->getArgOperand(1) == C &&
                            K->getArgOperand(0) != C;
                   });
        if (Src) {
          P.SrcAllocs.insert(C);
        } else {
          Net.insert(C);
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
          if (!Free)
            return false;  // a minted rail the stream never frees: not ours.
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
  // 3. Every user of a stream-minted rail lies inside the stream, no reader of
  //    %out does, and nothing in it writes a classical source.
  for (Value *V : Net)
    for (User *U : V->users())
      if (!between(cast<Instruction>(U), Lo, Hi))
        return false;
  for (CallInst *R : Readers)
    if (!before(Hi, R))
      return false;
  for (Instruction *I = Lo;; I = I->getNextNode()) {
    auto *C = cast<CallInst>(I);
    SmallVector<unsigned, 2> W;
    streamGateWrites(C, W);
    for (unsigned S : W)
      if (P.SrcAllocs.count(C->getArgOperand(S)))
        return false;
    if (I == Hi)
      break;
  }
  // 4. The CORE: first writer .. last writer, plus the `cqrt_x` brackets that
  //    close it. Only writers of %out, classical source loads and `cqrt_x` on
  //    a stream-minted flag may sit in it, and every flag's brackets must
  //    balance — then the core is an involution (copies on complementary
  //    branches of their flag commute and each squares to 1) that leaves every
  //    rail but %out as it found it, so its reverse is its adjoint.
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
  for (Instruction *I = C1;; I = I->getNextNode()) {
    auto *C = cast<CallInst>(I);
    if (calleeName(C) == "cqrt_x") {
      if (!Net.count(C->getArgOperand(0)))
        return false;
      ++XCount[C->getArgOperand(0)];
    } else if (!is_contained(Writers, C) && !P.SrcAllocs.count(C)) {
      return false;  // network traffic between the copies: not a plain core.
    }
    P.Core.push_back(C);
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
  // 5. The replay point: after the last reader; a reader that is itself an
  //    earlier replay is passed by its whole group (LIFO nesting).
  Instruction *Last = Hi;
  for (CallInst *R : Readers) {
    Instruction *At = GroupEnd.lookup(R);
    if (!At)
      At = R;
    if (before(Last, At))
      Last = At;
  }
  // A last reader that is ANOTHER merge's controlled copy (this rail is its
  // copy source) sits inside that merge's core: step to the core's end — its
  // further copies into the same rail, the `cqrt_x` brackets on the same flag
  // and their classical source loads — so the replay never lands inside a
  // foreign core. Cosmetic (none of it touches what this replay reads), and
  // the window check below still covers every instruction stepped over.
  if (auto *LC = dyn_cast<CallInst>(Last); LC && isControlledCopy(LC)) {
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
  // 6. The window (Hi, Last]: every register the stream reads — the core's
  //    sources, the flag network's controls and compare operands — is touched
  //    there only by pure reads, so the deferred strip and the core's adjoint
  //    see exactly what the forward saw.
  SmallPtrSet<Value *, 8> Ext;
  for (Instruction *I = Lo;; I = I->getNextNode()) {
    for (Value *Op : cast<CallInst>(I)->args())
      if (isRegister(Op, taint) && Op != Out && !Net.count(Op) &&
          !P.SrcAllocs.count(Op))
        Ext.insert(Op);
    if (I == Hi)
      break;
  }
  for (Value *X : Ext) {
    if (railStoredToRailBank(X))
      return false;
    for (User *U : X->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I || isa<StoreInst>(I))
        return false;  // a handle parked in memory can be moved by a call that
                       // never names it — no window proof survives that.
      if (!Chain.count(I->getParent()))
        continue;  // off the chain: cannot run inside its straight-line window.
      if (!before(Hi, I) || before(Last, I))
        continue;
      auto *C = dyn_cast<CallInst>(I);
      if (!C || !onlyReads(C, X, taint))
        return false;
    }
  }
  llvm::sort(P.InPlace, before);
  P.Out = Out;
  P.Lo = Lo;
  P.Hi = Hi;
  P.Last = Last;
  return true;
}

}  // namespace cq
