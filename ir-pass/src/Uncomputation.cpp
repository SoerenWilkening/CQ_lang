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
  // Phase 7.5 Inc 2: a QRAM array handle (`cqrt_qram_alloc_<W>`) backing an
  // ALLOCA mutable array is an in-place-mutated register the spine reverses — a
  // DEAD scratch array (its only users are stores) is a data terminal whose
  // stores reverse in LIFO (EmitInverse `cqrt_qram_store_<W>_unc`), the array
  // handle itself left allocated (never freed; §2.9). A const-global QROM array
  // handle (Inc 1) is NOT tainted, so it never reaches terminal selection here.
  if (N.starts_with("cqrt_qram_alloc_"))
    return true;
  // Phase 7.5: a QRAM load result is a reversible data producer (copy-out) — a
  // dead loaded value is a data terminal the spine reverses via its `_unc`
  // (EmitInverse) exactly like a `cq_template_*` producer. The `_unc` twin is not
  // a forward producer.
  if (N.starts_with("cqrt_qram_load_") && !N.ends_with("_unc"))
    return true;
  return N.starts_with("cq_template_") && !N.contains("_controlled");
}

// A QRAM array handle (`cqrt_qram_alloc_<W>` result) — a CLASSICAL resource token
// the reversal NEVER frees (its stores reverse, but a `cqrt_free` on it would be a
// hidden measurement of the restored cells; §2.9, Inc 1 "array-handle-never-freed").
bool isQramArrayHandle(const Value *V) {
  const auto *CI = dyn_cast<CallInst>(V);
  if (!CI)
    return false;
  const Function *Callee = CI->getCalledFunction();
  return Callee && Callee->getName().starts_with("cqrt_qram_alloc_");
}

// `railOf` (the rail a gate creates — the value its adjoint zeroes and the driver
// then frees) lives in `ChainWalk` (Rule 14). The freeze DECISION (`DagTraversal`
// step 3b) and this emission driver must agree on which rail a gate owns, so the
// definition is shared, not duplicated per-TU — the same hoist `LiteralIntegrity`
// applied to `valueCarriesUndef` "so cone proof and guard cannot drift".

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
    // bd 261j(a) — a FROZEN rail: RECORDED into a kept carrier (an output tape)
    // AND carrying a gate that is not a basis permutation of live conditions, so
    // its forward chain does NOT return it to |0⟩ (`DagTraversal` step 3b proves
    // this). It gets NO `cqrt_free`: it is LEFT ALLOCATED, the Rule-6 fallback for
    // a rail that is not provably |0⟩. Not a decline — no diagnostic, no new
    // symbol — and PER-RAIL: every non-frozen rail in the same DAG still frees
    // (lowering_io_tape_derived_uncompute.ll is the discrimination pin).
    //
    // THE FREEZE SUPPRESSES THE FREE, NEVER THE ADJOINT — and that distinction is
    // the whole soundness argument, learned the hard way. Skipping the frozen
    // rail's `emitInverseCall` as well (the first implementation of this ruling)
    // is a SILENT MISCOMPILE, MEASURED four independent ways in the Rule-13 round:
    // a surviving non-frozen rail's `_unc` READS the frozen rail, and it needs it
    // at the value it held when the forward producer ran — not at its final
    // forward value. Those differ exactly when a skipped non-diagonal gate on the
    // frozen rail sits AFTER the reader's producer, e.g.
    //     ry(%h,0.5); %op = add(%h,2); ry(%h,0.25); tape(%op)
    // (six lines of ordinary C — a chained `cq_theta` lowers to an in-place `ry`
    // on the EXISTING handle). Dropping `ry(%h,-0.25)` leaves `add_unc(%op,%h,2)`
    // recomputing from a scrambled %h, so %op is NOT zeroed and `cqrt_free(%op)`
    // becomes a hidden measurement — curing one Rule-6 violation by introducing
    // another, on a rail that was previously freed SOUNDLY. Same mechanism reached
    // the QRAM surface through `cqrt_qram_load_unc`'s idx slot.
    //
    // Emitting every adjoint keeps the gate stream BYTE-IDENTICAL to the
    // pre-261j stream, so no ordering, dominance or use-after-free hazard can be
    // introduced at all: the change is purely the removal of some `cqrt_free`s.
    // Applying an adjoint to a rail we then leak is harmless — every adjoint is
    // unitary, and `cqrt_free` is the only measurement-class op in the surface.
    // On the kept carrier it is not even observable: a local unitary on a leaked
    // rail cannot change the tape's reduced state.
    //
    // The suppression is SUBTRACTIVE and lands HERE, at the last step, rather than
    // pruning `D.Calls` in recovery: the invertibility pre-scan, the InLoop
    // backstop and the dominance scan above all iterate `D.Calls`, so a prune
    // would silently convert their loud declines into rc-0 accepts (risk 1/2;
    // lowering_reject_uncompute_uninvertible_taped.ll pins that it does not).
    if (Earliest.lookup(R) == G && !isQramArrayHandle(R) &&
        !D.FrozenRails.count(R)) {
      // R fully reversed → free it, UNLESS R is a QRAM array handle: that is a
      // classical resource token whose stores reverse (LIFO) but which is NEVER
      // freed — a `cqrt_free` on it would be a hidden measurement of the
      // (now-restored) classical cells (§2.9, Inc 1 "array-handle-never-freed").
      CallInst *Free = B.CreateCall(wd.freeFn(), {R});
      if (DebugLoc DL = G->getDebugLoc())
        Free->setDebugLoc(DL);
    }
  }
}

