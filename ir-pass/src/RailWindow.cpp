// RailWindow.cpp — bd `test_C_libtooling-01po.19` S1 (claim), S2 (quantization
// point) and the pending-step decline. Contract in RailWindow.h; S3's transform
// is in RailWindowPromote.cpp.

#include "RailWindow.h"

#include "OpcodeSupport.h"  // abiWidthFromType / widthHasReversibleCopy
#include "QramLowering.h"   // railBankCarveVerdict / railBankInstReaches
#include "TaintPropagation.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/TargetParser/Triple.h"
#include "llvm/Transforms/Utils/LoopSimplify.h"
#include "llvm/Transforms/Utils/LoopUtils.h"  // InsertPreheaderForLoop

#include <cstdlib>
#include <string>

using namespace llvm;

namespace cq {

namespace {

bool dbg() { return std::getenv("CQ_RAILWINDOW_DBG") != nullptr; }

// Can `From` execute and then `To`, on a path that executes none of
// `Barriers` in between? An exact block walk (the `instReaches` discipline:
// no budget), cut at a barrier inside a block.
bool reachesAvoiding(const Instruction *From, const Instruction *To,
                     const SmallPtrSetImpl<const Instruction *> &Barriers) {
  const BasicBlock *FB = From->getParent();
  for (auto I = std::next(From->getIterator()); I != FB->end(); ++I) {
    if (&*I == To)
      return true;
    if (Barriers.count(&*I))
      return false;
  }
  SmallVector<const BasicBlock *, 16> Work(succ_begin(FB), succ_end(FB));
  SmallPtrSet<const BasicBlock *, 32> Seen;
  while (!Work.empty()) {
    const BasicBlock *B = Work.pop_back_val();
    if (!Seen.insert(B).second)
      continue;
    bool Cut = false;
    for (const Instruction &I : *B) {
      if (&I == To)
        return true;
      if (Barriers.count(&I)) {
        Cut = true;
        break;
      }
    }
    if (!Cut)
      Work.append(succ_begin(B), succ_end(B));
  }
  return false;
}

// S1, structural half: collect the leaf accesses, or refuse the array.
bool collectAccesses(AllocaInst *AI, const TaintSet &taint,
                     ScalarEvolution &SE, RailWindowAccesses &Acc) {
  Acc = RailWindowAccesses();
  Acc.AI = AI;
  if (auto *AT = dyn_cast<ArrayType>(AI->getAllocatedType());
      AT && !AI->isArrayAllocation())
    Acc.CellTy = AT->getElementType();
  else if (AI->isArrayAllocation())
    Acc.CellTy = AI->getAllocatedType();
  if (!Acc.CellTy || !Acc.CellTy->isIntegerTy() ||
      !widthHasReversibleCopy(abiWidthFromType(Acc.CellTy)))
    return false;
  const DataLayout &DL = AI->getModule()->getDataLayout();
  uint64_t CellBytes = DL.getTypeStoreSize(Acc.CellTy).getFixedValue();
  const SCEV *Base = SE.getSCEV(AI);
  SmallVector<Value *, 8> Work{AI};
  SmallPtrSet<Value *, 16> Seen;
  while (!Work.empty()) {
    Value *P = Work.pop_back_val();
    if (!Seen.insert(P).second)
      continue;
    for (User *U : P->users()) {
      if (auto *G = dyn_cast<GetElementPtrInst>(U)) {
        if (G->getPointerOperand() != P)
          return false;  // the address is an index: it escapes.
        for (Value *Idx : G->indices())
          if (taint.Tainted.count(Idx))
            return false;  // 7.5's QRAM axis keeps its owner.
        Work.push_back(G);
        continue;
      }
      auto *I = dyn_cast<Instruction>(U);
      if (!I)
        return false;
      if (auto *L = dyn_cast<LoadInst>(I)) {
        if (!L->isSimple() || L->getType() != Acc.CellTy)
          return false;
        Acc.Loads.push_back(L);
        continue;
      }
      if (auto *S = dyn_cast<StoreInst>(I)) {
        if (!S->isSimple() || S->getValueOperand() == P)
          return false;
        if (S->getValueOperand()->getType() == Acc.CellTy) {
          Acc.Stores.push_back(S);
          continue;
        }
        if (P == AI && isa<Constant>(S->getValueOperand())) {
          Acc.Others.push_back(S);  // a whole-object classical initializer.
          continue;
        }
        return false;
      }
      if (auto *II = dyn_cast<IntrinsicInst>(I)) {
        Intrinsic::ID Id = II->getIntrinsicID();
        if (Id == Intrinsic::lifetime_start || Id == Intrinsic::lifetime_end ||
            ((Id == Intrinsic::memset || Id == Intrinsic::memset_inline) &&
             P == AI && II->getArgOperand(0) == AI && !II->isVolatile())) {
          Acc.Others.push_back(II);
          continue;
        }
      }
      return false;
    }
  }
  // F4 (review round 1, R8): leaf accesses in INSTRUCTION order, never
  // use-list order, so the diagnostic location, the preheader insertion order
  // and the quantization-point fold are functions of the program alone.
  DenseMap<const Instruction *, unsigned> Pos;
  unsigned N = 0;
  for (Instruction &I : instructions(*AI->getFunction()))
    Pos[&I] = N++;
  auto ByPos = [&](const Instruction *X, const Instruction *Y) {
    return Pos.lookup(X) < Pos.lookup(Y);
  };
  llvm::sort(Acc.Loads, ByPos);
  llvm::sort(Acc.Stores, ByPos);
  llvm::sort(Acc.Others, ByPos);
  // Every leaf address is a whole cell: a byte view of a wider cell is mixed.
  for (Instruction *I : Acc.Loads)
    if (SE.getMinTrailingZeros(SE.getMinusSCEV(
            SE.getSCEV(getLoadStorePointerOperand(I)), Base)) <
        Log2_64(CellBytes))
      return false;
  for (Instruction *I : Acc.Stores)
    if (SE.getMinTrailingZeros(SE.getMinusSCEV(
            SE.getSCEV(getLoadStorePointerOperand(I)), Base)) <
        Log2_64(CellBytes))
      return false;
  return true;
}

// S1: the claim.
bool claims(AllocaInst *AI, const TaintSet &taint, DominatorTree &DT,
            LoopInfo &LI, ScalarEvolution &SE, RailWindowAccesses &Acc) {
  if (railBankInstReaches(AI->getParent()->getTerminator(), AI))
    return false;  // allocated once per cycle trip: not one object.
  if (!collectAccesses(AI, taint, SE, Acc))
    return false;
  // The storage must be live at every access (the rail-bank `kMsgBankLifetime`
  // question, asked here because a refused claim leaves the array to that
  // decline): a `lifetime.start` that some access precedes (it re-starts the
  // object, e.g. inside the walk) or a `lifetime.end` that some access follows
  // ends the object's contents; a runtime-sized object is released by any
  // `stackrestore`.
  SmallVector<Instruction *, 32> All(Acc.Loads.begin(), Acc.Loads.end());
  All.append(Acc.Stores.begin(), Acc.Stores.end());
  SmallPtrSet<const Instruction *, 4> Starts, Ends;
  for (Instruction *O : Acc.Others)
    if (auto *II = dyn_cast<IntrinsicInst>(O)) {
      if (II->getIntrinsicID() == Intrinsic::lifetime_start)
        Starts.insert(II);
      if (II->getIntrinsicID() == Intrinsic::lifetime_end)
        Ends.insert(II);
    }
  // A start that some access reaches WITHOUT passing an end re-starts live
  // contents; an end that some access follows without a new start ends them.
  for (Instruction *A : All) {
    for (const Instruction *S : Starts)
      if (reachesAvoiding(A, S, Ends))
        return false;
    for (const Instruction *E : Ends)
      if (reachesAvoiding(E, A, Starts))
        return false;
  }
  // F3 (a): an object declared inside a loop body. Its one start is
  // re-executed per iteration (an end separates the iterations, checked
  // above); it must dominate every access, and it is then the quantization
  // point: the cells get fresh rails per iteration, the old ones are left
  // allocated (Q3). More than one re-executed start is not modelled.
  for (const Instruction *S : Starts)
    if (railBankInstReaches(S, S)) {
      if (Acc.ScopeStart)
        return false;
      Acc.ScopeStart = const_cast<Instruction *>(S);
    }
  if (Acc.ScopeStart)
    for (Instruction *A : All)
      if (!DT.dominates(Acc.ScopeStart, A))
        return false;
  // F3 (b): a runtime-sized object is released by a `stackrestore` only on a
  // path from its allocation to one of its accesses (per object, the
  // rail-bank Lifetime clause's question): any other `stackrestore` in the
  // function belongs to someone else.
  if (!AI->isStaticAlloca())
    for (Instruction &I : instructions(*AI->getFunction()))
      if (auto *II = dyn_cast<IntrinsicInst>(&I))
        if (II->getIntrinsicID() == Intrinsic::stackrestore &&
            railBankInstReaches(AI, II))
          for (Instruction *A : All)
            if (railBankInstReaches(II, A))
              return false;
  bool AnyTainted = false;
  for (StoreInst *S : Acc.Stores) {
    if (!taint.Tainted.count(S->getValueOperand()))
      continue;
    AnyTainted = true;
    const char *Msg = nullptr;
    RailBankCarve V = railBankCarveVerdict(S, taint, DT, LI, SE, Msg);
    if (V == RailBankCarve::Bank || V == RailBankCarve::BankRaw)
      return false;  // the rolled one-store bank owns it (Q5).
  }
  return AnyTainted;
}

Instruction *ncd(DominatorTree &DT, Instruction *A, Instruction *B) {
  if (A->getParent() == B->getParent())
    return A->comesBefore(B) ? A : B;
  BasicBlock *N = DT.findNearestCommonDominator(A->getParent(), B->getParent());
  if (N == A->getParent())
    return A;
  if (N == B->getParent())
    return B;
  return N->getTerminator();
}

// S2: the quantization point (null only for an array with no tainted store,
// which the claim already refused).
Instruction *quantizationPoint(const RailWindowAccesses &Acc,
                               const TaintSet &taint, DominatorTree &DT,
                               LoopInfo &LI) {
  if (Acc.ScopeStart)
    return Acc.ScopeStart;  // F3 (a): re-quantized per iteration.
  Instruction *Q = nullptr;
  for (StoreInst *S : Acc.Stores) {
    if (!taint.Tainted.count(S->getValueOperand()))
      continue;
    Instruction *P = S;
    if (Loop *L = LI.getLoopFor(S->getParent())) {
      L = L->getOutermostLoop();
      if (BasicBlock *PH = L->getLoopPreheader())
        P = PH->getTerminator();
      else if (auto *N = DT.getNode(L->getHeader())->getIDom())
        P = N->getBlock()->getTerminator();
    }
    Q = Q ? ncd(DT, Q, P) : P;
  }
  if (!Q)
    return nullptr;
  SmallVector<Instruction *, 32> All(Acc.Loads.begin(), Acc.Loads.end());
  All.append(Acc.Stores.begin(), Acc.Stores.end());
  // Hoist until Q dominates every access reachable from it AND runs once: a
  // point inside a cycle (LoopInfo's or an irreducible one) moves to its
  // immediate dominator's terminator. The entry block is in no cycle and
  // dominates everything, so this always terminates with a point.
  for (bool Changed = true; Changed;) {
    Changed = false;
    for (Instruction *A : All)
      if (A != Q && !DT.dominates(Q, A) && railBankInstReaches(Q, A)) {
        Q = ncd(DT, Q, A);
        Changed = true;
      }
    if (railBankInstReaches(Q, Q)) {
      auto *N = DT.getNode(Q->getParent())->getIDom();
      Q = N ? N->getBlock()->getTerminator()
            : &*Q->getParent()->getFirstInsertionPt();
      Changed = true;
    }
  }
  return Q;
}

}  // namespace

bool declineRailWindowArrays(Module &M, const TaintSet &taint) {
  for (Function &F : M) {
    if (F.isDeclaration() || F.callsFunctionThatReturnsTwice())
      continue;
    SmallVector<AllocaInst *, 4> Allocas;
    for (Instruction &I : instructions(F))
      if (auto *A = dyn_cast<AllocaInst>(&I))
        if (isa<ArrayType>(A->getAllocatedType()) || A->isArrayAllocation())
          Allocas.push_back(A);
    if (Allocas.empty())
      continue;
    DominatorTree DT(F);
    LoopInfo LI(DT);
    AssumptionCache AC(F);
    TargetLibraryInfoImpl TLII(Triple(M.getTargetTriple()));
    TargetLibraryInfo TLI(TLII);
    ScalarEvolution SE(F, TLI, AC, DT, LI);
    for (AllocaInst *AI : Allocas) {
      RailWindowAccesses Acc;
      if (!claims(AI, taint, DT, LI, SE, Acc))
        continue;
      DebugLoc DL;
      for (StoreInst *S : Acc.Stores)
        if (taint.Tainted.count(S->getValueOperand())) {
          DL = S->getDebugLoc();
          break;
        }
      // S2 needs a preheader on every outermost loop around a tainted write
      // (-O1 routinely enters a loop straight from the previous loop's latch,
      // as dicke_n.c's init walk does): split that edge first, so Q is a point
      // executed once rather than a loop block.
      for (StoreInst *S : Acc.ScopeStart ? ArrayRef<StoreInst *>()
                                         : ArrayRef<StoreInst *>(Acc.Stores))
        if (taint.Tainted.count(S->getValueOperand()))
          if (Loop *L = LI.getLoopFor(S->getParent()))
            if (!L->getOutermostLoop()->getLoopPreheader())
              InsertPreheaderForLoop(L->getOutermostLoop(), &DT, &LI,
                                     /*MSSAU=*/nullptr,
                                     /*PreserveLCSSA=*/false);
      Instruction *Q = quantizationPoint(Acc, taint, DT, LI);
      if (dbg()) {
        errs() << "CQ_RAILWINDOW_DBG: @" << F.getName() << " claims ";
        AI->printAsOperand(errs(), false);
        errs() << " cells=" << *Acc.CellTy << " loads=" << Acc.Loads.size()
               << " stores=" << Acc.Stores.size() << " Q=";
        if (Q)
          errs() << *Q;
        else
          errs() << "<none>";
        errs() << "\n";
      }
      // S3: promote the windows, then re-derive everything from the new IR.
      unsigned N = promoteRailWindows(F, Acc);
      DominatorTree DT2(F);
      LoopInfo LI2(DT2);
      AssumptionCache AC2(F);
      ScalarEvolution SE2(F, TLI, AC2, DT2, LI2);
      RailWindowAccesses Acc2;
      std::string Msg =
          collectAccesses(AI, taint, SE2, Acc2)
              ? railWindowNeeds(F, Acc2, taint, LI2, SE2)
              // Unreachable (promotion keeps the access vocabulary); if it
              // ever fires, claim every pending step rather than guess.
              : railWindowAllNeeds();
      if (dbg()) {
        errs() << "CQ_RAILWINDOW_DBG: promoted " << N << " cell class(es)\n";
        errs() << "=== CQ_RAILWINDOW_DBG: @" << F.getName()
               << " after window promotion ===\n";
        F.print(errs());
      }
      F.getContext().diagnose(DiagnosticInfoUnsupported(F, Msg, DL));
      return true;
    }
  }
  return false;
}

}  // namespace cq
