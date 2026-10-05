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
#include "QramLowering.h"     // qramAccessReads — a QRAM access's reads (bd r2j3.2)
#include "RailBankPromote.h"  // railBankParkedRails — the memory hop (review F-1)
#include "TaintPropagation.h"
#include "WidthDispatch.h"
#include "WireWalk.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/AssumptionCache.h"   // leg 1b's SCEV (bd 3d8q F-D2-2)
#include "llvm/Analysis/CFG.h"  // isPotentiallyReachable (bd 3d8q mutual-exclusion leg)
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"    // gateFollowsRead (bd r2j3.2 F1)
#include "llvm/Analysis/ScalarEvolution.h"   // leg 1b (bd 3d8q F-D2-2)
#include "llvm/Analysis/TargetLibraryInfo.h" // leg 1b's SCEV (bd 3d8q F-D2-2)
#include "llvm/TargetParser/Triple.h"        // leg 1b's SCEV (bd 3d8q F-D2-2)
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/ErrorHandling.h"  // report_fatal_error (bd 3d8q F-D1-2, outcome 3)
#include "llvm/Support/raw_ostream.h"    // CQ_STALEBANK_DBG (the memory hop)
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
// plain C — `int b=q; cq_theta(&b,.5); int c=q; cq_theta(&c,.9); return
// cq_measure(b)+cq_measure(c);` — lowered to a stream BYTE-IDENTICAL to the
// well-formed chain `a=q; cq_theta(&a,.5); c=a; cq_theta(&c,.9); cq_measure(c)+cq_measure(c)`:
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

// Per-read stale-record check (shared by the straight-line guard and the
// post-lift re-check, Rule 14). `I` reads each tainted value in `Reads` AT ITS
// OWN POSITION: walk that value's forward in-place-gate wire; if it gains a
// non-diagonal gate not provably after `I`, fire the loud diagnostic, record `I`
// in `StaleDeclined` (so `lowerOps` lowers nothing for it), and return true. `DT`
// must be the dominator tree of `I`'s function. A pure op reads its operands
// (`checkStaleOp`); a QRAM access reads its index register and stored value
// (`qramAccessReads`, bd test_C_libtooling-r2j3.2) — one policy, one diagnostic.
//
// THE GATE SET, NOT THE FIRST GATE (bd r2j3.2 review round 1, F1; L3). The walk's
// position-aware proof keeps the CONSERVATIVE precondition `I` dominates `T`
// (`RequireEmitDominance`, WireWalk.h), so a read in a branch arm declined against
// a gate after the merge — `if (k) v = tbl[q]; cq_theta(&q, .3);` — though every
// trace runs the read first. A gate that fails only that precondition is still
// harmless when `gateFollowsRead`; every collected gate must pass it.
//
// ⚠ ONLY FOR A READ THAT RUNS WHERE IT STANDS (review round 2, F1: a wrong unitary
// on d6ffaca3). A value arm's pure chain inside a TAINTED arm is hoisted into the
// pred, where it runs UNCONDITIONALLY, and the guarded-store region never
// discharges it: `if (c > 2) arr[j] = (int)(q ^ 6); cq_theta(&q, .3);` left
// `trunc(q)` a live copy of q on every branch across the Ry (rc 0). So a read under
// tainted control (`instUnderTaintedControl`, the carve's own predicate) keeps the
// dominance precondition unless `InPlace`: a QRAM access, which its emitter issues
// at the access under control with nothing hoisted
// (lowering_reject_stale_record_tainted_arm_hoisted_chain.ll pins the pure op).
bool gateFollowsRead(const Instruction &I, const CallInst *T,
                     const DominatorTree &DT, const PostDominatorTree &PDT);

// ── THE PER-USE LIFT COVERAGE (bd test_C_libtooling-r2j3.11 + -dm7f.1) ──────────
//
// After `liftOneRegisterMergePhi` RAUWs a phi onto its wire base, a read of the
// phi and a read of the base are the same operand, so the re-sweep seeded at the
// base sees the phi's OWN incoming gates as siblings (dm7f.1: `if (c)
// cq_theta(&q,.125); v = q + 3;` declined) — and a union of every lift's gates
// would accept a stale read of a SECOND phi over the same base (`int r = q; if (c)
// { cq_theta(&q,.125); r = q; cq_theta(&q,.25); } v = r + 3;`, measured: the
// `add` read the post-`.25` wire). The lift therefore records its USES
// (`TaintSet::LiftedMergePhi`), and a read is exempted from exactly the gates on
// the record it read:
//   * the read's own slot is a recorded use of lift L — L's `RecordGates`;
//   * the operand is an in-place gate chain whose ancestry passes a recorded use
//     (`%t = cq_theta(phi, ·)`, then `v = %t + 3`) — the same, since `%t`'s record
//     extends the phi's. The hop is the walker's own backward closure: a
//     `cq_theta_` call whose arg 0 is tainted (the relation `lowerRotations`
//     builds the rail from), or a `cq_phi_` call.
// A use only counts while its slot still holds the lift's base: a later rebuild
// that renumbered or re-pointed it drops out, which can only decline.
struct LiftCoverage {
  const TaintSet *Taint = nullptr;
  DenseMap<std::pair<const Value *, unsigned>, SmallVector<unsigned, 1>> UseToLift;

