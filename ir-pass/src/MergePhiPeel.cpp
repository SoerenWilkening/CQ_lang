// MergePhiPeel.cpp — bd `test_C_libtooling-b6ap`: THE MULTI-PHI MERGE PEEL.
//
// Read `MergePhiPeel.h` first: what this stage is, why `-O1` makes it necessary,
// why the condition is CLONED rather than shared, and why it must run in every
// detection round. This file carries the PREDICATE and the REWRITE.
//
// ACCEPT-ONLY (the `flattenPredMuxRegions` / `lowerControlledIOSinks`
// precedent): this stage NEVER calls `diagnoseUnderControl`. A shape that fails
// any clause is left BYTE-UNTOUCHED and reaches its existing loud owner
// unchanged — for a >1-φ merge that is `ControlDetect`'s `control flow`.

#include "MergePhiPeel.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include "BoolStorageNarrow.h" // narrowBoolStoragePhis (bd dm7f.53)
#include "ControlShape.h"     // uncondSucc / regionEntryInLoop
#include "PredMuxFlatten.h"   // isMuxableType (P5 — the ONE spelling, Rule 14)
#include "SelectClassify.h"   // isCondRailLeaf (P7b)
#include "TaintPropagation.h"

using namespace llvm;

namespace cq {

namespace {

// ── THE SHAPE (P1) ──────────────────────────────────────────────────────────
//
// A recovered peel site. `TruePred` / `FalsePred` are the MERGE PREDECESSORS
// reached when the condition is 1 / 0 respectively — the Rule-9 polarity, read
// off the branch and NEVER assumed (`clang -O1` routinely makes the gate arm the
// FALSE successor; a swapped polarity here would mux the two values the wrong way
// round, which is a wrong unitary that `opt -verify` cannot see).
struct PeelSite {
  BranchInst *BI = nullptr;
  BasicBlock *Pred = nullptr;
  BasicBlock *MergeBB = nullptr;
  BasicBlock *TruePred = nullptr;
  BasicBlock *FalsePred = nullptr;
  // P7: the region compare to CLONE into the merge, or null when the condition
  // is a bare RAIL leaf (which needs no clone — the register IS the condition).
  CmpInst *CondCmp = nullptr;
  // The φ to peel, in `MergeBB`'s own φ order.
  SmallVector<PHINode *, 4> Phis;
};

// P1 — recover the shape `recoverRegion` recognizes, by SSA identity and with NO
// mutation (Rule 9). This deliberately MIRRORS `ControlDetect::recoverRegion`'s
// three recognizers rather than calling it: `recoverRegion` bakes `soleMergePhi`
// into every one of them, so on the >1-φ merge this stage exists for it returns
// `OffPattern` (or `Nested`, when the merge hosts the next region's tainted
// branch — the hcrg sequential shape) and would tell us nothing. The SHAPE tests
// are transcribed clause-for-clause; only the φ-count question is dropped.
//
// The `hasNPredecessors(2)` demand is the one that carries the weight, and it
// carries three different loads at once:
//   (i)  it is what `soleMergePhi`'s 2-incoming φ proves for the shapes that DO
//        have one, and this stage has no φ to read it off — the same reason
//        `classifyPhaseKickback` and `lowerControlledIOSinks` ask it directly;
//   (ii) it makes every φ's incoming-block list exactly {TruePred, FalsePred},
//        so `getIncomingValueForBlock` below is total; and
//   (iii) it STRUCTURALLY EXCLUDES the depth-2 nest, whose shared merge has
//        THREE predecessors (outer straight-through, mid straight-through,
//        inner) — so the peel can never disturb a `RegionTreeDetect` accept, and
//        no `Claimed`-set equivalent is needed here (SCOPE §3 P1's "`BI` is not
//        `Claimed` by a nest" is discharged by shape, not by bookkeeping).
// An abort/exit-park arm is excluded for a fourth, independent reason: it ends in
// `unreachable`, so `uncondSucc(arm)` is null and no recognizer matches.
bool recoverPeelShape(BranchInst *BI, PeelSite &S) {
  BasicBlock *Pred = BI->getParent();
  BasicBlock *S0 = BI->getSuccessor(0);  // cond == 1
  BasicBlock *S1 = BI->getSuccessor(1);  // cond == 0
  if (S0 == S1)
    return false;  // degenerate; also the only way a φ could name one pred twice.

  if (uncondSucc(S0) == S1 && S0->getSinglePredecessor() == Pred) {
    // Diamond, orientation A — arm = S0 (TRUE successor), merge = S1. The merge
    // is reached from the ARM when the condition is 1 and from `Pred` when it
    // is 0.
    S.MergeBB = S1;
    S.TruePred = S0;
    S.FalsePred = Pred;
  } else if (uncondSucc(S1) == S0 && S1->getSinglePredecessor() == Pred) {
    // Diamond, orientation B — arm = S1 (FALSE successor), merge = S0. Rule 9's
    // canonical `clang -O1` output for `if (u != k)`, and the owner's file.
    S.MergeBB = S0;
    S.TruePred = Pred;
    S.FalsePred = S1;
  } else if (BasicBlock *M = uncondSucc(S0);
             M && M == uncondSucc(S1) && M != S0 && M != S1 &&
             S0->getSinglePredecessor() == Pred &&
             S1->getSinglePredecessor() == Pred) {
    // If/else — both successors are single-pred, single-succ arms reconverging.
    // There is no `Pred` edge at all, so P3 below asks both incomings to
    // dominate `BI`, which for an if/else means neither is arm-defined: the whole
    // φ was a cross-arm mux of pred-available values. Reachable from hand IR
    // only at `-O1` (which folds such a φ), kept in the predicate and fixtured.
    S.MergeBB = M;
    S.TruePred = S0;
    S.FalsePred = S1;
  } else {
    return false;
  }
  if (!S.MergeBB->hasNPredecessors(2))
    return false;
  S.BI = BI;
  S.Pred = Pred;
  return true;
}

// P10 — DOES EITHER ARM WRITE MEMORY? If so, NOT PEELED.
//
// ⚠ bd b6ap Rule-13 ROUND-1 finding F-B6-2, and it is the DECLINE-KEEPING half of
// the containment gate below rather than a new capability. `classifyGuardedStoreArm`
// (the 7.5 guarded Shadow store, `GuardedStoreArmEmit.cpp`) owns a diamond whose arm
// is a side-effect-only bounded-alloca store, and it LOUD-declines
// `guarded store with a merge value` the moment that merge holds ANY φ. Peel both φ
// away and the region flips DECLINE → ACCEPT — MEASURED on `g01`, where the answer
// is right and **the entire 7.5 reversal spine stops running**: no
// `cqrt_qram_load_<W>_unc`, no `cqrt_qram_store_<W>_controlled_unc`, no strip or
// free of the path-predicate flag, no `cqrt_ry` inverse; 10 rail mints, 10 left
// allocated, and stage 2b reports `0 violation(s)` because a leak is Rule-6's SAFE
// direction and 2b is blind to it. Its one-φ control `g02` runs the complete
// reversal on the oracle, so the difference belongs to the NEW ACCEPT, not to the
// extra registers.
//
// A brand-new accept in the QRAM neighbourhood, behaving materially unlike its
// shipped sibling, is exactly what the Prime Directive says not to ship on the
// strength of "the answer looked right": it needs its own row and its own round.
// So the peel refuses the site outright and `g01` keeps its existing loud decline.
//
// SPELLING, and why NOT the narrow one. The alternative was to call the shared
// recogniser `guardedShadowStoreShape` (`QramLowering.h`) on each arm store. It is
// rejected on two counts: it needs a `LoopInfo` and a QRAM dependency inside an
// accept-only normaliser that today knows nothing about memory at all; and it is
// NARROWER than the hazard — it would still peel a merge whose arm holds some OTHER
// write, i.e. it fences the ONE member that was probed instead of the property that
// made it dangerous. `StoreInst`/atomic-in-arm is the property: this stage's whole
// population is arms that compute, and a merge whose arm WRITES MEMORY belongs to
// the 7.5 owners. MEASURED cost: zero — no accept fixture and no shipped slice has a
// write in a peeled arm (the peel's own `control_peel_*` corpus and the two fused
// e2e slices are all pure-chain arms).
//
// NOT `mayHaveSideEffects()` / `mayWriteToMemory()`: a `@cq_theta` CALL answers TRUE
// to both (it is an opaque declaration), and an arm `cq_theta` is the peel's single
// commonest member — that spelling would silently delete the whole capability.
//
// ── AMENDMENT, bd `xdu2` / L-1a (Track B, 2026-09-14c): THE RAIL-BANK PROMOTER
//    REMOVES STORES FROM ARMS *BEFORE* THIS STAGE, AND THE MEASURED CONSEQUENCE
//    IS NOT THE ONE THE DESIGN PREDICTED ────────────────────────────────────────
//
// `SCOPE_L1a.md` §4.4(D) lists this clause as "a direct obstacle" to L-1a and
// predicts: *"the promotion must run BEFORE `MergePhiPeel` (it does) and after it
// the arm holds NO store, so P10 stops refusing. Verify by measurement, and amend
// the header."* The first half is true — `promoteRailBankCells` runs in the
// `-O1`-repair normaliser fixpoint, far above this stage — and the prediction is
// nevertheless FALSE for the whole bank population, for a reason that has nothing
// to do with this clause.
//
// MEASURED (a temporary audit build instrumenting P9 / P1 / P10 plus a
// `CQ_RAILBANK_OFF` lever, so both halves came from one binary; records at
// `inc1-records/session-2026-09-14c-xdu2-w1/trackB/probes/p10_measurement.txt`):
// over six bank modules (`a_loop_n{2,3,8}`, `…_noarm`, the uninitialized bank and
// the `int`-cell bank), with the promoter OFF and with it ON, this stage's loop
// emits **ZERO** audit lines — it is NEVER REACHED. The module dies at
// `declineTaintEscapes`' `kMsgStore` seven stages earlier, and
// `LLVMContext::diagnose` EXITS on the first `DS_Error` (bd `br4a`). The same
// audit binary printed the full P1 → "P10 asked" → "P10 passed" sequence on
// `control_peel_freeze_incoming.ll` and the "P10 armWritesMemory REFUSED" line on
// `control_peel_{reject_,}guarded_store*.ll`, so the lever was live and the zero
// is a fact about the population, not a dead instrument.
//
// ⚠ AND WHEN L-1a's DEFERRED HALF LANDS AND THE POPULATION STOPS DECLINING, P10
// IS STILL NOT THE FENCE IN FRONT OF IT: every rail-bank region is INSIDE THE
// WRITE LOOP, so **P9** (`regionEntryInLoop`, above) refuses it first, and the
// ≥2-φ containment gate refuses it again — the promoted latch carries exactly ONE
// φ. So this clause's own text ("a merge whose arm WRITES MEMORY belongs to the
// 7.5 owners") stands unchanged and unweakened; what is corrected is only the
// SCOPE's claim that L-1a would make this clause the live fence.
//
// RETIREMENT TRIGGER: the day P9 is narrowed to admit an in-loop peel site
// (P9's own note calls that a follow-on with its own rounds), re-run the
// measurement above — a promoted bank region would then reach P1, and this clause
// would be asked about it for the first time.
bool armWritesMemory(BasicBlock *ArmBB) {
  for (Instruction &I : *ArmBB)
    if (isa<StoreInst>(I) || isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I))
      return true;
  return false;
}

// P7 — is the region's condition RE-MINTABLE at the merge?
//
//   (a) a `CmpInst` defined in `Pred` all of whose operands dominate the merge —
//       clone it; or
//   (b) a bare RAIL leaf (`isCondRailLeaf` — a `cq_theta_i1` result), which needs
//       no clone at all because the register IS the condition and
//       `SelectMergeEmit`'s `CopyRailRoot` path mints its own CNOT copy of it.
//
// Anything else — an `and`/`or`/`xor` CONDITION TREE, a `select i1` combinator, a
// `trunc`, a `zext`, an `Argument`, a header φ — is NOT PEELED. The tree case is
// reachable and is a deliberate, recorded omission (OQ-4): `CondTreeEmit::
// collectCondTree` would accept the tree as a region condition, but cloning a
// TREE is a materially bigger rewrite than cloning one compare and it would put a
// second copy of a multi-node network on the condition wire. Over-declining is
// safe; the shape keeps its existing `control flow`.
//
// ⚠ THE CLONE IS A NEW TAINTED COMPARE ON THE CONDITION WIRE, and the wire fences
// ARE asked of it — they are not bypassed. `SelectClassify`'s gate 2c prong (a)
// is POSITION-FREE (any off-ancestry theta on the condition's provenance wire
// declines wherever the compare sits), so cloning cannot launder a stale
// condition: MEASURED on `h85`, where the arm rotates the condition register and
// the peeled module declines `condition predates a non-diagonal gate`. For a rail
// root the ladder is `SelectClassify.cpp`'s (i) tainted / (ii)
// `railMeasuredBeforeReadPoint` / (iii) gate 2c with the DT prong, plus the
// round-2 re-verification `reverifyRailCondReads`.
bool condRemintableAt(BranchInst *BI, BasicBlock *MergeBB, const DominatorTree &DT,
                      CmpInst *&CondCmpOut) {
  Value *Cond = BI->getCondition();
  if (isCondRailLeaf(Cond)) {
    // (b) The rail itself. It dominates `BI`, and `Pred` dominates `MergeBB`
    // (the merge's only two predecessors are `Pred` and blocks whose only
    // predecessor is `Pred`), so it dominates every use we are about to make.
    // Asked explicitly rather than argued, because "obviously dominates" is how
    // a use-before-def gets into a Release build.
    auto *CI = dyn_cast<Instruction>(Cond);
    if (!CI || !DT.dominates(CI, MergeBB))
      return false;
    CondCmpOut = nullptr;
    return true;
  }
  auto *Cmp = dyn_cast<CmpInst>(Cond);
  if (!Cmp || Cmp->getParent() != BI->getParent())
    return false;  // (a) fails — a compare hoisted out of `Pred` is not ours.
  for (Value *Op : Cmp->operands())
    if (auto *OI = dyn_cast<Instruction>(Op))
      if (!DT.dominates(OI, MergeBB))
        return false;  // the clone would not be legal at the merge.
  CondCmpOut = Cmp;
  return true;
}

// P2/P3/P5/P6/P8 — is this ONE φ a mux the peel may restore to a `select`?
//
// P3 IS THE WHOLE PREDICATE: every incoming must be AVAILABLE AT `BI` — a
// `Constant`, an `Argument`, or an `Instruction` that DOMINATES `BI`. An incoming
// defined IN AN ARM fails it, and the peel must NEVER hoist one out: hoisting a
// tainted op out of an arm changes which gates run unconditionally, which is
// PredMux's E4-gated job (it erases the whole arm) and not this stage's, whose
// contract is to leave the arm, the CFG and the region's own φ exactly where they
// are. MEASURED `p88` (two `cq_theta` preps in one arm — nothing peelable, the
// program must keep declining) and `h30b` (the arm incoming is a *speculatable*
// `mul` defined in the arm — STILL not peelable).
bool phiPeelable(PHINode *Phi, const PeelSite &S, const DominatorTree &DT) {
  if (Phi->getNumIncomingValues() != 2)  // P2
    return false;
  if (Phi->getBasicBlockIndex(S.TruePred) < 0 ||
      Phi->getBasicBlockIndex(S.FalsePred) < 0)
    return false;  // P2 — not a φ over THIS region's two edges.
  if (!isMuxableType(Phi->getType()))  // P5 — the 4.4/kjd1 copy envelope.
    return false;
  if (Phi->use_empty())  // P8 — a dead φ has no mux to build.
    return false;
  Value *TV = Phi->getIncomingValueForBlock(S.TruePred);
  Value *FV = Phi->getIncomingValueForBlock(S.FalsePred);
  if (TV == FV)
    return false;  // P6 — an identity φ is a live-range extender, not a mux.
  for (Value *V : {TV, FV}) {
    // P3b (SCOPE H-9) — an `undef`/`poison` incoming is REFUSED rather than
    // peeled. A peel would put the literal into a `select` arm and thence into
    // TWO emitted gate slots (the controlled copy and its `_unc`), which is
    // exactly the population `LiteralIntegrity`'s guard 1 counts: at the `-O0`
    // stage-3 link the two slots may read as two DIFFERENT values, so the adjoint
    // stops inverting its forward (Rules 6, 8). That guard is a module-wide LOUD
    // decline, so admitting the shape could only ever turn today's `control flow`
    // into a different loud decline — but the peel's job is not to manufacture
    // customers for a literal-integrity guard, and this clause is the
    // decline-keeping option. `PoisonValue` derives from `UndefValue`, so one
    // test covers both. NOT MEASURED in the scoping probes; recorded as such.
    //
    // ⚠ `freeze` IS PEELED, AND THAT IS CORRECT, NOT AN OVERSIGHT (Rule-13
    // round-1 review, P3b DOC item; fixtures `control_peel_freeze_incoming.ll`
    // ACCEPT / `control_peel_reject_undef_incoming.ll` DECLINE). `freeze i32
    // poison` is an `Instruction`, not an `UndefValue`, so it falls to the P3
    // dominance clause below and peels — and the clause above is not being
    // dodged: `freeze` is SINGLE-VALUED BY DEFINITION (every read of one
    // `freeze` yields the same bit pattern), which is precisely the property
    // `LiteralIntegrity`'s guard 1 counts. The hazard there is a literal
    // `undef`/`poison` read as TWO DIFFERENT values in the forward gate and its
    // adjoint; a `freeze` cannot do that. Refusing it would be an over-decline
    // with no argument behind it.
    if (isa<UndefValue>(V))
      return false;
    if (isa<Constant>(V) || isa<Argument>(V))
      continue;  // P3 — available everywhere / at function entry.
    auto *I = dyn_cast<Instruction>(V);
    if (!I || !DT.dominates(I, S.BI))
      return false;  // P3 — arm-defined (or otherwise unavailable at `Pred`).
  }
  return true;
}

}  // namespace

