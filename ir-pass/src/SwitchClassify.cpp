// SwitchClassify.cpp — the §0 prove-or-decline ladder for a tainted-condition
// `switch` (swap-route 4.5 WI-1; PRD Part V §20.7; IMPLEMENTATION-4.5 §3).
// See SwitchClassify.h for the contract.
//
// Pure SSA/CFG analysis — NO IR is mutated (Rule 9). Detection runs at the
// pipeline's `detectControlRegions` step (L83), before rotation lowering's
// RAUW-to-handle (L110), so the scrutinee, the case literals, and each arm's
// `cq_phi`/`cq_theta` calls still carry their real logical identity.
//
// `soleMergePhi` (ControlDetect.cpp) hard-requires a 2-incoming merge and is
// useless for an N-way switch merge, so the merge-block + sole-content-phi
// recovery here is its own N-incoming recognizer.

#include "SwitchClassify.h"

#include "ArmAnalysis.h"       // (per-class proofs reuse the lineage walks)
#include "ControlPlan.h"       // diagnoseUnderControl, ControlPlan, SwitchClass
#include "OpcodeSupport.h"     // abiWidthFromType
#include "SwitchArmProve.h"    // SwitchShape, caseArmClass, proveSwitch*
#include "TaintPropagation.h"  // TaintSet
#include "WireWalk.h"          // findNonDiagonalWireGate

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Type.h"

using namespace llvm;

