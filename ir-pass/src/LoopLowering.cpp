// LoopLowering.cpp — Phase 7.3 bounded-loop recognition + lowering (epic 799w).
// See LoopPlan.h for the contract and the ordering constraints.
//
// Increment 1 (799w.1) — Case A "in-place persistent accumulator". A
// classically-bounded loop whose every tainted value is a persistent rail
// threaded through a loop-carried header phi, mutated only by IN-PLACE gates
// (`cq_phi`=Rz / chained `cq_theta`=Ry on a tainted operand), lowers ROLLED IN
// PLACE: the loop CFG is preserved and the rail phi(s) — the loop-carried header
// phi AND the zero-trip/exit merge phi the `-O1` guard emits — collapse to the
// single persistent rail, so the body lowers to `cqrt_rz(%h, angle_i)` over a
// loop-invariant handle. The trace is byte-identical to the manually-unrolled
// form. No in-body free, no uncompute (the rail is measured/escaped after L).
//
// Also: the Q1 (quantum/measurement-bounded exit) and X1 (cross-iteration dirty
// rail) LOUD declines. Every other off-pattern loop is LEFT for its existing
// owner (`ControlDetect`/`RegionTreeDetect` for tainted control in the body,
// `kMsgQramLoop` for tainted-index memory, `declineClassicalMuxes`/`FreePoint`
// for an unrecognized live range) — `lowerLoops` claims a loop ONLY when it can
// PROVE the §2.2 sound-rolled invariant (Prime Directive: over-declining /
// not-claiming is safe).

#include "LoopPlan.h"

#include "TaintPropagation.h"
#include "ControlPlan.h"  // diagnoseUnderControl (Q1 reuses the control dialect)
#include "WidthDispatch.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

using namespace llvm;

namespace cq {

namespace {

// The exact diagnostic string the cross-iteration-dirty-rail decline owns
// (PRD-7.3 §2.7). The negative fixture mirrors it CHARACTER-FOR-CHARACTER
// (Rule 12): lowering_reject_loop_cross_iter.ll → kMsgCrossIter. The
// quantum-bounded-loop (Q1) decline reuses the control dialect via
// `diagnoseUnderControl(_, "loop")` → "cq controlled lowering: loop under
// quantum control" (lowering_reject_loop_quantum_bound.ll).
constexpr char kMsgCrossIter[] =
    "cq loop lowering: loop-carried tainted value crosses iterations";

void diagnose(Instruction *Where, StringRef Msg) {
  Where->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *Where->getFunction(), Msg, Where->getDebugLoc()));
}

// Peel in-place rotation gates (`cq_theta`/`cq_phi` whose arg-0 handle is
// tainted ⇒ an in-place mutation, its result RAUWs to the operand at lowering)
// off the front of a value's wire, returning the underlying base. Parallels
// `TaintPropagation::resolveWireBase` (the one-register-mux lift) but returns
// only the base — 7.3 keeps the gate list implicit. Stops at a classical-operand
// `cq_theta` (the rail MINT), at any non-gate value (a phi / template producer /
// argument), and never steps through another value op.
Value *peelInPlaceBase(Value *V, const SmallPtrSetImpl<CallInst *> &GateCalls,
                       const TaintSet &taint) {
  while (auto *CI = dyn_cast<CallInst>(V)) {
    if (!GateCalls.count(CI))
      break;  // not a collected rotation call — V is the base.
    Value *Handle = CI->getArgOperand(0);
    if (!taint.Tainted.count(Handle))
      break;  // classical-operand theta: the mint point IS the base.
    V = Handle;
  }
  return V;
}

// Is `CI` an IN-PLACE rotation gate on its arg-0 handle `H` (a collected
// `cq_theta`/`cq_phi` whose arg-0 is `H` and tainted)? Such a gate mints no new
// rail; its result RAUWs to `H` at rotation lowering — so its result belongs to
// `H`'s persistent rail.
bool isInPlaceGateOnArg0(const CallInst *CI, const Value *H,
                         const SmallPtrSetImpl<CallInst *> &GateCalls,
                         const TaintSet &taint) {
  if (!GateCalls.count(const_cast<CallInst *>(CI)))
    return false;
  return CI->arg_size() >= 1 && CI->getArgOperand(0) == H &&
         taint.Tainted.count(const_cast<Value *>(H));
}

