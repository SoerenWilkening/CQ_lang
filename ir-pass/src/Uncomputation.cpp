// Uncomputation.cpp — see header. The whole-DAG LIFO uncompute driver (Phase 5
// WI-4, PRD §2.1/§2.11). Selects each tainted DATA terminal handle
// (ChainWalk::isTerminalHandle), recovers the whole forward DAG over the SET of
// terminals (DagTraversal::recoverDataDag — fan-out and QQ are DAG shapes, not
// bails), and reverses it ONCE: a single reverse-topological pass adjoints each
// gate exactly once (void in-place `_unc`, EmitInverse) and frees each rail after
// its last reverse-use.
//
// The reversal is sound only for a CLOSED, non-measured, non-escaped DAG whose
// gates all dominate the single insertion point (acyclic + dominating ⇒ each gate
// ran exactly once on every reaching path). A measured intermediate declines
// LOUDLY (a free of a measured register is a hidden collapse, Rule 5/6); an
// escaped / not-closed / unplaceable DAG is a Rule-6/8 safe-leak (left allocated,
// never a dirty free). Phase-4-owned control rails are subtracted up front
// (DD-4 — `ControlOwnedRails`) so a flag / work / merge out-rail is never walked.

#include "Uncomputation.h"

#include "ChainWalk.h"          // isTerminalHandle
#include "DagTraversal.h"       // recoverDataDag / DataDag
#include "EmitInverse.h"        // emitInverseCall
#include "FreePoint.h"          // computeFreePoint
#include "TaintPropagation.h"   // TaintSet
#include "WidthDispatch.h"      // freeFn

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/LoopInfo.h"
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

// The uncompute-spine diagnostic FreePoint does NOT own (test_C_libtooling-3h8): a
// NON-terminal DAG rail is read by a measurement sink. FreePoint inspects only the
// terminal's own users, so it never sees the upstream measure; DagTraversal (which
// recovers the whole DAG) flags it and the driver rejects here. LOUD reject — a
// free of a measured register is a hidden projective collapse (Rule 5/6). The
// negative fixture lowering_uncompute_dead_sibling_premeasure.ll mirrors this
// string character-for-character.
constexpr char kMsgLineageMeasured[] =
    "cq uncompute: dead chain would free a measured register";

// WI-5 silent→loud flips (PRD §2.12; the Prime Directive — an unprovable shape
// declines, never silently leaks a dirty rail). The negative fixtures mirror
// each string CHARACTER-FOR-CHARACTER (Rule 12):
//   * lowering_uncompute_uninvertible.ll   → kMsgUninvertible
//   * lowering_uncompute_divergent_arm.ll  → kMsgDivergentArm
//
// A recovered gate Phase 5 has NO in-place adjoint for (a permutation primitive
// like `cqrt_cnot`, a controlled callee — outside `isInverseEmittable`). Pre-WI-5
// the driver IGNORED `emitInverseCall`'s `false` and still freed the rail =
// a dirty free (a hidden collapse, Rule 6/8). DD-1: the driver owns this message.
constexpr char kMsgUninvertible[] =
    "cq uncompute: dead chain contains an un-invertible primitive";

// A MUTATING gate that does not DOMINATE the single merge free point: it ran on
// only some exclusive paths, so one unconditional adjoint at the merge would fire
// on paths the forward gate never took (the reverted-543bd85 divergent-arm
// miscompile). Per-arm reverse-play is Phase 4's job; Phase 5 declines (§2.4).
constexpr char kMsgDivergentArm[] =
    "cq uncompute: dead chain spans divergent control-flow arms";

// Loud `DiagnosticInfoUnsupported(DS_Error)` on `Where`, with its `!dbg` so the
// rejection is SOURCE-LOCATED (mirrors FreePoint::diagnose). `opt` exits non-zero,
// which the negative LIT fixture inverts with `RUN: not`.
void diagnose(Instruction *Where, StringRef Msg) {
  Where->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *Where->getFunction(), Msg, Where->getDebugLoc()));
}

// A data-register producer we own: a tainted `cqrt_alloc_<W>` mint or an
// UNCONTROLLED `cq_template_*` result. Controlled results are Phase-4 scratch;
// rotations are void and never terminals.
bool isDataProducer(const CallInst *H) {
  const Function *Callee = H->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  if (N.starts_with("cqrt_alloc_"))
    return true;
  return N.starts_with("cq_template_") && !N.contains("_controlled");
}

