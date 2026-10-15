// RailWindowAlias.cpp — bd `test_C_libtooling-01po.19` S3/S7: THE alias
// question of the window model (one spelling, R12): are two cell classes of a
// window provably distinct cells, everywhere or where they are accessed; and,
// for S7, the control == target hazard of an aliased copy. Contract in
// RailWindow.h; the versioning transform is RailWindowVersion.cpp.

#include "RailWindow.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

std::optional<bool> railWindowEdgeFact(ScalarEvolution &SE, DominatorTree &DT,
                                       const Instruction *Ctx, const SCEV *A,
                                       const SCEV *B) {
  // An equality branch whose operands differ by `A - B` (either sign: the S7
  // guard compares byte offsets, so its operands are `null`-based and only
  // the difference is the same SCEV), and one of whose edges dominates the
  // context. The addresses are SSA values, fixed within a trip, and an edge
  // dominating a block of the same loop body is crossed on the same trip.
  const SCEV *AB = SE.getMinusSCEV(A, B);
  if (isa<SCEVCouldNotCompute>(AB))
    return std::nullopt;
  const BasicBlock *BB = Ctx->getParent();
  for (DomTreeNode *N = DT.getNode(BB); N && N->getIDom(); N = N->getIDom()) {
    BasicBlock *D = N->getIDom()->getBlock();
    auto *Br = dyn_cast<BranchInst>(D->getTerminator());
    auto *C = Br && Br->isConditional() ? dyn_cast<ICmpInst>(Br->getCondition())
                                        : nullptr;
    if (!C || !C->isEquality() ||
        Br->getSuccessor(0) == Br->getSuccessor(1))
      continue;
    const SCEV *X = SE.getSCEV(C->getOperand(0));
    const SCEV *Y = SE.getSCEV(C->getOperand(1));
    const SCEV *XY = SE.getMinusSCEV(X, Y);
    if (isa<SCEVCouldNotCompute>(XY) ||
        (XY != AB && XY != SE.getNegativeSCEV(AB)))
      continue;
    bool NeFirst = C->getPredicate() == ICmpInst::ICMP_NE;
    if (DT.dominates(BasicBlockEdge(D, Br->getSuccessor(NeFirst ? 0 : 1)), BB))
      return true;
    if (DT.dominates(BasicBlockEdge(D, Br->getSuccessor(NeFirst ? 1 : 0)), BB))
      return false;
  }
  return std::nullopt;
}

bool railWindowDistinct(ScalarEvolution &SE, const SCEV *A, const SCEV *B,
                        const Instruction *Ctx, DominatorTree *DT) {
  if (SE.isKnownNonZero(SE.getMinusSCEV(A, B)))
    return true;
  if (!Ctx)
    return false;
  // S7: a dominating `A != B` (the versioning guard, or the user's own test).
  // LLVM's dominating-condition query first; it climbs single-predecessor
  // chains only, so a join inside a versioned copy is answered by the edge
  // walk (`railWindowEdgeFact`).
  if (SE.isKnownPredicateAt(ICmpInst::ICMP_NE, A, B, Ctx))
    return true;
  return DT && railWindowEdgeFact(SE, *DT, Ctx, A, B) == std::optional(true);
}

bool railWindowPairProven(ScalarEvolution &SE, DominatorTree &DT,
                          const SCEV *A, const SCEV *B,
                          ArrayRef<Instruction *> AccA,
                          ArrayRef<Instruction *> AccB) {
  if (railWindowDistinct(SE, A, B))
    return true;
  // Forwarding cell A across the accesses of B is memory-preserving iff B is
  // never cell A where it is accessed (and symmetrically).
  auto All = [&](ArrayRef<Instruction *> Acc) {
    return !Acc.empty() && llvm::all_of(Acc, [&](Instruction *I) {
      return railWindowDistinct(SE, A, B, I, &DT);
    });
  };
  return All(AccB) || All(AccA);
}

bool railWindowUnprovenPair(Function &F, const RailWindowAccesses &Acc,
                            DominatorTree &DT, LoopInfo &LI,
                            ScalarEvolution &SE, RailWindowPair &Out) {
  DenseMap<BasicBlock *, BasicBlock *> R = computeWindowRegions(F, LI);
  // Classes keyed by (region entry, address SCEV), in instruction order (the
  // access lists are sorted), so the first unproven pair is a function of the
  // program alone.
  SmallVector<RailWindowPair, 8> Classes;  // one entry per class: E, A, AccA
  auto Add = [&](Instruction *I) {
    BasicBlock *E = R.lookup(I->getParent());
    if (!E)
      return;
    const SCEV *S = SE.getSCEV(getLoadStorePointerOperand(I));
    for (RailWindowPair &C : Classes)
      if (C.E == E && C.A == S) {
        C.AccA.push_back(I);
        return;
      }
    Classes.push_back(RailWindowPair{E, S, nullptr, {I}, {}});
  };
  SmallVector<Instruction *, 32> All(Acc.Loads.begin(), Acc.Loads.end());
  All.append(Acc.Stores.begin(), Acc.Stores.end());
  DenseMap<const Instruction *, unsigned> Pos;
  unsigned N = 0;
  for (Instruction &I : instructions(F))
    Pos[&I] = N++;
  llvm::sort(All, [&](Instruction *X, Instruction *Y) {
    return Pos.lookup(X) < Pos.lookup(Y);
  });
  for (Instruction *I : All)
    Add(I);
  for (unsigned a = 0; a < Classes.size(); ++a)
    for (unsigned b = a + 1; b < Classes.size(); ++b)
      if (Classes[a].E == Classes[b].E &&
          !railWindowPairProven(SE, DT, Classes[a].A, Classes[b].A,
                                Classes[a].AccA, Classes[b].AccA)) {
        Out = RailWindowPair{Classes[a].E, Classes[a].A, Classes[b].A,
                             Classes[a].AccA, Classes[b].AccA};
        return true;
      }
  return false;
}