namespace cq {

namespace {

// TU-local intrinsic-call predicates (re-derived; collide if promoted —
// ArmAnalysis.h note).
bool isCallToPrefix(const Value *V, StringRef Prefix) {
  const auto *CI = dyn_cast<CallInst>(V);
  if (!CI)
    return false;
  const Function *F = CI->getCalledFunction();
  return F && F->getName().starts_with(Prefix);
}
// ⚠ VACUOUS SINCE bd test_C_libtooling-3qlq Inc 1 (2026-09-05), AND DELIBERATELY
// KEPT (PRD `retire-swap-route-PRD.md` §6.2 row P6: "every 'Rz is diagonal and
// exempt' clause becomes VACUOUS rather than deleted").
//
// The 15-width `@cq_phi_<sfx>(x, angle)` family is RETIRED: `CQ.h` no longer
// declares it and `resolveSources` no longer resolves it, so no call this
// predicate can match exists in a module the pass lowers. It CANNOT accidentally
// match the register-free replacement, and that is a fact about the strings, not
// a hope: `StringRef("cq_phi").starts_with("cq_phi_")` is FALSE — six characters
// against a seven-character prefix. The new call is recognized by EXACT
// membership instead (`TaintPropagation.h`'s `isRegisterFreePhaseCall`), which is
// also the project's standing accept-side discipline (never a name prefix — the
// `cq_theta_evil` hazard).
//
// KEEPING IT IS THE POINT: a `void(double)` call has no arg-0 WIRE and no arg-1
// ANGLE, so every clause below that follows `getArgOperand(0)` as a rail, or
// reads `getArgOperand(1)` as an angle, would be reading the wrong operand — or
// out of range — if this predicate were widened to admit it. Do not "fix" this by
// making it match `cq_phi`.
bool isPhiCall(const Value *V) { return isCallToPrefix(V, "cq_phi_"); }
bool isThetaCall(const Value *V) { return isCallToPrefix(V, "cq_theta_"); }
bool isRotationCall(const Value *V) { return isPhiCall(V) || isThetaCall(V); }

// G3 (the §3.2 BLOCKER, modeled on `selReachesRotationArg1`) — does the merge phi
// `P`'s value reach a rotation's arg-1 ANGLE slot through value-preserving
// carriers? There is NO downstream backstop (`declineTaintedAngle` runs after the
// emitter RAUWs the merge to an untainted handle), so the angle MUST be caught
// here. The carriers are exactly the value-preserving subset
// `declineTaintEscapes` whitelists (fpext/fptrunc/bitcast + nested phi/select
// value operand); every other path is loudly backstopped before a miscompile can
// form. The per-use arg-1 predicate (`getArgOperand(1)==U && getArgOperand(0)!=U`)
// matches Rule 3's per-operand-use angle exclusion. The FAN-OUT rule: a single
// arg-1 reach declines the WHOLE switch.
bool mergeReachesRotationArg1(PHINode *P) {
  SmallVector<Value *, 8> Work;
  SmallPtrSet<Value *, 16> Visited;
  Work.push_back(P);
  Visited.insert(P);
  while (!Work.empty()) {
    Value *U = Work.pop_back_val();
    for (User *X : U->users()) {
      if (auto *CI = dyn_cast<CallInst>(X))
        if (isRotationCall(CI) && CI->arg_size() >= 2 &&
            CI->getArgOperand(1) == U && CI->getArgOperand(0) != U)
          return true;  // angle — decline the whole switch (fan-out rule).
      // COMPLETE forward value-flow (NOT just value-preserving carriers). Unlike
      // the 4.4 select — backstopped by SelectMergeEmit re-tainting %out, so
      // declineTaintedAngle re-catches a value-changing path at L110 — the switch's
      // merge result has NO downstream backstop (the emitter RAUWs it to an
      // untainted handle before L110). So G3 must cross EVERY value-deriving user:
      // any cast (incl. int<->fp + width casts), arithmetic/bitwise binop, unary
      // op, or phi — else `(double)(merge ^ 5)` feeding an angle slips through (the
      // f64/angle miscompile family, Rule 3). The arg-1 check above flags ONLY a
      // genuine angle reach, so crossing arithmetic costs no legitimate accept (a
      // clean phase/value switch never routes the merge into an angle slot).
      if (isa<CastInst>(X) || isa<BinaryOperator>(X) || isa<UnaryOperator>(X) ||
          isa<PHINode>(X)) {
        if (Visited.insert(X).second)
          Work.push_back(X);
      } else if (auto *Inner = dyn_cast<SelectInst>(X)) {
        if (U != Inner->getCondition() && Visited.insert(Inner).second)
          Work.push_back(Inner);
      }
    }
  }
  return false;
}

// The sole PHINode of `M`, or null if `M` has not exactly one (the N-incoming
// analog of `soleMergePhi` — N>2 incomings are allowed here, but >1 phi is the
// multi-phi C1 decline and 0 phis is off-pattern).
PHINode *soleSwitchMergePhi(BasicBlock *M) {
  PHINode *Found = nullptr;
  for (PHINode &P : M->phis()) {
    if (Found)
      return nullptr;  // ≥2 phis — C1 multi-phi.
    Found = &P;
  }
  return Found;
}

// `Succ` resolved as a switch successor: a GATE ARM (single-pred = `SwitchBB`,
// ends in an unconditional branch) yields its branch target as the merge
// candidate (and `Succ` as the arm block); a successor reached straight (the edge
// IS the merge edge) yields `Succ` itself as the merge candidate. Returns false
// (off-pattern) for a self-loop, a multi-pred arm, or an arm not ending in an
// unconditional branch.
struct ArmShape {
  BasicBlock *Block = nullptr;  // null when the edge goes straight to the merge.
  BasicBlock *MergeCand = nullptr;
};
bool resolveArm(BasicBlock *Succ, BasicBlock *SwitchBB, BasicBlock *MergeHint,
                ArmShape &Out) {
  if (Succ == SwitchBB)
    return false;  // self-loop — off-pattern.
  // A gate arm: single-pred(SwitchBB), single unconditional successor.
  if (Succ->getSinglePredecessor() == SwitchBB) {
    if (auto *BI = dyn_cast<BranchInst>(Succ->getTerminator());
        BI && BI->isUnconditional()) {
      Out.Block = Succ;
      Out.MergeCand = BI->getSuccessor(0);
      return true;
    }
    // single-pred but not a clean uncond arm — off-pattern (e.g. the case body
    // hosts a tainted br / switch; the explicit G11 check below also catches it).
    return false;
  }
  // Not single-pred(SwitchBB): the edge goes straight to a shared block — the
  // merge itself (the merge has several predecessors).
  (void)MergeHint;
  Out.Block = nullptr;
  Out.MergeCand = Succ;
  return true;
}

}  // namespace

void classifySwitchRegion(SwitchInst *SI, TaintSet &taint, ControlPlan &plan) {
  // G0 — entry: only tainted-scrutinee switches are ours (caller-guarded;
  // re-checked defensively). A classical-scrutinee switch is left byte-untouched.
  Value *Q = SI->getCondition();
  if (!taint.Tainted.count(Q))
    return;

  // (No separate per-case flag-mintability gate is needed — the §3 ladder's "G2"
  // is subsumed by G0 + the taint-seed invariant: a scrutinee is tainted only if it
  // descends from a @cq_theta_<sfx> of a SUPPORTED width (TaintPropagation seeds
  // taint solely from recognized integer suffixes {i1,i8,i16,i32,i64}; fp cannot
  // index a switch). The case literals share the scrutinee's width, so
  // abiWidthFromType(case literal) is always non-empty and emitEqFlag's width gate
  // always succeeds.)
  BasicBlock *SwitchBB = SI->getParent();

  // G9 — grouped fall-through: ≥2 case values targeting one successor block. The
  // per-value-flag routing is deferred (PRD §20.9); v1 declines generic.
  // G11 — a case body that is itself a tainted-control region (a nested tainted
  // br / switch) is deeper than the 4.3 nest; decline generic.
  DenseMap<BasicBlock *, unsigned> SuccValueCount;
  for (auto Case : SI->cases()) {
    BasicBlock *Succ = Case.getCaseSuccessor();
    if (++SuccValueCount[Succ] >= 2)
      return diagnoseUnderControl(SI, "control flow");  // G9 grouped.
    Instruction *T = Succ->getTerminator();
    if (isa<SwitchInst>(T))
      return diagnoseUnderControl(SI, "control flow");  // G11 nested switch.
    if (auto *BI = dyn_cast<BranchInst>(T))
      if (BI->isConditional() && taint.Tainted.count(BI->getCondition()))
        return diagnoseUnderControl(SI, "control flow");  // G11 nested br.
  }

  // ---- Structural recovery: the single common merge block ----
  BasicBlock *MergeBB = nullptr;
  auto unify = [&](BasicBlock *M) {
    if (!MergeBB)
      MergeBB = M;
    return MergeBB == M;
  };
  SmallVector<std::pair<ConstantInt *, BasicBlock *>, 4> CaseArmBlocks;
  for (auto Case : SI->cases()) {
    ArmShape AS;
    if (!resolveArm(Case.getCaseSuccessor(), SwitchBB, MergeBB, AS) ||
        !unify(AS.MergeCand))
      return diagnoseUnderControl(SI, "control flow");
    CaseArmBlocks.push_back({Case.getCaseValue(), AS.Block});
  }
  if (!MergeBB)
    return diagnoseUnderControl(SI, "control flow");  // no cases — off-pattern.

  // The default edge: direct to the merge (empty default — the lowerable shape),
  // or an explicit default body (C5 — the sanctioned ¬OR default-flag is excised;
  // decline generic), or unrelated (off-pattern).
  BasicBlock *DefaultDest = SI->getDefaultDest();
  bool DefaultDirect = (DefaultDest == MergeBB);
  if (!DefaultDirect)
    return diagnoseUnderControl(SI, "control flow");  // C5 non-empty default.

  // G1 — the sole content merge phi (N-incoming; >1 phi is the multi-phi C1
  // decline, 0 phis is off-pattern).
  PHINode *P = soleSwitchMergePhi(MergeBB);
  if (!P)
    return diagnoseUnderControl(SI, "control flow");

  // The straight-through value: the phi incoming on the SwitchBB→MergeBB edge (the
  // empty default + any straight-to-merge case share this one predecessor edge).
  int STIdx = P->getBasicBlockIndex(SwitchBB);
  if (STIdx < 0)
    return diagnoseUnderControl(SI, "control flow");  // no straight-through edge.
  Value *StraightThrough = P->getIncomingValue(STIdx);

  // Build the recovered shape (content = gate-arm cases; empty cases share the
  // straight-through edge and contribute no distinct incoming).
  SwitchShape S;
  S.SI = SI;
  S.SwitchBB = SwitchBB;
  S.MergeBB = MergeBB;
  S.Merge = P;
  S.StraightThrough = StraightThrough;
  S.DefaultDirect = DefaultDirect;
  bool SawContent = false;
  for (auto &CB : CaseArmBlocks) {
    SwitchCase SC;
    SC.Value = CB.first;
    SC.Block = CB.second;
    if (SC.Block) {
      int Idx = P->getBasicBlockIndex(SC.Block);
      if (Idx < 0)
        return diagnoseUnderControl(SI, "control flow");  // arm not a phi pred.
      SC.Incoming = P->getIncomingValue(Idx);
    } else {
      SC.Incoming = StraightThrough;  // straight-to-merge case = passthrough.
    }
    if (SC.Incoming != StraightThrough)
      SawContent = true;
    S.Cases.push_back(SC);
  }
  if (!SawContent)
    return diagnoseUnderControl(SI, "control flow");  // identity/no-op switch.

  // Foreign-predecessor guard: the merge phi's incoming blocks must be EXACTLY the
  // region edges — the switch block (the empty default + any straight-to-merge
  // case) and the resolved case-arm blocks. A FOREIGN predecessor (the merge is
  // also some unrelated branch's join) carries a distinct incoming that would be
  // silently dropped — and its control edge left dangling into a rewritten merge —
  // when WI-2/3/4 dissolves the N-way phi and flattens the diamond (the
  // "unlowerable merge phi must DECLINE, never dangle" hazard). The br-diamond path
  // gets this for free from soleMergePhi's 2-incoming bound; the N-way recovery had
  // to drop that, so re-impose it here. Over-decline is always safe (Rule 9).
  SmallPtrSet<const BasicBlock *, 8> RegionPreds;
  RegionPreds.insert(SwitchBB);
  for (auto &CB : CaseArmBlocks)
    if (CB.second)
      RegionPreds.insert(CB.second);
  for (const BasicBlock *PB : P->blocks())
    if (!RegionPreds.count(PB))
      return diagnoseUnderControl(SI, "control flow");

  // Uniform passthrough-arm purity (all classes, single source of truth). A case
  // whose merge incoming IS the straight-through routes the scrutinee/base
  // unchanged, so its resolved arm block (if any) must be EMPTY. The per-class
  // proofs SKIP passthrough cases (their content-arm spine/chain scans only run on
  // content arms), and the G10 scrutinee scan + the foreign-pred guard cannot see a
  // stray side-effecting op on a SIBLING handle inside such a block — yet the
  // flatten would silently drop it: a vanishing user measurement (Rule 5) + a
  // dangling taint-work-list pointer (UAF). Scan every passthrough arm block here,
  // uniformly, before per-class dispatch. (Content arms with a body are handled by
  // their per-class purity proof; a genuine straight-to-merge passthrough has a
  // null block and is correctly empty.)
  for (const SwitchCase &C : S.Cases)
    if (C.Incoming == StraightThrough && C.Block)
      for (const Instruction &I : *C.Block)
        if (!I.isTerminator())
          return diagnoseUnderControl(SI, "control flow");

  // G3 — the angle BLOCKER, FIRST among the type gates (the FP-use fence precedes
  // the width gate, exactly as ArmClassify.cpp:820 precedes :834). No backstop.
  if (mergeReachesRotationArg1(P))
    return diagnoseUnderControl(SI, "rotation angle");

  // G4 — ABI-width scalar-integer merge, AFTER the FP-use fence. Rejects fp-as-data
  // / vector / i128 / pointer / aggregate (the f64 trap: f64 has a valid width yet
  // is an angle, so never key on width alone). `isFPOrFPVectorTy`, not the
  // scalar-only `isFloatingPointTy` (which misses `<2 x double>`).
  Type *T = P->getType();
  // n0ui Tier-1: `widthHasReversibleCopy`, NOT `.empty()` — i128 is a recognized
  // intermediate width with no `cqrt_copy_i128`, so a tainted i128 switch data-mux
  // must still DECLINE here (the same fence as SelectClassify GATE 4).
  if (T->isFPOrFPVectorTy() || !T->isIntegerTy() ||
      !widthHasReversibleCopy(abiWidthFromType(T)))
    return diagnoseUnderControl(SI, "control flow");

  // G5 — homogeneity: every CONTENT arm shares one content class. Mixed declines.
  SwitchClass Cls = SwitchClass::Phase;
  bool ClsSet = false;
  for (const SwitchCase &C : S.Cases) {
    if (C.Incoming == StraightThrough)
      continue;
    SwitchClass AC = caseArmClass(C.Incoming, C.Block);
    if (!ClsSet) {
      Cls = AC;
      ClsSet = true;
    } else if (AC != Cls) {
      return diagnoseUnderControl(SI, "mixed phase/value arm");
    }
  }

  // G6 — the per-class base/operand proof (fires its own precise decline).
  bool Accept = false;
  switch (Cls) {
  case SwitchClass::Phase:
    Accept = proveSwitchPhase(S, taint);
    break;
  case SwitchClass::Value:
    Accept = proveSwitchValue(S, taint);
    break;
  case SwitchClass::DataMux:
    Accept = proveSwitchDataMux(S, taint);
    break;
  }
  if (!Accept)
    return;  // the proof already fired the precise diagnostic.

  // G10 — scrutinee data-use discipline (v1 floor, IMPLEMENTATION-4.5 open-Q-9).
  // A non-diagonal (Ry/theta) gate on the scrutinee's wire would change `q`'s
  // basis around the switch, so the eq-flags read a stale value.
  // CrossValueRouting=TRUE since bd tayx (2026-07-03): a chained theta whose
  // arg-0 reaches the scrutinee's wire only through a one-register router phi
  // ON AN OLD ALIAS (`q = theta(q0)`; router of `q0`) evaded the router-blind
  // walk AND the unowned-data-use scan below (which covers users of `q` only,
  // never `q0`'s) — the phase switch was accepted and every eq-flag minted
  // AFTER the hidden Ry (verify-clean stale scrutinee; pinned by
  // control_swap_reject_switch_stalecond_router.ll). A router forwards the
  // same physical handle; cross it.
  if (findNonDiagonalWireGate({Q}, /*CrossValueRouting=*/true))
    return diagnoseUnderControl(SI, "condition predates a non-diagonal gate");
  // An UNOWNED data use of the scrutinee (not the switch, not the merge phi, not
  // an escape `ret`, not a measurement) leaves a dirty/entangled rail with no
  // owner; decline conservatively.
  //
  // The measurement allowlist is EXACT-MEMBERSHIP against `taint.MeasureCalls`
  // (the recognized `@cq_measure_<sfx>` call sites), NOT a `starts_with(
  // "cq_measure_")` prefix match — mirrors `proveSwitchDataMux`'s sink test and
  // `isMeasureSink`/`declineTaintEscapes`. Prefix-on-accept is spoofable: an
  // opaque `cq_measure_evil` would confer false ownership of a live scrutinee
  // use. Here `Q` is ALWAYS tainted, so `declineTaintEscapes` (L64, pre-
  // detection) has already rejected any unknown-callee user before G10 runs — on
  // this tainted operand the two tests are equivalent, so the exact check is
  // consistency + defense-in-depth (Rule 14, not re-derive the masking
  // coincidence). The runtime `cqrt_measure_` prefix is correctly NOT matched
  // either — it is a compiler-emitted symbol absent pre-detection.
  SmallPtrSet<const CallInst *, 8> Sinks(taint.MeasureCalls.begin(),
                                         taint.MeasureCalls.end());
  for (User *X : Q->users()) {
    if (X == SI || X == P)
      continue;
    if (isa<ReturnInst>(X))
      continue;  // escapes via `ret` — the caller owns it.
    if (const auto *CI = dyn_cast<CallInst>(X))
      if (Sinks.count(CI))
        continue;  // a recognized measurement sink owns the handle.
    return diagnoseUnderControl(SI,
                                "condition data use neither escaped nor measured");
  }

  // ACCEPT — the whole switch is proven. The PHASE (WI-2), VALUE (WI-3), and
  // DATA-MUX (WI-4) emitters are all landed (`emitSwitchPhaseRegion` /
  // `emitSwitchValueRegion` / `emitSwitchDataMuxRegion`): push the region for
  // `lowerControlRegions`, which dispatches by `R.SwitchCls`.
  ControlRegion R;
  R.Kind = ControlRegion::SwitchRegion;
  R.SwitchCls = Cls;
  R.Condition = Q;            // the scrutinee. For PHASE it IS the routed base
                              // (§4A); for VALUE/DATA-MUX it is ONLY the eq-flag
                              // source — the routed base is `p` = the merge
                              // straight-through, recovered in the emitter, NOT
                              // R.Condition (WI-7 Lens-4 clarification).
  R.Merge = P;                // the sole N-incoming content merge phi.
  R.Pred = SwitchBB;          // the switch block (survives the flatten).
  R.MergeBB = MergeBB;
  R.SwitchDefaultDirect = DefaultDirect;
  // Capture every case-arm BLOCK (incl. an empty passthrough arm whose incoming
  // is just the scrutinee) so `flattenSwitchRegion` erases them all; the emitter
  // skips an arm with no folded gates (`collectArmPhis` empty). A straight-to-
  // merge case has a null block — no block to route or flatten — so skip it.
  for (const SwitchCase &C : S.Cases) {
    if (!C.Block)
      continue;
    SwitchArm A;
    A.Values.push_back(C.Value);
    A.Block = C.Block;
    R.SwitchArms.push_back(A);
  }
  plan.Regions.push_back(R);
}

}  // namespace cq