bool peelIndependentMergePhis(Module &M, TaintSet &taint,
                              SmallPtrSetImpl<Value *> *Delta) {
  bool Changed = false;
  // Every instruction this stage CREATES, for the seeded forward re-propagation
  // below. See the note at the `taint.Tainted.insert(Sel)` site for why inserting
  // the new values alone is NOT enough.
  SmallVector<Value *, 8> Seeds;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;

    // bd dm7f.53 — the `_Bool` storage-width φ narrowing (BoolStorageNarrow.h),
    // FIRST, so every round sees the `i1` spelling `-O1` uses for the
    // single-diamond program. Accept-only like the peel; its seeds join the
    // peel's one `propagateFromSeeds` below, so the taint growth is reported in
    // the same `Delta` the caller adjudicates.
    if (narrowBoolStoragePhis(F, taint, Seeds))
      Changed = true;

    // ── DETECT (pure, no mutation — Rule 9) ─────────────────────────────────
    //
    // ONE `DominatorTree` per function, built LAZILY on the first tainted
    // conditional branch — the same trigger and the same measured reason as
    // `detectControlRegions`' (an unconditional `DominatorTree DT(F)` costs
    // ~60ms per invocation on a libm slice whose functions mostly have no
    // tainted branch at all, and the census corpus is full of such modules).
    //
    // ONE tree is valid for this WHOLE sweep, including across the rewrite
    // below, and that is a property of the rewrite rather than an assumption:
    // the peel inserts instructions and erases φ, and changes NO edge — the CFG
    // is byte-identical afterwards, so dominance is too. It is still built
    // before the first mutation and never cached across a stage boundary.
    std::optional<DominatorTree> DT;
    SmallVector<PeelSite, 4> Sites;

    for (BasicBlock &BB : F) {
      auto *BI = dyn_cast<BranchInst>(BB.getTerminator());
      if (!BI || !BI->isConditional() ||
          !taint.Tainted.count(BI->getCondition()))
        continue;

      // P9 — NOT IN A LOOP. ⚠ THIS CLAUSE IS A DELIBERATE ADDITION TO SCOPE §3's
      // P1-P8 PARTITION, and it is the conservative (decline-keeping) direction.
      //
      // Every measured member of the peel's population is straight-line. An
      // in-loop 2-φ merge declines `control flow` today; peeling it would hand
      // the flattener a region that `flatRegionRollableInLoop` may ROLL IN PLACE
      // (bd 8h7d.5) with a peeled `select` and a freshly cloned tainted compare
      // in the loop BODY — a combination nothing in the tree has measured, in the
      // one neighbourhood where CLAUDE.md's record is eight findings over six
      // adversarial rounds on one function (the per-activation rail leaks). The
      // 4.4 select itself is loop-legal (bd 9ymx), so this is not a claim that
      // the shape is unsound; it is a refusal to widen two axes at once. Widening
      // it is a follow-on row with its own rounds, not a free line here.
      //
      // `regionEntryInLoop` is the reducibility-INDEPENDENT walk the d8jl guards
      // use, not `LoopInfo` — an irreducible cycle has no `LoopInfo` loop and
      // would be invisible to `getLoopFor` (the bd drbq Inc-2b S7 lesson).
      //
      // ⚠ P9 ALSO CARRIES A DANGLING-POINTER OBLIGATION, and a widening owes it
      // an answer (bd b6ap Rule-13 ROUND-2, the φ-consumer audit). `TaintSet::
      // BreakRegions` — written by `lowerLoops` (`CQLoweringPass.cpp`, BEFORE
      // this stage) and read by `lowerBreakReversePlay` (after it) — holds
      // RAW `llvm::PHINode *` (`LoopBreakRegion::EscapePhi`, `::CounterPhi`). It
      // is the ONE structure in the pass that a deleted φ could dangle in, and
      // what keeps it safe today is THIS CLAUSE plus P1: the 7.4 break shapes put
      // `CounterPhi` in the loop HEADER (in-loop ⇒ P9) and `EscapePhi` in the
      // exit merge, whose predecessor's terminator is the in-loop exiting branch
      // (in-loop ⇒ P9, and its arm does not unconditionally reach the merge ⇒
      // P1). MEASURED, not argued: over the 1814 fixtures, 17 reach this stage
      // with `BreakRegions` non-empty (the `lowering_loop_break_*` /
      // `lowering_reject_break_*` families) and **not one of them peels a φ**;
      // the four `slice_loop_break*` e2e slices likewise arrive with `n=1` and
      // peel nothing. RETIREMENT TRIGGER: if P9 is ever narrowed to admit an
      // in-loop site (IMPL §7 Q2), the peel must first scrub or re-derive
      // `BreakRegions`' φ pointers — this is the bd `drbq` Inc-1 stale-set class,
      // and a `Value *` table keyed one stage and read two stages later is
      // exactly how that defect shipped.
      if (regionEntryInLoop(BI))
        continue;

      if (!DT)
        DT.emplace(F);

      PeelSite S;
      if (!recoverPeelShape(BI, S))
        continue;  // P1.

      // P10 (bd b6ap F-B6-2) — an ARM that writes memory belongs to the 7.5
      // guarded-store owner, which declines on any merge φ; peeling would flip it
      // to an accept whose whole reversal spine stops running. Both merge
      // predecessors are asked: in a diamond exactly one of them IS `Pred` (the
      // straight-through edge, whose writes are unconditional and pre-branch, so
      // it is skipped), and in an if/else both are genuine arms.
      //
      // ⚠ WHY THE NARROW `StoreInst`/atomic SPELLING IS SUFFICIENT, and the
      // RETIREMENT TRIGGER for it (bd b6ap Rule-13 ROUND-2, item D-3). It is NOT
      // sufficient because the set of write-shaped instructions is small — it is
      // not: `@llvm.memset` / `@llvm.memcpy` and a call to a visible function that
      // stores are all `CallInst`s and pass this clause. It is sufficient because
      // THE ONLY OWNER IN THE TREE THAT ACCEPTS AN ARM WHICH WRITES is the 7.5
      // guarded store, and its recogniser is
      // `bool guardedShadowStoreShape(llvm::StoreInst *SI, …)` (`QramLowering.h`)
      // — it takes a `StoreInst *`, so a non-`StoreInst` writer has no classifier
      // at all and dies at the ARM classifier's `control flow` whether it is
      // peeled or not. MEASURED, all four, identical on both binaries: probes
      // `M03` (`memset`), `M04` (`memcpy`), `M02` (a writer call) and `M05` (the
      // plain `StoreInst` control). RETIREMENT TRIGGER: the day ANY classifier
      // accepts a `MemIntrinsic` or writer-call arm, P10 must widen with it —
      // the containment argument above is only as strong as "a write-arm shape
      // that is not a `StoreInst` has no accepting owner".
      if ((S.TruePred != S.Pred && armWritesMemory(S.TruePred)) ||
          (S.FalsePred != S.Pred && armWritesMemory(S.FalsePred)))
        continue;

      // THE CONTAINMENT GATE, and it is what makes this stage accept-monotone BY
      // CONSTRUCTION rather than by hope. The peel fires ONLY on a merge holding
      // **at least two** φ, and no classifier in the tree can claim such a region
      // today:
      //   * all three `recoverRegion` recognizers go through `soleMergePhi`,
      //     which returns null on >1 φ;
      //   * `classifyPhaseKickback` admits merge φ ∈ {none, ONE angle tail} —
      //     `phaseAngleTail` itself refuses a second φ;
      //   * `classifyAbortPark` needs an `unreachable`-terminated arm and
      //     `classifyGuardedStoreArm` LOUD-declines on any merge φ at all —
      //     ⚠ and THAT second clause is why "every site this stage touches
      //     declines today" was TRUE and INSUFFICIENT (bd b6ap F-B6-2): the
      //     guarded-store decline is a decline THE PEEL CAN REMOVE, by deleting
      //     the very φ it keys on. Containment needs the site to keep declining
      //     AFTER the peel, not merely to decline before it. P10 above restores
      //     that by refusing the shape outright;
      //   * `lowerControlledIOSinks` demands `NumPhis == 0 || ValuePhi` AND runs
      //     BEFORE this stage, so its verdict is already final;
      //   * the depth-2 nest is excluded by `hasNPredecessors(2)` above.
      // So every site this stage touches is one that declines LOUDLY today. The
      // corresponding COST is deliberate and recorded as OQ-5: a merge holding
      // exactly ONE φ that the region does not define (a data mux beside a VOID
      // phase arm — probe `p60` minus its prep) is left declining, because
      // relaxing this gate to "≥1 non-region φ" would mean deciding WHICH φ is
      // the region's, and getting that wrong on a one-φ merge would peel the
      // region's OWN merge and break a shipped accept.
      //
      // ⚠ THAT — "the stage cannot tell WHICH φ is the region's" — IS THE WHOLE
      // REASON, and the fixture that demonstrates it
      // (`control_peel_angle_tail_unchanged_control.ll`, the shipped
      // `classifyPhaseKickback` ANGLE TAIL) must NOT be read as an f64/angle
      // WIRE-CROSSING. The Rule-13 round-1 review MEASURED the pair: the same
      // angle φ, peeled (because a data mux sits beside it) and unpeeled, emit
      // the SAME UNITARY — relative phase `c=1 → 2.2`, `c=0 → 0.1` in both, no
      // `cqrt_alloc_f64` anywhere — because a peeled angle select is claimed by
      // `classifyAngleSelect`, which is an ANGLE consumer. The hazard is peeling
      // the region's OWN φ, whatever its type; the fp type is incidental.
      unsigned NumPhis = 0;
      for (PHINode &P : S.MergeBB->phis())
        (void)P, ++NumPhis;
      if (NumPhis < 2)
        continue;

      if (!condRemintableAt(BI, S.MergeBB, *DT, S.CondCmp))
        continue;  // P7.

      // P4 — peel EVERY passing φ, but only while AT MOST ONE φ fails. Two or
      // more survivors is a genuine multi-value arm merge (`p88`): the region
      // would still have a >1-φ merge after the peel and would still decline, so
      // peeling would buy nothing and would leave a half-normalised module for
      // the reviewer to reason about. Leave it wholly untouched instead — the
      // decline that must SURVIVE.
      unsigned NotPeelable = 0;
      for (PHINode &P : S.MergeBB->phis()) {
        if (phiPeelable(&P, S, *DT))
          S.Phis.push_back(&P);
        else
          ++NotPeelable;
      }
      if (NotPeelable > 1 || S.Phis.empty())
        continue;
      Sites.push_back(std::move(S));
    }

    // ── REWRITE ─────────────────────────────────────────────────────────────
    for (PeelSite &S : Sites) {
      // The insertion point is captured ONCE, before any φ is erased: the first
      // non-φ instruction of the merge. Every clone and select is inserted BEFORE
      // it, so they land in φ order (clone₀, sel₀, clone₁, sel₁, …) immediately
      // after the surviving φ — which is the position SCOPE §7 settles on, and
      // the minimal rewrite: the φ is replaced IN PLACE, so every use is already
      // dominated and no RAUW ordering question arises.
      //
      // MEASURED that the alternative is not equivalent: `h09c` (merge-placed)
      // and `h09d` (pred-placed) BOTH accept at 22 lines and 2b-clean, and their
      // TRACES DIFFER — pred placement emits the select's whole merge stream
      // BEFORE the region's. Merge placement preserves source order (the region
      // ran, then the mux was read).
      //
      // ⚠ MERGE PLACEMENT DOES **NOT** KEEP THE CLONE OUT OF THE drbq STATE-PREP
      // FENCE, and the claim that it does (shipped until 2026-09-13) was false.
      // `f2SeedPinnedByLiveRegister` has TWO halves; placement only moves the
      // clone out of the **backward** one (`Cand` filters on
      // `DT->dominates(&In, BI)`, in `f2SeedPinnedByLiveRegister`,
      // ArmClassify.cpp). The **forward** half reaches it anyway: it walks
      // every tainted USER of the condition's pinned operand rail with no
      // position filter, folds this clone to a singleton `i1` through
      // `f2Model`'s `ICmpInst` arm, and the seed test then matches it against
      // an `i1` (`_Bool`) seed — `true` on one edge, `false`
      // on the other, so BOTH `i1` seeds collide. MEASURED:
      // `HP_g_sel_only.ll` (this clone alone, merge-placed, no select) turns
      // `HP_f_nopeel.ll`'s ACCEPT into F2's `state prep seed is proven equal to
      // the condition register`; it is the PIN and not the spelling (`HP_d`:
      // another predicate, `HP_e`: another constant — both decline). The repair
      // is at F2's test, not here: the clone is recorded in `taint.PeelClones`
      // below and excluded at that test (`excludedAtTest` in
      // `f2SeedPinnedByLiveRegister`), on the ground that a value
      // this pass MANUFACTURES has no source preimage and therefore no rival
      // program for F2 to protect against (bd `rb9x`). Do not re-ground that
      // exclusion on "the same compare on the same wire": a function with two
      // fused diamonds produces a clone of the OTHER region's condition too, and
      // the preimage argument — not the wire one — is what covers it.
      Instruction *IP = S.MergeBB->getFirstNonPHI();
      for (PHINode *Phi : S.Phis) {
        Value *CondV = S.BI->getCondition();
        if (S.CondCmp) {
          // The CLONE (SCOPE §6 option A). `Instruction::clone` copies the
          // predicate, the operands, the flags and the `!dbg`, so the clone is
          // the same compare on the same wire — just a different SSA value, which
          // is the entire point: the region's own condition keeps EXACTLY ONE
          // user (its branch), so `classifyArms`' `HasDataUse` stays false and
          // the ziov `condDataUseDisposition` fence is never asked a question it
          // was not written for.
          Instruction *Clone = S.CondCmp->clone();
          Clone->insertBefore(IP);
          Clone->setName("cq.peel.cond");
          // The clone's tainted operand is the region's, so the clone is tainted
          // for exactly as long as it exists (`lowerOps`/`SelectMergeEmit` erase
          // it). Recording it is REQUIRED, not hygiene: `SelectClassify` claims a
          // select only when `taint.Tainted.count(Sel->getCondition())`, so an
          // unrecorded clone would leave the peeled select for
          // `declineClassicalMuxes` and turn today's `control flow` into
          // `kMsgClassicalSelect` — a loud decline, but the wrong one.
          taint.Tainted.insert(Clone);
          // bd `test_C_libtooling-rb9x`, increment R-1 — THE RECORD. The clone
          // is a value the COMPILER manufactured; it has no source preimage, so
          // the drbq Inc-4 state-prep fence F2 must not read it as a rival
          // register the author could have rotated. This is the L1 pattern
          // verbatim: record the question at the site that KNOWS the answer
          // (only this line knows the value is manufactured), ask it at the site
          // that NEEDS it (`f2SeedPinnedByLiveRegister`'s equality TEST,
          // `ArmClassify.cpp`). `TaintSet::PeelClones`' header carries the
          // argument, the `WeakTrackingVH` reason and the retirement triggers.
          // Recording is UNCONDITIONAL and happens for every clone in every
          // round, so the fence cannot be handed a clone this line did not
          // record.
          taint.PeelClones.push_back(Clone);
          Seeds.push_back(Clone);
          CondV = Clone;
        }
        // Rule 9 polarity: `select C, T, F` yields `T` when `C` is 1, so each
        // incoming goes in the slot ITS OWN EDGE selects. `TruePred`/`FalsePred`
        // were read off the branch in `recoverPeelShape`; nothing here assumes
        // successor 0 is the arm.
        Value *TV = Phi->getIncomingValueForBlock(S.TruePred);
        Value *FV = Phi->getIncomingValueForBlock(S.FalsePred);
        // `SelectInst::Create`, never `IRBuilder::CreateSelect` — the builder
        // CONSTANT-FOLDS, and a folded mux would silently erase the controlled
        // copy this stage exists to expose (the `SwapRouteEmit::emitValueRegion`
        // precedent, same reason).
        auto *Sel = SelectInst::Create(CondV, TV, FV, "cq.peel.mux", IP);
        Sel->setDebugLoc(Phi->getDebugLoc());
        // ⚠ THE SELECT IS TAINTED UNCONDITIONALLY, AND "taint follows the φ" IS
        // WRONG — this is a MEASURED correction, not a style choice.
        //
        // `propagateWorklist` taints EVERY user of a tainted value (bar a measure
        // sink, an angle-only edge and — since bd cepm — the RESULT of a would-be
        // Phase-6 call predicted to return a classical value; a `select` is none
        // of those). A `phi` in the merge is NOT a user of the
        // branch condition, so a constant-armed merge `phi` is UNTAINTED; a
        // `select` IS one, so the IDENTICAL mux written in the source is TAINTED.
        // Copying the φ's taint therefore produces a module the source spelling
        // could never produce — and the difference is not cosmetic: with the
        // select left classical, its downstream users stay classical too, so
        // `add nsw i32 %m, %out` over the 4.4 merge OUT-RAIL reaches the backend
        // UN-LOWERED and adds the runtime HANDLE TAG instead of the superposed
        // value. That is the bd `afmv` verify-clean wrong unitary, and it was
        // MEASURED at `opt` exit 0 with stage-2b `0 violation(s)` on probes
        // `z08`/`z18`/`z19` before this line was corrected. The hand-peeled twin
        // of the same program (`z12`) lowered it CORRECTLY on the oracle, which is
        // precisely how the divergence showed up: the peel's contract is "produce
        // the module the hand peel already is", and a taint difference breaks it.
        //
        // NO `BirthOrder` entry is written, deliberately: this stage runs BEFORE
        // `lowerRotations`, so the select it produces is indistinguishable from
        // one the SOURCE wrote — and a source-written select has none. Assigning
        // one (as the mid-lowering `emitValueRegion` does for its own merge)
        // would make the peeled module differ from the hand-peeled control that
        // is this increment's byte-identity witness.
        taint.Tainted.insert(Sel);
        Seeds.push_back(Sel);
        Phi->replaceAllUsesWith(Sel);
        // Erase from the taint set BEFORE the instruction dies. `Tainted` WAS a
        // raw `std::set<Value *>`, and a dangling key in it is the bd `drbq`
        // Inc-1 defect verbatim (a `Value *` set keyed at one stage and read
        // stages later, after the key was erased). ⚠ Since bd 8e5r it is a
        // self-cleaning `TaintedValueSet` (`ScrubOnDelete.h`) and EVERY
        // `TaintSet` table drops a deleted key by itself, so this erase — and the
        // measured audit below, which a site-by-site defence needed — is now
        // belt-and-braces rather than the defence. No OTHER `TaintSet` field can name a SOURCE
        // φ at this program point — `InPlaceRailOps`/`PreLoopCommittedInPlaceOps`
        // hold `add`/`xor` ops, `ClaimedRailRoots` holds `cq_theta` root mints,
        // every `*Rails` field holds emitter-created handles that do not exist
        // yet, and `BirthOrder`/`HandleWidth` are written by `lowerRotations` and
        // `lowerOps`, both later.
        //
        // ⚠ THAT SENTENCE IS NOW MEASURED, not reasoned (bd b6ap Rule-13 ROUND-2,
        // the round-3 question: *the peel does not only grow taint — it DELETES a
        // φ*). A temporary audit build asked, at THIS line, whether the dying φ is
        // a member of every `TaintSet` container that can hold a `Value *` /
        // `Instruction *` (plus `BreakRegions`' raw `PHINode *` fields), over all
        // 1814 fixtures and all 501 probe modules under `inc1-records/**`: **194
        // erasures, and the ONLY container ever hit is `Tainted` (6 hits, all
        // genuinely tainted muxes) — the one erased on the next line.** `Phi->user_empty()` also
        // held at every one of the 194 (the RAUW above ran first), so no LLVM
        // `Use` dangles either. The full row-by-row table — which containers
        // CANNOT hold a φ by TYPE (`CallInst *` / `StoreInst *` / `BasicBlock *`
        // / `Function *` keys), which cannot by WRITER (`StaleDeclined`, whose
        // `inLowerOpsScope` admits no `PHINode`), and which cannot only by STAGE
        // ORDER (`LiftedConsumers`, empty until `declineClassicalMuxes` runs
        // AFTER both peel sites; the member is removed since bd ec7r) — is in
        // `IMPL_b6ap.md` §2d, with the two
        // retirement triggers it found (that one, and P9's `BreakRegions` above).
        taint.Tainted.erase(Phi);
        Phi->eraseFromParent();
        Changed = true;
      }
    }
  }
  // ── FORWARD RE-PROPAGATION ──────────────────────────────────────────────
  //
  // The peel inserts tainted instructions AFTER `propagate` has run, so their
  // transitive users must be re-taken through the SHIPPED rule — never a second
  // spelling of it (Rule 14). `propagateFromSeeds` is that one walk
  // (`TaintPropagation.cpp`), the same `propagateWorklist` the 6.5/4.5 round-2
  // reseed uses. Run ONCE for the whole module: the walk is a fixpoint over the
  // user graph, so batching is exactly equivalent to per-site calls and costs one
  // FnSet rebuild instead of N.
  //
  // Idempotent when nothing was peeled (`Seeds` empty ⇒ immediate return), which
  // is what keeps the 1776-fixture corpus byte-identical.
  //
  // ⚠ AND THE GROWTH IS REPORTED, because growing taint here is only HALF the
  // obligation — bd b6ap Rule-13 round-1 finding F-B6-1. `detectSpecializations`,
  // `declineTaintEscapes` and `declineStaleRecordOps` are pure-analysis pre-passes
  // that ran ~90 lines earlier on the premise that `propagate` had settled; every
  // value this stage makes quantum is a value they never adjudicated. The caller
  // closes that with `adjudicateTaintDelta` (see `MergePhiPeel.h` and
  // `TaintPropagation.h`). Nothing here diagnoses — this stage stays ACCEPT-ONLY;
  // the DELTA it hands back is what makes the existing loud owners loud again.
  propagateFromSeeds(taint, Seeds, Delta);
  return Changed;
}

}  // namespace cq