  explicit LiftCoverage(TaintSet &T) : Taint(&T) {
    for (unsigned L = 0, E = T.LiftedMergePhis.size(); L != E; ++L) {
      const TaintSet::LiftedMergePhi &Rec = T.LiftedMergePhis[L];
      const Value *Base = Rec.Base;
      if (!Base)
        continue;
      for (const TaintSet::LiftedUse &U : Rec.Uses) {
        auto *UI = dyn_cast_or_null<User>(static_cast<Value *>(U.User));
        if (!UI || U.OpNo >= UI->getNumOperands() ||
            UI->getOperand(U.OpNo) != Base)
          continue;
        UseToLift[{UI, U.OpNo}].push_back(L);
      }
    }
  }

  // The lifts whose record the read in slot `OpNo` of `I` denotes; false when the
  // read is not a lifted read at all.
  bool liftsOf(const Instruction &I, unsigned OpNo,
               SmallVectorImpl<unsigned> &Lifts) const {
    auto Add = [&](const Value *U, unsigned Slot) {
      auto It = UseToLift.find({U, Slot});
      if (It != UseToLift.end())
        Lifts.append(It->second.begin(), It->second.end());
    };
    Add(&I, OpNo);
    SmallPtrSet<const Value *, 8> Seen;
    for (const Value *V = I.getOperand(OpNo); V && Seen.insert(V).second;) {
      const auto *CI = dyn_cast<CallInst>(V);
      const Function *F = CI ? CI->getCalledFunction() : nullptr;
      if (!F || CI->arg_size() < 1)
        break;
      const Value *A0 = CI->getArgOperand(0);
      const bool Hop = F->getName().starts_with("cq_phi_") ||
                       (F->getName().starts_with("cq_theta_") &&
                        Taint->Tainted.count(const_cast<Value *>(A0)));
      if (!Hop)
        break;
      Add(CI, 0);
      V = A0;
    }
    return !Lifts.empty();
  }

  // The gates the read in slot `OpNo` of `I` is exempt from (see above).
  bool coveredFor(const Instruction &I, unsigned OpNo,
                  SmallPtrSetImpl<const CallInst *> &Cov) const {
    SmallVector<unsigned, 2> Lifts;
    if (!liftsOf(I, OpNo, Lifts))
      return false;
    for (unsigned L : Lifts)
      for (const WeakVH &G : Taint->LiftedMergePhis[L].RecordGates)
        if (auto *GC = dyn_cast_or_null<CallInst>(static_cast<Value *>(G)))
          Cov.insert(GC);
    return true;
  }

  // Every slot of `I` that holds `Op` must be a lifted read, and a gate is exempt
  // only if EVERY such slot's record contains it: `add %p, %q` after the RAUW is
  // `add %q, %q`, and the base slot's record is not the phi's.
  bool coveredForValue(const Instruction &I, const Value *Op,
                       SmallPtrSetImpl<const CallInst *> &Cov) const {
    bool First = true;
    for (unsigned S = 0, E = I.getNumOperands(); S != E; ++S) {
      if (I.getOperand(S) != Op)
        continue;
      SmallPtrSet<const CallInst *, 8> Mine;
      if (!coveredFor(I, S, Mine)) {
        Cov.clear();
        return false;
      }
      if (First) {
        Cov.insert(Mine.begin(), Mine.end());
        First = false;
        continue;
      }
      SmallVector<const CallInst *, 8> Drop;
      for (const CallInst *G : Cov)
        if (!Mine.count(G))
          Drop.push_back(G);
      for (const CallInst *G : Drop)
        Cov.erase(G);
    }
    return !First;
  }

  // Record `I` as a covered reader of every lift its slots read, for the late
  // live-record warning (`TaintSet::LiftedMergePhi::Readers`).
  void noteReader(Instruction &I, TaintSet &T) const {
    SmallVector<unsigned, 2> Lifts;
    for (unsigned S = 0, E = I.getNumOperands(); S != E; ++S)
      liftsOf(I, S, Lifts);
    for (unsigned L : Lifts)
      T.LiftedMergePhis[L].Readers.emplace_back(&I);
  }
};

