// RailWindowArms.cpp — bd `test_C_libtooling-01po.19` S6 (design §5, owner
// ruling owner-ruling-01po19-rolled-design-2026-10-15): cell accesses inside an
// arm of a QUANTUM branch, put into the shape the control emitters own.
//
// THE SHAPE -O1 LEAVES. `if (q[i-1]) cq_theta(&q[i], θ)` over a window array is
//     P:   %c = load q[i-1];  br %c, A, M
//     A:   %x = load q[i];  %r = cq_theta(%x, θ);  store %r, q[i];  br M
// The arm is a load + in-place gate + SELF-STORE with no merge φ, so every
// region recognizer declines it (`control flow under quantum control`), and
// S3's promoter leaves it alone (one load, one store, in a window that the
// arm's own address bounds).
//
// THE REWRITE (exact). For a branch whose condition is quantum and whose
// region (the blocks between it and its immediate post-dominator M, all in
// P's loop) holds window accesses, each cell CLASS of the region (one address
// SCEV; classes provably distinct, `railWindowDistinct`, else the region is
// left as written) is loaded ONCE before the branch, carried through the
// region as SSA (`PromoteMemToReg`) and written back ONCE at M:
//     P:   %x = load q[i];  br %c, A, M
//     A:   %r = cq_theta(%x, θ);  br M
//     M:   %m = phi [%r, A], [%x, P];  store %m, q[i]
// This is the in-place controlled-Ry diamond lane C lowers
// (`cqrt_ry_<W>_controlled`, the target then frozen; design §5 item 2), and the
// write-back is a self-store in the handle domain. It is the identity on the
// program's values: the hoisted load reads the cell's content at the branch,
// which no region access precedes; every region read of the class sees the
// value its region writes left (SSA), and M's write-back stores the value the
// taken path left in the cell (the cell's own value on the path that wrote
// nothing). The hoisted ADDRESS is classical index arithmetic: under quantum
// control both arms' classical computations are evaluated anyway (the arm
// hoists of the emitters), so only pure, non-trapping instructions are moved
// (`isSafeToSpeculativelyExecute`); anything else leaves the region alone,
// and the control chain then declines it loudly.
// Ground truth (R12): BennettVM.jl 23d28e6 `MemoryAssignment` (src/ir/
// memory_instructions.jl:111) is the in-place cell update a controlled gate
// then applies; Bennett.jl 824458d1's guarded store (src/lowering/memory.jl:
// 838) moves the VALUE through a controlled mux, which CQ does not need for a
// cell whose handle is selected by a classical index.

#include "RailWindow.h"
#include "RailWindowAlias.h"  // railWindowPairProven (S7)

#include "TaintPropagation.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/TargetParser/Triple.h"
#include "llvm/Transforms/Utils/PromoteMemToReg.h"

#include <cstdlib>
#include <map>

using namespace llvm;