bool isMeasureCall(const Instruction *I) {
  const auto *CI = dyn_cast<CallInst>(I);
  if (!CI)
    return false;
  const Function *Callee = CI->getCalledFunction();
  // Pre-lowering the front-end form is `@cq_measure_<sfx>`; the `cqrt_measure_`
  // prefix is accepted defensively (mirrors `isMeasureSink`) though `lowerLoops`
  // always runs before measure lowering.
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  return N.starts_with("cq_measure_") || N.starts_with("cqrt_measure_");
}

// The loop's exiting condition is a live tainted value (`while(q<k)`,
// amplitude-/measurement-derived bound) ⇒ a runtime branch on a qubit — the
// genuinely quantum-controlled loop, a permanent decline (PRD §2.6, L1). Returns
// the offending terminator (for the diagnostic) or null.
Instruction *taintedExit(Loop *L, const TaintSet &taint) {
  SmallVector<BasicBlock *, 4> Exiting;
  L->getExitingBlocks(Exiting);
  for (BasicBlock *EB : Exiting) {
    Instruction *T = EB->getTerminator();
    if (auto *BI = dyn_cast<BranchInst>(T)) {
      if (BI->isConditional() && taint.Tainted.count(BI->getCondition()))
        return T;
    } else if (auto *SI = dyn_cast<SwitchInst>(T)) {
      if (taint.Tainted.count(SI->getCondition()))
        return T;
    }
  }
  return nullptr;
}

