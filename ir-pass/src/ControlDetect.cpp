// ControlDetect.cpp — Pure-analysis detection of tainted control regions.
//
// Replaces the transitional ControlStub.cpp (loud-decline-only). Owns the
// shared `diagnoseUnderControl` primitive, the `detectControlRegions`
// dispatcher, and the `recoverRegion` shape recovery (de-anonymized into
// `ControlShape.h` for the 4.3 RegionTreeDetect TU — WI-0/MD1). All recognition
// is by SSA-value identity BEFORE any IR mutation (Rule 9) — it survives the
// later rotation-lowering RAUW-to-handle because no block pointers are cached
// across erasures (none happen here).
//
// Disposition (swap-route 4.1):
//   * accepted PHASE-arm DIAMOND (one content arm, WI-2) or IF/ELSE (two arms,
//     WI-3) → pushed onto `plan.Regions` for the `SwapRouteEmit` emitter;
//   * §3c clobber → permanent reject; value-arm / nested / select / switch /
//     off-pattern → declined with a precise per-shape string.
// Every decline is a loud `DiagnosticInfoUnsupported` (opt exits non-zero).
//
// See swap-route 4.1 IMPLEMENTATION §0/§2/§3.

#include "ControlPlan.h"

#include "AbortParkEmit.h"
#include "ArmClassify.h"
#include "ControlShape.h"
#include "GuardedStoreArmEmit.h"  // classifyGuardedStoreArm (iw81.7)
#include "RegionTreeDetect.h"
#include "SelectClassify.h"
#include "SwitchClassify.h"
#include "TaintPropagation.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include <string>

using namespace llvm;

namespace cq {

// Promoted from ControlStub.cpp:43-48 (now shared via ControlPlan.h). Same
// `DiagnosticInfoUnsupported(DS_Error)` surface + message form, so the "… under
// quantum control" FileCheck idiom still holds and `opt` exits non-zero. The
// offending instruction's `!dbg` is attached so the rejection is source-located.
void diagnoseUnderControl(Instruction *Where, StringRef What) {
  std::string Msg =
      ("cq controlled lowering: " + What + " under quantum control").str();
  Where->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *Where->getFunction(), Msg, Where->getDebugLoc()));
}

// The shape recognizers below are de-anonymized into the named `cq` namespace
// (declared in ControlShape.h, WI-0/MD1) so the 4.3 RegionTreeDetect TU can reuse
// them; `RegionShape` now lives in that header. PURE REFACTOR — definitions and
// behavior unchanged.

// `BB`'s unique successor iff it ends in an UNCONDITIONAL branch; else null.
BasicBlock *uncondSucc(BasicBlock *BB) {
  auto *BI = dyn_cast<BranchInst>(BB->getTerminator());
  return (BI && BI->isUnconditional()) ? BI->getSuccessor(0) : nullptr;
}

// Does `BB` end in a tainted-condition conditional branch? (the nested-control
// signal — an arm that is itself a quantum-controlled region, deferred to 4.3).
bool hasTaintedCondBranch(BasicBlock *BB, TaintSet &Taint) {
  auto *BI = dyn_cast<BranchInst>(BB->getTerminator());
  return BI && BI->isConditional() && Taint.Tainted.count(BI->getCondition());
}

