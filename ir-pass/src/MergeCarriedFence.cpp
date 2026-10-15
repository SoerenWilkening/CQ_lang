// MergeCarriedFence.cpp — see header (bd test_C_libtooling-r2j3.32, r2j3.36).

#include "MergeCarriedFence.h"
#include "InPlaceQQ.h"               // isInPlaceQQGate (bd r2j3.33)
#include "MergeCarriedFenceFresh.h"  // clause (iv), handles, path question
#include "MergeStreamGates.h"        // calleeName / handleAliases

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/TargetParser/Triple.h"

#include <memory>

using namespace llvm;

namespace cq {

const char kMsgCarriedMergeLeak[] =
    "cq merge discharge: non-diagonal gate on a register a leaked "
    "loop-carried merge rail records";

namespace {

// The loop across whose back edge `Out` is carried: the outermost loop
// containing it in which a member of `Out`'s alias class (`handleAliases`) is
// the loop's header φ, or a rail-bank cell LOAD inside the loop (R11 round 1,
// F2: a rail parked in a cell a later trip re-reads — S3's Q6(a) header-φ →
// cell-load rewrite produces exactly that). An unprovable class inside a loop
// counts as carried (fail closed: `protect` then fails loudly). Null: not
// carried.
Loop *carriedLoop(CallInst *Out, const TaintSet &taint, DominatorTree &DT,
                  LoopInfo &LI) {
  Loop *Inner = LI.getLoopFor(Out->getParent());
  if (!Inner)
    return nullptr;
  SmallPtrSet<Value *, 16> Cls;
  if (!handleAliases(Out, taint, DT, Cls))
    return Inner->getOutermostLoop();
  Loop *Hit = nullptr;
  for (Loop *L = Inner; L; L = L->getParentLoop())
    for (Value *M : Cls)
      if ((isa<PHINode>(M) &&
           cast<PHINode>(M)->getParent() == L->getHeader()) ||
          (isa<LoadInst>(M) && L->contains(cast<LoadInst>(M)->getParent())))
        Hit = L;
  return Hit;
}

// Is a use of a PROTECTED register in slot `S` of `C` safe? Only in a gate
// known to be diagonal or a computational-basis permutation, or as a control
// (R11 round 2: an allowlist; everything else — `cqrt_ry*`, `cqrt_h`, a
// controlled gate's target, a runtime gate added later, any call that is not
// the runtime, a lifted body included — fails closed).
bool slotAllowed(CallInst *C, unsigned S) {
  StringRef N = calleeName(C);
  if (N.starts_with("cq_measure"))
    return true;
  bool Ctl = N.contains("_controlled");
  if (Ctl && S == 0 &&
      (N.starts_with("cqrt_") || N.starts_with("cq_template_")))
    return true;
  return N.starts_with("cqrt_rz") || N == "cqrt_x" || N == "cqrt_cnot" ||
         N == "cqrt_toffoli" || N == "cqrt_cswap" ||
         N.starts_with("cqrt_addc_") || N.starts_with("cqrt_xorc_") ||
         isInPlaceQQGate(C) ||  // bd r2j3.33: a basis permutation, by TAG

         N.starts_with("cqrt_copy_") || N == "cqrt_free" ||
         N.starts_with("cqrt_measure_") ||
         (N.starts_with("cq_template_") && !Ctl);
}

}  // namespace

bool fenceCarriedMergeLeaks(Function &F, const TaintSet &taint,
                            ArrayRef<CallInst *> Left, DominatorTree &DT,
                            LoopInfo &LI) {
  auto loud = [&](const Instruction *At) {
    F.getContext().diagnose(DiagnosticInfoUnsupported(
        F, kMsgCarriedMergeLeak, At->getDebugLoc()));
    return true;
  };
  SmallVector<CallInst *, 64> Calls;
  for (BasicBlock &BB : F)
    for (Instruction &I : BB)
      if (auto *C = dyn_cast<CallInst>(&I))
        Calls.push_back(C);
  // SCEV for clause (iv)(b), built once and only when a carried rail exists
  // (the same standalone construction RailWindow / LoopLowering use).
  std::unique_ptr<AssumptionCache> AC;
  std::unique_ptr<TargetLibraryInfoImpl> TLII;
  std::unique_ptr<TargetLibraryInfo> TLI;
  std::unique_ptr<ScalarEvolution> SE;
  for (CallInst *Out : Left) {
    Loop *TL = carriedLoop(Out, taint, DT, LI);
    if (!TL)
      continue;
    if (!SE) {
      AC = std::make_unique<AssumptionCache>(F);
      TLII = std::make_unique<TargetLibraryInfoImpl>(
          Triple(F.getParent()->getTargetTriple()));
      TLI = std::make_unique<TargetLibraryInfo>(*TLII);
      SE = std::make_unique<ScalarEvolution>(F, *TLI, *AC, DT, LI);
    }
    // THE ENTANGLEMENT CLOSURE (R11 round 2, replacing three rounds of
    // per-path closures): start from the leaked rail; any call, ANYWHERE in
    // the function, touching two or more handles one of whose alias classes is
    // protected protects all of them (a CNOT kicks phase back onto its control
    // as surely as it copies into its target; a lifted call is not descended —
    // every handle it touches joins). To a fixpoint. A protected handle whose
    // alias class leaves through unproven memory fails loudly.
    SmallPtrSet<Value *, 32> P;
    auto protect = [&](Value *V) {
      SmallPtrSet<Value *, 8> Alias;
      if (!handleAliases(V, taint, DT, Alias))
        return false;
      P.insert(V);
      P.insert(Alias.begin(), Alias.end());
      return true;
    };
    if (!protect(Out))
      return loud(Out);
    for (bool Grew = true; Grew;) {
      Grew = false;
      for (CallInst *C : Calls) {
        SmallVector<Value *, 4> H;
        carriedFenceHandlesOf(C, taint, H);
        if (H.size() < 2 ||
            llvm::none_of(H, [&](Value *V) { return P.count(V) != 0; }))
          continue;
        for (Value *V : H)
          if (!P.count(V)) {
            if (!protect(V))
              return loud(C);
            Grew = true;
          }
      }
    }
    // THE HAZARD SET (header; bd r2j3.36: everywhere, not only after the loop
    // exit): a use of a protected register in a slot `slotAllowed` does not
    // clear, at a call the rail's allocation can reach (a record can exist
    // there; in the loop that is every call, across the back edge), unless
    // the register is FRESH there (`carriedFenceFreshAt`).
    for (CallInst *C : Calls) {
      if (!isPotentiallyReachable(Out, C, nullptr, &DT, &LI))
        continue;
      for (unsigned S = 0, E = C->arg_size(); S != E; ++S) {
        Value *V = C->getArgOperand(S);
        if (P.count(V) && !slotAllowed(C, S) &&
            !carriedFenceFreshAt(V, C, TL, taint, DT, *SE))
          return loud(C);
      }
    }
  }
  return false;
}

}  // namespace cq