// Try to recognize + collapse one natural loop `L` as Case A (in-place
// persistent accumulator). Returns true iff a Case-A collapse (or a LOUD
// X1/Q1 decline) was performed; false ⇒ `L` is left untouched for its existing
// owner (Prime Directive — claim only what is proven).
bool tryCaseA(Loop *L, Function &F, TaintSet &taint,
              const SmallPtrSetImpl<CallInst *> &GateCalls, DominatorTree &DT,
              LoopInfo &LI) {
  // (L1) Quantum/measurement-bounded exit ⇒ permanent decline (§2.6). Checked
  //      FIRST and BEFORE `detectControlRegions`, so Q1 gets the dedicated
  //      `loop under quantum control` message rather than the generic
  //      `nested control flow…` ControlDetect would otherwise emit.
  if (Instruction *TE = taintedExit(L, taint)) {
    diagnoseUnderControl(TE, "loop");
    return true;
  }

  // (L2) Tainted control INSIDE the body (a non-exiting tainted `br`/`switch` —
  // a loop-resident diamond/if-else/switch). 7.3 does NOT lower control-in-loop
  // (§2.8): leave the loop unclaimed so the existing `ControlDetect` /
  // `RegionTreeDetect` owner declines it (`nested control flow under quantum
  // control`, the backedge guard `RegionTreeDetect.cpp`). Crucially this runs
  // BEFORE the X1 header-phi analysis below, so a control-merge latch phi (a
  // tainted nested-diamond merge feeding the backedge) is left for that owner
  // rather than mis-declined as a cross-iteration dirty value rail.
  for (BasicBlock *BB : L->blocks()) {
    Instruction *T = BB->getTerminator();
    if (auto *BI = dyn_cast<BranchInst>(T)) {
      if (BI->isConditional() && taint.Tainted.count(BI->getCondition()))
        return false;
    } else if (auto *SI = dyn_cast<SwitchInst>(T)) {
      if (taint.Tainted.count(SI->getCondition()))
        return false;
    }
  }

  BasicBlock *Header = L->getHeader();
  BasicBlock *Latch = L->getLoopLatch();
  // Require a single latch — the `-O1` shape (verified). NOTE: a rotated `-O1`
  // loop has a GUARD branch (`if (n>0) goto loop`) as its entry predecessor,
  // which is NOT a dedicated preheader (it has two successors), so
  // `getLoopPreheader()` returns null here — the header phi's external
  // (non-latch) incoming is identified directly from its incoming blocks below.
  // A multi-latch loop is an unproven shape; leave it (conservative).
  if (!Latch)
    return false;

  // railRoot maps every value on a recognized persistent rail to its single
  // root mint (a classical-operand `cq_theta`). Seeded from the clean
  // self-cycle header phis; expanded to a fixpoint over in-place gates and
  // single-root phis below.
  DenseMap<Value *, Value *> railRoot;
  for (PHINode &P : Header->phis()) {
    if (!taint.Tainted.count(&P))
      continue;  // classical induction phi — not a rail.
    // The header phi must have exactly two incomings: one from the latch (the
    // back edge) and one EXTERNAL (the entry/guard edge from outside L). A phi
    // with extra edges (an irreducible / multi-entry shape) is unproven.
    if (P.getNumIncomingValues() != 2)
      return false;  // unproven multi-edge header phi — leave it.
    Value *LatV = nullptr;
    Value *PreV = nullptr;
    for (unsigned i = 0; i < 2; ++i) {
      BasicBlock *IB = P.getIncomingBlock(i);
      if (IB == Latch)
        LatV = P.getIncomingValue(i);
      else if (!L->contains(IB))
        PreV = P.getIncomingValue(i);  // the external (entry) edge.
    }
    if (!PreV || !LatV)
      return false;  // not the clean latch + external-entry pair.
    // (Risk 2) The latch incoming must peel — through IN-PLACE gates ONLY —
    // back to the header phi itself (a closed self-cycle ⇒ a single persistent
    // rail). A latch that peels to a fresh value-op rail (a `cq_template_*`
    // accumulator, X1) is a cross-iteration dirty rail: LOUD decline, never a
    // silent collapse of a loop-variant handle.
    if (peelInPlaceBase(LatV, GateCalls, taint) != &P) {
      // X1 only when the latch carries a genuine tainted dirty rail across the
      // backedge (an `acc=acc+q` fresh-rail accumulator). A header phi we cannot
      // classify either way is left for downstream (conservative).
      Value *LatBase = peelInPlaceBase(LatV, GateCalls, taint);
      if (taint.Tainted.count(LatBase)) {
        diagnose(&P, kMsgCrossIter);
        return true;
      }
      return false;
    }
    // The preheader incoming must peel to a classical-operand `cq_theta` MINT
    // that dominates the loop (the rail origin).
    Value *Root = peelInPlaceBase(PreV, GateCalls, taint);
    auto *Mint = dyn_cast<CallInst>(Root);
    if (!Mint || !GateCalls.count(Mint) ||
        taint.Tainted.count(Mint->getArgOperand(0)))
      return false;  // preheader incoming is not a clean rail mint.
    if (!DT.dominates(Mint, Header))
      return false;
    railRoot[Root] = Root;
    railRoot[&P] = Root;
  }
  if (railRoot.empty())
    return false;  // no persistent rail — Case B / other, not Inc 1.

  // Fixpoint expansion: an in-place gate on a rail value joins the SAME rail; a
  // tainted phi ALL of whose incomings peel to one common root joins that root
  // (the zero-trip/exit merge phi and any inner renaming). A phi whose incomings
  // peel to TWO distinct roots is a cross-rail merge — not clean; bail.
  SmallVector<Value *, 16> Work;
  for (auto &KV : railRoot)
    Work.push_back(KV.first);
  bool PhiAdded = true;
  while (PhiAdded) {
    // (a) drain the in-place-gate worklist.
    while (!Work.empty()) {
      Value *V = Work.pop_back_val();
      Value *R = railRoot[V];
      for (User *U : V->users())
        if (auto *CI = dyn_cast<CallInst>(U))
          if (isInPlaceGateOnArg0(CI, V, GateCalls, taint)) {
            auto It = railRoot.find(CI);
            if (It == railRoot.end()) {
              railRoot[CI] = R;
              Work.push_back(CI);
            } else if (It->second != R) {
              return false;  // a gate result claimed by two rails — not clean.
            }
          }
    }
    // (b) one phi-scan pass: add any tainted phi now fully resolved to one root.
    PhiAdded = false;
    for (BasicBlock &BB : F)
      for (PHINode &P : BB.phis()) {
        if (railRoot.count(&P) || !taint.Tainted.count(&P))
          continue;
        Value *Common = nullptr;
        bool Ok = true, Touches = false;
        for (Value *V : P.incoming_values()) {
          Value *Base = peelInPlaceBase(V, GateCalls, taint);
          auto It = railRoot.find(Base);
          if (It == railRoot.end()) {
            Ok = false;
            break;
          }
          Touches = true;
          if (!Common)
            Common = It->second;
          else if (Common != It->second) {
            Ok = false;  // merges two distinct rails — not a clean renaming.
            break;
          }
        }
        if (Ok && Touches && Common) {
          railRoot[&P] = Common;
          Work.push_back(&P);
          PhiAdded = true;
        }
      }
  }

  // COVERAGE: every tainted value whose innermost loop is exactly `L` must be on
  // a rail (else there is a value op / control / memory in the body — not pure
  // Case A; leave it for Inc 2 / the existing owners). A tainted instruction in
  // a strictly-deeper subloop is NOT this loop's to classify.
  for (BasicBlock *BB : L->blocks()) {
    if (LI.getLoopFor(BB) != L)
      continue;  // a subloop block — owned by the inner loop's pass.
    for (Instruction &I : *BB) {
      if (!taint.Tainted.count(&I))
        continue;
      if (isMeasureCall(&I))
        continue;  // a sink reading the rail — fine.
      if (!railRoot.count(&I))
        return false;  // an uncovered tainted body value — not pure Case A.
    }
  }

  // CLOSURE: every user of a rail value is an in-place gate / phi on the rail, a
  // measure sink, or an escape (`ret`). ANY other consumer — a value-op
  // template producer, a tainted control compare, a store, an unknown call, or
  // the rail used as a classical ANGLE (arg-1) — means the rail is not isolated;
  // leave it (the consumer's own guard declines loudly downstream).
  for (auto &KV : railRoot) {
    Value *V = KV.first;
    for (User *U : V->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I)
        continue;
      if (railRoot.count(I) || isMeasureCall(I) || isa<ReturnInst>(I))
        continue;
      // An in-place gate on the rail whose result is itself a rail is in
      // railRoot (handled above). Anything else is an out-of-rail consumer.
      return false;
    }
  }

  // ACCEPT — collapse every rail PHINode to its root. RAUW to the root mint (the
  // still-pre-lowering `cq_theta` SSA value, SAME type as the phi — no ill-typed
  // `phi double` survives, Risk 5; rotation lowering later maps root→%h). Scrub
  // each erased phi from `Tainted` (the `scrubTaint` precedent) and erase after
  // ALL RAUWs so inter-phi references resolve cleanly.
  SmallVector<PHINode *, 4> Collapse;
  for (auto &KV : railRoot)
    if (auto *P = dyn_cast<PHINode>(KV.first))
      Collapse.push_back(P);
  for (PHINode *P : Collapse)
    P->replaceAllUsesWith(railRoot[P]);
  for (PHINode *P : Collapse) {
    taint.Tainted.erase(P);
    P->eraseFromParent();
  }
  return true;
}

