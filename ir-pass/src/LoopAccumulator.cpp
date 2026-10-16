// LoopAccumulator.cpp — see the header (bd test_C_libtooling-01po.19.18).

#include "LoopAccumulator.h"

#include "InPlaceQQ.h"         // kInPlaceQQTag — the spine's in-place QQ relation
#include "LiteralIntegrity.h"  // valueCarriesUndef
#include "OpcodeSupport.h"     // abiWidthFromType, diagnoseNoTemplate
#include "SelectMergeEmit.h"   // materializeCopySource (the L1-recorded seed load)
#include "TaintPropagation.h"  // TaintSet
#include "WidthDispatch.h"     // allocFn, qqInPlaceFn

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Metadata.h"

#include <functional>

using namespace llvm;

namespace cq {

namespace {

StringRef qqStem(Instruction::BinaryOps Op) {
  switch (Op) {
  case Instruction::Add:
    return "add";
  case Instruction::Sub:
    return "sub";
  case Instruction::Xor:
    return "xor";
  default:
    return {};
  }
}

// Does the SOURCE `S` of a QQ step read the accumulator's own register (any
// value in `Rail`, the chain from `P` up to the step)? Walked backward over
// operands inside `L`. A value defined outside `L` cannot read `P` (P is a
// header phi and does not dominate the preheader); a header phi other than `P`
// is ANOTHER register's trip-entry value and stops the walk; a load reads
// memory (a cell), not this SSA register. Anything reaching the chain is the
// aliased pair `x ⊕= f(x)` the references forbid (header) — refused.
bool accSourceReadsRail(Value *S, const SmallPtrSetImpl<Value *> &Rail,
                        const Loop *L) {
  SmallVector<Value *, 16> Work{S};
  SmallPtrSet<Value *, 32> Seen;
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (Rail.count(V))
      return true;
    if (!Seen.insert(V).second)
      continue;
    auto *I = dyn_cast<Instruction>(V);
    if (!I || !L->contains(I->getParent()) || isa<LoadInst>(I))
      continue;
    if (isa<PHINode>(I) && I->getParent() == L->getHeader())
      continue;
    for (Value *Op : I->operands())
      Work.push_back(Op);
  }
  return false;
}

bool inSubloop(const Loop *L, const BasicBlock *BB) {
  for (const Loop *S : L->getSubLoops())
    if (S->contains(BB))
      return true;
  return false;
}

// bd 01po.19.18.8 (R11 r1 rA1A-F2, an over-decline) — `-O1` may place the
// step BEFORE a read of the trip's OLD counter (`old = c; c += a; if (old ==
// 1) ...`: `%n = add %c, %a` then `icmp eq %c, 1`). In place the step moves the
// register, so that read would see the NEW value and the record fence refuses.
// The step is a pure op, so it is SUNK to the latest point that still precedes
// every use of its result: right before its first in-loop user (all of them in
// one block the step dominates), or the latch's end when its only in-loop user
// is the header phi. Moving a pure op later changes no operand value anywhere;
// it is done only when an in-loop read of the old value runs after the step in
// the trip AND none runs after the new point (else the fence still refuses,
// loudly), so every shape that lowered before is emitted byte-identically.
void sinkStepPastOldReads(const SeededAccumulator &A, const DominatorTree &DT) {
  if (A.Steps.size() != 1 || A.Steps.front().first != A.Latch)
    return;
  BinaryOperator *BO = A.Steps.front().first;
  const Loop *L = A.L;
  BasicBlock *Latch = L->getLoopLatch();
  if (!Latch)
    return;
  // The new point: the first in-loop user of the step, else the latch's end.
  Instruction *IP = Latch->getTerminator();
  BasicBlock *UB = nullptr;
  for (User *U : BO->users()) {
    auto *UI = dyn_cast<Instruction>(U);
    if (!UI)
      return;
    if (UI == A.Phi || !L->contains(UI->getParent()))
      continue;
    if (isa<PHINode>(UI) || (UB && UB != UI->getParent()))
      return;
    UB = UI->getParent();
  }
  if (UB) {
    if (!DT.dominates(BO->getParent(), UB))
      return;
    IP = nullptr;
    for (Instruction &I : *UB)
      if (is_contained(I.operands(), BO)) {
        IP = &I;
        break;
      }
    if (!IP)
      return;
  }
  // Runs `R` after `From` within the trip (never re-entering the header)?
  auto afterInTrip = [&](const Instruction *From, const Instruction *R) {
    for (const Instruction *I = From->getNextNode(); I; I = I->getNextNode())
      if (I == R)
        return true;
    SmallVector<const BasicBlock *, 8> W(succ_begin(From->getParent()),
                                         succ_end(From->getParent()));
    SmallPtrSet<const BasicBlock *, 8> Seen;
    while (!W.empty()) {
      const BasicBlock *B = W.pop_back_val();
      if (B == L->getHeader() || !L->contains(B) || !Seen.insert(B).second)
        continue;
      if (B == R->getParent())
        return true;
      W.append(succ_begin(B), succ_end(B));
    }
    return false;
  };
  bool Needed = false;
  for (User *U : A.Phi->users()) {
    auto *R = dyn_cast<Instruction>(U);
    if (!R || R == BO || !L->contains(R->getParent()) || isa<PHINode>(R))
      continue;
    if (afterInTrip(IP, R) || R == IP)
      return;  // a read of the old value after the new point: no sink helps.
    if (afterInTrip(BO, R))
      Needed = true;
  }
  if (Needed && BO->getNextNode() != IP)
    BO->moveBefore(IP);
}

}  // namespace

