// Uncomputation.cpp — see header. Step-2 slice: select each tainted DATA
// terminal handle (ChainWalk::isTerminalHandle), recover its whole forward chain
// (ChainWalk::recoverForwardChain), and emit the reversed adjoint + `cqrt_free`
// at the register's last touch. Generalizes the Step-1 rotation-only slice to the
// RAUW reassignment lineage (`q = q + 1; q = q * 2`).
//
// Still CONSERVATIVE: in-shadow (controlled) adjoints land in Step 4, the
// post-dominator last-use / measure / escape classification productionizes in
// Step 3 (FreePoint), and cross-block / multi-register (QQ) whole-chain reversal
// is deferred. Until then this slice emits ONLY for an uncontrolled,
// single-register, single-block chain whose terminal is neither measured nor
// escaping — which keeps the pass live in both entry points without disturbing
// the pre-Phase-5 suite or the e2e goldens (every e2e data terminal is measured
// or in-shadow scratch).

#include "Uncomputation.h"

#include "ChainWalk.h"
#include "ControlledSymbols.h"
#include "EmitInverse.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

// A data-register producer we own: a tainted `cqrt_alloc_<W>` mint or an
// UNCONTROLLED `cq_template_*` result. Controlled results are Phase-4/in-shadow
// scratch (Step 4); rotations are void and never terminals.
bool isDataProducer(const CallInst *H) {
  const Function *Callee = H->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  if (N.starts_with("cqrt_alloc_"))
    return true;
  return N.starts_with("cq_template_") && !N.contains("_controlled");
}

// Does the terminal escape Phase-5 emission? Conservative pre-FreePoint guard
// (Step 3 productionizes this): a `ret` operand outlives the function, and a
// measured handle's lifetime ends at the measurement sink — neither is freed.
bool escapesOrMeasured(const Value *Terminal) {
  for (const User *U : Terminal->users()) {
    if (isa<ReturnInst>(U))
      return true;
    if (const auto *CI = dyn_cast<CallInst>(U)) {
      const Function *Callee = CI->getCalledFunction();
      if (Callee && Callee->getName().starts_with("cqrt_measure_"))
        return true;
    }
  }
  return false;
}

// Is every link of `Chain` something Step-2 can invert in place: a same-block,
// uncontrolled gate, and — for a data template — a SINGLE-register link (exactly
// one tainted operand)? A QQ template (two tainted operands) would branch the
// lineage (whole-chain multi-register reversal is deferred), and a controlled
// gate needs the Step-4 path; either disqualifies the whole terminal.
bool isStep2Emittable(const ForwardChain &Chain, const TaintSet &taint) {
  if (Chain.Calls.empty())
    return false;
  if (Chain.HasFanOut)
    return false;  // shared register / sibling branch — true DAG reversal deferred
  const BasicBlock *BB = Chain.Calls.front()->getParent();
  for (CallInst *G : Chain.Calls) {
    if (G->getParent() != BB)
      return false;  // cross-block chain — Step 3/6
    const Function *Callee = G->getCalledFunction();
    if (!Callee)
      return false;
    StringRef N = Callee->getName();
    if (N.contains("_controlled"))
      return false;  // in-shadow — Step 4
    if (N.starts_with("cq_template_")) {
      unsigned Tainted = 0;
      for (Value *Op : G->args())
        Tainted += taint.Tainted.count(Op) ? 1 : 0;
      if (Tainted != 1)
        return false;  // multi-register (QQ) link — deferred
    }
  }
  return true;
}

}  // namespace

void uncompute(Module &M, WidthDispatch &wd, TaintSet &taint) {
  ControlledSymbols csyms(M, wd);

  // Control-flag IMAGE (the flag VALUES, not the in-shadow data keys — the §2.2
  // direction trap): these are Phase-4 control scratch, never Phase-5 data
  // targets. Subtracting the image (not the keys) is finalized in Step 5; doing
  // it here keeps Step 2 from ever selecting a flag handle.
  SmallPtrSet<Value *, 8> FlagImage;
  for (auto &KV : taint.ControlFlag)
    FlagImage.insert(KV.second);

  // Module-scoped walk. In the `runOnFunction` shim only the requested F's ops
  // were lowered, so only F yields candidates (IMPLEMENTATION §8 Q4: the target
  // set reads the module-wide taint).
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;

    // Collect terminals FIRST (a full walk), then emit — so the freshly-inserted
    // adjoint / free / `_inv` calls are never re-scanned.
    SmallVector<CallInst *, 8> Terminals;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        auto *H = dyn_cast<CallInst>(&I);
        if (!H || !taint.Tainted.count(H) || !isDataProducer(H))
          continue;
        if (FlagImage.count(H))
          continue;  // control scratch, not a data target (§2.2)
        if (!isTerminalHandle(H, taint))
          continue;  // collapse the reassignment chain to one terminal (§2.1)
        Terminals.push_back(H);
      }
    if (Terminals.empty())
      continue;

    DominatorTree DT(F);
    IRBuilder<> B(F.getContext());
    for (CallInst *Term : Terminals) {
      if (escapesOrMeasured(Term))
        continue;

      ForwardChain Chain = recoverForwardChain(Term, taint, DT);
      if (!isStep2Emittable(Chain, taint))
        continue;

      // Last touch of the register = the last forward gate in program order.
      // Insert the reversed adjoint there (a call is never a terminator, so the
      // next node exists), then `cqrt_free` of the final threaded handle at the
      // SAME point (PRD §2.10). Step 3 routes placement through FreePoint's
      // post-dominator last-use.
      Instruction *At = Chain.Calls.back()->getNextNode();
      if (!At)
        continue;
      B.SetInsertPoint(At);
      Value *Final = emitInverseChain(B, Chain.Calls, wd, csyms,
                                      /*Flag=*/nullptr, /*Terminal=*/Term);
      if (!Final)
        continue;  // an un-invertible link bailed — emit no dangling free
      CallInst *Free = B.CreateCall(wd.freeFn(), {Final});
      if (DebugLoc DL = Term->getDebugLoc())
        Free->setDebugLoc(DL);
    }
  }
}

}  // namespace cq