// d8jl — is `Term`'s block on a CFG CYCLE (i.e., the tainted-control region it
// opens — a flat `br` diamond/if-else or a `switch` — sits inside a loop body)?
// A COMPLETE forward reachability walk from the block's successors back to the
// block itself.
//
// Why not `LoopInfo`: it recognizes only NATURAL/reducible loops, so an
// IRREDUCIBLE cycle (a `goto` into a loop body / Duff's device — reachable from
// real clang -O1) has `getLoopFor == null` and would slip through. Why not
// `llvm::isPotentiallyReachable`: it bails `true` once its 32-block scan limit
// is hit, which would over-DECLINE a legitimate NON-loop diamond buried in a
// large function. This walk is reducibility-independent AND unbounded-but-finite
// (each block visited once), so it is exact for our purpose.
//
// A flat tainted-control region on a cycle has NO sound swap-route lowering: the
// merge feeds the backedge / the routed base is a loop-carried phi, so
// `RegionFlatten` would erase the merge — the loop latch / backedge source —
// leaving the loop's header phi dangling (a BROKEN MODULE, verified on the
// clang-O1 iteration-local `for(){ q=cq_theta; if(q>5) q=cq_phi(q);
// acc+=cq_measure(q); }` shape) OR, when a loop-carried header phi survives,
// deferring to `declineClassicalMuxes` whose `classical-condition phi` string
// MISLABELS the QUANTUM condition. We decline HERE, before any mutation
// (Rule 9), with an accurate source-located message. A region whose entry is NOT
// on a cycle (a non-loop diamond, or a loop-EXIT diamond whose successors all
// leave the loop) returns false and keeps its current disposition. Pure
// analysis. Wired into THREE dispatch arms, each at the point where the relevant
// CFG-flattening emitter would otherwise run: the flat `br` Diamond/IfElse arm
// and the `switch` dispatch (message `control flow inside a loop body`), and the
// depth-2 `RegionShape::Nested` arm BEFORE `recoverRegionTree` (message
// `nested control flow`, matching that path's own backedge-guard string — no
// fixture churn).
bool regionEntryInLoop(Instruction *Term) {
  BasicBlock *Entry = Term->getParent();
  SmallPtrSet<BasicBlock *, 16> Seen;
  SmallVector<BasicBlock *, 16> Work(succ_begin(Entry), succ_end(Entry));
  while (!Work.empty()) {
    BasicBlock *BB = Work.pop_back_val();
    if (BB == Entry)
      return true;  // control returns to the region entry — it is in a loop.
    if (!Seen.insert(BB).second)
      continue;
    Work.append(succ_begin(BB), succ_end(BB));
  }
  return false;
}

// The sole 2-incoming merge `φ` of block `M`. Null if `M` has not exactly one
// PHINode, or that phi is not 2-incoming (a mixed gate+angle merge, or a
// shared/nested merge with >2 predecessors → decline generic, never mis-lower).
PHINode *soleMergePhi(BasicBlock *M) {
  PHINode *Found = nullptr;
  for (PHINode &P : M->phis()) {
    if (Found)
      return nullptr;  // more than one phi → off-pattern.
    Found = &P;
  }
  if (!Found || Found->getNumIncomingValues() != 2)
    return nullptr;
  return Found;
}

