// OpcodeLowering.cpp — the single ordered driver for tainted data-opcode
// lowering (Phase 3; PRD §2.2/§2.3, IMPLEMENTATION §1.4/§5.3). It owns
// collection, program order, cast-width capture, dispatch, and erase; the
// per-instruction emit + RAUW + bookkeeping lives in the class lowerers
// (`ArithLowering`, `CompareLowering`, `CastLowering`).
//
// One program-order walk over all four tainted instruction classes
// (`BinaryOperator`, `UnaryOperator`, `CmpInst`, `CastInst`) builds:
//   * `Work`  — instructions to rewrite, in program order. SSA dominance
//     guarantees producers precede consumers, so when a consumer is
//     rewritten its operands are already template handles (RAUW propagated
//     them) and already in `taint.Tainted` (IMPLEMENTATION §1.4).
//   * `CastW` — captured (from,to) ABI widths per tainted cast, recorded
//     BEFORE any rewrite mutates an operand. `CastInst::getSrcTy()` reads
//     `getOperand(0)->getType()`, so once the operand is RAUW'd to an i32
//     handle the source width is lost (PRD §2.3 / risk R1). Capture is why
//     collection is fully up-front.
//
// After collection the driver iterates `Work`, dispatches by `dyn_cast` to
// the matching rewriter, and erases ONLY the instructions that were
// actually rewritten. A rewriter returns false when it diagnosed/left an
// op un-lowered (unsupported opcode/width) — that op must stay in the IR
// (erasing a still-used value would corrupt it / break `opt -verify`).
//
// All four classes are live: binary + unary (ArithLowering), compare
// (CompareLowering), and cast (CastLowering). Each rewriter returns false on
// an unsupported op so the driver leaves it un-lowered and `opt -verify`
// stays clean.

#include "OpcodeLowering.h"

#include "ArithLowering.h"
#include "CastLowering.h"
#include "CompareLowering.h"
#include "IntrinsicLowering.h"
// bd test_C_libtooling-eqpx — `inPlaceValueRailOperand` (G2), the ONE spelling of
// the dtzb shape test that every `taint.InPlaceRailOps` writer proved with. The
// consumer tripwire below re-asks THAT predicate under final taint; Rule 14 says
// ask it, never re-spell it.
#include "LoopPlan.h"
#include "OpcodeSupport.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"
#include "WireWalk.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/AssumptionCache.h"   // leg 1b's SCEV (bd 3d8q F-D2-2)
#include "llvm/Analysis/CFG.h"  // isPotentiallyReachable (bd 3d8q mutual-exclusion leg)
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"   // leg 1b (bd 3d8q F-D2-2)
#include "llvm/Analysis/TargetLibraryInfo.h" // leg 1b's SCEV (bd 3d8q F-D2-2)
#include "llvm/TargetParser/Triple.h"        // leg 1b's SCEV (bd 3d8q F-D2-2)
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/ErrorHandling.h"  // report_fatal_error (bd 3d8q F-D1-2, outcome 3)
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

#include <optional>
#include <vector>

using namespace llvm;

namespace cq {

namespace {

// Loud decline for a stale-record pure producer. Same
// `DiagnosticInfoUnsupported(DS_Error)` surface + `!dbg` source location as
// the rest of the pass; the negative fixtures mirror the message
// character-for-character (Rule 12).
void diagnoseStaleRecord(Instruction *I) {
  I->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *I->getFunction(),
      "cq opcode lowering: operand predates a non-diagonal gate",
      I->getDebugLoc()));
}

// (1b) Loud decline for a PRE-LOOP in-place commitment whose fence no longer
// holds at lowering time — bd 3qlq Inc 1, C-1 review round 3, finding F-C1B-1.
// The message is owned by `cq loop lowering` because the DECISION is
// `LoopLowering::commitOutOfLoopInPlaceOps`'; only the re-verification lives
// here, where the final CFG and the final taint exist. Same
// `DiagnosticInfoUnsupported(DS_Error)` + `!dbg` surface as the rest of the pass,
// mirrored character-for-character by a negative fixture (Rule 12).
void diagnosePreLoopCommitStale(Instruction *I) {
  I->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *I->getFunction(),
      "cq loop lowering: pre-loop in-place op no longer provable at lowering",
      I->getDebugLoc()));
}

// THE eqpx TRIPWIRE — loud decline for an IN-LOOP in-place rail marking whose G2
// shape no longer holds at lowering time (bd test_C_libtooling-eqpx, P1). The
// (1b) sibling above owns `commitOutOfLoopInPlaceOps`' PREDICTION; this one owns
// the three LOOP writers' PROOF, whose stale input is a different one — the
// "classical immediate" that stopped being classical. The message is likewise
// owned by `cq loop lowering` because the DECISION is `LoopLowering`'s; only the
// re-verification lives here, where the final taint exists. Same
// `DiagnosticInfoUnsupported(DS_Error)` + `!dbg` surface, mirrored
// character-for-character by eight negative fixtures (Rule 12).
void diagnoseRailOpStale(Instruction *I) {
  I->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *I->getFunction(),
      "cq loop lowering: in-place rail op no longer provable at lowering",
      I->getDebugLoc()));
}

// (bd test_C_libtooling-3d8q) THE STALE-READER DECLINE for a `@cq_theta_<sfx>` /
// `@cq_measure_<sfx>` reader of a stale name. A SEPARATE STRING from
// `diagnoseStaleRecord` above, and deliberately so:
//   * the OWNING STAGE is the same (`declineStaleRecordOps`, one operand policy
//     wider), which is why the `cq opcode lowering:` prefix is retained — the
//     project's convention is that the message names the stage that owns the
//     DECISION (`diagnosePreLoopCommitStale` above says this in as many words);
//   * the FAMILY is not, and the corpus sweep's mover attribution is BY STRING
//     (PROTOCOL S1), so folding this into the shipped opcode string would make
//     an ACCEPT→DECLINE row on a rotation reader indistinguishable from one on
//     an `add`. It would also make Rule 12's "does this negative fixture pin the
//     NEW predicate?" unanswerable — fixture-hygiene defect (c), the decline
//     fixture that goes green because its subject is somebody else's.
// ⚠ The string deliberately does NOT begin with `cq_measure_`: the shared
// `corpus.sh` tag regex renders that whole family as an empty `D:` (PROTOCOL S3),
// which would make this decline INVISIBLE to the sweep it must be attributed in.
void diagnoseStaleQuantumReader(Instruction *I) {
  I->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *I->getFunction(),
      "cq opcode lowering: rotation/measure operand predates a non-diagonal "
      "gate",
      I->getDebugLoc()));
}

