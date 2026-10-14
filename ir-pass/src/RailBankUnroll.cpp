// RailBankUnroll.cpp — bd `test_C_libtooling-01po.19`: unroll the constant-trip
// loops that index a quantum local array, then scalarize the array with SROA.
// The contract, the soundness argument, the Bennett references and the slot
// are in RailBankUnroll.h.

#include "RailBankUnroll.h"

#include "QramLowering.h"  // railBankCarveVerdict / RailBankCarve
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

// (e) Does the ROLLED rail bank own anything in `F`? Any tainted store the ONE
// rail-bank verdict classifies `Bank` (promoted, or promotable as is) or
// `BankRaw` (the promoter's input) keeps the whole function out of this stage.
bool functionHasRolledBank(Function &F, const TaintSet &taint,
                           DominatorTree &DT, LoopInfo &LI,
                           ScalarEvolution &SE) {
  for (Instruction &I : instructions(F)) {
    auto *SI = dyn_cast<StoreInst>(&I);
    if (!SI || !taint.Tainted.count(SI->getValueOperand()))
      continue;
    const char *Msg = nullptr;
    RailBankCarve V = railBankCarveVerdict(SI, taint, DT, LI, SE, Msg);
    if (V == RailBankCarve::Bank || V == RailBankCarve::BankRaw)
      return true;
  }
  return false;
}

// The outermost loop around `G` with a SCEV-proven exact constant trip count
// (the `LoopUnrollPrepass` U6 proof: exact == max, so `UnrollLoop` completes).
Loop *outermostConstTripLoop(Instruction *I, LoopInfo &LI,
                             ScalarEvolution &SE, unsigned &TripOut) {
  Loop *Best = nullptr;
  for (Loop *L = LI.getLoopFor(I->getParent()); L; L = L->getParentLoop()) {
    unsigned Trip = SE.getSmallConstantTripCount(L);
    if (Trip == 0 || Trip > kMaxUnrollTrip ||
        SE.getSmallConstantMaxTripCount(L) != Trip)
      continue;
    if (!L->isSafeToClone() || L->getHeader()->hasAddressTaken())
      continue;
    Best = L;
    TripOut = Trip;
  }
  return Best;
}

// One full unroll of `L` by its exact trip. The `LoopUnrollPrepass.cpp`
// call sequence, including its LCSSA lesson (an out-of-loop use of an in-loop
// value is remapped through the exit LCSSA phis or it reads the FIRST trip).
bool fullyUnroll(Function &F, Loop *L, unsigned Trip, DominatorTree &DT,
                 LoopInfo &LI, ScalarEvolution &SE, AssumptionCache &AC) {
  if (!L->isLoopSimplifyForm() &&
      !simplifyLoop(L, &DT, &LI, &SE, &AC, /*MSSAU=*/nullptr,
                    /*PreserveLCSSA=*/false))
    return false;
  if (!L->getLoopPreheader() || !L->getLoopLatch())
    return false;
  formLCSSARecursively(*L, DT, &LI, &SE);
  TargetTransformInfo TTI(F.getParent()->getDataLayout());
  OptimizationRemarkEmitter ORE(&F);
  UnrollLoopOptions ULO;
  ULO.Count = Trip;
  ULO.Force = true;
  ULO.Runtime = false;
  ULO.AllowExpensiveTripCount = false;
  ULO.UnrollRemainder = false;
  ULO.ForgetAllSCEV = true;
  LoopUnrollResult R = UnrollLoop(L, ULO, &LI, &SE, &DT, &AC, &TTI, &ORE,
                                  /*PreserveLCSSA=*/true);
  return R == LoopUnrollResult::FullyUnrolled;
}

// The stock cleanup a hand-unrolled source gets at `clang -O1`, run on the
// trial clone only.
void runCleanup(Function &F, bool Full) {
  PassBuilder PB;
  LoopAnalysisManager LAM;
  FunctionAnalysisManager FAM;
  CGSCCAnalysisManager CGAM;
  ModuleAnalysisManager MAM;
  PB.registerModuleAnalyses(MAM);
  PB.registerCGSCCAnalyses(CGAM);
  PB.registerFunctionAnalyses(FAM);
  PB.registerLoopAnalyses(LAM);
  PB.crossRegisterProxies(LAM, FAM, CGAM, MAM);
  FunctionPassManager FPM;
  FPM.addPass(InstSimplifyPass());
  if (Full) {
    FPM.addPass(SROAPass(SROAOptions::ModifyCFG));
    FPM.addPass(EarlyCSEPass());
    FPM.addPass(InstCombinePass());
  }
  FPM.addPass(SimplifyCFGPass());
  if (Full)
    FPM.addPass(SROAPass(SROAOptions::ModifyCFG));
  FPM.run(F, FAM);
}