// Increment 2 (799w.2) — Case B: mark a loop whose every tainted value is an
// ITERATION-LOCAL born-and-dies temporary, so the Phase-5 uncompute spine
// recovers each temp's DAG IN-BODY (once per iteration) instead of declining
// (FreePoint kMsgLoopBackedge) or leaking. Pure analysis; the ONLY effect is
// inserting `L`'s blocks into `taint.IterationLocalBlocks` (no mutation). Called
// only when `tryCaseA` left the loop unclaimed.
//
// A loop qualifies iff: classical exit (L1 — a tainted exit was already declined
// Q1 by `tryCaseA`); no tainted control (L2) / tainted-index memory (L3) in the
// body; and every tainted value is iteration-local — NO tainted header phi (no
// loop-carried persistent rail; that is Case A or X1), every tainted value
// DEFINED in L is USED only in L (nothing escapes the loop), and every tainted
// OPERAND of an in-L instruction is DEFINED in L (no loop-invariant tainted input
// minted outside, whose register would accumulate across iterations — the
// `lowering_uncompute_loop_backedge` residual). The spine then PROVES per-DAG
// closure/measure/escape; this predicate only certifies the loop is a sound place
// to lift the backedge guard (Prime Directive: not-marking is always safe).
void markIfIterationLocal(Loop *L, TaintSet &taint, LoopInfo &LI) {
  if (taintedExit(L, taint))
    return;  // Q1 quantum-bounded — never Case B.
  BasicBlock *Header = L->getHeader();
  bool AnyTainted = false;
  for (BasicBlock *BB : L->blocks()) {
    // (L2) tainted control in the body ⇒ the existing ControlDetect owner's.
    Instruction *T = BB->getTerminator();
    if (auto *BI = dyn_cast<BranchInst>(T)) {
      if (BI->isConditional() && taint.Tainted.count(BI->getCondition()))
        return;
    } else if (auto *SI = dyn_cast<SwitchInst>(T)) {
      if (taint.Tainted.count(SI->getCondition()))
        return;
    }
    if (LI.getLoopFor(BB) != L) {
      // A strictly-deeper SUBLOOP with quantum content is a NESTED quantum loop,
      // not a single-level iteration-local loop: a value rotated by the subloop
      // runs the subloop-trip-count times PER outer iteration, but the spine
      // would reverse it ONCE (a dirty free of an under-reversed rail — a SILENT
      // miscompile, confirmed on a do-while inner loop whose body dominates the
      // outer recovery point, so the divergent-arm backstop does not catch it).
      // Decline to mark (Prime Directive: over-declining is safe — the value's
      // terminal then keeps FreePoint's `kMsgLoopBackedge` reject). 7.3 does not
      // lower nested quantum loops; the subloop is handled (or declined) on its
      // own, never folded into the outer iteration-local set.
      for (Instruction &I : *BB)
        if (taint.Tainted.count(&I))
          return;
      continue;
    }
    for (Instruction &I : *BB) {
      // (L3) tainted-index memory in the body ⇒ the existing kMsgQramLoop owner's.
      if (isa<GetElementPtrInst>(I) || isa<LoadInst>(I) || isa<StoreInst>(I))
        for (Value *Op : I.operands())
          if (taint.Tainted.count(Op))
            return;
      const bool TI = taint.Tainted.count(&I);
      // A tainted HEADER phi is a loop-carried persistent rail (Case A / X1),
      // not an iteration-local temp.
      if (TI && isa<PHINode>(I) && BB == Header)
        return;
      if (TI) {
        AnyTainted = true;
        // Every tainted value defined in L must be used ONLY in L (nothing
        // escapes the loop — the last iteration's value never reads downstream).
        for (User *U : I.users())
          if (auto *UI = dyn_cast<Instruction>(U))
            if (!L->contains(UI->getParent()))
              return;
      }
      // Every tainted OPERAND must be defined in L — a tainted value minted
      // OUTSIDE L and read inside (loop-invariant) is a persistent register that
      // accumulates across iterations, NOT iteration-local.
      for (Value *Op : I.operands())
        if (taint.Tainted.count(Op)) {
          auto *OpI = dyn_cast<Instruction>(Op);
          if (!OpI || !L->contains(OpI->getParent()))
            return;
        }
    }
  }
  if (!AnyTainted)
    return;  // a purely-classical loop — leave it byte-identical.
  for (BasicBlock *BB : L->blocks())
    taint.IterationLocalBlocks.insert(BB);
}

}  // namespace