// Recognize the §0 diamond / if-else shape of a tainted-condition `br` by SSA
// identity, populating `R` (Condition/Pred/Arm/ArmFalse/MergeBB/Merge and the
// Rule-9 ArmNegated polarity). Returns the shape, or OffPattern/Nested to
// decline. Never assumes successor 0 is the taken arm.
RegionShape recoverRegion(BranchInst *BI, TaintSet &Taint, ControlRegion &R) {
  BasicBlock *Pred = BI->getParent();
  BasicBlock *S0 = BI->getSuccessor(0);  // cond == true
  BasicBlock *S1 = BI->getSuccessor(1);  // cond == false
  R.Condition = BI->getCondition();
  R.Pred = Pred;
  R.Kind = ControlRegion::BranchRegion;

  // Nested control first: an immediate successor that is itself a
  // tainted-condition branch (the outer/mid arm of `if(q){if(q'){…}}`).
  if (hasTaintedCondBranch(S0, Taint) || hasTaintedCondBranch(S1, Taint))
    return RegionShape::Nested;

  // Diamond, orientation A — arm = S0 (true successor), merge = S1: the arm is
  // single-pred(Pred), single-succ(merge), and the merge is reached directly by
  // the straight-through (false) edge.
  if (uncondSucc(S0) == S1 && S0->getSinglePredecessor() == Pred) {
    if (PHINode *Phi = soleMergePhi(S1))
      if (Phi->getBasicBlockIndex(S0) >= 0 &&
          Phi->getBasicBlockIndex(Pred) >= 0) {
        R.Arm = S0;
        R.MergeBB = S1;
        R.Merge = Phi;
        R.ArmNegated = false;
        return RegionShape::Diamond;
      }
  }
  // Diamond, orientation B — arm = S1 (FALSE successor), merge = S0 (Rule 9:
  // clang -O1 swaps successors for `if(u!=k)`-style conditions). The gate arm
  // fires on ¬flag; record ArmNegated.
  if (uncondSucc(S1) == S0 && S1->getSinglePredecessor() == Pred) {
    if (PHINode *Phi = soleMergePhi(S0))
      if (Phi->getBasicBlockIndex(S1) >= 0 &&
          Phi->getBasicBlockIndex(Pred) >= 0) {
        R.Arm = S1;
        R.MergeBB = S0;
        R.Merge = Phi;
        R.ArmNegated = true;
        return RegionShape::Diamond;
      }
  }
  // If/else — both successors are single-pred(Pred), single-succ arms
  // reconverging at a common merge distinct from either arm.
  if (BasicBlock *M = uncondSucc(S0))
    if (M == uncondSucc(S1) && M != S0 && M != S1 &&
        S0->getSinglePredecessor() == Pred &&
        S1->getSinglePredecessor() == Pred) {
      // The MERGE hosting the next region's tainted branch (sequential
      // `if/else; if`) must decline HERE, while every block is still valid: an
      // accepted if/else's flattenRegion splices + ERASES its merge block,
      // which is exactly the second region's Pred — emitting both is a
      // use-after-free (SIGSEGV on valid input; §8 adversarial review
      // 2026-06-10). A DIAMOND gets this protection incidentally (its merge is
      // an immediate successor, caught by the Nested check above); the if/else
      // merge is one hop further, so check it explicitly. Same imprecise-but-
      // safe "nested" label as the sequential-diamond case (known-limits §3).
      if (hasTaintedCondBranch(M, Taint))
        return RegionShape::Nested;
      if (PHINode *Phi = soleMergePhi(M))
        if (Phi->getBasicBlockIndex(S0) >= 0 &&
            Phi->getBasicBlockIndex(S1) >= 0) {
          R.Arm = S0;       // true arm
          R.ArmFalse = S1;  // false arm (¬flag bracket at emit time)
          R.MergeBB = M;
          R.Merge = Phi;
          R.ArmNegated = false;
          return RegionShape::IfElse;
        }
    }

  return RegionShape::OffPattern;
}

namespace {

// ── 7.2 Inc 4 — OffPattern decline-diagnostic partition (PRD-7.2 §2.10/§2.11-C) ──
// Replace the single generic `control flow` at the structural OffPattern site
// with a per-disposition, source-located `What`. PURE SSA, NO mutation — keyed on
// arm-terminator KIND by value identity before any lowering (Rule 9). SCOPED to
// THIS site: `control flow` is the `What` at ~60 other decline sites, so the
// partition keys on the OffPattern PATH, never on the message string (§2-F). The
// abort park (`classifyAbortPark`, run first) and `recoverRegion`'s three accept
// shapes have already filtered out everything that parks or reconverges, so an
// OffPattern `br` is a genuinely non-reconverging tainted-condition branch.

// The value returned by `Arm`'s terminator iff it ends in a value-bearing `ret`;
// null for a `ret void` / a non-`ret` terminator (`br`/`switch`/`unreachable`).
Value *armReturnValue(BasicBlock *Arm) {
  auto *Ret = dyn_cast<ReturnInst>(Arm->getTerminator());
  return Ret ? Ret->getReturnValue() : nullptr;
}

// Is `Arm` a self-`br` infinite loop (`br label %<itself>`)? The §2.11-C-ii
// divergent-arm signature, deferred to 7.3/7.4. Pure structural — the recognized
// noreturn sinks were already parked/declined by `classifyAbortPark`, so a
// divergent arm surviving here has no recognized terminating sink.
bool isSelfLoopArm(BasicBlock *Arm) {
  auto *BI = dyn_cast<BranchInst>(Arm->getTerminator());
  return BI && BI->isUnconditional() && BI->getSuccessor(0) == Arm;
}

// Backward "does this value's lineage carry a relative phase (an Rz / `cq_phi`)?"
// walk — the §2.6/§2.11-C-iii phase fence. A per-TU mirror of AbortParkEmit's and
// SelectClassify's identical walks (the house style permits the trivial duplicate
// — keeping the partition self-contained, no cross-TU mechanism, Rule 14). A
// `cq_theta` (Ry) basis superposition has no relative phase and STOPS the walk; a
// `cq_phi` in the lineage is the phase carrier. Over-decline-safe (any phi flags
// it). The caller gates entry on `Taint.Tainted.count(Op)` so a MEASURED ret
// operand (the taint sink — phase already collapsed to a basis outcome) is never
// walked into (the `cq_measure` result is untainted).
bool retLineageCarriesPhase(Value *Op, const TaintSet &Taint) {
  SmallVector<Value *, 8> Work;
  SmallPtrSet<Value *, 16> Visited;
  Work.push_back(Op);
  Visited.insert(Op);
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (auto *CI = dyn_cast<CallInst>(V)) {
      const Function *F = CI->getCalledFunction();
      if (F && F->getName().starts_with("cq_phi_"))
        return true;  // an Rz (cq_phi) in the lineage — a relative-phase carrier.
    }
    auto *I = dyn_cast<Instruction>(V);
    if (!I)
      continue;  // an argument / constant root — basis, not a phase.
    for (Value *In : I->operands())
      if (Taint.Tainted.count(In) && Visited.insert(In).second)
        Work.push_back(In);
  }
  return false;
}