// (bd test_C_libtooling-3d8q) The operand a `@cq_theta_<sfx>` / `@cq_measure_<sfx>`
// call reads AS A BASIS RECORD, or nullptr when `I` is not one of those or the
// operand carries no wire. THE P1 SILENT MISCOMPILE THIS CLOSES: `inLowerOpsScope`
// below is `BinaryOperator | UnaryOperator | CastInst | data-position Cmp |
// curated intrinsic`, so a rotation or a measurement reading a stale name was
// asked NOTHING, while a PURE op reading the same name declined. One line of
// plain C — `int b=cq_theta(q,.5); int c=cq_theta(q,.9); return
// cq_measure(b)+cq_measure(c);` — lowered to a stream BYTE-IDENTICAL to the
// well-formed chain `a=cq_theta(q,.5); c=cq_theta(a,.9); cq_measure(c)+cq_measure(c)`:
// two different programs, one circuit, `opt` exit 0 and stage 2b clean (Rule 2 in
// its purest form; bd 3d8q, review_1b_r2.md §F-1b2-1).
//
// ⚠ ARG-0 ONLY, and that is RULE 3 MADE STRUCTURAL, not an optimization. A
// `cq_theta`'s arg-1 is the CLASSICAL ANGLE; walking its wire would be the
// f64/angle wire-crossing this project has hit repeatedly. The exclusion is
// spelled by never looking past index 0, not by a taint test that a future
// tainted-angle program could pass.
//
// A SOURCE theta (arg-0 is the classical init) and the 21mg CLASSICAL measure
// (`cq_measure(<untainted>)`) both fall out here with no special case: their
// arg-0 is not tainted, so there is no wire to be stale about. The register-free
// `void cq_phi(double)` has NO handle operand at all and the 15-width
// `cq_phi_<sfx>` family is retired (a use is a reserved-name decline), so the
// phase intrinsic is structurally out of this fence.
//
// The name test is the PREFIX form, matching `WireWalk.cpp`'s own
// `isCallToPrefix(CI, "cq_theta_")` and `RotationLowering.cpp`'s collection loop
// character-for-character. That lockstep is the point: this fence's reader family
// must be exactly the family the walker treats as a gate, or the two disagree
// about what a rail is. `resolveSources` has already validated every surviving
// `cq_theta_<sfx>` / `cq_measure_<sfx>` prototype by the time this runs.
Value *staleReaderRecordOperand(Instruction &I, TaintSet &taint) {
  auto *CI = dyn_cast<CallInst>(&I);
  if (!CI || CI->arg_size() < 1)
    return nullptr;
  const Function *F = CI->getCalledFunction();
  if (!F)
    return nullptr;
  StringRef N = F->getName();
  if (!N.starts_with("cq_theta_") && !N.starts_with("cq_measure_"))
    return nullptr;
  Value *A0 = CI->getArgOperand(0);
  return taint.Tainted.count(A0) ? A0 : nullptr;
}

// Is `I` an instruction `lowerOps` would collect? Mirrors the Phase-1
// collection below exactly: the four tainted classes, with branch/select-
// condition compares excluded (Phase 4's — ArmClassify owns their stale
// check via the provenance-seeded wire walk and its own diagnostic).
//
// ⚠ NOT WIDENED by bd 3d8q, and that is deliberate: it answers "would `lowerOps`
// collect this?", which is FALSE of a `@cq_theta_*` / `@cq_measure_*` call
// (`lowerRotations` / `lowerMeasures` own those). The stale sweep's scope is the
// UNION of this and `staleReaderRecordOperand` — see `declineStaleRecordOps`.
// Several shipped fixture headers quote this set verbatim as
// "binary/unary/cast/data-compare/curated-intrinsic"; keeping the predicate
// honest keeps those citations true.
bool inLowerOpsScope(Instruction &I, TaintSet &taint) {
  if (!taint.Tainted.count(&I))
    return false;
  if (isa<BinaryOperator>(&I) || isa<UnaryOperator>(&I) || isa<CastInst>(&I))
    return true;
  if (auto *Cmp = dyn_cast<CmpInst>(&I))
    return isDataPositionCompare(Cmp);
  // Phase 7.1 Increment E: a curated reversible intrinsic is a tainted pure
  // producer lowered in Phase 2, so it is subject to the SAME stale-record
  // precondition as add/mul/cast — its handle operand must not predate a
  // non-diagonal wire gate (a chained `theta` re-rotating the same wire), or
  // the template reads the post-Ry basis while the SSA operand denotes the
  // pre-Ry record (the verify-clean stale-record miscompile). Without this the
  // intrinsic would bypass declineStaleRecordOps where the add-shaped program
  // declines. checkStaleOp walks each tainted operand's wire; the constant i1
  // flag / rotation amount are untainted and skipped.
  // bd 3c6m.2: a curated DIRECT-libm call (cbrt/atan2/ilogb/ldexp/…) is likewise
  // a tainted pure producer lowered in Phase 2, so its fp handle operand is
  // subject to the SAME stale-record precondition (a chained theta re-rotating
  // the wire → the post-Ry-basis miscompile). checkStaleOp walks each tainted
  // operand's wire; a classical exponent/literal is untainted and skipped.
  if (auto *CI = dyn_cast<CallInst>(&I))
    return isCuratedReversibleIntrinsic(CI);
  return false;
}

// Per-op stale-record check (shared by the straight-line guard and the
// post-lift re-check, Rule 14). For each tainted operand of `I`, walk its
// forward in-place-gate wire; if it gains a non-diagonal gate not provably
// after `I`'s emission point, fire the loud diagnostic, record `I` in
// `StaleDeclined` (so `lowerOps` lowers nothing for it), and return true. `DT`
// must be the dominator tree of `I`'s function.
bool checkStaleOp(Instruction &I, TaintSet &taint, DominatorTree &DT) {
  if (taint.StaleDeclined.count(&I))
    return false;  // already declined — idempotent across the post-lift re-sweep.
  for (Value *Op : I.operands()) {
    if (!taint.Tainted.count(Op))
      continue;  // classical operand — no wire.
    if (findNonDiagonalWireGate(Op, /*CrossValueRouting=*/true, &I, &DT,
                                &taint)) {
      diagnoseStaleRecord(&I);
      taint.StaleDeclined.insert(&I);
      return true;  // one diagnostic per op; lowerOps will skip it.
    }
  }
  return false;
}

}  // namespace

