// RailWindowVersionPair.cpp — bd `test_C_libtooling-01po.19` S7: the CFG
// transform of ONE index-alias versioning (contract in RailWindow.h; the
// driver, the fold and the postconditions are RailWindowVersion.cpp).
//
// The stretch from the version point G (the nearest common dominator of the
// pair's accesses) to the nearest common post-dominator of those accesses is
// cloned when it is one single-entry single-exit piece of the window (the -O1
// common case), else the rest of the window. The original is the DISTINCT
// copy, the clone the ALIASED one; a guard on the two cell offsets selects
// between them and carries `!cq.railwindow.version`, which makes each copy
// (and the join after them) a window of its own.

#include "RailWindow.h"
#include "RailWindowAlias.h"

#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/Transforms/Utils/LoopSimplify.h"
#include "llvm/Transforms/Utils/SSAUpdater.h"
#include "llvm/Transforms/Utils/ValueMapper.h"

using namespace llvm;

namespace cq {

namespace {

// Mirrored by railwindow_reject_alias_address.ll.
constexpr char kMsgAddr[] =
    "cq rail window: aliased cell address is not available at the version "
    "point";

bool diagnose(Function &F, const char *Msg, const Instruction *At) {
  F.getContext().diagnose(
      DiagnosticInfoUnsupported(F, Msg, At ? At->getDebugLoc() : DebugLoc()));
  return false;
}

// `V` available at `G`: itself if it dominates `G`, else its pure operand
// chain (casts, arithmetic, GEPs: speculatable, no memory, no phi) rebuilt at
// `G`, poison-generating flags dropped (the guard may run on a path where the
// original never did: branching on poison would be UB). Null if not possible.
Value *availAt(Value *V, Instruction *G, DominatorTree &DT,
               DenseMap<Value *, Value *> &Memo, unsigned Depth) {
  auto *I = dyn_cast<Instruction>(V);
  if (!I || (I != G && DT.dominates(I, G)))
    return V;
  if (Value *M = Memo.lookup(V))
    return M;
  if (Depth == 0 || isa<PHINode>(I) || I->mayReadOrWriteMemory() ||
      !isSafeToSpeculativelyExecute(I))
    return nullptr;
  SmallVector<Value *, 4> Ops;
  for (Value *Op : I->operands()) {
    Value *A = availAt(Op, G, DT, Memo, Depth - 1);
    if (!A)
      return nullptr;
    Ops.push_back(A);
  }
  Instruction *C = I->clone();
  for (unsigned i = 0; i < Ops.size(); ++i)
    C->setOperand(i, Ops[i]);
  C->dropPoisonGeneratingFlags();
  C->dropPoisonGeneratingMetadata();
  C->insertBefore(G);
  C->setName(I->getName() + ".cq.ver");
  Memo[V] = C;
  return C;
}

// The address `P` (a GEP chain over `W`, available at the builder) with `W`
// replaced by `null`: the cell's byte offset as a pointer. The guard compares
// offsets, never `W`'s own pointers, so the handle array keeps exactly the
// user vocabulary S1 and the retype admit (GEP, load, store).
Value *offsetOf(Value *P, AllocaInst *W, IRBuilder<> &B) {
  if (P == W)
    return ConstantPointerNull::get(W->getType());
  auto *G = cast<GetElementPtrInst>(P);  // S1: every address is a GEP chain.
  SmallVector<Value *, 4> Idx(G->indices());
  return B.CreateGEP(G->getSourceElementType(),
                     offsetOf(G->getPointerOperand(), W, B), Idx,
                     G->getName() + ".cq.off");
}

// A pointer to the class's cell available at `G` (the first access's address
// in instruction order, rebuilt at `G` when it is defined later).
Value *repAt(ArrayRef<Instruction *> Acc, Instruction *G, DominatorTree &DT) {
  DenseMap<Value *, Value *> Memo;
  for (Instruction *I : Acc)
    if (Value *P = availAt(getLoadStorePointerOperand(I), G, DT, Memo, 8))
      return P;
  return nullptr;
}

}  // namespace

bool railWindowVersionPair(Function &F, AllocaInst *W,
                           const RailWindowPair &P,
                           SmallPtrSetImpl<BasicBlock *> &Alias,
                           DenseMap<BasicBlock *, BasicBlock *> &Origin,
                           BasicBlock *O) {
  DominatorTree DT(F);
  LoopInfo LI(DT);
  SmallVector<Instruction *, 16> Accs(P.AccA.begin(), P.AccA.end());
  Accs.append(P.AccB.begin(), P.AccB.end());
  // The version point: the nearest common dominator of the pair's accesses.
  Instruction *G = Accs.front();
  for (Instruction *I : Accs)
    G = DT.findNearestCommonDominator(G, I);
  Value *RepA = nullptr, *RepB = nullptr;
  auto RepsAt = [&](Instruction *At) {
    RepB = repAt(P.AccB, At, DT);
    RepA = RepB ? repAt(P.AccA, At, DT) : nullptr;
    return RepA && RepB;
  };
  if (!RepsAt(G)) {
    // B's address may be computed after an early access of A (`q[i]` gated,
    // then `j = *p`, then `q[j]`): version lower, at the nearest common
    // dominator of B's accesses and of every A access reachable from it. An
    // A access left in front of the guard meets no B access there.
    Instruction *G2 = P.AccB.front();
    for (Instruction *I : P.AccB)
      G2 = DT.findNearestCommonDominator(G2, I);
    for (bool Again = true; Again;) {
      Again = false;
      for (Instruction *X : P.AccA)
        if (!DT.dominates(G2, X) &&
            isPotentiallyReachable(G2, X, nullptr, &DT)) {
          G2 = DT.findNearestCommonDominator(G2, X);
          Again = true;
        }
    }
    if (G2 == G || !RepsAt(G2))
      return diagnose(F, kMsgAddr, G);
    G = G2;
  }
  // The join: the nearest common post-dominator of the accesses when the
  // stretch from G to it is one single-entry single-exit piece of the region
  // (the -O1 common case, `q[i] ^= q[2-i]` in one block); else the whole rest
  // of the region (its exits, a back edge included).
  PostDominatorTree PDT(F);
  BasicBlock *PB = Accs.front()->getParent();
  for (Instruction *I : Accs)
    PB = PB ? PDT.findNearestCommonDominator(PB, I->getParent()) : nullptr;
  Instruction *Last = nullptr;
  if (PB)
    for (Instruction &I : *PB)
      if (is_contained(Accs, &I))
        Last = &I;
  SmallPtrSet<BasicBlock *, 16> OldLoopsSimplified;
  for (Loop *L : LI.getLoopsInPreorder())
    if (L->isLoopSimplifyForm())
      OldLoopsSimplified.insert(L->getHeader());
  BasicBlock *Head = G->getParent();
  BasicBlock *Tail = SplitBlock(Head, G, &DT, &LI);
  if (Alias.count(Head))
    Alias.insert(Tail);
  if (PB == Head)
    PB = Tail;
  BasicBlock *Join = nullptr;
  if (PB) {
    if (Last && !Last->isTerminator()) {
      Join = SplitBlock(PB, Last->getNextNode(), &DT, &LI);
      if (Alias.count(PB))
        Alias.insert(Join);
    } else if (!Last && PB != Tail) {
      Join = PB;
    }
  }
  DenseMap<BasicBlock *, BasicBlock *> R = computeWindowRegions(F, LI);
  BasicBlock *E = R.lookup(Tail);
  SmallVector<BasicBlock *, 16> T;
  SmallPtrSet<BasicBlock *, 16> InT;
  bool Sese = Join != nullptr;
  if (Sese) {
    SmallVector<BasicBlock *, 8> Work{Tail};
    while (!Work.empty() && Sese) {
      BasicBlock *B = Work.pop_back_val();
      if (B == Join || !InT.insert(B).second)
        continue;
      if (B == E || R.lookup(B) != E || !DT.dominates(Tail, B))
        Sese = false;
      Work.append(succ_begin(B), succ_end(B));
    }
  }
  if (!Sese) {
    InT.clear();
    for (BasicBlock &B : F)
      if (R.lookup(&B) == E && DT.dominates(Tail, &B))
        InT.insert(&B);
  }
  for (BasicBlock &B : F)
    if (InT.count(&B))
      T.push_back(&B);
  // Every access of the pair past the guard names its class through ONE
  // dominating address (S3 needs it; the same SCEV, so the same cell).
  for (Instruction *I : P.AccA)
    if (InT.count(I->getParent()))
      I->setOperand(isa<StoreInst>(I) ? 1 : 0, RepA);
  for (Instruction *I : P.AccB)
    I->setOperand(isa<StoreInst>(I) ? 1 : 0, RepB);
  // Clone the stretch: the clones are the ALIASED copy.
  ValueToValueMapTy VMap;
  SmallVector<BasicBlock *, 16> Clones;
  for (BasicBlock *B : T) {
    BasicBlock *C = CloneBasicBlock(B, VMap, ".cq.alias", &F);
    VMap[B] = C;
    Clones.push_back(C);
    Alias.insert(C);
  }
  remapInstructionsInBlocks(Clones, VMap);
  // Exit edges: each successor outside the stretch gets the clone's incomings.
  for (BasicBlock *B : T) {
    SmallPtrSet<BasicBlock *, 4> Done;
    for (BasicBlock *S : successors(B)) {
      if (InT.count(S) || !Done.insert(S).second)
        continue;
      for (PHINode &Phi : S->phis())
        for (unsigned i = 0, e = Phi.getNumIncomingValues(); i != e; ++i)
          if (Phi.getIncomingBlock(i) == B) {
            Value *V = Phi.getIncomingValue(i);
            Phi.addIncoming(VMap.count(V) ? static_cast<Value *>(VMap[V]) : V,
                            cast<BasicBlock>(VMap[B]));
          }
    }
  }
  // Values of the stretch used past it: SSAUpdater merges the two copies.
  for (BasicBlock *B : T)
    for (Instruction &I : *B) {
      SmallVector<Use *, 4> Outside;
      for (Use &U : I.uses()) {
        auto *UI = cast<Instruction>(U.getUser());
        BasicBlock *UB = UI->getParent();
        if (auto *Phi = dyn_cast<PHINode>(UI))
          UB = Phi->getIncomingBlock(U);
        // (A clone never uses `I`: remapping named `VMap[I]` there.)
        if (!InT.count(UB))
          Outside.push_back(&U);
      }
      if (Outside.empty())
        continue;
      SSAUpdater SSA;
      SSA.Initialize(I.getType(), I.getName());
      SSA.AddAvailableValue(B, &I);
      SSA.AddAvailableValue(cast<BasicBlock>(VMap[B]), VMap[&I]);
      for (Use *U : Outside)
        SSA.RewriteUse(*U);
    }
  // The aliased copy names class B through A's address: one cell, one name.
  for (Instruction *I : P.AccB)
    cast<Instruction>(VMap[I])->setOperand(isa<StoreInst>(I) ? 1 : 0, RepA);
  // The guard: classical control on classical indices.
  Instruction *Br = Head->getTerminator();
  IRBuilder<> GB(Br);
  Value *Ne = GB.CreateICmpNE(offsetOf(RepA, W, GB), offsetOf(RepB, W, GB),
                              "cq.win.ne");
  BranchInst *Guard = GB.CreateCondBr(Ne, Tail, cast<BasicBlock>(VMap[Tail]));
  // The record that makes each copy (and the join after them) a window of
  // its own (`computeWindowRegions`): memory carries the cells between them,
  // so a class is seeded and written back inside the copy where the guard
  // holds, never across the join where it does not.
  Guard->setMetadata("cq.railwindow.version",
                     MDNode::get(F.getContext(), {}));
  for (BasicBlock *B : T)
    Origin[B] = O;
  for (BasicBlock *B : Clones)
    Origin[B] = O;
  if (Join)
    Origin[Join] = O;
  Br->eraseFromParent();
  // The pair's old address computations are dead in both copies now.
  SmallVector<WeakVH, 16> Dead;
  for (BasicBlock *B : T)
    for (Instruction &I : *B)
      Dead.push_back(&I);
  for (BasicBlock *B : Clones)
    for (Instruction &I : *B)
      Dead.push_back(&I);
  for (WeakVH &VH : Dead)
    if (auto *I = dyn_cast_or_null<Instruction>(VH);
        I && (isa<GetElementPtrInst>(I) || isa<CastInst>(I)) &&
        isInstructionTriviallyDead(I))
      RecursivelyDeleteTriviallyDeadInstructions(I);
  // A cloned latch or exit edge leaves the loop out of simplify form.
  DominatorTree DT2(F);
  LoopInfo LI2(DT2);
  for (Loop *L : LI2.getLoopsInPreorder())
    if (OldLoopsSimplified.count(L->getHeader()) && !L->isLoopSimplifyForm())
      simplifyLoop(L, &DT2, &LI2, nullptr, nullptr, nullptr, false);
  return true;
}

}  // namespace cq