bool checkStaleReads(Instruction &I, ArrayRef<Value *> Reads, TaintSet &taint,
                     DominatorTree &DT, std::optional<PostDominatorTree> &PDT,
                     bool InPlace, const LiftCoverage *LC = nullptr) {
  if (taint.StaleDeclined.count(&I))
    return false;  // already declined — idempotent across the post-lift re-sweep.
  bool Lifted = false;
  for (Value *Op : Reads) {
    if (!taint.Tainted.count(Op))
      continue;  // classical operand — no wire.
    SmallVector<CallInst *, 4> Gates;
    collectNonDiagonalWireGates(Op, /*CrossValueRouting=*/true, &I, &DT, &taint,
                                Gates);
    // bd r2j3.11 / dm7f.1 — the post-lift re-sweep drops the gates ON the record
    // this read denotes. A dropped gate that is not provably after the read was
    // walked THROUGH by the enumeration (it is pushed like any staler), so a gate
    // behind it is still here: the exemption is of the gate, not of what follows.
    SmallPtrSet<const CallInst *, 8> Cov;
    if (LC && LC->coveredForValue(I, Op, Cov)) {
      Lifted = true;
      llvm::erase_if(Gates, [&](CallInst *G) { return Cov.count(G) != 0; });
    }
    if (Gates.empty())
      continue;
    if (!PDT)
      PDT.emplace(*I.getFunction());
    if ((InPlace || !instUnderTaintedControl(&I, taint, DT)) &&
        llvm::all_of(Gates, [&](const CallInst *T) {
          return gateFollowsRead(I, T, DT, *PDT);
        }))
      continue;
    diagnoseStaleRecord(&I);
    taint.StaleDeclined.insert(&I);
    return true;  // one diagnostic per op; lowerOps will skip it.
  }
  if (Lifted)
    LC->noteReader(I, taint);
  return false;
}

// `T` runs after `I` on every trace that runs both, and the two are never
// alternatives of one branch. Leg 1 of the walk's proof, `!isPotentiallyReachable
// (T, I)` (conservative toward "reachable", so exact in this direction), means no
// path runs `T` and then `I`. The precondition it replaces also excluded paths that
// reach `T` without `I`. `T` post-dominating `I` keeps the part of that which
// flattening can break: `I` and `T` in SIBLING arms of a tainted branch, which a
// control emitter runs in sequence. Every path from `I` passes `T`, so `T` is after
// the merge or later in `I`'s own arm, and a claimed region is emitted inside its
// own span with each arm in program order. ORDER IS NOT THE WHOLE STORY: a hoisted
// read also becomes UNCONDITIONAL, which is why the caller withholds this for a
// read under tainted control (above). Sibling arms keep declining, classical or
// tainted (lowering_reject_stale_record_exclusive_arms.ll,
// lowering_reject_stale_record_tainted_sibling_arms.ll). Leg 2 (a back edge
// refreshing the record) is not widened: a `T` that can reach `I` still needs `I`
// to dominate it.
bool gateFollowsRead(const Instruction &I, const CallInst *T,
                     const DominatorTree &DT, const PostDominatorTree &PDT) {
  return PDT.dominates(T, &I) &&
         !isPotentiallyReachable(T, &I, /*ExclusionSet=*/nullptr, &DT);
}

bool checkStaleOp(Instruction &I, TaintSet &taint, DominatorTree &DT,
                  std::optional<PostDominatorTree> &PDT,
                  const LiftCoverage *LC) {
  SmallVector<Value *, 4> Ops(I.operand_values());
  return checkStaleReads(I, Ops, taint, DT, PDT, /*InPlace=*/false, LC);
}

void declineStaleRecordOpsImpl(Module &M, TaintSet &taint,
                               const LiftCoverage *LC);

}  // namespace

void declineStaleRecordOps(Module &M, TaintSet &taint) {
  declineStaleRecordOpsImpl(M, taint, /*LC=*/nullptr);
}

