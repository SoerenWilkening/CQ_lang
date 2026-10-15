// RailWindowAlias.cpp — bd `test_C_libtooling-01po.19` S3/S7: THE alias
// question of the window model (one spelling, R12): are two cell classes of a
// window provably distinct cells, everywhere or where they are accessed; and,
// for S7, the control == target hazard of an aliased copy. Contract in
// RailWindow.h; the versioning transform is RailWindowVersion.cpp.

#include "RailWindow.h"
#include "RailWindowAlias.h"

#include "TaintPropagation.h"

#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/ConstantRange.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/raw_ostream.h"

#include <cstdlib>

using namespace llvm;

namespace cq {

bool railWindowCompareIsCellEquality(ScalarEvolution &SE, const ICmpInst *C,
                                     const SCEV *AB) {
  if (!C->isEquality())
    return false;
  Value *X = C->getOperand(0), *Y = C->getOperand(1);
  // Pointers (the S7 guard's `null`-based byte offsets): the same difference,
  // either sign.
  if (X->getType()->isPointerTy()) {
    const SCEV *D = SE.getMinusSCEV(SE.getSCEV(X), SE.getSCEV(Y));
    return !isa<SCEVCouldNotCompute>(D) &&
           (D == AB || D == SE.getNegativeSCEV(AB));
  }
  // Integers (R11 S7 B-F3, the user's own test): X == Y iff K * (ext X - ext Y)
  // == 0 for a constant K != 0 when the product cannot wrap to 0: |ext X - ext
  // Y| < 2^W, so W + log2|K| < width(AB) suffices. K = +-1 needs no width
  // margin (the compare IS the address difference, both modulo 2^64), which
  // covers `a * 4ul != j * 4ul`; `i != j` on i64 indices of 4-byte cells
  // (K = 4, W = 64) is accepted only when SCEV bounds i - j (e.g. `& 7`
  // masks), else it is not a cell test. Either extension is injective.
  if (!X->getType()->isIntegerTy() || !AB->getType()->isIntegerTy())
    return false;
  unsigned W = X->getType()->getIntegerBitWidth();
  unsigned TW = AB->getType()->getIntegerBitWidth();
  if (W > TW)
    return false;
  for (bool Signed : {false, true}) {
    const SCEV *XE = Signed ? SE.getNoopOrSignExtend(SE.getSCEV(X), AB->getType())
                            : SE.getNoopOrZeroExtend(SE.getSCEV(X), AB->getType());
    const SCEV *YE = Signed ? SE.getNoopOrSignExtend(SE.getSCEV(Y), AB->getType())
                            : SE.getNoopOrZeroExtend(SE.getSCEV(Y), AB->getType());
    const SCEV *D = SE.getMinusSCEV(XE, YE);
    // |D| < 2^(TW-1-L) keeps K * D (K = 2^L) clear of a wrap to 0: by the
    // operand width, or by SCEV's signed range of D (`a & 7` vs `j & 7`).
    ConstantRange DR = SE.getSignedRange(D);
    for (unsigned L = 0; L <= 6; ++L) {
      if (L && W + L >= TW) {
        APInt Lim = APInt::getOneBitSet(TW, TW - 1 - L);
        if (DR.isFullSet() || DR.getSignedMin().sle(-Lim) ||
            DR.getSignedMax().sge(Lim))
          break;
      }
      const SCEV *KD = SE.getMulExpr(SE.getConstant(AB->getType(), 1ull << L), D);
      if (KD == AB || KD == SE.getNegativeSCEV(AB))
        return true;
    }
  }
  return false;
}

std::optional<bool> railWindowEdgeFact(ScalarEvolution &SE, DominatorTree &DT,
                                       const Instruction *Ctx, const SCEV *A,
                                       const SCEV *B) {
  // An equality branch that compares the two cells (`railWindowCompareIsCell
  // Equality`: the S7 guard's offsets, or a user index compare scaled to the
  // cell difference), one of whose edges dominates the context. The addresses
  // are SSA values, fixed within a trip, and an edge dominating a block of the
  // same loop body is crossed on the same trip.
  const SCEV *AB = SE.getMinusSCEV(A, B);
  if (isa<SCEVCouldNotCompute>(AB))
    return std::nullopt;
  const BasicBlock *BB = Ctx->getParent();
  bool Equal = false;
  for (DomTreeNode *N = DT.getNode(BB); N && N->getIDom(); N = N->getIDom()) {
    BasicBlock *D = N->getIDom()->getBlock();
    auto *Br = dyn_cast<BranchInst>(D->getTerminator());
    auto *C = Br && Br->isConditional() ? dyn_cast<ICmpInst>(Br->getCondition())
                                        : nullptr;
    if (!C || Br->getSuccessor(0) == Br->getSuccessor(1) ||
        !railWindowCompareIsCellEquality(SE, C, AB))
      continue;
    bool NeFirst = C->getPredicate() == ICmpInst::ICMP_NE;
    if (DT.dominates(BasicBlockEdge(D, Br->getSuccessor(NeFirst ? 0 : 1)), BB))
      return true;
    if (DT.dominates(BasicBlockEdge(D, Br->getSuccessor(NeFirst ? 1 : 0)), BB))
      Equal = true;  // keep climbing: a `!=` edge above wins (R11 S7)
  }
  // Both edges dominating means the context is dead (`i != j` guard, then the
  // user's `i == j` arm): "distinct" is then as true as anything, and it is
  // the answer that does not chain versionings forever.
  return Equal ? std::optional<bool>(false) : std::nullopt;
}

bool railWindowDistinct(ScalarEvolution &SE, const SCEV *A, const SCEV *B,
                        const Instruction *Ctx, DominatorTree *DT) {
  if (SE.isKnownNonZero(SE.getMinusSCEV(A, B)))
    return true;
  if (!Ctx)
    return false;
  // S7: a dominating `A != B` (the versioning guard, or a user test that
  // `railWindowCompareIsCellEquality` accepts as the cell test).
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
  // Each class's touches: its accesses plus the points S3's promotion would
  // add (seed, write-backs; R11 S7 A-F1), so a pair the promoter would refuse
  // is versioned here instead.
  SmallVector<SmallVector<Instruction *, 8>, 8> Touch;
  for (RailWindowPair &C : Classes) {
    Touch.emplace_back(C.AccA.begin(), C.AccA.end());
    RailWindowClassPlan Plan;
    railWindowClassPlan(F, DT, R, C.E, C.AccA, Plan);
    railWindowPlanPoints(Plan, Touch.back());
  }
  for (unsigned a = 0; a < Classes.size(); ++a)
    for (unsigned b = a + 1; b < Classes.size(); ++b)
      if (Classes[a].E == Classes[b].E &&
          !railWindowPairProven(SE, DT, Classes[a].A, Classes[b].A, Touch[a],
                                Touch[b])) {
        Out = RailWindowPair{Classes[a].E, Classes[a].A, Classes[b].A,
                             Classes[a].AccA, Classes[b].AccA};
        return true;
      }
  return false;
}

namespace {

bool isThetaCall(const Value *V) {
  const auto *CI = dyn_cast<CallInst>(V);
  const Function *Fn = CI ? CI->getCalledFunction() : nullptr;
  return Fn && Fn->getName().starts_with("cq_theta_") && CI->arg_size() >= 1;
}

// THE MEMBER FAMILY of one class (R11 S7 B-F2; the stale-cell fence's family,
// `railWindowStaleUse`): every in-place spelling of the cell's rail — its
// loads and what they flow into through storage casts and in-place
// `cq_theta`, and every value stored into it back through the same
// vocabulary (and same-trip phis), the PRE-Q stored value included
// (`cq_theta(&q[i], .3); if (q[i]) ...` branches on the theta result itself).
void markFamily(ArrayRef<Instruction *> Accs, unsigned Bit, DominatorTree &DT,
                DenseMap<Value *, unsigned> &Member) {
  SmallVector<Value *, 16> Fwd, Back;
  for (Instruction *I : Accs) {
    if (isa<LoadInst>(I))
      Fwd.push_back(I);
    else if (auto *S = dyn_cast<StoreInst>(I))
      Back.push_back(S->getValueOperand());
  }
  SmallPtrSet<Value *, 32> SeenF, SeenB;
  while (!Fwd.empty()) {
    Value *X = Fwd.pop_back_val();
    if (!SeenF.insert(X).second)
      continue;
    Member[X] |= Bit;
    for (User *U : X->users())
      if (isa<CastInst>(U) ||
          (isThetaCall(U) && cast<CallInst>(U)->getArgOperand(0) == X))
        Fwd.push_back(U);
  }
  while (!Back.empty()) {
    Value *X = Back.pop_back_val();
    if (!isa<Instruction>(X) || !SeenB.insert(X).second)
      continue;
    Member[X] |= Bit;
    if (auto *C = dyn_cast<CastInst>(X))
      Back.push_back(C->getOperand(0));
    else if (isThetaCall(X))
      Back.push_back(cast<CallInst>(X)->getArgOperand(0));
    else if (auto *Phi = dyn_cast<PHINode>(X))
      for (unsigned i = 0, e = Phi->getNumIncomingValues(); i != e; ++i)
        if (!DT.dominates(Phi->getParent(), Phi->getIncomingBlock(i)))
          Back.push_back(Phi->getIncomingValue(i));
  }
}

// The classes (bit mask) whose rail `V`'s quantum backward slice reads (a
// `cq_measure` result is classical: `railWindowQuantum` never puts one in
// `QD`).
unsigned classReads(Value *V, const SmallPtrSetImpl<Value *> &QD,
                    const DenseMap<Value *, unsigned> &Member,
                    DominatorTree &DT) {
  unsigned Out = 0;
  SmallVector<Value *, 8> W{V};
  SmallPtrSet<Value *, 16> Seen;
  while (!W.empty()) {
    Value *X = W.pop_back_val();
    if (!QD.count(X) || !Seen.insert(X).second)
      continue;
    Out |= Member.lookup(X);
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
  return Out;
}

}  // namespace

// CONTROL == TARGET: a quantum condition reading class X controls a store to
// class Y, {X, Y} the pair. Returns the offending store, or null.
Instruction *railWindowSelfControl(Function &F, const RailWindowAccesses &,
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
  DenseMap<Value *, unsigned> Member;
  markFamily(P.AccA, 1, DT, Member);
  markFamily(P.AccB, 2, DT, Member);
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
    unsigned Reads = classReads(C, QD, Member, DT);
    bool ReadsA = Reads & 1, ReadsB = Reads & 2;
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

// Moved verbatim from RailWindowPromote.cpp (400-line budget).
DenseMap<BasicBlock *, BasicBlock *> computeWindowRegions(Function &F,
                                                           LoopInfo &LI) {
  DenseMap<BasicBlock *, BasicBlock *> R;
  ReversePostOrderTraversal<Function *> RPOT(&F);
  for (BasicBlock *BB : RPOT) {
    Loop *L = LI.getLoopFor(BB);
    bool Entry = BB == &F.getEntryBlock() || (L && L->getHeader() == BB);
    BasicBlock *Reg = nullptr;
    if (!Entry)
      for (BasicBlock *P : predecessors(BB)) {
        auto It = R.find(P);
        // A predecessor in another loop body (a sub-loop exit, an outer
        // body), or not yet visited (an irreducible edge), starts a region.
        // S7: each copy of a versioned window is a window of its own.
        if (LI.getLoopFor(P) != L || It == R.end() ||
            P->getTerminator()->getMetadata("cq.railwindow.version")) {
          Entry = true;
          break;
        }
        if (!Reg)
          Reg = It->second;
        else if (Reg != It->second) {
          Entry = true;  // a join of two regions starts its own.
          break;
        }
      }
    R[BB] = Entry ? BB : Reg;
  }
  return R;
}

// Moved from RailWindowPromote.cpp (400-line budget): the plan helpers.
Instruction *railWindowPlanSeedPoint(const RailWindowClassPlan &P) {
  // Asked again at transform time: an earlier class's seed may now follow
  // the same address, and the seed goes in front of it (emitted order).
  auto *AddrI = dyn_cast<Instruction>(P.Addr);
  if (P.Inside)
    return isa<PHINode>(AddrI) ? &*AddrI->getParent()->getFirstInsertionPt()
                               : AddrI->getNextNode();
  return &*P.Entry->getFirstInsertionPt();
}

void railWindowPlanPoints(const RailWindowClassPlan &P,
                          SmallVectorImpl<Instruction *> &Out) {
  if (!P.At)
    return;
  Out.push_back(P.At);  // the seed load
  if (P.HasStores)
    for (BasicBlock *X : P.Exiting)
      Out.push_back(X->getTerminator());  // each write-back
}

}  // namespace cq