void declineStaleRecordOps(Module &M, TaintSet &taint) {
  // WHY POSITION-AWARE (and why that is not the MINT_AT_COMPARE §4 trap):
  // a pure tainted producer's template is emitted AT THE PRODUCER'S OWN
  // scheduled position, and opaque calls keep their order through the
  // backend — so the schedule this pass sees IS the emitted gate stream.
  // The §4 lesson ("position is not provenance") condemned inferring wire
  // state at one point (the branch-time mint) from the schedule of ANOTHER
  // instruction (the compare); here the inspected point and the emission
  // point are the same instruction, so dominance over the operand's wire
  // gates is exactly the emitted-stream order. Consequences:
  //   * `d = q + 1` SCHEDULED BEFORE a chained `theta(q, t2)` stays
  //     accepted: the template fires pre-Ry, capturing the record onto its
  //     own fresh rail — matching SSA semantics — and the later Ry on `q`'s
  //     wire cannot touch that rail (fixture
  //     lowering_stale_record_add_before_theta.ll pins this boundary).
  //   * the same op SCHEDULED AFTER the chained theta declines: the
  //     template would read the post-Ry basis while `%d` denotes the
  //     pre-Ry record (the confirmed verify-clean miscompile; fixture
  //     lowering_reject_stale_record_add.ll).
  //   * a position-FREE rule would over-decline the first shape — a
  //     legitimate use-then-re-rotate program — for no soundness gain.
  // Diagonal gates (`cq_phi`/Rz) on the wire are basis-preserving and never
  // trigger (bd memory rz-diag-flag-strip-invariant; fixture
  // lowering_stale_record_add_after_phi.ll). An operand that is itself a
  // diagonal ALIAS (`%qd = cq_phi(%q, ·)`) shares `%q`'s physical wire, so a
  // chained theta consuming the SIBLING name `%q` stales it too — the wire
  // walk closes every seed backward through `cq_phi` arg-0 hops before
  // walking forward (test_C_libtooling-6j1; fixtures
  // lowering_reject_stale_record_alias_{sibling,chain}.ll, accept twins
  // lowering_stale_record_alias_{before_theta,producer}.ll).
  //
  // ── WHERE THIS RUNS, AND THE L1 ANSWER (bd 3d8q) ─────────────────────────
  // This sweep is called from FOUR slots and needs no fifth:
  //   1. `CQLoweringPass.cpp` (both entry points), EARLY — before `lowerLoops`,
  //      before the peel, before control detection. The `@cq_theta_*` /
  //      `@cq_measure_*` calls still exist here as calls (rotation and measure
  //      lowering run ~300 lines later), which is precisely why the widened
  //      operand policy CAN see them;
  //   2. `adjudicateTaintDelta` — the guard sequence EVERY taint-growth event
  //      owes (the `MergePhiPeel` sites, bd b6ap), which ends with this call;
  //   3. the same, inside `repropagateControlMerges` on the round-2 `reseed`;
  //   4. `declineLiftedStaleRecordOps`, after the one-register merge-phi lift.
  // So "can a value become a stale reader only in ROUND 2?" — yes (a 6.5/4.5
  // merge `%out` rail is untainted at round 1), and slot 3 is what asks about it:
  // the widening rides the SAME re-run the pure-op policy already rides, because
  // it is one operand policy inside one function rather than a new stage with a
  // premise of its own. A NEW SWEEP SITE would have owed the L1 question; this
  // does not, and that is the reason it was built this way.
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Built lazily — only when a tainted in-scope op exists in `F`.
    std::optional<DominatorTree> DT;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (!inLowerOpsScope(I, taint))
          continue;
        if (!DT)
          DT.emplace(F);  // a tainted in-scope op always has a tainted operand.
        checkStaleOp(I, taint, *DT);
      }
    }
  }
}

void declineLiftedStaleRecordOps(Module &M, TaintSet &taint) {
  // Re-adjudicate stale records exposed by the one-register merge-phi lift
  // (test_C_libtooling-2qyz). `liftOneRegisterMergePhi` (declineClassicalMuxes)
  // RAUWs a proven pure-renaming phi to its wire BASE and erases it — AFTER
  // `declineStaleRecordOps` already ran. An in-scope op that consumed the phi
  // (directly or through intervening in-place-gate hops) now resolves to the
  // base, so a sibling Ry re-rotating the base's wire — invisible to the first
  // guard, whose backward closure stops at the opaque PHINode — now stales it.
  //
  // The re-check is a FULL re-sweep, NOT scoped to the phi's direct users. A
  // Rule-13 adversarial probe (2026-06-11) showed that scoping to the recorded
  // direct consumers is INCOMPLETE: a stale arithmetic op can sit ANY number of
  // in-place-gate hops (a diagonal `cq_phi`/Rz, or a chained `cq_theta`/Ry, both
  // valid wire-sharing users that are not themselves `lowerOps` ops) downstream
  // of the lifted phi, so the genuine stale op is a TRANSITIVE user the direct
  // re-check never visits — a residual silent miscompile. Re-running the
  // COMPLETE `declineStaleRecordOps` on the post-lift IR adjudicates every
  // exposed op: the phi is now the base SSA value, so the (unchanged) WireWalk
  // closure walks each consumer's wire all the way to the origin and finds the
  // sibling regardless of how many hops away the consumer sits (Rule 14 — reuse
  // the exact analysis, add no parallel wire-walk).
  //
  // Gated on a lift having occurred (`LiftedConsumers` is the witness, populated
  // by `liftOneRegisterMergePhi`): a module with no lift skips the re-sweep
  // entirely, so NO message-ownership churn on non-lift fixtures (opt exits at
  // the first DS_Error). The re-sweep is idempotent — `checkStaleOp` skips ops
  // already in `StaleDeclined`, so the first pass's diagnostics are neither
  // duplicated nor re-pointed; only newly-exposed ops are diagnosed (with the
  // accurate stale-record message — the lift proved the phi a pure renaming, so
  // the residual defect IS a stale record). Still BEFORE any rotation lowering
  // (pre-RAUW SSA identity).
  if (taint.LiftedConsumers.empty())
    return;  // no lift occurred — nothing to re-adjudicate.
  // ⚠ PURE OPS ONLY, and after bd test_C_libtooling-3d8q that is a positive
  // statement rather than an accident of scope: `declineStaleQuantumReaders` runs
  // BEFORE `declineClassicalMuxes`, hence before this lift, ON PURPOSE. A pure op
  // CAPTURES a basis record onto a FRESH rail, so which record it captures is a
  // fact about the NAME it reads and the lift's proof ("every incoming is one
  // register") says nothing about it — that is bd 2qyz, and it is why this
  // re-sweep exists. A `@cq_theta_*` / `@cq_measure_*` reader READS THE WIRE IN
  // PLACE: before the lift its name is the merge φ, which denotes the wire on
  // every edge ("the per-path record matches the wire per path" —
  // `lowering_classical_mux_phi_onereg_theta_chain.ll`,
  // `control_phase_kickback_rail_cross_block.ll`, both shipped Rule-13-cleared
  // ACCEPTS that flip if a reader sweep runs here). RESIDUAL, filed not hidden: a
  // quantum reader whose staling sibling is reachable ONLY through the lift's
  // RAUW is not caught — a MISS of the 3d8q class in one narrow shape, strictly
  // no worse than the pre-fix compiler, which asked NOTHING of any reader.
  declineStaleRecordOps(M, taint);
}