// Pick the precise PRD-7.2 §2.10 `What` for an OffPattern tainted `br`. Pure
// analysis; returns the message string only (the caller fires the one shared
// `diagnoseUnderControl`). Priority is most-specific-physics-first; each branch is
// mutually exclusive on the verified-fixture corpus (control_swap_reject_abort_
// nonnoreturn.ll + control_swap_reject_nested_switch.ll are the ONLY two fixtures
// that reach this site, and both correctly stay generic — see the per-row notes).
StringRef offPatternDisposition(BranchInst *BI, TaintSet &Taint) {
  BasicBlock *S0 = BI->getSuccessor(0), *S1 = BI->getSuccessor(1);

  // (C-iii) PHASE-CLASS value escaping — checked FIRST (the most specific hazard:
  // a phase reaching a data/exit path is the Rule-7 dephasing leak, P0 0.585→
  // 0.500). A value-`ret` arm whose returned operand is TAINTED and carries an Rz
  // (`cq_phi`) lineage. Single-arm scan — the phase may escape beside an
  // `unreachable`/exit sibling (§2.11-C-iii "incl. an abort sibling"). The TAINTED
  // gate is load-bearing: it excludes a MEASURED return (`ret %m`, `%m =
  // cq_measure …`, whose pre-measure lineage carried a phase but has collapsed) —
  // exactly control_swap_reject_nested_switch.ll's merge arm, which must stay
  // generic. A RECOGNIZED-sink abort+phase is `classifyAbortPark`'s own Declined
  // `phase-class value escaping`, never reaching here. SCOPED to the DIRECT
  // escaping `ret` operand (§2.11-C-iii's exact wording): a phase reaching the
  // exit through a longer `br`→downstream-`ret` chain is a best-effort labeling
  // gap that falls to the generic `control flow` — still a DECLINE (no miscompile,
  // no accept, Prime Directive), this partition is a source-locator over an
  // already-declining path, not an exhaustive phase detector (Rule-13 residual).
  for (BasicBlock *Arm : {S0, S1})
    if (Value *RV = armReturnValue(Arm))
      if (Taint.Tainted.count(RV) && retLineageCarriesPhase(RV, Taint))
        return "phase-class value escaping";

  // (C-ii) LOOP — a self-`br` divergent arm (no recognized noreturn sink; abort-
  // park already handled the sinks). Deferred to 7.3/7.4. Checked before the
  // value-exit row so a divergent arm beside a value-`ret` sibling reports the
  // divergence, not the sibling's exit.
  if (isSelfLoopArm(S0) || isSelfLoopArm(S1))
    return "loop";

  // (C-i) NON-RECONVERGING VALUE EXIT — the two-way value-exit mux clang did NOT
  // reconverge: BOTH arms end in a value `ret` (the two-un-merged-rets / `musttail`
  // survivors; 7.2 does NOT synthesize the merge — reopenable tooling boundary,
  // §2.10). REQUIRING BOTH arms is LOAD-BEARING for the §2.11 mutual-exclusivity:
  // an abort LOOKALIKE (an `unreachable` arm beside the ordinary uncontrolled
  // `ret` sibling — control_swap_reject_abort_nonnoreturn.ll) has ONE `unreachable`
  // arm, so it is NEVER a `non-reconverging value exit` (its `ret` sibling is the
  // normal return, not a second mux arm), and stays the generic `control flow`. A
  // RECOGNIZED abort+value is the park (handled upstream), never this row.
  if (armReturnValue(S0) && armReturnValue(S1))
    return "non-reconverging value exit";

  // Everything else (an `unreachable`/`switch`/cond-`br`-terminated arm beside a
  // non-value sibling — e.g. the nested_switch outer branch, the abort lookalike —
  // or a failed-merge-φ shape) keeps the generic catch-all (Prime Directive over-
  // decline; behavior unchanged from pre-7.2-Inc-4).
  return "control flow";
}

