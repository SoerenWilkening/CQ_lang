// StageList.cpp — see StageList.h. The stage calls and their placement comments
// moved here verbatim from `CQLoweringPass::run` (bd p3kd.7.8); "run()" in the
// comments below means this sequence as `run()` calls it.
#include "StageList.h"

#include "ArmAnalysis.h"      // reverifyRailCondReads / reverifyCmpCondReads
#include "CondLiteral.h"      // declineQuantumCondLiterals / stripPredMuxPredictedMarks
#include "ControlPlan.h"
#include "CtlzIdiomPrepass.h"
#include "LoopPlan.h"
#include "LoopUnrollPrepass.h"
#include "MergePhiPeel.h"
#include "PredMuxFlatten.h"
#include "ReturnMerge.h"      // unifyTaintedReturns
#include "SelectMergeEmit.h"  // declineQuantumCopySources
#include "SpecializePlan.h"
#include "SwapRouteEmit.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Module.h"

using namespace llvm;

namespace cq {

void runLoopPrepasses(Module &M, TaintSet &taint,
                      PredMuxRailPhiRecord &railPhiRec, const StageScope &S) {
  // bd 3c6m.55 Inc 2 (Lever B, ticket lf8s) — static-K force-unroll pre-pass
  // (LoopUnrollPrepass.cpp): a PROVEN-constant-trip loop with no cq-family
  // call, no tainted control, and no 799w/dtzb in-place rail structure (the
  // openlibm `__polevll` Horner loops, kept rolled at -O1 by
  // `!llvm.loop.unroll.disable`) is fully unrolled to the straight-line form
  // the substrate already lowers. Runs HERE — after the fp80-union + PredMux
  // fixpoints (the relevance fence must read the SAME settled taint
  // `detectSpecializations` reads: the taint reaching a polevll accumulator
  // flows through Lever-A-promoted unions) and BEFORE `detectSpecializations`
  // (the spec-scan and the later clone must see the unrolled body) and
  // `lowerLoops` (a claimed loop is gone before `tryCaseA` would X1-decline
  // it; the fence is structurally disjoint from every rolled-in-place claim —
  // see the U1–U8 gate proof in LoopUnrollPrepass.h). ACCEPT-ONLY: an
  // off-fence loop is byte-untouched for its existing loud owner. One loop per
  // iteration + a full re-propagate (the PredMux precedent — the unroll erases
  // loop phis and clones body instructions, so `taint` is stale until
  // re-propagated); each unroll re-runs the PredMux fixpoint, since a region
  // that contained the loop (cyclic — PredMux never claims it) is acyclic and
  // claimable once the loop is gone.
  while (unrollConstTripLoops(M, taint)) {
    S.Repropagate();
    while (flattenPredMuxRegions(M, taint, S.ClaimAll, &railPhiRec))
      S.Repropagate();
  }

  // bd ww4c Inc 1 — the shift-count loop -> `llvm.ctlz` idiom recognizer
  // (CtlzIdiomPrepass.cpp): a rotated do-while `do { c--; x <<= 1; } while
  // ((signed)x > 0)` over a TAINTED entry value is replaced by its closed form
  // (C0-1) - (ctlz(v<<1) & (N-1)) — four already-linked template ops, no new
  // frozen symbol. Runs HERE, on the same reasoning as the unroll pre-pass
  // above and for one reason of its own: AFTER the fp80-union + PredMux
  // fixpoints (Z8 must read taint that has SETTLED through them — for the ld80
  // cells that taint arrives through the union promotion; NOT "the same taint
  // the rest of the pipeline reads", which bd ww4c.4 measured false: argument
  // taint is minted later by `detectSpecializations`, so a callee-hosted idiom
  // is never claimed — see CtlzIdiomPrepass.cpp), BEFORE `detectSpecializations`
  // (the spec-scan and any later
  // clone must see the rewritten body), and BEFORE `lowerLoops` (a claimed
  // loop is gone before Q1 would decline it). Same one-claim-per-call +
  // full-re-propagate + nested-PredMux-fixpoint shape: the claim mints tainted
  // SSA and erases the loop's, and the enclosing region was CYCLIC (PredMux
  // never claims a region containing a loop) so it becomes claimable the
  // moment the loop is gone. ACCEPT-ONLY, and note the ONE way this differs
  // from the unroll pre-pass: that fence is DISJOINT from the rolled-in-place
  // owners, while THIS ONE COMPETES WITH Q1 FOR THE SAME LOOPS (Q1 fires on a
  // tainted exiting condition, which every loop here has). So its failure mode
  // is a wrong CLAIM, not a wrong decline — see the Z1-Z9 contract in
  // CtlzIdiomPrepass.h.
  while (recognizeCtlzIdiomLoops(M, taint)) {
    S.Repropagate();
    while (flattenPredMuxRegions(M, taint, S.ClaimAll, &railPhiRec))
      S.Repropagate();
  }
}

std::unique_ptr<ControlPlan> runControlChain(Module &M, WidthDispatch &wd,
                                             TaintSet &taint, SpecPlan &plan6,
                                             const StageScope &S) {
  // Bounded loops (Phase 7.3, epic 799w): a classically-bounded loop over a
  // tainted body lowers ROLLED IN PLACE. `lowerLoops` (LoopLowering.cpp)
  // recognizes the §2.2 sound-rolled invariant by pure LoopInfo/SSA analysis
  // (Rule 9) and collapses each Case-A in-place persistent-rail phi (the
  // loop-carried header phi + the zero-trip/exit merge phi) to its single rail,
  // so the body's in-place gates (`cqrt_ry_<W>(%h, angle_i)`) reuse one handle.
  // Runs BEFORE `detectControlRegions` so a quantum/measurement-bounded loop
  // (Q1) is partitioned out with the dedicated `loop under quantum control`
  // message before ControlDetect declines it generically; BEFORE
  // `declineClassicalMuxes` so the collapsed header phi never reaches
  // `kMsgClassicalPhi`; and BEFORE `lowerRotations` (the still-present
  // `@cq_theta` SSA values). A cross-iteration dirty rail (X1) and a
  // tainted-exit loop (Q1) decline LOUDLY here; every other loop is left for its
  // existing owner. A purely-classical loop is untouched.
  lowerLoops(M, wd, taint);

  // Tainted control flow: `detectControlRegions` (ControlDetect.cpp) recognizes
  // each region by SSA identity (Rule 9, no mutation), pushes it onto
  // `plan.Regions`, and declines everything else loudly ("… under quantum
  // control", opt exits non-zero). `lowerControlRegions` (SwapRouteEmit) emits
  // each region (a phase arm by kickback: flag mint → `cqrt_rz_i1` on the flag →
  // `_unc` flag-strip → flag free; a value arm by the controlled-copy merge) and
  // flattens the CFG. It runs BEFORE `lowerRotations` so it can reference the
  // still-present `@cq_theta` result; the later RAUW-to-handle updates every
  // emitted call (Rule 9). A classical-condition branch stays byte-untouched.
  // bd test_C_libtooling-b6ap — THE MULTI-PHI MERGE PEEL (MergePhiPeel.cpp).
  // `clang -O1` fuses two consecutive source `if`s whose conditions it proves
  // equivalent into ONE diamond whose merge holds SEVERAL phi; `soleMergePhi`
  // returns null on >1 phi and `recoverRegion` then declines `control flow` for a
  // BOOKKEEPING reason (`ControlRegion::Merge` is a single `PHINode *`), not a
  // semantic one. This accept-only normalisation turns every merge phi the region
  // does NOT define into a tainted-condition `select` on a CLONE of the region's
  // compare (or on the rail itself), leaving the ONE phi the region needs and
  // handing the mux to the 4.4 `SelectClassify`/`SelectMergeEmit` substrate that
  // has lowered exactly that spelling since Phase 4.4.
  //
  // ⚠ THE SLOT: immediately BEFORE `detectControlRegions`, and AFTER the PredMux
  // fixpoint. Not before it — peeling first would hand PredMux a merge with one
  // phi where it had two, and BOTH of PredMux's own W5 and W7 witnesses require
  // `NumMergePhis == 1`, so an earlier peel could silently MOVE a PredMux accept.
  // Running after the fixpoint means every region PredMux can claim is already
  // gone, so the peel only ever sees shapes that decline today (its own >=2-phi
  // containment gate makes that exact; see the definition). The
  // `lowerControlledIOSinks` / `lowerLoops` precedent is the same "runs BEFORE
  // `detectControlRegions`" slot, for the same reason.
  //
  // ⚠ IT IS CALLED IMMEDIATELY BEFORE **EVERY** `detectControlRegions` CALL IN
  // THE TREE — here, in the second entry point, and inside
  // `TaintPropagation::detectAndLowerOnwardControl`'s round-2 fixpoint. That is
  // CLAUDE.md's standing lesson "a stage that runs ONCE has a round-2-FALSE
  // premise": `repropagateControlMerges` is a SECOND, FULL round of detection over
  // taint re-seeded from the 6.5/4.5 `%out` rails, so it creates regions round 1
  // never saw (MEASURED: probe `p80`, a fused 2-phi diamond whose condition reads
  // a 6.5 `%out`, against its accepting one-phi control `p81`). A fourth
  // `detectControlRegions` that forgets this call re-opens that window with no
  // diagnostic anywhere.
  //
  // NOTES §2's stage-table question — "does this stage compute something a LATER
  // stage consumes, over a premise round 2 falsifies?" — is YES-with-an-argument
  // here: the peel's P3 dominance and P7 clonability proofs are computed before
  // detection and consumed by it, but both are STRUCTURAL (dominance, block
  // shape, `isa<>`) and the peel changes no edge, so round 2 cannot falsify them
  // for a region round 1 already saw. What round 2 changes is WHICH branches are
  // tainted, and that is what the third call site is for.
  //
  // ⚠ AND THE PEEL GROWS TAINT, SO ITS DELTA IS ADJUDICATED — bd b6ap Rule-13
  // ROUND-1 finding F-B6-1, a CONFIRMED plain-C silent miscompile in five consumer
  // classes. The peel turns a CLASSICAL merge phi into a QUANTUM `select`, and
  // `detectSpecializations`, `declineTaintEscapes` and `declineStaleRecordOps`
  // (the `:NNN` marks below are line numbers in the pre-p3kd.7.8
  // CQLoweringPass.cpp this block was moved from) are pure-analysis pre-passes
  // that ran earlier on the premise that `propagate` had settled — so without this call a
  // `store`, an unknown callee, a visible-body callee or a STALE-MASK Phase-6
  // clone consumes the new rail's runtime HANDLE TAG as a classical integer, at
  // `opt` exit 0, verify-clean and STRICT stage-2b `0 violation(s)`.
  //
  // ⚠ THE SLOT IS THE ANSWER TO A MEASURED QUESTION, not a convenience. The
  // alternative was to MOVE the peel above `detectSpecializations` so the guards
  // see it in their normal single run; that is refused because the peel cannot
  // cross the four stages in between — `unrollConstTripLoops` (:273) and
  // `recognizeCtlzIdiomLoops` (:302) each RE-RUN the PredMux fixpoint internally
  // and PredMux's own W-witness is literally `NumMergePhis >= 2`
  // (`PredMuxFlatten.cpp`), so a peel above them MOVES a PredMux verdict;
  // `lowerControlledIOSinks` (:349) gates on `NumPhis == 0 || ValuePhi`, so a peel
  // above it manufactures NEW 7.6 I/O accepts nothing has measured (and retires
  // the containment-gate argument that its verdict is already final); and
  // `lowerLoops` (:365) is the eight-findings-over-six-rounds neighbourhood the
  // peel's own P9 refuses to widen into. Keeping the slot and re-asking the
  // guards costs one pure-analysis re-scan and removes the premise instead of
  // relocating it. See `FIX_b6ap_R1.md` for the per-stage table.
  //
  // bd `test_C_libtooling-dm7f.5` — the multi-exit `ret` normalization's SLOT (b)
  // shares this block and this delta: a `br` whose condition became tainted after
  // slot (a) (a rail-bank promotion, an `%out` at round 2) can reach two `ret`s
  // only now. Its new `cq.ret` φ is a taint-growth event exactly like a peeled
  // `select`, so it is adjudicated by the same `adjudicateTaintDelta` call.
  {
    SmallPtrSet<Value *, 32> PeelDelta;
    unifyTaintedReturns(M, taint, &PeelDelta);
    peelIndependentMergePhis(M, taint, &PeelDelta);
    adjudicateTaintDelta(M, wd, taint, plan6, PeelDelta);
  }

  // Heap-allocated so the plan is built in place (guaranteed elision) and never
  // moved after `detectControlRegions` returns; the caller keeps it for
  // `lowerRotations`.
  std::unique_ptr<ControlPlan> Plan(
      new ControlPlan(detectControlRegions(M, wd, taint)));
  lowerControlRegions(M, wd, taint, *Plan);

  // Bounded loops, ROUND 2 (Phase 7.3 Increment 3, bd test_C_libtooling-8h7d.5).
  // `lowerLoops` above deliberately leaves a loop with IN-BODY tainted control
  // unclaimed (`tryCaseA` gate L2) — pre-flatten it cannot peel the persistent
  // rail past the region's merge phi and would X1-decline a clean loop. The
  // regions are flattened now, so the same analysis is re-asked on the
  // straight-line body and collapses the loop-carried header phi to its root
  // mint (the rolled-in-place form, PRD 7.3 §2.1 — IR size independent of the
  // trip count). Placed HERE and not later for the SAME three reasons round 1
  // states: BEFORE `declineClassicalMuxes` (else the surviving rail phi
  // false-declines with `kMsgClassicalPhi`, whose "classical-condition" wording
  // mislabels a quantum register), BEFORE `lowerRotations` (pre-RAUW SSA
  // identity — the collapse target is the still-present `@cq_theta` mint), and
  // AFTER the flatten it depends on. A no-op unless an in-loop region was
  // actually emitted (`taint.InLoopFlattenedPreds`), so every pre-existing
  // module is byte-identical.
  // The `runOnFunction` unit shim has never run this stage (S.CollapseLoopRails
  // is false there); `run()` and a lifted clone do.
  if (S.CollapseLoopRails)
    collapseFlattenedLoopRails(M, wd, taint);

  // Issue dugh (Phase 4×6): the SECOND propagation round for control-merge
  // out-rails. The untainted-merge emitters (6.5 classical-call arm, 4.5 switch
  // data-mux, the IO-sink mux, and the 7.4 break escape register
  // `cq.brk.esc.out`, bd 8h7d.17) built a fresh quantum handle and RAUW'd a
  // (data-untainted) value to it after the first `propagate` ran, so its onward
  // consumers were classified CLASSICAL. The IO-sink mux and the break escape
  // register are minted before round-1 detection (`lowerControlledIOSinks`,
  // `lowerLoops`), so they already EXIST there, with their consumers still
  // classical; anything asked about those consumers before this point is round-1
  // evidence (L1). Re-seed a forward
  // propagation from `taint.UntaintedMergeRails` so an onward QUANTUM flow (arith /
  // phase / local-array Shadow store) is re-tainted and lowers via the stages
  // below, while an onward CLASSICAL escape / a new tainted-condition control on
  // `%out` declines via the re-run escape + control nets. Runs BEFORE
  // `lowerIOSinks`/`lowerQramReads`/`lowerShadowMemory` (they must see the newly-
  // tainted onward IO/QRAM/Shadow access), BEFORE `declineClassicalMuxes` (a
  // classical mux over a derived `%out` value), and BEFORE `lowerRotations` (the
  // tainted-angle guard + the newly-tainted onward `cq_phi`). A no-op when no
  // untainted-merge region was emitted.
  repropagateControlMerges(M, wd, taint, plan6);

  // bd test_C_libtooling-r9e5 (1b-B.1), Rule-13 ROUND-2 finding F-B1R2-1 — the
  // RAIL-LADDER RE-VERIFICATION, and its slot is the whole soundness argument,
  // exactly as it is for P7 immediately below. `classifySelectRegion`'s §14.3
  // ladder (rung (ii) measured-before, rung (iii) the wire question) and
  // `classifyPhaseKickback`'s step 5b run inside `detectControlRegions`, i.e.
  // with ROUND-1 taint — while `lowerRotations` decides chained-vs-source with
  // FINAL taint (`Chained = taint.Tainted.count(arg0)`). `repropagateControlMerges`
  // re-seeds taint from the 6.5/4.5 `%out` rails, so in that window a
  // `cq_theta_i1` on an `%out`-derived seed is a SOURCE theta to both of the
  // ladder's closures and a CHAINED one to the lowering: its SIBLING then rides
  // the same physical rail and the emitted control read fires on a register the
  // sibling moved (a CONFIRMED silent miscompile, plain C through the two-TU 6.5
  // recipe, `opt` exit 0 / verify-clean / STRICT-stage-2b clean). Every emitter
  // that reads a rail as a control RECORDS `(rail, first read)` at its emission
  // site; this stage re-asks the SAME two rungs here, where the taint is final,
  // and declines LOUDLY. It must run AFTER the round-2 fixpoint (nothing else
  // makes the answer final) and BEFORE `lowerRotations` (which erases the
  // `cq_theta_i1` calls the record names). A no-op for every module that never
  // read a bare `_Bool` register as a control.
  reverifyRailCondReads(M, taint);
  // (Track A.1; bd test_C_libtooling-9pum) THE COMPARE HALF of the same stage,
  // in the same slot for the same reason — `y` in the 6.5 two-TU reproducer is
  // an `%out` derivative, classical at round 1 and tainted after the fixpoint,
  // so the two `@cq_theta_*(y, ·)` siblings are two rails to the classifier and ONE
  // rail to `lowerRotations`. Immediately after its rail twin, not merged with
  // it: the compare record's rung (iii) is asked over the whole `condProvenance`
  // cone AT ONCE (`WireWalk::gateIsHarmless` grows its per-activation barriers
  // from the seed set it is handed), while a rail's is asked per rail.
  reverifyCmpCondReads(M, taint);
  // (bd `test_C_libtooling-xdu2.13`) THE LITERAL HALF, same slot, same reason: a
  // 4.4 condition node's classical `_hl` LITERAL was untainted at the classifier's
  // taint, and one derived from a 6.5/4.5 `%out` is quantum after the fixpoint —
  // a quantum value in a classical slot (Rule 3). Loud. The rule-(B) marks are
  // dropped immediately after: no classifier can ask again past this slot.
  declineQuantumCondLiterals(M, taint);
  // (bd `test_C_libtooling-r2j3.14`) THE DATA HALF of the literal re-ask, same
  // slot, same reason: a round-1 controlled-copy merge (4.4 select, 6.5 arm, 4.5
  // delta, IO-sink mux) loaded a CLASSICAL arm with `cqrt_alloc_<W>(v)`, and a `v`
  // derived from a 6.5/4.5 `%out` or a 7.4 break escape register is quantum after
  // the fixpoint, so the load would read a handle id. Loud.
  declineQuantumCopySources(M, taint);
  // bd `test_C_libtooling-3jru` — THE refusal of a register returned across a
  // function boundary, and its slot is the argument. The call-return closure lives
  // in `propagateWorklist`, through which `propagate`, the round-2 reseed and
  // `propagateFromSeeds` drain — and a DIRECT `Tainted` insert of a fresh rail
  // over an untainted value drains through it only if registered in
  // `UntaintedMergeRails` (the IO-sink mux rail was not until Rule-13 round 5
  // F-R5-1; the complete list is at `propagateWorklist`) — so every stage above
  // sees such a call result as quantum AT THE TAINT OF ITS OWN ROUND; asking HERE, after the
  // round-2 fixpoint, (a) reads FINAL taint — round 2 can taint a callee's `ret`
  // through a 6.5/4.5 `%out` (CLAUDE.md L1; Rule-13 round 4 F-R4-1 measured round
  // 3's `propagate`-only closure missing exactly that) — and (b) leaves the owners
  // ABOVE this slot untouched: the specializer's `detectSpecializations`, the loop
  // layer, and `declineQuantumCondLiterals` just above keep their strings
  // (measured, TRACK_E §6d/§6e). ⚠ Owners BELOW it are PRE-EMPTED in a
  // multi-function module whose callee returns a register: `declineClassicalMuxes`
  // and everything after now see this string instead of theirs (round 4 P3-b —
  // e.g. reviewer probes a08, g03, g05, which the oracle declined as `tainted value
  // muxed by a classical-condition phi`). Both are declines; only the owner moved.
  // Not for a lifted clone: returning its result handle is the Bennett
  // contract (the wrap copies it out), and the clone has no call site yet
  // (`retargetSite` runs after the build), so the fence would be vacuous there
  // today and wrong the day a site existed.
  if (!S.LiftedClone)
    declineQuantumReturnCalls(M, taint);
  stripPredMuxPredictedMarks(M);
  // (bd `test_C_libtooling-wx8g`) THE THIRD RE-ASK IN THIS SLOT, and it is about
  // a marking rather than a read: `ArmClassify`'s R7-loop clause (c) admitted an
  // ITERATION-LOCAL rotated register inside a rolled loop, and the per-trip
  // TEMPLATE rails that loop's body mints are discharged by the whole-DAG spine
  // ONLY inside `taint.IterationLocalBlocks`. `markIfRailLocal` populates that
  // set after the flatten at FINAL taint and can refuse — or never be asked —
  // for four reasons detection cannot see. Same placement rule as its two
  // neighbours: AFTER the round-2 fixpoint (nothing else makes the marking
  // final), BEFORE `lowerRotations` (which erases the `@cq_theta` the record
  // names). See `TaintPropagation.h`'s `RolledLoopRegionGates` for the measured
  // cost of getting this wrong (two entangled which-path rails leaked per
  // activation, `opt` exit 0 and stage-2b clean).
  declineUnmarkedRolledIterLocal(M, taint);
  // (bd `test_C_libtooling-fn1q` increment 1) THE FOURTH RE-ASK IN THIS SLOT, and
  // it is about a HOIST. `emitValueRegion` moved a value arm's CLASSICAL cone
  // into the pred on a ROUND-1 verdict that every member is untainted; the
  // round-2 re-seed from the 6.5/4.5 `%out` rails can falsify that, which would
  // leave a Q+Q chain link accepted under a Q+C premise — a shape `classifyArms`
  // DEFERS by design. Same placement rule as its three neighbours: AFTER the
  // fixpoint (nothing else makes the taint final), BEFORE `lowerRotations`.
  declineRound2TaintedArmCone(M, taint);
  return Plan;
}

}  // namespace cq