void recordStaleQuantumReaders(Module &M, TaintSet &taint,
                               const SmallPtrSetImpl<Value *> *Delta) {
  // THE LINEAR RULE FOR THE READER FAMILIES (bd test_C_libtooling-3d8q, P1 —
  // the project's one KNOWN pre-existing silent miscompile). PURE ANALYSIS:
  // this function diagnoses nothing and mutates no IR; it fills
  // `taint.StaleQuantumReaders`, which `declineRecordedStaleQuantumReaders`
  // drains at the late slot. `TaintSet::StaleQuantumReaders` carries the reason
  // for the split, in measurements.
  //
  // `docs/frontend.md` §3.2 states the rule and, since 2026-09-05, states this
  // exact hole in the same breath: *"the example above declines, but replacing
  // the arithmetic with a MEASUREMENT of the same stale name … is accepted …
  // `declineStaleRecordOps` covers tainted PURE OPS only … Do not rely on the
  // compiler to catch this spelling."* That paragraph is the specification of
  // this function. The rule is the LANGUAGE SEMANTICS; the enforcement was
  // incomplete, and the reader families are the incompleteness.
  //
  // MEASURED, one line of plain C, byte-identical on three shipped binaries:
  //   `int q=cq_theta(0,.3); int b=cq_theta(q,.5); int c=cq_theta(q,.9);
  //    return cq_measure(b)+cq_measure(c);`
  // emits `ry(.3); ry(.5); ry(.9); measure; measure` — BYTE-IDENTICAL to the
  // well-formed chain `a=cq_theta(q,.5); c=cq_theta(a,.9);
  // cq_measure(c)+cq_measure(c)`. Two different programs, one circuit, `opt`
  // exit 0, verify-clean, stage-2b `0 violation(s)`. Rule 2 in its purest form.
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Lazy — built only when a reader exists in `F`, and built TOGETHER because
    // `ScalarEvolution`'s constructor is cheap (it computes nothing until it is
    // queried) while its answers are what leg 1b of `readerStalesItself` needs
    // (bd 3d8q, Rule-13 round-2 finding F-D2-2). Declaration ORDER IS THE
    // DESTRUCTION CONTRACT: `SE` references `TLI`/`AC`/`DT`/`LI` and is declared
    // last, so it is destroyed first. Same direct-construction idiom as
    // `LoopLowering.cpp`'s (a default `TargetLibraryInfoImpl` is a conservative
    // TLI, which is what SCEV's range and trip-count reasoning needs here).
    std::optional<DominatorTree> DT;
    std::optional<LoopInfo> LI;
    std::optional<AssumptionCache> AC;
    std::optional<TargetLibraryInfoImpl> TLII;
    std::optional<TargetLibraryInfo> TLI;
    std::optional<ScalarEvolution> SE;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        Value *Rec = staleReaderRecordOperand(I, taint);
        if (!Rec)
          continue;
        // ── THE ROUND-2 HALF, and it is the L1 obligation paid in the ONE way
        //    that does not reopen the over-decline (bd 3d8q).
        //
        // With `Delta`, only readers whose RECORD OPERAND just became tainted are
        // analysed. Those are exactly the ones the round-1 pass could not see —
        // a `MergePhiPeel` mux out-rail, a 6.5/4.5 merge `%out` — and they are
        // values the pass itself MANUFACTURED or freshly re-seeded, never a name
        // some earlier rewrite collapsed. Re-asking the WHOLE module here instead
        // would decline 9 shipped in-loop ACCEPT fixtures, because `lowerLoops`'
        // rail-φ collapse has already replaced their per-trip barrier φ with the
        // loop-invariant preheader mint (`TaintSet::StaleQuantumReaders`).
        //
        // MEASURED CUSTOMER: `review_b6ap_r2_probes/S03_stale_mux_sibling.c` —
        // two sibling `cq_theta` on a peeled mux out-rail, both measured, which
        // ACCEPTED at 35 trace lines on the ORACLE *and* on the round-1-only
        // version of this fence, because `%m` is a φ over CONSTANTS and is
        // untainted until the peel manufactures its `select`.
        // ⚠ THE DELTA'S SOUNDNESS IS PARTLY CARRIED BY A DIFFERENT FENCE, and
        // that coupling is recorded rather than left as an inference (bd 3d8q,
        // Rule-13 round-1 item F-D1-5; L3 — "when a set is NARROWED, ask what
        // OTHER predicate names the same gate"). The full enumeration of what
        // round 2 can add to a reader's closure, and why only sub-case (c) —
        // a staling gate behind a `phi`/`select` ROUTING node — is a residual,
        // is in `TaintSet::StaleQuantumReaders`. (c) is closed by
        // `declineClassicalMuxes` refusing a live heterogeneous tainted mux and
        // by the one-register lift claiming the homogeneous one; if either
        // moves, this scope must be re-derived.
        if (Delta && !Delta->count(Rec))
          continue;
        if (!DT) {
          DT.emplace(F);
          LI.emplace(*DT);
          AC.emplace(F);
          TLII.emplace(Triple(M.getTargetTriple()));
          TLI.emplace(*TLII);
          SE.emplace(F, *TLI, *AC, *DT, *LI);
        }
        // (i) THE READER IS ITS OWN GATE, exempted with `Covered` — the shipped
        // per-entry exemption bit, NOT a boolean short-circuit (L4: "enumerate,
        // take the difference, and carry the exemption as a per-entry bit").
        // `c = cq_theta(a, .9)` is an in-place Ry on the very rail it reads, so
        // a walk seeded at `a` finds `c` among `a`'s users; without the
        // exemption EVERY well-formed chained rotation would decline against
        // itself. `Covered` skips it AS EVIDENCE while still walking THROUGH it,
        // so nothing behind the reader rides on the exemption — precisely the
        // property the boolean spelling lost (F-A1-1).
        // ⚠ ONLY for the rotation reader: a `@cq_measure_*` call is not a
        // `cq_theta_` gate, the walk can never return it, and calling it
        // "already ruled on" would be an untrue statement in the code.
        //
        // ⚠⚠ AND ONLY WHERE THE READER PROVABLY CANNOT STALE ITSELF ACROSS A
        // BACK EDGE (bd 3d8q, Rule-13 round-1 finding F-D1-1 — an OVER-ACCEPT
        // in the unforgivable class, found in this exemption).
        //
        // `Covered`'s contract is "a gate the CALLER has already ruled on", and
        // it is tested INSIDE the walker BEFORE the harmlessness proof. Granted
        // unconditionally, the one gate this fence never ruled on was the
        // reader's own PREVIOUS DYNAMIC INSTANCE: MEASURED, a loop body holding
        // exactly ONE `cq_theta` on a loop-INVARIANT quantum name —
        //   `int q=cq_theta(0,.3); for(i<3){ int b=cq_theta(q,.1);
        //    s+=cq_measure(b); }`
        // — compiled at `opt` exit 0 and emitted a stream BYTE-IDENTICAL to the
        // self-assigned chain `for(i<3){ q=cq_theta(q,.1); … }`, a DIFFERENT,
        // well-formed program. Two programs, one circuit: bd 3d8q's own
        // definition of the defect, surviving the fence built to close it.
        // At trip 2 the name `q` denotes `Ry(.3)|0>` while the register holds
        // `Ry(.4)|0>` — CLAUDE.md CORRECTNESS RISK §2's rail-staleness rule
        // verbatim ("no rail-relabelling gate executes between the record's
        // definition and the read WITHOUT that definition re-executing").
        //
        // So ASK — `WireWalk::readerStalesItself`, which owns exactly this
        // question and asks it with the walker's own shared implementations
        // (Rule 14 — never a second spelling). ⚠ It is NOT spelled
        // `gateIsHarmless(I, I, …)`: that relation's leg 1 is
        // `isPotentiallyReachable(T, EmitPoint)`, TRUE **by identity** in LLVM 19
        // when the two coincide, so every self-gate falls into leg 2 and a
        // non-wire-tracking φ seed is refused even where the reader provably runs
        // at most once — MEASURED on binary `33af6130`, that spelling declines 12
        // shipped Rule-13-cleared ACCEPT fixtures. See the definition for the
        // list. The three legs that matter, all measured:
        //   * straight-line chain / exclusive arms — `reachesWithoutBarrier`
        //     finds no path back, harmless, EXEMPT (the chain keeps accepting);
        //   * the φ-carried in-loop chain (`q = cq_theta(q,θ)`) — the header φ
        //     IS the barrier on every back-edge path, harmless, EXEMPT;
        //   * the loop-INVARIANT seed — `SeedDef` is outside the loop, the back
        //     edge reaches the reader again without crossing it, NOT harmless,
        //     exemption WITHHELD.
        // ⚠ WITHHOLDING IS THE WHOLE MECHANISM, and it must be done HERE rather
        // than by weakening `Covered` inside the walker (Track A.1 owns that
        // contract, and its other half — "walk THROUGH it" — is load-bearing).
        // With the reader absent from `Self`, the walk reaches it as an ordinary
        // candidate, asks this same predicate again, and RETURNS it as the
        // staler. That is why no new relation, and no new diagnostic, is needed.
        SmallPtrSet<const CallInst *, 1> Self;
        if (auto *CI = dyn_cast<CallInst>(&I))
          if (CI->getCalledFunction() &&
              CI->getCalledFunction()->getName().starts_with("cq_theta_") &&
              !readerStalesItself(CI, Rec, *DT, &*LI, &*SE, &taint))
            Self.insert(CI);
        // (ii) `RequireEmitDominance=false` — THE POLICY BIT (see `WireWalk.h`).
        // The pure-op policy keeps the conservative dominance PRECONDITION; this
        // policy asks the harmlessness proof itself, because the reader family
        // structurally cannot satisfy that precondition in two shapes that are
        // perfectly well formed:
        //   * a rotation reader that IS a branch arm — `%rt` in `armt` and `%rf`
        //     in `armf` are siblings on one rail that NEVER BOTH RUN, so neither
        //     can stale the other and neither dominates the other (leg 1;
        //     `control_inplace_ry_ifelse.ll` + 13 more, measured);
        //   * a measurement AFTER a loop whose body holds the arm gate — the
        //     merge φ re-establishes the record every trip, so the exit read is
        //     fresh, but the exit block dominates nothing in the body (leg 2's
        //     record-barrier walk; `control_inplace_ry_inloop_*`, 12 measured).
        if (findNonDiagonalWireGate(Rec, /*CrossValueRouting=*/true, &I, &*DT,
                                    &taint, Self.empty() ? nullptr : &Self,
                                    /*RequireEmitDominance=*/false))
          taint.StaleQuantumReaders.emplace_back(&I);
      }
    }
  }
}