namespace cq {

namespace {

bool inW(const Value *Ptr, const AllocaInst *W) {
  return getUnderlyingObject(Ptr) == W;
}

// Can `V` be made available at `At` by hoisting pure, non-trapping
// instructions (in `Hoist`, operands first)? Nothing is moved here.
bool hoistable(Value *V, Instruction *At, DominatorTree &DT,
               SmallVectorImpl<Instruction *> &Hoist,
               SmallPtrSetImpl<Instruction *> &Seen, unsigned Depth = 0) {
  auto *I = dyn_cast<Instruction>(V);
  if (!I || DT.dominates(I, At))
    return true;
  if (Depth > 16 || isa<PHINode>(I) || I->mayReadOrWriteMemory() ||
      !isSafeToSpeculativelyExecute(I))
    return false;
  if (!Seen.insert(I).second)
    return true;
  for (Value *Op : I->operands())
    if (!hoistable(Op, At, DT, Hoist, Seen, Depth + 1))
      return false;
  Hoist.push_back(I);
  return true;
}

struct Class {
  const SCEV *S = nullptr;
  Value *Addr = nullptr;
  SmallVector<LoadInst *, 2> Loads;
  SmallVector<StoreInst *, 2> Stores;
};

// One region: rewrite it if every condition holds; true if it changed.
bool promoteArm(BranchInst *BI, AllocaInst *W, Type *RT, DominatorTree &DT,
                PostDominatorTree &PDT, LoopInfo &LI, ScalarEvolution &SE) {
  BasicBlock *P = BI->getParent();
  DomTreeNodeBase<BasicBlock> *PN = PDT.getNode(P);
  if (!PN || !PN->getIDom() || !PN->getIDom()->getBlock())
    return false;
  BasicBlock *M = PN->getIDom()->getBlock();
  // The region: everything reachable from P's successors before M, inside P's
  // loop, dominated by P (single entry), and free of back edges to P.
  SmallVector<BasicBlock *, 8> Region, Work(succ_begin(P), succ_end(P));
  SmallPtrSet<BasicBlock *, 8> Seen;
  while (!Work.empty()) {
    BasicBlock *B = Work.pop_back_val();
    if (B == M || !Seen.insert(B).second)
      continue;
    if (B == P || !DT.dominates(P, B) || LI.getLoopFor(B) != LI.getLoopFor(P))
      return false;
    Region.push_back(B);
    Work.append(succ_begin(B), succ_end(B));
  }
  if (!DT.dominates(P, M) || LI.getLoopFor(M) != LI.getLoopFor(P))
    return false;
  std::map<const SCEV *, Class> Classes;
  SmallVector<const SCEV *, 4> Order;
  for (BasicBlock *B : Region)
    for (Instruction &I : *B) {
      Value *Ptr = getLoadStorePointerOperand(&I);
      if (!Ptr || !inW(Ptr, W))
        continue;
      Type *Ty = isa<StoreInst>(I) ? cast<StoreInst>(I).getValueOperand()->getType()
                                   : I.getType();
      if (Ty != RT)
        return false;
      const SCEV *S = SE.getSCEV(Ptr);
      if (!Classes.count(S))
        Order.push_back(S);
      Class &C = Classes[S];
      C.S = S;
      if (!C.Addr)
        C.Addr = Ptr;
      if (auto *L = dyn_cast<LoadInst>(&I))
        C.Loads.push_back(L);
      else
        C.Stores.push_back(cast<StoreInst>(&I));
    }
  if (Order.empty())
    return false;
  // Pairwise distinct per S7's context-aware proof (`railWindowPairProven`,
  // every access of each class asked under its dominating guards), so a
  // versioned copy's classes, proven only inside the copy, are promoted.
  // The rewrite adds two accesses per class OUTSIDE the arm — the hoisted
  // in-load at the branch and the write-back at the merge — so the pair is
  // asked at those plan points too (review S6 round 2 F2: an S7 version guard
  // INSIDE the arm proves the arm's accesses but not the branch or merge,
  // where i == j is possible). Unproven there: the region is not promoted.
  Instruction *MergePt = &*M->getFirstInsertionPt();
  auto accesses = [&](const Class &C) {
    SmallVector<Instruction *, 4> V(C.Loads.begin(), C.Loads.end());
    V.append(C.Stores.begin(), C.Stores.end());
    V.push_back(BI);
    if (!C.Stores.empty())
      V.push_back(MergePt);
    return V;
  };
  for (unsigned a = 0; a < Order.size(); ++a)
    for (unsigned b = a + 1; b < Order.size(); ++b)
      if (!railWindowPairProven(SE, DT, Order[a], Order[b],
                                accesses(Classes[Order[a]]),
                                accesses(Classes[Order[b]]))) {
        if (std::getenv("CQ_RAILWINDOW_DBG"))
          errs() << "CQ_RAILWINDOW_DBG: arm not promoted: cell pair unproven "
                    "at the arm, its branch or its merge\n";
        return false;  // an unproven pair: S7's question, not this rewrite's.
      }
  // Every class address must be computable at the branch.
  SmallVector<Instruction *, 8> Hoist;
  SmallPtrSet<Instruction *, 8> HSeen;
  for (const SCEV *S : Order)
    if (!hoistable(Classes[S].Addr, BI, DT, Hoist, HSeen))
      return false;
  // ── mutate ──
  for (Instruction *I : Hoist)
    I->moveBefore(BI);
  Function &F = *P->getParent();
  IRBuilder<> EB(&*F.getEntryBlock().getFirstInsertionPt());
  SmallVector<AllocaInst *, 4> Temps;
  for (const SCEV *S : Order) {
    Class &C = Classes[S];
    AllocaInst *T = EB.CreateAlloca(RT, nullptr, "cq.arm");
    IRBuilder<> B(BI);
    B.CreateStore(B.CreateLoad(RT, C.Addr, "cq.arm.in"), T);
    for (LoadInst *L : C.Loads)
      L->setOperand(0, T);
    for (StoreInst *St : C.Stores)
      St->setOperand(1, T);
    if (!C.Stores.empty()) {
      IRBuilder<> MB(&*M->getFirstInsertionPt());
      MB.CreateStore(MB.CreateLoad(RT, T, "cq.arm.out"), C.Addr);
    }
    Temps.push_back(T);
  }
  DominatorTree DT2(F);
  PromoteMemToReg(Temps, DT2);
  return true;
}

// A multi-successor terminator whose condition (or any operand) is tainted.
bool taintedTerminator(const Instruction *T, const TaintSet &taint) {
  for (const Value *Op : T->operands())
    if (taint.Tainted.count(Op))
      return true;
  return false;
}

// Is `To` reachable from `From`'s successors along a path that never enters
// `Avoid` (null: nothing avoided)?
bool reachesAvoiding(BasicBlock *From, BasicBlock *To, BasicBlock *Avoid) {
  SmallVector<BasicBlock *, 16> Work(succ_begin(From), succ_end(From));
  SmallPtrSet<BasicBlock *, 16> Seen;
  while (!Work.empty()) {
    BasicBlock *B = Work.pop_back_val();
    if (B == Avoid || !Seen.insert(B).second)
      continue;
    if (B == To)
      return true;
    Work.append(succ_begin(B), succ_end(B));
  }
  return false;
}

}  // namespace

bool promoteRailWindowArms(Function &F, AllocaInst *W, const TaintSet &taint) {
  Type *RT = W->getAllocatedType();
  bool Changed = false;
  // One region at a time, every analysis rebuilt (R9).
  for (bool Again = true; Again;) {
    Again = false;
    RailWindowAccesses Acc;
    Acc.AI = W;
    SmallVector<Value *, 16> Ptrs{W};
    for (User *U : W->users())
      if (isa<GetElementPtrInst>(U))
        Ptrs.push_back(U);
    for (Value *Ptr : Ptrs)
      for (User *U : Ptr->users())
        if (auto *L = dyn_cast<LoadInst>(U); L && L->getPointerOperand() == Ptr)
          Acc.Loads.push_back(L);
    SmallPtrSet<Value *, 32> QD;
    railWindowQuantum(F, Acc, taint, QD);
    DominatorTree DT(F);
    PostDominatorTree PDT(F);
    LoopInfo LI(DT);
    AssumptionCache AC(F);
    TargetLibraryInfoImpl TLII(Triple(F.getParent()->getTargetTriple()));
    TargetLibraryInfo TLI(TLII);
    ScalarEvolution SE(F, TLI, AC, DT, LI);
    for (BasicBlock &BB : F) {
      auto *BI = dyn_cast<BranchInst>(BB.getTerminator());
      if (!BI || !BI->isConditional() || !QD.count(BI->getCondition()))
        continue;
      if (promoteArm(BI, W, RT, DT, PDT, LI, SE)) {
        Changed = Again = true;
        break;
      }
    }
  }
  return Changed;
}

// bd 01po.19 S6 — THE WRITE-BACK φ. S3's promotion writes a cell back once at
// its window exit, so a cell updated on only some classical paths (dicke's
// `q[m-1]`: two updates when m >= 3, one otherwise) is written back as
//     M:  %v = phi [ %a, P1 ], [ %b, P2 ];  store %v, q[c]
// a tainted value muxed by a CLASSICAL condition, which the taint-escape guard
// refuses (no lowering selects between two rails classically). Every incoming
// IS the cell's current value at the end of its predecessor (the promoted
// class's SSA value there), so storing `%a` at the end of P1 and `%b` at the
// end of P2 writes, on every path, exactly the value the merge store wrote —
// and on a path leaving P1 elsewhere it writes the cell's own current value,
// which no read of that path can tell apart (S3: one SSA name per class, other
// classes provably distinct). The merge store and the dead φ are erased. Only
// a φ whose sole user is that store, in a window function, whose incomings are
// not φs of M, is split. Returns true if anything changed.
bool splitRailWindowWritebacks(Module &M, TaintSet &taint) {
  bool Changed = false;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    SmallVector<StoreInst *, 8> Sites;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *S = dyn_cast<StoreInst>(&I))
          if (auto *P = dyn_cast<PHINode>(S->getValueOperand());
              P && P->getParent() == S->getParent() && P->hasOneUse() &&
              railWindowOfPointer(S->getPointerOperand()) &&
              taint.Tainted.count(P) && llvm::none_of(P->incoming_values(),
                                                      [&](Value *In) {
                auto *IP = dyn_cast<PHINode>(In);
                return IP && IP->getParent() == P->getParent();
              }))
            Sites.push_back(S);
    for (StoreInst *S : Sites) {
      auto *P = cast<PHINode>(S->getValueOperand());
      auto *Ptr = dyn_cast<Instruction>(S->getPointerOperand());
      bool Avail = true;  // the address must be available in every predecessor.
      DominatorTree DT(F);
      PostDominatorTree PDT(F);
      for (unsigned i = 0, e = P->getNumIncomingValues(); i != e; ++i)
        if (Ptr && !DT.dominates(Ptr, P->getIncomingBlock(i)->getTerminator()))
          Avail = false;
      // Only a CLASSICAL merge (review S6 A-F3, round 2 F1). THE ONE
      // PREDICATE, the invariant itself: the φ's incoming selection never
      // depends on a tainted terminator. A tainted terminator T (a `br` or
      // `switch` on a tainted condition, or any multi-successor terminator
      // with a tainted operand) steers it iff M is T's immediate
      // post-dominator, or M is reachable from T without passing that
      // post-dominator (M inside T's region, including a region with an exit
      // around M).
      for (BasicBlock &B : F)
        if (Instruction *T = B.getTerminator(); T && T->getNumSuccessors() > 1 &&
                                                taintedTerminator(T, taint)) {
          auto *TN = PDT.getNode(&B);
          BasicBlock *IP = TN && TN->getIDom() ? TN->getIDom()->getBlock() : nullptr;
          if (IP == P->getParent() || reachesAvoiding(&B, P->getParent(), IP))
            Avail = false;
        }
      // DEFENSIVE, kept two-sided (review S6 C-F2): the idom's and the direct
      // predecessors' branches, which the predicate above already covers today;
      // the idom half is what review_s6C/p5.c (if/else rotating two different
      // registers) needs. RETIREMENT: when bd 01po.19.20 lowers that shape, its
      // fixture must kill the guard-removed mutant before either half goes.
      if (auto *N = DT.getNode(P->getParent()); N && N->getIDom())
        if (auto *Br = dyn_cast<BranchInst>(N->getIDom()->getBlock()->getTerminator());
            Br && Br->isConditional() && taint.Tainted.count(Br->getCondition()))
          Avail = false;
      for (BasicBlock *Pr : predecessors(P->getParent()))
        if (auto *Br = dyn_cast<BranchInst>(Pr->getTerminator());
            Br && Br->isConditional() && taint.Tainted.count(Br->getCondition()))
          Avail = false;
      if (std::getenv("CQ_RAILWINDOW_DBG"))
        errs() << "CQ_RAILWINDOW_DBG: write-back " << (Avail ? "split" : "kept")
               << ": " << *S << "\n";
      if (!Avail)
        continue;
      for (unsigned i = 0, e = P->getNumIncomingValues(); i != e; ++i) {
        auto *NS = new StoreInst(P->getIncomingValue(i), S->getPointerOperand(),
                                 S->isVolatile(), S->getAlign(),
                                 P->getIncomingBlock(i)->getTerminator());
        NS->setDebugLoc(S->getDebugLoc());
      }
      taint.Tainted.erase(S);
      S->eraseFromParent();
      taint.Tainted.erase(P);
      P->eraseFromParent();
      Changed = true;
    }
  }
  return Changed;
}

}  // namespace cq