namespace {

void declineStaleRecordOpsImpl(Module &M, TaintSet &taint,
                               const LiftCoverage *LC) {
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
  // Diagonal gates (Rz) on the wire are basis-preserving and never trigger
  // (bd memory rz-diag-flag-strip-invariant; fixture
  // lowering_stale_record_add_after_phi.ll). A pre-3qlq register-form diagonal
  // ALIAS (`%qd = cq_phi(%q, ·)`) shared `%q`'s physical wire, so a chained
  // theta consuming the SIBLING name `%q` staled it too — the wire walk closes
  // every seed backward through such arg-0 hops before walking forward
  // (test_C_libtooling-6j1). That alias no longer occurs: the 3qlq migration
  // removed it from the fixtures written for it, `..._alias_chain.ll` was
  // deleted at ae840fac as an IR duplicate of
  // lowering_reject_stale_record_alias_sibling.ll, and the three survivors
  // carried no diagonal hop. bd jttf (2026-10-05) retired two of them as
  // duplicates: `..._reject_..._alias_sibling.ll` (decline) still reads `%q`
  // after a chained theta on it; its accept twin is now
  // lowering_stale_record_add_before_theta.ll, and the no-chained-theta
  // producer case is lowering_stale_record_add_after_phi.ll.
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
  //   4. `declineLiftedStaleRecordOps`, after the one-register merge-phi lift
  //      (since bd d88e, after `specialize()` and the lift's re-ask).
  // So "can a value become a stale reader only in ROUND 2?" — yes (a 6.5/4.5
  // merge `%out` rail is untainted at round 1), and slot 3 is what asks about it:
  // the widening rides the SAME re-run the pure-op policy already rides, because
  // it is one operand policy inside one function rather than a new stage with a
  // premise of its own. A NEW SWEEP SITE would have owed the L1 question; this
  // does not, and that is the reason it was built this way.
  //
  // ── THE QRAM ACCESS (bd test_C_libtooling-r2j3.2, P1 silent miscompile) ────
  // A QRAM call reads its index register (and a store its value) AT THE ACCESS,
  // so it is asked the pure-op question about exactly those registers
  // (`qramAccessReads`, owned by QramLowering). `long q2 = q; cq_theta(&q2, .3);
  // v = tbl[q];` used to lower to `qram_load(arr, q)` after the Ry: a bare index
  // has no op between the gep and the register, and the `int` twin declined only
  // because its widening `sext` happened to be scheduled after the gate. All four
  // slots above see the pre-emission `load`/`store`, except the post-lift re-sweep,
  // which runs after both emitters and sees the emitted call — and needs to, since
  // the lift is what turns a φ index into its wire base.
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Built lazily — only when a tainted in-scope op exists in `F` (the
    // post-dominator tree only when a gate fails the dominance precondition).
    std::optional<DominatorTree> DT;
    std::optional<PostDominatorTree> PDT;
    SmallVector<Value *, 4> QramReads;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        QramReads.clear();
        const bool PureOp = inLowerOpsScope(I, taint);
        if (!PureOp && !qramAccessReads(I, taint, QramReads))
          continue;
        if (!DT)
          DT.emplace(F);  // either form always has a tainted read.
        if (PureOp)
          checkStaleOp(I, taint, *DT, PDT, LC);
        else
          checkStaleReads(I, QramReads, taint, *DT, PDT, /*InPlace=*/true, LC);
      }
    }
  }
}