void declineRecordedStaleQuantumReaders(Module &M, TaintSet &taint) {
  (void)M;
  // Drain the early analysis' record, in the program order it was taken in.
  //
  // ── THE THREE OUTCOMES, ENUMERATED, NONE SILENT (bd 3d8q, Rule-13 round-1
  //    finding F-D1-2 — Rule 1's "no third path", which this drain had).
  //
  // The record is a `WeakVH`, and the choice of handle IS the fix. Between the
  // two slots the pass RAUWs freely (`emitInPlaceRotationRegion`'s M-α/M-β,
  // `MergePhiPeel`, `liftOneRegisterMergePhi`, `SelectMergeEmit`), and LLVM 19's
  // two nullable handles differ on exactly that (`llvm/IR/ValueHandle.h`):
  // `WeakTrackingVH` *"tries hard to point to a Value, even across RAUW"*, while
  // `WeakVH` *"points to a value, and nulls itself out if that value is
  // deleted"*. The question this drain must answer is **"is the reader
  // INSTRUCTION still in the module?"**, never "what is its result now" — a
  // reader whose result was replaced is still an instruction that still reads a
  // stale name and still lowers to a gate. So:
  //
  //   (1) the handle is ALIVE and is an instruction in a block — the reader
  //       survived, RAUW'd or not. DECLINE, anchored on the reader itself, which
  //       is also the `!dbg` the early slot read (IMPL_D §7b).
  //   (2) the handle is NULL — the reader instruction was DESTROYED between the
  //       slots, which happens when a control emitter CLAIMED and PROVED the
  //       shape (the in-place-Ry arm's theta is hoisted away and replaced by
  //       `cqrt_ry_<W>_controlled`). There is nothing left to decline: skip.
  //       This is the handle's intended semantics, not a papered-over dangle.
  //   (3) the handle is ALIVE but is NOT an instruction in a block. Under the
  //       documented `WeakVH` semantics this is UNREACHABLE — a non-tracking
  //       handle to a `CallInst` cannot come to denote a `Constant` — and it is
  //       `report_fatal_error` rather than a `continue` precisely BECAUSE it is
  //       unreachable: the shipped spelling used the TRACKING handle, where a
  //       RAUW to a non-`Instruction` made `dyn_cast_or_null` return null and
  //       DROPPED a recorded decline with no diagnostic anywhere. That is the
  //       over-accept this outcome exists to make impossible. ⚠ Note the fix is
  //       correct under BOTH readings of `WeakVH`: if it did follow RAUW, this
  //       path becomes reachable and is LOUD instead of silent.
  //
  // `LLVMContext::diagnose` EXITS on the first `DS_Error` (bd `br4a`), so in
  // practice this emits exactly one diagnostic and never returns; the loop and
  // the `StaleDeclined` bookkeeping are written for the case where that ever
  // stops being true, not as live control flow.
  for (WeakVH &VH : taint.StaleQuantumReaders) {
    Value *V = VH;
    if (!V)
      continue;  // (2) destroyed — an owner claimed the shape.
    auto *I = dyn_cast<Instruction>(V);
    if (!I || !I->getParent())
      report_fatal_error(  // (3) never silent.
          "cq: internal — a recorded stale quantum reader survived as a "
          "non-instruction; refusing to lower (bd 3d8q F-D1-2)");
    if (taint.StaleDeclined.count(I))
      continue;
    diagnoseStaleQuantumReader(I);  // (1)
    taint.StaleDeclined.insert(I);
  }
}