void lowerLoops(Module &M, WidthDispatch &wd, TaintSet &taint) {
  (void)wd;
  // The collected rotation call sites — the in-place-gate wire vocabulary the
  // peel + closure consult (same seed as `declineClassicalMuxes`).
  SmallPtrSet<CallInst *, 32> GateCalls;
  GateCalls.insert(taint.ThetaCalls.begin(), taint.ThetaCalls.end());
  GateCalls.insert(taint.PhiCalls.begin(), taint.PhiCalls.end());

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Cheap skip: a function with no tainted value has no quantum loop.
    bool AnyTainted = false;
    for (Value *V : taint.Tainted)
      if (auto *I = dyn_cast<Instruction>(V))
        if (I->getFunction() == &F) {
          AnyTainted = true;
          break;
        }
    if (!AnyTainted)
      continue;

    DominatorTree DT(F);
    LoopInfo LI(DT);
    if (LI.empty())
      continue;
    // Recognition is pure analysis on the still-unmutated IR; the only mutation
    // is the Case-A phi collapse inside `tryCaseA`, which erases phis (the CFG —
    // blocks + edges — is untouched, so `LI`/`DT` stay valid across loops). A
    // loop `tryCaseA` does not claim (Case A collapse / Q1 / X1) is offered to
    // the Case-B iteration-local recognizer (Increment 2), which only marks
    // blocks for the spine — never mutates.
    for (Loop *L : LI.getLoopsInPreorder())
      if (!tryCaseA(L, F, taint, GateCalls, DT, LI))
        markIfIterationLocal(L, taint, LI);
  }
}

}  // namespace cq
