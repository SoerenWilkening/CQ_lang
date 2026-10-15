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

// Mirrored CHARACTER-FOR-CHARACTER by railwindow_reject_quantum_extent.ll.
constexpr char kMsgWindowQuantumExtent[] =
    "cq rail window: quantum array extent is a quantum value";
// Mirrored CHARACTER-FOR-CHARACTER by railwindow_reject_stale_cell_read.ll and
// railwindow_reject_stale_parked_rail.ll (RailWindowFence.cpp).
constexpr char kMsgWindowStale[] =
    "cq rail window: quantum-array cell rail read past a non-diagonal gate "
    "on that array";

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
        if (!L->isSimple())
          return false;
        if (L->getType() == Acc.CellTy) {
          Acc.Loads.push_back(L);
          continue;
        }
        // A wider integer read of the object's start (-O1's `r = q` copy
        // loop): classical before Q, a cell COPY after it (review C-F1).
        if (P != AI || !L->getType()->isIntegerTy())
          return false;
        Acc.Others.push_back(L);
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
        // S4: clang's `T q[N] = {5, 6, 7}` — a copy FROM a constant global
        // INTO the whole object (classical before Q; refused after it).
        if (auto *MC = dyn_cast<MemCpyInst>(II);
            MC && P == AI && MC->getDest() == AI && !MC->isVolatile())
          if (auto *GV = dyn_cast<GlobalVariable>(MC->getSource());
              GV && GV->isConstant() && GV->hasDefinitiveInitializer()) {
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
      if (railWindowReachesAvoiding(A, S, Ends))
        return false;
    for (const Instruction *E : Ends)
      if (railWindowReachesAvoiding(E, A, Starts))
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

}  // namespace

bool lowerRailWindowArrays(Module &M, const TaintSet &taint, bool &Changed) {
  if (declineForeignRailWindowRecords(M))
    return true;
  TargetLibraryInfoImpl TLII(Triple(M.getTargetTriple()));
  TargetLibraryInfo TLI(TLII);
  for (Function &F : M) {
    if (F.isDeclaration() || F.callsFunctionThatReturnsTwice())
      continue;
    SmallVector<AllocaInst *, 4> Allocas;
    for (Instruction &I : instructions(F))
      if (auto *A = dyn_cast<AllocaInst>(&I))
        if (isa<ArrayType>(A->getAllocatedType()) || A->isArrayAllocation())
          Allocas.push_back(A);
    // One array at a time, every analysis rebuilt from the IR the previous
    // array's transform left (R9: nothing cached across a mutation).
    for (AllocaInst *AI : Allocas) {
      DominatorTree DT(F);
      LoopInfo LI(DT);
      AssumptionCache AC(F);
      ScalarEvolution SE(F, TLI, AC, DT, LI);
      RailWindowAccesses Acc;
      if (!claims(AI, taint, DT, LI, SE, Acc))
        continue;
      DebugLoc DL;
      for (StoreInst *S : Acc.Stores)
        if (taint.Tainted.count(S->getValueOperand())) {
          DL = S->getDebugLoc();
          break;
        }
      // Addendum note 3: a QUANTUM extent is a quantum-sized allocation; the
      // handle walk needs a classical cell count.
      if (AI->isArrayAllocation() &&
          taint.Tainted.count(AI->getArraySize())) {
        F.getContext().diagnose(
            DiagnosticInfoUnsupported(F, kMsgWindowQuantumExtent, DL));
        return true;
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
      Instruction *Q = railWindowQuantizationPoint(Acc, taint, DT, LI);
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
      // S4: every post-Q access now names the handle array `W`.
      AllocaInst *W = materializeRailWindow(F, Acc, Q);
      if (!W)
        return true;  // diagnosed (loud, nothing lowered).
      if (!undoRailWindowHeaderPhis(F, W))  // design Q6 (a), S5
        return true;
      Changed = true;
      // S3 on the handle array, then re-derive everything from the new IR.
      // `collectAccesses` failing on `W` is unreachable (the redirect emits
      // only its vocabulary); if it ever fires, claim every pending step.
      unsigned N = 0;
      std::string Msg = railWindowAllNeeds();
      Instruction *Stale = nullptr, *Copy = nullptr;
      RailWindowAccesses AccW;
      for (int Round = 0; Round < 2; ++Round) {
        DominatorTree DT2(F);
        LoopInfo LI2(DT2);
        AssumptionCache AC2(F);
        ScalarEvolution SE2(F, TLI, AC2, DT2, LI2);
        if (!collectAccesses(W, taint, SE2, AccW))
          break;
        if (Round == 0) {
          N = promoteRailWindows(F, AccW);
          continue;
        }
        Msg = railWindowNeeds(F, AccW, taint, LI2, SE2);
        SmallPtrSet<Value *, 32> QD;
        railWindowQuantum(F, AccW, taint, QD);
        if (Msg.empty()) {
          Copy = railWindowCellCopy(F, AccW);
          Stale = railWindowStaleUse(F, AccW, QD, SE2,
                                     computeWindowRegions(F, LI2));
        }
      }
      if (dbg()) {
        errs() << "CQ_RAILWINDOW_DBG: promoted " << N << " cell class(es)\n";
        errs() << "=== CQ_RAILWINDOW_DBG: @" << F.getName()
               << " after window promotion ===\n";
        F.print(errs());
      }
      if (!Msg.empty()) {
        F.getContext().diagnose(DiagnosticInfoUnsupported(F, Msg, DL));
        return true;
      }
      if (Instruction *Bad = Copy ? Copy : Stale) {
        F.getContext().diagnose(DiagnosticInfoUnsupported(
            F, Copy ? railWindowCopyNeeds() : std::string(kMsgWindowStale),
            Bad->getDebugLoc()));
        return true;
      }
      markRailWindowAlloca(W, AccW.CellTy);
    }
  }
  return false;
}

}  // namespace cq