void lowerOps(Module &M, WidthDispatch &wd, TaintSet &taint,
              bool inBennettClone) {
  // ── Phase 1: one program-order collection over all four classes ──
  // Gated by taint membership. Casts also capture (from,to) widths here,
  // before any rewrite corrupts the operand type (PRD §2.3).
  std::vector<Instruction *> Work;
  DenseMap<CastInst *, CastWidths> CastW;
  // bd test_C_libtooling-6uqc (M-C Inc 2a): the adds this walk decided to lower
  // IN PLACE. Decided HERE, in Phase 1, and for a measured reason — this is the
  // first point in the pipeline where the fence can see the truth.
  //
  // MEASURED, on the campaign's own customer (`slice_control_seq_grover`, IR
  // dumped immediately before this call). At `clang -O1` the parent of two of
  // its three candidate sites is a MERGE PHI of a tainted-condition diamond
  // (`%8 = phi i32 [ %6, %5 ], [ %3, %0 ]`), whose "later uses" cannot be read
  // off the CFG at all. By the time `lowerOps` runs, `detectControlRegions` +
  // `SwapRouteEmit` + `RegionFlatten` have linearized the whole function and
  // RAUW'd those phis away, so the same site reads as a flat
  // `%6 = add nsw i32 %5, %4` on a handle whose entire user list — the region
  // compare, its `_unc` strip, the two `cqrt_cswap`s, the `cqrt_free` — is
  // visible, positioned, and ALREADY TORN DOWN. The plan of record said "the
  // Phase-1 collection loop"; this is that loop, and it is also the earliest
  // slot where the answer is not a guess.
  //
  // Deciding in Phase 1 rather than Phase 2 also keeps the fence on PRE-rewrite
  // SSA: Phase 2's RAUWs replace values but preserve the use STRUCTURE (each
  // template is inserted at its original's position), so a "no use after" proof
  // taken here still holds when `rewriteInPlaceValueRail` reads the (by then
  // possibly RAUW'd) operand.
  SmallPtrSet<const Instruction *, 8> InPlaceReassign;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Built lazily, and ONLY when this function has an M-C candidate — the
    // overwhelming majority of functions never pay for them.
    std::optional<DominatorTree> MCDT;
    std::optional<LoopInfo> MCLI;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (!taint.Tainted.count(&I))
          continue;
        // Stale-record decline (test_C_libtooling-uzb): the diagnostic
        // already fired in `declineStaleRecordOps` (which ran before any
        // mutation); lower NOTHING for this op (emitting its template here
        // would put the wrong unitary in the stream — the template reads
        // the post-Ry basis while the SSA operand denotes the pre-Ry
        // record). Never enqueued ⇒ never rewritten ⇒ never erased.
        if (taint.StaleDeclined.count(&I))
          continue;
        if (isa<BinaryOperator>(&I) || isa<UnaryOperator>(&I)) {
          // (1b) THE PRE-LOOP COMMIT TRIPWIRE — bd 3qlq Inc 1, the THIRD C-1
          // review round, finding F-C1B-1. `LoopLowering`'s
          // `commitOutOfLoopInPlaceOps` runs at `lowerLoops`, i.e. BEFORE
          // `repropagateControlMerges` grows `taint.Tainted` and before the
          // round-2 flatten moves a block; the marking it writes is honoured
          // UNCONDITIONALLY twenty lines below (`InPlaceRailOps` skips M-C and
          // routes to `rewriteInPlaceValueRail`, which never re-asks the shape).
          // That is a PREDICTION consumed as a fact, and when it went stale the
          // emitted gate was `cqrt_addc_i32(%h4, %h_op)` — a quantum rail handle
          // in the ABI's classical-immediate slot, `opt` exit 0, verify-clean,
          // STRICT stage-2b clean, from four plain-C programs.
          //
          // Round 3 closes the measured half MONOTONELY at the commit
          // (`isa<Constant>(Imm)`), so this is the RESIDUAL net for every OTHER
          // input of the fence that a later stage could in principle move — a
          // taint change on the PARENT, a CFG change that puts the site in a
          // cycle, a use-list change that adds a read of the parent. Re-ask the
          // ONE fence, under the FINAL `DominatorTree`/`LoopInfo` this driver
          // builds and the FINAL taint, and DECLINE LOUDLY on a changed answer.
          //
          // NEVER A SILENT FALLBACK TO OUT-OF-PLACE, and that is the whole
          // reason it is a diagnostic (Rule 1 — no third path). The commit is
          // what licensed `markIfRailLocal` to mark the loop body, and that
          // permission is already in `taint.IterationLocalBlocks`; lowering this
          // one op out of place would leave the body marked on a premise that no
          // longer holds. Lowering NOTHING and exiting non-zero is the only
          // disposition that keeps the two consistent.
          //
          // ONLY the ops THIS path committed are re-asked
          // (`PreLoopCommittedInPlaceOps`, not `InPlaceRailOps`), because
          // re-asking M-C's WHOLE fence about the other three writers' ops would
          // put a second recognizer over G5's loop clause — a question those
          // writers deliberately answer differently, being in-loop by
          // construction. That is a statement about THIS FENCE BODY.
          //
          // ⚠ IT IS **NOT** A CLEAN BILL OF HEALTH FOR THE OTHER WRITERS, and
          // the sentence that used to stand here — "the other three writers mark
          // a rail they PROVED with their own fences" — was MEASURED FALSE as a
          // bound on this defect class (bd 3qlq Inc 1, round-3 lens finding
          // F-C1C-B; notes §3.12). Their fences prove the RAIL (a closed
          // self-cycle, its fan-out, its record reads); NOT ONE OF THEM PROVES
          // THE IMMEDIATE STAYS CLASSICAL, which is the input F-C1B-1 turned on.
          // Through `emitBreakForward` / `tryCaseA` / `collapseRailPhisIn` step
          // (3) the identical defect is reachable for BOTH stems from plain C —
          // `cqrt_xorc_i32(h1, 6)` where the bare `6` is a template rail's HANDLE
          // ID — and it is PRE-EXISTING (it reproduces on the pre-3qlq oracle
          // 52d7764 and on every binary of this epic), so it was out of THAT
          // round's scope but never out of the class. Filed as bd
          // `test_C_libtooling-eqpx` and **FIXED (2026-09-06) BY THE BLOCK
          // IMMEDIATELY BELOW**: the same shape with **G2 alone** re-asked for
          // every `InPlaceRailOps` member W4 did not commit (G2 alone because G5
          // would always refuse an in-loop site), declining loudly.
          if (auto *BO = dyn_cast<BinaryOperator>(&I);
              BO && !inBennettClone &&
              taint.PreLoopCommittedInPlaceOps.count(BO)) {
            if (!MCDT) {
              MCDT.emplace(F);
              MCLI.emplace(*MCDT);
            }
            if (!classifyInPlaceReassignment(BO, wd, taint, *MCDT, *MCLI,
                                             /*IgnoreSelfMarking=*/true)) {
              diagnosePreLoopCommitStale(BO);
              continue;  // never enqueued ⇒ never rewritten ⇒ never erased.
            }
          }
          // ── THE eqpx TRIPWIRE — bd test_C_libtooling-eqpx (P1), the SAME
          // once-only-stage class as (1b) above, through the OTHER THREE writers
          // of `taint.InPlaceRailOps`. PRE-EXISTING: it reproduces on the
          // pre-3qlq oracle 52d7764 and on every binary of the 3qlq epic.
          //
          // WHAT IT RE-ASKS: **G2 ALONE** — `inPlaceValueRailOperand(BO, taint)`,
          // the ONE exported spelling of the dtzb shape test every writer proved
          // with (`LoopLowering.cpp:143`; add/xor, <=64-bit integer, and EXACTLY
          // ONE tainted operand) — under the FINAL taint.
          //
          // WHY NOT THE WHOLE FENCE, i.e. why this is a SECOND predicate at this
          // site rather than (1b) widened: `inPlaceFenceHolds`' G5 second
          // disjunct (`ArithLowering.cpp:695-696`,
          // `LI.getLoopFor(Site->getParent()) || blockCanRepeat(...)`) is NOT
          // gated by `IgnoreSelfMarking` — only the `InPlaceRailOps` self-marking
          // disjunct is — and every W1/W2/W3 member is inside a loop BY
          // CONSTRUCTION. Re-asking the whole fence would decline 100% of them,
          // shipped ones included. G5 answers a question those writers
          // deliberately answer differently; G2 is the one they actually asked.
          //
          // FOR WHOM, by name — and the command is
          // `grep -n 'markInPlaceRailOp(' ir-pass/src/LoopLowering.cpp` (FOUR
          // callers, not three). ⚠ NOT `InPlaceRailOps.insert(`: since the four
          // writers were folded into the one `markInPlaceRailOp` helper that
          // grep returns a SINGLE site, inside the helper itself — the round-1
          // lens's finding F-E1-1, which is also why the numbers below are
          // written as "true at this edit" and the NAMES are the durable key:
          //   W1 `emitBreakForward`      `LoopLowering.cpp:1738` (7.4 break)
          //   W2 `tryCaseA`'s ACCEPT     `LoopLowering.cpp:2321` (round 1)
          //   W3 `collapseRailPhisIn`(3) `LoopLowering.cpp:2719` (round 2)
          //   W4 `commitOutOfLoopInPlaceOps` `:3124` — EXCLUDED here, it has its
          //      own stronger re-ask twenty lines above and being adjudicated by
          //      two different fences is how one op gets two answers.
          // Each of W1-W3 proves THE RAIL (a closed self-cycle, its fan-out, its
          // record reads). NOT ONE OF THEM PROVES THE IMMEDIATE STAYS CLASSICAL,
          // and W1's own immediate test (`:1586-1588`) is a DOMINANCE test for
          // the reverse-play, never a classicality test.
          //
          // WHAT MOVES THE ANSWER — TWO taint-growth events in the window, not
          // the one the bd issue names:
          //   E1 `lowerControlRegions` (`CQLoweringPass.cpp:376`) —
          //      `ClassicalCallArmEmit.cpp:209` / `SwitchDataMuxEmit.cpp:144` do
          //      `taint.Tainted.insert(Out)` AT EMISSION, so the BARE 6.5 / 4.5
          //      merge value is a quantum handle from that moment. AFTER W1/W2
          //      (`:363`), BEFORE W3/W4 (`:393`).
          //   E2 `repropagateControlMerges` (`:409`) — everything DERIVED from
          //      that `%out`.
          // The emitted defect was `cqrt_xorc_i32(%h2, %h_op)` — a quantum rail
          // handle in the ABI's classical-immediate slot, printed by the trace
          // runtime as a bare decimal handle id — at `opt` exit 0, verify-clean
          // and STRICT stage-2b `0 violation(s)`, from six lines of plain C; and
          // with the operands COMMUTED the same re-pick mutates the WRONG
          // REGISTER (`rewriteInPlaceValueRail`'s `TL = Tainted.count(L)`,
          // `ArithLowering.cpp:375`, answering about a value that changed class).
          //
          // NEVER A SILENT FALLBACK TO OUT-OF-PLACE (Rule 1 — no third path).
          // FOUR permissions the marking already bought are standing in the
          // module by now and cannot be withdrawn: `markIfRailLocal`'s
          // `taint.IterationLocalBlocks`, the IRREVERSIBLY COLLAPSED rail phi,
          // `taint.ClaimedRailRoots`, and — for W1 — the whole forward break
          // transform plus the post-`lowerOps` `lowerBreakReversePlay` stage that
          // re-emits this op's adjoint. Lowering this one op into a fresh
          // per-iteration rail leaves every one of them on a premise that no
          // longer holds: the X1 cross-iteration dirty rail the marking exists to
          // prevent. Lowering NOTHING and exiting non-zero is the only
          // disposition that keeps them consistent.
          //
          // THE 8h7d.5 QUESTION — "when you widen a set, ask what OTHER set was
          // computed over the same closure". `taint.InPlaceRailOps` is read by
          // `railValueConsumerDisposition` (`LoopLowering.cpp`, by NAME), whose
          // `InPlace` cell feeds the Rule-8 fan-out guard and `collectRailGates`'
          // forward extension. This widening is DECLINE-ONLY: it never REMOVES a
          // member, so that cell is byte-unchanged for every module that still
          // lowers. A silent removal would make `collectRailGates` stop following
          // the op and judge a rail record read past it FRESH when it is STALE —
          // reopening 8h7d.5 F-1. That is a second, independent reason the
          // disposition must be a decline.
          //
          // NOT GATED ON `!inBennettClone`, unlike (1b) above: the Phase-2
          // dispatch (`taint.InPlaceRailOps.count(BO) || InPlaceReassign.count(BO)`)
          // honours the marking UNCONDITIONALLY, so gating here would leave a hole
          // exactly where the dispatch has none. It is INERT either way —
          // `seedClone` builds a FRESH `TaintSet` (`SpecializeSeed.h`) and clones
          // are built long after `lowerLoops`, so no clone instruction can be in
          // `taint.InPlaceRailOps` — and that inertness was MEASURED (the whole
          // fixture corpus and all 43 eqpx reproducers move only the members).
          if (auto *BO = dyn_cast<BinaryOperator>(&I);
              BO && taint.InPlaceRailOps.count(BO) &&
              !taint.PreLoopCommittedInPlaceOps.count(BO)) {
            Value *Rail = inPlaceValueRailOperand(BO, taint);
            // The INDEX half (`taint.InPlaceRailIdx`): the writer recorded WHICH
            // operand it proved was the rail, so the emitter can CONSUME that
            // answer instead of re-deriving it a third time from a `Tainted` that
            // Phase 2's `promote()` mutates as Phase 2 runs. Here we check the
            // two answers still AGREE; `rewriteInPlaceValueRail` consumes the
            // recorded index. An index, never a `Value *` — a pointer keyed at
            // one stage and read at another is the bd drbq Inc-1 dangling defect,
            // and RAUW replaces operands in place without reordering them.
            auto It = taint.InPlaceRailIdx.find(BO);
            bool IdxDisagrees = It != taint.InPlaceRailIdx.end() &&
                                BO->getOperand(It->second) != Rail;
            if (!Rail || IdxDisagrees) {
              diagnoseRailOpStale(BO);
              continue;  // never enqueued ⇒ never rewritten ⇒ never erased.
            }
          }
          // M-C (bd 6uqc Inc 2a): decide the in-place reassignment here, on
          // pre-rewrite SSA. NEVER a decline — `classifyInPlaceReassignment`
          // returning false just means this op keeps today's out-of-place
          // lowering (Rule 17: the decline belongs to inputs outside the target
          // shape, and `q + c` out of place is a shape we lower correctly).
          if (auto *BO = dyn_cast<BinaryOperator>(&I);
              BO && !inBennettClone && !taint.InPlaceRailOps.count(BO)) {
            if (!MCDT) {
              MCDT.emplace(F);
              MCLI.emplace(*MCDT);
            }
            if (classifyInPlaceReassignment(BO, wd, taint, *MCDT, *MCLI))
              InPlaceReassign.insert(BO);
          }
          Work.push_back(&I);
        } else if (auto *Cmp = dyn_cast<CmpInst>(&I)) {
          // A branch/select-feeding compare is Phase 4's — never enqueue
          // it (so it is never rewritten or erased). Data-position compares
          // are enqueued and lowered by CompareLowering::rewriteCompare.
          if (isDataPositionCompare(Cmp))
            Work.push_back(&I);
        } else if (auto *Cast = dyn_cast<CastInst>(&I)) {
          // Capture widths NOW, before any sibling Phase-2 rewrite RAUWs the
          // operand and makes `getSrcTy()` read the i32 handle (risk R1).
          // `rewriteCast` consumes exactly this captured pair — never the live
          // operand type. This up-front capture is what makes the measured-
          // compare zext bridge emit `cq_template_zext_i1_to_i32` not garbage.
          StringRef FromW = abiWidthFromType(Cast->getSrcTy());
          // BUT a cast directly off a tainted THETA handle is already
          // laundered: RotationLowering (which runs BEFORE lowerOps) RAUW'd the
          // possibly-non-i32 theta result to its i32 handle, so `getSrcTy()`
          // here reads the laundered i32, not the logical source width. Recover
          // it from HandleWidth — the same Increment-A side-table the Q+Q
          // compare path reads, recorded at the theta mint (RotationLowering)
          // and on every arith/cast handle output. For a sibling Phase-2 source
          // (a compare/arith/cast result not yet rewritten at this point)
          // `getSrcTy()` still reads the correct pre-rewrite type and the
          // lookup is empty, so the recovery is inert. That inertness is
          // LOAD-BEARING and rests on an ordering invariant: every Arith/Cast/
          // Compare HandleWidth write happens in Phase 2 (promote(), after
          // RAUW), strictly AFTER this whole Phase-1 capture loop — so no
          // sibling result is in HandleWidth yet here. (Even if one were, its
          // recorded width equals its own result width == this cast's
          // getSrcTy(), so an override would coincide, never give a wrong
          // width.) Only RotationLowering, which runs BEFORE lowerOps,
          // pre-populates HandleWidth for a theta handle — exactly the laundered
          // case this recovery fixes. Without it, a cast off a non-i32 tainted
          // source — `fpext f16->f32`, `sext i8->i32`, `fptosi f16->i32`, ... —
          // captured "i32" and declined (the f16 cast surface, and the latent
          // non-i32-source-cast gap, were unreachable).
          if (StringRef R = taint.HandleWidth.lookup(Cast->getOperand(0));
              !R.empty())
            FromW = R;
          CastW[Cast] = {FromW, abiWidthFromType(Cast->getDestTy())};
          Work.push_back(&I);
        } else if (auto *CI = dyn_cast<CallInst>(&I);
                   CI && isCuratedReversibleIntrinsic(CI)) {
          // A curated reversible llvm.* idiom / hardware fp-math intrinsic
          // (recognized by exact Intrinsic::ID + table width + the fshl/fshr
          // constant-amount guard — rotation or general two-operand funnel).
          // Lowered by IntrinsicLowering to a cq_template_<op>_<W>
          // additive producer in Phase 2. p119: a LIBRARY function
          // (transcendental / direct-libm call) is NOT lowerable by recognition —
          // it must be source-injected; a NON-curated tainted call already
          // declined loudly at declineTaintEscapes (kMsgUnknownCallee), so it is
          // not in the lowerable shapes here.
          Work.push_back(&I);
        }
      }
    }
  }

  if (Work.empty())
    return;

  // ── Phase 2: rewrite in program order, dispatch by dyn_cast ──
  // Each rewriter does emit + RAUW + taint/BirthOrder bookkeeping and
  // returns true iff it rewrote the op (and the driver may erase it).
  // false ⇒ diagnosed/inert/left un-lowered ⇒ MUST NOT be erased.
  std::vector<Instruction *> ToErase;
  for (Instruction *I : Work) {
    bool Rewritten = false;
    if (auto *BO = dyn_cast<BinaryOperator>(I)) {
      // Issue dtzb: a `lowerLoops`-marked loop-rail self-update lowers to the
      // IN-PLACE `cqrt_{addc,xorc}` (one rail handle), NOT the out-of-place data
      // template (which mints a fresh per-iteration rail — the X1 dirty rail).
      // Two INDEPENDENT routes to the same in-place emitter, deliberately kept
      // as two sets: `InPlaceRailOps` is `lowerLoops`' proven loop-carried rail
      // self-update (dtzb), `InPlaceReassign` is the M-C straight-line
      // reassignment decided in Phase 1 above (bd 6uqc Inc 2a). They are
      // disjoint by construction — the M-C fence refuses anything already in
      // `InPlaceRailOps` and anything inside a natural loop — so neither
      // recognizer can silently widen the other.
      Rewritten = (taint.InPlaceRailOps.count(BO) || InPlaceReassign.count(BO))
                      ? rewriteInPlaceValueRail(BO, wd, taint)
                      : rewriteBinary(BO, wd, taint);
    } else if (auto *UO = dyn_cast<UnaryOperator>(I)) {
      Rewritten = rewriteUnary(UO, wd, taint);
    } else if (auto *Cmp = dyn_cast<CmpInst>(I)) {
      Rewritten = rewriteCompare(Cmp, wd, taint);
    } else if (auto *Cast = dyn_cast<CastInst>(I)) {
      Rewritten = rewriteCast(Cast, CastW[Cast], wd, taint);
    } else if (auto *CI = dyn_cast<CallInst>(I);
               CI && isCuratedReversibleIntrinsic(CI)) {
      // Only curated intrinsics are enqueued as calls (the predicate is the SAME
      // at enqueue and here — no drift). p119: library functions are not lowered
      // by recognition (removed) — they are source-injected or decline.
      Rewritten = rewriteIntrinsic(CI, wd, taint);
    }
    if (Rewritten)
      ToErase.push_back(I);
  }

  // ── Phase 3: erase only the rewritten originals ──
  for (Instruction *I : ToErase)
    I->eraseFromParent();
}

}  // namespace cq
