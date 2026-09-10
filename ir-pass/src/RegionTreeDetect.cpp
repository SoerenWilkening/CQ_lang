// RegionTreeDetect.cpp — Depth-2 nested-control region-tree recovery.
// See RegionTreeDetect.h for the contract and the criterion order.
//
// Invoked from ControlDetect's `case RegionShape::Nested:` (where the blanket
// `nested control flow` decline lived). Proves the §0 depth-2 homogeneous-phase
// nest by SSA-value identity (Rule 9) or declines loudly with the §5h per-shape
// string. WI-1 lands DETECTION ONLY: an Accepted nest declines transitionally via
// the existing `nested control flow` string at the call site (no emitter yet),
// while the inner branch is recorded in `Claimed` (FA0) for WI-3.

#include "RegionTreeDetect.h"

#include "ArmAnalysis.h"
#include "ArmHomogeneity.h"
#include "ControlPlan.h"
#include "ControlShape.h"
#include "TaintPropagation.h"
#include "WireWalk.h"        // findNonDiagonalWireGate (per-level stale guard)

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"          // llvm::successors
#include "llvm/IR/Dominators.h"   // llvm::DominatorTree (the backedge guard)
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

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

// The bottom of `V`'s backward `cq_phi` arg-0 chain — the diagonal-alias base
// (criterion 4). Rz is diagonal, so rotation lowering RAUWs every link on this
// chain to one i32 handle; two merge incomings agree iff their bases are
// identical. A `cq_theta`/Ry or value-op incoming bottoms at itself (NOT the
// routed base) → distinct base → criterion 4 declines.
Value *diagonalBase(Value *V) {
  while (isPhiCall(V)) {
    auto *CI = cast<CallInst>(V);
    if (CI->arg_size() < 1)
      break;
    V = CI->getArgOperand(0);
  }
  return V;
}

// ziov.3: does the tainted control compare `Cond` feed any NON-branch (data)
// position? A condition reused as data (`int f=(q>5)` beside `if(q>5)`; clang -O1
// CSEs the two to one `icmp` with a `br` + a data user) is the cond-data-use shape
// the flat phase path SHARES one flag for (`condDataUseDisposition` → ShareOk).
bool condHasDataUse(const Value *Cond) {
  for (const User *U : Cond->users())
    if (!isa<BranchInst>(U))
      return true;
  return false;
}

}  // namespace

