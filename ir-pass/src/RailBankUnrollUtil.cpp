// RailBankUnrollUtil.cpp — bd `test_C_libtooling-01po.19`: the LLVM-utility half
// of `unrollQuantumArrayWalks` (the trip choice, the exact full unroll and the
// `-O1` cleanup), split from RailBankUnroll.cpp for the 400-line limit. See
// RailBankUnroll.h for the contract.

#include "RailBankUnrollUtil.h"

#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/OptimizationRemarkEmitter.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/InstCombine/InstCombine.h"
#include "llvm/Transforms/Scalar/EarlyCSE.h"
#include "llvm/Transforms/Scalar/InstSimplifyPass.h"
#include "llvm/Transforms/Scalar/SROA.h"
#include "llvm/Transforms/Scalar/SimplifyCFG.h"
#include "llvm/Transforms/Utils/LoopSimplify.h"
#include "llvm/Transforms/Utils/LoopUtils.h"
#include "llvm/Transforms/Utils/UnrollLoop.h"

using namespace llvm;

namespace cq {

// The trip `UnrollLoop` fully unrolls `L` by: the SCEV constant MAX trip count
// (review round 1, item 3). When the exact count is also constant the two are
// equal (the `LoopUnrollPrepass` U6 proof). When it is not (an early exit on a
// measured cell) `Count == MaxTripCount` still completes the unroll and keeps
// every unproven exit as a conditional branch in each copy, so the program is
// unchanged. 0 means "not unrollable here".
unsigned unrollTrip(Loop *L, ScalarEvolution &SE, unsigned MaxTrip) {
  unsigned Max = SE.getSmallConstantMaxTripCount(L);
  if (Max == 0 || Max > MaxTrip)
    return 0;
  unsigned Exact = SE.getSmallConstantTripCount(L);
  if (Exact != 0 && Exact != Max)
    return 0;
  if (!L->isSafeToClone() || L->getHeader()->hasAddressTaken())
    return 0;
  return Max;
}

// One full unroll of `L` by `Trip`. The `LoopUnrollPrepass.cpp` call
// sequence, including its LCSSA lesson (an out-of-loop use of an in-loop
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

// The stock cleanup a hand-unrolled source gets at `clang -O1`.
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

std::string headerName(const Loop *L) {
  std::string S;
  raw_string_ostream OS(S);
  L->getHeader()->printAsOperand(OS, /*PrintType=*/false);
  return OS.str();
}

}  // namespace cq