void recordStaleQuantumReadersImpl(Module &M, TaintSet &taint,
                                   const SmallPtrSetImpl<Value *> *Delta,
                                   const LiftCoverage *LC);

}  // namespace

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
  // in-place-gate hops (a chained `cq_theta`/Ry; pre-3qlq a register `cq_phi`/Rz —
  // wire-sharing users that are not themselves `lowerOps` ops) downstream
  // of the lifted phi, so the genuine stale op is a TRANSITIVE user the direct
  // re-check never visits — a residual silent miscompile. Re-running the
  // COMPLETE `declineStaleRecordOps` on the post-lift IR adjudicates every
  // exposed op: the phi is now the base SSA value, so the (unchanged) WireWalk
  // closure walks each consumer's wire all the way to the origin and finds the
  // sibling regardless of how many hops away the consumer sits (Rule 14 — reuse
  // the exact analysis, add no parallel wire-walk).
  //
  // Gated on a lift having occurred: a module with no lift skips the re-sweep
  // entirely, so NO message-ownership churn on non-lift fixtures (opt exits at
  // the first DS_Error).
  // ⚠ THE WITNESS IS THE LIFT **EVENT**, `taint.LiftedMergePhis` (bd
  // test_C_libtooling-ec7r, Rule-13 delta round r2 F-R2-1). It used to be the
  // lift's direct consumers (`LiftedConsumers`), and that broke in the
  // COMPOSITION of two correct changes: bd 8e5r made the set self-cleaning
  // (`empty()` = "no LIVE consumer"), and bd d88e moved this re-sweep AFTER
  // `specialize()`, whose `retargetSite` REBUILDS an fp-return spec call and
  // ERASES the old one — so when that call was the lift's only consumer the set
  // emptied, the re-sweep was SKIPPED, and a module every pre-merge binary
  // declined was accepted (`lowering_reject_lift_resweep_spec_rebuilt_consumer.ll`).
  // The question this sweep asks is module-wide and does not depend on any
  // consumer still being alive, so the gate must not either. `LiftedMergePhis`
  // gets one record per accepted lift and is never shrunk (its handles may null;
  // its LENGTH cannot), and every lifted phi has >= 1 Instruction user
  // (`declineClassicalMuxes` skips `use_empty()` phis), so this is exactly the
  // fact the pre-merge raw consumer set encoded. The re-sweep is idempotent — `checkStaleOp` skips ops
  // already in `StaleDeclined`, so the first pass's diagnostics are neither
  // duplicated nor re-pointed; only newly-exposed ops are diagnosed (with the
  // accurate stale-record message — the lift proved the phi a pure renaming, so
  // the residual defect IS a stale record). Still BEFORE any rotation lowering
  // (pre-RAUW SSA identity).
  // ⚠ CORRECTED (L7): the note that stood here argued a self-cleaning consumer
  // set was equivalent because "nothing erases between `declineClassicalMuxes`
  // and this re-sweep". FALSE since the d88e merge — `specialize()` is in that
  // window and erases rebuilt spec calls. Written after the merge, measured on
  // the pre-merge binary: the bd 8e5r lesson that a claim about a WINDOW must be
  // re-asked whenever a stage moves into it.
  if (taint.LiftedMergePhis.empty())
    return;  // no lift occurred — nothing to re-adjudicate.
  // ── PER USE (bd test_C_libtooling-dm7f.1 + -r2j3.11). A read the lift
  // recorded as a read of the phi is exempt from the gates ON the phi's per-path
  // record (`LiftCoverage`), and from nothing else: the arm's own `cq_theta` is
  // part of what `if (c) cq_theta(&q,.125); v = q + 3;` reads, while a second phi
  // over the same base contributes its gates to its OWN readers only.
  LiftCoverage LC(taint);
  declineStaleRecordOpsImpl(M, taint, &LC);
  // ⚠ THE READER FAMILIES ARE NOW RE-ASKED HERE TOO, and ONLY for a lifted read.
  // This used to say "PURE OPS ONLY": a `@cq_theta_*` / `@cq_measure_*` reader
  // reads the wire in place, and before the lift its name is the merge φ, which
  // denotes the wire on every edge — so a plain re-sweep would flip the shipped
  // ACCEPTS `lowering_classical_mux_phi_onereg_theta_chain.ll` and
  // `control_phase_kickback_rail_cross_block.ll`. That argument is true of the
  // phi's OWN incoming gates and false of a gate on another name over the same
  // base, and the residual it left was a silent miscompile (bd r2j3.11): `int r =
  // q; if (c) { cq_theta(&q,.125); r = q; cq_theta(&q,.25); } cq_measure(r)`
  // measured the post-`.25` wire, byte-identical to measuring `q` twice. With the
  // per-use record the two shipped accepts keep their exemption (their gates ARE
  // the phi's record) and that sibling is evidence. The scope is the lifted reads
  // alone: every other reader keeps the verdict the early slot gave it on IR the
  // loop-rail collapse had not yet rewritten (`TaintSet::StaleQuantumReaders`).
  recordStaleQuantumReadersImpl(M, taint, /*Delta=*/nullptr, &LC);
}

void recordStaleQuantumReaders(Module &M, TaintSet &taint,
                               const SmallPtrSetImpl<Value *> *Delta) {
  recordStaleQuantumReadersImpl(M, taint, Delta, /*LC=*/nullptr);
}

