// MergeCarriedFence.cpp — see header (bd test_C_libtooling-r2j3.32, r2j3.36).

#include "MergeCarriedFence.h"
#include "InPlaceQQ.h"         // isInPlaceQQGate (bd r2j3.33)
#include "MergeStreamGates.h"  // calleeName / readsState / isRegister /
                               // handleAliases

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/CFG.h"
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

bool isRuntime(StringRef N) {
  return N.starts_with("cqrt_") || N.starts_with("cq_template_");
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
      (isRuntime(N) || N.starts_with("__cq_q_")))
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
  if (Ctl && S == 0 && isRuntime(N))
    return true;
  return N.starts_with("cqrt_rz") || N == "cqrt_x" || N == "cqrt_cnot" ||
         N == "cqrt_toffoli" || N == "cqrt_cswap" ||
         N.starts_with("cqrt_addc_") || N.starts_with("cqrt_xorc_") ||
         isInPlaceQQGate(C) ||  // bd r2j3.33: a basis permutation, by TAG

         N.starts_with("cqrt_copy_") || N == "cqrt_free" ||
         N.starts_with("cqrt_measure_") ||
         (N.starts_with("cq_template_") && !Ctl);
}

// Is there a CFG path that runs `From`, then `To`, on which `Redef` does NOT
// run strictly in between (bd r2j3.36)? Block-level search through LLVM's
// `isPotentiallyReachableFromMany` with `Redef`'s block excluded (entering it
// from the top runs `Redef`), no DT/LI shortcut (both would answer "yes" past
// the exclusion); its block budget answers "yes" when exceeded — the
// conservative side here. `From == To` asks for a cycle.
bool runsWithoutRedef(const Instruction *From, const Instruction *To,
                      const Instruction *Redef) {
  const BasicBlock *FB = From->getParent(), *TB = To->getParent(),
                   *RB = Redef->getParent();
  // Straight down one block.
  if (FB == TB && From->comesBefore(To))
    return !(RB == FB && From->comesBefore(Redef) && Redef->comesBefore(To));
  // Otherwise the path leaves `From`'s block by its tail and enters `To`'s
  // block from its top.
  if (RB == FB && From->comesBefore(Redef))
    return false;
  if (RB == TB && Redef->comesBefore(To))
    return false;
  SmallVector<BasicBlock *, 8> WL;
  for (const BasicBlock *S : successors(FB))
    WL.push_back(const_cast<BasicBlock *>(S));
  if (WL.empty())
    return false;
  SmallPtrSet<BasicBlock *, 1> Ex;
  Ex.insert(const_cast<BasicBlock *>(RB));
  return isPotentiallyReachableFromMany(WL, TB, &Ex, nullptr, nullptr);
}

// FRESH AT `C` (bd r2j3.36): `V` is a `cqrt_alloc_*` result, and no use that
// can couple its CURRENT instance to another register runs between that alloc
// and `C`. A coupling use is any use of a member of `V`'s alias class
// (`handleAliases`; unprovable: not fresh) other than a carrier inside the
// class, a park into its proven rail bank, or a RUNTIME call touching one
// handle (a local gate, a measurement, a free). A register no coupling ever
// reached is in a product state: no gate on it can interfere branches a record
// tells apart. Anything else — a template result (born entangled with its
// operands), a φ, a bank load — is never fresh.
bool freshAt(Value *V, const Instruction *C, const TaintSet &taint,
             const DominatorTree &DT) {
  auto *A = dyn_cast<CallInst>(V);
  if (!A || !calleeName(A).starts_with("cqrt_alloc_"))
    return false;
  SmallPtrSet<Value *, 8> Cls;
  if (!handleAliases(A, taint, DT, Cls))
    return false;
  for (Value *M : Cls)
    for (User *U : M->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I)
        return false;
      if (Cls.count(I) || isa<StoreInst>(I))
        continue;  // a carrier in the class; a proven bank park.
      if (auto *K = dyn_cast<CallInst>(I); K && isRuntime(calleeName(K))) {
        SmallVector<Value *, 4> H;
        handlesOf(K, taint, H);
        if (H.size() < 2)
          continue;
      }
      if (runsWithoutRedef(A, I, A) && runsWithoutRedef(I, C, A))
        return false;
    }
  return true;
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
    if (!carriedLoop(Out, LI))
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
    // THE HAZARD (bd r2j3.36: everywhere, not only after the loop exit): a
    // use of a protected register in a slot `slotAllowed` does not clear, at
    // a call the rail's allocation can reach (a record can exist there; in
    // the loop that is every call, across the back edge), unless the register
    // is FRESH there — allocated and never coupled since (`freshAt`).
    for (CallInst *C : Calls) {
      if (!isPotentiallyReachable(Out, C, nullptr, &DT, &LI))
        continue;
      for (unsigned S = 0, E = C->arg_size(); S != E; ++S) {
        Value *V = C->getArgOperand(S);
        if (P.count(V) && !slotAllowed(C, S) && !freshAt(V, C, taint, DT))
          return loud(C);
      }
    }
  }
  return false;
}

}  // namespace cq