std::optional<SeededAccumulator>
seededAccumulatorPhi(PHINode &P, const Loop *L, const TaintSet &taint,
                     const DominatorTree &DT, AccStepFn Step) {
  // (A1)
  BasicBlock *Latch = L->getLoopLatch();
  if (!Latch || P.getParent() != L->getHeader() || !taint.Tainted.count(&P) ||
      P.getNumIncomingValues() != 2)
    return std::nullopt;
  // (A5) the handle ABI width — see the header.
  if (!P.getType()->isIntegerTy(32))
    return std::nullopt;
  SeededAccumulator A;
  A.Phi = &P;
  A.L = L;
  Value *LatV = nullptr;
  for (unsigned i = 0; i < 2; ++i) {
    BasicBlock *IB = P.getIncomingBlock(i);
    if (IB == Latch)
      LatV = P.getIncomingValue(i);
    else if (!L->contains(IB)) {
      A.Entry = IB;
      A.Seed = P.getIncomingValue(i);
    }
  }
  if (!LatV || !A.Seed)
    return std::nullopt;
  // (A2)
  if (taint.Tainted.count(A.Seed) || valueCarriesUndef(A.Seed))
    return std::nullopt;
  if (auto *SI = dyn_cast<Instruction>(A.Seed))
    if (L->contains(SI->getParent()) ||
        !DT.dominates(SI, A.Entry->getTerminator()))
      return std::nullopt;
  // (A3)/(A4) — walk the latch value back to `P`. The chain is collected first
  // (latch → P); each QQ step's source is then asked against the chain values
  // BELOW it (the rail's state before the step), which is every value the
  // source could alias.
  SmallVector<Value *, 8> Chain;  // LatV first, P excluded
  SmallVector<std::pair<BinaryOperator *, unsigned>, 2> Steps;
  // Depth-first: a caller step has one parent; a QQ step's rail is whichever
  // operand walks on to `P` (for `sub`, the minuend only — `y - x` has no
  // in-place form). Both operands walking to `P` (`c + c`) is the aliased pair,
  // refused by the source test below whichever is taken.
  std::function<bool(Value *)> Walk = [&](Value *V) -> bool {
    if (V == &P)
      return true;
    if (Chain.size() > 64 || is_contained(Chain, V))
      return false;
    Chain.push_back(V);
    if (Value *Next = Step(V)) {
      if (Walk(Next))
        return true;
      Chain.pop_back();
      return false;
    }
    auto *BO = dyn_cast<BinaryOperator>(V);
    if (BO && !qqStem(BO->getOpcode()).empty() &&
        L->contains(BO->getParent()) && !inSubloop(L, BO->getParent()) &&
        taint.Tainted.count(BO->getOperand(0)) &&
        taint.Tainted.count(BO->getOperand(1))) {
      unsigned NIdx = BO->getOpcode() == Instruction::Sub ? 1 : 2;
      for (unsigned Idx = 0; Idx < NIdx; ++Idx) {
        Steps.push_back({BO, Idx});
        if (Walk(BO->getOperand(Idx)))
          return true;
        Steps.pop_back();
      }
    }
    Chain.pop_back();
    return false;
  };
  if (!Walk(LatV) || Steps.empty())
    return std::nullopt;  // not this kind (no quantum source) — the caller's.
  // The source test, per step, against P and every chain value preceding it.
  for (auto &[BO, Idx] : Steps) {
    SmallPtrSet<Value *, 8> Below;
    Below.insert(&P);
    bool Past = false;
    for (Value *C : Chain) {
      if (Past)
        Below.insert(C);
      if (C == BO)
        Past = true;
    }
    Below.insert(BO);
    if (accSourceReadsRail(BO->getOperand(1 - Idx), Below, L))
      return std::nullopt;
  }
  A.Steps = std::move(Steps);
  A.Latch = LatV;
  return A;
}