namespace {

void recordStaleQuantumReadersImpl(Module &M, TaintSet &taint,
                                   const SmallPtrSetImpl<Value *> *Delta,
                                   const LiftCoverage *LC) {
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
  //   `int q=0; cq_theta(&q,.3); int b=q; cq_theta(&b,.5); int c=q; cq_theta(&c,.9);
  //    return cq_measure(b)+cq_measure(c);`
  // emits `ry(.3); ry(.5); ry(.9); measure; measure` — BYTE-IDENTICAL to the
  // well-formed chain `a=q; cq_theta(&a,.5); c=a; cq_theta(&c,.9);
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
        // bd r2j3.11 — the post-lift pass (`LC`) asks ONLY a lifted read, and
        // exempts it from the gates on the record it read (`LiftCoverage`).
        SmallPtrSet<const CallInst *, 8> LiftCov;
        if (LC && !LC->coveredFor(I, /*OpNo=*/0, LiftCov))
          continue;
        // ── THE MEMORY HOP (bd `xdu2` W1, Rule-13 review F-1, 2026-09-15 —
        //    a P1 OVER-ACCEPT: THE RAIL BANK LAUNDERED bd `3d8q` THROUGH MEMORY).
        //
        // Everything below this line walks an SSA WIRE. A rail bank parks a
        // rail's NAME IN A MEMORY CELL, so when `Rec` is a cell `load` the
        // walker is handed a value with no wire: it finds no gate, the reader is
        // never adjudicated, and a `cq_measure` of a name a later non-diagonal
        // gate has relabelled COMPILES SILENTLY. MEASURED on the reviewed binary
        // `784c14fa` (`bfix/probes/f01`): exit 0, stderr EMPTY, STRICT 2b
        // `0 violation(s)`, a plausible 7-line trace — emitting
        // `ry(.5); ry(.7); measure x4`, so three bank measures observe the
        // register AFTER a rotation the source places AFTER them. The REGISTER
        // SPELLING of the same program (`f02`) declines on the ORACLE, on the
        // base and on that same binary, with this fence's own string.
        //
        // THE FIX IS A SEED, NOT A POLICY. `railBankParkedRails` answers "which
        // rail NAME does this cell read denote", and the walk that follows is
        // the SAME walk with the SAME `EmitPoint` and the SAME policy bit. So a
        // bank cell read is adjudicated EXACTLY AS IF THE SOURCE HAD NAMED THE
        // PARKED RAIL DIRECTLY — which is precisely what the source says it is —
        // and that is why the fix separates ORDERING rather than banning the
        // shape:
        //   * a gate between the STORE and the READ is not provably after the
        //     read ⇒ returned ⇒ DECLINE (`f01`, `p01`/`p05`/`p08`);
        //   * a gate AFTER the read is harmless by leg 1 ⇒ ACCEPT, and the
        //     emitted stream is byte-identical to the register twin's (`f06`
        //     vs `f07`, measured equal; pair `p02`);
        //   * the CAPABILITY — a DISTINCT theta per cell, minted INSIDE the walk
        //     loop — seeds at a SOURCE theta (after `applyBank` PASS A the
        //     in-loop cell read IS `Constant::getNullValue`, so the theta's
        //     arg-0 is a classical constant), whose backward closure therefore
        //     stops at that init and whose forward users are the storage cast
        //     and the store — NEITHER of them a gate. So no gate is found and
        //     NOTHING changes (pairs `p03`/`p04`/`p07`; MEASURED with
        //     `CQ_STALEBANK_DBG=1`, which prints the seed: `o01` gives
        //     `cq_theta_si32(i32 noundef 0, …)` and `o02` gives
        //     `cq_theta_i1(i1 noundef zeroext false, …)`).
        //
        // ⚠ WHY HERE AND NOT AT D5. `isAdmittedRailBankReader` adjudicates WHICH
        // consumer may read a parked rail and asks nothing POSITIONAL; this is a
        // WHEN question and it belongs to the fence that owns it. Putting the
        // refusal on ALIASING grounds instead (N cells holding one rail) would
        // also decline `f06`/`d03`, which are byte-identical to register twins
        // the ORACLE accepts — an over-decline of a valid circuit (owner ruling
        // 2026-09-11), and a fence in the wrong file.
        //
        // ⚠ THE OTHER TWO FENCES THAT GO SILENT ON A MEMORY-RESIDENT WIRE ARE
        // NOT TAUGHT THIS HOP, DELIBERATELY. `railWireClosure` MUST NOT LEARN
        // ONE — `RailBankPromote.h` says so and it would trip
        // `f2SeedPinnedByLiveRegister`'s retirement trigger — and
        // `LoopLowering::staleRailRecordRead` groups per ROOT MINT, which a bank
        // load has none of. Their subjects are refused UPSTREAM by D5's POSITIVE
        // allow-list (a bank load may reach a `@cq_measure_<sfx>` and its
        // storage `trunc`, and nothing else). RETIREMENT TRIGGER: the day D5
        // admits a consumer that is not a measurement — a branch condition, an
        // arithmetic reader, a `cq_theta` arg-0 — re-derive which of those
        // fences now has a memory-resident subject, and give
        // `declineStaleRecordOps` the same hop in the same change.
        SmallVector<Value *, 4> Seeds;
        const bool Hopped = railBankParkedRails(Rec, Seeds);
        if (Seeds.empty()) {
          // Not a bank read at all — or a bank every store into which parks a
          // CONSTANT, i.e. a cell holding no rail name. Seeding `Rec` is then
          // byte-for-byte the pre-fix behaviour, so this fallback can never
          // create an accept; it can only fail to add a decline. It has no
          // subject today because the carve refuses a bank whose store value is
          // untainted (`QramLowering.cpp`: *"a classical store is never a rail
          // bank"*) and a `Constant` is never tainted — but the conjunct is
          // justified by DIRECTION, not by that unreachability (the Rule-13
          // review's item I-6 is exactly the objection to resting on a stage
          // enumeration), and the alternative failure would be silent.
          Seeds.push_back(Rec);
        }
        if (::getenv("CQ_STALEBANK_DBG") && Hopped) {
          errs() << "CQ_STALEBANK_DBG: reader in @" << F.getName()
                 << " reads a rail bank; seeds=" << Seeds.size();
          for (Value *S : Seeds)
            errs() << " [" << *S << " ]";
          errs() << "\n";
        }
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
        //
        // ⚠ THE DELTA IS TESTED AGAINST THE **SEEDS**, NOT ONLY AGAINST `Rec`
        // (the memory hop, 2026-09-15). A bank cell load is tainted from round 1
        // by piece 1, so keying the re-ask on `Rec` alone would skip a bank
        // whose PARKED RAIL is the value that just became tainted — the very
        // L1 PREDICATE species this comment is about, one indirection out. The
        // conjunct is a DECLINE-direction widening of a re-ask (it can only add
        // work and add declines, never grant one), and it has no constructible
        // subject today because a `%out` rail reaches a bank store only through
        // in-loop tainted control flow, which declines earlier. It is here on
        // I-6's ground — *the alternative failure is silent and the direction is
        // narrowing* — and NOT on a claim of unreachability.
        if (Delta) {
          bool InDelta = Delta->count(Rec) != 0;
          for (Value *S : Seeds)
            InDelta = InDelta || Delta->count(S) != 0;
          if (!InDelta)
            continue;
        }
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
        // `c = a; cq_theta(&c, .9)` is an in-place Ry on the very rail it reads, so
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
        //   `int q=0; cq_theta(&q,.3); for(i<3){ int b=q; cq_theta(&b,.1);
        //    s+=cq_measure(b); }`
        // — compiled at `opt` exit 0 and emitted a stream BYTE-IDENTICAL to the
        // self-assigned chain `for(i<3){ cq_theta(&q,.1); … }`, a DIFFERENT,
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
        //   * the φ-carried in-loop chain (`cq_theta(&q,θ)`) — the header φ
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
        //
        // ⚠ AND IT IS WITHHELD OUTRIGHT WHEN THE MEMORY HOP FIRED. The
        // exemption's contract is "the reader IS its own gate on the record it
        // reads", and `readerStalesItself` is asked about `Rec`. After the hop
        // the record is the PARKED RAIL and `Rec` is only the cell that holds
        // its name, so asking the predicate about `Rec` would be asking about
        // the wrong object — the L3-MIRROR failure exactly (a third caller
        // arriving at a shared predicate without reading which direction it
        // grants in). Withholding is the DECLINE direction and needs no new
        // reasoning. It has no subject today: the only reader that can hop is a
        // `@cq_measure_*`, which is never a `cq_theta_` call, because D5's
        // positive allow-list refuses a bank load at `cq_theta` arg-0
        // (`bfix/probes/e03_load_theta_arg0.c`, measured DECLINE). RETIREMENT
        // TRIGGER: the day D5 admits a rotation reader, this must become
        // `readerStalesItself(CI, Seeds.front(), …)` over each seed, not a
        // blanket withholding — and the seed set must be a singleton for that
        // question to be well posed.
        SmallPtrSet<const CallInst *, 8> Self;
        if (!Hopped)
          if (auto *CI = dyn_cast<CallInst>(&I))
            if (CI->getCalledFunction() &&
                CI->getCalledFunction()->getName().starts_with("cq_theta_") &&
                !readerStalesItself(CI, Rec, *DT, &*LI, &*SE, &taint))
              Self.insert(CI);
        // A lifted read is not a cell read (its slot holds the base, not a bank
        // load), so the hop never fires for one; the record's gates join `Self`
        // as the same per-entry exemption (`Covered`: skipped as evidence, walked
        // through).
        if (LC) {
          if (Hopped)
            continue;
          Self.insert(LiftCov.begin(), LiftCov.end());
        }
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
        //
        // ⚠ THE POLICY BIT IS UNCHANGED BY THE MEMORY HOP, AND THAT IS THE
        // POINT. `Seeds` is `{Rec}` for every reader that is not a bank read —
        // byte-for-byte the shipped call — and the parked rail for one that is.
        // One relation, one implementation, one policy bit (Rule 14): the hop
        // moves the SEED and nothing else, so a bank cell read gets exactly the
        // verdict its register spelling gets.
        //
        // ⚠ LEG 2'S BARRIER IS THE SEED'S **DEFINITION**, NOT THE **STORE**, and
        // for a bank those are two different instructions. `recordBarrierCutsPath`
        // grants when every path from the staling gate back to the read
        // re-executes the seed's def; what re-establishes a CELL's contents is
        // the store. They coincide today, and only because of clauses proven
        // elsewhere: the carve's C4 gives ONE store site, `applyBank` puts it at
        // the single LATCH of `L`, and a seed defined inside `L` is that store's
        // own operand — so re-executing the def re-executes the store in the
        // same activation. A seed defined OUTSIDE `L` cannot be granted at all
        // (its def never re-executes between the two loops), which is `f01`.
        // RETIREMENT TRIGGER — THE SAME GATE AS THE REVIEW'S I-2/I-3: the day a
        // CONDITIONAL bank store accepts, the store's value is a `phi` (PASS G),
        // a seed def inside `L` no longer implies the store ran, and this
        // coincidence must be re-derived against the STORE rather than assumed.
        // The same landing also owes this hop a backward closure through that
        // `phi`'s incomings — today the seed IS the `phi` and only its forward
        // users are walked.
        //
        // ⚠ THAT TRIGGER FIRED WITHOUT BEING READ, AND IS RE-DERIVED HERE
        // (bd `xdu2.1`, Track B, 2026-09-24 — L8's "a trigger works only if
        // someone reads it"). CONDITIONAL bank stores accept today: the xdu2.4
        // seed-path prep (`if (Z >= 2) cq_theta(&b[i], .5); if (b[i])
        // Z -= 2;`, the owner's `example/grover/main.c`) stores the merge phi
        // `%cq.bank = phi [theta, %arm], [%cq.bank.seed, %skip]`, and the PASS-H
        // emptied arm stores `%cq.bank1 = select c, t, 0` (both MEASURED with
        // `CQ_STALEBANK_DBG=1` / `CQ_RAILBANK_DBG=1`). The re-derivation:
        //   * LEG 2's COINCIDENCE STILL HOLDS, for a reason that is now about
        //     the STORE: PASS C/D put the phi (or select) and the ONE store in
        //     the same activation, def before store, and the carve refuses an
        //     exit between them (the early-exit decline, matrix row 5 of
        //     `railbank_dynamic_matrix.c`), so re-executing the seed def
        //     re-executes the store. It is argued, not measured by a mutant: no
        //     accepting module puts a gate on the phi's wire between the two.
        //   * THE BACKWARD CLOSURE HAS NO SUBJECT, SO IT IS NOT ADDED. The phi
        //     is exactly the MERGE VALUE the register spelling of the same
        //     program names, and the register fence seeds a merge value
        //     forward-only too, so seeding the phi is parity with the register
        //     spelling. A stale read THROUGH an incoming needs that incoming to
        //     have another name outside `L`, and MEASURED, every such spelling
        //     declines at an earlier wall (`railbank_stale_matrix.c` rows
        //     14/15: `condition predates a non-diagonal gate` and `control flow
        //     under quantum control`; the unconditional sibling, row 16,
        //     declines HERE). The closure was built as source mutant M8
        //     (`TRACK_B.md` §4: every non-constant phi/select incoming added as
        //     a seed) and moved NO verdict in the owned tests — including both
        //     shipped conditional-bank shapes (matrix rows 30/31) — so it is
        //     free on what was measured and pinned by nothing: shipping it
        //     would be a conjunct no fixture can hold (Rule 12 (c)).
        //     RETIREMENT TRIGGER, narrowed: the day a conditional-bank program
        //     whose arm rail ESCAPES `L` accepts, add the closure WITH a row
        //     for that program in `tools/railbank_twin_pairs`.
        // ⚠ `SeedIsCellRead = Hopped` (bd `xdu2.1`, Rule-13 round 3, F-R3-1):
        // a hopped seed is read out of a CELL, so the harmlessness proof may
        // not grant by "re-running the seed's def refreshes the record" — that
        // writes the NEXT cell, not this one (see `WireWalk.h`). Leg 1 only.
        // The comment above that says the hop "moves the SEED and nothing
        // else" was true until this bit; it now also withholds leg 2, and
        // only for a hopped reader.
        if (findNonDiagonalWireGate(Seeds, /*CrossValueRouting=*/true, &I, &*DT,
                                    &taint, Self.empty() ? nullptr : &Self,
                                    /*RequireEmitDominance=*/false,
                                    /*SeedIsCellRead=*/Hopped))
          taint.StaleQuantumReaders.emplace_back(&I);
      }
    }
  }
}

}  // namespace

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
  // MEASURED pre-3qlq, on the customer (`slice_control_seq_grover` in the register
  // form, IR dumped immediately before this call). At `-O1` the parent of two of
  // its three candidate sites is a MERGE PHI of a tainted-condition diamond
  // (`%8 = phi i32 [ %6, %5 ], [ %3, %0 ]`), whose "later uses" cannot be read
  // off the CFG at all. By the time `lowerOps` runs, `detectControlRegions` +
  // `SwapRouteEmit` + `RegionFlatten` have linearized the whole function and
  // RAUW'd those phis away, so the same site reads as a flat
  // `%6 = add nsw i32 %5, %4` on a handle whose entire user list — the region
  // compare, its `_unc` strip, the route's two `cqrt_cswap`s, the free — was
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