// Classify + recover + reverse ONE group of data terminals at a single insertion
// point (PRD §2.11; the body of the per-function driver, factored out so the
// regular straight-line group and each Phase-7.3 ITERATION-LOCAL loop group are
// reversed independently — a shared union insertion point across a loop boundary
// would place an in-body free at a function-scope point, the Risk-1 hazard).
//
// `IterLocal` ⇒ the group's terminals were proven by `lowerLoops` to be
// iteration-local temps of ONE recognized Case-B loop (FreePoint already lifted
// its backedge guard for them, returning an IN-BODY insertion point). The §2.9
// acyclic InLoop backstop is then lifted — BUT only after re-confirming every
// recovered gate sits in an `IterationLocalBlocks` block (defense-in-depth: a DAG
// that escaped the loop is leaked, never reversed once over a K-times rail). For
// the regular group (`IterLocal=false`) the backstop stands exactly as before —
// a loop-resident gate leaves the whole DAG allocated (a safe leak).
void reverseTerminalGroup(Function &F, ArrayRef<CallInst *> Terminals,
                          TaintSet &taint, WidthDispatch &wd, DominatorTree &DT,
                          PostDominatorTree &PDT, LoopInfo &LI, bool IterLocal) {
  if (Terminals.empty())
    return;

  // 2. Classify each terminal (FreePoint owns measure/escape/loud diagnostics).
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
    return;

  // 3. Recover the whole forward DAG (union over all Insert terminals).
  DataDag D = recoverDataDag(InsertTerms, taint, DT);
  if (D.MeasuredUpstream) {
    diagnose(D.UpstreamMeasure, kMsgLineageMeasured);
    return;
  }
  if (D.Escaped || D.NotClosed || D.Calls.empty())
    return;

  // Invertibility pre-scan (WI-5, PRD §2.12/§2.10).
  CallInst *Uninvertible = nullptr;
  for (CallInst *G : D.Calls)
    if (!isInverseEmittable(G)) {
      Uninvertible = G;
      break;
    }
  if (Uninvertible) {
    diagnose(Uninvertible, kMsgUninvertible);
    return;
  }

  // §2.9 acyclic backstop. A loop-carried tainted live range is loudly declined
  // UPSTREAM; defense-in-depth here: a single adjoint cannot undo a gate that ran
  // once per iteration, so if ANY recovered gate sits inside a natural loop,
  // leave the DAG allocated (a safe leak) — UNLESS this is an affirmatively-
  // recognized Phase-7.3 ITERATION-LOCAL group, whose gates all sit in
  // `IterationLocalBlocks` and whose recovery point is IN-BODY (once per
  // iteration). The explicit re-confirmation that every gate is in an
  // iteration-local block is the Rule-13 backstop (a DAG that walked outside the
  // loop is leaked, never reversed).
  bool InLoop = false;
  for (CallInst *G : D.Calls)
    if (LI.getLoopFor(G->getParent())) {
      InLoop = true;
      break;
    }
  if (InLoop) {
    if (!IterLocal)
      return;  // safe leak (acyclic backstop stands)
    for (CallInst *G : D.Calls)
      if (!taint.IterationLocalBlocks.count(G->getParent()))
        return;  // a gate escaped the loop body — leak, never reverse once.
  }

  // 4. Single insertion point (in-body for an iteration-local group — FreePoint
  //    returned the per-iteration anchor; for the regular group, the function
  //    post-dominator).
  Instruction *At = dagInsertPoint(InsertAts, PDT);
  if (!At)
    return;

  // Every gate must DOMINATE `At` (acyclic + dominating ⇒ ran exactly once on
  // every reaching path). For an iteration-local group this holds WITHIN the
  // iteration (no value crosses the backedge by construction of L4b); a gate that
  // does not dominate the in-body `At` (a split across a classical in-body
  // diamond) declines LOUDLY rather than reverse a partial chain.
  CallInst *NonDominating = nullptr;
  for (CallInst *G : D.Calls)
    if (!DT.dominates(G, At)) {
      NonDominating = G;
      break;
    }
  if (NonDominating) {
    diagnose(NonDominating, kMsgDivergentArm);
    return;
  }

  // 5. Reverse the whole DAG once at `At`.
  emitDagReversal(D, At, wd);
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
    LoopInfo LI(DT);

    // Partition the terminals into the REGULAR straight-line group and one group
    // per recognized Phase-7.3 ITERATION-LOCAL loop (a terminal whose def block
    // ∈ `IterationLocalBlocks`). The groups are reversed at INDEPENDENT insertion
    // points: a regular straight-line terminal at the function post-dominator, an
    // iteration-local temp IN-BODY (once per iteration). A single union point
    // across that boundary would place an in-body free at a function-scope point
    // (the Risk-1 hazard). Loops are kept in first-seen (BB) order for
    // FileCheck-stable emission.
    SmallVector<CallInst *, 8> Regular;
    SmallVector<Loop *, 4> IterLoops;
    DenseMap<Loop *, SmallVector<CallInst *, 4>> IterByLoop;
    for (CallInst *Term : Terminals) {
      Loop *L = LI.getLoopFor(Term->getParent());
      if (L && !taint.IterationLocalBlocks.empty() &&
          taint.IterationLocalBlocks.count(Term->getParent())) {
        if (!IterByLoop.count(L))
          IterLoops.push_back(L);
        IterByLoop[L].push_back(Term);
      } else {
        Regular.push_back(Term);
      }
    }

    reverseTerminalGroup(F, Regular, taint, wd, DT, PDT, LI, /*IterLocal=*/false);
    for (Loop *L : IterLoops)
      reverseTerminalGroup(F, IterByLoop[L], taint, wd, DT, PDT, LI,
                           /*IterLocal=*/true);
  }
}

}  // namespace cq