NestDisposition recoverRegionTree(
    BranchInst *OuterBI, TaintSet &Taint, ControlPlan &Plan,
    SmallPtrSetImpl<BranchInst *> &Claimed) {
  BasicBlock *Pred = OuterBI->getParent();
  BasicBlock *S0 = OuterBI->getSuccessor(0);
  BasicBlock *S1 = OuterBI->getSuccessor(1);
  const bool T0 = hasTaintedCondBranch(S0, Taint);
  const bool T1 = hasTaintedCondBranch(S1, Taint);

  // Criterion 1 — outer ONE-CONTENT-ARM diamond. Exactly one outer successor is
  // the inner (Mid) diamond; the other is the shared merge reached straight from
  // Pred. BOTH tainted-branch (an if/else both-arm nest — not a one-content-arm
  // diamond, §12.4 inv-(i)) OR NEITHER (the sequential `if/else; if` reaching
  // here via the if/else merge's tainted branch) → decline `nested control flow`.
  if (T0 == T1)
    return diagnoseUnderControl(OuterBI, "nested control flow"),
           NestDisposition::Declined;

  BasicBlock *Mid = T0 ? S0 : S1;
  BasicBlock *Merge = T0 ? S1 : S0;  // outer straight-through successor.

  // Criterion 7 (part) — the outer single-pred invariant (`Arm`/`Mid` reached
  // ONLY from Pred; a sequential layout sharing Mid fails this).
  if (Mid->getSinglePredecessor() != Pred)
    return diagnoseUnderControl(OuterBI, "nested control flow"),
           NestDisposition::Declined;

  // Inner diamond — Mid's terminator is the inner conditional branch (guaranteed
  // conditional + tainted by `hasTaintedCondBranch`).
  auto *InnerBI = cast<BranchInst>(Mid->getTerminator());
  BasicBlock *IS0 = InnerBI->getSuccessor(0);
  BasicBlock *IS1 = InnerBI->getSuccessor(1);

  // The inner content arm is single-pred(Mid) and falls through UNCONDITIONALLY
  // to the SAME outer merge; the other inner successor IS that merge. This also
  // enforces the depth-2 cap (criterion 2): a depth-3 inner arm ends in a tainted
  // br, so `uncondSucc` is null and neither orientation matches → decline.
  BasicBlock *InnerArm = nullptr;
  if (IS1 == Merge && uncondSucc(IS0) == Merge &&
      IS0->getSinglePredecessor() == Mid)
    InnerArm = IS0;
  else if (IS0 == Merge && uncondSucc(IS1) == Merge &&
           IS1->getSinglePredecessor() == Mid)
    InnerArm = IS1;
  else
    return diagnoseUnderControl(OuterBI, "nested control flow"),
           NestDisposition::Declined;

  // LOOP GUARD (WI-1 forward note / Rule 6 — the backedge live-range hazard). A
  // loop-resident nest (the routed base is a loop-carried phi, or the region sits
  // on a backedge) has no proven sound swap-route lowering in 4.3: the emitter's
  // emitter-driven LIFO frees + 3-incoming-phi erase run BEFORE — and BYPASS — the
  // `FreePoint` / `declineClassicalMuxes` backedge guards the flat path defers to
  // ("tainted value muxed by a classical-condition phi"). So detection must
  // re-check here, exactly as the flat path relies on those guards. Decline if any
  // region edge is a backedge — a successor that DOMINATES its source (the textbook
  // backedge test). Realistic loop nests are ALSO caught incidentally by criterion
  // 5's provenance cycle (the backedge pulls the inner-arm gate, a non-closure
  // `cq_phi`, into the inner condition's provenance). SCOPE (WI-5 §8 review, NIT —
  // do NOT over-trust this): this check inspects only edges OUT of the region
  // block-set {Pred, Mid, InnerArm, Merge}, so it catches backedges INTERNAL to the
  // region. A loop whose latch lies OUTSIDE that set (Merge → latch → header, latch
  // ∉ set) is NOT inspected here and lowers — but ONLY soundly, because a phase nest
  // self-cleans within the body (no rail/flag handle crosses the backedge; all four
  // `cqrt_free` land inside the region), the SAME accepted-leak disposition the flat
  // 4.1 path gives the identical "control region inside a fresh-θ loop" shape. When
  // value-arm nests land, a loop-carried DIRTY rail WOULD be a Rule-6 collapse — this
  // guard must then be WIDENED to all reachable backedges, not assumed complete.
  // Fresh DT per call (never reuse across levels — §12.4). All four §5g/§5h-accept
  // shapes are acyclic → no false decline.
  DominatorTree DT(*Pred->getParent());
  for (BasicBlock *B : {Pred, Mid, InnerArm, Merge})
    for (BasicBlock *S : successors(B))
      if (DT.dominates(S, B))
        return diagnoseUnderControl(OuterBI, "nested control flow"),
               NestDisposition::Declined;

  // Per-level polarity (Rule 9 — clang -O1 may make either gate arm the FALSE
  // successor; the emitter routes a negated level on ¬flag via the cqrt_x
  // bracket). The OUTER gate arm `Mid` is the false successor iff it was S1 (i.e.
  // the tainted branch was on S1, so !T0); the INNER content arm is the false
  // successor iff it was IS1. Resolved by SSA/successor identity, never edge
  // truth — the emitter pairs them against the 3-incoming phi incomings.
  const bool OuterNeg = !T0;
  const bool InnerNeg = (InnerArm == IS1);

  // Criterion 3 — exactly one merge phi. Two phis (the inner cond/arm on distinct
  // registers, real `-O1`) → `control flow`.
  PHINode *MergePhi = nullptr;
  unsigned NumPhi = 0;
  for (PHINode &P : Merge->phis()) {
    MergePhi = &P;
    ++NumPhi;
  }
  if (NumPhi != 1)
    return diagnoseUnderControl(OuterBI, "control flow"),
           NestDisposition::Declined;

  // Criterion 2 (cap) — exactly 3 incomings, exactly {Pred, Mid, InnerArm}.
  if (MergePhi->getNumIncomingValues() != 3 ||
      MergePhi->getBasicBlockIndex(Pred) < 0 ||
      MergePhi->getBasicBlockIndex(Mid) < 0 ||
      MergePhi->getBasicBlockIndex(InnerArm) < 0)
    return diagnoseUnderControl(OuterBI, "nested control flow"),
           NestDisposition::Declined;

  Value *QPred = MergePhi->getIncomingValueForBlock(Pred);   // %q
  Value *GMid = MergePhi->getIncomingValueForBlock(Mid);     // %g (routed to rail1)
  Value *HArm = MergePhi->getIncomingValueForBlock(InnerArm);  // %h
  Value *InnerCond = InnerBI->getCondition();

  // ziov.3 — Q/C-BOUNDARY COND-DATA-USE on a nested condition (the flat path's
  // `ArmClassify::condDataUseDisposition`, applied to BOTH nest levels). A tainted
  // control compare ALSO read as data (`int f=(q>5)`; clang -O1 CSEs the two to one
  // `icmp` with a `br` + a data user) is a cond-data-use: the flat 4.1 phase path
  // SHARES ONE physical flag (mint once, route + feed the data use, skip the
  // strip+free — ziov WI-1). `NestedRouteEmit` does NOT yet share, so left
  // unchecked it (i) DUPLICATE-MINTS on an OUTER cond-data-use — `flattenRegionTree`
  // keeps the live data compare (use_empty() false), then `lowerOps` mints a
  // SECOND, leaked, entangled-with-q flag (verify-clean qubit leak, reachable from
  // clang -O1); or (ii) (the inner level) would dangle a live use of the Mid gate
  // the flatten erases. Apply the SAME disposition predicate the flat path uses,
  // keyed on each region's route block (outer = `Pred`, inner = `Mid`), and decline
  // LOUDLY HERE — in detection, before `NestedRouteEmit` mutates (Prime Directive;
  // over-declining is always safe). BEFORE criterion 6 so the precise cond-data-use
  // string fires rather than the arm-content `impure phase arm` an inner data use
  // would otherwise hit (an in-`Mid`/`InnerArm` data op is a homogeneity stray);
  // no existing reject fixture reuses a condition as data, so no message regresses.
  // Nested flag-SHARING is a later WI: when it lands the `ShareOk` arm flips from
  // decline to a shared-flag accept. Pure SSA analysis (Rule 9); diagnostics
  // anchored on `OuterBI` like every other nested decline, messages mirror the flat
  // path char-for-char.
  auto declineCondDataUse = [&](Value *CondV, const BasicBlock *Route) -> bool {
    auto *Cond = dyn_cast<Instruction>(CondV);
    if (!Cond || !condHasDataUse(Cond))
      return false;
    switch (condDataUseDisposition(Cond, Route, Taint)) {
    case CondDataDisp::ShareOk:
      // A shareable cond-data-use, but `NestedRouteEmit` has no shared-flag path
      // yet — decline (the flat VALUE-arm path declines a `ShareCondFlag` region
      // with the SAME string). The later nested-sharing WI flips this to accept.
      diagnoseUnderControl(OuterBI, "condition used outside the branch");
      return true;
    case CondDataDisp::MeasuredEarly:
      diagnoseUnderControl(OuterBI,
                           "condition measured before the control route");
      return true;
    case CondDataDisp::Unowned:
      diagnoseUnderControl(OuterBI,
                           "condition data use neither escaped nor measured");
      return true;
    case CondDataDisp::Unlowerable:
      // A data cast on the lineage has no template (unsupported width /
      // out-of-scope pair) — the nested path already declines every cond-data-use
      // before `NestedRouteEmit` mutates, so this only sharpens the reason from
      // the generic "used outside the branch" to the precise cause (ziov.4).
      diagnoseUnderControl(OuterBI, "condition data use has no template");
      return true;
    }
    return true;  // exhaustive switch — silence -Wreturn-type.
  };
  if (declineCondDataUse(OuterBI->getCondition(), Pred) ||
      declineCondDataUse(InnerCond, Mid))
    return NestDisposition::Declined;

  // jvun — CONTROL-CONDITION predicate scope (outer AND inner). An out-of-scope
  // fcmp predicate has no flag template; the OUTER mint is `NestedRouteEmit` step
  // 1 (null-bails clean) but the INNER mint follows the outer rail alloc + route +
  // replay, so an out-of-scope inner condition would MUTATE-then-decline. Decline
  // BOTH here, in detection, before any emit (Rule 9 detect-before-mutate). The
  // conditions are tainted `br` operands the nest proved are `CmpInst`s (the flag
  // mints cast to `CmpInst`); guard the cast defensively all the same.
  auto declineUnlowerableCond = [&](Value *CondV) -> bool {
    auto *Cmp = dyn_cast<CmpInst>(CondV);
    if (Cmp && !comparePredLowerable(Cmp)) {
      diagnoseUnderControl(OuterBI, "control condition has no template");
      return true;
    }
    return false;
  };
  if (declineUnlowerableCond(OuterBI->getCondition()) ||
      declineUnlowerableCond(InnerCond))
    return NestDisposition::Declined;

  // Criterion 6 — TREE HOMOGENEITY (before RAUW-collapse, FA2). Any value arm →
  // `mixed phase/value arm` / `value-arm swap-route`; a Mid stray → `impure phase
  // arm`; a tainted angle → `rotation angle`. (A non-`cq_phi` intervening Mid gate
  // — cq_theta/Ry — is a phase-leaf here, so homogeneity PASSES it through; it
  // declines below at RAUW-collapse, `control flow`.)
  if (!treeHomogeneous(Mid, GMid, InnerCond, InnerArm, HArm, Taint, OuterBI))
    return NestDisposition::Declined;

  // Criterion 4 — N-incoming RAUW-collapse: every merge incoming bottoms at one
  // base through the `cq_phi` diagonal-alias closure. A distinct independently-
  // derived base, or a non-diagonal (cq_theta) intervening gate, → `control flow`.
  Value *BasePred = diagonalBase(QPred);
  if (diagonalBase(GMid) != BasePred || diagonalBase(HArm) != BasePred)
    return diagnoseUnderControl(OuterBI, "control flow"),
           NestDisposition::Declined;

  // Criterion 5 — MINT-FROM-RAIL (the load-bearing binding signal). The inner
  // condition must be a function of ONLY the parent-routed value `%g` (the value
  // physically on rail1 post-route-in) and classical constants — so the inner
  // flag can be minted `icmp(rail1, k)`. Build `%g`'s diagonal-alias closure (the
  // backward `cq_phi` arg-0 chain) and require EVERY quantum-register LEAF in the
  // inner condition's provenance — a `cq_theta` source or a pre-region `cq_phi`
  // handle — to lie in it. A SECOND quantum register (`icmp((%g+%r),9)` /
  // `(%g*0)+%r`) leaves `%r` (a `cq_theta`) outside the closure → decline `nested
  // control flow`: minting from rail1 (which holds only `%g`) cannot evaluate a
  // predicate that depends on off-rail `%r` — a verify-clean wrong predicate (the
  // multi-register false-accept, criterion 4 passes since the merge is all
  // `%g`-lineage). Derivation intermediates (add/mul/icmp/cast — themselves in
  // the provenance) are functions of their operands and are NOT required to be in
  // the closure (else the canonical derived cond `icmp(%g,9)` would over-decline).
  // A single membership hit is INSUFFICIENT — the WHOLE quantum lineage must be
  // contained (the §8 over-accept fix, adversarial review 2026-06-12).
  SmallPtrSet<const Value *, 8> RailClosure;
  for (Value *V = GMid;;) {
    RailClosure.insert(V);
    if (!isPhiCall(V))
      break;
    auto *CI = cast<CallInst>(V);
    if (CI->arg_size() < 1)
      break;
    V = CI->getArgOperand(0);
  }
  SmallPtrSet<Value *, 16> InnerProv;
  condProvenance(InnerCond, Taint, InnerProv);
  for (Value *V : InnerProv)
    if ((isThetaCall(V) || isPhiCall(V)) && !RailClosure.count(V))
      return diagnoseUnderControl(OuterBI, "nested control flow"),
             NestDisposition::Declined;

  // Criterion 5, STRENGTHENED (§8 adversarial review 2026-06-12 — a REAL verify-
  // clean silent miscompile the leaf-loop above MISSED): the inner compare's
  // tainted operand must be a DIRECT member of the rail closure — a diagonal
  // (`cq_phi`/Rz) alias of the routed base, whose BASIS VALUE equals rail1's — NOT a
  // value-DERIVED offshoot built in `Mid` (e.g. `%d = add %g, 1`). `lowerCompare
  // ToFlagRail` mints the inner flag by substituting rail1 for that operand
  // WHOLESALE: an in-`Mid` derivation is (i) DROPPED by the substitution, so the
  // flag tests `rail1 < k` instead of `(rail1+1) < k` — a wrong predicate; AND
  // (ii) it is neither a `cq_phi` gate (collectArmPhis walks only `cq_phi`) nor a
  // compare, so `flattenRegionTree` never erases it → it dangles a live use of `%g`
  // and the `Mid` block erase is a use-after-free (silent on this no-assert LLVM;
  // SIGSEGV under Guard Malloc). The leaf-only check passes it (its sole quantum
  // leaf `%g` IS in-closure), so the OPERAND itself must be checked. Over-decline
  // the derived-inner shape (Prime Directive) — 4.3 does not replay an in-`Mid`
  // derivation onto the rail. A direct `icmp(%g, k)` / `icmp(%q, k)` (gate-free
  // Mid) / multi-gate `icmp(%g2, k)` keeps its operand IN the closure and lowers.
  auto *InnerCmp = dyn_cast<CmpInst>(InnerCond);
  if (!InnerCmp)
    return diagnoseUnderControl(OuterBI, "nested control flow"),
           NestDisposition::Declined;
  const bool LhsT = Taint.Tainted.count(InnerCmp->getOperand(0)) != 0;
  const bool RhsT = Taint.Tainted.count(InnerCmp->getOperand(1)) != 0;
  if (LhsT == RhsT)  // both tainted (Q+Q) or neither (no rail handle) → decline.
    return diagnoseUnderControl(OuterBI, "nested control flow"),
           NestDisposition::Declined;
  const Value *RailOperand = LhsT ? InnerCmp->getOperand(0) : InnerCmp->getOperand(1);
  if (!RailClosure.count(RailOperand))
    return diagnoseUnderControl(OuterBI, "nested control flow"),
           NestDisposition::Declined;

  // Per-level STALE-CONDITION wire guard (bd tayx Rule-13 clearance, the p16
  // probe family — a REAL verify-clean hole this path carried since 4.3): the
  // nested dispatch BYPASSES classifyArms, so neither condition ever reached
  // condWireDisposition (`nonDiagonalGateBeforeBranch` before bd lom0 Inc 4 —
  // which is also why the Inc-4 POSITION-AWARE phase accept does not reach this
  // path: it lives entirely inside that function), and the criteria above walk
  // the inner
  // provenance only against the RAIL closure — no wire is checked for a
  // non-diagonal gate. A chained cq_theta re-rotating a condition's wire
  // before its compare (DIRECT or hidden behind a one-register router phi)
  // let that level's flag mint read the post-Ry basis while the SSA condition
  // denoted the pre-Ry record: the routed nested stream emitted verify-clean,
  // plain-C-reachable at -O1 (control_swap_reject_nested_stalecond_*.ll).
  // Mirror the flat guard PER LEVEL (Rule 14): the position-free,
  // router-crossing wire walk over the condition's tainted provenance (any
  // off-ancestry theta on the wire declines, no window — routers forward the
  // same physical handle, the tayx posture) plus the bounded positional
  // compare->branch scan for tainted-operand thetas (same-block; a
  // cross-block compare declines conservatively, exactly as ArmClassify).
  const auto staleCond = [&Taint](Value *CondV, BranchInst *BI) -> bool {
    SmallPtrSet<Value *, 16> Prov;
    condProvenance(CondV, Taint, Prov);
    SmallVector<Value *, 16> Seeds(Prov.begin(), Prov.end());
    if (findNonDiagonalWireGate(Seeds, /*CrossValueRouting=*/true,
                                /*EmitPoint=*/nullptr, /*DT=*/nullptr, &Taint))
      return true;  // theta on the condition's wire — the mint would be stale.
    auto *Cond = dyn_cast<Instruction>(CondV);
    if (!Cond || Cond->getParent() != BI->getParent())
      return true;  // cannot bound the positional scan — conservative decline.
    for (const Instruction *I = Cond->getNextNode(); I && I != BI;
         I = I->getNextNode()) {
      const auto *CI = dyn_cast<CallInst>(I);
      if (!CI)
        continue;
      const Function *F = CI->getCalledFunction();
      if (F && F->getName().starts_with("cq_theta_") && CI->arg_size() >= 1 &&
          Taint.Tainted.count(CI->getArgOperand(0)))
        return true;  // chained Ry between the compare and its branch.
    }
    return false;
  };
  if (staleCond(OuterBI->getCondition(), OuterBI) ||
      staleCond(InnerCond, InnerBI))
    return diagnoseUnderControl(OuterBI,
                                "condition predates a non-diagonal gate"),
           NestDisposition::Declined;

  // ⚠ THERE IS NO LONGER AN ACCEPT HERE, AND THAT IS NOT A PUNT (bd
  // test_C_libtooling-3qlq Inc 1 part B). Everything above proves the 4.3
  // REGISTER-FORM nest — a shape that CANNOT EXIST after owner decision D1/D2,
  // because every criterion it turns on is a consequence of the arm gate
  // carrying a register: criterion 3 needs exactly one merge φ (a `void
  // @cq_phi(double)` arm produces none), criterion 4 needs all three merge
  // incomings to bottom at one `cq_phi` DIAGONAL-ALIAS base (that chain is the
  // retired `@cq_phi_<sfx>(x, angle)` family, which `resolveSources` no longer
  // resolves), and criterion 5 needs the inner flag minted FROM the parent's
  // work RAIL (there is no rail). The register-free nest is claimed EARLIER, by
  // `ArmClassify::classifyPhaseKickbackNest`, which this function never sees.
  //
  // So the honest disposition of anything that still reaches this line is a LOUD
  // DECLINE with the message this path has always used, and
  // `NestedRouteEmit.{h,cpp}` — the swap-route emitter this used to feed, and one
  // of the two remaining minters of a TENSORED non-`i1` `cqrt_rz` — is DELETED
  // with this increment. Rule 17 is satisfied because the shape the increment set
  // out to build (the GENUINE depth-2 phase nest) DOES lower; what declines here
  // is a shape whose own preconditions the language no longer admits.
  (void)Plan;
  (void)Claimed;
  diagnoseUnderControl(OuterBI, "nested control flow");
  return NestDisposition::Declined;
}

}  // namespace cq
