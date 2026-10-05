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
// Disposition: an accepted region (phase-arm kickback, value arm, in-place Ry,
// select, switch, park, guarded store, classical call, ...) is pushed onto
// `plan.Regions` for `SwapRouteEmit::lowerControlRegions`; every other shape is
// declined with a precise per-shape string, a loud `DiagnosticInfoUnsupported`
// (opt exits non-zero).
//
// See swap-route 4.1 IMPLEMENTATION §0/§2/§3.

#include "ControlPlan.h"

#include "AbortParkEmit.h"
#include "ArmAnalysis.h"   // classifyPhaseKickback (3qlq Inc 1 P1 pre-peel)
#include "ArmClassify.h"
#include "ControlShape.h"
#include "GuardedStoreArmEmit.h"  // classifyGuardedStoreArm (iw81.7)
#include "RegionTreeDetect.h"
#include "SelectClassify.h"
#include "SwitchClassify.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include "llvm/Support/Signals.h"

#include <optional>
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
  // bd adia debug lever (env-gated, byte-neutral): print the offending instruction.
  if (::getenv("CQ_CTRL_DBG"))
    llvm::errs() << "CQ_CTRL_DBG: decline [" << What << "] at: " << *Where
                 << "\n";
  // bd `test_C_libtooling-fn1q` — THE SITE LEVER, beside the bd `adia` value
  // lever above. Env-gated and byte-neutral when unset.
  //
  // ⚠ IT EXISTS BECAUSE THE VALUE LEVER ALONE CANNOT ANSWER "WHICH FENCE FIRED".
  // Several decline strings have MANY call sites — `control flow` has dozens,
  // `value-arm swap-route` six — so `CQ_CTRL_DBG` naming the offending
  // instruction still leaves the reader guessing which predicate refused it, and
  // `LLVMContext::diagnose` EXITS on the first `DS_Error` (bd `br4a`), so the
  // usual way to find out is one rebuild per hypothesis. Measured on the fn1q
  // bisection: three probes that share two strings resolved to THREE DIFFERENT
  // predicates, and the bead's recorded attribution for one of them was wrong.
  // Read the frame below `diagnoseUnderControl`, then the symbol offset against
  // the source.
  if (::getenv("CQ_CTRL_BT"))
    llvm::sys::PrintStackTrace(llvm::errs());
  Where->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *Where->getFunction(), Msg, Where->getDebugLoc()));
}