// Recognize and classify one tainted-condition `br`, firing the precise
// decline or PUSHING an accepted region onto `Plan` for `SwapRouteEmit`.
void handleBranchRegion(BranchInst *BI, TaintSet &Taint, ControlPlan &Plan,
                        SmallPtrSetImpl<BranchInst *> &Claimed) {
  ControlRegion R;
  // 7.2 Inc 3 — abort/exit park FIRST: a recognized noreturn-sink arm ends in
  // `unreachable`, so `recoverRegion` would label it `OffPattern` and decline
  // generically. Recognize it BEFORE that fall-through (parallel to how
  // `lowerControlledIOSinks` pre-peels the merge-φ-less void-I/O diamond). On
  // Accept push the `AbortPark` region for `emitAbortParkRegion`; on Declined it
  // already fired the precise diagnostic; NotApplicable falls through to the
  // ordinary shape recovery (`R` is untouched, so it is reused below).
  switch (classifyAbortPark(BI, Taint, R)) {
  case AbortParkDisp::Accept:
    Plan.Regions.push_back(R);
    return;
  case AbortParkDisp::Declined:
    return;
  case AbortParkDisp::NotApplicable:
    break;
  }
  // iw81.7 — guarded Shadow store arm, tried BEFORE `recoverRegion`: a
  // side-effect-only store arm (a `store`, NO merge φ) would be labelled
  // `OffPattern` and declined generically, exactly like the abort/exit sink arm.
  // On Accept push the `GuardedStoreArm` region for `emitGuardedStoreArmRegion`; on
  // Declined it already fired the precise diagnostic; NotApplicable falls through.
  switch (classifyGuardedStoreArm(BI, Taint, R)) {
  case GuardedStoreDisp::Accept:
    Plan.Regions.push_back(R);
    return;
  case GuardedStoreDisp::Declined:
    return;
  case GuardedStoreDisp::NotApplicable:
    break;
  }
  switch (recoverRegion(BI, Taint, R)) {
  case RegionShape::OffPattern:
    // 7.2 Inc 4 — partition the generic decline into a per-disposition, source-
    // located `What` (PRD-7.2 §2.10/§2.11-C). Same `diagnoseUnderControl`
    // mechanism (Rule 14), pure-SSA `offPatternDisposition` just selects a
    // precise message; non-partitioned shapes keep the generic `control flow`.
    diagnoseUnderControl(BI, offPatternDisposition(BI, Taint));
    return;
  case RegionShape::Nested:
    // d8jl (Rule-13 round 2) — a depth-2 nest whose entry is on a CFG cycle
    // (inside a loop body) has no sound NestedRouteEmit lowering: its
    // `flattenRegionTree` erases the shared merge — a backedge source — dangling
    // the loop's re-entry phi (a BROKEN MODULE on the IRREDUCIBLE iteration-local
    // nest, reachable from a clang-O1 `goto`-into-loop). `recoverRegionTree`'s
    // own `DominatorTree` backedge guard MISSES that case — in an irreducible
    // loop neither cycle-entry block dominates the other, so no edge tests as a
    // backedge (the same reason `LoopInfo` reports no loop). Decline HERE, before
    // `recoverRegionTree`, with the reducibility-independent `regionEntryInLoop`
    // walk, firing the SAME `nested control flow` message that guard already uses
    // for the reducible in-loop nest (no nested-fixture churn). The internal DT
    // guard stays as an acyclic-only defense-in-depth backstop.
    if (regionEntryInLoop(BI)) {
      diagnoseUnderControl(BI, "nested control flow");
      return;
    }
    // 4.3 — prove-or-decline the depth-2 nest instead of the blanket decline. On
    // ACCEPT, `recoverRegionTree` has pushed the Outer (Depth 0) + Inner (Depth 1)
    // regions onto `Plan` and recorded the inner `br` in `Claimed`;
    // `lowerControlRegions` dispatches `NestedRouteEmit` for them. On decline it
    // has already fired the precise §5h string. Either way nothing more to do here
    // (WI-3 drops the WI-1 transitional `nested control flow` decline — the proven
    // nest now LOWERS).
    recoverRegionTree(BI, Taint, Plan, Claimed);
    return;
  case RegionShape::Diamond:
  case RegionShape::IfElse:
    // d8jl — a FLAT tainted-condition control region whose entry is on a CFG
    // cycle (inside a loop body) has no sound swap-route lowering (see
    // `regionEntryInLoop`). Decline HERE, before `classifyArms` accepts and
    // `lowerControlRegions`/`RegionFlatten` mutates the CFG — accepting +
    // emitting it corrupts the loop's header phi (a BROKEN MODULE on the
    // iteration-local-measured shape) or relies on the surviving loop-header phi
    // tripping `declineClassicalMuxes` (whose `classical-condition phi` string
    // mislabels the QUANTUM condition). The depth-2 in-loop NEST never reaches
    // here — it recovered as `RegionShape::Nested` and was dispatched to
    // `recoverRegionTree` above, so its `nested control flow` message is
    // unchanged.
    if (regionEntryInLoop(BI)) {
      diagnoseUnderControl(BI, "control flow inside a loop body");
      return;
    }
    // 6.5 (DD-7) — try the classical-call-under-control shape FIRST. A pure
    // classical call (all-classical-args) whose i32 result feeds the diamond
    // merge is route-merged by `ClassicalCallArmEmit` (no clone). On Accept it
    // set `R.Kind = ClassicalCallArm`; push it. On Declined it already fired the
    // precise diagnostic. NotApplicable falls through to `classifyArms` (the
    // phase/value/§3c classifier owns every other shape).
    switch (classifyClassicalCallArm(R, Taint)) {
    case ClassicalCallDisp::Accept:
      Plan.Regions.push_back(R);
      return;
    case ClassicalCallDisp::Declined:
      return;
    case ClassicalCallDisp::NotApplicable:
      break;
    }
    if (classifyArms(R, Taint) == ArmDisposition::Declined)
      return;  // ArmClassify already fired the precise diagnostic (§3c / value).
    // ACCEPT: a pure phase region over ONE tainted handle — a one-content-arm
    // diamond (WI-2) or a two-arm if/else (WI-3). Push it so `lowerControlRegions`
    // (SwapRouteEmit) emits the routed stream. Polarity: a diamond's single arm
    // rides `R.ArmNegated` (Rule 9 — clang -O1 may make the gate arm the false
    // successor); an if/else routes `R.Arm` (S0) under flag and `R.ArmFalse` (S1)
    // under ¬flag via the emitter's `cqrt_x` bracket.
    Plan.Regions.push_back(R);
    return;
  }
}

}  // namespace

