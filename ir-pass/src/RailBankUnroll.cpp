// RailBankUnroll.cpp — bd `test_C_libtooling-01po.19`: unroll the constant-trip
// loops that index a quantum local array, then scalarize the array with SROA.
// The contract, the soundness argument, the Bennett references and the slot
// are in RailBankUnroll.h.

#include "RailBankUnroll.h"

#include "QramLowering.h"  // railBankCarveVerdict / RailBankCarve
#include "RailBankUnrollUtil.h"
#include "TaintPropagation.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/OptimizationRemarkEmitter.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/TargetParser/Triple.h"
#include "llvm/Transforms/InstCombine/InstCombine.h"
#include "llvm/Transforms/Scalar/EarlyCSE.h"
#include "llvm/Transforms/Scalar/InstSimplifyPass.h"
#include "llvm/Transforms/Scalar/SROA.h"
#include "llvm/Transforms/Scalar/SimplifyCFG.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/LoopSimplify.h"
#include "llvm/Transforms/Utils/LoopUtils.h"
#include "llvm/Transforms/Utils/UnrollLoop.h"

#include <cstdlib>
#include <string>

using namespace llvm;

namespace cq {

namespace {

// Bounds on code growth. A trip above this, or a function that would grow past
// the instruction cap, keeps its existing loud decline (RailBankUnroll.h).
constexpr unsigned kMaxUnrollTrip = 256;
constexpr unsigned kMaxFunctionInsts = 20000;
constexpr unsigned kMaxRounds = 512;

bool dbg() { return std::getenv("CQ_RAILBANK_UNROLL_DBG") != nullptr; }

unsigned instCount(const Function &F) {
  unsigned N = 0;
  for (const BasicBlock &BB : F)
    N += BB.size();
  return N;
}

// The address users of `AI`: every GEP rooted DIRECTLY at it. A nested GEP or
// any other pointer user makes the trial fail (SROA decides), so this only has
// to find the variable-index ones.
void collectGeps(AllocaInst *AI, SmallVectorImpl<GetElementPtrInst *> &Out) {
  for (User *U : AI->users())
    if (auto *G = dyn_cast<GetElementPtrInst>(U))
      Out.push_back(G);
}

// Every instruction that touches the array: its GEPs (where the index lives)
// and every other direct or one-GEP-deep user (loads, stores, markers).
SmallVector<Instruction *, 16> arrayAccesses(AllocaInst *AI) {
  SmallVector<Instruction *, 16> Out;
  for (User *U : AI->users()) {
    auto *I = dyn_cast<Instruction>(U);
    if (!I)
      continue;
    Out.push_back(I);
    if (isa<GetElementPtrInst>(I))
      for (User *GU : I->users())
        if (auto *GI = dyn_cast<Instruction>(GU))
          Out.push_back(GI);
  }
  return Out;
}

// Is `V` a store into `AI` (directly or through one of its GEPs)?
bool storesInto(const StoreInst *SI, const AllocaInst *AI) {
  const Value *P = SI->getPointerOperand();
  if (P == AI)
    return true;
  auto *G = dyn_cast<GetElementPtrInst>(P);
  return G && G->getPointerOperand() == AI;
}

// The candidate predicate (pure analysis on the ORIGINAL function).
//   (a) a static fixed-size array alloca in the entry block;
//   (b) quantum: some store into it stores a TAINTED value;
//   (c) no GEP into it has a tainted index (that is 7.5's QRAM axis);
//   (d) some variable-index GEP into it lies inside a loop (otherwise there is
//       nothing to unroll and `-O1`'s own SROA already had its chance).
// Clause (e), the rolled bank's priority, is asked per FUNCTION by the caller
// (`functionHasRolledBank`): unrolling a loop is a function-wide edit and
// would rewrite a rolled bank's walk that shares the function.
bool isCandidate(AllocaInst *AI, const TaintSet &taint, LoopInfo &LI) {
  if (!AI->isStaticAlloca() || AI->isArrayAllocation() ||
      !isa<ArrayType>(AI->getAllocatedType()))
    return false;
  SmallVector<GetElementPtrInst *, 8> Geps;
  collectGeps(AI, Geps);
  bool VarInLoop = false;
  for (GetElementPtrInst *G : Geps) {
    for (Value *Idx : G->indices())
      if (taint.Tainted.count(Idx))
        return false;  // (c)
    if (!G->hasAllConstantIndices() && LI.getLoopFor(G->getParent()))
      VarInLoop = true;
  }
  if (!VarInLoop)
    return false;  // (d)
  for (Instruction *I : arrayAccesses(AI))
    if (auto *SI = dyn_cast<StoreInst>(I))
      if (storesInto(SI, AI) && taint.Tainted.count(SI->getValueOperand()))
        return true;  // (b)
  return false;
}

// (e) The arrays the ROLLED rail bank owns in `F`: the object of every tainted
// store the ONE rail-bank verdict classifies `Bank` (promoted, or promotable as
// is) or `BankRaw` (the promoter's input). The priority is PER ARRAY (review
// round 1, item 2): such an array is never a candidate, and no loop that STORES
// into it is unrolled (that loop is its walk), but an unrelated array in the
// same function is still taken.
SmallPtrSet<AllocaInst *, 4> rolledBankAllocas(Function &F,
                                              const TaintSet &taint,
                                              DominatorTree &DT, LoopInfo &LI,
                                              ScalarEvolution &SE) {
  SmallPtrSet<AllocaInst *, 4> Out;
  for (Instruction &I : instructions(F)) {
    auto *SI = dyn_cast<StoreInst>(&I);
    if (!SI || !taint.Tainted.count(SI->getValueOperand()))
      continue;
    const char *Msg = nullptr;
    RailBankShape Shape;
    RailBankCarve V = railBankCarveVerdict(SI, taint, DT, LI, SE, Msg, &Shape);
    if ((V == RailBankCarve::Bank || V == RailBankCarve::BankRaw) &&
        Shape.Alloca)
      Out.insert(Shape.Alloca);
  }
  return Out;
}

// Does `L` store into one of the rolled banks (it is, or contains, a bank's
// walk)? Such a loop is left rolled for the bank.
bool loopStoresIntoBank(const Loop *L,
                        const SmallPtrSetImpl<AllocaInst *> &Banks) {
  for (const BasicBlock *BB : L->blocks())
    for (const Instruction &I : *BB)
      if (auto *SI = dyn_cast<StoreInst>(&I))
        for (AllocaInst *B : Banks)
          if (storesInto(SI, B))
            return true;
  return false;
}

// The outermost unrollable loop around `I` that does not store into a bank.
Loop *outermostUnrollableLoop(Instruction *I, LoopInfo &LI,
                              ScalarEvolution &SE,
                              const SmallPtrSetImpl<AllocaInst *> &Banks,
                              unsigned &TripOut) {
  Loop *Best = nullptr;
  for (Loop *L = LI.getLoopFor(I->getParent()); L; L = L->getParentLoop()) {
    unsigned Trip = unrollTrip(L, SE, kMaxUnrollTrip);
    if (Trip == 0 || loopStoresIntoBank(L, Banks))
      continue;
    Best = L;
    TripOut = Trip;
  }
  return Best;
}

// The trial, on the CLONE: unroll every unrollable loop that touches `AI`,
// clean up, and succeed iff the array is gone and nothing else was left in
// memory. With `YieldToBanks` a loop that stores into a rolled bank is never
// unrolled. Without it (the second trial, taken only when the first fails) such
// a loop may be unrolled — `-O1` fuses a bank's walk with another array's walk
// (review probe rv/p2) — but then every bank whose walk was unrolled must be
// scalarized too, so no bank is left half rolled. Loops are chosen in INSTRUCTION order (review round
// 1, item 1), never in `users()` order: a use list is not program order, and it
// differs between a function and its clone.
bool trialTransform(Function &F, AllocaInst *AI,
                    const SmallPtrSetImpl<AllocaInst *> &Banks,
                    bool YieldToBanks) {
  const SmallPtrSet<AllocaInst *, 4> NoBanks;
  const SmallPtrSetImpl<AllocaInst *> &Fence = YieldToBanks ? Banks : NoBanks;
  SmallVector<WeakVH, 4> Touched;
  SmallPtrSet<AllocaInst *, 8> Before;
  for (Instruction &I : instructions(F))
    if (auto *A = dyn_cast<AllocaInst>(&I))
      if (A != AI)
        Before.insert(A);
  WeakVH Arr(AI);
  for (unsigned Round = 0; Round < kMaxRounds; ++Round) {
    auto *A = dyn_cast_or_null<AllocaInst>(Arr);
    if (!A)
      break;
    DominatorTree DT(F);
    LoopInfo LI(DT);
    AssumptionCache AC(F);
    TargetLibraryInfoImpl TLII(Triple(F.getParent()->getTargetTriple()));
    TargetLibraryInfo TLI(TLII);
    ScalarEvolution SE(F, TLI, AC, DT, LI);
    // Every ACCESS of the array inside an unrollable loop is unrolled out of
    // it, not only a variable-index one: a constant-index cell left inside a
    // rolled loop becomes a loop-carried register after SROA, and the
    // hand-unrolled program this stage stands in for has no such loop (F5's
    // inner `for (v…) if (c == v) cq_theta(&q[i], …)`). A variable index that
    // no loop resolves NOW may be resolved by a later round (a loop whose
    // bound another loop computes), so it fails the trial only when no access
    // offers an unrollable loop at all.
    SmallVector<Instruction *, 16> AccV = arrayAccesses(A);
    SmallPtrSet<Instruction *, 16> Acc(AccV.begin(), AccV.end());
    Loop *Pick = nullptr;
    unsigned Trip = 0;
    bool Unresolved = false;
    for (Instruction &I : instructions(F)) {
      if (!Acc.count(&I))
        continue;
      unsigned T = 0;
      if (Loop *L = outermostUnrollableLoop(&I, LI, SE, Fence, T)) {
        Pick = L;
        Trip = T;
        break;
      }
      auto *G = dyn_cast<GetElementPtrInst>(&I);
      if (G && !G->hasAllConstantIndices())
        Unresolved = true;
    }
    if (!Pick) {
      if (Unresolved)
        return false;  // a variable index no unrollable loop resolves.
      break;
    }
    if (dbg())
      errs() << "CQ_RAILBANK_UNROLL_DBG: unroll trip-" << Trip << " loop at "
             << headerName(Pick) << " in @" << F.getName() << "\n";
    for (AllocaInst *B : Banks) {
      SmallPtrSet<AllocaInst *, 1> One;
      One.insert(B);
      if (loopStoresIntoBank(Pick, One))
        Touched.push_back(WeakVH(B));
    }
    if (!fullyUnroll(F, Pick, Trip, DT, LI, SE, AC))
      return false;
    runCleanup(F, /*Full=*/false);
    if (instCount(F) > kMaxFunctionInsts)
      return false;
  }
  runCleanup(F, /*Full=*/true);
  if (Arr)
    return false;  // SROA could not promote the whole array.
  for (WeakVH &B : Touched)
    if (B)
      return false;  // a bank whose walk was unrolled stayed in memory.
  for (Instruction &I : instructions(F))
    if (auto *A = dyn_cast<AllocaInst>(&I))
      if (!Before.count(A))
        return false;  // a partially promoted residue of the array.
  return true;
}

// ADOPT the clone's transformed body whole: `F`'s body is dropped, the clone's
// blocks are spliced in, and `F` takes the clone's DISubprogram, which every
// spliced `!dbg` already names (`CloneFunction` mints a fresh one; keeping
// `F`'s old subprogram leaves every location pointing at the wrong function,
// MEASURED as a verifier abort on `-g`). The trial IS the adoption, so there is
// no second run to diverge (review round 1, item 1: the earlier re-run on the
// original read a different use-list order, could fail after a successful
// trial, and left the fixpoint spinning on an unchanged function).
void adoptBody(Function &F, Function *C) {
  for (BasicBlock &BB : F)
    BB.dropAllReferences();
  while (!F.empty())
    F.begin()->eraseFromParent();
  for (auto [A, CA] : zip(F.args(), C->args()))
    CA.replaceAllUsesWith(&A);
  F.splice(F.end(), C);
  F.setSubprogram(C->getSubprogram());
  C->setSubprogram(nullptr);
  C->eraseFromParent();
}

bool hasAddressTakenBlock(const Function &F) {
  for (const BasicBlock &BB : F)
    if (BB.hasAddressTaken())
      return true;
  return false;
}

}  // namespace

bool unrollQuantumArrayWalks(Module &M, const TaintSet &taint) {
  for (Function &F : M) {
    if (F.isDeclaration() || hasAddressTakenBlock(F))
      continue;
    // A `returns_twice` call re-runs code with no CFG edge (the rail-bank
    // verdict refuses it for the same reason); leave such a function alone.
    if (F.callsFunctionThatReturnsTwice())
      continue;
    bool AnyArray = false;
    for (Instruction &I : F.getEntryBlock())
      if (auto *A = dyn_cast<AllocaInst>(&I))
        if (isa<ArrayType>(A->getAllocatedType())) {
          AnyArray = true;
          break;
        }
    if (!AnyArray)
      continue;
    DominatorTree DT(F);
    LoopInfo LI(DT);
    if (LI.empty())
      continue;
    AssumptionCache AC(F);
    TargetLibraryInfoImpl TLII(Triple(M.getTargetTriple()));
    TargetLibraryInfo TLI(TLII);
    ScalarEvolution SE(F, TLI, AC, DT, LI);
    SmallPtrSet<AllocaInst *, 4> Banks =
        rolledBankAllocas(F, taint, DT, LI, SE);
    for (Instruction &I : F.getEntryBlock()) {
      auto *AI = dyn_cast<AllocaInst>(&I);
      if (!AI || Banks.count(AI) || !isCandidate(AI, taint, LI))
        continue;
      // THE TRIAL, on a clone: adopted whole or discarded whole, so a shape
      // this stage cannot finish reaches its existing owner byte-untouched.
      ValueToValueMapTy VMap;
      Function *C = CloneFunction(&F, VMap);
      auto *CAI = cast<AllocaInst>(VMap[AI]);
      SmallPtrSet<AllocaInst *, 4> CBanks;
      for (AllocaInst *B : Banks)
        CBanks.insert(cast<AllocaInst>(VMap[B]));
      bool OK = trialTransform(*C, CAI, CBanks, /*YieldToBanks=*/true);
      if (!OK && !Banks.empty()) {
        C->eraseFromParent();
        VMap.clear();
        C = CloneFunction(&F, VMap);
        CAI = cast<AllocaInst>(VMap[AI]);
        CBanks.clear();
        for (AllocaInst *B : Banks)
          CBanks.insert(cast<AllocaInst>(VMap[B]));
        OK = trialTransform(*C, CAI, CBanks, /*YieldToBanks=*/false);
      }
      if (dbg())
        errs() << "CQ_RAILBANK_UNROLL_DBG: @" << F.getName() << " array "
               << AI->getName() << (OK ? " scalarized" : " left for its owner")
               << "\n";
      if (!OK) {
        C->eraseFromParent();
        continue;
      }
      // `true` MEANS CHANGED: the adopted body has no `AI` (the trial proved
      // the array gone), so `F` is not what it was.
      adoptBody(F, C);
      return true;  // one function per call; the caller re-propagates.
    }
  }
  return false;
}

}  // namespace cq