// The trial: unroll every constant-trip loop that touches `AI` (a variable
// index with no such loop around it fails the trial), clean up, and succeed
// iff the array is gone and nothing else was left in memory.
bool transform(Function &F, AllocaInst *AI) {
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
    // Every ACCESS of the array inside a constant-trip loop is unrolled out of
    // it, not only a variable-index one: a constant-index cell left inside a
    // rolled loop becomes a loop-carried register after SROA, and the
    // hand-unrolled program this stage stands in for has no such loop (F5's
    // inner `for (v…) if (c == v) cq_theta(&q[i], …)`). A VARIABLE index with
    // no constant-trip loop around it cannot be resolved: the trial fails.
    Loop *Pick = nullptr;
    unsigned Trip = 0;
    for (Instruction *Acc : arrayAccesses(A)) {
      auto *G = dyn_cast<GetElementPtrInst>(Acc);
      bool Variable = G && !G->hasAllConstantIndices();
      unsigned T = 0;
      Loop *L = outermostConstTripLoop(Acc, LI, SE, T);
      if (!L) {
        if (Variable)
          return false;  // a variable index no constant-trip loop resolves.
        continue;
      }
      Pick = L;
      Trip = T;
      break;
    }
    if (!Pick)
      break;
    if (dbg())
      errs() << "CQ_RAILBANK_UNROLL_DBG: unroll trip-" << Trip << " loop at "
             << Pick->getHeader()->getName() << " in @" << F.getName() << "\n";
    if (!fullyUnroll(F, Pick, Trip, DT, LI, SE, AC))
      return false;
    runCleanup(F, /*Full=*/false);
    if (instCount(F) > kMaxFunctionInsts)
      return false;
  }
  runCleanup(F, /*Full=*/true);
  if (Arr)
    return false;  // SROA could not promote the whole array.
  for (Instruction &I : instructions(F))
    if (auto *A = dyn_cast<AllocaInst>(&I))
      if (!Before.count(A))
        return false;  // a partially promoted residue of the array.
  return true;
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
    // A `returns_twice` call re-runs code with no CFG edge (the rail-bank
    // verdict refuses it for the same reason); leave such a function alone.
    if (F.callsFunctionThatReturnsTwice() ||
        functionHasRolledBank(F, taint, DT, LI, SE))
      continue;
    for (Instruction &I : F.getEntryBlock()) {
      auto *AI = dyn_cast<AllocaInst>(&I);
      if (!AI || !isCandidate(AI, taint, LI))
        continue;
      // THE TRIAL, on a clone: adopted whole or discarded whole, so a shape
      // this stage cannot finish reaches its existing owner byte-untouched.
      ValueToValueMapTy VMap;
      Function *C = CloneFunction(&F, VMap);
      auto *CAI = cast<AllocaInst>(VMap[AI]);
      bool OK = transform(*C, CAI);
      if (dbg())
        errs() << "CQ_RAILBANK_UNROLL_DBG: @" << F.getName() << " array "
               << AI->getName() << (OK ? " scalarized" : " left for its owner")
               << "\n";
      C->eraseFromParent();
      if (!OK)
        continue;
      // ADOPT by re-running the same deterministic transformation on `F`. The
      // clone's body is never spliced back: `CloneFunction` mints a fresh
      // DISubprogram, so a spliced body's `!dbg` points at the wrong subprogram
      // (MEASURED: the verifier aborts on any `-g` module).
      bool Again = transform(F, AI);
      if (dbg() && !Again)
        errs() << "CQ_RAILBANK_UNROLL_DBG: @" << F.getName()
               << " re-run diverged from the trial\n";
      return true;  // one function per call; the caller re-propagates.
    }
  }
  return false;
}

}  // namespace cq