// See the header for the two failure forms and why a null test alone is half a
// fix (F-W2-5). Deliberately NOT a `DebugLoc` predicate — the question is about
// an INSTRUCTION's anchor, and every caller has an instruction in hand.
bool anchorIsLocated(const Instruction *I) {
  if (!I)
    return false;
  const DebugLoc &DL = I->getDebugLoc();
  return static_cast<bool>(DL) && DL.getLine() != 0;
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
// A flat tainted-control region on a cycle had NO sound lowering when this was
// written (bd d8jl; see the 8h7d.5 narrowing below): the merge feeds the backedge /
// the base is a loop-carried phi, so `RegionFlatten` would erase the merge,
// leaving the loop's header phi dangling (a BROKEN MODULE, verified on the
// pre-3qlq register-form `for(){ q=cq_theta; if(q>5) q=cq_phi(q);
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
// THE WALK ITSELF, de-anonymized so a NON-region caller can ask the same question
// (bd drbq Inc 2b round-1 Rule-13 review, lens L3-1). `classifyAngleSelect`'s S7
// shipped spelled ONLY as `LoopInfo::getLoopFor`, which is a NATURAL-loop
// question, so an IRREDUCIBLE cycle through the select's block made it VACUOUS
// while the manual by-difference DIAMOND over the same cycle declined here. The
// repair is Rule 14: ONE walk, two callers — not a second reachability in
// `ArmClassify.cpp`.
bool blockOnCycle(BasicBlock *Entry) {
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

bool regionEntryInLoop(Instruction *Term) {
  return blockOnCycle(Term->getParent());
}

// ── bd test_C_libtooling-8h7d.5 (Phase 7.3 Increment 3) — the NARROWING ──────
//
// `regionEntryInLoop` above answers "is this region on a cycle". Until
// 2026-08-29 that answer alone declined, which made the natural spelling of a
// repeated quantum kernel — `for (i…) { if (q…) q = cq_phi(q, θ); … }` —
// uncompilable while its HAND-UNROLLED twin compiled. Owner ruling 2026-08-29:
// a purely CLASSICAL loop around a NON-EXITING tainted `if` must not decline;
// the loop stays ROLLED (PRD 7.3 §2.1 — IR size independent of the trip count).
//
// This predicate is the admission half. It answers a strictly narrower question
// than "is it on a cycle": is the cycle one that every DOWNSTREAM loop-aware
// guard can also see, and does the region sit wholly inside it?
//
//   (A) `LI.getLoopFor(Pred)` is a NATURAL loop `L`. This is the irreducible
//       fence, and the reason is NOT that `flattenRegion` cannot repair the
//       CFG — since bd dugh (2026-07-04, AFTER d8jl was written) it splices the
//       merge into the pred and then runs
//       `Pred->replaceSuccessorsPhiUsesWith(Merge, Pred)`, which repoints
//       exactly the loop-header phi incoming that d8jl's broken-module report
//       was about. The reason is the LAYER BELOW: every guard that adjudicates
//       the flattened body — `LoopLowering`'s Case-A/X1 rail analysis,
//       `markIfIterationLocal`, and `FreePoint`'s back-edge live-range reject —
//       is `LoopInfo`-gated, so an IRREDUCIBLE cycle is INVISIBLE to all three.
//       Admitting one would flatten a region into a cycle whose second
//       iteration nobody checks: a rail freed at iteration 1 and re-entered at
//       iteration 2 is a dirty free (Rule 6) that no shipped guard can see.
//       So `control_swap_reject_inloop_diamond_irreducible.ll` and
//       `control_swap_reject_nested_loop_irreducible.ll` stay RED, by design.
//   (B) Every region block sits at EXACTLY `L`'s depth (`LI.getLoopFor(BB) ==
//       L`). A region straddling a subloop boundary is unproven; a region in a
//       DEEPER subloop is that subloop's to adjudicate, not `L`'s.
//   (C) `L` has a single latch. Multi-latch is the unproven shape `tryCaseA`
//       already refuses; the round-2 rail collapse below reasons about one.
//   (D) The region entry is NOT on any cycle OTHER than `L`'s back edge. This
//       is (A) made exact: `LI.getLoopFor(Pred)` being non-null says the block
//       is inside SOME natural loop, not that the cycle through the REGION is
//       that loop's. A region on an irreducible sub-cycle NESTED inside a
//       natural outer loop would pass (A)+(B) — so the walk below re-runs the
//       `regionEntryInLoop` reachability with `L`'s back edges and `L`'s exits
//       cut. Reaching `Pred` again means a second, `LoopInfo`-invisible cycle:
//       decline.
//
// The tainted branch itself can never LEAVE the loop under (B): both its
// successors (`Arm`, `MergeBB`) are `L` blocks. That is the owner's
// "non-exiting" scope, structurally, not by a separate test. A tainted loop
// EXIT (Q1) never reaches here at all — `lowerLoops` runs BEFORE detection and
// `tryCaseA`'s L1 fires `loop under quantum control` first, and `LLVMContext::
// diagnose` exits on the first `DS_Error`.
//
// Pure analysis; mutates nothing (Rule 9).
bool flatRegionRollableInLoop(const ControlRegion &R, const LoopInfo &LI) {
  if (!R.Pred || !R.Arm || !R.MergeBB)
    return false;
  const Loop *L = LI.getLoopFor(R.Pred);
  if (!L)
    return false;  // (A) no natural loop → an irreducible cycle. Decline.
  auto atThisLevel = [&](const BasicBlock *BB) {
    return BB && LI.getLoopFor(BB) == L;
  };
  if (!atThisLevel(R.Arm) || !atThisLevel(R.MergeBB))
    return false;  // (B)
  if (R.ArmFalse && !atThisLevel(R.ArmFalse))
    return false;  // (B)
  if (!L->getLoopLatch())
    return false;  // (C)

  // (D) — the exact "no OTHER cycle through the entry" walk. Same shape as
  // `regionEntryInLoop` (each block visited once, no scan limit, reducibility-
  // independent), with two edge classes cut: `L`'s back edges (latch → header,
  // the cycle we ARE admitting) and every edge leaving `L` (a path that exits
  // can only come back through `L`'s header, i.e. a fresh entry to the whole
  // loop, which is not a cycle through the region within one activation).
  const BasicBlock *Header = L->getHeader();
  const BasicBlock *Entry = R.Pred;
  SmallPtrSet<const BasicBlock *, 16> Seen;
  SmallVector<const BasicBlock *, 16> Work;
  auto push = [&](const BasicBlock *From) {
    for (const BasicBlock *S : successors(From)) {
      if (S == Header)
        continue;  // `L`'s back edge — the admitted cycle.
      if (!L->contains(S))
        continue;  // leaves `L`.
      Work.push_back(S);
    }
  };
  push(Entry);
  while (!Work.empty()) {
    const BasicBlock *BB = Work.pop_back_val();
    if (BB == Entry)
      return false;  // a second cycle `LoopInfo` does not name — decline.
    if (!Seen.insert(BB).second)
      continue;
    push(BB);
  }
  return true;
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

  // Nested control — an ARM that is itself a tainted-condition branch (the
  // outer/mid arm of `if(q){if(q'){…}}`) — is recognized at the END of this
  // function, AFTER the diamond / if-else recognizers have had their turn.
  //
  // THE ORDER IS LOAD-BEARING, and it is what admits the SEQUENTIAL pair (bd
  // hcrg). Both shapes arrive here as "an immediate successor ends in a tainted
  // conditional br", but they are not the same shape:
  //   * ARM-hosted  → a real depth-2 NEST. The arm is not single-succ, so
  //     `uncondSucc(arm)` is null and EVERY recognizer below fails; control
  //     falls through to the `Nested` return at the bottom, unchanged.
  //   * MERGE-hosted → two SEQUENTIAL regions (`if(q){…} …; if(q'){…}` — the
  //     clang -O1 shape of two consecutive tainted ifs). Here both arms are
  //     clean single-succ blocks, so a recognizer below MATCHES and we return a
  //     real Diamond / IfElse.
  // The two can never be confused, because every recognizer below REQUIRES
  // `uncondSucc(arm)` to be non-null: a matched region's arms cannot host a
  // conditional branch of any kind, tainted or not.
  //
  // The sequential pair used to decline right here as `nested control flow`,
  // for a purely STRUCTURAL reason — block lifetime, never semantics.
  // Flattening region 1 splices + ERASES its merge block, which is exactly
  // region 2's Pred, so emitting both dereferenced freed memory (SIGSEGV on
  // valid input; §8 adversarial review 2026-06-10). That hazard is now handled
  // where it actually lives: `lowerControlRegions` ORDERS the emission so no
  // region is emitted after another has erased a block it names, and still
  // declines loudly on any alias ordering cannot resolve (the precedence graph +
  // Kahn order inline in `SwapRouteEmit::lowerControlRegions`, keyed on its
  // `sequentialChainAlias` predicate). Detection's job is to classify the shape;
  // it is not the place to work around an emitter's teardown order.

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
      // The MERGE hosting the NEXT region's tainted branch (sequential
      // `if/else; if`) is an ACCEPT since bd hcrg — the explicit decline that
      // stood here is gone, for the reason given at the top of this function.
      // The block-lifetime hazard it existed for is resolved by the emission
      // ordering in `lowerControlRegions`, not by refusing the shape.
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

  // No flat shape matched. An immediate successor that is itself a
  // tainted-condition branch is then the depth-2 NEST signal (see the note at
  // the top of this function for why this test lives here and not there);
  // `handleBranchRegion` hands it to `recoverRegionTree` to prove or decline.
  if (hasTaintedCondBranch(S0, Taint) || hasTaintedCondBranch(S1, Taint))
    return RegionShape::Nested;

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
  // ---- THE REGISTER-FREE BRANCH PHASE (bd 3qlq Inc 1 part A, Rule-13 round-1
  // finding F-L5-6 — a latent WIDENING). The `cq_phi_` prefix row below went
  // VACUOUS with the surface change, and the property it protected became
  // UNREPRESENTABLE in the SSA lineage: a register whose branches carry a
  // kickback phase has no `cq_phi` in its operand graph at all, because the gate
  // lands on a flag ancilla the register does not derive from. Without this
  // clause this fence silently answered "no phase" for a value that carries one.
  // Asked FIRST and COARSELY (any tainted-control branch phase in the same
  // function) — see `TaintPropagation.h` for why a precise, per-register answer
  // is a control-dependence question this backward operand walk cannot ask, and
  // why over-declining is safe here (every consumer turns `true` into a loud
  // decline).
  if (auto *OpI = dyn_cast<Instruction>(Op))
    if (functionCarriesBranchPhase(OpI->getFunction(), Taint))
      return true;

  SmallVector<Value *, 8> Work;
  SmallPtrSet<Value *, 16> Visited;
  Work.push_back(Op);
  Visited.insert(Op);
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (auto *CI = dyn_cast<CallInst>(V)) {
      const Function *F = CI->getCalledFunction();
      // ⚠ VACUOUS SINCE bd test_C_libtooling-3qlq Inc 1 — the `@cq_phi_<sfx>` family is
      // RETIRED and `StringRef("cq_phi").starts_with("cq_phi_")` is FALSE, so the
      // register-free `void @cq_phi(double)` never reaches here. Kept, not deleted
      // (PRD §6.2 row P6); see the note at `ArmClassify.cpp`'s `isPhiCall` for why
      // widening it would read the wrong operand.
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
  // survivors). ⚠ A BACKSTOP since bd test_C_libtooling-dm7f.5: the merge IS now
  // synthesized before every detection round (`unifyTaintedReturns`, ReturnMerge.h),
  // so a tainted `br` whose two arms are `ret` blocks reaches this row only when that
  // stage REFUSED the function (a load-bearing `musttail`), which has already fired
  // its own diagnostic; on a host whose handler does not exit (bd br4a) this is the
  // second, still-loud message. No fixture can reach it through `opt` any more
  // (control_swap_reject_nonreconverging_value_exit.ll was re-derived). REQUIRING
  // BOTH arms is LOAD-BEARING for the §2.11 mutual-exclusivity:
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
                        SmallPtrSetImpl<BranchInst *> &Claimed,
                        SmallPtrSetImpl<Instruction *> &ClaimedSelects,
                        const DominatorTree *DT, const LoopInfo *LI) {
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
  // bd test_C_libtooling-3qlq Inc 1 (PRD `retire-swap-route-PRD.md` §6.2 row
  // P1) — the register-free BRANCH PHASE, tried BEFORE `recoverRegion` for the
  // THIRD time in this function and for the identical reason: its arm is
  // `call void @cq_phi(double θ)`, a VOID call, so the merge block carries no φ
  // for the region and all three of `recoverRegion`'s recognizers — each of
  // which requires a non-null `soleMergePhi` — fall through to `OffPattern`.
  // MEASURED on the pre-increment oracle: the flagship Grover customer declined
  // `control flow` (via `offPatternDisposition`'s catch-all) with no lowering at
  // all.
  //
  // ORDER WITHIN THE PRE-PEELS IS NOT LOAD-BEARING and that is a checked
  // property, not luck: an abort/exit arm ends in `unreachable` (this
  // classifier's `uncondSucc(arm) == merge` shape test fails), and a guarded
  // Shadow store arm holds a `store` beside nothing this classifier recognizes
  // (its `NumPhase == 0` early-out). The three accept classes are disjoint by
  // arm CONTENT, so each pre-peel returns `NotApplicable` on the other two.
  switch (classifyPhaseKickback(BI, Taint, R, Plan, DT, LI, &ClaimedSelects)) {
  case PhaseKickbackDisp::Accept:
    Plan.Regions.push_back(R);
    return;
  case PhaseKickbackDisp::Declined:
    return;
  case PhaseKickbackDisp::NotApplicable:
    // `R` was used as scratch by the classifier (as it is by the two above);
    // reset it so `recoverRegion` starts from a clean region.
    R = ControlRegion();
    break;
  }
  // 3qlq Inc 1 part B (PRD §6.2 row P4) — the GENUINE depth-2 register-free
  // PHASE NEST, the FOURTH pre-peel and for the same reason as the third: its
  // merge carries no φ, so `recoverRegion` labels the whole thing `OffPattern`
  // and declines generically (MEASURED on `if (q>5){cq_phi(.25); if (q<9)
  // cq_phi(.75);}` at part A's HEAD — `control flow`, at the OUTER branch). It
  // must run AFTER the flat kickback, and that order IS load-bearing here,
  // unlike among the first three: a nest's outer branch has a `Mid` arm that
  // ends in a CONDITIONAL branch, which `classifyPhaseKickback`'s
  // `uncondSucc(arm) == merge` shape test refuses — so the flat classifier
  // returns NotApplicable on a nest, but only because it asks that question
  // first. Do not reorder them without re-deriving that.
  switch (classifyPhaseKickbackNest(BI, Taint, R, DT, LI, &Claimed,
                                    &ClaimedSelects)) {
  case PhaseKickbackDisp::Accept:
    Plan.Regions.push_back(R);
    return;
  case PhaseKickbackDisp::Declined:
    return;
  case PhaseKickbackDisp::NotApplicable:
    R = ControlRegion();
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
    // (inside a loop body) had no sound pre-3qlq NestedRouteEmit lowering: its
    // `flattenRegionTree` erased the shared merge — a backedge source — dangling
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
    // 4.3 — `recoverRegionTree` fires its precise §5h string, or `nested control
    // flow` for a nest that passes every criterion: it has accepted nothing since
    // 3qlq Inc 1 part B (the register-free nest is claimed above by
    // `classifyPhaseKickbackNest`). Nothing more to do here.
    recoverRegionTree(BI, Taint, Plan, Claimed);
    return;
  case RegionShape::Diamond:
  case RegionShape::IfElse:
    // d8jl — a FLAT tainted-condition control region whose entry is on a CFG
    // cycle (inside a loop body) is unsound to flatten as-is (see
    // `regionEntryInLoop`). Decline HERE, before `classifyArms` accepts and
    // `lowerControlRegions`/`RegionFlatten` mutates the CFG — accepting +
    // emitting it corrupts the loop's header phi (a BROKEN MODULE on the
    // iteration-local-measured shape) or relies on the surviving loop-header phi
    // tripping `declineClassicalMuxes` (whose `classical-condition phi` string
    // mislabels the QUANTUM condition). The depth-2 in-loop NEST never reaches
    // here — it recovered as `RegionShape::Nested` and was dispatched to
    // `recoverRegionTree` above, so its `nested control flow` message is
    // unchanged.
    //
    // NARROWED 2026-08-29 (bd test_C_libtooling-8h7d.5, owner ruling): a region
    // that `flatRegionRollableInLoop` proves sits wholly inside a REDUCIBLE
    // `LoopInfo` loop at one depth is ADMITTED and lowers ROLLED — read that
    // predicate for the full (A)-(D) argument and for why the irreducible half
    // of d8jl is kept verbatim. Everything else on a cycle keeps the decline.
    if (regionEntryInLoop(BI)) {
      if (!LI || !flatRegionRollableInLoop(R, *LI)) {
        diagnoseUnderControl(BI, "control flow inside a loop body");
        return;
      }
      R.InLoop = true;
    }
    // IN-LOOP SCOPE FENCE, part 1 (bd test_C_libtooling-8h7d.5). The owner's
    // increment is the NON-EXITING tainted `if` whose every ancilla is minted,
    // stripped and freed INSIDE the iteration, leaving only the persistent
    // register across the back edge. The 6.5 classical-call arm is a different
    // emitter with a different teardown (it HOISTS a call into the pred and
    // copy-merges its result into a fresh `%out` rail),
    // and no shipped analysis proves that `%out` is clean at the back edge — so
    // an in-loop classical-call arm keeps the loop decline rather than silently
    // acquiring an accept it was never cleared for (Prime Directive). Skipping
    // the classifier entirely (rather than declining its Accept) also keeps its
    // own precise diagnostics for the NON-loop case byte-identical.
    if (!R.InLoop) {
      // 6.5 (DD-7) — try the classical-call-under-control shape FIRST. A pure
      // classical call (all-classical-args) whose i32 result feeds the diamond
      // merge is copy-merged by `ClassicalCallArmEmit` (no clone). On Accept it
      // set `R.Kind = ClassicalCallArm`; push it. On Declined it already fired
      // the precise diagnostic. NotApplicable falls through to `classifyArms`
      // (the phase/value/§3c classifier owns every other shape).
      switch (classifyClassicalCallArm(R, Taint)) {
      case ClassicalCallDisp::Accept:
        Plan.Regions.push_back(R);
        return;
      case ClassicalCallDisp::Declined:
        return;
      case ClassicalCallDisp::NotApplicable:
        break;
      }
    }
    if (classifyArms(R, Taint, DT, LI) == ArmDisposition::Declined)
      return;  // ArmClassify already fired the precise diagnostic (§3c / value).
    // IN-LOOP SCOPE FENCE, part 2 — a VALUE arm inside a loop. Its
    // copy-out mints a FRESH `%out` rail per iteration and RAUWs the merge to
    // it, so the loop-carried register is a different handle every trip:
    // nothing proves `%out` is `|0>` at the back edge, and the per-iteration
    // leftover is linear in the trip count. `lowerLoops`' X1 would catch
    // the loop-carried spelling as a cross-iteration dirty rail, but NOT an
    // iteration-local one — so decline HERE, with the loop message, rather than
    // lean on a guard that does not cover the whole shape. Deferred, not
    // impossible (the 7.x-widenings tracker owns it).
    if (R.InLoop &&
        (R.ClassArm == ArmClass::Value || R.ClassArmFalse == ArmClass::Value)) {
      diagnoseUnderControl(BI, "control flow inside a loop body");
      return;
    }
    // IN-LOOP SCOPE FENCE, part 3 — RETIRED 2026-09-04 (bd
    // test_C_libtooling-drbq Increment 3), and retired rather than re-asked, for
    // a reason worth stating: it was a BLANKET decline of the very shape this
    // increment ships. A control-in-place ROTATION arm inside a rollable loop is
    // now an ACCEPT (PRD §13), so a backstop that still fired here would refuse
    // it after `classifyArms` had already proved it — Rule 17's "a decline is not
    // the development escape hatch", one level down.
    //
    // WHAT REPLACED IT, so nobody re-adds a guard for a question that IS asked.
    // The loop half of R7 now lives entirely in `classifyArms`, where it can see
    // the rotated base's wire closure: clause (b) requires a `BaseWire` member
    // that is a PHINode in `L`'s header (the rail crosses the back edge — an
    // iteration-local rotated register is out of scope and is measurably NOT
    // twin-identical), and clause (b') requires that φ to be one the round-2
    // collapse will claim, asked by CALLING `LoopPlan.h`'s `railPhiRootMint` —
    // the collapse's own step-(1) body. Both fire the SAME string this did. R6 is
    // then asked PER ACTIVATION (`recordLivePerActivation`), which is the fence
    // that makes the loop-carried header φ readable at all.
    //
    // The CFG half is unmoved and is still asked BEFORE this point:
    // `flatRegionRollableInLoop` (A)-(D) is what sets `R.InLoop` in the first
    // place, so an irreducible cycle, a two-depth region, a multi-latch loop or a
    // second cycle through the entry never reaches the classifier at all. Parts 1
    // (6.5 classical-call arm) and 2 (value arm) are UNCHANGED — neither
    // was cleared for a loop and neither moves in this increment.
    // ACCEPT: what `classifyArms` proved (e.g. a value arm, an in-place Ry arm or
    // a controlled state prep; the register-free phase arm was pre-peeled above).
    // `lowerControlRegions` hands it to `emitRegion`. Polarity: a diamond's single
    // arm rides `R.ArmNegated` (Rule 9 — clang -O1 may make the gate arm the false
    // successor); an if/else fires `R.Arm` (S0) under flag, `R.ArmFalse` (S1) under
    // ¬flag.
    Plan.Regions.push_back(R);
    return;
  }
}

}  // namespace

// Scan every function for a tainted-condition `br i1` / `switch` / `select i1`:
// push each accepted region onto the returned `ControlPlan` and
// decline everything else with its precise string. A classical-condition
// construct is left byte-untouched (detection keys strictly on condition taint).
// No IR is mutated here — emission is `SwapRouteEmit::lowerControlRegions`.
ControlPlan detectControlRegions(Module &M, WidthDispatch &wd,
                                 TaintSet &taint) {
  ControlPlan plan;
  // Inner branches of an ACCEPTED nest, claimed by `classifyPhaseKickbackNest`
  // so the loop does NOT re-visit them (blocker FA0): the inner tainted `br`
  // recovers FLAT in isolation (pre-3qlq: 3-incoming merge → OffPattern) and
  // would false-decline `control flow`, killing the accept. `-O1` visits the
  // outer Pred before the inner Mid, so the outer's claim lands first.
  SmallPtrSet<BranchInst *, 4> Claimed;
  // 3qlq Inc 1 part B (P3) — the LOGICAL `select i1` nodes of an ACCEPTED
  // compound BRANCH-PHASE condition tree. They are that region's CONDITION, not
  // data muxes, and `emitPhaseKickbackRegion` erases them; letting the select
  // scan below also classify one produces a `SelectRegion` whose `Merge` is
  // freed memory by the time `emitSelectRegion` runs (a SIGSEGV, measured on
  // `if (q==5 && r==3) cq_phi(θ)`). Function-local like `Claimed`: it is
  // rebuilt per function because both sets only ever name instructions of the
  // function being scanned.
  //
  // ⚠ IT INHERITS `Claimed`'s BLOCK-ORDER ASSUMPTION, and the inheritance is
  // exact: both sets are filled when a region's OUTER construct is dispatched,
  // and both are read when a block that construct OWNS is reached — so both rely
  // on the owner being visited first. That is the same assumption the 4.3 nest
  // recorded as "`-O1` visits the outer Pred before the inner Mid, so the outer's
  // claim lands first". WHEN IT FAILS THE OUTCOME IS A LOUD DECLINE, NOT A
  // MISCOMPILE: the inner `br` recovers `OffPattern` on its own and fires
  // `control flow`, so `opt` exits non-zero before any output is written —
  // MEASURED, and clean under Guard Malloc
  // (control_phase_nest_reject_block_order.ll). Nothing `clang -O1` produces has
  // that layout; the fix if it ever becomes reachable is to dispatch terminators
  // in reverse post-order, NOT to widen a classifier.
  SmallPtrSet<Instruction *, 4> ClaimedSelects;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // ONE `DominatorTree` per function, threaded down to `classifyArms` (bd
    // test_C_libtooling-lom0 Inc 4). Detection mutates nothing —
    // `recoverRegion`, the classifiers and the wire walks are pure SSA analysis,
    // and every emitter/flattener runs later in `lowerControlRegions` — so one
    // tree is valid for this whole sweep and is never cached across an erasure
    // (Rule 9).
    //
    // Built LAZILY, on the first tainted conditional branch, and that is a
    // MEASURED choice, not a reflex: an unconditional `DominatorTree DT(F)`
    // costs ~60ms per `opt` invocation on a 1536-line libm slice whose functions
    // mostly have no tainted branch at all (0.376s -> 0.436s, 5-run mean), and
    // the census corpus is full of such modules. `std::optional` keeps the
    // one-tree-per-function property exactly — it just does not pay for it in
    // functions that never ask.
    std::optional<DominatorTree> DT;
    // bd test_C_libtooling-8h7d.5 — the `LoopInfo` the in-loop narrowing needs,
    // built from the SAME lazy `DominatorTree` and on the same first-tainted-
    // branch trigger (so a function with no tainted branch still pays nothing).
    // Detection mutates nothing, so one tree/one LI is valid for the whole sweep
    // and is never cached across an erasure (Rule 9) — every flatten happens
    // later, in `lowerControlRegions`.
    std::optional<LoopInfo> LI;
    ClaimedSelects.clear();
    for (BasicBlock &BB : F) {
      Instruction *Term = BB.getTerminator();
      if (auto *BI = dyn_cast<BranchInst>(Term)) {
        if (BI->isConditional() && taint.Tainted.count(BI->getCondition()) &&
            !Claimed.count(BI)) {
          if (!DT) {
            DT.emplace(F);
            LI.emplace(*DT);
          }
          handleBranchRegion(BI, taint, plan, Claimed, ClaimedSelects, &*DT,
                             &*LI);
        }
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
          // (the N-way merge would flatten across the backedge), so this
          // only sharpens an already-declining path.
          if (regionEntryInLoop(SI)) {
            diagnoseUnderControl(SI, "control flow inside a loop body");
          } else {
            // 3qlq Inc 1 part B (PRD §6.2 row P5) — the register-free PHASE
            // switch is PRE-PEELED, the fifth pre-peel and for the same reason
            // as the third and fourth: with `void @cq_phi(double)` arms the
            // merge carries no φ, so the G0-G11 ladder's G1
            // (`soleSwitchMergePhi`) refuses it and declines generically. The
            // ladder still owns the VALUE and DATA-MUX classes, which DO have a
            // merge φ.
            ControlRegion SR;
            switch (classifyPhaseKickbackSwitch(SI, taint, SR)) {
            case SwitchPhaseKickbackDisp::Accept:
              plan.Regions.push_back(SR);
              break;
            case SwitchPhaseKickbackDisp::Declined:
              break;
            case SwitchPhaseKickbackDisp::NotApplicable:
              classifySwitchRegion(SI, taint, plan);
              break;
            }
          }
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
      //
      // bd drbq Inc 2b: the lazy `DominatorTree`/`LoopInfo` above is now built on
      // the first tainted BRANCH **or SELECT**, because gate 3's angle-select
      // hook needs both (`LI` for the flat-only fence, `DT` for R6's position
      // proofs). A function with a tainted select and no tainted branch used to
      // pay nothing and would have handed the hook a null pair — which is a
      // silent OVER-DECLINE (`NotApplicable` ⇒ the pre-2b `rotation angle`), not
      // a miscompile, but it would have made the accept depend on whether some
      // OTHER construct in the same function happened to build the tree. The
      // measured cost of the lazy trigger is unchanged for every function that
      // has neither (`std::optional` — nothing is built).
      for (Instruction &I : BB)
        if (auto *Sel = dyn_cast<SelectInst>(&I))
          if (taint.Tainted.count(Sel->getCondition()) &&
              !ClaimedSelects.count(Sel)) {
            if (!DT) {
              DT.emplace(F);
              LI.emplace(*DT);
            }
            classifySelectRegion(Sel, taint, wd, &*DT, &*LI, plan);
          }
    }
  }
  return plan;
}

}  // namespace cq