// The RAIL a gate creates — the value the gate's adjoint zeroes, then the driver
// frees. An in-place rotation (`cqrt_ry/rz`, self-adjoint `cqrt_x`) acts on its
// arg-0 handle; a template producer's result IS the rail. (PRD §2.11.)
Value *railOf(CallInst *G) {
  const Function *Callee = G->getCalledFunction();
  StringRef N = Callee ? Callee->getName() : StringRef();
  if ((N.starts_with("cqrt_ry_") || N.starts_with("cqrt_rz_") || N == "cqrt_x") &&
      G->arg_size() >= 1)
    return G->getArgOperand(0);
  return G;
}

// The single insertion point for the whole-DAG reversal: the nearest common
// POST-dominator of every terminal's last-use anchor, after the latest anchor in
// that block (else its first insertion point, after φ-nodes). Null if the anchors
// do not reconverge (a non-reconverging multi-terminal shape — skip).
Instruction *dagInsertPoint(ArrayRef<Instruction *> Ats, PostDominatorTree &PDT) {
  BasicBlock *Common = Ats.front()->getParent();
  for (Instruction *A : Ats.drop_front()) {
    Common = PDT.findNearestCommonDominator(Common, A->getParent());
    if (!Common)
      return nullptr;
  }
  Instruction *Latest = nullptr;
  for (Instruction *A : Ats)
    if (A->getParent() == Common && (!Latest || Latest->comesBefore(A)))
      Latest = A;
  if (Latest)
    return Latest;
  BasicBlock::iterator FI = Common->getFirstInsertionPt();
  return FI == Common->end() ? nullptr : &*FI;
}

// Emit the whole-DAG adjoint at `At` (PRD §2.11): each gate's void `_unc` once, in
// reverse program order; each rail freed right after the adjoint of its EARLIEST
// forward gate — that adjoint is emitted LAST among the rail's reverse-touches
// (SSA dominance), so the free lands after every reverse-read of the rail.
void emitDagReversal(const DataDag &D, Instruction *At, WidthDispatch &wd) {
  DenseMap<Value *, CallInst *> Earliest;  // rail → its earliest forward gate
  for (CallInst *G : D.Calls)              // D.Calls is forward program order
    Earliest.try_emplace(railOf(G), G);    // first occurrence wins

  IRBuilder<> B(At);
  SmallPtrSet<CallInst *, 16> Seen;
  for (int i = (int)D.Calls.size() - 1; i >= 0; --i) {
    CallInst *G = D.Calls[i];
    if (!Seen.insert(G).second)
      continue;  // a shared-prefix gate already adjointed (once-per-gate)
    emitInverseCall(B, G, wd, /*CurHandle=*/nullptr);
    Value *R = railOf(G);
    if (Earliest.lookup(R) == G) {  // R fully reversed → free it
      CallInst *Free = B.CreateCall(wd.freeFn(), {R});
      if (DebugLoc DL = G->getDebugLoc())
        Free->setDebugLoc(DL);
    }
  }
}

}  // namespace