// Scan every function for a tainted-condition `br i1` / `switch` / `select i1`:
// push each accepted phase-arm diamond onto the returned `ControlPlan` and
// decline everything else with its precise string. A classical-condition
// construct is left byte-untouched (detection keys strictly on condition taint).
// No IR is mutated here — emission is `SwapRouteEmit::lowerControlRegions`.
ControlPlan detectControlRegions(Module &M, TaintSet &taint) {
  ControlPlan plan;
  // Inner branches of an ACCEPTED nest, claimed by `recoverRegionTree` so the
  // loop does NOT re-visit them (blocker FA0): the inner tainted `br` recovers
  // FLAT in isolation (its 3-incoming merge → `soleMergePhi` null → OffPattern)
  // and would false-decline `control flow`, killing the accept. `-O1` visits the
  // outer Pred before the inner Mid, so the outer's claim lands first.
  SmallPtrSet<BranchInst *, 4> Claimed;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      Instruction *Term = BB.getTerminator();
      if (auto *BI = dyn_cast<BranchInst>(Term)) {
        if (BI->isConditional() && taint.Tainted.count(BI->getCondition()) &&
            !Claimed.count(BI))
          handleBranchRegion(BI, taint, plan, Claimed);
      } else if (auto *SI = dyn_cast<SwitchInst>(Term)) {
        // 4.5 — prove-or-decline a tainted-scrutinee `switch` instead of the
        // blanket decline (mirrors the 4.4 `classifySelectRegion` flip).
        // `classifySwitchRegion` runs the G0-G11 ladder: a real off-pattern shape
        // fires its precise per-shape string; a proven would-be-ACCEPT fires the
        // transitional `switch` string (WI-1 emit is stubbed — WI-2/3/4 push the
        // region + dispatch the emitter). The tainted-scrutinee entry guard is
        // unchanged. Switch is a TERMINATOR, so this stays in the terminator
        // dispatch (unlike the select scan's second instruction loop below).
        if (taint.Tainted.count(SI->getCondition())) {
          // d8jl — a flat tainted-scrutinee `switch` whose block is on a CFG
          // cycle (inside a loop body) declines with the accurate loop message
          // (mirrors the `br` Diamond/IfElse guard) before the G-ladder fires its
          // generic `control flow`; no in-loop switch is ever soundly ACCEPTED
          // (the N-way route + merge would flatten across the backedge), so this
          // only sharpens an already-declining path.
          if (regionEntryInLoop(SI))
            diagnoseUnderControl(SI, "control flow inside a loop body");
          else
            classifySwitchRegion(SI, taint, plan);
        }
      }
      // 4.4 — prove-or-decline a tainted-condition `select` instead of the
      // blanket decline. `classifySelectRegion` (SelectClassify) runs the §0
      // six-gate ladder: on ACCEPT it pushes a `SelectRegion` for
      // `SelectMergeEmit` (WI-3; WI-1 declines transitionally), else it fires the
      // precise per-shape string (`rotation angle` / `control flow`). The
      // per-block scan and the tainted-condition entry guard are unchanged; only
      // the body flips from the WI-1 transitional `select` decline.
      //
      // Deliberately NO `regionEntryInLoop` guard here (bd 9ymx, owner decision
      // 2026-07-03: conditionals in loops are ALLOWED): unlike br/switch above,
      // a select performs no CFG surgery -- there is no flatten to tear across a
      // backedge (the structural hazard d8jl guards) -- and the per-iteration
      // merge stream is faithful (fresh flag minted from the loop-invariant
      // condition wire each iteration, stripped and freed at |0>; a fresh |0>
      // out rail per iteration; the per-iteration measure is user-written).
      // Pinned by control_swap_select_inloop{,_hoisted_cond}.ll and the
      // slice_control_select_loop e2e golden.
      for (Instruction &I : BB)
        if (auto *Sel = dyn_cast<SelectInst>(&I))
          if (taint.Tainted.count(Sel->getCondition()))
            classifySelectRegion(Sel, taint, plan);
    }
  }
  return plan;
}

}  // namespace cq