namespace {

// The array loads `V`'s quantum backward slice reaches (a `cq_measure` result
// is classical: `railWindowQuantum` never puts one in `QD`).
void cellReads(Value *V, const SmallPtrSetImpl<Value *> &QD,
               const RailWindowAccesses &Acc, DominatorTree &DT,
               SmallPtrSetImpl<LoadInst *> &Out) {
  SmallVector<Value *, 8> W{V};
  SmallPtrSet<Value *, 16> Seen;
  while (!W.empty()) {
    Value *X = W.pop_back_val();
    if (!QD.count(X) || !Seen.insert(X).second)
      continue;
    if (auto *L = dyn_cast<LoadInst>(X); L && is_contained(Acc.Loads, L)) {
      Out.insert(L);
      continue;
    }
    // A value carried over a back edge was read on an EARLIER trip: its
    // address SCEV names another trip's cell, never this trip's class.
    if (auto *Phi = dyn_cast<PHINode>(X)) {
      for (unsigned i = 0, e = Phi->getNumIncomingValues(); i != e; ++i)
        if (!DT.dominates(Phi->getParent(), Phi->getIncomingBlock(i)))
          W.push_back(Phi->getIncomingValue(i));
      continue;
    }
    if (auto *I = dyn_cast<Instruction>(X))
      W.append(I->op_begin(), I->op_end());
  }
}

}  // namespace

// CONTROL == TARGET: a quantum condition reading class X controls a store to
// class Y, {X, Y} the pair. Returns the offending store, or null.
Instruction *railWindowSelfControl(Function &F, const RailWindowAccesses &Acc,
                         const SmallPtrSetImpl<Value *> &QD,
                         const RailWindowPair &P, ScalarEvolution &SE,
                         DominatorTree &DT, PostDominatorTree &PDT) {
  auto ClassOf = [&](Instruction *I) -> int {
    const SCEV *S = SE.getSCEV(getLoadStorePointerOperand(I));
    return S == P.A ? 0 : S == P.B ? 1 : -1;
  };
  SmallVector<StoreInst *, 8> Stores;
  for (Instruction *I : P.AccA)
    if (auto *S = dyn_cast<StoreInst>(I))
      Stores.push_back(S);
  for (Instruction *I : P.AccB)
    if (auto *S = dyn_cast<StoreInst>(I))
      Stores.push_back(S);
  for (Instruction &I : instructions(F)) {
    Value *C = nullptr;
    if (auto *B = dyn_cast<BranchInst>(&I); B && B->isConditional())
      C = B->getCondition();
    else if (auto *Sw = dyn_cast<SwitchInst>(&I))
      C = Sw->getCondition();
    else if (auto *Se = dyn_cast<SelectInst>(&I))
      C = Se->getCondition();
    if (!C || !QD.count(C))
      continue;
    SmallPtrSet<LoadInst *, 4> Reads;
    cellReads(C, QD, Acc, DT, Reads);
    bool ReadsA = false, ReadsB = false;
    for (LoadInst *L : Reads) {
      ReadsA |= ClassOf(L) == 0;
      ReadsB |= ClassOf(L) == 1;
    }
    for (StoreInst *S : Stores) {
      int K = ClassOf(S);
      if (!((K == 1 && ReadsA) || (K == 0 && ReadsB)))
        continue;
      bool Controlled;
      if (isa<SelectInst>(&I)) {
        SmallVector<Value *, 8> W{S->getValueOperand()};
        SmallPtrSet<Value *, 16> Seen;
        Controlled = false;
        while (!W.empty() && !Controlled) {
          Value *X = W.pop_back_val();
          if (!QD.count(X) || !Seen.insert(X).second)
            continue;
          Controlled = X == &I;
          if (auto *XI = dyn_cast<Instruction>(X))
            W.append(XI->op_begin(), XI->op_end());
        }
      } else {
        Controlled = DT.dominates(I.getParent(), S->getParent()) &&
                     !PDT.dominates(S->getParent(), I.getParent());
      }
      if (Controlled)
        return S;
    }
  }
  return nullptr;
}

}  // namespace cq