void uncompute(Module &M, WidthDispatch &wd, TaintSet &taint) {
  // Module-scoped walk. In the `runOnFunction` shim only the requested F's ops
  // were lowered, so only F yields candidates (the target set reads the
  // module-wide taint).
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;

    // 1. Collect terminal candidates: tainted data producers whose only users are
    //    benign, MINUS Phase-4-owned control rails (DD-4 — never select a flag /
    //    work / merge out-rail the swap-route emitter owns and leaves allocated;
    //    its reversal-or-leak is Phase 4's, not the data-uncompute driver's).
    SmallVector<CallInst *, 8> Terminals;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        auto *H = dyn_cast<CallInst>(&I);
        if (!H || !taint.Tainted.count(H) || !isDataProducer(H))
          continue;
        if (taint.ControlOwnedRails.count(H))
          continue;  // DD-4: Phase-4 owns this rail
        if (taint.OutputRails.count(H))
          continue;  // 7.6: kept I/O output rail — never a data terminal
                     // (PRD-7.6 §2.5). Defensive: a tape-write out_handle is not
                     // a data producer, so it never reaches here, but the
                     // explicit image is load-bearing, like ControlOwnedRails.
        if (taint.GraveyardRails.count(H))
          continue;  // 7.2 Inc 3: a parked abort/exit graveyard rail (or the
                     // abort flag) — kept frozen + entangled, NEVER reversed or
                     // freed (Rule 6, plan §2-A). The cswap-into-graveyard already
                     // makes `isTerminalHandle` false, but the explicit image is
                     // load-bearing — the SAME discipline as OutputRails above.
        if (!isTerminalHandle(H, taint))
          continue;  // collapse the reassignment DAG to its terminals (§2.1)
        Terminals.push_back(H);
      }
    if (Terminals.empty())
      continue;

    DominatorTree DT(F);
    PostDominatorTree PDT(F);

    // 2. Classify each terminal (FreePoint owns measure/escape/loud diagnostics):
    //    measure / escape (`ret` / `main` / `cq_invert_*`) skip with no emit; a
    //    post-measure gate / unrecognized user / backedge live range is diagnosed
    //    LOUDLY inside `computeFreePoint`. Only `Insert` terminals reach reversal;
    //    collect their last-use anchors for the single insertion point.
    SmallVector<Value *, 8> InsertTerms;
    SmallVector<Instruction *, 8> InsertAts;
    for (CallInst *Term : Terminals) {
      FreePoint FP = computeFreePoint(Term, F, PDT, taint);
      if (FP.Kind != FreePointKind::Insert)
        continue;
      InsertTerms.push_back(Term);
      InsertAts.push_back(FP.At);
    }
    if (InsertTerms.empty())
      continue;

    // 3. Recover the whole forward DAG (union over all Insert terminals — a shared
    //    fan-out prefix is recovered once).
    DataDag D = recoverDataDag(InsertTerms, taint, DT);

    // Measured intermediate → LOUD (a free of a measured register is a hidden
    // collapse, Rule 5/6). Escaped / not-closed rails are owned elsewhere (a
    // returned handle; a Phase-4 controlled-copy-entangled operand — §16.5) —
    // leave the whole DAG allocated (Rule 6/8 safe-leak; never a dirty free).
    if (D.MeasuredUpstream) {
      diagnose(D.UpstreamMeasure, kMsgLineageMeasured);
      continue;
    }
    if (D.Escaped || D.NotClosed || D.Calls.empty())
      continue;

    // Invertibility pre-scan (WI-5, PRD §2.12/§2.10): every recovered gate must
    // have an in-place adjoint (`isInverseEmittable` — the SAME predicate the
    // emitter consults). A primitive outside that surface (a permutation gate
    // Phase 5 never emits for data, a controlled callee) declines LOUDLY here —
    // BEFORE any emission — so no half-reversed chain and no dirty free of an
    // un-reversed rail are ever produced (the pre-WI-5 silent skip emitted the
    // `cqrt_free` of an un-adjointed rail = a hidden collapse, Rule 6/8). DD-1:
    // the driver owns the message.
    CallInst *Uninvertible = nullptr;
    for (CallInst *G : D.Calls)
      if (!isInverseEmittable(G)) {
        Uninvertible = G;
        break;
      }
    if (Uninvertible) {
      diagnose(Uninvertible, kMsgUninvertible);
      continue;
    }

    // §2.9 acyclic backstop: Phase 5 reverses on acyclic CFGs only. A
    // loop-carried tainted live range is loudly declined UPSTREAM (the
    // classical-mux phi guard / FreePoint's per-terminal backedge guard, both
    // before this point), but defense-in-depth: a single adjoint cannot undo a
    // gate that ran once per iteration, so if ANY recovered gate sits inside a
    // natural loop, leave the DAG allocated rather than reverse it once (a safe
    // leak, never a miscompile). No positive acyclic shape trips this.
    LoopInfo LI(DT);
    bool InLoop = false;
    for (CallInst *G : D.Calls)
      if (LI.getLoopFor(G->getParent())) {
        InLoop = true;
        break;
      }
    if (InLoop)
      continue;

    // 4. Single insertion point: the common post-dominator of all anchors, after
    //    the latest. A non-reconverging multi-terminal shape has no common
    //    post-dominator — left allocated (a safe leak), never miscompiled.
    Instruction *At = dagInsertPoint(InsertAts, PDT);
    if (!At)
      continue;

    // Every gate must DOMINATE `At` — its operands are then in scope, and
    // (acyclic + dominating) it ran exactly once on every reaching path. A gate
    // that does NOT dominate `At` ran on only some exclusive paths (mutating
    // gates split across the arms of a classical branch — the reverted-543bd85
    // divergent-arm shape); one unconditional adjoint at the merge would fire on
    // paths the forward gate never took. WI-5 declines this LOUDLY rather than
    // silently leaking the register (PRD §2.4/§2.12): per-arm reverse-play is
    // Phase 4's job, and Phase 5 defers to it.
    CallInst *NonDominating = nullptr;
    for (CallInst *G : D.Calls)
      if (!DT.dominates(G, At)) {
        NonDominating = G;
        break;
      }
    if (NonDominating) {
      diagnose(NonDominating, kMsgDivergentArm);
      continue;
    }

    // 5. Reverse the whole DAG once at `At` (every gate proven invertible and
    //    dominating — `emitDagReversal`'s per-gate adjoint cannot fail).
    emitDagReversal(D, At, wd);
  }
}

}  // namespace cq