Value *commitSeededAccumulator(const SeededAccumulator &A, WidthDispatch &wd,
                               TaintSet &taint, const DominatorTree &DT) {
  PHINode &P = *A.Phi;
  StringRef W = abiWidthFromType(P.getType());
  FunctionCallee Alloc = wd.allocFn(W);
  if (!Alloc)
    return nullptr;
  for (auto &[BO, Idx] : A.Steps)
    if (!wd.qqInPlaceFn(qqStem(BO->getOpcode()), W))
      return nullptr;
  // ---- MUTATION STARTS HERE.
  sinkStepPastOldReads(A, DT);
  for (auto &[BO, Idx] : A.Steps) {
    taint.InPlaceQQRailOps.insert(BO);
    taint.InPlaceRailIdx[BO] = Idx;
  }
  // The seed is classical at THIS taint; a seed that becomes quantum in the
  // round-2 fixpoint (a 6.5/4.5 `%out` derivative) is re-asked at final taint by
  // `declineQuantumCopySources`, which `materializeCopySource` records it for
  // (L1; bd r2j3.14). The register is quantum from here on.
  IRBuilder<> B(A.Entry->getTerminator());
  Value *H = materializeCopySource(A.Seed, Alloc, taint, B, P.getDebugLoc(),
                                   "cq.acc");
  taint.Tainted.insert(H);
  if (auto *HI = dyn_cast<Instruction>(H))
    taint.AccumulatorRails.insert(HI);
  taint.BirthOrder[H] = taint.NextBirth++;
  taint.HandleWidth[H] = W;
  P.setIncomingValueForBlock(A.Entry, H);
  // THE ZERO-TRIP PATH NAMES THE SAME REGISTER (the h1ip argument, for this
  // kind). A guarded loop's exit φ merges the SEED on the guard's bypass edge
  // with the register on the exit edge; where the mint dominates that bypass
  // edge (it is at the end of the entry block, which is the guard itself when
  // `-O1` gives no preheader), the seed incoming IS the register's value on that
  // path and is renamed to it. The exit φ then is a pure renaming of the rail,
  // which the caller's renaming fixpoint collapses and its record fence asks.
  // A bypass the mint does not dominate, or any in-loop exit edge, stays
  // classical and the φ declines at `declineClassicalMuxes`, loudly.
  const Loop *Lp = A.L;
  for (Value *Name : {static_cast<Value *>(&P), A.Latch})
    for (User *U : Name->users())
      if (auto *X = dyn_cast<PHINode>(U); X && !Lp->contains(X->getParent()))
        for (unsigned i = 0, e = X->getNumIncomingValues(); i != e; ++i)
          // Invariant (4): ONLY a BYPASS edge (from outside the loop) carries
          // the register's value; an in-loop exit edge carrying a constant equal
          // to the seed (`c = 0; break;`, LLVM uniques the `0`) is the
          // program's own value, not the register (R11 r1 rA1A-F1).
          if (X->getIncomingValue(i) == A.Seed &&
              !Lp->contains(X->getIncomingBlock(i)) &&
              DT.dominates(A.Entry, X->getIncomingBlock(i)))
            X->setIncomingValue(i, H);
  return H;
}

bool emitAccumulatorQQStep(BinaryOperator *BO, WidthDispatch &wd,
                           TaintSet &taint) {
  auto It = taint.InPlaceRailIdx.find(BO);
  StringRef W = abiWidthFromType(BO->getType());
  FunctionCallee Fn = wd.qqInPlaceFn(qqStem(BO->getOpcode()), W);
  if (It == taint.InPlaceRailIdx.end() || !Fn ||
      (BO->getOpcode() == Instruction::Sub && It->second != 0)) {
    diagnoseNoTemplate(BO);
    return false;
  }
  Value *Rail = BO->getOperand(It->second);
  Value *Src = BO->getOperand(1 - It->second);
  IRBuilder<> B(BO);
  CallInst *G = B.CreateCall(Fn, {Src, Rail});
  if (DebugLoc DL = BO->getDebugLoc())
    G->setDebugLoc(DL);
  G->setMetadata(kInPlaceQQTag, MDNode::get(BO->getContext(), {}));
  BO->replaceAllUsesWith(Rail);
  return true;
}

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

}  // namespace cq
