// MergeCarriedFence.cpp — see header (bd test_C_libtooling-r2j3.32).

#include "MergeCarriedFence.h"
#include "MergeStreamGates.h"  // calleeName / readsState / isRegister /
                               // handleAliases

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

const char kMsgCarriedMergeLeak[] =
    "cq merge discharge: non-diagonal gate on a register a leaked "
    "loop-carried merge rail records";

namespace {

// The loop across whose back edge `Out` is carried: the outermost loop
// containing it whose header has a φ that takes `Out`. Null: not carried.
Loop *carriedLoop(CallInst *Out, LoopInfo &LI) {
  Loop *Hit = nullptr;
  for (Loop *L = LI.getLoopFor(Out->getParent()); L; L = L->getParentLoop())
    for (User *U : Out->users())
      if (auto *P = dyn_cast<PHINode>(U); P && P->getParent() == L->getHeader())
        Hit = L;
  return Hit;
}

// The HANDLES a call touches: every i32 register operand in a state slot
// (`readsState`: not an alloc seed, not a template's literal), plus its i32
// result when that result is a fresh handle (a runtime or lifted producer,
// never a measurement's classical value).
void handlesOf(CallInst *C, const TaintSet &taint,
               SmallVectorImpl<Value *> &H) {
  for (unsigned S = 0, E = C->arg_size(); S != E; ++S) {
    Value *Op = C->getArgOperand(S);
    if (Op->getType()->isIntegerTy(32) && readsState(C, S) &&
        isRegister(Op, taint))
      H.push_back(Op);
  }
  StringRef N = calleeName(C);
  if (C->getType()->isIntegerTy(32) && !N.starts_with("cqrt_measure") &&
      (N.starts_with("cqrt_") || N.starts_with("cq_template_") ||
       N.starts_with("__cq_q_")))
    H.push_back(C);
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
  for (CallInst *Out : Left) {
    Loop *L = carriedLoop(Out, LI);
    if (!L)
      continue;
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
        handlesOf(C, taint, H);
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
    // THE HAZARD: after the loop exit (outside the carried loop, reachable
    // from it), a use of a protected register in a slot `slotAllowed` does
    // not clear. Inside the loop each trip's gates are the per-trip body the
    // control-lowering fences already adjudicate; after the exit the leaked
    // records are what is left to protect (header, "WHERE").
    BasicBlock *Hd = L->getHeader();
    for (CallInst *C : Calls) {
      if (L->contains(C->getParent()) ||
          !isPotentiallyReachable(Hd, C->getParent(), nullptr, &DT, &LI))
        continue;
      for (unsigned S = 0, E = C->arg_size(); S != E; ++S)
        if (P.count(C->getArgOperand(S)) && !slotAllowed(C, S))
          return loud(C);
    }
  }
  return false;
}

}  // namespace cq
