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
#include "FreePoint.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

// The uncompute-spine diagnostic FreePoint does NOT own (test_C_libtooling-3h8):
// a NON-terminal lineage handle of a dead terminal is read by a measurement
// sink. FreePoint inspects only the terminal's own users, so it never sees the
// upstream measure; ChainWalk (which recovers the whole lineage) flags it and
// the driver rejects here. LOUD reject, not a silent skip — a free of a
// measured register is a hidden projective collapse (Rule 5/6). The negative
// fixture lowering_uncompute_dead_sibling_premeasure.ll mirrors this string
// character-for-character.
constexpr char kMsgLineageMeasured[] =
    "cq uncompute: dead chain would free a measured register";

// Loud `DiagnosticInfoUnsupported(DS_Error)` on `Where`, with its `!dbg` so the
// rejection is SOURCE-LOCATED (mirrors FreePoint::diagnose). `opt` exits
// non-zero, which the negative LIT fixture inverts with `RUN: not`.
void diagnose(Instruction *Where, StringRef Msg) {
  Where->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *Where->getFunction(), Msg, Where->getDebugLoc()));
}

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

// Is every link of `Chain` something Step-2 can invert in place: a same-block,
// uncontrolled gate, and — for a data template — a SINGLE-register link (exactly
// one tainted operand)? A QQ template (two tainted operands) would branch the
// lineage (whole-chain multi-register reversal is deferred), and a controlled
// gate needs the Step-4 path; either disqualifies the whole terminal.
//
// SAME-BLOCK is REQUIRED and load-bearing for soundness, NOT a placement
// convenience: a chain that crosses blocks may have MUTUALLY-EXCLUSIVE per-arm
// links (e.g. a divergent `cqrt_rz` on each arm of an `i1` branch). A single
// unconditional adjoint at the merge post-dominator would re-emit EVERY arm's
// inverse on EVERY path — corrupting the register on each (divergent per-arm
// mutating reversal is deferred to Step 6, never relaxed in here). The both-arm
// case Phase 5 DOES handle is a forward chain wholly in a COMMON DOMINATOR whose
// divergent per-arm aspect is a non-mutating USE that merely extends the live
// range; FreePoint then post-dominates that use set to the merge, and the
// single same-block adjoint reversed there is sound.
bool isStep2Emittable(const ForwardChain &Chain, const TaintSet &taint) {
  if (Chain.Calls.empty())
    return false;
  if (Chain.HasFanOut)
    return false;  // shared register / sibling branch — true DAG reversal deferred
  const BasicBlock *BB = Chain.Calls.front()->getParent();
  for (CallInst *G : Chain.Calls) {
    if (G->getParent() != BB)
      return false;  // cross-block chain — Step 6 (deferred, see header above)
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
        if (!isTerminalHandle(H, taint))
          continue;  // collapse the reassignment chain to one terminal (§2.1)
        Terminals.push_back(H);
      }
    if (Terminals.empty())
      continue;

    DominatorTree DT(F);
    PostDominatorTree PDT(F);
    IRBuilder<> B(F.getContext());
    for (CallInst *Term : Terminals) {
      // FreePoint OWNS classification + placement (PRD §2.4/§2.5/§2.6/§2.9):
      // measure / escape (`ret` / `main` / `cq_invert_*`) skip with no emit; an
      // unrecognized user, a post-measure gate, a non-reconverging arm, or a
      // backedge-crossing live range is diagnosed LOUDLY inside `computeFreePoint`
      // (which makes `opt` exit non-zero). Only `Insert` proceeds to emission.
      FreePoint FP = computeFreePoint(Term, F, PDT, taint);
      if (FP.Kind != FreePointKind::Insert)
        continue;

      ForwardChain Chain = recoverForwardChain(Term, taint, DT);
      // Lineage-measure guard (test_C_libtooling-3h8): a NON-terminal lineage
      // handle is measured, so the whole-chain adjoint + `cqrt_free` would reset
      // a register the measurement still reads — a hidden collapse (Rule 5/6),
      // invisible to FreePoint (which inspects only the terminal's own users)
      // and to the fan-out guard (`forwardConsumerCount` excludes measure
      // sinks). Loud reject, never a silent skip.
      if (Chain.MeasuredUpstream) {
        diagnose(Chain.UpstreamMeasure ? Chain.UpstreamMeasure : Term,
                 kMsgLineageMeasured);
        continue;
      }
      if (!isStep2Emittable(Chain, taint))
        continue;

      // Anchor the reversed adjoint at FreePoint's post-dominating last-use point
      // (after φ-nodes for a φ-merge), then `cqrt_free` the final threaded handle
      // at the SAME point (PRD §2.10).
      B.SetInsertPoint(FP.At);
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
