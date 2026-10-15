// ArmClassify.cpp — Per-arm lineage classification + §3c provenance walk.
// See ArmClassify.h for the contract; swap-route 4.1 IMPLEMENTATION §3 (phase
// arms) + 4.2 IMPLEMENTATION-4.2 §3 / PRD Part II §8.3 (value arms).
//
// All analysis is by SSA-value identity, before any mutation (Rule 9). The
// classifier walks each arm's contribution to the merge `φ` back along its
// PHASE spine (`cq_phi_<sfx>` handle edges: the retired register form, which
// declines at `resolveSources`, so the spine is empty on an accepted module;
// the register-free `cq_phi` arm is `classifyPhaseKickback`'s). What the
// spine bottoms at decides the arm's class:
//   * a leaf handle (a value defined OUTSIDE the arm, or a `cq_theta` source)
//     equal to the routed slot → PHASE arm, i.e. a gate-free arm — accept iff
//     tainted (criterion 3);
//   * no spine at all → try the arm-block-bounded VALUE chain walk
//     (`walkValueChain`): a pure linear chain of supported tainted integer
//     `BinaryOperator`s bottoming at exactly the routed slot is the 4.2
//     value-arm class — §3c PERMANENT reject if the routed register is in the
//     condition's transitive taint provenance (ACTIVE since WI-3), accept
//     class otherwise: a value DIAMOND (WI-4) and a two-arm value IF/ELSE over
//     ONE shared routed base (WI-5) both lower by the controlled-copy merge
//     (`emitValueRegion` hoists the chain into `emitSelectRegion`);
//     everything off-pattern declines with its precise string (mux/FP →
//     `control flow`; mixed content → `mixed phase/value arm`; fan-out/stray
//     → `impure value arm`; Q+Q link → `value-arm swap-route`).

#include "ArmClassify.h"
#include "RegCondLeaf.h"  // isRegCondLeaf / regCondProvenance (bd dm7f.77)

#include "ArmAnalysis.h"
#include "CompareLowering.h"   // compareFlagMintable (2b angle-select S4)
#include "ControlPlan.h"
#include "ControlShape.h"     // blockOnCycle (2b angle-select S7 cycle prong)
#include "EqFoldArm.h"
#include "IntrinsicLowering.h"  // F2 conservative half: the rail-producing
                               // curated call set (round-4 review, F-R4-3)
#include "LiteralIntegrity.h"  // valueCarriesUndef (2b angle-select S1 arm fence)
#include "LoopPlan.h"          // railPhiRootMint (Inc 3 R7-loop clause (b'))
#include "OpcodeSupport.h"
#include "PredMuxFlatten.h"
#include "PoisonFlow.h"  // classicalCallHoistRoute (bd dm7f.21)
#include "SpeculationSafety.h"  // hoistedArgPoisonIsUB (bd bwfp)
#include "RailBankPromote.h"  // isRailBankSeedAlloc
#include "RotationLowering.h"  // suffixFromName (2b angle-select S5)
#include "SelectClassify.h"    // CondTree (2b angle-select S4)
#include "TaintPropagation.h"
#include "WidthDispatch.h"     // abiWidthFor (2b angle-select S5)
#include "WireWalk.h"

#include "llvm/ADT/APFloat.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/AssumptionCache.h"   // F2-semantic: LVI needs one (round-3 R3)
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/ConstantFolding.h"   // F2-semantic: the EXACT fold half
#include "llvm/Analysis/LazyValueInfo.h"     // F2-semantic: the BACKWARD edge analysis
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"  // successors() — the bd hn29/leyd/52og CFG-bounded scan
#include "llvm/IR/ConstantRange.h"  // F2 edge-pinned-seed range test (round-1 L2)
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/InstIterator.h"  // instructions() (bd dm7f.53 L1 re-ask)
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/Support/KnownBits.h"        // F2-semantic: the hull-repair enumeration

#include <algorithm>
#include <cassert>
#include <cmath>  // foldCuratedTrigF64 (bd dm7f.18)
#include <functional>  // collectAngleMux (bd dm7f.54)
#include <memory>  // unique_ptr (the per-function DominatorTree cache, bd r9e5 1b-B.1)
#include <utility>

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

}  // namespace

bool isFrontEndThetaCall(const Value *V) { return isThetaCall(V); }

// The per-arm analyses below are de-anonymized into the named `cq` namespace
// (declared in ArmAnalysis.h, WI-0/MD1) so the 4.3 RegionTreeDetect /
// ArmHomogeneity TUs can reuse them. PURE REFACTOR — definitions and behavior
// unchanged; the tiny `isPhiCall`/`isThetaCall`/`isCallToPrefix` predicates above
// stay TU-local (they collide with same-named anon helpers in other TUs). The
// remaining internal-only helpers keep their own (reopened) anonymous blocks.

// Walk the PHASE spine WITHIN one arm block: while `V` is a `cq_phi_<sfx>` (Rz)
// call DEFINED IN `ArmBB`, follow its arg-0 handle operand (arg 1 is the classical
// angle). Returns the first value the chain bottoms at — the arm's base handle, a
// value-changing op, OR a `cq_phi_<sfx>` defined OUTSIDE `ArmBB`. Only the retired
// register form matches (it declines at `resolveSources`), so on an accepted
// module this returns `V` unchanged.
//
// (Pre-3qlq history.) Bounding at the arm-block boundary was LOAD-BEARING: an
// UNBOUNDED walk hopped past a pre-region `cq_phi` to the `cq_theta` source, so a
// derived handle (`%qd = cq_phi(%q,·)` before the branch, shared by both arm
// spines) was misread as `%q`; an if/else was ACCEPTED and the emitter collected
// the shared phi ONCE PER ARM → double-erase SIGSEGV (§8 adversarial review
// 2026-06-09, exit 139). A pre-region `cq_phi` base was then treated as a tainted
// leaf (test_C_libtooling-9hh, 2026-06-10; criterion 3 permits a derived base).
Value *walkPhaseSpine(Value *V, const BasicBlock *ArmBB) {
  while (auto *CI = dyn_cast<CallInst>(V)) {
    const Function *F = CI->getCalledFunction();
    if (!F || !F->getName().starts_with("cq_phi_") || CI->arg_size() < 1)
      break;
    if (CI->getParent() != ArmBB)
      break;  // pre-region cq_phi — the derived base handle, not an arm gate.
    V = CI->getArgOperand(0);
  }
  return V;
}

// PURE ARM BODY (Rule 8 linearity + no stray ops). The arm block must contain
// NOTHING beyond the linear phase spine that feeds the merge phi — i.e. every
// non-terminator instruction in `ArmBB` is a `cq_phi_<sfx>` on the spine of
// `ArmIncoming`. That spine is the retired register form (declines at
// `resolveSources`), so on an accepted module this asks "is the arm block
// empty?". It rejects two silent-miscompile/crash paths (both confirmed against
// the pre-3qlq swap-route emitter by the WI-2 §8 adversarial review, 2026-06-09):
//   * FAN-OUT — a spine `cq_phi` reused by a sibling `cq_phi` (Rule 8 linearity).
//     The emitter replayed + erased ONLY the merge-feeding spine, so the off-spine
//     sibling dangled in `taint.PhiCalls` → use-after-free when `lowerRotations`
//     re-read its freed operand (reproduced as a broken module).
//   * STRAY op in the arm — a `cq_measure` / `cq_theta` / arithmetic the emitter
//     does not move. `RegionFlatten` erases the arm BLOCK, so the
//     stray op is silently DROPPED from the IR (e.g. a user measurement vanishes)
//     AND its `taint.MeasureCalls`/`ThetaCalls` pointer dangles → use-after-free
//     in `lowerMeasures`/`lowerRotations`.
// Whole-chain reversal needs linear lineage and a self-contained arm; anything
// else is declined loudly (over-decline is safe; Prime Directive). The base
// handle the spine bottoms at is NOT in `ArmBB` (it is the live register in the
// pred), so it is correctly never inspected here.
bool armBlockIsPureSpine(const BasicBlock *ArmBB, const Value *ArmIncoming) {
  SmallPtrSet<const Value *, 8> Spine;
  for (const Value *V = ArmIncoming; isPhiCall(V);) {
    Spine.insert(V);
    const auto *CI = cast<CallInst>(V);
    if (CI->arg_size() < 1)
      break;
    V = CI->getArgOperand(0);
  }
  for (const Instruction &I : *ArmBB) {
    if (I.isTerminator())
      continue;
    if (!Spine.count(&I))
      return false;  // a fan-out sibling or a stray op — not a pure phase arm.
  }
  return true;
}

namespace {

// Is `Base` a VALUE-changing op (changes the computational-basis value), as
// opposed to a leaf quantum handle? Classified by OPCODE/kind, NEVER by defining
// block — clang -O1 (LICM/sinking/GVN) freely hoists a branch-invariant value op
// out of the arm into a dominating block, so keying on `getParent()` there
// mis-accepts a real data-mux / §3c-clobber arm as a phase leaf (a verify-clean
// silent miscompile; caught by WI-1 adversarial review 2026-06-09). A leaf is a
// `cq_theta` source, a `cq_phi_<sfx>` result, a function argument, or a constant;
// ANY other instruction (add/mul/cast/select/non-rotation call/…) defining a new
// value from a quantum operand is value-changing.
//
// The `cq_phi_<sfx>` leaf is the retired register form (it declines at
// `resolveSources`). It was a leaf BY OPCODE: Rz = diag(1, e^{iθ}) is DIAGONAL,
// so it preserves the basis value wherever clang placed it; one reaching here
// was a PRE-REGION rotation, the DERIVED base the arm extended (9hh).
bool isValueChangingOp(const Value *Base) {
  const auto *I = dyn_cast<Instruction>(Base);
  if (!I)
    return false;  // Argument / Constant — a leaf base.
  if (isThetaCall(I))
    return false;  // quantum source — a leaf handle.
  if (isPhiCall(I))
    return false;  // pre-region Rz — diagonal: the live DERIVED leaf handle.
  return true;     // any other instruction defines a new basis value → decline.
}

}  // namespace

// Backward taint provenance of the branch condition: every tainted value
// reachable by walking operand edges back from `Cond`, stopping at `cq_theta`
// sources. Replicates the per-use arg-1 angle exclusion from
// TaintPropagation.cpp VERBATIM — the angle of a `cq_phi_<sfx>` (the retired
// register form) is classical and is never a condition operand (the f64/angle
// miscompile family). Only tainted values are recorded; classical scaffolding
// (constants, the classical seed of a theta) is traversed but never collected.
//
// ⚠ THIS CONE IS ALSO R4's COMPLETENESS CARRIER, which its original callers did
// not need it to be (round-1 Rule-13 review of bd test_C_libtooling-drbq, lens
// L1 §2) — ⚠ AND SINCE 2026-09-11 IT IS **F2's** COMPLETENESS CARRIER TOO (owner
// ruling, bd `drbq.14`). `classifyArms`' F2 clause builds its exclusion set
// `CondWire` from exactly the same two seeds R4 uses, by calling the same
// `railWireClosure` (Rule 14 — a second spelling of "the condition's wire" is
// what the drbq Inc-3 (b′) lesson forbids). So the warning below now has TWO
// subjects and they fail in OPPOSITE directions, which is why it is worth
// re-reading rather than skimming:
//   * NARROWING this cone makes **R4** vacuous — a rotation arm on the
//     condition's wire stops being detected, and the flag is stripped against a
//     relabelled register (Rules 6/8);
//   * NARROWING it also SHRINKS **F2's** exclusion set, which is an
//     OVER-DECLINE, not a miscompile — the safe direction;
//   * WIDENING it (a forward hop, `WireDir::BothWays`, following a cast) is
//     harmless for R4 and is an **OVER-ACCEPT for F2**: it would swallow the
//     F-R1-1 six, the sideways family, the casts, the curated intrinsics and the
//     `sitofp` — every one a recorded CONFIRMED silent miscompile. Before the
//     ruling, widening this cone was a decline-monotone tidy-up. It is not any
//     more.
// `control_inplace_ry_stateprep_condwire_alias_accept.ll` is the fixture that
// notices a change here, and it is RED under a mutant that builds `CondWire`
// as `{Region.Condition} ∪ Prov` (MEASURED 2026-09-11: that mutant moves that
// ONE file and nothing else in the 109-file state-prep family).
//
// `classifyArms`' R4 clause seeds `CondRails` with
// `railWireClosure(Region.Condition, BackwardOnly, …)` — which stops dead,
// because a `CmpInst` is not a `BinaryOperator` and that walk has no `CmpInst`
// arm — and then closes over EVERY member of this set. So "the rotated wire is
// not a condition wire" is proved from THIS function's reach, not from the
// compare's. NARROWING IT (stopping at a template producer, collecting only
// direct operands, dropping a hop) IS A RULE-13 CHANGE TO R4, and R4 is the
// fence whose failure is a flag stripped against a relabelled register — a
// `cqrt_free` of an entangled ancilla (Rules 6/8).
void condProvenance(Value *Cond, TaintSet &Taint,
                    SmallPtrSetImpl<Value *> &Out,
                    function_ref<bool(Value *)> Stop) {
  SmallVector<Value *, 16> Work;
  SmallPtrSet<Value *, 16> Seen;
  Work.push_back(Cond);
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (!Seen.insert(V).second)
      continue;
    if (Taint.Tainted.count(V))
      Out.insert(V);
    auto *I = dyn_cast<Instruction>(V);
    if (!I || (Stop && Stop(V)))
      continue;
    if (isThetaCall(I))
      continue;  // source: collected V already; do NOT enter the classical seed.
    // bd dm7f.77 — a REGISTER CONDITION (RegCondLeaf.h) is a register: its wire
    // is `{V} ∪ wire(target)`, and the xor's SOURCE is only read by the in-place
    // gate (or by the out-of-place template, at `V`'s own position). Walking into
    // the source would put a register the condition no longer reads into every
    // wire question asked through `V` (L2: the set `regCondProvenance` computes).
    if (isRegCondLeaf(I)) {
      if (Value *T = regCondTarget(I))
        Work.push_back(T);
      continue;
    }
    const bool IsPhi = isPhiCall(I);
    for (unsigned Idx = 0, E = I->getNumOperands(); Idx < E; ++Idx) {
      Value *Op = I->getOperand(Idx);
      if (IsPhi) {
        // arg-1 angle exclusion (TaintPropagation.cpp): skip the operand-use
        // that is ONLY the angle (arg 1) and not also the arg-0 handle.
        auto *CI = cast<CallInst>(I);
        if (CI->arg_size() >= 2 && Op == CI->getArgOperand(1) &&
            Op != CI->getArgOperand(0))
          continue;
      }
      Work.push_back(Op);
    }
  }
}

// The routed base's first DIAGONAL-ALIAS hit in `Prov`, or null. Walks the
// pre-region `cq_phi_<sfx>` arg-0 chain from `Routed`. That is the retired
// register form (declines at `resolveSources`), so on an accepted module this is
// `Prov.count(Routed) ? Routed : null`. Pre-3qlq, rotation lowering RAUW'd
// `%qd = cq_phi(%q, ·)` and `%q` to the SAME i32 handle, so SSA-value
// disjointness from the condition's provenance was NOT wire disjointness — a
// value arm over `%qd` while the condition read `%q` transformed the
// very physical wire the `icmp_inv` flag-strip reads (§8 review 2026-06-10).
// Enforcing provenance disjointness through this closure keeps the accept class
// inside the documented rationale. Pure reading walk — no collection, so the
// arm-block bounding discipline (which guards COLLECTION) does not apply; the
// chain terminates at the first non-`cq_phi_<sfx>` (a theta source,
// template-derived value, or argument — all genuinely fresh wires).
Value *diagonalAliasHit(Value *Routed, const SmallPtrSetImpl<Value *> &Prov) {
  for (Value *V = Routed;;) {
    if (Prov.count(V))
      return V;
    auto *CI = dyn_cast<CallInst>(V);
    if (!CI || !isPhiCall(CI) || CI->arg_size() < 1)
      return nullptr;
    V = CI->getArgOperand(0);
  }
}

// The RAIL CLOSURE of `V` — every SSA value that MIGHT name `V`'s physical rail
// (control-in-place-PRD §4 R4 **and** R6, bd test_C_libtooling-drbq Inc 1).
//
// ONE WALK, TWO QUESTIONS (and finding J is what forced that). R4 asks "is the
// rotated wire one of the condition's?", which only needs the walk BACKWARD to
// the roots: two names of one wire share a root, so two backward closures that
// intersect is the test. R6 asks "does anything READ a record of this wire after
// the region?", and enumerating readers needs the wire's MEMBERS — which live
// FORWARD of the base as often as behind it. Inc 1 shipped R6 over the DIRECT
// users of the base alone and a one-hop diagonal alias evaded it in BOTH
// directions (`control_inplace_ry_reject_stale_diag_alias_{forward,backward}.ll`,
// both measured wrong-VALUE silent miscompiles; both fixtures are gone: the 3qlq
// migration removed their register-form `cq_phi` hop, `..._backward` was merged
// into `..._forward` at 402a5643, and `..._forward` was deleted at ae840fac as an
// IR duplicate of `control_inplace_ry_reject_stale_measure.ll`). The FORWARD
// member hop is pinned today by `control_inplace_ry_reject_stale_chained_theta.ll`
// (a chained `cq_theta`) and the `control_inplace_ry_reject_lifted_phi_*.ll`
// family (a classical join φ). No fixture carrying R6's diagnostic pins the
// BACKWARD hop in a straight-line region (scanned 2026-10-05; the diagonal
// spelling no longer exists). That is the bd 8h7d.5 F-1/F-3
// lesson one epic later: the fence was written over the CHAIN — one SSA name —
// when the object it protects is the RAIL. So both questions now read ONE member
// set built by ONE walk, and `WireDir` is the only thing that differs.
//
// Physical-rail identity is not SSA identity: rotation lowering RAUWs a whole
// chain of SSA names onto ONE `cqrt_alloc_<W>` handle. Two values share a rail
// exactly when one is reachable from the other along IN-PLACE hops, so two
// closures that intersect is the (conservative) test, and two that do not is a
// proof of disjointness.
//
// BACKWARD hops (taken under BOTH `WireDir`s) — each is a spelling that keeps
// the SAME handle:
//
//   * `cq_phi_<sfx>(x, θ)` — `diagonalAliasHit`'s hop, generalized. The retired
//     register form (declines at `resolveSources`): vacuous on an accepted module.
//   * `@cq_theta_*(x, θ)` with `x` TAINTED — a CHAINED Ry lowers in place on `x`'s
//     handle too (`RotationLowering`'s `Chained` branch mints no alloc). A
//     SOURCE theta (classical arg-0) mints a fresh rail, so the walk stops
//     there — that is what makes `int q = 0; cq_theta(&q,·); int r = 0; cq_theta(&r,·)`
//     two disjoint wires and the whole increment possible.
//   * a `PHINode` / `SelectInst` over tainted operands — a ROUTER forwards the
//     same physical handle (the bd tayx rule that `WireWalk` crosses).
//   * a `freeze` — the same handle laundered.
//   * `add`/`sub`/`xor` with exactly one tainted operand — and this one is the
//     reason the closure is CONSERVATIVE rather than exact. Such an op lowers
//     IN PLACE (`cqrt_addc_<W>`/`cqrt_xorc_<W>` on the parent's own rail) when
//     the M-C fence admits it and OUT of place (a fresh template rail)
//     otherwise — but that fence lives in `lowerOps`, which runs LONG AFTER
//     detection, so nothing here can know which. Both roots are therefore
//     admitted. It also subsumes `taint.InPlaceRailOps` (the `lowerLoops`-proven
//     set the PRD names): every member is an `add`/`xor` this hop already
//     crosses.
//
//     ⚠ THAT "NOTHING HERE CAN KNOW WHICH" IS TRUE FOR `add`/`xor` AND FALSE FOR
//     `sub` (bd drbq round-2 review, lens B §1). There is NO `cqrt_subc_<W>` at
//     any width — zero hits in `runtime/cq_runtime.h` and in
//     `tools/opcode_table.yaml` — so the in-place ABI is `addc`/`xorc` only, and
//     `inPlaceReassignRailOperand` (`ArithLowering.cpp`) additionally admits only
//     the HANDLE-LHS spelling `q - c`. For the LH spelling `k - q` the answer IS
//     knowable at detection and is always "out of place, a FRESH rail" — so
//     crossing `k - q` is UNCONDITIONALLY conservative here, not conditionally
//     so. Measured cost: `int r = 5 - p; if (q==5) cq_theta(&r,.9); …
//     cq_measure(p);` declines R6, while its (pre-3qlq register-form) `cq_phi`
//     twin accepted and emitted `cq_template_sub_i32_lh(5, h1)` on a fresh rail
//     where `p` was never touched. The decline is loud, so it is never silent,
//     but it is an over-decline to remove (R1), not a safe margin; it is
//     recorded and not yet fixed — and PRD §11.5 obligation 2 makes NARROWING
//     this hop a Rule-13 change, and whoever performs it must not reason from
//     the M-C-fence premise for the `sub` half: it does not apply.
//
// Everything else STOPS: a `cq_template_*` producer (mul, cast, compare, the
// out-of-place arith) mints a FRESH rail, so it is its own root. That is not a
// shortcut — a value entangled with the condition but living on its own rail is
// genuinely a different wire, and rotating it leaves the condition's BASIS
// untouched, which is all the `icmp_inv` flag strip needs (PRD §3).
//
// FORWARD hops (`WireDir::BothWays` only) are the exact MIRROR of the backward
// list — a user whose RESULT keeps the member's own handle: `cq_phi_<sfx>(M,·)`, a
// CHAINED `@cq_theta_*(M,·)`, an `add`/`sub`/`xor` whose sole tainted operand is
// `M`, and (since the round-1 Rule-13 review, lens L2 §1) a `PHINode` /
// `SelectInst` / `freeze` DATA user. Three deliberate exclusions remain, each of
// which is the STRICT direction because a non-member user faces R6's position
// proof instead of being walked through:
//
//   * the ONE EXCLUDED INSTRUCTION the caller names (`Exclude`) — the value that
//     WILL DENOTE THE POST-GATE REGISTER once emission finishes, so its own users
//     are correct by construction and must not be re-enumerated. There are
//     exactly two spellings of that one value, one per caller:
//       - `classifyArms` (Inc 1) passes the REGION'S OWN MERGE φ. It is a user of
//         the base by construction and the emitter RAUWs it to the base.
//       - `classifyAngleSelect` (Inc 2b) passes the CONSUMING ROTATION `T`. `T` is
//         a chained-rotation user of the base, so `forwardRailHop` admits it; but
//         `T`'s RESULT is the post-gate name (the emitter rewires `T`'s operands
//         and leaves the call standing), so every consumer of it already reads the
//         relabelled register.
//     Crossing either would make every legitimate post-region consumer a
//     member's user and collapse the whole accept class
//     (`control_inplace_ry_alias_after_region.ll` is the fixture that would
//     die). Inc 1 shipped this exclusion as a BAN ON THE WHOLE CLASS, justified
//     by that one φ, and the gap was a CONFIRMED silent miscompile: an ordinary
//     CLASSICAL join φ (pre-3qlq `int m; if (c) m = cq_phi(r,.1); else m = r;`)
//     was a plain user that passed `provablyBefore` honestly, so its OWN users were
//     never enumerated — and `liftOneRegisterMergePhi` later RAUW'd it to the
//     base, handing `cq_measure`, `ret`, a tape write, a Phase-6 clone argument
//     and a `cq_invert` bracket the POST-Ry register. See `forwardRailHop`.
//   * the region's OWN ARM BLOCKS are skipped wholesale (`ArmA`/`ArmB`): those
//     users are region-INTERNAL and the arm classifier adjudicates them — this
//     arm's gate, the sibling arm's gate, or a stray op `inPlaceRotationArmTheta`
//     already refused. Crossing into them would reach the arm theta and, through
//     its sole use, the merge φ — the same collapse.
//   * a `cq_measure` / opaque call / `cq_template_*` producer is not a hop at
//     all: it either reads the wire (R6's business) or mints a fresh rail.
//
// KNOWN OVER-DECLINE, stated so it is not rediscovered as a bug: the add/xor hop
// refuses `if (q==5) cq_theta(&r,·)` when `r = q + 1`, even though M-C would
// in fact lower that out of place. The decline is loud, so it is never silent,
// but it is an over-decline to remove (R1), not a safe margin; the shape is
// outside the Inc-1 accept class either way.
namespace {

enum class WireDir {
  BackwardOnly,  // R4's condition side: roots are all an intersection needs.
  BothWays,      // R4's base side + R6's member set: every name of the wire.
};

// Does `U`'s RESULT name the same physical rail as its operand `M`? The forward
// mirror of the backward hop list above; see it for each hop's justification.
bool forwardRailHop(Instruction *U, Value *M, TaintSet &Taint) {
  if (auto *CI = dyn_cast<CallInst>(U)) {
    if (CI->arg_size() < 1 || CI->getArgOperand(0) != M)
      return false;  // arg-1 is the ANGLE (Rule 3) — never a wire edge.
    if (isPhiCall(CI))
      return true;  // Rz: always in place.
    if (isThetaCall(CI))
      return Taint.Tainted.count(M) != 0;  // chained Ry: in place.
    return false;    // measure / cq_invert / anything opaque: not a hop.
  }
  // A `PHINode` / `SelectInst` / `freeze` DATA user — crossed FORWARD since the
  // round-1 Rule-13 review (lens L2 §1, a CONFIRMED silent miscompile). Inc 1
  // crossed these BACKWARD only, on the stated ground that "the region's OWN
  // MERGE φ is a user of the base" — which names ONE φ, not the class, and the
  // caller now excludes exactly that one φ instead. The measured cost of the
  // omission: the pre-3qlq `int m; if (c) m = cq_phi(r,.1); else m = r;` — a
  // purely CLASSICAL diamond — made the join φ a plain *user* of a member. It passes
  // `provablyBefore` honestly (it does dominate the region's branch), its own
  // users were therefore never enumerated, and `liftOneRegisterMergePhi` later
  // RAUW'd it to the base: `cq_measure(m)`, `ret m`, a 7.6 tape write, a Phase-6
  // clone argument and a `cq_invert` bracket all read the POST-Ry register where
  // the source names the record BEFORE it. Six accepting reproducers, five
  // consumer kinds, `opt` exit 0, verify-clean, stage-2b clean.
  //
  // A crossed φ's RESULT becomes a member, so ITS users owe the position proof —
  // which is the whole point. A φ over two DIFFERENT rails is a classical mux,
  // not rail identity; admitting it here is still the SAFE direction (a member
  // only ever adds obligations), and `declineClassicalMuxes` owns that shape.
  if (isa<PHINode>(U) || isa<FreezeInst>(U))
    return Taint.Tainted.count(M) != 0;
  if (auto *SI = dyn_cast<SelectInst>(U))
    // DATA operands only. `M` as the select's CONDITION (operand 0) does not put
    // the result on `M`'s rail — that is the 4.4 tainted-condition select, whose
    // result is a fresh merged register.
    return Taint.Tainted.count(M) != 0 &&
           (SI->getTrueValue() == M || SI->getFalseValue() == M);
  if (auto *BO = dyn_cast<BinaryOperator>(U)) {
    // bd dm7f.77 (design D3) — a REGISTER CONDITION's rail is its in-place
    // TARGET's (when it has one) and otherwise its own: it is crossed forward
    // from the target only, never from the xor's source.
    if (isRegCondLeaf(BO))
      return regCondTarget(BO) == M;
    const Instruction::BinaryOps Op = BO->getOpcode();
    if (Op != Instruction::Add && Op != Instruction::Sub &&
        Op != Instruction::Xor)
      return false;  // mul/shift/… have no in-place ABI: a fresh rail.
    Value *L = BO->getOperand(0), *R = BO->getOperand(1);
    const bool TL = Taint.Tainted.count(L) != 0;
    const bool TR = Taint.Tainted.count(R) != 0;
    // MAY be an M-C / dtzb in-place tweak for `add`/`xor`; for `sub` see the
    // block comment above — `k - M` has NO in-place ABI at any width
    // (`cqrt_subc` does not exist), so that half is unconditionally
    // conservative rather than M-C-dependent.
    return TL != TR && (TL ? L : R) == M;
  }
  return false;
}

// `Order` (optional) receives the members in worklist-discovery order, so R6's
// scan — and therefore the instruction its diagnostic anchors on — is
// deterministic; `SmallPtrSet` iteration is address-ordered and is not.
// `Exclude` (optional) is the ONE forward exclusion: the instruction that WILL
// DENOTE THE POST-GATE REGISTER after emission, so its own users are correct by
// construction. It is the region's own merge φ for `classifyArms` (which the
// emitter RAUWs to the base) and the consuming rotation `T` for
// `classifyAngleSelect` (whose result IS the post-gate name). Crossing it would
// make every legitimate POST-region consumer a member's user and collapse the
// entire accept class. Every OTHER φ / select / freeze is crossed (round-1
// review L2 §1) — see `forwardRailHop`.
//
// ⚠ IT WAS SPELLED `MergePhi` UNTIL bd drbq Inc 2b, AND THE RENAME IS THE POINT
// (Rule 14): the parameter's CONTRACT was never "a φ" — it was "the one value
// the emitter makes denote the post-gate register" — and a name that describes
// one caller's spelling of that contract is how a second caller gets told the
// exclusion does not apply to it. Behaviour for regions is unchanged; the Inc-1
// call site still passes its merge φ.
void railWireClosure(Value *V, TaintSet &Taint, WireDir Dir,
                     const BasicBlock *ArmA, const BasicBlock *ArmB,
                     SmallPtrSetImpl<Value *> &Out,
                     SmallVectorImpl<Value *> *Order = nullptr,
                     const Instruction *Exclude = nullptr) {
  SmallVector<Value *, 16> Work;
  Work.push_back(V);
  while (!Work.empty()) {
    Value *W = Work.pop_back_val();
    if (!W || !Out.insert(W).second)
      continue;
    if (Order)
      Order->push_back(W);
    // FORWARD, asked of every TAINTED member (including the roots the backward
    // hops bottom at — that is how a sibling alias off the ROOT is found, which
    // was the shape of the deleted `..._stale_diag_alias_backward.ll`; see the
    // header of this walk for what pins the closure today).
    //
    // The taint gate is not decoration. Every hop above pushes only tainted
    // values EXCEPT the backward `cq_phi_<sfx>` one (retired register form),
    // which pushes arg-0 unconditionally — so a degenerate `cq_phi(0, θ)` could
    // put a CONSTANT in the set, and forward-walking a constant
    // would sweep in every unrelated `cq_phi(0, ·)` in the module as a "member
    // of this wire". Untainted is never a wire. (No probe got a MISCOMPILE
    // through that gap — those degenerate phis are untainted, so their own
    // consumers decline earlier; the guard is here because forward-walking a
    // constant is meaningless and unbounded, not because one did.)
    if (Dir == WireDir::BothWays && Taint.Tainted.count(W)) {
      for (User *U : W->users()) {
        auto *UI = dyn_cast<Instruction>(U);
        if (!UI || UI->getParent() == ArmA || UI->getParent() == ArmB)
          continue;  // non-instruction, or region-internal (see the note above).
        if (UI == Exclude)
          continue;  // the caller's post-gate name — the ONE forward exclusion.
        if (forwardRailHop(UI, W, Taint))
          Work.push_back(UI);
      }
    }
    auto *I = dyn_cast<Instruction>(W);
    if (!I)
      continue;  // Argument / Constant — its own root.
    if (auto *CI = dyn_cast<CallInst>(I)) {
      if (isPhiCall(CI) && CI->arg_size() >= 1) {
        Work.push_back(CI->getArgOperand(0));  // Rz: always in place.
        continue;
      }
      if (isThetaCall(CI) && CI->arg_size() >= 1 &&
          Taint.Tainted.count(CI->getArgOperand(0))) {
        Work.push_back(CI->getArgOperand(0));  // chained Ry: in place.
        continue;
      }
      continue;  // a source theta / template producer / anything else: fresh.
    }
    if (isa<PHINode>(I) || isa<SelectInst>(I) || isa<FreezeInst>(I)) {
      for (Value *Op : I->operands())
        if (Taint.Tainted.count(Op))
          Work.push_back(Op);  // router / launder: the same handle.
      continue;
    }
    if (auto *BO = dyn_cast<BinaryOperator>(I)) {
      // bd dm7f.77 — the backward mirror: a register condition hops to its
      // in-place target only; with none it is its own root (a fresh rail).
      if (isRegCondLeaf(BO)) {
        if (Value *T = regCondTarget(BO))
          Work.push_back(T);
        continue;
      }
      const Instruction::BinaryOps Op = BO->getOpcode();
      if (Op != Instruction::Add && Op != Instruction::Sub &&
          Op != Instruction::Xor)
        continue;  // mul/shift/… have no in-place ABI: a fresh rail.
      Value *L = BO->getOperand(0), *R = BO->getOperand(1);
      const bool TL = Taint.Tainted.count(L) != 0;
      const bool TR = Taint.Tainted.count(R) != 0;
      if (TL != TR)
        // MAY be an M-C / dtzb in-place tweak for `add`/`xor`; the `sub` half is
        // unconditionally conservative (no `cqrt_subc` at any width) — see the
        // block comment above `railWireClosure`.
        Work.push_back(TL ? L : R);
      continue;
    }
  }
}

// R6's position obligation for an ALIAS HOP — a user that is ITSELF a member of
// the wire (bd test_C_libtooling-drbq Inc 1, finding J).
//
// TWO SETS, TWO QUESTIONS — the bd 8h7d.5 round-3 discipline, applied here on
// purpose. Widening the MEMBER set (whose users get enumerated) must not widen
// the SKIP set (which users are exempt from a position proof), and it does not:
// a member's own position is still proved, just against the obligation that
// actually applies to it.
//
//   * a genuine READ (measure / ret / store / call / φ / select / pure op) keeps
//     the SHIPPED `provablyBefore(U, BI)` test verbatim;
//   * an ALIAS HOP is a GATE on the wire, not a record read, and the only thing
//     that can go wrong with it is FIRING AFTER the hoisted controlled Ry. The
//     obligation is therefore "`BI` cannot reach `U`" — the second conjunct of
//     `provablyBefore` on its own. Its FIRST conjunct (`U` dominates `BI`) is a
//     different question ("did `U` definitely execute"), which R6 does not ask,
//     and requiring it is WRONG-STRONG here: `control_inplace_ry_sequential.ll`'s
//     region 2 has region 1's ARM THETA as a member's user — it precedes region 2
//     on every path where it runs, and dominates nothing.
//
// A hop that CAN follow the gate is a stale record either way and declines (the
// dead `z = r_pre; cq_theta(&z, ·)` written after the region), and every hop's own
// readers are enumerated regardless, because it is a member.
//
// SAY THE COST OUT LOUD: this is a WIDENING, and exactly one shape gains an
// accept it did not have — an alias hop that is a DIRECT user of the base and
// sits on a classically-branched path the region cannot reach back into
// (`control_inplace_ry_alias_pre_region_branch.ll`, committed for that reason).
// The emitted order is checked there and is the source's: the hop lowers in its
// own conditional block, the controlled Ry is hoisted into the region's pred.
// Everything else is a NARROWING — the member set grew, so strictly more users
// are asked the question at all.
bool cannotFollowGate(const Instruction *U, const Instruction *BI,
                      const DominatorTree &DT) {
  return !isPotentiallyReachable(BI, U, /*ExclusionSet=*/nullptr, &DT);
}

// R6's PER-ACTIVATION reading, for an IN-LOOP region ONLY (bd
// test_C_libtooling-drbq Increment 3, PRD §13.3).
//
// WHY THE TWO FLAT PREDICATES CANNOT SIMPLY BE REUSED. Both `provablyBefore` and
// `cannotFollowGate` contain the reachability conjunct `!isPotentiallyReachable(
// BI, U)`, which EVERY BACK EDGE falsifies (bd
// [[provably-before-per-activation]]). Inside a loop the base's wire closure also
// reaches values it never reaches flat — `railWireClosure` crosses phis BACKWARD,
// and the loop-carried header φ's latch incoming is either the region's own merge
// φ or a post-region gate whose arg-0 is that φ, so the merge (and through it the
// arm theta) becomes a MEMBER and the forward `Exclude` cannot help. Every one of
// their in-loop users then fails both flat predicates. Measured: with R7's loop
// clause lifted and nothing else, all three flagship shapes (S1/S2/S11) declined
// `stale rail record read past a controlled Ry`.
//
// THE CERTIFICATE. Let `D = def(M)` and let `p(U)` be `U`'s READ POSITION: `U`
// itself, or — when `U` is a `PHINode` — the TERMINATOR of the incoming block on
// each edge that names `M` (a phi reads its incoming ON THE EDGE, the same rule
// `LoopLowering::staleReadOfValue` applies, and without it shape S2 alone dies:
// the header φ's entry edge would be judged from inside the loop). Then
//
//     OK  iff  `D` REFRESHES  and  every CFG path `BI → p(U)` re-executes `D`.
//
// THE BARRIER IS `D`, THE RECORD'S OWN DEFINITION — never `BI`, never `U`. The
// premise being re-established is "`M` denotes the register", and `D` is the
// instruction whose execution establishes it (the same barrier
// `WireWalk::gateIsHarmless` and `LoopLowering::railGateBetween` take). `Barrier
// == To` is the P1 VACUITY (bd [[peractivation-barrier-must-not-be-subject-p1]]):
// `reachesWithoutBarrier` tests barrier membership BEFORE the endpoint, so it
// would cut at the very instruction it is trying to reach and could never
// succeed — the certificate would be granted to everything, silently. Refused
// outright below rather than in a comment at the call site.
//
// ⚠ AND THE REFUSAL IS THE `if`, NOT THE `assert` BESIDE IT (round-1 lens L1
// Q1a). This project configures `CMAKE_BUILD_TYPE=Release`, so `NDEBUG` is on
// and BOTH `assert`s in the body below are compiled out. They are documentation
// of the invariant; the two `PU == D` / `U == D` early-`false` tests are what
// actually holds it. Do not "simplify" either one away on the grounds that the
// assert already covers it.
//
// THE GATE POSITION IS `BI`, NOT `T`. At detection `T` still sits in the arm
// block, so a path through the MERGE that skips the arm never "sees" it — while
// the HOISTED controlled gate executes unconditionally at `BI` on every
// activation. Asking at `BI` is both the conservative reading and the
// post-emission truth.
//
// THE REFRESH FENCE. The certificate's premise is "re-executing `D`
// re-establishes `M`". True by construction for an in-place gate or a producer
// (each re-reads the wire). FALSE for a φ that does not track the wire — bd
// [[identity-carry-phi-does-not-refresh]], where `%p = phi [%q, pre], [%p, latch]`
// provably equals the PRE-loop record while the wire moves under it. So a
// `PHINode` `D` must satisfy `WireWalk::phiTracksWire`, which is EXPORTED for
// this caller rather than re-spelt (Rule 14); `LoopLowering::recordRefreshedByDef`
// asks the same question over a POST-FLATTEN gate set this stage does not have,
// so it is not the reusable one.
//
// ⚠ THE FENCE'S POLARITY IS INVERTED HERE, AND ITS VOCABULARY IS NARROWER THAN
// THIS STAGE'S (bd drbq Inc 3, round-1 lens L5 Q3). `phiTracksWire`'s other
// caller uses it as a BARRIER, where `false` refuses and over-refusing is free;
// HERE it is a PRECONDITION, so `true` GRANTS and an over-permissive answer
// would be an OVER-ACCEPT. And it is spelled over `thetaOnPathTo`, which counts
// a `cq_theta` and does NOT count the dtzb in-place `add`/`xor` that
// `LoopLowering::collectRailGates` treats as a rail-relabelling gate.
//
// MEASURED 2026-09-04, 5 probes, and NOT exploitable — the discrimination is in
// `control_inplace_ry_reject_inloop_frozen_dtzb_carry.ll`. The fence is never
// the decider for this class: a FROZEN carry is its own user, so the PHI-EDGE
// READ POSITION rule below refuses the mirrored pair (M = P, U = P) on the latch
// edge before the refresh conjunct is consulted; and any NON-frozen φ on the
// same wire has an incoming whose `collectWireValues` closure REACHES the
// region's own arm `cq_theta`, so the fence answers `false` on its own terms.
// RETIREMENT TRIGGER, THREE WAYS: relax the phi-edge read-position rule, admit a
// non-φ `D` that can be frozen, or relax `LoopLowering::collapseRailPhisIn` step
// (1)'s LOOP-CARRIED guard (`kMsgCrossIter`, "cq loop lowering: loop-carried
// tainted value crosses iterations") — any of the three makes `phiTracksWire` the
// ONLY wall, so widen its vocabulary (or fence this caller) in the same change.
// The third is the ROUND-2 addition: a reviewer built the shape the two measured
// legs do not cover (a NON-frozen carry seeded from the region's MERGE value,
// the dtzb `add` after the region on the sibling chain, the carry read IN THE
// BODY so R6's path conjunct is satisfiable) and it declines — but on the
// loop-carried guard, not on either leg. Written identically at `WireWalk.h`'s
// declaration and in that fixture; all three move together.
//
// (It is also why the fence is KEPT although deleting it reds nothing — §6a /
// lens L1 Q1b. Defence in depth, measured redundant in every reachable shape,
// with the pre-existing `cq_*`-call-consumer hole bd test_C_libtooling-67s8 as
// what would be left uncovered if it went.)
//
// THE ONE WIDENING, STATED PLAINLY: the DOMINANCE conjunct that
// `provablyBeforePerActivation` bundles is deliberately DROPPED here, so
// `provablyBefore ⇒ certificate` and `cannotFollowGate ⇒ certificate` — the
// certificate is strictly WEAKER than both, which is exactly why the FLAT path
// must keep its own spelling verbatim and no acyclic shape may move. Dominance
// answers "did `U` definitely execute", a question R6 has never asked (see
// `cannotFollowGate`'s own header); keeping it in-loop would refuse the
// customer's own post-loop `cq_measure(r)`, whose read position sits in the exit
// block and dominates nothing.
//
// ⚠ TWO SETS, TWO QUESTIONS — UNCHANGED, and say so rather than deleting the
// distinction (bd [[rail-record-set-is-the-rail-not-the-chain]]). The MEMBER set
// whose users are enumerated stays `BaseWireOrder`; the SKIP set of alias hops
// stays `BaseWire`. In-loop BOTH obligations collapse to this one certificate —
// a RELAXATION for genuine reads and no change for hops — but the sets still
// differ; only the predicate they feed is now common.
bool recordLivePerActivation(Value *M, const Instruction *U,
                             const Instruction *BI) {
  auto *D = dyn_cast<Instruction>(M);
  if (!D)
    return false;  // a non-instruction member has no definition to re-execute.
  if (auto *DP = dyn_cast<PHINode>(D))
    if (!phiTracksWire(DP))
      return false;  // frozen carry — re-executing it does not re-read the wire.
  if (const auto *P = dyn_cast<PHINode>(U)) {
    bool NamesM = false;
    for (unsigned i = 0, e = P->getNumIncomingValues(); i != e; ++i) {
      if (P->getIncomingValue(i) != M)
        continue;
      NamesM = true;
      const Instruction *PU = P->getIncomingBlock(i)->getTerminator();
      assert(PU != D && "per-activation barrier must not be the read position");
      if (PU == D || !everyPathReExecutes(BI, PU, D))
        return false;
    }
    return NamesM;
  }
  assert(U != D && "per-activation barrier must not be the read position");
  if (U == D)
    return false;
  return everyPathReExecutes(BI, U, D);
}

// The angle operand of a rotation call, tainted? ONE spelling, shared with
// `taintedAngleGate`'s own lambda below (Rule 14) — the arg-1 angle is classical
// by Rule 3, and a quantum-derived one has no fixed unitary.
bool rotationAngleIsTainted(const CallInst *CI, const TaintSet &Taint) {
  return CI->arg_size() >= 2 && Taint.Tainted.count(CI->getArgOperand(1));
}

// ---- control-in-place ROTATION arm (control-in-place-PRD §4, bd
//      test_C_libtooling-drbq Inc 1) ------------------------------------------
//
// R1's shape half: is `ArmIncoming` a single in-place `cq_theta` gate that IS
// the whole arm? Returns the theta on a match, null otherwise (NotApplicable —
// the caller falls through to every pre-existing decline path unchanged).
//
//   * a `@cq_theta_<sfx>` CALL, defined IN `ArmBB` (an out-of-arm theta is the
//     routed base's own lineage, never an arm gate — the same arm-block bound
//     `walkPhaseSpine`/`walkValueChain` are built on, and for the same
//     double-collection reason);
//   * arg-0 either TAINTED (a CHAINED Ry on a live register — Inc 1) or
//     CLASSICAL (controlled STATE PREP, PRD §14 / Inc 4: the alloc hoists with
//     the gate and the merge φ's pred incoming owes the F1 seed-identity fence).
//     `StatePrep` reports which; the caller's clause owns the two fences;
//   * SOLE USER is the merge phi (no fan-out — Rule 8 linearity: the emitter
//     RAUWs the phi to the base, and a second consumer of the theta result
//     would be left reading a value that no longer exists);
//   * NOTHING ELSE in the arm block. `RegionFlatten` ERASES the arm block, so a
//     stray op is silently DROPPED from the IR and its taint work-list pointer
//     dangles — `armBlockIsPureSpine`'s two reasons, verbatim, which is why the
//     shape is tested the same way rather than by a second spelling.
CallInst *inPlaceRotationArmTheta(Value *ArmIncoming, const BasicBlock *ArmBB,
                                  const PHINode *MergePhi, TaintSet &Taint,
                                  bool &StatePrep) {
  StatePrep = false;
  auto *T = dyn_cast<CallInst>(ArmIncoming);
  if (!T || !isThetaCall(T) || T->getParent() != ArmBB || T->arg_size() < 2)
    return nullptr;
  // A CLASSICAL arg-0 is controlled STATE PREP (PRD §14, bd
  // test_C_libtooling-drbq Inc 4) — the theta MINTS the rail instead of rotating
  // a live one. It is recognized HERE and adjudicated by the clause (F1/F2/the
  // if/else clause), NOT refused here: refusing here would send every off-shape
  // state prep back to the generic `control flow` decline, and the whole point of
  // F1 and F2 is that the author must be told WHICH of the seed, the merge
  // incoming and the compare literal is the problem. `StatePrep` is an OUT
  // parameter rather than a second entry point so the three shape halves below
  // (defined in `ArmBB`, sole user is the merge φ, nothing else in the block)
  // are asked ONCE, of both classes, and cannot drift apart.
  //
  // ⚠ IT ADMITS ANY UNTAINTED arg-0, INCLUDING `undef` / a `ConstantExpr` / a
  // function ARGUMENT — deliberately. F1 is where the narrowing lives (a
  // `ConstantInt`/`ConstantFP`, or since bd z0re a RUNTIME SSA value —
  // `isRuntimeStatePrepSeed`), and it is one clause with one string; splitting
  // the test across two functions is how "the fence fires, but nobody can find
  // which" happens (§14.2a item 1).
  if (!Taint.Tainted.count(T->getArgOperand(0)))
    StatePrep = true;
  if (!T->hasOneUse() || T->user_back() != MergePhi)
    return nullptr;  // fan-out, or it does not feed the merge.
  for (const Instruction &I : *ArmBB)
    if (!I.isTerminator() && &I != T)
      return nullptr;  // a stray op the flatten would drop.
  return T;
}

// ---- F2 — THE SEMANTIC FORM. THE QUESTION, NOT A FOURTH ENUMERATION
//      (bd test_C_libtooling-drbq Inc 4, ROUND-3 Rule-13 review, lens R3 —
//      findings F-R3-1 / F-R3-2 / F-R3-3, 42 plain-C programs, every one graded
//      CONFIRMED-MISCOMPILE, every one ORACLE-decline / HEAD-accept, strict-2b
//      clean, linked and RUN) --------------------------------------------------
//
// ⚠ READ THIS BEFORE WIDENING ANYTHING HERE. F2's question is SEMANTIC:
//
//     after `clang -O1`, could the arm's constant SEED be the FOLD of a TAINTED
//     register that the source rotated IN PLACE and that is STILL ALIVE?
//
// It was answered THREE TIMES by a syntactic SET, and each generation was
// defeated by the next InstCombine rewrite. The three generations and their
// MEASURED defeats are recorded here deliberately — this is the memory the next
// widener needs, and it is the REASON the shape of the answer changed:
//
//   gen 1  (shipped Inc 4)   the compare's LITERAL `k`, bit-identical to the
//          seed. DEFEATED by round-1 lens L2: `int t = q & 1; if (t) { r = t;
//          cq_theta(&r,θ); }` pins `t` to 1 on the `!= 0` edge while `k` is 0 —
//          NINE plain-C spellings, all accepted, all in-place Ry on the
//          CONDITION register.
//   gen 2  (round-1 fix)     `H`'s EDGE RANGE (`computeConstantRange` ∩
//          `makeExactICmpRegion`). DEFEATED by round-2 lens R1: IPSCCP pins a
//          register `X` and substitutes it into the arm, and a LATER InstCombine
//          rewrites the compare DOWNWARD onto an ANCESTOR of `X` — so the `H`
//          the pass is handed is not the register the theorem was about. SIX
//          plain-C spellings.
//   gen 3  (round-2 fix)     `H`'s tainted FORWARD closure through same-type
//          integer `op constant`. DEFEATED THREE WAYS by round-3 lens R3:
//            (i)   `-O1` also moves the compare SIDEWAYS onto a fresh SIBLING —
//                  `q/4 == 5` becomes `icmp eq (and q,-4), 20` and `q/3 == 5`
//                  becomes `icmp ult (add q,-15), 3`, so `H` and the rotated
//                  register are two USERS OF THE SAME ROOT and no forward walk
//                  from `H` can reach it (30 programs);
//            (ii)  the SET was `BinaryOperator`-only while `IntrinsicLowering`
//                  lowers a curated 16-strong `llvm.*` integer family to real
//                  rails — `bswap`/`bitreverse`/`fshl`/`fshr` are the invertible
//                  members InstCombine relocates the compare across (4 programs);
//            (iii) the K/seed TYPE GATE one line above the walk's caller skipped
//                  ALL of F2 the moment `-O1` narrowed the compare to the root's
//                  width, which is what an ordinary `long long t = q;` does
//                  (8 programs).
//
// SO THE SET IS GONE. What replaces it is the question itself, asked with LLVM's
// OWN value machinery instead of a hand-picked opcode list:
//
//   (1) BACKWARD — `LazyValueInfo::getConstantRangeOnEdge`, asked on BOTH edges
//       of the region's branch about EVERY TAINTED INTEGER VALUE of the
//       function. LVI is a real EDGE analysis: it reads the branch condition
//       itself, so it recovers the pin for a register the compare mentions only
//       through an ancestor — `(Val & Mask) == C` yields `KnownBits` on `Val`,
//       and `icmp ult (Val + Off), C` yields a range on `Val`. Those are exactly
//       the two rewrites F-R3-1 measured, and they are recovered by an ANALYSIS
//       rather than by a preimage table that the next InstCombine can miss.
//   (2) FORWARD — from every value LVI constrains, an abstract evaluation over
//       the TAINTED USER graph with NO opcode filter in the accept direction:
//       `ConstantRange::binaryOp` / `castOp` / `intrinsic` / `icmp` where a range
//       models, EXACT `ConstantFoldInstOperands` / `ConstantFoldCall` the moment
//       every operand is pinned (which is what answers `bswap`, `bitreverse`,
//       `fshl`, `fshr`, every cast, and `sitofp` for an fp seed), and a
//       `KnownBits` refinement on every value learned.
//   (3) THE TEST is `Constant *` POINTER IDENTITY against the seed. LLVM uniques
//       `ConstantInt` on type+bits and `ConstantFP` on the `APFloat` BITS, so
//       this is F1's bit-identity discipline reused — and it covers an fp seed
//       (`-0.0` vs `0.0` correctly stays a non-match) at no extra cost. THERE IS
//       NO TYPE GATE ANY MORE: a value of the SEED'S type is asked about wherever
//       it lives and whatever width the compare ended up at (F-R3-2).
//
// THE ONE PLACE IT STILL SKIPS, AND THE ARGUMENT FOR IT — said plainly, because
// "not in my set ⇒ accept" is the exact default that lost three rounds. A tainted
// user whose value this evaluation cannot bound AND NONE of whose operands is
// exactly pinned is SKIPPED. The argument is not "we do not handle it". It is
// that the seed can only BE a fold if `clang` PERFORMED that fold; `clang`'s
// folds come from IPSCCP's `ConstantRange` lattice, InstCombine's `KnownBits`
// and `ConstantFolding` — all three of which ARE the machinery above — so a
// value LLVM's own lattice reports overdefined is a value LLVM could not have
// substituted a constant for. `@cq_theta` / `@cq_phi` are the everyday members:
// opaque declarations, overdefined by construction, so a CHAINED rotation's
// result is not a fold candidate and `..._stateprep_post_region_theta_cond.ll`
// keeps accepting.
//
// AND THE CONSERVATIVE HALF, which is where the brief's rule lands: if an
// instruction HAS a tainted operand that is EXACTLY PINNED and we still produce
// no abstract value for it, we DECLINE (`Truncated`) — "a function of a pinned
// register that we cannot evaluate". That over-declines only the COINCIDENCE
// where such a function's value happens to equal the seed, and it refuses the
// whole `load` / `extractvalue` / unmodelled-intrinsic direction rather than
// guessing at it.
//
// THE RESIDUAL that argument leaves is REAL and is written down rather than
// implied (PRD §14.2b / §14.11 Q3, notes §12): InstCombine's RELATIONSHIP folds
// (`x - x`, `simplifyWithOpReplaced`) can mint a constant no lattice sees. The
// sentence that stood here said "every one measured DELETES the register — which
// is the DELETED-REGISTER residual §14.11 Q3 already owns". ⚠ THAT WAS FALSE
// (bd test_C_libtooling-fmt3, 2026-09-28, measured): SimplifyCFG sinks two
// `cq_theta` arms that differ in ONE operand, FoldTwoEntryPHINode builds
// `select (q == 20), t, 5`, and `simplifyWithOpReplaced(t, q := 20)` folds it to
// the literal with `t` LIVE and MEASURED (`fmt3_probes/src/n13.c`, `n14.c`,
// `n17.c`, `n17f.c`) — and, worse, the branch whose edge proved the pin was
// ERASED, so this function's question (asked on the REGION's own two edges) could
// not see it at all, and in the no-region members there was no region to ask
// about. That class is closed UPSTREAM, not here, and only PARTLY: `include/CQ.h`
// puts `nomerge` on every `cq_theta_*`, so two DIRECT calls are never merged and
// the erasing fold does not happen for them (owner ruling, option B). ⚠ It is NOT
// closed (fmt3 round 2, Rule-13 r1A): clang puts `nomerge` on the CALL SITE, so a
// call through a FUNCTION POINTER is merged exactly as before (bd `4e4p`, P1,
// PRE-EXISTING); and the arg-0 `select (t == s), t, s` → `s` fold erases a quantum
// register's identity with NO merge at all (bd `uw5u`, P1, PRE-EXISTING — the
// pass's own `DeadValueLiveness` fold performs it too). What else survives of this
// paragraph is the DELETED-register residual (§14.11 Q3) for the non-merge
// relationship folds, still a measurement and not a theorem. The other premise
// above — "the seed can only BE a fold if `clang` PERFORMED that fold [with this
// machinery]" — also assumed the pinning edge is the region's own; `nomerge`
// guarantees that only for direct calls, and any `-O1` route that erases a branch
// WITHOUT merging two direct calls re-opens it (retirement trigger; 4e4p is one).
//
// MONOTONE, exactly as before: this block only ever DECLINES. A range that is
// too WIDE loses a decline (the residual); a range that is too NARROW, or a
// bound that trips, costs an over-decline. Neither direction can turn a decline
// into an accept.
constexpr unsigned kF2MaxSteps = 4096;
// `ConstantRange::fromKnownBits` is a HULL: it cannot represent `{0,4}` and
// answers `[0,5)` (round-2 lens R1 finding F-R1-3, the recorded over-accept).
// When `KnownBits` leaves few enough bits unknown, ENUMERATE the consistent
// values and intersect with the range instead — the fix F-R1-3 itself named.
// 8 unknown bits = at most 256 candidates.
constexpr unsigned kF2KnownBitsEnumUnknownMax = 8;

// One EDGE's abstract state. `Rs` is indexed through `Idx` (rather than a
// `DenseMap<Value*, ConstantRange>`) so the state is deterministic and
// `ConstantRange`'s missing default constructor never has to be worked around.
struct F2State {
  DenseMap<Value *, unsigned> Idx;    // integer value -> index into `Rs`
  SmallVector<ConstantRange, 32> Rs;
  DenseMap<Value *, Constant *> Cst;  // ANY type: the EXACT constant, when known
  SmallVector<Value *, 32> WL;
};

// The exact constant `V` is pinned to under `S`, or null. An integer singleton
// range IS an exact constant — the two representations are kept in step here and
// nowhere else, so a caller cannot ask the question two ways.
Constant *f2Exact(Value *V, F2State &S) {
  if (auto *C = dyn_cast<Constant>(V))
    return C;
  auto CI = S.Cst.find(V);
  if (CI != S.Cst.end())
    return CI->second;
  auto It = S.Idx.find(V);
  if (It != S.Idx.end())
    if (const APInt *Sing = S.Rs[It->second].getSingleElement())
      return ConstantInt::get(V->getType(), *Sing);
  return nullptr;
}

// `V`'s range under `S`; FULL when unknown. FULL is the sound top element, so
// every operator below returns a sound SUPERSET of the true value set.
ConstantRange f2Range(Value *V, F2State &S) {
  unsigned BW = V->getType()->getIntegerBitWidth();
  if (auto *C = dyn_cast<ConstantInt>(V))
    return ConstantRange(C->getValue());
  auto It = S.Idx.find(V);
  if (It != S.Idx.end())
    return S.Rs[It->second];
  return ConstantRange::getFull(BW);
}

// Sharpen `R` with everything ValueTracking knows about `V` STRUCTURALLY.
// `CxtI` is deliberately null (and `AC` therefore inert for the context walk):
// this is a question about the VALUE, asked at no program point, and the
// `llvm.assume` direction is refused a layer up by `declineTaintEscapes`. The
// enumeration is the `fromKnownBits`-hull repair named in F-R1-3.
ConstantRange f2Refine(Value *V, ConstantRange R, const DataLayout &DL,
                       AssumptionCache *AC, const DominatorTree *DT) {
  const unsigned BW = R.getBitWidth();
  if (R.isEmptySet())
    return R;
  KnownBits KB = computeKnownBits(V, DL, /*Depth=*/0, AC, /*CxtI=*/nullptr, DT);
  R = R.intersectWith(ConstantRange::fromKnownBits(KB, /*IsSigned=*/false));
  R = R.intersectWith(ConstantRange::fromKnownBits(KB, /*IsSigned=*/true));
  R = R.intersectWith(computeConstantRange(V, /*ForSigned=*/false,
                                           /*UseInstrInfo=*/true, AC,
                                           /*CtxI=*/nullptr, DT));
  R = R.intersectWith(computeConstantRange(V, /*ForSigned=*/true,
                                           /*UseInstrInfo=*/true, AC,
                                           /*CtxI=*/nullptr, DT));
  if (R.isEmptySet())
    return R;
  APInt Unknown = ~(KB.Zero | KB.One);
  const unsigned NU = Unknown.popcount();
  if (NU >= 1 && NU <= kF2KnownBitsEnumUnknownMax) {
    SmallVector<unsigned, 8> Bits;
    for (unsigned b = 0; b < BW; ++b)
      if (Unknown[b])
        Bits.push_back(b);
    APInt Keep(BW, 0);
    unsigned Count = 0;
    for (unsigned m = 0, N = 1u << NU; m < N && Count < 2; ++m) {
      APInt Cand = KB.One;
      for (unsigned i = 0; i < NU; ++i)
        if (m & (1u << i))
          Cand.setBit(Bits[i]);
      if (!R.contains(Cand))
        continue;
      if (++Count == 1)
        Keep = Cand;
    }
    if (Count == 1)
      return ConstantRange(Keep);
  }
  return R;
}

// Record a range for `V`, INTERSECTING with anything already known (two
// derivations of one value are both sound supersets, so their intersection is
// too). Re-queues on a strict narrowing, which is what makes the walk a fixpoint
// rather than a single sweep.
void f2Note(Value *V, ConstantRange R, F2State &S) {
  if (R.isEmptySet())
    return;  // a contradiction on this edge: nothing to learn, nothing to fear.
  auto It = S.Idx.find(V);
  if (It == S.Idx.end()) {
    if (R.isFullSet())
      return;
    S.Idx[V] = S.Rs.size();
    S.Rs.push_back(R);
    S.WL.push_back(V);
    return;
  }
  ConstantRange N = S.Rs[It->second].intersectWith(R);
  if (N == S.Rs[It->second])
    return;
  S.Rs[It->second] = N;
  S.WL.push_back(V);
}

// bd dm7f.18 — the four curated f64 trig ids LLVM 19 cannot fold, evaluated the
// way ConstantFolding evaluates the `tan`/`asin`/`acos`/`atan` LIBCALLS
// (`ConstantFoldFP`: host libm on the double, no fold for a NaN or infinite
// result). A `-fmath-errno` frontend (Linux) emits and folds those libcalls
// before the pass binds them to these intrinsics, so the fold is what clang
// could have substituted. On darwin clang emits the intrinsics and folds
// nothing (review round 2 F4): there the fold only adds a decline for a seed
// that is bit-equal to the value, the safe direction. This fold refuses only
// NaN/inf results while LLVM also refuses underflow and non-finite inputs, a
// superset (also safe). ASSUMPTION: frontend and pass run on ONE host libm. IR
// folded by another libm (glibc, `-fmath-errno`) and lowered here could differ
// by an ulp, so F2 would miss a substituted seed (review round 3).
Constant *foldCuratedTrigF64(const CallInst *CI, ArrayRef<Constant *> Ops) {
  const auto *II = dyn_cast<IntrinsicInst>(CI);
  const auto *X = Ops.size() == 1 ? dyn_cast<ConstantFP>(Ops[0]) : nullptr;
  if (!II || !X || !X->getType()->isDoubleTy())
    return nullptr;
  const double V = X->getValueAPF().convertToDouble();
  double R;
  switch (II->getIntrinsicID()) {
  case Intrinsic::tan:
    R = std::tan(V);
    break;
  case Intrinsic::asin:
    R = std::asin(V);
    break;
  case Intrinsic::acos:
    R = std::acos(V);
    break;
  case Intrinsic::atan:
    R = std::atan(V);
    break;
  default:
    return nullptr;
  }
  if (std::isnan(R) || std::isinf(R))
    return nullptr;
  return ConstantFP::get(X->getType(), R);
}

void f2NoteConst(Value *V, Constant *C, F2State &S) {
  if (auto *CI = dyn_cast<ConstantInt>(C)) {
    f2Note(V, ConstantRange(CI->getValue()), S);
    return;
  }
  if (S.Cst.find(V) == S.Cst.end()) {
    S.Cst[V] = C;
    S.WL.push_back(V);
  }
}

// Evaluate ONE tainted user `I`. Returns FALSE only in the conservative case:
// `I` has a tainted operand that is EXACTLY PINNED and no abstract value could
// be produced for `I` (the caller turns that into a loud F2 decline).
bool f2Model(Instruction *I, F2State &S, const DataLayout &DL,
             AssumptionCache *AC, const DominatorTree *DT) {
  Type *Ty = I->getType();
  bool AnyPinnedOperand = false;

  if (auto *CB = dyn_cast<CallBase>(I)) {
    Function *Callee = CB->getCalledFunction();
    // ⚠ THE ORDER OF THE NEXT TWO BLOCKS IS THE FINDING, NOT A STYLE CHOICE
    // (round-4 Rule-13 review, lens R4, F-R4-3 item 1). `AnyPinnedOperand` is
    // computed BEFORE the not-foldable early return, because the header's own
    // statement of the conservative rule — "a tainted operand that is EXACTLY
    // PINNED, feeding something we cannot evaluate, DECLINES" — was FALSE for
    // the whole `CallBase` class: the early return ran first, so the rule was
    // never asked there. MEASURED before the fix (`$S/fix4/p/nbf.ll`, a
    // `nobuiltin`-attributed `@llvm.bswap.i32` whose operand is pinned to 5 and
    // whose seed is `bswap(5)` = 83886080): ACCEPT. After: DECLINE.
    SmallVector<Constant *, 4> Ops;
    bool AllConst = true;
    for (Value *A : CB->args()) {
      Constant *C = f2Exact(A, S);
      if (!C) {
        AllConst = false;
        continue;
      }
      if (!isa<Constant>(A))
        AnyPinnedOperand = true;
      Ops.push_back(C);
    }
    // NOT constant-foldable by LLVM ⇒ for an OPAQUE callee, NOT a fold
    // candidate: `clang`'s own lattice is overdefined here too, so it cannot
    // have substituted the seed FROM this value. `@cq_theta` / `@cq_phi` are
    // the everyday members, and a Phase-6 specialised clone call is the other
    // one — for both, "LLVM cannot fold it" is a statement about the VALUE, and
    // the skip is the same argument the header makes for the whole forward half.
    //
    // A CURATED REVERSIBLE INTRINSIC IS NOT IN THAT CLASS, and telling the two
    // apart is F-R4-3's fix. Every member of that set is a pure, total function
    // of its operands that CQ LOWERS TO A RAIL (`isCuratedReversibleIntrinsic`
    // is the same predicate `OpcodeLowering` enqueues on, so the two cannot
    // drift — Rule 14): for one of those, "`canConstantFoldCallTo` said no" is
    // an artefact of LLVM's fold TABLE (a `nobuiltin` call site, a signature
    // mismatch, a future curated id LLVM never taught itself to fold), not
    // evidence that the value is unknowable. So a pinned operand feeding one we
    // could not evaluate takes the conservative DECLINE.
    //
    // ⚠ "MEASURED at LLVM 19: this branch has NO live customer" stood here and
    // went false with 66f18d19 (bd dm7f.18): the curated set gained
    // `llvm.tan`/`asin`/`acos`/`atan`, which LLVM 19 does NOT fold (it folds
    // `llvm.sin`/`cos`, and the `tan`/`asin`/`acos`/`atan` LIBCALLS a
    // `-fmath-errno` frontend emits).
    // So those four are folded here with the host libm, exactly as
    // ConstantFolding folds the libcalls (`ConstantFoldFP`: a NaN/inf result is
    // left unfolded), and F2 compares the value instead of declining blind
    // (control_inplace_ry_accept_stateprep_curated_trig_fold.ll and its
    // `_equal` decline twin). A curated id neither LLVM nor this fold can
    // evaluate keeps the conservative decline below.
    if (!Callee || !canConstantFoldCallTo(CB, Callee)) {
      const auto *CI = dyn_cast<CallInst>(CB);
      if (CI && isCuratedReversibleIntrinsic(CI)) {
        if (AllConst)
          if (Constant *R = foldCuratedTrigF64(CI, Ops)) {
            f2NoteConst(I, R, S);
            return true;
          }
        return !AnyPinnedOperand;
      }
      return true;
    }
    if (AllConst)
      if (Constant *R = ConstantFoldCall(CB, Callee, Ops, /*TLI=*/nullptr)) {
        f2NoteConst(I, R, S);
        return true;
      }
    // The range model for the intrinsics `ConstantRange` supports — which is
    // the SAME set IPSCCP's `visitIntrinsicCall` uses, so this tracks `clang`
    // exactly rather than approximating it.
    if (auto *II = dyn_cast<IntrinsicInst>(I))
      if (Ty->isIntegerTy() &&
          ConstantRange::isIntrinsicSupported(II->getIntrinsicID())) {
        SmallVector<ConstantRange, 3> ORs;
        bool Ok = true;
        for (Value *A : CB->args()) {
          if (!A->getType()->isIntegerTy()) {
            Ok = false;
            break;
          }
          ORs.push_back(f2Range(A, S));
        }
        if (Ok) {
          f2Note(I,
                 f2Refine(I,
                          ConstantRange::intrinsic(II->getIntrinsicID(), ORs),
                          DL, AC, DT),
                 S);
          return true;
        }
      }
    return !AnyPinnedOperand;
  }

  // EXACT — every operand pinned. This is the uniform answer for every opcode
  // LLVM itself can fold, and it is what closes F-R3-3 without an opcode table.
  {
    SmallVector<Constant *, 4> Ops;
    bool AllConst = true;
    for (Value *O : I->operands()) {
      Constant *C = f2Exact(O, S);
      if (!C) {
        AllConst = false;
        break;
      }
      if (!isa<Constant>(O))
        AnyPinnedOperand = true;
      Ops.push_back(C);
    }
    if (AllConst && !isa<PHINode>(I))
      if (Constant *R = ConstantFoldInstOperands(I, Ops, DL)) {
        f2NoteConst(I, R, S);
        return true;
      }
  }
  if (!AnyPinnedOperand)
    for (Value *O : I->operands())
      if (!isa<Constant>(O) && f2Exact(O, S))
        AnyPinnedOperand = true;

  if (Ty->isIntegerTy()) {
    const unsigned BW = Ty->getIntegerBitWidth();
    if (auto *BO = dyn_cast<BinaryOperator>(I)) {
      f2Note(I,
             f2Refine(I,
                      f2Range(BO->getOperand(0), S)
                          .binaryOp(BO->getOpcode(), f2Range(BO->getOperand(1), S)),
                      DL, AC, DT),
             S);
      return true;
    }
    if (auto *CI = dyn_cast<CastInst>(I)) {
      if (CI->getSrcTy()->isIntegerTy()) {
        f2Note(I,
               f2Refine(I,
                        f2Range(CI->getOperand(0), S)
                            .castOp(CI->getOpcode(), BW),
                        DL, AC, DT),
               S);
        return true;
      }
      return !AnyPinnedOperand;
    }
    if (auto *IC = dyn_cast<ICmpInst>(I)) {
      ConstantRange L = f2Range(IC->getOperand(0), S);
      ConstantRange Rr = f2Range(IC->getOperand(1), S);
      ConstantRange Res = ConstantRange::getFull(BW);
      if (!L.isEmptySet() && !Rr.isEmptySet()) {
        if (L.icmp(IC->getPredicate(), Rr))
          Res = ConstantRange(APInt(BW, 1));
        else if (L.icmp(IC->getInversePredicate(), Rr))
          Res = ConstantRange(APInt(BW, 0));
      }
      f2Note(I, f2Refine(I, Res, DL, AC, DT), S);
      return true;
    }
    if (auto *SI = dyn_cast<SelectInst>(I)) {
      if (SI->getTrueValue()->getType()->isIntegerTy()) {
        f2Note(I,
               f2Refine(I,
                        f2Range(SI->getTrueValue(), S)
                            .unionWith(f2Range(SI->getFalseValue(), S)),
                        DL, AC, DT),
               S);
        return true;
      }
      return !AnyPinnedOperand;
    }
    if (auto *PN = dyn_cast<PHINode>(I)) {
      ConstantRange U = ConstantRange::getEmpty(BW);
      for (Value *In : PN->incoming_values())
        U = U.unionWith(f2Range(In, S));
      f2Note(I, f2Refine(I, U, DL, AC, DT), S);
      return true;
    }
    if (isa<FreezeInst>(I)) {
      f2Note(I, f2Refine(I, f2Range(I->getOperand(0), S), DL, AC, DT), S);
      return true;
    }
    return !AnyPinnedOperand;
  }
  return !AnyPinnedOperand;
}

// F2's question, asked semantically. TRUE ⇒ some live tainted value of the
// SEED'S type that is **NOT ON THE CONDITION'S OWN WIRE** is provably EQUAL to
// the seed on one of the branch's two edges, i.e. the source the author wrote
// could have been `cq_theta(&<that register>,θ)` and this arm's constant is
// `-O1`'s fold of it. `Truncated` ⇒ the evaluation could not be completed; the
// caller declines on that too.
//
// ---- `CondWire` — THE 2026-09-11 NARROWING (owner ruling; bd `drbq.14`) ----
//
// OWNER RULING, verbatim: *"WE DO NOT WANT TO WRITE `int b1`. also WE DO NOT
// WANT ANOTHER cq function. it should just be an application of gates … I dont
// see the need for the over-decline."* The trade below was put to the owner
// plainly and was not vetoed.
//
// WHAT CHANGED: a pinned value that is IN THE CONDITION'S OWN BACKWARD WIRE is
// no longer a collider. Every other pinned value still declines, with the same
// string. `CondWire` is `{Region.Condition} ∪ ⋃_{P ∈ condProvenance(Cond)}
// railWireClosure(P, WireDir::BackwardOnly)` — built at the caller **by calling
// R4's own helper**, never re-spelled (Rule 14; the drbq Inc-3 (b′) lesson).
//
// ⚠ SAY OUT LOUD WHAT THAT SET IS, BECAUSE "THE CONDITION'S OWN WIRE" READS
// FAR NARROWER THAN IT IS (round-1 review item I-3). `condProvenance` follows
// **EVERY** operand edge backward, stopping only at a `cq_theta` source — so
// `CondWire` is the condition's whole backward **TAINTED CONE**, and it contains
// values reached through `mul`, `and`, `shl`, `load`, casts and templates, whose
// physical RAILS are genuinely DISTINCT from the condition's. Excluding those is
// therefore NOT justified by "it is the same rail". It is justified by one fact
// and nothing else, and here it is as a sentence:
//
//     `CondWire` is **byte-identically the set R4 builds as `CondRails`** — the
//     same helper, over the same `Prov`, with the same `Taint`, at the same
//     program point, in the same `BackwardOnly` direction — so every value F2
//     stops colliding on is a value R4 would decline a rotation arm for. The
//     over-approximation in F2's exclusion set CANCELS EXACTLY against the
//     over-approximation in R4's refusal. The safety of this narrowing is an
//     argument about the EQUALITY OF TWO SETS, not about physical rails.
//
// The cancellation survives the rival module because a rival differs from the
// prep module only in a FORWARD position (which register the arm rotates) while
// both closures are `BackwardOnly`, so the two sets are the same set in both. It
// survives the `r9e5` round-2 taint window for the same reason: both are keyed
// on the same `Taint` and shrink together.
//
// ⚠ RETIREMENT TRIGGER (I-3), and it is the cheapest one here to trip by
// accident: **if `railWireClosure` as called here and R4's `CondRails` ever
// DIVERGE — a different helper, a different `WireDir`, a different seed set, an
// `Exclude` argument passed on one side and not the other, or one call site
// "tidied" — this narrowing must be RE-DERIVED FROM SCRATCH.** Nothing in the
// fixture corpus would notice a small divergence except
// `..._stateprep_condwire_alias_accept.ll`, and that file pins only the
// chained-theta hop; a divergence anywhere else in the cone is silent.
//
// ⚠ THERE ARE **TWO** ADMISSIBILITY ARGUMENTS, NOT ONE, AND THEY COVER DIFFERENT
// HALVES OF THE ACCEPT CLASS. Do not let the first stand in for the second: the
// R4 theorem below covers the **α** rivals (an in-place Ry on the condition's
// own register), and it does NOT reach the **β** rivals (a merge incoming that
// was a live register `-O1` folded to the seed). β has its own argument, from
// the state vector, in the "WHAT THIS SILENTLY ABSORBS" block at the end of this
// header — and it rests on a DIFFERENT kind of assumption (LLVM's own edge
// analysis being sound, rather than a structural property of this pass), which
// is why a Rule-13 round should attack the two separately.
//
// WHY THE α HALF IS ADMISSIBLE — AND IT IS A THEOREM ABOUT R4, NOT A SURVEY. The
// alternative reading of an in-cone pin is *"the source rotated the CONDITION'S
// OWN register in place and `-O1` folded arg-0 to the literal"*. That reading
// has never had a lowering in CQ and **cannot acquire one while R4 stands**:
// `railWireClosure` does `Out.insert(W)` BEFORE any gate, so
// `RotBase ∈ BaseWireOrder` unconditionally, so `RotBase ∈ CondRails ⇒ R4
// declines` for every CHAINED (register-arg-0) rotation arm. The only way past
// R4 is `StatePrep` — which is the folded case under discussion, i.e. the case
// where the register no longer appears in the module at all. So the excluded
// set is one for which a proof exists, not one for which a survey came back
// clean. (The survey was run anyway: SCOPE §2.2 measured 19/19 unfolded
// spellings declining, plus 13 plain-C ones.) ⚠ BUT R4 IS NOT THE FENCE THAT
// ACTUALLY FIRES — it fired for **0 of the 27** rivals measured to date. Read
// the retirement trigger below for the split before relying on the theorem.
//
// ⚠ RETIREMENT TRIGGER, WRITTEN NOW RATHER THAN DISCOVERED LATER (SCOPE H-4,
// the bd 8h7d.5 F-1/F-3 discipline). The trigger is *"the day any chained
// rotation arm whose `RotBase` is in `CondRails` LOWERS, this narrowing becomes
// an OVER-ACCEPT and must be re-derived from scratch"*, and it has TWO doors.
// **THEY ARE RANKED HERE BY MEASURED RISK, NOT BY WHICH FENCE THE THEOREM
// NAMES** (round-1 review item I-1):
//
//   1. **2c `condition predates a non-diagonal gate` — THE LIVE DOOR.** This is
//      the fence that actually refuses the α rivals today, and it has been made
//      MORE PERMISSIVE twice in this epic's history (drbq Inc 3's position-aware
//      accept; lom0 Inc 4's). Make it position-aware enough to admit a
//      post-region rotation on the condition's wire and this narrowing is an
//      over-accept — whatever R4 still says, and with no fixture moving.
//      "Rotate the flag in place" is a live Grover-ancilla wish, so treat this
//      as a warning about a plausible future rather than a formality.
//   2. **R4 `rotation arm on a condition wire` — the BACKSTOP the theorem is
//      about.** Narrowing it retires the proof; but nothing reaches it today.
//
// MEASURED over the 27 alternative readings built for this increment (IMPL's 21
// `probes/alt/` modules + the round-1 review's 6 `rival/` ones), the fence that
// FIRES:
//     2c  `condition predates a non-diagonal gate` ............... **16**
//     F1  `state prep merged with a quantum register` ............     5
//         `condition data use neither escaped nor measured` ......     5
//         `bare i1 register condition` (bd `l4x4`) ..............      1
//     **R4 `rotation arm on a condition wire`** ................. **0**
// R4 is NOT vacuous — `probes/v3.c`, the alias-hop rival, does decline on it —
// it is simply never REACHED, because 2c stands in front of every direct α
// rival, including the on-wire row of the round-1 review's F-2 matrix. So a
// change to **2c**, not only a change to R4, can invalidate this narrowing.
// The mirror obligation is already recorded at R4: narrowing `condProvenance` is
// now a Rule-13 change to **two** fences (R4 *and* F2), not one.
//
// ⚠ AND THE EXCLUSION IS APPLIED AT THE **TEST**, NEVER AT THE **ANCHOR**
// (SCOPE H-6 — the one way to get this change catastrophically wrong).
// `CondWire` members keep SEEDING the forward evaluation: they are still fed to
// `f2Note`/`f2NoteConst` and their users are still modelled, so every value
// DERIVED from the condition is still reached and still tested. Only the
// *answer* is filtered. Dropping them from `Cand` (or from the fp anchor)
// instead would stop the walk before it started. MEASURED 2026-09-11 on exactly
// that mutant: **ALL 40** F2 fixtures flip — not the 19, but every one —
// including the six F-R1-1 CONFIRMED plain-C miscompiles, the 30-program
// sideways family, the four curated-`llvm.*` rails and the three cast rails.
// The tripwire fixtures — MEASURED RED on the anchor spelling and green here —
// are `..._reject_stateprep_fcmp_oeq_derived.ll` (the pin ONE HOP forward of the
// fp anchor's seed: it can only stay a decline while the anchor still SEEDS),
// `..._reject_stateprep_range_forward_add.ll`,
// `..._reject_stateprep_second_flag_i1.ll` and
// `..._reject_stateprep_offwire_sideways_min.ll`.
//
// ⚠ AND THE ANCHOR SPELLING'S DAMAGE IS NOT UNIFORM, WHICH IS A BETTER REASON TO
// REFUSE IT THAN "IT FLIPS EVERYTHING" (measured 2026-09-11, after the inference
// was checked and found wrong for one file):
// `..._reject_stateprep_nonwire_still_collides.ll` KEEPS declining under the
// anchor mutant. Its off-wire pin `%t = lshr %q, 31` is one LVI can answer about
// DIRECTLY on the edge, so `%t` is its own `Cand` entry and never needed the
// forward walk; the four above are pins LVI cannot reach on its own and that
// only the forward evaluation from an ON-WIRE seed produces. So at the anchor,
// whether an out-of-cone CONFIRMED miscompile survives depends on whether LVI
// happens to model that opcode — i.e. the fence's coverage would be decided by
// an LLVM implementation detail nobody here controls, and would move silently
// when LLVM improves. At the TEST it does not depend on that at all.
//
// ⚠ AND `Truncated` IS UNTOUCHED — a SECOND, INDEPENDENT reason the exclusion
// belongs here rather than at the anchor. No `CondWire` check sits on any path
// that sets it, so the conservative half — the one that catches what LLVM's own
// machinery cannot evaluate — is not selectively skippable (SCOPE H-8).
// MEASURED on the same anchor mutant, and it is worse than SCOPE predicted:
// `step_cap_over`, `unevaluable_pinned_operand` and `unfoldable_curated_call`
// flipped to ACCEPT there too, because a SMALLER CANDIDATE LIST NEVER TRIPS THE
// 4096-STEP BOUND. At the anchor, filtering the exclusion set silently disables
// the very half of F2 that exists for the cases no analysis can decide. On the
// shipped spelling all three are byte-unchanged and never reach the test.
//
// WHAT THIS SILENTLY ABSORBS, said in the words it must be said in (SCOPE H-1 /
// H-2): a program that was LOUDLY REFUSED yesterday now receives the circuit for
// the *other* reading.
//   * α (15 of the 19) — the plain-C illustration is `int r = k; if (q == k)
//     { r = q; cq_theta(&r, θ); }`, which is BYTE-IDENTICAL after `-O1` to the genuine
//     prep (MEASURED: `probes/a_prep.c` vs `probes/a_self.c`, `diff` empty). It
//     now compiles as a fresh rail rotated under the flag, `q` never touched.
//     ⚠ **DO NOT ATTACK THIS FENCE WITH THAT SPELLING — IT IS THE WRONG RIVAL**
//     (round-1 review item I-2). For the accepted IR `phi [ %rt, %arm ],
//     [ k, %entry ]` that spelling's `RotBase` is the REGISTER `%q` while the
//     straight-through incoming is the LITERAL `k`, so **R3's "ONE base" clause
//     refuses it before R4 is ever asked**; and `probes/u1.c` measures that the
//     plain-C form cannot even produce a state-prep module (the Pred edge does
//     not pin `q`, so only arg-0 folds and F1 fires).
//
//     THE RIVAL THAT CAN ACTUALLY PRODUCE THE ACCEPTED IR needs **BOTH** the
//     arm's arg-0 AND the merge incoming to fold — i.e. a register pinned on
//     BOTH edges. That is the `%t = and %q, 0` shape of
//     `..._stateprep_condwire_alias_accept.ll`, and it is what a future round
//     should try to break this with:
//
//         %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
//         %t  = and i32 %q, 0                       ; singleton {0}, BOTH edges
//         %b  = call i32 @cq_theta_si32(i32 %t, double 3.000000e-01)
//         %c  = icmp eq i32 %b, 5
//         br i1 %c, label %arm, label %merge
//       arm:
//         %rt = call i32 @cq_theta_si32(i32 %t, double 9.000000e-01)   ; <- RIVAL
//         br label %merge
//       merge:
//         %rm = phi i32 [ %rt, %arm ], [ %t, %entry ]                  ; <- RIVAL
//
//     Both `%t` uses fold to `i32 0`, so `-O1` hands the pass the accepted prep
//     module verbatim. This is a GENUINE in-place rotation arm, and it **DOES
//     lower when it is OFF-wire** — delete the chained `%b` and condition on
//     `icmp eq i32 %q, 5`: rc=0 on BOTH binaries, emitting
//     `cqrt_ry_i32_controlled(h_cmp, h_op, 0.9)` in place on `%t` (the drbq
//     Inc-1 shape). ON-wire it declines `condition predates a non-diagonal gate`
//     on both binaries, because `%t` and `%b` are ONE physical rail and rotating
//     `%t` IS rotating the register the flag is minted from. That matched 2x2 is
//     the round-1 review's F-2 and is the measurement the α theorem is worth:
//     **where the rival has a lowering, F2 still declines its folded image;
//     where the narrowing removes the decline, the rival has no lowering to be
//     robbed of.**
//   * β (4 of the 19) — the straight-through incoming was a live register
//     `-O1` folded to the seed. On THAT edge the register is pinned to the seed
//     by a SOUND edge fact, so within the `f`-subspace its rail is the product
//     basis state |seed⟩: a controlled copy of it into a fresh |0⟩ rail yields
//     |seed⟩⊗|seed⟩, which is exactly what preparing |seed⟩ yields. There is no
//     superposition on that edge to clone, so the two readings agree there — and
//     they already agreed on the other edge, where the arm's seed is a literal
//     in both. See `..._stateprep_mux_incoming_pinned_accept.ll`.
//
// ---- THERE IS A **SECOND** EXCLUSION AT THE SAME TEST: R-1, 2026-09-13 ----
//
// `Taint.isPeelClone(V)` (bd `test_C_libtooling-rb9x`). `MergePhiPeel`'s compare
// CLONES are not colliders, on the PREIMAGE ground — a value this pass
// manufactured has no source program behind it, so it is not a register the
// author could have rotated. It is a different kind of argument from
// `CondWire`'s (no rival enumeration at all), it is stated in full at the test
// below and in `TaintSet::PeelClones`' header, and the two exclusions are
// INDEPENDENT: neither subsumes the other (a clone of a SECOND fused region's
// condition is off the wire, and an in-cone value the user wrote is not a
// clone). Both are applied at the TEST and neither touches `Truncated`.
//
// ---- AND A **THIRD**, AT THE SAME TEST: the φ-DESCENDANT rule, 2026-09-14,
// ---- MADE PRECISE AND OPCODE-AGNOSTIC 2026-09-15 ----
//
// `PhiDesc.count(V)` (bd `test_C_libtooling-om35`, OWNER-RULED 2026-09-14; bd
// `test_C_libtooling-hrts` + `l3i1` + `dpau`, 2026-09-15). A value in the
// transitive USER closure of the region's OWN state-prep merge φ, **truncated at
// any value that is itself AVAILABLE at one of F2's two slots**, is not a
// collider. ⚠ The truncation clause is not a detail and is not conservatism: a
// value that merely USES `M` can be available at a slot (a loop-header φ taking
// an `M`-descendant on its BACK EDGE is exactly that), and a user of such a
// value is SPELLABLE at the slot, hence a genuine rival — so enqueuing past one
// would be an OVER-ACCEPT. **THE GROUND IS AVAILABILITY, NOT "THE SAME WIRE"** — say it
// that way, because the wire reading is false here and would license a different
// set: the excluded values are frequently on a DIFFERENT wire from the condition
// (the owner's cascade excludes `icmp sgt (select %phi, …), 2`, which is off the
// condition's backward cone entirely, and is exactly why `CondWire` does not
// already cover it).
//
// THE ARGUMENT, IN FULL — AND IT IS AN **OPERAND** ARGUMENT, NOT A POSITION
// ONE. This function's question is *"the source the author wrote could have been
// `cq_theta(&<that register>, θ)`"*, and the register it is asking about can
// occupy exactly two slots of the module in front of us: the ARM theta's arg-0,
// or the merge φ's PRED-edge incoming. The φ `M` is defined AT THE JOIN, so `M`
// IS NOT AVAILABLE AT EITHER SLOT — and therefore any `V` whose OPERANDS reach
// `M` CANNOT BE SPELLED AT EITHER SLOT, IN ANY MODULE:
//   * not at the ARM slot — `M` does not dominate the arm block (the arm is a
//     PREDECESSOR of `M`'s block), so an operand chain through `M` cannot be
//     written there;
//   * not at the PRED slot — a φ incoming must dominate its incoming EDGE, and
//     `M`'s block does not dominate `Pred`; spelling `V` there is
//     use-before-def, i.e. not a module at all.
// A value whose operands did not exist yet at either slot is not a register the
// author could have named in the definition of `M` itself. It is therefore
// outside the question's domain, exactly as R-1's manufactured clone is.
//
// ⚠ DO NOT COMPRESS THIS TO *"`V` SITS AFTER THE JOIN, SO IT IS AVAILABLE AT
// NEITHER SLOT"*. That sentence is about POSITION, it is the refused dominance
// conjunct in disguise, and **it is false**: `-O1` SINKS, so the ≥11 shipped
// merge-block colliders also sit after the join and are genuine rivals precisely
// because their position is a consequence of the fold, not evidence about the
// source. Sinking moves a definition and NEVER rewrites its operands, which is
// why the operand form survives it and the position form does not. (Nor can a
// pre-region value ACQUIRE a use of `M` in place: that would be invalid SSA, so
// no pass can do it at any -O level — round-1 review §2a.)
//
// ⚠ THIS IS **NOT** THE DOMINANCE CONJUNCT, WHICH STAYS REFUSED IN WRITING.
// "Defined after the branch" is NOT "uses the region's own φ", and the whole
// F-R3-1 family lives in the gap: `range_forward_*`, `sideways_*`,
// `merge_edge_sideways`, `offwire_sideways_min` and `step_cap_over` all pin
// colliders defined in the MERGE BLOCK — post-branch — and NONE of them uses the
// φ (measured 2026-09-14, 25/25 of the shipped pin fixtures + all 4 `Truncated`
// ones: `collider-uses-phi = no`). A dominance test flips all of them and
// re-opens measured over-accept holes; this test moves NONE of them. If a future
// reader is tempted to "simplify" this into `DT->dominates`, that measurement is
// the answer.
//
// ⚠ IT REMOVES A WITNESS, NOT A DECLINE. `V` being excluded does not assert that
// the module is unambiguous — it asserts that `V` is not evidence. Any OTHER
// pinned value that could have occupied a slot is still found, on either edge,
// and still declines: the owner's own file declines today on this witness and
// only on it (measured on the ORACLE, `trackF/probes/cust/owner_file_solecoll.ll`
// — NOT the earlier `probes/c/owner.S1.ll`, which `IMPL_F.md` §7 records as a
// 0-byte and therefore VACUOUS probe), which is why removing it compiles the
// file and why removing it changes nothing anywhere else.
//
// ⚠ WHAT MAKES THE TWO BULLETS A THEOREM IS AN **INVARIANT OF THE SET**, AND
// SINCE 2026-09-15 THAT INVARIANT IS THE BULLETS THEMSELVES, ESTABLISHED BY
// DIRECT TEST. (bd `test_C_libtooling-hrts` + bd `test_C_libtooling-l3i1` — the
// precision fix — and bd `test_C_libtooling-dpau` — the opcode filter — landed
// together, because they are one line. Two earlier framings are RETIRED and are
// recorded here only so a reader who meets them in an old record knows they are
// gone: (i) *"the argument is a theorem only for an ACYCLIC user chain"*, which
// described a DRAFT and not the shipped line, retired by the X5 re-derivation
// 2026-09-14c; and (ii) the `MergeBB`-dominance invariant X5 wrote in its place,
// retired here — it was SUFFICIENT and not NECESSARY, and the gap was the
// over-decline the two beads own.)
//
// THE INVARIANT: **every member of `PhiDesc` is UNAVAILABLE AT BOTH OF F2'S
// SLOTS**, and the walk enforces it by asking exactly that of every user it
// meets (`availableAtAnF2Slot`, in this file, above the helper — it carries the
// spelling of each slot and the reason the arm clause is written though
// unreachable). Nothing is inferred from a position, an opcode or a CFG shape.
// The two bullets above ARE the invariant, so the theorem needs no further step:
// a value unavailable at both slots cannot be spelled at either, in any module,
// and is therefore not a register the author could have rotated.
//
// ⚠ WHAT THE WALK COMPUTES IS NOT "THE USERS OF `M`" — IT IS **THE VALUES WHOSE
// OPERAND CHAIN REACHES `M` WITHOUT PASSING THROUGH A SLOT-AVAILABLE VALUE**,
// and the second half is as load-bearing as the first. The walk TRUNCATES at a
// slot-available value: it neither inserts it nor enqueues its users. That is
// REQUIRED, not merely conservative — if `I` is available at a slot then a user
// `f(I)` is SPELLABLE at that slot, because `I` is a register available there,
// so `f(I)` is a genuine rival and excluding it would be an OVER-ACCEPT. The
// back-edge loop-header φ is exactly that case and is why the truncation exists.
//
// ⚠ AND THE OTHER HALF — MEMBERSHIP — IS WHAT KEEPS THIS OFF THE REFUSED
// DOMINANCE CONJUNCT. Availability ALONE would exclude every value defined after
// the join, which is the refused conjunct verbatim and flips the ≥11 shipped
// merge-block colliders (`range_forward_*`, `sideways_*`, `merge_edge_sideways`,
// `offwire_sideways_min`, `step_cap_over` — measured 2026-09-14, 25/25 of the
// shipped pin fixtures plus all 4 `Truncated` ones: `collider-uses-phi = no`).
// Those colliders never enter this walk at all, because their operands do not
// reach `M`; that is why they are untouched, measured at ZERO movers across the
// 2026-09-15 landing. **The conjunction is the predicate. Neither half alone is.**
//
// ⚠ TWO PREMISES THE PREVIOUS SPELLING NEEDED AND THIS ONE DOES NOT — this is
// the whole reason the change is worth a Rule-13 round rather than a comment
// edit. (1) It no longer derives unavailability from `recoverRegion`'s
// structural gates (`soleMergePhi`'s exactly-two-incomings, the arms'
// `getSinglePredecessor() == Pred`), so X5's trigger *"the day `recoverRegion`
// admits a region whose `MergeBB` has a predecessor that is neither `Pred` nor
// an arm, the sufficiency step must be re-derived from scratch"* is **RETIRED**:
// widen `recoverRegion` however you like and this walk still asks the right
// question, because it asks it of the slots directly. (2) It no longer rests on
// *"`PHINode` is the only class LLVM 19 checks per incoming edge"* — every user
// is tested, so a future opcode with per-edge value operands is asked the same
// question as everything else instead of short-circuiting past an `isa<PHINode>`.
// The residual premise that DOES remain is the one in the two bullets: that the
// arm theta's arg-0 and the merge φ's pred-edge incoming are the only two slots
// the register in question can occupy. That is a fact about F2's question, and
// it is stated at the top of this block.
//
// ⚠ RETIREMENT TRIGGERS (L8), as file:line conditions — THREE of them:
//  (1) `f2Model`'s `SelectInst` arm BELOW — the `unionWith` of the two value
//      operands, which deliberately never reads the select's CONDITION — is what
//      makes a φ-descendant reachable by this walk at all (it is how the owner's
//      `%8 = select i1 %phi, %7, %2` is folded to `[-1,2]` and then compared).
//      **The day that union stops being a union — the day it reads the
//      condition, or splits per edge — re-derive the availability argument from
//      scratch**, because the shape of what reaches the test changes.
//  (2) F2's own `railWireClosure`-vs-`CondRails` trigger above, unchanged.
//  (3) THE SLOT TEST IN THE HELPER. ⚠ **ITS THREE PREDECESSOR TRIGGERS HAVE ALL
//      FIRED AND ALL THREE WERE TAKEN, 2026-09-15** — read this item as history
//      plus ONE live obligation, not as pending work:
//      (3a) THE CYCLIC HALF (bd `test_C_libtooling-wx8g`) — fired 2026-09-14
//           when `wx8g` landed; the re-derivation it demanded was done by X5
//           (session 2026-09-14c, `trackX/X5_REDERIVATION.md`). Its two
//           headline findings survive the 2026-09-15 rewrite and are worth
//           keeping: the two named tripwires
//           (`…_reject_stateprep_backedge_{phi,nonphi}desc_collider.ll`) were
//           NEVER behind `wx8g`'s fence in the first place — both spell their
//           condition as a COMPARE while the retired carve-out was
//           `if (RailCond && Region.InLoop)`, guarded on a BARE RAIL — so "the
//           pair held" was never evidence about the spelling the trigger named;
//           and the bare-rail spelling was then measured directly as the
//           three-way isolation `trackX/probes/w3{,b,c}.ll` (back-edge φ
//           collider → DECLINE at F2; the same with only a NON-φ `M`-descendant
//           → F2 silent; one operand changed so the collider is not an
//           `M`-descendant → DECLINE at F2), with `w1{,b,c}` reproducing all
//           three under a compare condition and `w1d`/`w2d` calibrating that the
//           minimal in-loop prep ACCEPTS in both spellings. ⚠ THE CYCLIC /
//           ACYCLIC AXIS IS RETIRED; it is kept in these labels only so the bd
//           ids stay findable. Cyclicity is not a term in the argument —
//           AVAILABILITY is, and the back-edge φ is simply the sub-case where
//           the candidate IS available at a slot.
//           ⚠ X5 ALSO ADDED A TRIGGER OF ITS OWN HERE — *"the day `recoverRegion`
//           admits a region whose `MergeBB` has a predecessor that is neither
//           `Pred` nor an arm … the sufficiency step must be re-derived from
//           scratch"* — and **that trigger is RETIRED rather than pending**: the
//           slot test does not derive unavailability from `recoverRegion`'s
//           gates at all (see the INVARIANT block above). The companion
//           REACHABILITY premise moved with it: see `availableAtAnF2Slot`'s
//           header for what an unreachable region now answers and why the change
//           is in the decline direction.
//      (3b) THE ACYCLIC HALF (bd `test_C_libtooling-hrts` / bd
//           `test_C_libtooling-l3i1`) — **FIRED AND TAKEN, 2026-09-15.** The old
//           line `!DT.dominates(MergeBB, I->getParent())` was a SUFFICIENT proxy
//           for unavailability, so it also dropped φs that were unavailable at
//           both slots and merely sat off `MergeBB`'s dominance subtree — which
//           needs no cycle, only a classical branch that BYPASSES the region and
//           re-joins after it. Those were LICENSED exclusions and dropping them
//           was an OVER-DECLINE (owner ruling 2026-09-11: an over-decline is a
//           defect to remove). Option (b) — test the MEMBER against the SLOTS —
//           is what `availableAtAnF2Slot` now does. MEASURED at the landing, on
//           the ORACLE (`cq-opt` sha256 `0e280fc6…`) against the subject
//           (`8cda04ca…`): exactly THREE corpus modules move, all in the ACCEPT
//           direction (F2 stops firing) — `r20_acyclic_nondominated_phi.ll`
//           (the bead's own named subject, no loop anywhere), and X5's
//           `c2_inloop_acyclic_bypass_nondominated_phi{,_live}.ll`. The whole
//           back-edge family is unmoved, and so are the ≥11 merge-block
//           colliders. ⚠ AND THE HONEST HALF: **no top-level ACCEPT was
//           recovered.** Every such module is still declined by
//           `declineClassicalMuxes` underneath — a φ off `MergeBB`'s subtree
//           carrying an `M`-descendant is a tainted φ under a classical
//           condition, and is not one-register liftable. Track F′ re-attempted
//           the ACCEPT construction X5 failed at and failed again (round 1,
//           `trackF/IMPL_F2.md` §5), with a structural reason rather than an
//           accidental one — but **that is an argument, not a theorem** (L5), and
//           the mask is `declineClassicalMuxes`, which is itself under widening
//           pressure. **LIVE TRIGGER, and it is the only one left in this item:
//           the day `declineClassicalMuxes` or the one-register lift widens, or
//           bd `test_C_libtooling-xdu2`'s rail bank lands, re-run
//           `r20`/`c2`/`c2_live` — if any of them ACCEPTS, this predicate has
//           become load-bearing for a real program and is owed a fresh Rule-13
//           round in that light.** Tripwire fixtures, as a PAIR:
//           `control_inplace_ry_reject_stateprep_acyclic_nondominated_phi.ll`
//           (flipped to the taint-escape string by this landing, exactly as its
//           own L8 header instructed) and its one-operand isolating control
//           `…_acyclic_nondominated_phi_control.ll` (unmoved at F2 on both
//           binaries), which is what keeps the first from being a fixture that
//           went green because its subject vanished.
//      (3c) THE OPCODE FILTER (bd `test_C_libtooling-dpau`) — **FIRED AND TAKEN
//           IN THE SAME CHANGE, and it had to be**: the old `isa<PHINode> &&`
//           short-circuit was a no-op on valid IR only because the dominance
//           half was a `MergeBB` test that SSA already guaranteed for non-φs.
//           The slot test is asked of EVERY user; the no-op argument is now SSA
//           TRANSITIVITY (a non-φ user `J` of a member `V` has `V` dominating
//           `J`, so `J` available at a slot would make `V` available at it,
//           contradicting `V`'s membership) and depends on no opcode
//           enumeration. Its original trigger — *"the day
//           `DominatorTree::dominates(const Value *, const Use &)` names any
//           class besides `PHINode` when choosing `UseBB`"* — is **RETIRED**:
//           there is no longer a class name in the predicate to be wrong about.
//
// The set is COMPUTED LOCALLY, once per call, from `Region.Merge` — deliberately
// NOT recorded in `TaintSet` the way R-1's clones are. R-1 needed a record
// because only `MergePhiPeel` knows what it manufactured (the L1 pattern: record
// where the answer is known, ask where it is needed). Here there is nothing to
// clear between rounds and no `WeakTrackingVH` hazard.
//
// ⚠ L1, AND **"IT IS RECOMPUTED" IS NOT THE ARGUMENT — IT IS THE HAZARD.** An
// earlier draft of this header closed the L1 question with *"the answer is a
// pure function of the module in front of this call, so recomputing it in BOTH
// detection rounds is automatic and there is no premise for `repropagate-
// ControlMerges` to falsify"*. That is BACKWARDS, and it is the sentence a
// future reader must not inherit. `repropagateControlMerges` runs a SECOND full
// round of detection, and round 1's EMITTERS MUTATE the very SSA user graph
// this walk reads. A predicate recomputed over a graph a previous round
// rewrote IS the L1 PREDICATE species — it is bd `9pum` / `r9e5` F-B1R2-1 and
// bd `b6ap` F-B6-1 verbatim. Recomputation guarantees only that the answer is
// current; it says nothing about whether the graph it is current over is the
// one the availability argument is about.
//
// THE ROUND-2 CALL IS REACHABLE AND THIS CONJUNCT DOES FIRE THERE — measured,
// not assumed, because an unreachable round-2 F2 would make the whole question
// vacuous: on a 6.5 classical-call skeleton whose state prep is classified ONLY
// after the re-seed, `trackF/fix_r2_probes/r5_round2_phidesc.ll` ACCEPTS while
// its one-operand isolating control `r5c_round2_nonphidesc.ll` DECLINES, with
// `CQ_CTRL_DBG` naming the round-1-emitted out-rail `%out1` in the decline
// anchor. Both are committed as fixtures (`…_stateprep_round2_phidesc_collider_
// accept.ll` / `…_reject_stateprep_round2_nonphidesc_collider.ll`).
//
// WHAT ACTUALLY MAKES THE ROUND-2 SET SOUND IS A PROPERTY OF THE **EMITTERS**,
// AND IT LIVES IN OTHER FILES. Every merge-φ RAUW in the tree targets either
//   (a) a fresh `cqrt_alloc` call whose ONLY operand is a CONSTANT — no SSA
//       lineage at all, so the closure SHRINKS: `SelectMergeEmit.cpp:386`,
//       `SwitchValueEmit.cpp:376`, `SwitchDataMuxEmit.cpp:230`; or
//   (b) one of the φ's OWN INCOMINGS, or a descendant of one:
//       `SwapRouteEmit.cpp:1295` / `:1534` (M-α) and `RegionFlatten.cpp:176`
//       take the straight-through incoming `Q`; `SwapRouteEmit.cpp:1105` (M-β)
//       takes `Gates.back().first`, which is the arm theta `T` itself, or the
//       if/else re-chained `T2` (`:948`, `G.first->setArgOperand(0, Prev)`),
//       or the negated-rail CLONE `TNeg` whose only two operand roots are `T`
//       (`:917`) and `T`'s own angle (`:930`).
// In case (b) the target was ALREADY reachable from anything that reached the
// φ, because `inPlaceRotationArmTheta` admits an arm theta ONLY when the merge
// φ is its SOLE USER — its own `if (!T->hasOneUse() ||
// T->user_back() != MergePhi) return nullptr;` (the `SwapRouteEmit.cpp`
// re-check once cited here no longer exists, 2026-10-05). So for every `X`,
//       X →* T  ⟹  X →* M  ⟹  X →* users(M)
// held BEFORE the RAUW, and the RAUW re-parents exactly those users onto `T`.
// No pre-existing value gains membership in any region's `PhiDesc`, in round 2
// or ever. (Round-2 Rule-13 review, F-F1-5 / F-F2-1.) The TRIPWIRES for this —
// the only ones anywhere — are `control_inplace_ry_reject_stateprep_mbeta_base_
// offcone.ll` and `…_mbeta_ifelse_rechain.ll`, read against the on-cone ACCEPT
// `control_inplace_ry_stateprep_mbeta_base_oncone_accept.ll`.
//
// ⚠ RETIREMENT TRIGGER (L8) — **THE DAY ANY EMITTER RAUWs A MERGE φ TO A VALUE
// THAT IS NOT A DESCENDANT OF ONE OF THAT φ'S OWN INCOMINGS**, this walk is
// reading a graph the pass manufactured and the argument above must be
// re-derived from scratch. TWO SITES ALREADY HAVE EXACTLY THAT SHAPE and are
// safe only by TIMING, not by construction: `SwapRouteEmit.cpp:536`
// (`emitValueRegion`) and `MergePhiPeel.cpp:559` both RAUW a φ to a `select`,
// which GAINS THE CONDITION as an operand the φ never had — a third growth
// vector, and the only one with the right polarity. They do not reach a round-2
// F2 today because `emitValueRegion`'s select is RAUW'd to the out-rail and
// erased inside `emitSelectRegion` IN THE SAME ROUND (falling into row (a)),
// and because a peel whose manufactured edge would BE an `M`-descendancy is a
// peel whose region condition is `M`-reachable, hence tainted in round 1, hence
// claimed and lowered in round 1 (measured: `trackF/fix_r2_probes/r10`, `r10c`,
// `r11`, `r11c` — on-cone/off-cone peel pairs, each probe giving the SAME
// verdict on the ORACLE, the un-narrowed and the narrowed binary; none accepts).
// Break EITHER of those two timings and this trigger has fired.
//
// Rule 14, asked and answered: `RotationLowering.cpp`'s `collectDescendantRecords`
// is NOT this walk and was not reused — it follows only `CallInst` RECORD
// PRODUCERS and copy-gate SRC→DST edges, i.e. a rail relation, while this is the
// plain SSA user relation over every opcode. Sharing one helper would have to
// widen that one, which is a Rule-13 rail fence.
// ---- THE SLOT TEST ITSELF (bd `test_C_libtooling-hrts` / `l3i1` / `dpau`,
// ---- 2026-09-15) — "IS `I` AVAILABLE AT EITHER OF F2's TWO SLOTS?" ----
//
// This is the NECESSARY-AND-SUFFICIENT form of the question the availability
// ground asks, replacing the SUFFICIENT-ONLY proxy `DT.dominates(MergeBB,
// I->getParent())`. It is asked of EVERY user, not only of φs. The two slots are
// the only two places the register F2 is asking about can occupy:
//
//   * THE PRED SLOT — the merge φ's incoming on the `Pred`→`MergeBB` edge. A φ
//     incoming must dominate its incoming EDGE, i.e. the END of `Pred`, and
//     `PredSlot` IS `Pred`'s terminator (the region's own conditional branch),
//     so `DT.dominates(I, PredSlot)` is exactly that question. ⚠ Spell it
//     against the TERMINATOR, never `DT.dominates(I->getParent(), Pred)`: a
//     value defined in `Pred` itself is available on that edge and block
//     dominance would answer `false` for it.
//
//   * THE ARM SLOT — the arm theta's arg-0, which lives inside `Arm` (and
//     `ArmFalse` for an if/else). `DT.dominates(I->getParent(), ArmBB)` is a
//     CONSERVATIVE over-approximation of "available at a position inside
//     `ArmBB`": it answers `true` for a value defined in `ArmBB` itself,
//     including one defined AFTER the theta, which this walk then keeps OUT of
//     the exclusion set — i.e. it errs toward leaving a rival in, which is the
//     DECLINE direction. Deliberate: the precise form would need the arm theta
//     pointer threaded through a helper that is called before `classifyArms`
//     has committed one, and the imprecision can only cost accepts.
//
// ⚠ THE ARM CLAUSE IS UNREACHABLE TODAY — FOR THREE INDEPENDENT REASONS — AND
// IS SPELLED ANYWAY, ON PURPOSE. (1) Every block that dominates `ArmBB` other
// than `ArmBB` itself also dominates `PredSlot`, because `recoverRegion` makes
// `Pred` the arm's SINGLE predecessor; so the PRED clause already subsumes all
// of them. (2) A value defined IN `ArmBB` cannot be an `M`-descendant: a φ there
// has exactly ONE incoming, on the `Pred`→arm edge, which `M` does not dominate,
// and a non-φ arm-block user of an `M`-descendant is use-before-def — both
// rejected by `opt -passes=verify` (X5 probes `a1_…`, `a2_…`,
// `c4_arm_block_phi_taking_M_INVALID.ll`, 2026-09-14c). (3) `ArmSlots[1]` is
// ALWAYS NULL here: F1 computes `PredIdx = MergePhi->getBasicBlockIndex(Pred)`
// and declines when it is negative, and an IF/ELSE merge φ has incomings from
// the two ARMS and none from `Pred` — so an if/else STATE PREP is refused by F1
// before F2 ever runs, and `Region.ArmFalse` is non-null only for shapes that do
// not reach this function. (⚠ Read (3) as a FACT ABOUT F1, not as a licence: the
// day F1 admits an if/else prep, the pred-edge slot becomes the FALSE ARM's
// terminator rather than `BI`, and the clause that covers it is this one — a
// value available there but not at `BI` must be defined in `ArmFalse`, which
// `DT.dominates(ArmFalseBB, ArmFalseBB)` catches.)
//
// WRITING THE CLAUSE BUYS AN ARGUMENT, NOT A BEHAVIOUR: with it, the set
// invariant is established BY DIRECT TEST and no longer has to be derived from
// `recoverRegion`'s exactly-two-incomings / single-pred-arm gates — which is
// what retired X5's own trigger *"the day `recoverRegion` admits a region whose
// `MergeBB` has a predecessor that is neither `Pred` nor an arm, the sufficiency
// step must be re-derived from scratch"*. It is measured at ZERO movers over the
// whole corpus, not assumed.
//
// ⚠ UNREACHABLE CODE, AND THE ANSWER MOVED — SAFE DIRECTION, SAID OUT LOUD.
// `DominatorTree::dominates(const Value *, const Instruction *)` answers "any
// unreachable USE is dominated" (`true`) and "an unreachable DEF dominates
// nothing" (`false`). So when the region itself is unreachable every user reads
// as AVAILABLE and the set collapses to `{M}` — where the old `MergeBB` proxy
// kept the non-φ users in it. Fewer exclusions is fewer witnesses removed, i.e.
// strictly MORE declines, and an unreachable region's gates never execute; `-O1`
// deletes such blocks before the pass ever sees them. A user in an unreachable
// block while the region is reachable reads as NOT available and is KEPT in the
// set, exactly as the old proxy had it. No Release-build wild read in either
// direction: LLVM 19 answers both from the tree-node lookup without
// dereferencing a null node (`GenericDomTree.h:430-442`).
bool availableAtAnF2Slot(const Instruction *I, const Instruction *PredSlot,
                         ArrayRef<const BasicBlock *> ArmSlots,
                         const DominatorTree &DT) {
  if (PredSlot && DT.dominates(I, PredSlot))
    return true;
  for (const BasicBlock *ArmBB : ArmSlots)
    if (ArmBB && DT.dominates(I->getParent(), ArmBB))
      return true;
  return false;
}

void collectStatePrepPhiDescendants(const Value *Merge, const Function *F,
                                    const Instruction *PredSlot,
                                    ArrayRef<const BasicBlock *> ArmSlots,
                                    const DominatorTree &DT,
                                    SmallPtrSetImpl<const Value *> &Out) {
  // Only a `br`-diamond state prep reaches F2, so `Region.Merge` is the merge φ
  // here; a `SelectRegion`'s `Merge` is a `SelectInst` and is not this question.
  const auto *MergePhi = dyn_cast_or_null<PHINode>(Merge);
  if (!MergePhi)
    return;
  SmallVector<const Value *, 16> Work;
  // `M` ITSELF IS IN THE SET, for the same reason its users are: the φ is not
  // available on its own pred edge either, so "the author rotated `M`" is not a
  // reading of the source the module could be the image of. It satisfies the
  // set invariant by the SAME test the users get — `availableAtAnF2Slot(M, …)`
  // is false, because `M`'s block is `MergeBB` and `Pred` strictly dominates
  // `MergeBB` — but it is inserted unconditionally rather than tested, so that a
  // region whose `Pred` is unreachable (where the test answers `true` for
  // everything) still anchors the walk. That only ever costs declines.
  Out.insert(MergePhi);
  Work.push_back(MergePhi);
  while (!Work.empty()) {
    const Value *V = Work.pop_back_val();
    for (const User *U : V->users()) {
      const auto *I = dyn_cast<Instruction>(U);
      // Function-local by construction, the same filter the users walk below
      // applies: a value in another function is not a slot of this region.
      if (!I || I->getFunction() != F)
        continue;
      // ---- THE SLOT TEST — WHY IT IS HERE, WHAT IT REPLACED, AND WHY THE
      // ---- TRUNCATION IS LOAD-BEARING RATHER THAN MERELY SAFE ----
      //
      // (bd `test_C_libtooling-hrts` + bd `test_C_libtooling-l3i1` — the
      // precision fix — and bd `test_C_libtooling-dpau` — the opcode filter —
      // taken together 2026-09-15, because they are ONE line. The predicate
      // spelled here before that day was
      //     `if (isa<PHINode>(I) && !DT.dominates(MergeBB, I->getParent()))`
      // whose history is: round-1 Rule-13 finding F-F1-1 wrote the dominance
      // half for the BACK-EDGE φ; round-2 finding F-F2-2 measured that the same
      // line also drops ACYCLIC non-dominated φs, which were LICENSED
      // exclusions, and filed the two over-decline beads; X5 (2026-09-14c)
      // retired the cyclic/acyclic axis and named AVAILABILITY as the right one,
      // and filed the opcode question separately.)
      //
      // ⚠ THE BACK-EDGE φ IS STILL THE SHAPE THIS LINE EXISTS FOR, and it still
      // declines. A φ is the one opcode in LLVM 19 whose operand need only
      // dominate its incoming EDGE, so a LOOP-HEADER φ can take an
      // `M`-descendant on its BACK EDGE while sitting in a block that DOMINATES
      // both of F2's slots — i.e. while being AVAILABLE at both, which is
      // exactly what a member of this set must not be. Such a φ is a genuine
      // rival and the walk must not swallow it. Tripwires:
      // `…_reject_stateprep_backedge_{phi,nonphi}desc_collider.ll`, and the
      // bare-rail triple `trackX/probes/w3{,b,c}.ll` that measured the same
      // three verdicts inside a loop after bd `test_C_libtooling-wx8g` landed.
      //
      // WHAT CHANGED: THE QUESTION IS NOW ASKED DIRECTLY. `!DT.dominates(
      // MergeBB, IBB)` was a PROXY — sufficient for "unavailable at both slots",
      // not necessary — so it also dropped every φ whose block merely is not
      // dominated by `MergeBB`, which needs NO CYCLE: a classical branch that
      // BYPASSES the region and re-joins after it does it in a fully acyclic
      // CFG. Those φs are unavailable at both slots, so they were licensed
      // exclusions, and dropping them was an OVER-DECLINE (owner ruling
      // 2026-09-11: an over-decline is a defect to remove). `availableAtAnF2Slot`
      // asks the necessary-and-sufficient question instead; see its header for
      // the two slots and for why the ARM clause is written though unreachable.
      //
      // ⚠ AND IT IS ASKED OF **EVERY** USER, NOT ONLY OF φs — bd `dpau`. The old
      // `isa<PHINode> &&` conjunct short-circuited, so a hypothetical future
      // opcode with PER-EDGE value operands would have entered the set
      // UNCHECKED; the premise holding that shut was *"`PHINode` is the only
      // class `DominatorTree::dominates(const Value *, const Use &)` treats that
      // way"*, which is a fact about LLVM 19 and not about this pass. There is
      // no such premise left: every user is tested. On valid IR today the two
      // spellings agree, and the proof is SSA TRANSITIVITY rather than an opcode
      // list — if `I` is a non-φ user of member `V` then `V` dominates `I`, so
      // `I` available at a slot would make `V` available at it too, contradicting
      // `V`'s membership. MEASURED at zero corpus movers, not asserted.
      //
      // ⚠ THE TRUNCATION (`continue` skips the INSERT **and** the enqueue) IS
      // REQUIRED FOR SOUNDNESS — IT IS NOT MERELY "THE SAFE DIRECTION", AND THE
      // EARLIER TEXT HERE UNDERSOLD IT. If `I` is slot-available, a user `J` of
      // `I` is SPELLABLE AT THE SLOT — the author could have written `f(I)`
      // there, since `I` is a register available at that position — so `J` is a
      // genuine rival and excluding it would be an OVER-ACCEPT. Enqueuing the
      // users of a skipped value is therefore forbidden, not just unhelpful.
      // (The round-1 draft justified the truncation with *"whatever it carries
      // forward is likewise slot-available"*, which is NOT a theorem and was
      // corrected in round 2 to a direction argument; the direction argument is
      // true and is still not the reason. This is.) What the truncation makes
      // the walk compute is exactly: **the values whose operand chain reaches
      // `M` WITHOUT PASSING THROUGH A SLOT-AVAILABLE VALUE** — and that set,
      // not "the users of `M`", is what the availability ground licenses.
      //
      // ⚠ THIS IS A **NARROWING OF THE EXCLUSION SET WHERE IT FIRES**, AND IT IS
      // STILL NOT THE REFUSED DOMINANCE CONJUNCT — do not "simplify" the two
      // together. The refused conjunct tests a COLLIDER's position against the
      // ARM and turns declines into ACCEPTS (it flips the ≥11 shipped
      // merge-block colliders: `range_forward_*`, `sideways_*`,
      // `merge_edge_sideways`, `offwire_sideways_min`, `step_cap_over`). This
      // tests a candidate MEMBER against the SLOTS and decides only whether that
      // member is a rival. ⚠ Note the ONE genuinely new thing to hold in mind
      // since 2026-09-15: unlike its predecessor, this line moves in BOTH
      // directions — it still removes an exclusion for a slot-available φ (more
      // declines) and it now KEEPS one for a slot-unavailable φ the proxy
      // dropped (more accepts). The second direction is the fix; it is the
      // reason this file needed its own Rule-13 rounds, and it is why the
      // membership half — the operand chain must reach `M` — is the load-bearing
      // half and must never be dropped. Membership WITHOUT the chain is the
      // refused conjunct exactly.
      if (availableAtAnF2Slot(I, PredSlot, ArmSlots, DT))
        continue;
      if (!Out.insert(I).second)
        continue;
      Work.push_back(I);
    }
  }
}

// The fp EQUALITY polarity table, ONE spelling for F2's two fp questions (the
// constant fp ANCHOR and the runtime seed's relational fp half, bd z0re): on
// which successor of a conditional `br` on `fcmp <P>` do the two operands
// compare EQUAL? `oeq`/`ueq` on the TRUE edge, `one`/`une` on the FALSE edge,
// nowhere for every other predicate. (`E == 0` is the TRUE successor — LLVM
// invariant.) `ueq`-true and `one`-false also admit NaN, an OVER-approximation
// of "equal" — the safe direction for a fence that only ever declines.
// Extracted verbatim from the anchor's `switch` (behaviour-preserving), so the
// two callers cannot disagree about which edge an equality holds on.
bool fcmpEqualityHoldsOnEdge(FCmpInst::Predicate P, bool TrueEdge) {
  switch (P) {
  case FCmpInst::FCMP_OEQ:
  case FCmpInst::FCMP_UEQ:
    return TrueEdge;
  case FCmpInst::FCMP_ONE:
  case FCmpInst::FCMP_UNE:
    return !TrueEdge;
  default:
    return false;
  }
}

// ---- THE RUNTIME SEED (bd `test_C_libtooling-z0re`, owner ruling 2026-09-28,
//      option (a); PRD §14.11 Q2) — F2 RE-ASKED FOR A NON-`Constant` SEED ----
//
// F2's question is *"could the arm's seed be `-O1`'s rewrite of a live tainted
// register the source rotated in place?"*. For a LITERAL seed the rewrite in
// question is a CONSTANT FOLD, and the machinery below the relational branch
// (LVI ranges + the forward `ConstantRange`/`ConstantFold`/`KnownBits`
// evaluation + the `Truncated` conservative half) is exactly LLVM's own
// constant lattice asked on both edges. For a RUNTIME seed `s` (an untainted
// `Instruction`/`Argument`, `isRuntimeStatePrepSeed`) that half has NO SUBJECT,
// and the argument is about the pipeline's IMAGE, not about a survey:
//   * every constant-producing pass `clang -O1` runs (IPSCCP/SCCP's
//     `ValueLattice`, InstCombine's `KnownBits`, `ConstantFolding`) substitutes
//     a CONSTANT, so a non-`Constant` seed is never the image of such a fold —
//     `f2Exact(V, S) == Seed` cannot hold, and `Truncated`'s premise ("a function
//     of a pinned register we cannot evaluate might have folded to the seed")
//     is a premise about a CONSTANT the fold could have produced;
//   * the one way a fold CAN leave a runtime value in the ARM slot is an
//     arm-local expression over a pinned register that simplifies to `s`
//     (`smax(W, s)` with `W` pinned to `INT_MIN`, `W + s - k` with `W` pinned to
//     `k`) — an out-of-place rail the fold DELETES, i.e. PRD §14.11 Q3's
//     deleted-register residual, where both readings agree on every rail
//     anything reads; the PRED slot cannot receive one at all (a φ incoming is
//     evaluated before the branch, so only a condition OPERAND is renamed along
//     the edge, and IPSCCP renames it to a constant);
//   * what is left is the RELATIONAL rewrite — replacing a tainted `W` by `s`
//     where some edge proves `W == s`. On the REGION'S OWN edges it needs an
//     equality-propagating pass (GVN / NewGVN / JumpThreading /
//     CorrelatedValuePropagation), and NONE is in the `-O1` pipeline at LLVM 19
//     (MEASURED with `-print-pipeline-passes`: 1× ipsccp, 1× sccp, 2× early-cse,
//     8× instcombine, 9× simplifycfg, no gvn/newgvn/jump-threading/correlated-
//     propagation — TRACK_Z0RE.md §3). Measured from C: `if (q == s) { r = q;
//     cq_theta(&r, θ); }` keeps `%q` as arg-0, `r = q; if (q != s) { r = s; cq_theta(&r,
//     θ); }` keeps `%q` as the Pred incoming (probes e02/e09/e10/e15/e16).
//   ⚠ CORRECTED (Rule-13 r1A F-r1A-1, L7): this bullet used to end "and
//     InstCombine's relational simplification (`select (X == Y), X, Y → Y`)
//     acts on a SELECT, which a diamond whose arm holds a `cq_theta` CALL never
//     becomes". FALSE as a class statement. `-O1` DOES perform ONE relational
//     rewrite into a call operand: an if/else of two thetas differing in ONE
//     operand (`if (q == s) { r = q; cq_theta(&r, θ); } else { r = s; cq_theta(&r, θ); }`) is
//     SUNK by SimplifyCFG into one call reading a φ, `FoldTwoEntryPHINode` turns
//     that φ into `select (q == s), q, s`, and InstSimplify folds it to `s` —
//     the pinning branch is ERASED. Flat, that is an UNCONDITIONAL prep with no
//     region (bd `zt0b`). NESTED in an outer tainted diamond it IS a runtime-seed
//     prep that reaches F1 — the outer arm is `@cq_theta_*(s, θ)` with Pred
//     incoming `s` — and F2 cannot see it, because the pin lived on an edge that
//     is NOT the region's (review_r1A_z0re probes a1/a3/a5). ⚠ The post-fold
//     module is INDISTINGUISHABLE from a legitimate program: bd `fmt3` measured
//     that the rotated register need not even be the erased compare's operand
//     (probe n13: inner `q == 20`, rotated `t = q / 4`) and that the folded IR is
//     byte-identical to `if (q2 > 3) { r = 5; cq_theta(&r, .9); }` (n12) — so NO question
//     this pass can ask of the IR in front of it separates the hazard from the
//     program the module denotes. The disposition is therefore at the SOURCE
//     level, not here: bd `fmt3` OPTION B (owner ruling 2026-09-28, LANDED after
//     z0re, 2026-09-29) puts `__attribute__((nomerge))` on the `cq_theta_*`
//     declarations in `CQ.h`, so that `-O1` can no longer merge two DIRECT calls
//     and the inner branch survives (measured: a1/a3/a5 now decline `nested control
//     flow`). The IR-level fixtures
//     `control_inplace_ry_stateprep_runtime_seed_postfold{,_offwire,_noread}.ll`
//     pin the post-fold modules as ACCEPTS on exactly that ground — the module is
//     the legitimate program. ⚠ THE WINDOW IS CLOSED ONLY FOR DIRECT CALLS: clang
//     puts `nomerge` on the call SITE, so the same programs written through a
//     FUNCTION POINTER still fold and still accept (fmt3 r1A `fpzt_a1`, measured on
//     the composed binary — bd `4e4p`, P1, PRE-EXISTING).
// So the question is ASKED ANYWAY for the region's own edges, as the relation
// itself and with LLVM's own implication engine rather than a hand-picked shape
// list (L5): on each edge, is some live tainted value of the seed's type
// PROVABLY EQUAL to `s` — `isImpliedCondition(BranchCond, ICMP_EQ, V, s, DL,
// /*LHSIsTrue=*/edge)` for an integer seed, the SAME `fcmpEqualityHoldsOnEdge`
// table the fp anchor uses for an fp seed — with the THREE exclusions applied at
// the same TEST, by the same lambda (`CondWire`, `PeelClones`, the φ-descendant
// set).
// ⚠ AND IT IS UNPINNABLE TODAY — SAID PLAINLY, CORRECTING THE FIRST SPELLING OF
// THIS COMMENT (Rule-13 r1A F-r1A-3, L7), which read "It is MEASURED live rather
// than dead: a mutant that drops the exclusion at this test declines
// `…_runtime_seed_cond_operand.ll`". That mutant measured the EXCLUSION
// (`excludedAtTest`), not this half: it shows the implication loop RUNS and
// finds the compare operand, not that it ever changes a verdict. For every
// condition that reaches a state prep today — a single compare or a bare rail;
// a compound condition declines `control flow` first (r1A `e20.c`) — the only
// values a branch condition can imply equal to `s` are the compare's own
// operands, all in `CondWire` by construction. So with the exclusion in place
// DELETING THE WHOLE RELATIONAL HALF IS AN EQUIVALENT MUTANT ON EVERY REACHABLE
// INPUT, and no fixture can distinguish it from its absence (Rule 12 has no
// subject for an unreachable shape). It is kept as the honest spelling of the
// question — the analysis that must already be in place the day a trigger below
// fires — not as a fence that is doing work today.
// RETIREMENT TRIGGERS: (1) the day an equality-propagating pass enters the
// `-O1` pipeline (or CQ moves off `-O1`), the "no subject" argument for the
// constant walk and the forward half must be re-derived for runtime seeds; (2)
// the day compound conditions reach a state prep (F2's own compound-condition
// trigger, below), `isImpliedCondition` starts deriving equalities about values
// OFF the leaves' wires, and this half becomes PINNABLE and load-bearing; (3)
// F2's `railWireClosure`-vs-`CondRails` trigger applies unchanged; (4) — the
// route (1) misses, and the one that EXISTS at `-O1` today — SimplifyCFG
// MERGING two thetas (the sink described above, and bd `fmt3`'s hoist of two
// now-identical literal thetas) ERASES the branch that pinned the register.
// Neither this relational half nor the constant half looks at an erased branch:
// this function is anchored on the REGION'S branch, and the erased branch leaves
// nothing in the module to anchor on. This route IS closed for DIRECT calls by bd
// `fmt3` option B (`nomerge` on `cq_theta_*`, owner 2026-09-28, landed 2026-09-29) —
// it removes the MERGE at the C level — and it stays OPEN through a FUNCTION POINTER
// (bd `4e4p`: the attribute is on the call site, not the declaration). A route that
// erases the register's identity WITHOUT merging two thetas exists too: the arg-0
// `select (t == s), t, s` → `s` fold (bd `uw5u`, P1, PRE-EXISTING — no header can
// reach it). If `nomerge` is later dropped from `CQ.h`, or another route is found
// that erases a pinning branch WITHOUT merging two thetas, this function needs a question
// asked of the seed's own provenance, not of the region's edges.
// bd test_C_libtooling-dm7f.53 — THE SIBLING-CONDITION EXCLUSION. Delegated
// ruling `ruling-dm7f53-p4-sibling-cond-prep-2026-10-15` (applying
// `owner-ruling-f2-condwire-2026-09-11` / `owner-ruling-drbq14-tree-leaves-
// 2026-10-14`), AMENDED twice on 2026-10-15: `…-amend-forced` (any predicate:
// the argument is FORCEDNESS, not equality) and `…-amend-straight-through`
// (either edge: the argument is edge-independent).
//
// THE QUESTION, split in two and each half asked ONCE:
//   * STRUCTURE (this predicate): `V` is an `icmp` (any predicate) of a
//     `CondWire` member against a literal, used ONLY as the condition of
//     conditional branches — a SIBLING region's condition read off this
//     region's own condition wire. (`CondWire` null = the L1 re-ask, which has
//     no region left; it asks the remaining structure only.)
//   * FORCEDNESS: NOT asked here. It IS F2's own pin — `f2Exact(V, S) == Seed`
//     at the constant TEST, an LVI edge fact (`getConstantRangeOnEdge` on the
//     register, carried forward by `f2Model`) — so "forced" and "pinned" have
//     ONE spelling (R12), and an enclosing condition LVI can see forces `V`
//     exactly when it pins it (R11 round-2 finding: `isImpliedCondition` on the
//     region's own branch was strictly narrower; it is no longer used here).
//     The exclusion is applied only where that pin was found, i.e. only to a
//     collider whose forced value EQUALS the CONSTANT seed; the relational
//     (runtime, non-fresh) seed half and the fp half never consult it.
//
// WHY IT IS THE IDENTITY, on either edge. Arm edge: the -O1 rival `if (C) {
// t = V; Ry(t,θ); }` aliases `t` to a flag that holds the seed on every branch
// the arm runs in (`if (x==0) Ry(t,.3); if (x==1) Ry(t,.7)`). Straight-through
// edge: the rival `else t = V` is a controlled permutation whose control
// predicate (¬C ∧ V ≠ seed) is unsatisfiable on every basis state, hence the
// identity operator (`if (x<3) Ry(t,.3); if (x<2) Ry(t,.7)`).
//
// THE SET QUESTION (L3): F2 returns on the FIRST collider no exclusion covers,
// so one unforced, off-wire, data-used or fp sibling keeps the region loud.
// WHAT STAYS LOUD BY CONSTRUCTION: a register reached through a shift, a cast, a
// sideways `-O1` rewrite (`and x, -4`) or an intrinsic is not a `CondWire`
// member; an `fcmp` is not an `icmp`; a data use is not a branch use; a
// non-constant seed never asks. Asked ONLY at F2's TEST, never at the LVI
// anchor (the 2026-09-11 placement rule).
//
// L1: every collider this exclusion covers is TAGGED (`kF2SiblingMD`) at the
// test, and `declineRound2QuantumPrepSeeds` re-asks the structural half after
// the round-2 fixpoint in BOTH entry points (see there).
constexpr const char *kF2SiblingMD = "cq.f2.sibling";
// bd dm7f.54 (A1): the classical-pin record of `angleSelectLiteralSeedPinned`.
constexpr const char *kAngleSelSeedPinMD = "cq.anglesel.seedpin";

bool siblingConditionCompareOnWire(const Value *V,
                                   const SmallPtrSetImpl<Value *> *CondWire) {
  const auto *C = dyn_cast<ICmpInst>(V);
  if (!C)
    return false;
  bool OnWire = false;
  for (unsigned K = 0; K < 2; ++K)
    if (isa<ConstantInt>(C->getOperand(1 - K)) &&
        !isa<Constant>(C->getOperand(K)) &&
        (!CondWire || CondWire->count(C->getOperand(K))))
      OnWire = true;
  if (!OnWire || C->use_empty())
    return false;
  for (const User *U : C->users()) {
    const auto *B = dyn_cast<BranchInst>(U);
    if (!B || !B->isConditional() || B->getCondition() != C)
      return false;
  }
  return true;
}

// THE THREE EXCLUSIONS OF F2's TEST, ONE SPELLING (bd z0re spelled them once
// inside F2; bd dm7f.54 round-2 review F2 lifted them here so the angle select's
// literal-seed pin (`angleSelectLiteralSeedPinned`) asks the SAME question
// instead of a stricter second one — the if/else and ternary forms of one
// program must answer alike). `CondWire`: the owner-ruled α trade (a value on
// the condition's own wire may be the pinned register; owner rulings
// 2026-09-11 / drbq14-tree-leaves-2026-10-14). `isPeelClone`: a value the peel
// manufactured is in no rival program. `PhiDesc`: the region-merge availability
// exclusion (empty for a consumer with no merge). The arguments are at F2's
// TEST below; this is only where they are spelled.
bool f2ExcludedAtTest(const Value *V, const SmallPtrSetImpl<Value *> &CondWire,
                      const TaintSet &Taint,
                      const SmallPtrSetImpl<const Value *> *PhiDesc) {
  return CondWire.count(const_cast<Value *>(V)) ||
         Taint.isPeelClone(const_cast<Value *>(V)) ||
         (PhiDesc && PhiDesc->count(V));
}

// Every `fcmp` whose truth value is FIXED when `Cond` evaluates to `Holds`,
// with that value: through an `and` (or `select a, b, false`) when true,
// through an `or` (or `select a, true, b`) when false, recursively. A bare
// `fcmp` yields `{(fcmp, Holds)}`. Lifted out of F2 (bd dm7f.52's
// `forcedFcmpLeaves`) by bd dm7f.54 round-2 review H5 so the angle select's
// literal-seed fp pin reads compound conditions exactly as F2 does.
SmallVector<std::pair<FCmpInst *, bool>, 4> forcedFcmpLeavesOf(Value *Cond,
                                                                bool Holds) {
  SmallVector<std::pair<FCmpInst *, bool>, 4> Out;
  SmallVector<std::pair<Value *, bool>, 8> WL;
  WL.push_back({Cond, Holds});
  unsigned Budget = 64;  // a tree is bounded by `condTreeTooLarge`; defence.
  while (!WL.empty() && Budget--) {
    auto [V, Val] = WL.pop_back_val();
    if (auto *FCI = dyn_cast<FCmpInst>(V)) {
      Out.push_back({FCI, Val});
      continue;
    }
    Instruction::BinaryOps Opc;
    Value *L = nullptr;
    Value *R = nullptr;
    if (!decomposeCondNode(V, Opc, L, R, /*AllowLogicalSelect=*/true))
      continue;
    if ((Opc == Instruction::And && Val) || (Opc == Instruction::Or && !Val)) {
      WL.push_back({L, Val});
      WL.push_back({R, Val});
    }
  }
  return Out;
}

bool f2SeedPinnedByLiveRegister(const ControlRegion &Region, Value *SeedV,
                                TaintSet &Taint, const DominatorTree *DT,
                                const SmallPtrSetImpl<Value *> &CondWire,
                                bool &Truncated, Value **PinnedBy = nullptr) {
  BasicBlock *Pred = Region.Pred;
  if (!Pred) {
    Truncated = true;
    return false;
  }
  auto *BI = dyn_cast<BranchInst>(Pred->getTerminator());
  if (!BI || !BI->isConditional()) {
    // Every state-prep region reaching here is a `br`-diamond whose `Pred`
    // terminator IS the conditional branch (`handleBranchRegion` sets both from
    // the same `BranchInst`). If that ever stops holding, F2 has no edge to ask
    // about — which is a decline, not a pass-through.
    Truncated = true;
    return false;
  }
  if (!DT) {
    // Without a `DominatorTree` the "is this value LIVE on the edge?" filter
    // below cannot be spelled, and asking `LazyValueInfo` about a value that is
    // not is a CRASH, not a wrong answer (measured: `solveBlockValueNonLocal`
    // `cast<Argument>`s any non-Argument live-in of the entry block). Every
    // caller passes one today; if that changes, DECLINE rather than narrow the
    // question silently.
    Truncated = true;
    return false;
  }
  Function *F = Pred->getParent();
  const DataLayout &DL = F->getParent()->getDataLayout();
  AssumptionCache AC(*F);
  LazyValueInfo LVI(&AC, &DL);

  // The φ-DESCENDANT set (2026-09-14; the argument is in this function's header).
  // ONCE, before the edge loop and before `Cand`, because it is a property of the
  // region and not of an edge or of a candidate. It is NOT used to prune `Cand`
  // and NOT used to prune the users walk — see the TEST below.
  //
  // `DT` is dereferenced inside (the back-edge-φ narrowing, F-F1-1) and is
  // non-null here BY THE GUARD ABOVE, which declines rather than narrowing the
  // question silently when there is no dominator tree.
  //
  // THE TWO SLOTS ARE PASSED IN, 2026-09-15 (bd `test_C_libtooling-hrts` /
  // `l3i1`): `BI` — `Pred`'s own conditional terminator, established non-null
  // by the guard above — IS the pred-edge slot, and `Region.Arm` / `ArmFalse`
  // are the arm slot's block(s). ⚠ `ArmFalse` is null for a plain diamond and
  // `availableAtAnF2Slot` skips a null entry; do NOT replace this with a
  // re-derivation of the arms from the CFG, which would be a second spelling of
  // what `recoverRegion` already committed (Rule 14).
  SmallPtrSet<const Value *, 32> PhiDesc;
  const BasicBlock *ArmSlots[] = {Region.Arm, Region.ArmFalse};
  collectStatePrepPhiDescendants(Region.Merge, F, BI, ArmSlots, *DT, PhiDesc);

  // The LVI ANCHORS: every tainted integer value that is LIVE ON THE EDGE, in
  // FUNCTION ORDER rather than in `Taint.Tainted`'s pointer order so the walk
  // (and therefore the step bound) is deterministic.
  //
  // ⚠ THE DOMINANCE FILTER IS A HARD API PRECONDITION, NOT AN OPTIMIZATION.
  // `LazyValueInfoImpl::solveBlockValueNonLocal` asserts `isa<Argument>` for a
  // live-in of the ENTRY block and then `cast<Argument>`s it — in a Release
  // build that assert is compiled out and the cast is a WILD read. MEASURED
  // 2026-09-05: asking about `%8 = sdiv %1, 4` (defined in the MERGE block) at
  // `Pred` = entry SIGSEGVs `cq-opt` on the flagship. So LVI is asked ONLY about
  // values it is contracted to answer for, and everything defined after the
  // branch — which is where `-O1` schedules the rotated register in the whole
  // F-R3-1 family — is reached by the FORWARD half below instead. That split is
  // the reason the forward half exists at all and is not redundant with LVI.
  //
  // ⚠ AND THE `isIntegerTy()` FILTER IS A SECOND HARD API PRECONDITION, SAID
  // OUT LOUD (round-4 Rule-13 review, lens R4, finding F-R4-1 — the half this
  // comment used to leave undiscussed while explaining only the `DT` half).
  // `LazyValueInfo::getConstantRangeOnEdge` is defined over `ConstantRange`,
  // which is an INTEGER lattice: LVI has no fp edge fact to give, at any
  // predicate, ever. So the BACKWARD direction is integer-only BY TYPE, and an
  // fp register pinned by the region's own `fcmp` was asked NOTHING —
  // MEASURED as an ACCEPT on `hf01_fcmp_folded.ll` (a live f64 `%t` pinned to
  // 5.0 by `fcmp oeq %t, 5.0`, the arm's seed 5.0, `%t` measured UNROTATED),
  // where the unconditional twin `hf04` is byte-identical on both binaries and
  // proves CQ's own reading is an in-place Ry on `%t`'s rail. The repair is the
  // fp ANCHOR inside the edge loop below — NOT a widening of this list.
  SmallVector<Value *, 32> Cand;
  for (Argument &A : F->args())
    if (A.getType()->isIntegerTy() && Taint.Tainted.count(&A))
      Cand.push_back(&A);
  for (BasicBlock &BB : *F)
    for (Instruction &In : BB)
      if (In.getType()->isIntegerTy() && Taint.Tainted.count(&In) &&
          DT->dominates(&In, BI))
        Cand.push_back(&In);

  // THE THREE EXCLUSIONS, ONE SPELLING for both of F2's TESTs (the literal
  // seed's constant test in the walk below, the runtime seed's relational test
  // right here). Each conjunct's argument is in this function's header and at
  // the walk's TEST; they are a filter on the ANSWER, never on a seed of the
  // walk (H-6).
  // (bd dm7f.53: the sibling-condition exclusion is NOT a conjunct of this
  // lambda — its forcedness half is F2's own pin, so it lives at the CONSTANT
  // test only; see `siblingConditionCompareOnWire`.)
  auto excludedAtTest = [&](Value *V) {
    return f2ExcludedAtTest(V, CondWire, Taint, &PhiDesc);
  };

  // ---- THE RUNTIME SEED (bd z0re) — the RELATIONAL half. See the header
  //      block immediately above this function for why it replaces the
  //      constant walk for a non-`Constant` seed rather than running beside it.
  // ---- bd test_C_libtooling-dm7f.52 — THE fp HALF IS ASKED OF EVERY LEAF THE
  //      EDGE FORCES, discharging the retirement trigger committed in
  //      `control_inplace_ry_reject_stateprep_compound_cond.ll` (now the accept
  //      `control_inplace_ry_stateprep_compound_cond.ll`) ("THE DAY
  //      COMPOUND CONDITIONS ARE ADMITTED TO ANY CONTROL ACCEPT PATH, F2 MUST BE
  //      ASKED OF EVERY LEAF OF THE FLAG NETWORK"). The INTEGER half already is:
  //      `LazyValueInfo::getConstantRangeOnEdge` and `isImpliedCondition` both
  //      decompose a logical `and`/`or` condition natively. The fp half read only
  //      `BI->getCondition()` as an `FCmpInst`, so an `fcmp` LEAF of a compound
  //      tree was asked nothing. `forcedFcmpLeaves(E)` lists every `fcmp` whose
  //      truth value the edge FIXES — through an `and` (or `select a, b, false`)
  //      on the TRUE edge, through an `or` (or `select a, true, b`) on the FALSE
  //      edge, recursively — with that value. A bare `fcmp` condition yields
  //      exactly `{(fcmp, E == 0)}`, so every single-compare region asks the
  //      identical question it asked before (the anchor below is unchanged for
  //      it). An `xor` node forces nothing (neither child's value is fixed),
  //      which is the honest answer, not an omission. Monotone: it can only add
  //      pins, i.e. only turn an accept into a decline.
  auto forcedFcmpLeaves = [&](unsigned E) {
    return forcedFcmpLeavesOf(BI->getCondition(), /*Holds=*/E == 0);
  };
  auto *Seed = dyn_cast<Constant>(SeedV);
  if (!Seed) {
    Value *BrCond = BI->getCondition();
    for (unsigned E = 0; E < BI->getNumSuccessors(); ++E) {
      const bool TrueEdge = (E == 0);
      // INTEGER: every live tainted value of the seed's type (the same `Cand`
      // the LVI anchor reads — available at the branch, in function order).
      if (SeedV->getType()->isIntegerTy())
        for (Value *V : Cand) {
          if (V->getType() != SeedV->getType() || excludedAtTest(V))
            continue;
          if (isImpliedCondition(BrCond, ICmpInst::ICMP_EQ, V, SeedV, DL,
                                 /*LHSIsTrue=*/TrueEdge)
                  .value_or(false))
            return true;
        }
      // fp: an EQUALITY `fcmp` between the seed and a tainted value pins that
      // value to the seed's run-time BITS on the edge where the equality holds
      // (±0 and NaN make it an over-approximation — the decline direction).
      // `isImpliedCondition` is an `icmp` engine, so the fp half reads the
      // branch's own `fcmp`, exactly as the constant fp ANCHOR does.
      // (bd dm7f.52: every `fcmp` the edge forces, with its forced value —
      // for a bare `fcmp` branch that is the branch's own compare at `TrueEdge`.)
      if (SeedV->getType()->isFloatingPointTy())
        for (auto [BrFC, Holds] : forcedFcmpLeaves(E)) {
          if (!fcmpEqualityHoldsOnEdge(BrFC->getPredicate(), Holds))
            continue;
          for (unsigned K = 0; K < 2; ++K) {
            if (BrFC->getOperand(K) != SeedV)
              continue;
            Value *H = BrFC->getOperand(1 - K);
            if (H->getType() == SeedV->getType() && Taint.Tainted.count(H) &&
                !excludedAtTest(H))
              return true;
          }
        }
    }
    return false;
  }

  // The fp ANCHOR's operands, read ONCE from the branch's own condition. It is
  // deliberately NOT `Region.Condition`: the pin is an EDGE fact, and the edge
  // is the branch's, so the value asked about must be the value the branch
  // tests. (For every region reaching here the two are the same instruction;
  // reading `BI` means a future detection change cannot silently move the pin
  // off the edge it is about.)
  // (bd dm7f.52: the extraction below is now a lambda applied to every `fcmp`
  // the edge forces — `forcedFcmpLeaves(E)` — instead of to the branch's own
  // condition only; for a bare `fcmp` branch the two are the same compare.)
  auto fpAnchorOf = [&](FCmpInst *FC, ConstantFP *&FpK, Value *&FpH) {
    FpK = dyn_cast<ConstantFP>(FC->getOperand(1));
    FpH = FC->getOperand(0);
    if (!FpK) {
      FpK = dyn_cast<ConstantFP>(FC->getOperand(0));
      FpH = FC->getOperand(1);
    }
    // ±0.0 IS NOT A SINGLETON, AND THAT IS THE WHOLE REASON `clang` REFUSES THE
    // SUBSTITUTION IN THE FIRST PLACE. `fcmp oeq %x, 0.0` is TRUE for `%x =
    // -0.0` as well as `+0.0`, so the equality edge admits TWO distinct bit
    // patterns and `%x` is pinned to NEITHER. Pinning it to the written zero
    // would be a claim the edge does not support — and since the test below is
    // BIT identity on the `APFloat` (`ConstantFP` uniques on bits), it would
    // also be the exact `+0.0`/`-0.0` confusion `f2NoteConst`'s pointer test
    // exists to avoid. Refuse both zeros.
    //
    // A NaN CONSTANT is refused for the mirror reason: `oeq` with NaN is FALSE
    // for every `%x`, so its equality edge is unreachable and the pin would be
    // vacuous; `ueq` with NaN is TRUE for every `%x`, so it pins nothing. There
    // is no third case — a NaN `K` never yields a singleton edge.
    if (!FpK || !FpH || isa<Constant>(FpH) || !Taint.Tainted.count(FpH) ||
        FpK->getValueAPF().isNaN() || FpK->getValueAPF().isZero())
      FpK = nullptr;
    return FpK != nullptr;
  };

  for (unsigned E = 0; E < BI->getNumSuccessors(); ++E) {
    BasicBlock *To = BI->getSuccessor(E);
    F2State S;
    for (Value *V : Cand) {
      ConstantRange Edge = LVI.getConstantRangeOnEdge(V, Pred, To, BI);
      if (Edge.isFullSet() || Edge.isEmptySet())
        continue;
      f2Note(V, f2Refine(V, Edge, DL, &AC, DT), S);
    }

    // ---- THE fp ANCHOR (round-4 Rule-13 review, lens R4, finding F-R4-1).
    //
    // The one thing LVI structurally cannot do, done by hand and ONLY for the
    // shape where the answer is a theorem: on the edge where an EQUALITY
    // `fcmp` against a `ConstantFP` HOLDS, its other (tainted) operand IS that
    // constant. That is exactly what LVI does for an `icmp eq`; there is no
    // range lattice underneath it because a pinned fp value is a single
    // constant, which `F2State::Cst` already carries for ANY type.
    //
    // NOTHING ELSE IS SEEDED HERE, and the FORWARD half does the rest: every
    // tainted fp value derived from `FpH` is reached by `f2Model`'s EXACT
    // `ConstantFoldInstOperands` / `ConstantFoldCall` path the moment all its
    // operands are pinned, which is the same machinery that already answers a
    // pinned INTEGER register's `sitofp` (`..._stateprep_fp_seed_sitofp.ll`).
    // So an fp value that is SSA-identical to `FpH`, or an in-place alias of it
    // through a foldable chain, is covered without a second walker — the
    // F-1/F-3 "what OTHER set is computed over the same closure?" discipline
    // answered by reusing the closure rather than by minting one.
    //
    // POLARITY IS EXPLICIT AND COMPLETE over the four equality predicates.
    // `E == 0` is the TRUE successor of a conditional `br` (LLVM invariant):
    //   `oeq` / `ueq` pin on the TRUE edge, `one` / `une` on the FALSE edge.
    // `oeq`-true and `une`-false are EXACT (ordered equality: one bit pattern,
    // zeros and NaN excluded above). `ueq`-true and `one`-false additionally
    // admit `%x = NaN`, so the pin there is an OVER-approximation — which is
    // the SAFE direction and only ever costs a decline, because this whole
    // block is monotone: it can turn an accept into a decline and never the
    // reverse. `ueq`/`one` are kept rather than dropped so the clause has no
    // edge to get backwards, the same argument F2's integer half makes by
    // asking both edges.
    // (The table lives in `fcmpEqualityHoldsOnEdge` since bd z0re, which reads
    // it a second time for the runtime seed's fp half; extracted verbatim.)
    for (auto [FC, Holds] : forcedFcmpLeaves(E)) {
      ConstantFP *FpK = nullptr;
      Value *FpH = nullptr;
      if (fpAnchorOf(FC, FpK, FpH) &&
          fcmpEqualityHoldsOnEdge(FC->getPredicate(), /*TrueEdge=*/Holds))
        f2NoteConst(FpH, FpK, S);
    }
    unsigned Steps = 0;
    while (!S.WL.empty()) {
      if (++Steps > kF2MaxSteps) {
        Truncated = true;
        return false;
      }
      Value *V = S.WL.pop_back_val();
      // THE TEST — and the ONE place `CondWire` is consulted (2026-09-11 owner
      // ruling; see this function's header for the theorem, the retirement
      // trigger, and why the exclusion is HERE and not at the anchor). `V` is
      // still popped, and its users are still modelled below, so excluding it
      // costs the walk NOTHING: it filters an answer, it does not prune a seed.
      //
      // ---- THE 2026-09-13 NARROWING, R-1 (bd `test_C_libtooling-rb9x`) ----
      //
      // `Taint.isPeelClone(V)` is the SECOND exclusion, and its ground is a
      // DIFFERENT kind of argument from `CondWire`'s — weaker to state and
      // stronger to hold. `CondWire` had to reason about rival PROGRAMS (α: an
      // in-place Ry on the condition's own register; β: a live incoming `-O1`
      // folded to the seed). R-1 needs no rival at all: a value
      // `peelIndependentMergePhis` MANUFACTURED **did not exist in the module
      // `clang` produced**. This function's question is *"the source the author
      // wrote could have been `cq_theta(&<that register>, θ)`"*, and a value the
      // author could not have named is not in that question's domain — there is
      // no rival program for F2 to be protecting against.
      //
      // ⚠ THE PREIMAGE ARGUMENT, NOT THE "SAME WIRE" ONE. The weaker reading
      // ("the clone is the same compare, on the same wire, as
      // `Region.Condition` — which is `CondWire`'s first element") is TRUE for
      // the one-diamond case and does NOT cover a function with two FUSED
      // diamonds, where the peel manufactures a clone of the OTHER region's
      // condition, on a DIFFERENT wire, which can be pinned on this region's
      // edge (SCOPE_R.md §3b). That clone is excluded here too, and only the
      // preimage argument licenses it. A later reader who re-grounds this
      // conjunct on the wire turns that case into an unlicensed accept.
      //
      // ⚠ AT THE TEST, FOR A REASON THAT IS MEASURED AND NOT SYMMETRY. `V` is
      // still popped and its USERS are still modelled, so the clone keeps
      // seeding the forward evaluation. `control_peel_reject_fp_stateprep.ll`
      // declines through `f2Model`'s conservative arm on an fp select that is
      // reachable ONLY as a user of the clone (`Cand` is integer-only and the
      // branch is an `icmp`, so there is no fp anchor): pruning the clone from
      // the walk would flip that deliberately-pinned capability cost into an
      // unargued fp-merge-mux ACCEPT, which is the L9 angle-vs-data
      // wire-crossing family. The same spelling rule, for a second reason,
      // therefore has TWO independent measurements behind it.
      //
      // WHAT IT DOES **NOT** DO, because the partition is the honest part:
      //   * it does not reach a value DERIVED from a clone. `r_R4` (SCOPE_R.md
      //     §3e) pins a `zext i1 %clone to i32` that is itself pinned to
      //     `i32 0` and collides with an `i32` seed; that module still DECLINES
      //     after R-1, and deliberately — `zext(<a clone>)` has the same fold
      //     image as `zext(<the user's own compare>)`, so it is NOT
      //     preimage-free and a spelling that excluded it would be unargued.
      //   * it does not reach a compare the USER wrote twice, nor a
      //     hand-written `%cq.peel.cond`
      //     (`control_peel_stateprep_datamux_peeled_control.ll`): membership is
      //     a RECORD written at the manufacture site, never a name or a shape.
      //     `r_R1b` / `r_R5` as fixtures
      //     (`control_inplace_ry_reject_stateprep_second_cmp_onwire_{merge,pred}.ll`)
      //     are what fails if this is ever widened into "any second compare".
      //
      // RETIREMENT TRIGGERS: `TaintSet::PeelClones`' header carries all four
      // (the peel's placement / sole-consumer / in-loop triggers and the
      // `CmpInst`-RAUW one), and F2's own `railWireClosure`-vs-`CondRails`
      // divergence trigger above applies to this conjunct unchanged.
      // ---- THE 2026-09-14 NARROWING (bd `om35`, OWNER-RULED) ----
      //
      // `!PhiDesc.count(V)` is the THIRD exclusion and the AVAILABILITY one: a
      // value whose operand chain reaches the region's own merge φ WITHOUT
      // PASSING THROUGH A SLOT-AVAILABLE VALUE is available at neither slot the
      // question is about, so it is not a register the author could have
      // rotated. ⚠ Both halves of that sentence are load-bearing and the second
      // was added 2026-09-15 (bd `test_C_libtooling-hrts` / `l3i1` / `dpau`): a
      // value that merely USES `M` can perfectly well be available at a slot —
      // a loop-header φ taking an `M`-descendant on its BACK EDGE is exactly
      // that, and is a genuine rival the walk must not swallow. The full
      // argument, the reason it is NOT the refused dominance conjunct, and the
      // retirement triggers are in this function's header — read them there
      // before touching this line.
      //
      // ⚠ ON REACHABLE CODE THE 2026-09-15 SET IS A STRICT SUPERSET of what the
      // `MergeBB`-dominance proxy produced, so the effect at THIS line is
      // monotone: strictly more exclusions, hence strictly fewer witnesses,
      // hence F2 declines no more often than it did and sometimes less. (The one
      // place the set SHRINKS is a region whose `Pred` is unreachable, where the
      // slot test answers "available" for everything and the set collapses to
      // `{M}` — more declines, and `-O1` deletes such blocks before the pass
      // sees them. `availableAtAnF2Slot`'s header carries that case.)
      //
      // ⚠ AT THE TEST, AND FOR THE SAME MEASURED REASON AS THE OTHER TWO.
      // `V` is still popped and its USERS ARE STILL MODELLED below, so a
      // φ-descendant keeps seeding the forward evaluation and keeps feeding
      // `f2Model`'s conservative arm. The precedent is exact and is R-1's:
      // `control_peel_reject_fp_stateprep.ll` declines through that conservative
      // arm on an fp select reachable ONLY as a user of a value R-1 excludes
      // here, and pruning rather than filtering would have flipped that
      // deliberate capability cost into an unargued fp-mux accept. The same
      // spelling rule therefore protects the same property for a second
      // exclusion: pruning `PhiDesc` from `Cand` or from the walk would change
      // the walk and the step bound, and could vacate a `Truncated` decline into
      // an accept nobody argued for.
      //
      // ⚠ WHAT IT DOES TO `Truncated`, SAID PRECISELY (round-1 review, F-F1-4).
      // It can only ever convert a TEST decline into a `Truncated` decline,
      // NEVER the reverse — because excluding a value removes an EARLY RETURN
      // and so can only make the walk run MORE steps, never fewer. Both are
      // declines and the direction is safe, but the walk IS changed, so do not
      // read this as "the walk is untouched": `p8`'s subject run is a live
      // example of the walk continuing past a value the ORACLE stopped on. The
      // four fixtures that decline through the `|| Truncated` disjunct at this
      // function's CALL SITE are MEASURED unmoved (not unmoved "by
      // construction"), and they are the red-green for that: `step_cap_over`,
      // `unfoldable_curated_call`, `unevaluable_pinned_operand`,
      // `control_peel_reject_fp_stateprep`.
      // (`excludedAtTest` is the three conjuncts `CondWire.count(V) ||
      // Taint.isPeelClone(V) || PhiDesc.count(V)`, spelled once since bd z0re
      // so the runtime seed's relational test cannot drift from this one.)
      // bd dm7f.53 — the FOURTH exclusion, the sibling condition: its
      // forcedness half IS this pin (`f2Exact(V, S) == Seed`), so it is asked
      // here, after the pin, on whichever edge `E` found it; a covered
      // collider is TAGGED for the L1 re-ask (`siblingConditionCompareOnWire`).
      if (V->getType() == Seed->getType() && !excludedAtTest(V) &&
          f2Exact(V, S) == Seed) {
        if (!siblingConditionCompareOnWire(V, &CondWire)) {
          if (PinnedBy)
            *PinnedBy = V;  // R11 round 1 (A-F2): the diagnostic names it.
          return true;
        }
        cast<Instruction>(V)->setMetadata(
            kF2SiblingMD, MDNode::get(V->getContext(), {}));
      }
      for (User *U : V->users()) {
        auto *I = dyn_cast<Instruction>(U);
        if (!I || I->getFunction() != F || I->getType()->isVoidTy())
          continue;
        if (!Taint.Tainted.count(I))
          continue;  // classical, or the measure SINK — never a live rail.
        if (!f2Model(I, S, DL, &AC, DT)) {
          Truncated = true;
          return false;
        }
      }
    }
  }
  return false;
}

}  // namespace

// ---- 4.2 value-arm classification (PRD Part II §8.3; IMPLEMENTATION-4.2 §3).
// (The 4.1 if/else `readsProvenance` fallback that lived here is RETIRED —
// replaced by the chain walk's base-identity: a condition READ now surfaces as
// `ChainBase != Routed` → `control flow`, never the §3c string. That honors
// the bd `swap-route-detect-known-limits` warning: `if(q>5){p=q+1}` is a
// legitimate read, not a clobber.)
//
// `ValueChain` (the struct `walkValueChain` returns) is declared in
// ArmAnalysis.h (WI-0/MD1) so the re-hosted PASS-1 classifier shares it.

// Walk the VALUE chain WITHIN one arm block: while `V` is a supported tainted
// integer/fp `BinaryOperator` DEFINED IN `ArmBB`, follow its threaded operand
// — the SOLE tainted one (the other is classical, the `_hl`/`_lh` template
// shapes). Returns the chain and the value it bottoms at.
//
// ARM-BLOCK-BOUNDED for the same load-bearing reason as `walkPhaseSpine`
// above (bd `swap-route-ifelse-derived-base-boundary`): a value op defined
// OUTSIDE the arm is the routed base's own lineage, never an arm gate — and
// an unbounded walk would double-collect a shared pre-region op into both
// arms' chains (the double-erase/UAF family under the pre-3qlq replay+erase emitter).
//
// A Q+Q link (both operands tainted) sets `HasQQ` and threads the operand
// IDENTICAL to `RoutedHint` when exactly one matches (so `if(q>5){q=q+p}`
// bottoms at the routed `%q` and stays eligible for the §3c PERMANENT reject
// rather than the QQ defer — the PRD §8.3 disposition order runs the
// provenance check first), falling back to operand 0 (every QQ chain declines
// either way; the fallback only picks WHICH safe string fires).
//
// FP chains are walked like integer ones (fadd/fmul/… are supported stems) —
// the CALLER declines an FP-typed merge (`control flow`) before reading the
// base: the 4.2 emitter is integer-only and PredMux owns scalar-fp merges
// (bd dm7f.17). That is a lowering gap, not an angle rule — angle use is
// decided at the rotation consumers (CLAUDE.md R3).
ValueChain walkValueChain(Value *ArmIncoming, const BasicBlock *ArmBB,
                          TaintSet &Taint, Value *RoutedHint) {
  ValueChain C;
  Value *V = ArmIncoming;
  while (true) {
    auto *I = dyn_cast<Instruction>(V);
    if (!I || I->getParent() != ArmBB)
      break;  // out-of-arm (or non-instruction) — the chain's base.
    if (isPhiCall(I)) {
      C.MixedPhi = I;  // in-arm Rz inside a value lineage — mixed arm.
      break;
    }
    auto *BO = dyn_cast<BinaryOperator>(I);
    if (!BO || binaryStem(BO->getOpcode()).empty() ||
        !Taint.Tainted.count(BO))
      break;  // not a supported tainted link — bottoms here (caller declines).
    Value *Op0 = BO->getOperand(0);
    Value *Op1 = BO->getOperand(1);
    const bool T0 = Taint.Tainted.count(Op0) != 0;
    const bool T1 = Taint.Tainted.count(Op1) != 0;
    Value *Next = nullptr;
    if (T0 && T1) {
      C.HasQQ = true;
      Next = (Op1 == RoutedHint && Op0 != RoutedHint) ? Op1 : Op0;
    } else if (T0 || T1) {
      Next = T0 ? Op0 : Op1;
    } else {
      break;  // tainted result, untainted operands — off-pattern; bottoms here.
    }
    C.Ops.push_back(BO);
    V = Next;
  }
  C.Base = V;
  std::reverse(C.Ops.begin(), C.Ops.end());
  return C;
}

namespace {

// PURE VALUE ARM (Rule 8 linearity + no stray ops) — the value twin of
// `armBlockIsPureSpine` above, rejecting the same two emitter-fatal families:
//   * STRAY op beside the chain (incl. an off-path DAG sibling — the fan-out
//     shape `p=(p+3)*(p^5)` threads one path and leaves the other as a stray):
//     the value emitter hoists ONLY the chain (and its cone), and `RegionFlatten`
//     erases the arm BLOCK — a stray op is silently DROPPED (a vanishing user
//     measurement, Rule 5) and its taint work-list pointer dangles (UAF).
//   * FAN-OUT of a chain link: whole-chain reversal needs LINEAR lineage —
//     reverse-playing a shared link double-uncomputes the shared prefix
//     (use-after-free + double-free, Rule 8). Each link's ONLY user must be
//     the next link; the merge-feeding link's only user the merge `φ` itself.
// The base handle the chain bottoms at is NOT in `ArmBB` (it is the live
// routed register in the pred), so it is correctly never inspected here.
//
// bd `test_C_libtooling-fn1q` INCREMENT 1 — THE CLASSICAL CONE IS NO LONGER A
// STRAY. A non-chain arm instruction that is UNTAINTED, pure, non-escaping and
// speculatable is the classical computation feeding a chain link's classical
// operand (`if (c) p += (k*3+7)^5;` — `load @k`, `mul`, `add`, `xor`). It is
// collected into `Cone` in BLOCK order and hoisted by `emitValueRegion` AHEAD of
// the chain; anything else in the block is still a stray and still declines.
//
// ⚠ WHY THIS IS NOT A WIDENING OF THE STRAY RULE'S TWO HAZARDS. The rule above
// exists because the emitter hoists only the chain while `RegionFlatten`
// erases the arm BLOCK, so a stray is silently DROPPED (Rule 5) and its taint
// work-list pointer dangles. A cone member is neither dropped nor dangling: it
// is MOVED into the pred by the same hoist that moves the chain, before the
// flatten, and it is UNTAINTED so no taint structure names it at all.
//
// ⚠ FOUR CONJUNCTS, AND EACH IS LOAD-BEARING FOR A DIFFERENT REASON:
//   (K1) UNTAINTED. A tainted stray is a quantum value the chain does not
//        thread — the Rule-3 wire-crossing and the original fan-out hazard.
//        ⚠ It does NOT make the cone independent of the chain on its own. The
//        text here said "a classical op consuming a chain link would itself be
//        tainted by forward propagation, so (K1) already implies 'no cone member
//        reads a chain link'". That implication was NEVER true: a `cq_measure`
//        sink reads a quantum value and has an untainted result (the (K5)
//        paragraph below says "(K1) cannot see it"), and since bd cepm a second
//        op joins it — a would-be Phase-6 call whose callee is predicted to return
//        a classical value (`specCallResultPredictedClassical`). So the gap is
//        neither new with cepm nor one op (Rule-13 r1B F-r1B-4, ground corrected
//        by r2 F-r2-3; CLAUDE.md L3). What refuses a cone member reading a chain
//        link is the EXPLICIT operand test below, backed by the chain's
//        `hasOneUse` check (a link read by a cone member has a second user); the
//        code was and is safe, and the implication was never the fence.
//   (K2) NO WRITE, NO SIDE EFFECT. A `store` arm belongs to the 7.5 guarded-
//        store owner and must keep declining here, exactly as before; and it is
//        what makes (K4)'s memory argument true.
//   (K3) EVERY USER INSIDE THE ARM. ⚠ STATE THIS ONE PRECISELY, BECAUSE IT IS
//        DEFENSIVE AND HAS NO FIXTURE (L7 — an unruled bound that reads as a
//        live fence is how agent prose hardens into a ruling). For every shape
//        `recoverRegion` admits, an arm block dominates NOTHING but itself: its
//        sole successor is the merge, which it does not dominate, so a use
//        outside the arm can only be a merge φ — and a SECOND merge φ is
//        already refused by `soleMergePhi` before this helper is reached.
//        (K3) is therefore believed UNREACHABLE on the shipped accept surface,
//        and it was MEASURED as such at the increment's mutation matrix
//        (deleting it moves nothing over the corpus). It is kept because the
//        containment argument above rests on `recoverRegion`'s shape, which is
//        a DIFFERENT stage's property — exactly the premise L1 says not to
//        leave unstated. RETIREMENT TRIGGER: the day a value region admits an
//        arm with more than one successor, or a merge with a second φ, (K3)
//        becomes live and owes a fixture.
//   (K5) ⚠ NO NON-INTRINSIC CALL — added by Rule-13 round 1 (F-1), which
//        MEASURED the hole rather than arguing it. Before this increment the
//        containment of CQ's own front-end calls in a value arm was STRUCTURAL:
//        any non-chain arm op declined, so nobody had to name them. The four
//        conjuncts above replace that structure and NONE of them names a `cq_*`
//        call. Measured on a hand-written `.ll` whose `declare void @cq_phi(double)`
//        carries `speculatable memory(none) nounwind willreturn`: (K1) passes
//        (`cq_phi` takes no tainted operand and is not a taint source), (K2)
//        passes, (K3) passes, (K4) passes — the branch phase is HOISTED into the
//        pred, where it is uncontrolled, and `deleteGlobalPhases` then DELETES
//        it. A vanishing user gate, which is the stray rule's own named hazard
//        (Rule 5). The same held for `cq_measure` (whose taint stops at the sink,
//        so (K1) cannot see it) and `__cq_invert_begin/_end`.
//
//        ⚠ ASK THE QUESTION YOU MEAN, NOT A NAME — the bd `11qv` round-4 (P4)
//        lesson, which cost a P1 there for exactly this shape. The question is
//        "does some CQ stage OWN this call?", and the answer that does not drift
//        is: a call the lowering owns is a DECLARED external (`cq_theta`,
//        `cq_phi`, `cq_measure`, `cq_invert_*`, and every family added later),
//        while a legitimate classical cone call is an `@llvm.*` INTRINSIC — which
//        is what `clang -O1` leaves for `abs`/`smax`/`fshl`/`ctlz`. A name-prefix
//        test would have to be re-edited for every future family; this one does
//        not. MEASURED COST: nothing in the corpus moves, and a user's
//        `__attribute__((const))` helper already declined at (K4) (clang emits
//        `nounwind willreturn memory(none)` and never `speculatable`).
//
//        ⚠ (K1) INDEPENDENTLY COVERS `cq_theta` and `cq_invert_*` (both consume
//        or produce taint), so (K5) is the SOLE fence only for `cq_phi`,
//        `cq_measure` and the invert BRACKETS. Say that precisely: two fences on
//        two of the families and one on the other three is not "belt and braces
//        everywhere". ⚠ And since bd cepm a FOURTH: an untainted Phase-6 call
//        predicted to return a classical value that reads a quantum NON-chain
//        value (the condition register, say). (K1) passes it (untainted result).
//        In C it cannot reach (K5): after `-O1` a callee that reads its argument
//        LIVE while returning a classical value needs a side effect (the liveness
//        root that keeps the argument), so (K2) refuses the call; and (K4) refuses
//        every C spelling anyway, clang never marking such a callee
//        `speculatable`. ⚠ The first version of this sentence credited (K2) with
//        the `speculatable` fact, which is (K4)'s criterion — a callee clang
//        infers `memory(none) nounwind willreturn` PASSES (K2) (Rule-13 r2
//        F-r2-3). For an IR-level `speculatable memory(none)` callee (K5) is the
//        only fence (Rule-13 r1B F-r1B-4).
//   (K4) `isSafeToSpeculativelyExecute`. The hoist runs the op UNCONDITIONALLY,
//        which is not a choice: the condition is QUANTUM, so the emitted circuit
//        has no classical branch to hide behind. This is LLVM's own predicate —
//        the SAME call `emitValueRegion`'s speculation-totality fence already
//        makes on the chain (Rule 14: one spelling, asked in lockstep), in its
//        NO-CONTEXT form in BOTH places so the two cannot disagree.
//
// ⚠ AND THE HAZARD `isSafeToSpeculativelyExecute` DOES **NOT** COVER, stated
// here because it is the one a reader will look for: a hoisted LOAD is only
// sound if nothing between the hoist point and the load's old position can
// WRITE the location. That holds by CONSTRUCTION rather than by analysis — the
// only instructions on that path are the region's `br`, the arm's other cone
// members (K2: no writes) and its chain links (`walkValueChain` admits only
// `BinaryOperator`s, which write nothing). If either of those two facts ever
// changes, this argument must be rebuilt, not re-quoted.
//
// `Cone` is a REFERENCE, not an optional out-parameter: there is exactly one
// caller and it always wants the cone, so a nullable spelling would carry a
// branch nothing reaches. On a FALSE return the cone is CLEARED — a partially
// filled vector from an arm this function rejected must never be readable as a
// proven set, even though today's caller declines before looking.
bool valueArmIsPureChain(BasicBlock *ArmBB, ArrayRef<Instruction *> ChainOps,
                         const PHINode *MergePhi, TaintSet &Taint,
                         SmallVectorImpl<Instruction *> &Cone) {
  SmallPtrSet<const Instruction *, 8> OnChain(ChainOps.begin(),
                                              ChainOps.end());
  auto Reject = [&]() {
    Cone.clear();
    return false;
  };
  for (Instruction &I : *ArmBB) {
    if (I.isTerminator())
      continue;
    if (OnChain.count(&I))
      continue;
    if (isa<PHINode>(&I))
      return Reject();  // an arm-block φ is off-pattern for every value shape.
    if (Taint.Tainted.count(&I))
      return Reject();  // (K1)
    if (I.mayWriteToMemory() || I.mayHaveSideEffects())
      return Reject();  // (K2)
    for (const User *U : I.users()) {
      auto *UI = dyn_cast<Instruction>(U);
      if (!UI || UI->getParent() != ArmBB)
        return Reject();  // (K3)
    }
    for (const Value *Op : I.operands())
      if (auto *OpI = dyn_cast<Instruction>(Op))
        if (OnChain.count(OpI))
          return Reject();  // (K1), asked directly — see the note above.
    if (!isSafeToSpeculativelyExecute(&I))
      return Reject();  // (K4)
    if (isa<CallInst>(&I) && !isa<IntrinsicInst>(&I))
      return Reject();  // (K5)
    Cone.push_back(&I);  // BLOCK order ⇒ operand-before-user by construction.
  }
  for (size_t Idx = 0; Idx < ChainOps.size(); ++Idx) {
    const Instruction *I = ChainOps[Idx];
    const User *Expected = (Idx + 1 < ChainOps.size())
                               ? cast<User>(ChainOps[Idx + 1])
                               : cast<const User>(MergePhi);
    if (!I->hasOneUse() || *I->user_begin() != Expected)
      return Reject();  // fan-out, or a link consumed out of chain order.
  }
  return true;
}

// An instruction to anchor a generic decline diagnostic on (for the !dbg /
// source location). Prefer the tainted condition; fall back to the merge phi.
//
// ⚠ THE PREFERENCE ORDER IS UNCHANGED WHEN THE PREFERRED ANCHOR IS LOCATED —
// the rungs below only ever fire where the old spelling produced
// `<unknown>:0:0` (or `:0:0`), so no located diagnostic moves. When nothing is
// located the ORIGINAL choice is returned verbatim: `diagnoseUnderControl`
// dereferences its argument (`Where->getFunction()`), so this must never hand
// back null where the old spelling handed back an instruction, and the
// `CQ_CTRL_DBG` lever must keep printing the offending value.
//
// WHY THE RUNGS EXIST AT ALL — measured, review round 2 finding F-W2-5,
// 2026-09-14. The two-TU 6.5 probes `w2i2_h1_round2.c` / `w2i3_h1_cmpcond.c`
// (built `-O1 -g` per TU, `llvm-link`ed, one `cq-lowering`) decline at
// `classifyPhaseKickback`'s 2c wire fence, in ROUND 2 out of
// `repropagateControlMerges` — verified by breakpoint backtrace, not inferred —
// and `-O1` LICM had hoisted their condition `icmp sgt i32 %y, 50` out of the
// loop, DROPPING its `!dbg`. The old spelling returned that compare and `opt`
// printed `error: <unknown>:0:0:`, where the pre-increment ORACLE (which
// declined the same modules EARLIER, at the loop gate) printed
// `./w2i2_h1_round2.c:16:18`. A widening that moves traffic to a different
// fence inherits that fence's anchor quality; this is the repair.
//
// RUNG 3 IS THE REGION'S OWN `br i1`, and it is the RIGHT anchor rather than a
// consolation prize: every consumer of this helper is declining a REGION, and
// the branch is the `if` the user wrote. On those probes it is
// `br i1 %7, …, !dbg !48` = `w2i2_h1_round2.c:18:13` — the line that has to
// change — where the hoisted condition has no location at all. `Pred` is null
// for a `SelectRegion` / `AngleSelectRegion` (no CFG diamond), which the null
// test covers; and this helper is only ever called from the CLASSIFIERS, before
// any emitter flattens or erases a block, so the block pointer is live (the
// Track M H-1 dangle is a plan field read at EMIT time, a different question).
//
// ⚠ RETIREMENT TRIGGER: if a consumer of `declAnchor` is ever moved to run
// AFTER `RegionFlatten`, rung 3 becomes a read of a freed `BasicBlock` — drop
// the rung rather than "fixing" it with a handle, exactly as Track M's H-1 note
// says about `ControlRegion::Condition`.
Instruction *declAnchor(const ControlRegion &R) {
  auto *Cond = dyn_cast_or_null<Instruction>(R.Condition);
  if (anchorIsLocated(Cond))
    return Cond;
  if (anchorIsLocated(R.Merge))
    return R.Merge;
  if (R.Pred)
    if (Instruction *Term = R.Pred->getTerminator())
      if (anchorIsLocated(Term))
        return Term;
  return Cond ? Cond : R.Merge;
}

}  // namespace

// The first rotation whose arg-1 ANGLE operand is TAINTED — i.e. quantum-derived
// data in the angle slot — among the arm's IN-BLOCK spine gates and (for a
// derived base) the pre-region base `cq_phi` itself. Null if every angle is
// classical. Only the retired `cq_phi_<sfx>` register form is matched (it
// declines at `resolveSources`), so this returns null on an accepted module.
// (Pre-3qlq:) the emitter replayed each spine gate's angle VERBATIM onto a work
// rail (`cqrt_rz(rail, angle)`); after rotation lowering's RAUW a tainted angle
// read the i32 RUNTIME HANDLE, a fixed per-run tag, while the source semantics
// (angle = f(quantum value), value in superposition) admit NO fixed unitary.
// That was a verify-clean silent miscompile (found by the test_C_libtooling-9hh
// §8 adversarial review, 2026-06-10 — probe: `%ang = call double @ext(i32 %qd)`
// in the pred, arm gate `cq_phi(%qd, %ang)`; the trace printed
// `cqrt_rz(rail, ext(handle_id))`). The only sound disposition is a loud decline
// (Rule 3: the angle operand is classical, per-operand-use).
CallInst *taintedAngleGate(Value *ArmIncoming, const BasicBlock *ArmBB,
                           Value *Base, TaintSet &Taint) {
  auto AngleTainted = [&Taint](CallInst *CI) {
    return rotationAngleIsTainted(CI, Taint);  // ONE spelling (Rule 14).
  };
  for (Value *V = ArmIncoming; isPhiCall(V);) {
    auto *CI = cast<CallInst>(V);
    if (CI->getParent() != ArmBB)
      break;  // pre-region — handled via Base below.
    if (AngleTainted(CI))
      return CI;
    if (CI->arg_size() < 1)
      break;
    V = CI->getArgOperand(0);
  }
  // A derived base's OWN angle must be classical too: declining here turns the
  // later broken-module abort (rotation lowering RAUWs the f64 angle to an i32
  // handle inside a call that is never erased — exit 134) into a clean,
  // source-located decline.
  // ⚠ This row matches only the retired `cq_phi_<sfx>` base, as do the
  // value-arm row in `classifyArms` and `SwitchArmProve`'s twin. A `cq_theta`
  // base with a quantum-derived angle passes all three. On a value-arm diamond
  // (IR probe, 2026-10-05, bd tn85; its classical-angle twin lowers) the region
  // is lowered and `lowerRotations`' `declineTaintedAngle` then fails loudly
  // AFTER `lowerControlRegions` (`cq rotation lowering: unsupported
  // quantum-derived rotation angle`). Still loud, but mutate-then-decline rather
  // than detection before mutation (R8). Lowering a quantum angle at all is the
  // angle-register gap (bd 94ad).
  if (isPhiCall(Base) && AngleTainted(cast<CallInst>(Base)))
    return cast<CallInst>(Base);
  return nullptr;
}

namespace {

// SSA wire-walk twin of the positional scan below (position-robust, Rule 9): a
// pure tainted producer (`icmp`, `add`, casts) can be SCHEDULED anywhere —
// LLVM may sink the compare, or the arithmetic feeding it, below the chained
// theta with the SSA graph unchanged (`%c` still denotes the pre-Ry value) —
// so POSITION proves nothing about the wire. Opaque `cq_*` calls do keep
// their order, so the wire itself is reliable. Seeding matters as much as
// walking: the walk is seeded from the condition's full tainted backward
// PROVENANCE (`condProvenance`), NOT just the compare's direct operands — a
// derived condition (`%d = add %q, 1; icmp %d`) hides the stale `%q` one pure
// wire-hop behind the compare, and direct-operand seeding never reached
// `%q`'s chained theta user (confirmed accepted+miscompiled by the pre-fix
// tree 2026-06-10: `cq_template_add(%h, 1)` emitted after `cqrt_ry(%h, %t2)`;
// fixture control_swap_reject_stalecond_derived_cond.ll). From each seed,
// follow in-place gate user edges — a `cq_phi_<sfx>` user (retired register
// form) taking the value as its arg-0 handle is DIAGONAL (keep walking its
// result, the same physical wire), a `cq_theta` user is an in-place Ry AFTER the compared
// value was defined, i.e. the branch-time mint would read a post-Ry basis
// while the SSA operand denotes the pre-Ry value (the sunk-compare layout of
// the same miscompile — confirmed accepted+miscompiled 2026-06-10; fixture
// control_swap_reject_stalecond_sunk_compare.ll). The walk does not cross the
// merge `phi` (`CrossValueRouting` off), so PHI-MEDIATED post-region
// thetas are unreachable; a DIRECT post-region theta user of a provenance
// value IS reachable and declines — over-decline, accepted as safe (the wire
// demonstrably gains a non-diagonal gate while the condition's record is
// live; Prime Directive).
//
// The walk core is shared with the straight-line stale-record guard
// (`OpcodeLowering::declineStaleRecordOps`, test_C_libtooling-uzb) via
// `WireWalk::findNonDiagonalWireGate` (Rule 14). BOTH of that walker's modes
// are used from here since bd test_C_libtooling-lom0 Inc 4 — see
// `condWireDisposition` below for which one decides what.
CallInst *wireGainsNonDiagonalGate(
    const SmallPtrSetImpl<Value *> &Prov, const Instruction *EmitPoint,
    const DominatorTree *DT, const TaintSet *Taint,
    const SmallPtrSetImpl<const CallInst *> *Covered = nullptr) {
  // CrossValueRouting=TRUE since bd tayx (2026-07-03): the router-blind walk
  // was EVADED by a chained theta whose arg-0 reaches the condition's
  // provenance wire only through a one-register value-routing phi positioned
  // BEFORE the compare — outside condWireDisposition's positional
  // window and invisible to the router-blind forward walk, so the phase-arm
  // diamond was ACCEPTED and emitted its routed stream over a stale flag
  // (verify-clean wrong unitary; kjd1 post-fix round probe p11, pinned by
  // control_swap_reject_stalecond_router_diamond.ll). A router forwards the
  // same physical handle, so the walk must cross it — the identical fix as
  // the select mirror's GATE 2c (SelectClassify). This supersedes the old
  // "PHI-mediated post-region theta is unreachable by design" boundary note:
  // that rationale covered POST-region routing only and never considered the
  // pre-compare router; crossing also aligns the two SSA spellings of one
  // unitary (the DIRECT post-region theta already declined — over-decline,
  // safe — so the phi-mediated spelling declining too is consistency, not a
  // regression; no shipped accept fixture routes a theta through a phi).
  SmallVector<Value *, 16> Seeds(Prov.begin(), Prov.end());
  // bd dm7f.53: `Covered` is `findNonDiagonalWireGate`'s own set-difference
  // parameter, passed through; null (every caller but the two tree consumers'
  // claimed-φ-leaf rule, `condTreeCoveredPhiGates`) is the shipped walk.
  return findNonDiagonalWireGate(Seeds, /*CrossValueRouting=*/true, EmitPoint,
                                 DT, Taint, Covered);
}

// Disposition of the condition's non-diagonal-gate exposure (bd
// test_C_libtooling-lom0 Increment 4). Three outcomes, and the middle one is
// the whole increment: a wire gate that the emitter PROVABLY precedes is no
// longer an unconditional decline, it is a decline DEFERRED until the arm
// class is known.
enum class CondWireDisp {
  None,        // no relevant non-diagonal gate — the pre-4.1 accept path.
  DeclineNow,  // decline immediately, exactly as before Inc 4.
  ProvenPostRegion,  // every wire gate is provably after the whole emitted
                     // stream; ACCEPTABLE for a homogeneous PHASE arm only, so
                     // the caller carries it until `SawValueArm` is decided.
};

// Does a TAINTED-OPERAND `cq_theta` (an IN-PLACE, NON-DIAGONAL Ry on an existing
// handle) sit between the condition compare and the branch — positionally OR on
// the condition's SSA provenance wire (`wireGainsNonDiagonalGate`)? The emitter
// mints the flag at the BRANCH position, so the flag reads the basis AFTER any
// gate between the compare and the branch. A diagonal gate (`cq_phi`/Rz)
// preserves the basis, so the mint still equals the source compare (the
// stale-condition accept's soundness). A chained Ry does NOT: the flag then
// encodes a predicate of the post-Ry state — the wrong arm fires AND `icmp_inv`
// cannot strip the flag (verify-clean miscompile, pre-existing at WI-3; oracle
// investigation_mint_at_compare.py P2: stream fidelity cos^2(t2/2) = 0.848 with
// a CLEAN flag). Decline conservatively: any tainted-operand theta between
// compare and branch (even on another wire — over-decline is safe), any theta
// user anywhere on the condition's tainted provenance wire (the sunk-compare
// and derived-condition layouts), or a compare we cannot bound the scan for
// (defined outside the pred block). Minting at the COMPARE's program point was
// investigated and REJECTED (test_C_libtooling-ee5): it fixes arm selection but
// no flag-freeing compilation of this shape is source-exact — the decline is
// permanent. Design-of-record:
// docs/design/rssa-swap-control/MINT_AT_COMPARE.md.
//
// ---- INCREMENT 4 (bd test_C_libtooling-lom0): the POSITION-AWARE half ----
//
// Everything above stays true of a gate the emitter does not PROVABLY precede.
// What changed is the one case the position-free walk over-declined: a chained
// Ry that runs strictly AFTER this region's whole emitted stream. That was the
// single wall between CQ and a full Grover iteration (`… R0;
// cq_theta(&a, 0.5); a += off;` — state prep is Ry THEN +off, and no source
// spelling of S itself got past the walk).
//
// THE EMISSION CONTRACT IS THE PREDICATE. `SwapRouteEmit::emitRegion` builds
// with `IRBuilder<> B(BI)` where `BI == R.Pred->getTerminator()`: the flag
// mint, the hoisted arm gates with their `cqrt_x` brackets, the `_unc` flag
// strip and the flag free ALL land before `BI`, in `R.Pred`. So a theta `T`
// runs after the entire stream — mint, use, strip and free — exactly when
// `provablyBefore(BI, T, DT)`, i.e. `DT.dominates(BI, T)` (every path to `T`
// already executed the stream) AND `!isPotentiallyReachable(T, BI)` (once `T`
// fires the stream never re-runs, closing the loop-iteration-2 replay). A
// theta BEFORE the compare, on a sibling alias, through a pre-compare router
// phi, or on a CFG cycle with the region is NOT provably after and keeps its
// decline. Dominance over `BI` implies dominance over every stream call (they
// precede `BI` in `BI`'s own block), and `!reachable(T, BI)` implies
// `!reachable(T, S)` for every such `S` (reaching `S` in `R.Pred` falls
// through to `BI`) — so proving it at `BI` proves it for the whole stream.
//
// WHY THE FIRST-GATE ANSWER IS ENOUGH. `findNonDiagonalWireGate` in
// position-aware mode SKIPS a provably-after theta and keeps walking, but it
// does not walk THROUGH it (a theta result is never pushed onto the frontier,
// in either mode). Everything the walk would reach past a skipped `T1` is a
// forward USER of `T1`, hence CFG-reachable from `T1`; if any such `T2` could
// reach `BI` then `T1` could too, contradicting `!reachable(T1, BI)`. And the
// safety obligation here is exactly "no wire gate runs before the mint at
// `BI`", i.e. the reachability half — the dominance half is strictly extra
// conservatism. So "the walk returned nullptr" IS "every relevant gate is
// provably post-stream".
//
// WHY THIS IS SOUND ONLY BECAUSE INCREMENT 3 SHIPPED. The accept's claim is
// "once the strip has run, the region holds no live record of the wire". That
// is TRUE for a DIRECT condition (the flag is the sole record and the `_unc`
// strip discharges it) and FALSE for a DERIVED one: a `sqrt(a+3.0)<=5.0`
// condition leaves sitofp/fadd/sqrt template rails allocated and entangled
// past the strip, and a dead alloc parent of a derived routed base survives it
// too. Increment 4 does NOT re-prove that here — it RELIES on the M-A
// live-record guard (`RotationLowering::warnLiveRecordRotations`, the late
// post-uncompute slot) to adjudicate the post-region theta over those records,
// which it does with its own message
// (`lowering_reject_live_record_routed_base_anc.ll`). The interlock is the
// mechanism, not an assumption — that is why bd 6uqc sequenced Inc 3 strictly
// before Inc 4.
//
// ⚠ THAT INTERLOCK IS NOW A REPORT, NOT A DECLINE, AND THE ACCEPT STILL STANDS
// (owner ruling 2026-08-29, bd test_C_libtooling-lyyf, shipped as M-A Increment
// 7b). The guard emits a `DS_Warning` and the program LOWERS, so a
// derived-condition post-region theta with live records now compiles instead of
// exiting non-zero. Read what Increment 4 was actually leaning on before
// concluding this weakens it: every record in the list above is a DEPHASING
// record — a rail whose presence makes the wire's reduced state diagonal — and
// dephasing is precisely the class the ruling assigns to the USER's circuit
// ("we can always apply any unitary operation we want"). Increment 4 never
// borrowed M-A for a wrong-VALUE property (that is `declineStaleRecordOps` and
// this file's own condition-wire fence, both still loud) nor for a dirty-free
// one (`FreePoint`/`Uncomputation`, also still loud). What changed is who owns
// the ANSWER, not whether the answer is right: the compiler now emits the
// circuit the source describes and names the gate that carries the record.
// The two fixtures the sentence above once named are both re-dispositioned —
// `control_swap_reject_post_region_theta_derived_cond.ll` became an ACCEPT at
// Increment 6 (M-B discharged its records; the guard did not move), and
// `lowering_reject_live_record_routed_base_anc.ll` is now a WARNING fixture.
//
// NEVER ARGUE "DIFFERENT SSA VALUES ⇒ DIFFERENT RAILS" HERE. Since M-C (Inc 2)
// a tainted `add`/`sub`/`xor` with a classical operand lowers IN PLACE, so the
// customer's post-region theta acts on the very physical rail the condition
// read (one rail end to end — see tests/e2e/slice_control_seq_grover.c's
// corrected note). The proof above is over IR POSITIONS, which stay valid; a
// rail-identity argument would not.
//
// THE ACCEPT SET IS NARROW, AND EVERY LEG IS CHECKED SOMEWHERE:
//   P1 homogeneous PHASE arm — decided by the caller AFTER arm classification
//      (value arms keep the position-free walk verbatim, here and at the
//      routed-base walk; the 6.5 ClassicalCallArm path never reaches here).
//   P2 `!ShareCondFlag` — checked below: on the ziov share path `emitRegion`
//      SKIPS the strip+free, so the flag is a LIVE record past the region and
//      a later Ry on the wire dephases it.
//   P3 a FLAT `emitRegion` region — structural: `classifyArms` is reached only
//      from `handleBranchRegion`'s Diamond/IfElse arm, after the abort-park,
//      guarded-store and 6.5 classical-call pre-peels and after
//      `RegionShape::Nested` was dispatched to `recoverRegionTree`; the
//      resulting region is Kind=BranchRegion, Depth 0, childless, which
//      `lowerControlRegions` dispatches to `emitRegion`. The 4.3 nest, the
//      switch and the select paths keep their own position-free walks.
//   P4/P5 the pre-existing preconditions — `Cond` in `R.Pred` and the
//      positional compare→branch scan — are UNCHANGED for every condition
//      species but ONE and still decline immediately (the positional scan fires
//      even for a theta on ANOTHER wire, which no wire walk can see). The one
//      exception is a CLAIMED prep merge φ — see `chainedThetaBetweenDefAndBranch`
//      and the `CondIsClaimedRailPhi` parameter below (bd `hn29`/`leyd`/`52og`).

// bd `test_C_libtooling-hn29` / `-leyd` / `-52og` (Track P′) — THE CFG-BOUNDED
// POSITIONAL SCAN, and it is the ONE spelling of "can a tainted-operand
// `cq_theta` execute between this condition's definition and the flag mint at
// the branch?" for both φ consumers (Rule 14: `condWireDisposition`'s P5 prong
// and `classifyPhaseKickback`'s step-6 per-leaf window both CALL it; a second
// spelling is the drbq Inc-3 (b′) defect).
//
// WHAT IT REPLACES AND WHY THE FENCE IS NOT DELETED. The window this prong had
// was `Def->getNextNode() … Term` inside ONE block, which is a bounded, complete
// scan of the program points between the two **only when `Def` lives in `Pred`**.
// Everywhere else it walks off the end of `Def`'s block and returns `false`
// VACUOUSLY — which is precisely why the callers paired it with an unconditional
// `getParent() != Pred → DeclineNow`. The pairing is sound and it is an
// OVER-DECLINE (bd `hn29`, `leyd`, `52og`, all three filed under the owner's
// 2026-09-11 ruling that an over-decline of a valid circuit is a defect). This
// function is the fix the three beads and
// `control_phase_kickback_reject_mergephi_cross_block.ll`'s retirement trigger
// all name in the same words: *a real CFG-bounded scan — every block on a path
// from the φ's block to `Pred`, visited-set bounded — instead of the single-block
// window it has today*, obtained by SCANNING MORE PROGRAM POINTS and never by
// dropping the in-`Pred` conjunct.
//
// ⚠ THE IN-`Pred` CASE IS BYTE-IDENTICAL, DELIBERATELY AND BY CONSTRUCTION.
// `Def->getParent() == Pred` takes the first `return` below, which is the old
// loop expression-for-expression. Nothing that lowered before can move, in
// either direction, and that is what makes every flip this change produces an
// ACCEPT-direction one (its other input was an *unconditional* decline).
//
// ⚠ IT DOES NOT WIDEN THE IN-`Pred` RESIDUAL EITHER, AND THAT IS A CHOICE, NOT
// AN OVERSIGHT. Inside a loop, a theta sitting AFTER the branch in the body
// executes before the NEXT activation of the branch; the in-`Pred` window has
// never seen that, and the wire walk covers it only for gates on the condition's
// own wire (`provablyBefore`'s `!isPotentiallyReachable(T, BI)` half). Widening
// the in-`Pred` window to close it would flip shipped ACCEPTs in the DECLINE
// direction and is a separate, decline-direction change with its own Rule-13
// obligation. The CROSS-block walk below DOES cover it, because it must: its
// baseline is a decline, so the only sound direction to move from is "scan
// everything that can execute in between". The asymmetry is therefore
// conservative at both ends and is stated rather than tidied away.
//
// THE OBLIGATION, precisely. Decline iff some tainted-operand `cq_theta` can
// execute after `Def` and before an activation of `Term`. The walk:
//   * the tail of `Def`'s block — or ALL of it when `Pred` can reach `Def`'s
//     block, because then a later trip re-executes the part before `Def` while
//     the φ still denotes the first trip's value;
//   * every block reachable forward from there that can still reach `Pred`
//     (`isPotentiallyReachable`, which answers conservative-TRUE when it gives
//     up on its own block budget — the safe direction here, since a true answer
//     only adds blocks to scan);
//   * `Pred` itself up to `Term`, and then `Pred`'s successors ON THE SAME
//     reachability test — which contributes NOTHING in an acyclic region (no
//     successor of `Pred` can reach `Pred`) and walks the whole loop body when
//     the region entry is on a cycle. That second half is load-bearing for bd
//     `52og`: the back edge is exactly how a body theta gets in front of the
//     next mint.
// A visited set bounds it; exhausting the block budget DECLINES (Prime
// Directive — an unbounded gap is what the old prong refused, and refusing it
// here keeps that refusal rather than replacing it with a vacuous `false`).
//
// ⚠ THE VOCABULARY IS `cq_theta_*` ONLY, AND THE GROUND FOR THAT IS
// **AVAILABILITY** — NOT A TWIN. The rail-relabelling gate set also contains the
// dtzb in-place `add`/`xor` (CLAUDE.md), so scanning cross-block for thetas
// alone newly admits programs that could, in principle, carry such an op on the
// φ's rail inside the gap. The clearance for that was originally written as an
// argument from ONE measured twin (`c5_bare_xor_in_pred.ll` accepts on the
// ORACLE and its `xor` lowers OUT of place, `IMPL_P.md` §6 V12). That twin is
// real and it is not the reason. The reason is stronger, is about the module in
// front of the pass, and was re-derived at the Rule-13 round of 2026-09-15
// (item R-6):
//
//   **THE ONLY NAMES OF THE CONDITION RAIL THAT ARE AVAILABLE IN THE GAP ARE THE
//   φ ITSELF AND VALUES DERIVED FROM IT.** The arm theta's result is NOT: it is
//   defined inside the arm, the gap is not dominated by the arm, and spelling an
//   `xor` on it there is INVALID SSA — measured, not argued, on all three
//   binaries of that round and re-measured on the ORACLE at the ARM group gate:
//   `review_r13_armclassify/probes/r1_crossblock_xor_on_theta_name.ll` and its
//   in-`Pred` twin `r2_inpred_xor_on_theta_name.ll` are both rejected by the
//   VERIFIER — *"Instruction does not dominate all uses!"* — so the shape is not
//   expressible at all. And a state prep's straight-through incoming is the
//   SEED, which F1 requires to be untainted (*"a TAINTED pred incoming is a
//   no-cloning mux"*), so it is CLASSICAL and an `xor` on it is not a rail op.
//
//   The φ is then ALWAYS READ LATER — by the branch (a φ ROOT) or by a tree node
//   in `Pred` (a φ LEAF) — so `ArithLowering::classifyInPlaceReassignment`'s G6
//   (*"no data use AFTER the op"*, `provablyBefore` over EVERY user) refuses the
//   in-place conversion on it: the `xor` lowers onto a FRESH handle and cannot
//   alias the kickback's control. G6 additionally bails unconditionally inside a
//   loop (`LI.getLoopFor(Site->getParent()) || blockCanRepeat(…) → false`), which
//   covers the in-loop spelling the back-edge clause admits.
//
// ⚠ RETIREMENT TRIGGER — THE SAME ONE `railCondWireDisposition`'s header
// carries, now with a FOURTH pin: *"If M-C's G6 ever admits an in-place op on a
// rail with a later read, this ground is gone"*. The pins are the kickback's
// `control_phase_kickback_rail_inplace_xor_bridge.ll`, the select's
// `control_swap_select_rail_inplace_xor_bridge.ll`, the compare spelling's
// documented over-decline `..._reject_cmp_inplace_xor_bridge.ll`, and now the
// cross-block pair `d5_bare_xor_in_gap.ll` / `c5_bare_xor_in_pred.ll`
// (`trackP/probes/`), whose SUBJECT stream is
// `%h_op = cq_template_xor_i1_hl(i32 %h1, i1 true)` — a fresh handle — followed
// by `cqrt_rz_i1(i32 %h1, 0.9), !cq.branchphase`, the control untouched.
// ⚠ AND THE AVAILABILITY HALF HAS A TRIGGER OF ITS OWN: it is an argument about
// what can be SPELLED in the gap, so the day this helper gains a caller whose
// `Def` is NOT a region merge φ — a plain compare leaf, say, if step 5a's
// cross-block decline is ever widened — re-derive it. A compare is a snapshot,
// not a register, and neither half of the argument above transfers unexamined.
//
// ⚠ THE L1 ITEM — THIS PREDICATE DECIDES ON **ROUND-1 TAINT**, AND NOTHING
// RE-ASKS IT (Rule-13 round 2026-09-15, item R-5; neither track's record carried
// it, and `IMPL_P.md` §6's V1–V13 has no L1 entry at all). `isChainedTheta`
// below keys on `Taint.Tainted.count(CI->getArgOperand(0))`, and every caller
// runs inside `detectControlRegions`/`classifyPhaseKickback`, i.e. BEFORE
// `repropagateControlMerges` re-seeds taint from the 6.5/4.5 merge `%out` rails.
// A `cq_theta` whose arg-0 becomes tainted only in round 2 therefore reads as a
// SOURCE theta to this scan and as a CHAINED one to `lowerRotations`, which
// decides at FINAL taint — CLAUDE.md's L1 **PREDICATE** species, verbatim, and
// the same asymmetry that produced bd `9pum` / r9e5 F-B1R2-1.
//
// THE RECORD-AND-RE-ASK MACHINERY THAT EXISTS FOR THIS FAMILY DOES NOT COVER
// THIS PRONG, and that is a fact about it rather than an oversight to be read
// past: `markRailCondRead` → `reverifyRailCondReads` re-asks rungs (ii) and
// (iii) ONLY — the measure question and the wire question, *"exactly as
// `railCondWireDisposition` asks them"* — and `railCondWireDisposition` has NO
// POSITIONAL PRONG. So the positional scan is asked once, at round-1 taint, and
// never again.
//
// WHY THE RESIDUAL IS BELIEVED EMPTY — AN ARGUMENT, NOT A CLOSURE, AND IT WAS
// NOT CONSTRUCTED. (a) A round-2-only-tainted theta on the condition's OWN wire
// is covered by rung (iii)'s re-ask, which runs at FINAL taint. (b) The scan's
// reason for existing is the OTHER-wire case, and the only rail-relabelling gate
// it could miss there is a dtzb in-place `add`/`xor` aliasing the condition's
// rail — which the availability paragraph below shows is not spellable in the
// gap for this species, and which M-C's G6 refuses to convert in place anyway.
// ⚠ **SAY "PROBABLY EMPTY", NEVER "CLOSED"**: nobody has built the input, the
// exposure is PRE-EXISTING (the in-`Pred` window has it identically, and the
// in-`Pred` path is byte-identical here by construction), and what bd `hn29` /
// `leyd` / `52og` changed is that a population moved from an UNCONDITIONAL
// decline onto this taint-dependent test — new customers for an old premise.
// ⚠ RETIREMENT TRIGGER, by name: `reverifyRailCondReads`. The day it (or a
// sibling re-ask) gains a POSITIONAL rung, this prong owes it too — record the
// question at every call site here and re-ask it after the round-2 fixpoint, in
// BOTH entry points, declining loudly (CLAUDE.md L1: *"the cure is always the
// same and it is a pattern, not a prediction"*). Equally, the day any caller
// passes a `TaintSet` that is already FINAL, delete this paragraph rather than
// leaving a stale warning in front of a closed hole (L7-with-a-twist).
// ⚠ THE WALK ITSELF IS NOW SHARED, AND THE EXTRACTION IS A RULE-14 MOVE, NOT A
// TIDY-UP (bd `test_C_libtooling-drbq.12`, 2026-09-17). `anyInstructionInGap` is
// the ONE spelling of *"which program points can execute after `Def` and before
// an activation of `Term`?"*; `IsEvidence` is the ONLY thing its two callers
// differ in. The walk below is Track P′'s, moved line-for-line — the block
// bounds, the `Cyclic` re-scan, the `isPotentiallyReachable` push filter, the
// `B == Pred ? Term : nullptr` stop and the 512-block budget whose exhaustion
// DECLINES are all unchanged, so `chainedThetaBetweenDefAndBranch` is
// behaviour-identical for every pre-existing caller. Adding a THIRD question
// over this gap must extend this function, never copy it: two walks over one
// gap is how the two halves start to disagree about which points are in it.
template <typename FnT>
bool anyInstructionInGap(const Instruction *Def, const BasicBlock *Pred,
                         const Instruction *Term, FnT IsEvidence) {
  // `[From, Stop)` within one block; a null `Stop` means "to the end".
  auto scanRange = [&](const Instruction *From, const Instruction *Stop) {
    for (const Instruction *I = From; I && I != Stop; I = I->getNextNode())
      if (IsEvidence(*I))
        return true;
    return false;
  };
  if (!Def || !Pred || !Term)
    return true;  // cannot reason about the gap (Prime Directive).
  const BasicBlock *DefBB = Def->getParent();
  if (DefBB == Pred)
    return scanRange(Def->getNextNode(), Term);  // the pre-widening window.

  // ---- cross-block. Bounded forward walk over blocks that can still reach
  // `Pred`; anything that cannot reach it cannot precede the mint.
  const bool Cyclic = isPotentiallyReachable(Pred, DefBB);
  if (scanRange(Cyclic ? &DefBB->front() : Def->getNextNode(), nullptr))
    return true;
  SmallPtrSet<const BasicBlock *, 32> Visited;
  SmallVector<const BasicBlock *, 32> Work;
  Visited.insert(DefBB);
  auto push = [&](const BasicBlock *S) {
    if (!isPotentiallyReachable(S, Pred))
      return;  // off every path from `Def` to the mint.
    if (Visited.insert(S).second)
      Work.push_back(S);
  };
  for (const BasicBlock *S : successors(DefBB))
    push(S);
  // A budget, not an assertion: a pathological CFG must DECLINE rather than
  // fall out of the loop with a `false` nobody proved.
  unsigned Budget = 512;
  while (!Work.empty()) {
    if (Budget-- == 0)
      return true;
    const BasicBlock *B = Work.pop_back_val();
    if (scanRange(&B->front(), B == Pred ? Term : nullptr))
      return true;
    for (const BasicBlock *S : successors(B))
      push(S);
  }
  return false;
}

// The predicate is the old loop's, verbatim: a `cq_theta_*` whose arg-0 is
// TAINTED is an IN-PLACE, NON-DIAGONAL Ry on a live handle. A source theta
// (arg-0 classical) allocates a FRESH rail and relabels nothing, which is why
// the two-prep customer (bd `hn29`/`leyd`) is an accept and not a lucky one.
bool isChainedThetaCall(const Instruction &I, TaintSet &Taint) {
  const auto *CI = dyn_cast<CallInst>(&I);
  if (!CI)
    return false;
  const Function *F = CI->getCalledFunction();
  return F && F->getName().starts_with("cq_theta_") && CI->arg_size() >= 1 &&
         Taint.Tainted.count(CI->getArgOperand(0)) != 0;
}

bool chainedThetaBetweenDefAndBranch(const Instruction *Def,
                                     const BasicBlock *Pred,
                                     const Instruction *Term, TaintSet &Taint) {
  return anyInstructionInGap(Def, Pred, Term, [&](const Instruction &I) {
    return isChainedThetaCall(I, Taint);
  });
}

// ---- bd `test_C_libtooling-drbq.12` — THE LICM-HOISTED / CSE'd LOOP-INVARIANT
//      COMPARE (PRD §13.2 row W, §13.10 Q1; owner ruling 2026-09-11 that an
//      over-decline of a valid circuit is a DEFECT, not a safety margin).
//
// THE PROGRAM. `for (…) { if (q == 5) cq_theta(&r, .9); }` with `r` disjoint
// from `q` and NO gate on `q` — the simplest thing a user writes, and PRD §13.11
// worry 7's own headline. `q` is loop-INVARIANT, so `clang -O1` LICM-hoists the
// compare into the preheader (and, in the hand-unrolled twin, CSEs the two
// copies into the entry block so the SECOND region's `Pred` is the FIRST
// region's merge). Either way `Cond->getParent() != R.Pred`, P4 returns
// `DeclineNow` before anything else runs, and **the arm's own Ry plays no part
// in the decline at all**. 16 twin-matrix cells × 2 halves are this shape.
//
// WHY P4 EXISTED AND WHY IT NO LONGER HAS TO. Its own comment says it: the P5
// positional scan *"walks off the end of `Def`'s block and returns `false`
// VACUOUSLY"* outside `Pred`, *"which is precisely why the callers paired it
// with an unconditional `getParent() != Pred → DeclineNow`"*. Track P′ (bd
// `hn29`/`leyd`/`52og`) made that scan a REAL CFG-bounded walk and then flipped
// the pairing off for exactly ONE species — a claimed prep merge φ. This is the
// same flip for a COMPARE, and it pays a price P′ did not have to: P′'s walk is
// WIRE-BLIND, and a hoisted compare's gap contains the loop body, hence THE
// ARM'S OWN `cq_theta` ON A DISJOINT RAIL. MEASURED: with the wire-blind walk
// and no filter, all 16 cells trade a P4 decline for a P5 decline and move ZERO
// (`trackD2/IMPL_D2b.md` §4). So the gap question here is asked WIRE-SCOPED,
// which is PRD §13.10 Q1's remedy in its own words — *"admit a compare that
// DOMINATES `Pred` when nothing on the CONDITION's wire stands between it and
// `BI`"*.
//
// ⚠ THE RE-DERIVATION `chainedThetaBetweenDefAndBranch` DEMANDS OF THIS CALLER,
// DONE AND NOT INHERITED. That function's header carries a trigger naming this
// exact arrival: *"the day this helper gains a caller whose `Def` is NOT a
// region merge φ — a plain compare leaf, say … re-derive it. A compare is a
// snapshot, not a register, and neither half of the argument above transfers
// unexamined."* It does not transfer, in both halves:
//   * P′'s availability half — *"the only names of the condition rail available
//     in the gap are the φ itself and values derived from it"* — is FALSE here.
//     A compare's tainted operand is an ordinary register that DOMINATES the
//     compare, so `%q2 = add i32 %q, 1` in the gap is valid SSA, not an
//     "Instruction does not dominate all uses" verifier reject.
//   * P′'s G6 half — the φ *"is ALWAYS READ LATER"*, so M-C refuses the in-place
//     conversion — does not transfer either: the compare reads `%q` BEFORE the
//     gap, and the branch reads the COMPARE, not `%q`.
// The answer is an INTERLOCK, and it is MEASURED rather than assumed: control
// emission runs BEFORE `lowerOps`, so by the time M-C decides in-place-vs-out,
// the flag mint / `_unc` strip / controlled gate already read the condition's
// handle and already sit after anything in the gap, and G6 refuses the in-place
// conversion for a parent with a use it cannot prove earlier.
// `railRelabellingGateOn` below carries the measurement, the probe that showed
// the ALTERNATIVE (a fence on the `add`) to be a pure OVER-DECLINE, and the
// retirement trigger -- which is the one `railCondWireDisposition`'s header
// already owns rather than a new one.
//
// ⚠ THIS IS A THIRD CALLER OF `railWireClosure` AND IT IS DELIBERATELY **NOT**
// THE F2/R4 `CondRails`/`CondWire` SPELLING. Those two are `BackwardOnly`; this
// one is `BothWays`. That is not drift and it does not fire CLAUDE.md §4's
// *"`railWireClosure` as called by F2 diverges from R4's `CondRails`"* trigger,
// because NEITHER of those call sites is touched here and the three ask
// different questions whose failure directions are OPPOSITE: widening F2's
// exclusion set is an OVER-ACCEPT (21 recorded confirmed miscompiles), widening
// this GATE set is an OVER-DECLINE. A gate test wants the whole rail — including
// the forward members a diagonal `cq_phi` or a chained theta adds — while an
// exclusion set wants the provable core. Folding all three into one helper would
// put the strictly-safe direction of one in charge of the strictly-unsafe
// direction of the others, so it is refused IN WRITING here rather than left to
// a later tidy-up (Rule 14 cuts this way too: one SPELLING per QUESTION, not one
// spelling per callee).
void condRailMembers(Value *Cond, TaintSet &Taint,
                     SmallPtrSetImpl<Value *> &Out) {
  SmallPtrSet<Value *, 16> Prov;
  condProvenance(Cond, Taint, Prov);
  railWireClosure(Cond, Taint, WireDir::BothWays, nullptr, nullptr, Out);
  for (Value *P : Prov)
    railWireClosure(P, Taint, WireDir::BothWays, nullptr, nullptr, Out);
}

// Is `I` a gate that RELABELS the basis of a rail in `Members`? ONE species: a
// CHAINED `cq_theta` (an in-place, NON-DIAGONAL Ry) whose arg-0 NAMES the rail.
// Rz (`cq_phi`) is deliberately absent -- it is DIAGONAL, it preserves the basis
// the mint reads, and that is the whole ground the stale-condition accept has
// always stood on.
//
// THE dtzb IN-PLACE `add`/`sub`/`xor` IS DELIBERATELY **NOT** HERE, AND IT WAS
// BUILT, MEASURED AND REMOVED RATHER THAN NEVER CONSIDERED. The re-derivation
// above owes an answer for it (the availability half of Track P-prime's ground
// does not transfer to a compare), and the first answer written here was a
// FENCE: "an `add`/`sub`/`xor` with one tainted operand naming the rail is
// evidence", the same conservative both-roots reading `railWireClosure`'s own
// hop takes. **Measured, it is a pure OVER-DECLINE.** On
// `trackD2/probes/dtzb_flat_red.ll` -- the CSE'd two-region customer with
// `%u = add nsw i32 %1, 1` in the shared merge block, i.e. squarely in the gap
// -- the fence declined, and with the fence deleted the module ACCEPTS and emits
// `%h_op = cq_template_add_i32_hl(i32 %h, i32 1)`: an **OUT-OF-PLACE** add on a
// FRESH rail. It relabels nothing, so there was nothing to fence.
//
// AND THE REASON IT IS OUT OF PLACE IS STRUCTURAL FOR THIS SHAPE, NOT LUCK. By
// the time `classifyInPlaceReassignment` (M-C, `ArithLowering.h` -- the ONE owner
// of the in-place decision, Rule 14) runs inside `lowerOps`, CONTROL EMISSION HAS
// ALREADY HAPPENED: the flag mint, the `_unc` strip and the controlled gate are
// real instructions reading the condition's handle, and they sit AFTER anything
// in the gap. G6 refuses the in-place conversion for any parent carrying a data
// use it cannot prove earlier than the site, and it bails unconditionally inside
// a loop besides. So an in-place candidate in the gap is exactly a candidate M-C
// refuses. Asking M-C from HERE instead would be worse than useless: its answer
// is taken at FINAL taint over a FINAL CFG, so a `false` read at round-1
// detection could become `true` later -- a decline traded for an OVER-ACCEPT,
// which is the unforgivable direction.
//
// RETIREMENT TRIGGER -- and it is NOT A NEW ONE, which is the point. This rests on
// the SAME pin `railCondWireDisposition`'s and `chainedThetaBetweenDefAndBranch`'s
// headers already carry: *"If M-C's G6 ever admits an in-place op on a rail with
// a later read, this ground is gone."* Add this caller to that list rather than
// starting a second one. The day it fires, the fence measured and removed here is
// the shape to re-derive -- but re-derive it against G6's new answer, not against
// the both-roots reading, which is what made it an over-decline.
bool railRelabellingGateOn(const Instruction &I, TaintSet &Taint,
                           const SmallPtrSetImpl<Value *> &Members) {
  const auto *CI = dyn_cast<CallInst>(&I);
  if (!CI)
    return false;
  const Function *F = CI->getCalledFunction();
  if (!F || !F->getName().starts_with("cq_theta_") || CI->arg_size() < 1)
    return false;
  Value *A0 = CI->getArgOperand(0);
  return Taint.Tainted.count(A0) && Members.count(A0);
}

// May a COMPARE defined OUTSIDE `Pred` still have its flag minted at `Term`?
// The ONE spelling, CALLED by both consumers (`condWireDisposition`'s P4 and
// `classifyPhaseKickback`'s step-5a tree leaf) and re-derived by neither.
//
// FOUR CONJUNCTS, and the first is the one a reader will think is decoration:
//   (1) `isa<CmpInst>` — this admits a COMPARE only. A φ has its own route
//       (`CondIsClaimedRailPhi`, whose ground is a claimed prep region) and a
//       RAIL has `railCondWireDisposition`; neither ground is re-used here.
//   (2) `DT->dominates(C, Term)` — the mint reads `C`'s OPERANDS at `Term`, so
//       they must be available there. ⚠ It is VACUOUSLY TRUE for every module
//       LLVM will accept — `C` feeds `Term`'s condition through an SSA chain, so
//       it dominates `Term` by the verifier's own rule — and it is written
//       anyway because it is the PRECONDITION, not the test: the day a caller
//       passes a `C` that does not feed `Term`, this line is what refuses it.
//       A null `DT` refuses too (no tree, no proof).
//   (3) the gap carries no rail-relabelling gate on the condition's OWN rail.
//   (4) — at the CALLERS — the region must not be `ShareCondFlag`. That path
//       mints at `Cond->getNextNode()` (`SwapRouteEmit.cpp`) rather than at
//       `BI` and SKIPS the strip+free, so a cross-block condition would put the
//       flag mint in a different block from the rest of the stream and, in a
//       loop, mint ONCE for a stream that fires per trip. Kept on the
//       unconditional decline; it is a different emission contract, not a
//       different position.
//
// ⚠ WHAT THIS DOES **NOT** RELAX: the wire walk. `condWireDisposition` still
// runs `wireGainsNonDiagonalGate` over the condition's provenance, position-free
// first and then position-aware against `BI`, and that is what catches the
// dangerous half of this family — a body gate that relabels the condition's rail
// under a loop-INVARIANT SSA name. Such a gate can reach `BI` around the back
// edge, so `provablyBefore(BI, G)`'s second conjunct fails and the region
// declines. The two fences are complementary and neither is redundant: the walk
// covers FORWARD/diagonal descendants the backward closure never reaches, and
// this scan covers the in-place `add`/`xor` hop the walk deliberately refuses to
// cross.
// THE L1 ITEM, AND IT JOINS AN EXISTING ONE RATHER THAN OPENING A NEW ONE
// (self-adversarial round 2, 2026-09-17). Both halves of this predicate decide on
// **ROUND-1 TAINT**: `condRailMembers` builds `Members` from `condProvenance` +
// `railWireClosure` over `Taint.Tainted` as it stands before
// `repropagateControlMerges` re-seeds from the 6.5/4.5 merge `%out` rails, and
// `railRelabellingGateOn` reads the same set. A `cq_theta` whose arg-0 becomes
// tainted only in ROUND 2 therefore reads as a SOURCE theta here (not evidence) and
// as a CHAINED one to `lowerRotations`, which decides at FINAL taint - CLAUDE.md's
// L1 **PREDICATE** species, verbatim. That is EXACTLY the residual
// `chainedThetaBetweenDefAndBranch`'s own header already documents for the prong
// this one replaces on the cross-block path; this caller widens that residual's
// POPULATION (a class that was an unconditional decline now rests on a round-1
// test) without changing its species.
//
// WHAT IS RE-ASKED, MEASURED IN SOURCE: the WIRE and MEASURE rungs ARE. The flag
// mint calls `markCmpCondRead` from `lowerCompareImpl` with `WireRuled` on this
// path, and that record is keyed on the MINT's position - not on the source
// compare's block - so a hoisted compare gets the same record an in-`Pred` one does
// and `reverifyCmpCondReads` re-asks rungs (ii)/(iii) at FINAL taint in BOTH entry
// points. The POSITIONAL question is the one nothing re-asks.
//
// RETIREMENT TRIGGER, by name and shared: `reverifyCmpCondReads` /
// `reverifyRailCondReads`. The day either gains a POSITIONAL rung, this prong owes
// it too - record the question at this call site and re-ask it after the round-2
// fixpoint, declining loudly. Equally, the day any caller passes a `TaintSet` that
// is already FINAL, delete this paragraph rather than leave a stale warning in front
// of a closed hole (L7-with-a-twist).
bool crossBlockCompareMintable(Instruction *C, const BasicBlock *Pred,
                               const Instruction *Term, TaintSet &Taint,
                               const DominatorTree *DT) {
  if (!C || !Pred || !Term || !DT)
    return false;  // cannot reason about the gap (Prime Directive).
  if (!isa<CmpInst>(C))
    return false;
  if (!DT->dominates(C, Term))
    return false;
  SmallPtrSet<Value *, 16> Members;
  condRailMembers(C, Taint, Members);
  return !anyInstructionInGap(C, Pred, Term, [&](const Instruction &I) {
    return railRelabellingGateOn(I, Taint, Members);
  });
}

// bd test_C_libtooling-dm7f.53 — THE φ ANALOGUE OF `crossBlockCompareMintable`,
// discharging the retirement trigger `condTreeLeafWindowStale` carried: *"the
// day a φ leaf gains a wire-scoped cross-block admission of its own, this loop
// owes the same `getParent()` split"*. May a claimed region-merge φ leaf defined
// OUTSIDE `Pred` be read as a control at `Term`?
//
// THE CUSTOMER is the Dicke cascade (reporter t6.c line 13): `if (q0 & q1)
// cq_theta(&q2,·)` where `q1` is region 1's merge and region 2 (`if (q0 ^ q1)
// cq_theta(&q2,·)`) sits in the gap. Region 2's arm Ry on `q2` — a DISJOINT
// rail — is exactly the evidence the wire-BLIND walk cannot dismiss, so every
// third region of a cascade declined `condition predates a non-diagonal gate`.
//
// THE QUESTION is the compare's, asked of the φ's rail: no rail-relabelling gate
// (`railRelabellingGateOn`, a CHAINED Ry naming a member) on the φ's OWN rail
// (`condRailMembers(P)` — the φ, its incomings and their wire closure, so a gate
// on the pre-region name `S` or on the φ itself is still evidence) at any point
// of the gap. The compare's re-derivation transfers, in both halves:
//   * availability — the names of the φ's rail available in the gap are the φ,
//     values derived from it, and the pre-region name `S`; all are members;
//   * G6 — the φ IS read later (by this branch's network), so M-C refuses an
//     in-place `add`/`xor` conversion on it, the `railRelabellingGateOn` ground.
// The φ is ALSO `DT`-dominating `Term` (vacuous for a verified module; the
// precondition, as for the compare). Round-1-taint residual: the same one
// `crossBlockCompareMintable`'s L1 paragraph documents, same species.
bool crossBlockPhiLeafMintable(PHINode *P, const BasicBlock *Pred,
                               const Instruction *Term, TaintSet &Taint,
                               const DominatorTree *DT) {
  if (!P || !Pred || !Term || !DT)
    return false;  // cannot reason about the gap (Prime Directive).
  if (!DT->dominates(P, Term))
    return false;
  SmallPtrSet<Value *, 16> Members;
  condRailMembers(P, Taint, Members);
  return !anyInstructionInGap(P, Pred, Term, [&](const Instruction &I) {
    return railRelabellingGateOn(I, Taint, Members);
  });
}

bool crossBlockPhiLeafMintable(PHINode *P, const BasicBlock *Pred,
                               const Instruction *Term, TaintSet &Taint,
                               const DominatorTree *DT);

CondWireDisp condWireDisposition(
    const ControlRegion &R, TaintSet &Taint,
    const SmallPtrSetImpl<Value *> &Prov, const DominatorTree *DT,
    bool CondIsClaimedRailPhi = false,
    const SmallPtrSetImpl<const CallInst *> *Covered = nullptr) {
  auto *Cond = dyn_cast_or_null<Instruction>(R.Condition);
  if (!Cond || !R.Pred)
    return CondWireDisp::DeclineNow;  // cannot reason about the gap (Prime Directive).
  // bd `hn29` / `52og` (Track P′) — THE P4 CROSS-BLOCK PRONG IS NOW SPECIES-
  // SCOPED, and the scoping is the whole safety argument for leaving every other
  // caller byte-identical.
  //
  // `CondIsClaimedRailPhi` is set by exactly ONE caller
  // (`classifyPhaseKickback`, for a φ ROOT whose step-5c ladder has already run
  // rung 0 — `preppedRailPhiRegionIdx`, the ONE spelling, CALLED — plus rungs
  // (i)/(ii)). Everything else — every COMPARE condition at the flat kickback,
  // the value arm, the in-place Ry arm, the state prep — passes the default
  // `false` and keeps the unconditional decline, INCLUDING the LICM-hoisted
  // loop-invariant compare that CLAUDE.md §2 names as the reason "Grover's
  // condition register must be loop-variant". A compare is a SNAPSHOT of a
  // predicate taken at a program point; a claimed prep merge φ, like the
  // `cq_theta_i1` rail leaf beside it, IS the register. That difference is why
  // `railCondWireDisposition` may drop the prong entirely for a rail and why a
  // φ gets the STRICTLY STRONGER treatment of keeping it and making it real.
  // ⚠ Do NOT "simplify" this by transplanting `railCondWireDisposition`'s
  // prong-free treatment onto the φ: that ground is an argument about M-C's G6
  // over a `cq_theta_i1` NAME, and bd `4aiu` refused to transplant it unmeasured.
  // This change does not transplant it either — it keeps the prong.
  //
  // ⚠ bd `drbq.12` (2026-09-17) — AND A COMPARE THAT **DOMINATES** `Pred` WITH A
  // CLEAN WIRE-SCOPED GAP. The paragraph above says every COMPARE *"keeps the
  // unconditional decline, INCLUDING the LICM-hoisted loop-invariant compare
  // that CLAUDE.md §2 names as the reason 'Grover's condition register must be
  // loop-variant'"*. THAT SENTENCE IS NOW HISTORY and is deliberately left
  // standing above so the two readings can be compared: what made a compare
  // different from a claimed φ was never the species, it was that P′'s
  // cross-block walk is WIRE-BLIND and a compare's gap routinely contains the
  // arm's own Ry on a DISJOINT rail. `crossBlockCompareMintable` is the
  // wire-scoped answer to exactly that, with the availability re-derivation the
  // callee's own trigger demands of a non-φ caller — see its header.
  // `ShareCondFlag` is NOT admitted: that path mints the flag at
  // `Cond->getNextNode()`, so it is a different emission contract.
  const Instruction *BI = R.Pred->getTerminator();
  const bool CrossBlockCompare = !CondIsClaimedRailPhi &&
                                 Cond->getParent() != R.Pred;
  if (CrossBlockCompare &&
      (R.ShareCondFlag ||
       !crossBlockCompareMintable(Cond, R.Pred, BI, Taint, DT)))
    return CondWireDisp::DeclineNow;  // unbounded gap across blocks.
  // The POSITIONAL scan (P5) is unconditional and runs first: a tainted-operand
  // theta between the compare and the branch is a decline even on another wire,
  // and no position-aware proof can reach it (it is not dominated by `BI`
  // anyway, but the scan also covers wires the walk never sees). For a condition
  // in `R.Pred` this call IS the old single-block loop, expression-for-
  // expression; for a claimed φ elsewhere it is the CFG-bounded walk.
  //
  // ⚠ bd `drbq.12` — AND IT IS SKIPPED, EXACTLY ONCE, FOR THE CROSS-BLOCK
  // COMPARE THE PRONG ABOVE ADMITTED. Reaching here with `CrossBlockCompare`
  // means `crossBlockCompareMintable` has ALREADY walked this same gap with
  // `anyInstructionInGap` — the same walk, the same blocks, the same budget —
  // and found no relabelling gate ON THE CONDITION'S RAIL. Asking the WIRE-BLIND
  // question here would re-decline what it proved, on the one piece of evidence
  // this whole bead is about: the arm's own `cq_theta` on a DISJOINT rail, which
  // for a hoisted loop-invariant compare sits inside the gap because the body
  // reaches `Pred` around the back edge. ONE question, asked ONCE, at the site
  // that decides admission.
  // ⚠ NOTHING ELSE LOSES THE SCAN. An in-`Pred` compare, a claimed prep merge φ
  // (P′'s own customer, which needs the CFG walk precisely because it has no
  // wire-scoped admission of its own) and a rail all take it unchanged.
  // bd dm7f.53 (closes bd dm7f.62) — A CLAIMED φ ROOT DEFINED OUTSIDE `Pred`
  // asks the WIRE-SCOPED gap, `crossBlockPhiLeafMintable` — the question the
  // φ LEAF already asks (`condTreeLeafWindowStale`), so the root and the leaf
  // spell one question once. Its ground is the leaf's (availability + G6, at
  // that function). An in-`Pred` φ keeps the scan below unchanged.
  if (CondIsClaimedRailPhi && Cond->getParent() != R.Pred) {
    auto *P = dyn_cast<PHINode>(Cond);
    if (!P || !crossBlockPhiLeafMintable(P, R.Pred, BI, Taint, DT))
      return CondWireDisp::DeclineNow;
  } else if (!CrossBlockCompare &&
             chainedThetaBetweenDefAndBranch(Cond, R.Pred, BI, Taint))
    return CondWireDisp::DeclineNow;  // chained Ry on a live handle after the compare.
  // Position-FREE first: no gate at all is the ordinary accept path, and it
  // must not pay for a dominator query.
  if (!wireGainsNonDiagonalGate(Prov, /*EmitPoint=*/nullptr, /*DT=*/nullptr,
                                &Taint, Covered))
    return CondWireDisp::None;
  if (R.ShareCondFlag)
    return CondWireDisp::DeclineNow;  // P2 — the flag outlives the region.
  if (!DT)
    return CondWireDisp::DeclineNow;  // no tree, no proof (Prime Directive).
  if (wireGainsNonDiagonalGate(Prov, BI, DT, &Taint, Covered))
    return CondWireDisp::DeclineNow;  // some gate is NOT provably post-stream.
  return CondWireDisp::ProvenPostRegion;
}

// bd test_C_libtooling-3qlq.4 (Inc 1b) — the wire question for a RAIL-LEAF
// condition (`_Bool b = b0; cq_theta(&b, θ); if (b) …`). The SSA name `b` read by
// the branch is STALE iff a non-diagonal gate fires on `b`'s wire between its
// def and the branch; the kickback gate is emitted AT the branch and is
// diagonal, so — exactly as `condWireDisposition` argues for a compare — a
// gate proven to execute AFTER the branch (`ProvenPostRegion`) invalidates
// nothing this region leaves behind. Two prongs of the compare version are
// deliberately absent: the same-block/positional scan and the `ShareCondFlag`
// clause (a rail is the user's register, shared with its data users by
// construction — nothing is minted, nothing outlives the region).
//
// ⚠ THE POSITIONAL PRONG IS NOT REDUNDANT WITH THE WIRE WALK, AND THE FIRST
// SPELLING OF THIS HEADER SAID IT WAS (Rule-13 round-1 finding F-1b-1, a
// CONFIRMED silent miscompile). The prong scans the block window for ANY
// tainted-operand theta; the walk asks the seed's USER graph — and until F-1b-1
// the walk's ancestry stopped at a TEMPLATE parent, so a SIBLING in-place Ry on
// the same physical rail (`bool t = q & 1; b = t; cq_theta(&b,.5); c = t; cq_theta(&c,.9);
// if (b) …`) was on neither side, and the kickback rode the register `c` moved.
// The fix is in the walker, not here: `findNonDiagonalWireGate` now crosses a
// chained theta's arg-0 edge whenever the parent is TAINTED (the relation
// `lowerRotations` builds the rail from), which also closes the compare twin
// that accepted on `main`. With `Taint` the walk asks the rail's whole wire, in
// this block or another, with the DT prong: a chained or sibling `cq_theta`
// between the def and the branch is refused (not provably post-branch), and a
// rotation on the register AFTER the region is admitted
// (`control_phase_kickback_rail_post_ry.ll`).
//
// ⚠ THAT IS THE SAME-WIRE HALF ONLY, AND THE PRONG'S OTHER HALF IS NOT COVERED
// BY ANY WALK (round 2, F-1b2-4 — the sentence above once read as complete).
// The compare path's P5 keeps its positional scan for a theta on ANOTHER wire,
// whose residual target is a dtzb in-place `add`/`xor` that would ALIAS the
// condition's rail (`x = b ^ 1; c = x; cq_theta(&c, θ); if (b) …`), which the
// forward walk deliberately does not cross. The rail path drops the prong on a
// STRUCTURAL ground, measured: a condition rail is always read later by its own
// branch in `R.Pred` — or, at the 4.4 select (bd r9e5, 1b-B.1, which inherits
// this ground), by the two mid-block `cqrt_cnot` reads that mint and strip its
// copy flag — so M-C's G6 ("no data use AFTER the site") refuses the in-place
// conversion on it — the `xor` lowers OUT of place onto a fresh rail and cannot
// alias (`control_phase_kickback_rail_inplace_xor_bridge.ll` for the kickback
// and `control_swap_select_rail_inplace_xor_bridge.ll` for the select, the two
// ACCEPT pins; the compare spelling is the documented over-decline
// `..._reject_cmp_inplace_xor_bridge.ll`). If M-C's G6 ever admits an in-place
// op on a rail with a later read, this ground is gone and the prong must return
// at BOTH consumers (round-1 item F-B1R1-3: one retirement trigger, two pins).
CondWireDisp railCondWireDisposition(
    const ControlRegion &R, TaintSet &Taint,
    const SmallPtrSetImpl<Value *> &Prov, const DominatorTree *DT,
    const SmallPtrSetImpl<const CallInst *> *Covered = nullptr) {
  if (!R.Pred || !(isCondRailLeaf(R.Condition) || isRegCondLeaf(R.Condition)))
    return CondWireDisp::DeclineNow;
  const Instruction *BI = R.Pred->getTerminator();
  if (!wireGainsNonDiagonalGate(Prov, /*EmitPoint=*/nullptr, /*DT=*/nullptr,
                                &Taint, Covered))
    return CondWireDisp::None;
  if (!DT)
    return CondWireDisp::DeclineNow;  // no tree, no proof (Prime Directive).
  if (wireGainsNonDiagonalGate(Prov, BI, DT, &Taint, Covered))
    return CondWireDisp::DeclineNow;  // some gate is NOT provably post-branch.
  return CondWireDisp::ProvenPostRegion;
}

}  // namespace

// bd 3qlq.4 — a RAIL-LEAF condition must not have been MEASURED before the
// consumer that reads it: a measured register is classical there, and firing a
// gate controlled on it after the measurement would be a post-measure gate
// (Rule 6's loud-reject class). The mirror of `condDataUseDisposition`'s
// `MeasuredEarly` for a compare — ⚠ with one qualification that the first two
// spellings lacked (F-B1R1-1): the register is a WIRE with several SSA NAMES
// (a chained theta's result and its arg-0 denote one handle after
// `lowerRotations`), and the measurement may name any of them, so the question
// is asked over `railWireNamesBackward`'s closure and not over `Rail->users()`
// alone. A `cq_measure` user of any wire name that precedes `ReadPoint`,
// or one from which `ReadPoint` is REACHABLE on some path (a dominating block, a
// classically-guarded side path — F-1b-2), executes first and refuses; only a
// measurement the read point can never follow is downstream of the region and
// owns the register from there on. Strictly stricter than the compare path,
// which (measured, F-1b-2) mints a flag from a register measured
// UNCONDITIONALLY before the branch — a pre-existing gap recorded with bd
// test_C_libtooling-r903, not widened here.
//
// bd test_C_libtooling-r9e5 (1b-B.1) — THE READ POINT IS A PARAMETER, NOT THE
// BLOCK'S TERMINATOR, and the difference is a live accept. The kickback's gate
// is emitted AT the branch, so every non-terminator of `Pred` precedes it and
// "same block" IS "before"; the 4.4 select's stream is emitted immediately
// BEFORE THE SELECT, mid-block, so a same-block measurement must be tested
// POSITIONALLY — `bool b = θ(…); int a = b ? 2 : 5; int m = cq_measure(b);`
// (plain `clang -O1`, probe `s05`) measures AFTER the select and is the ordinary
// downstream case. ONE spelling, two read points (Rule 14): the two kickback
// callers pass `Pred->getTerminator()` and are byte-unchanged by construction —
// a `cq_measure` user is never a terminator, so a same-block one always
// precedes it, which is exactly what the old `return true` said.
//
// ⚠ THE SAME-BLOCK CASE IS ONE QUESTION, NOT A SHORTCUT (orchestrator finding
// F-B1-1, 2026-09-10, plain-C reachable and CONFIRMED on the first B.1 build).
// The first spelling returned `M->comesBefore(ReadPoint)` for a same-block
// measure and never asked reachability — so `for (i…) { int a = b ? i : 5;
// acc += cq_measure(a) + cq_measure(b); }` (the select stays in the body because
// its arm is loop-VARIANT; `-O1` LICM-hoists the constant-arm form) ACCEPTED,
// and every activation after the first controlled its copies on a register the
// previous trip had COLLAPSED — a post-measure gate, Rule 6's loud-reject class,
// which the kickback's terminator read point refuses on the same program.
// `isPotentiallyReachable` already answers the same-block case correctly on its
// own (`M` before `ReadPoint` ⇒ true; `M` after it ⇒ true iff the block can
// reach itself through a back edge, false in the entry block or any acyclic
// one), so the ONLY correct spelling is to ask it for every measure, wherever
// it sits. Pinned by `control_swap_reject_select_rail_inloop_measure_after.ll`
// (the plain-C module) and `…_inloop_measure_after_constarm.ll` (hand IR: the
// constant-arm select kept inside the body); `…_rail_measure_after.ll` (`s05`,
// flat) stays the accept that keeps this a discriminator.
void railWireNamesBackward(const Value *Rail, const TaintSet &Taint,
                           SmallVectorImpl<const Value *> &Out) {
  // THE ONE RELATION: `lowerRotations` lowers a `cq_theta` IN PLACE on its
  // arg-0's rail iff that arg-0 is TAINTED (`Chained = taint.Tainted.count(Op)`,
  // RotationLowering.cpp) and RAUWs the whole chain onto ONE handle — so every
  // name on that chain denotes the same physical register. The walk follows
  // exactly that edge: a chained theta steps to its parent; a SOURCE theta (a
  // classical seed) stops; a NON-theta tainted parent (a template / cast / phi
  // result the theta rotates in place) is COLLECTED and not entered — its own
  // operands are OTHER rails (an out-of-place template mints a fresh rail), so
  // entering them would over-decline a measurement of a different register
  // (`control_swap_select_rail_other_register_measured.ll` pins the stop).
  // ⚠ THAT STOP RESTS ON ANOTHER FILE'S FENCE (round-2 item F-B1R2-3): "its
  // operands are other rails" is a statement about M-C — a measured or
  // later-read parent is always lowered OUT of place because
  // `ArithLowering::classifyInPlaceReassignment`'s G6 refuses a later data use
  // and G7's `priorUseIsSettled` refuses a prior `cq_measure` (measured:
  // `cq_measure(b0)` before `x = b0 ^ 1` emits `cq_template_xor_i1_hl(h0,1)`, a
  // fresh rail). RETIREMENT TRIGGER: if M-C ever admits an in-place op on a rail
  // with a measured or later-read parent, this closure must ENTER the parent.
  // FORWARD names (a later chained theta on this wire) are not collected here,
  // and the argument has TWO legs, one per accept leg of `gateIsHarmless`
  // (round-2 item F-B1R2-2): leg 1 — if the forward theta T is provably after
  // every execution of the read, no measurement of T's result can precede the
  // read (it is dominated by T, so a path M → read would give T → M → read);
  // leg 2 — the BARRIER accept admits T only when every path T → read executes
  // the seed's own definition (or a superseding wire-tracking phi), so any
  // measurement of T's result lies on such a path and the barrier — the seed
  // theta re-executing — sits between it and the control read. A forward
  // theta that precedes the read WITHOUT either leg is rung (iii)'s own decline.
  //
  // (Track A.1, Rule-13 round-1 finding F-A1-3) ⚠ AN IN-PLACE RELABELLING IS THE
  // SAME REGISTER UNDER A NEW NAME, and the closure CROSSES it. The narrowing of
  // rung (ii)'s SEED to the compare's direct operands is sound only if the WIRE
  // is still followed, and `taint.InPlaceRailOps` is a second way one register
  // wears two names: the dtzb `q = q OP c` that `lowerLoops` proved and
  // `lowerOps` emits as `cqrt_{addc,xorc}_<W>(handle, imm)` — a MUTATION of the
  // handle, not a fresh rail. Its result and its rail operand are one physical
  // register, so a measurement naming either collapses both. Asked of the ONE
  // set `lowerLoops` writes (`markInPlaceRailOp`, which records the set and the
  // proven operand INDEX at the same statement — the eqpx spelling) and the same
  // set `LoopLowering::staleRailRecordRead` reasons over; never re-derived.
  // The OUT-of-place case is deliberately NOT crossed and is the whole point of
  // the narrowing: `cq_template_add_<W>_hl` MINTS a fresh rail, and its operand
  // is a different register the control does not read.
  SmallPtrSet<const Value *, 8> Seen;
  const Value *V = Rail;
  while (V && Seen.insert(V).second) {
    Out.push_back(V);
    if (auto *I = const_cast<Instruction *>(dyn_cast<Instruction>(V)))
      if (Taint.InPlaceRailOps.count(I)) {
        auto It = Taint.InPlaceRailIdx.find(I);
        if (It != Taint.InPlaceRailIdx.end() &&
            It->second < I->getNumOperands()) {
          V = I->getOperand(It->second);
          continue;  // same register, previous name.
        }
        // UNREACHABLE at HEAD — `markInPlaceRailOp` is the one way to join that
        // set and writes the index in the same statement — but if it ever is
        // reached, over-approximate the wire (collect BOTH operands and stop)
        // rather than silently narrow it: more names means more refusals, and a
        // non-theta last name grants no per-activation barrier either, so both
        // effects point at a DECLINE. Never guess which operand is the rail.
        for (const Use &U : I->operands())
          if (Taint.Tainted.count(U.get()))
            Out.push_back(U.get());
        break;
      }
    const auto *CI = dyn_cast<CallInst>(V);
    if (!CI)
      break;
    const Function *F = CI->getCalledFunction();
    if (!F || !F->getName().starts_with("cq_theta_") || CI->arg_size() < 1)
      break;
    const Value *Op = CI->getArgOperand(0);
    if (!Taint.Tainted.count(const_cast<Value *>(Op)))
      break;  // a SOURCE theta: arg-0 is the classical seed, not a rail.
    V = Op;   // CHAINED: in place on the parent's rail — same register.
  }
}

bool railMeasuredBeforeReadPoint(const Value *Rail,
                                 const Instruction *ReadPoint,
                                 const TaintSet &Taint,
                                 const DominatorTree *DT) {
  SmallPtrSet<const CallInst *, 8> Sinks(Taint.MeasureCalls.begin(),
                                         Taint.MeasureCalls.end());
  // Rule-13 round-1 item F-B1R1-1 (bd r9e5): the measure set is the rail's
  // WIRE, not its SSA name. `lowerRotations` RAUWs a chained-theta chain onto
  // ONE handle, so `bool b = θ(b0, ·); m = cq_measure(b0); a = b ? 2 : 5;`
  // collapses the very register the merge then controls on, while `b0` is no
  // user of `b`. Rung (iii)'s gate walk already closes each seed backward over
  // that chain; this rung asked the SSA name — two rungs of one ladder over
  // two closures, the 8h7d.5 F-1/F-3 shape, and the widening the parameterised
  // read point (§14.3) added customers to. Now both rungs ask the wire
  // (`railWireNamesBackward`); the kickback callers get the same widening
  // (`control_phase_kickback_reject_rail_measured_parent_name.ll` — an ACCEPT on
  // `main` b00fdc2, a decline now: monotone toward decline).
  SmallVector<const Value *, 4> Names;
  railWireNamesBackward(Rail, Taint, Names);
  // ── THE PER-ACTIVATION BARRIER (Track A.1) ────────────────────────────────
  //
  // `Names.back()` is where the backward walk STOPPED: the wire's ORIGIN. When
  // that origin is a SOURCE theta — a `cq_theta_*` whose arg-0 is NOT tainted —
  // its every execution lowers to a FRESH `cqrt_alloc_<W>` plus `cqrt_ry_<W>`,
  // i.e. a NEW physical register. So a measurement that is followed by a
  // re-execution of the origin on EVERY path back to the read point collapsed a
  // register this read can no longer name, and refuses nothing.
  //
  // WITHOUT THIS, AN ITERATION-LOCAL REGISTER IS AN OVER-DECLINE, and it is not
  // hypothetical: `for (…) { int q = x; cq_theta(&q,.5); if (q > 5) …;
  // acc += cq_measure(q); }` mints a FRESH `q` every trip, so the body measure
  // owns THIS trip's register and the next trip's mint reads the NEXT one. Five
  // shipped accepts have exactly that shape (`control_swap_inloop_diamond_iterlocal`,
  // `…_seq`, and the three `…_reject_inloop_{irreducible,multilatch,second_cycle}`
  // declines, which must keep declining on their OWN loop-shape grounds and not
  // on this rung). `isPotentiallyReachable` alone answers "can the read follow
  // the measure?" — TRUE around any back edge — and that is the wrong question
  // inside a loop; the right one is "can it follow it ON THE SAME REGISTER?".
  //
  // IT IS THE SAME READING RUNG (iii) ALREADY USES one rung over, and the same
  // walk: `gateIsHarmless`'s leg 2 (`WireWalk`) admits a wire gate when every
  // path from it back to the emission re-executes the seed's own definition.
  // Two rungs of one ladder, one modality (bd 8h7d.5's standing lesson).
  //
  // THE BARRIER IS THE ORIGIN AND ONLY WHEN IT IS A SOURCE THETA — Prime
  // Directive. A CHAINED theta is an IN-PLACE Ry: re-executing it re-rotates the
  // SAME register and refreshes nothing. A non-theta origin (a template result,
  // a cast, a phi, an argument) is refused too: an out-of-place template does
  // mint a fresh rail, but M-C (`ArithLowering::classifyInPlaceReassignment`)
  // can lower the very same op IN PLACE, and this predicate runs before that
  // decision is made — so "a fresh rail" is exactly the kind of assumption this
  // project's history says not to bank on. A missing barrier DECLINES.
  const Instruction *Barrier = nullptr;
  if (!Names.empty())
    if (const auto *Origin = dyn_cast<CallInst>(Names.back())) {
      const Function *OF = Origin->getCalledFunction();
      if (OF && OF->getName().starts_with("cq_theta_") &&
          Origin->arg_size() >= 1 &&
          !Taint.Tainted.count(
              const_cast<Value *>(Origin->getArgOperand(0))) &&
          Origin != ReadPoint)
        Barrier = Origin;
    }
  for (const Value *N : Names)
  for (const User *U : N->users()) {
    const auto *M = dyn_cast<CallInst>(U);
    if (!M || !Sinks.count(M))
      continue;
    // REACHABILITY, not dominance and not position (Rule-13 round-1 finding
    // F-1b-2, and F-B1-1 above): a measure on a classically-guarded SIDE PATH
    // neither is the read point's block nor dominates it, yet executes before
    // it on that path; a same-block measure AFTER the read point still precedes
    // its NEXT execution when the block sits on a cycle. "Can the read point
    // execute after this measurement on SOME path?" is the one question;
    // `isPotentiallyReachable` answers it conservatively for every placement (a
    // null tree only makes it more conservative). A measurement the read point
    // can never follow is downstream of the region and owns the register from
    // there on, exactly as for a compare.
    if (!isPotentiallyReachable(M, ReadPoint, /*ExclusionSet=*/nullptr, DT))
      continue;
    // The register is re-minted between them on every path ⇒ this measurement
    // owns a DIFFERENT register than the one the read point names. `M` and
    // `ReadPoint` in ONE straight-line activation are unaffected: the path from
    // `M` to `ReadPoint` that stays inside the block does not cross the origin,
    // so `everyPathReExecutes` is false and the rung still refuses (which is the
    // flat `int m = cq_measure(q); if (q > 3) …` case, bd r903 item (b)).
    if (Barrier && M != Barrier && everyPathReExecutes(M, ReadPoint, Barrier))
      continue;
    return true;
  }
  return false;
}

// (Track A.1, Rule-13 round-1 finding F-A1-3) THE ONE SPELLING of "which
// registers does this compare READ?" — its direct TAINTED operands. Used by
// rung (ii) at classification (`condCmpMeasuredBeforeReadPoint` below) and
// recorded by the mint (`CompareLowering.cpp`) so the backstop asks the same
// question at FINAL taint. Deliberately NOT `condProvenance`: that cone is
// every tainted ANCESTOR and is rung (iii)'s set (and R4's completeness
// carrier — see its own header, which forbids narrowing IT). A classical
// operand is skipped; both operands are collected for a Q+Q compare.
void condCmpOperandSeeds(const CmpInst *Cmp, TaintSet &Taint,
                         SmallVectorImpl<Value *> &Out) {
  if (!Cmp)
    return;
  for (const Use &U : Cmp->operands()) {
    Value *Op = U.get();
    if (Taint.Tainted.count(Op) && !is_contained(Out, Op))
      Out.push_back(Op);
  }
}

// bd test_C_libtooling-r10v / -r903(b) (Track A.1) — RUNG (ii) FOR COMPARE
// LEAVES. See `ArmAnalysis.h` for the contract.
//
// WHY THIS RUNG DID NOT EXIST, AND WHY NOTHING ELSE CATCHES IT. The compare path
// asks the measurement question in exactly one place — `condDataUseDisposition`'s
// `MeasuredEarly` — and that question is about the FLAG's own lineage (`int f =
// (q > 5)` read as data beside the branch, the ziov `atk9` shape). "Was the
// condition REGISTER measured?" is a different question with the same shape, and
// it was asked by NO rung: `int m = cq_measure(q); if (q > 3) cq_phi(.3);` mints
// `cq_template_icmp_sgt_i32_hl(%h, 3)` AFTER `cqrt_measure_i32(%h)` — a gate
// controlled on a COLLAPSED register, Rule 6's loud-reject class — at `opt` exit
// 0, verify-clean and STRICT-stage-2b clean (bd `r903` item (b)). Its one-token
// `_Bool` twin DECLINES, because the rail ladder's rung (ii) shipped with
// Increment 1b; this is the parity repair, not a new capability.
//
// ⚠ THE SEED SET IS THE COMPARE'S DIRECT TAINTED OPERANDS AND THEIR WIRES —
// NOT the `condProvenance` cone, and that narrowing is Rule-13 round-1 finding
// F-A1-3 (an OVER-DECLINE of valid circuits `main` compiles, plain C ×2). The
// cone collects EVERY tainted ancestor of the condition, so
// `int t = q + 3; int m = cq_measure(q); int a = (t == 5) ? 2 : 5;` refused on
// `q` — a register the control never reads. Measured on the oracle, `t` lowers
// OUT of place (`cq_template_add_i32_hl`) onto a FRESH rail and the flag is
// minted from THAT rail, with `q` collapsed beside it; `q`'s measurement fixes
// `t` through their entanglement, so the flag is deterministic and the emitted
// unitary is exactly what the source asks for (`free_pairing_check`: 4 rail
// mints, 1 free site, 0 violations). The class was also ASYMMETRIC, which is
// what made it a defect rather than a policy: the exact mirror
// (`int t = q + 3; int m = cq_measure(t); int a = (q == 5) ? …`) accepted on
// both binaries with the same two entangled rails and the same one measurement.
// The question this rung asks is "was the register THE CONTROL READS
// collapsed?", and the register the control reads is named by the compare's own
// operands.
//
// THE WIRE, NOT THE NAME, is still the closure (`railWireNamesBackward`): a
// measurement may name any SSA name of the same physical register — a chained
// theta's arg-0, or (round-1 item F-B1R1-1) a parent the round-2 crossing
// reaches — and an IN-PLACE relabelling (`taint.InPlaceRailOps`, the dtzb
// `q = q OP c` the loop path proves) is the same register under a new name and
// is CROSSED there. So the narrowing is of the SEED, never of the wire.
//
// MEASURED COST OF THE NARROWING, and it is the reason the four reported
// over-declines are only two: `c2` (`long long t = (long long) q;`) and `c9`
// (`if (t > 3)` with `t = q + 3`) keep DECLINING, because `clang -O1` folds the
// cast and rewrites the compare back onto `%q` itself — their stage-1 IR is
// `icmp eq i32 %1, 5` and `icmp sgt i32 %1, 0`, so the compare's DIRECT operand
// IS the measured register and the oracle emits `cqrt_measure_i32(%h)` then
// `cq_template_icmp_*_i32_hl(%h, ·)`, bd `r903` item (b) verbatim. `c1` and
// `c10` (whose compares read a genuinely separate `add`/`and` rail) accept.
// Read that as the narrowing being about the WIRE and not about the spelling.
CmpInst *condCmpMeasuredBeforeReadPoint(ArrayRef<CmpInst *> Leaves,
                                        const Instruction *ReadPoint,
                                        TaintSet &Taint,
                                        const DominatorTree *DT) {
  if (!ReadPoint)
    return nullptr;
  for (CmpInst *Leaf : Leaves) {
    SmallVector<Value *, 2> Seeds;
    condCmpOperandSeeds(Leaf, Taint, Seeds);
    for (Value *P : Seeds)
      if (railMeasuredBeforeReadPoint(P, ReadPoint, Taint, DT))
        return Leaf;
  }
  return nullptr;
}

// bd test_C_libtooling-r9e5 (1b-B.1), Rule-13 ROUND-2 finding F-B1R2-1 — see the
// header. The write half of the record; the read half is `reverifyRailCondReads`
// below.
void markRailCondRead(TaintSet &Taint, Value *Rail, Instruction *FirstRead) {
  if (!Rail || !FirstRead)
    return;
  for (const auto &E : Taint.RailCondReads)
    if (E.first == Rail && E.second == FirstRead)
      return;  // idempotent for an identical pair; a SECOND read point is kept.
  Taint.RailCondReads.emplace_back(Rail, FirstRead);
}

// bd test_C_libtooling-r9e5 (1b-B.1), Rule-13 ROUND-2 finding F-B1R2-1 — THE
// RE-VERIFICATION TRIPWIRE. A CONFIRMED silent miscompile, plain C through the
// shipped two-TU 6.5 recipe, `opt` exit 0, verify-clean, STRICT-stage-2b clean.
//
// THE DEFECT IN ONE PARAGRAPH. The §14.3 rail ladder's rungs (ii) (measured
// before the read point) and (iii) (the wire question) are asked inside
// `detectControlRegions`, i.e. with ROUND-1 taint. `repropagateControlMerges`
// then re-seeds taint from the 6.5 classical-call-arm / 4.5 data-mux `%out`
// rails, and `lowerRotations` decides chained-vs-source with FINAL taint —
// `Chained = taint.Tainted.count(arg0)` (`RotationLowering.cpp`), the ONE
// relation that makes a whole chain RAUW onto one handle. In the window between
// those two points a `cq_theta_i1(%x, θ)` whose `%x` is DERIVED from `%out` is a
// SOURCE theta to BOTH of the ladder's closures (`railWireNamesBackward` stops
// at it; `findNonDiagonalWireGate`'s F-1b-1 tainted-parent ancestry does not
// cross) and a CHAINED theta to the lowering, which puts it and its SIBLING
// `cq_theta_i1(%x, θ')` on ONE rail. The emitted control read — a `cqrt_cnot`
// copy mint, a node gate, a kickback `cqrt_rz_i1` — then fires on
// `Ry(θ')Ry(θ)|x⟩` while the SSA condition names `Ry(θ)|x⟩`. A different
// unitary, with no diagnostic anywhere.
//
// THE FIX IS A RE-VERIFICATION, NOT A PREDICTION (the bd `eqpx` (1b) tripwire
// pattern this project already ships). Predicting what round 2 will taint is the
// exact shape of the eight findings CLAUDE.md's CORRECTNESS-RISK section
// records; and the blunt alternative (treat any non-`Constant` arg-0 as chained)
// costs a CORRECT accept — the opaque-classical-seed program pinned by
// `control_swap_select_rail_round2_opaque_seed_accept.ll`, where the two thetas
// really are two registers. So every emitter that reads a rail as a control
// RECORDS `(Rail, FirstRead)` at its emission site, and this stage re-asks the
// SAME two rungs — the same two functions, not a second spelling — once the
// taint is final.
//
// POSITION: after the round-2 fixpoint (`repropagateControlMerges`, whose
// `detectAndLowerOnwardControl` is itself a full second round of control
// detection and lowering) and before `lowerRotations`, in BOTH entry points.
// This is the slot `deleteGlobalPhases` was MOVED to for the same reason (the
// round-1 lens L3 finding F-L3-1) — "a stage that runs ONCE has a round-2-FALSE
// premise" — and it is also the last point at which the record's two halves are
// still the values the ladder reasoned about: `lowerRotations` erases the
// `cq_theta_i1` calls.
//
// ⚠ WHY RE-ASKING **AFTER** THE EMISSION IS SOUND, and it is not obvious.
// `findNonDiagonalWireGate` looks for `cq_theta_`-prefixed users on the wire and
// crosses `cq_phi_`/tainted arg-0 edges; the gates this region has already
// emitted are `cqrt_*` runtime calls, which are NOT thetas and match no prefix
// the walker tests, so they are invisible to it. `railMeasuredBeforeReadPoint`
// asks `taint.MeasureCalls`, which holds `@cq_measure_*` calls only
// (`lowerMeasures` has not run). The answer this stage computes is therefore the
// answer the classifier WOULD have computed with final taint, not an answer
// perturbed by the emission — the only thing that changed is the taint set and
// the availability of a concrete read POINT.
//
// ⚠ THE POSITION-FREE WALK IS ASKED WITH `Taint`, deliberately: that crossing IS
// the point (F-1b-1's tainted-parent ancestry), and at final taint it reaches
// the sibling the round-1 ask could not see.
//
// LOUD AND FINAL — AS AN ASSUMPTION ABOUT THE HOST TOOL, NOT A PROPERTY OF THIS
// STAGE (round-3 item F-B1R3-2). `diagnoseUnderControl` is `DS_Error`; neither
// `opt` nor `cq_opt_main.cpp` installs a diagnostic handler, so the default
// `LLVMContext::diagnose` printer `exit(1)`s INSIDE the call and no module is
// ever printed — the already-emitted stream is discarded with it. That is the
// house style of every decline in the pass. It means everything below the first
// `diagnoseUnderControl` — the `Diagnosed` set, the `continue`, the `bool` — is
// DEAD under `opt` (measured: two failing rails print exactly ONE line) and is
// kept only so the stage reads correctly under a driver whose handler returns;
// under such a driver the pipeline WOULD continue over a refused region, and a
// new host must install a handler that stops. There is deliberately NO silent
// fallback and no attempt to un-emit — a region whose ladder no longer holds has
// no correct lowering to fall back TO (Rule 1, Prime Directive). One diagnostic
// per RAIL, not per recorded read: a kickback records one read per arm and they
// are emitted contiguously, so a second message would only repeat the first.
//
// ⚠ THE PLACEMENT ARGUMENT ABOVE IS NOT THE SOUNDNESS ARGUMENT (round-3 item
// F-B1R3-1). FOUR `taint.Tainted` mutations run AFTER this slot — `lowerIOSinks`,
// `lowerQramReads`, `lowerShadowMemory` (the last two RAUW a `load` onto a
// tainted value, the exact `Chained` input) and `specialize` (which also SHRINKS
// taint through `scrubForwardCone`). None re-opens the window, for reasons that
// live in OTHER files: `propagateWorklist` taints every user of a tainted value
// (bar a measure sink, an angle-only edge and — since bd cepm — the RESULT of a
// would-be Phase-6 call predicted to return a classical value; a `load` is none of
// those), so a QROM/Shadow load at a tainted index is already tainted at round 1
// (measured: the QROM sibling program declines on both binaries, and the
// sibling-free one lowers CHAINED onto `cqrt_qram_load_i1`), and a
// classical-index Shadow access declines `alloca array mixes a tainted-index and
// a classical access`; a scrub can only turn an assumed-chained theta into a
// SOURCE, i.e. split one wire into two rails — the safe direction for both
// rungs. RETIREMENT TRIGGER: if `propagate` ever stops taking the address edge
// into a `load`, or the Shadow mixed-access decline is narrowed, this stage must
// move BELOW `lowerShadowMemory` (and re-argue `specialize`'s scrub).
//
// SEEDS (round-3 item F-B1R3-3): this re-ask seeds `{Rail}`; the classifiers seed
// a `condProvenance` UNION over the tree's leaves. For a rail leaf the two
// coincide exactly (`condProvenance` stops at a theta call), so nothing is lost
// today; for a MIXED tree the COMPARE leaves' wires are asked at round 1 only —
// that is the compare half of the window, bd `test_C_libtooling-9pum`, and the
// record's extension to compare seeds is where it closes.
// bd `test_C_libtooling-fn1q` increment 1 — the hoisted value-arm cone, re-asked
// at FINAL taint. See `TaintSet::ValueArmConeOps` for the hazard this closes and
// why it is a checked property rather than an argued-empty residual.
//
// ⚠ IT GUARDS A REACHABLE HOLE. `control_swap_value_reject_arm_cone_round2_quantum.ll`
// is the shape, built by Rule-13 round 1 after the increment's own record claimed
// it could not be exhibited; the fence is backtrace-confirmed as the one that
// fires on it.
//
// ⚠ WHAT IT WITNESSES AND WHAT IT DOES NOT. It witnesses exactly one thing: that
// no instruction `emitValueRegion` hoisted as CLASSICAL is tainted once the
// round-2 fixpoint has made the taint final. It does NOT witness that the hoist
// was otherwise well-placed, that the cone was speculatable (that is (K4), asked
// twice before the mutation) or that the region's merge is correct. A dead or
// erased cone member is skipped rather than read — `lowerOps` and the spine may
// legitimately have removed one by the time this runs, and a freed pointer is
// not a finding.
bool declineRound2TaintedArmCone(Module &M, TaintSet &Taint) {
  if (Taint.ValueArmConeOps.empty())
    return false;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        if (!Taint.ValueArmConeOps.count(&I))
          continue;
        if (!Taint.Tainted.count(&I))
          continue;
        // The anchor is the cone member itself: it is the instruction whose
        // classicality the accept rested on, and it still carries the arm's
        // `!dbg`, so the diagnostic points at the user's own expression.
        diagnoseUnderControl(&I, "value arm classical operand became quantum");
        return true;
      }
  }
  return false;
}

// bd `test_C_libtooling-z0re` — see `ArmAnalysis.h` for the contract and the
// callers. A literal is F1's `ConstantInt`/`ConstantFP` clause, and a
// `ConstantExpr` / `GlobalValue` / `undef` / `poison` stays refused for the
// reasons F1's header gives each (an unreadable link-time value; the bd `xy9n`
// literal-integrity defect). What is admitted is a value computed at run time —
// an `Instruction` or an `Argument` — which `cqrt_alloc_<W>` takes as it takes
// the unconditional prep's `int q = atoi(v[1]); cq_theta(&q, θ)` seed today.
//
// ⚠ WHICH CONJUNCTS ARE FENCES AND WHICH ARE MEANING (Rule-13 r1A P3-2, r1B M4).
// Measured and argued: at EVERY current caller only the first test below
// discriminates anything.
//   * `Instruction`/`Argument` — THE scope line. It also excludes every
//     `Constant` (a `Constant` is neither), which is why the separate
//     `isa<Constant>` test the first spelling carried is GONE: it was subsumed,
//     and the old header's "the `Constant` exclusion is the whole scope line"
//     described documentation, not a fence.
//   * `!Tainted` — UNPINNABLE at every caller, and KEPT: F1 reaches here only
//     with `StatePrep` (arg-0 untainted by construction) and S3 only with
//     `UntaintedBase`, so no input separates it (r1A P3-2). It stays because it
//     IS the predicate's meaning ("a seed, not a register"); a caller that asked
//     about a tainted value and got `true` would be told a register is a seed.
//   * int-or-fp type — UNPINNABLE at every caller, and KEPT for the same
//     reason: collection-time prototype validation refuses a non-int/fp
//     `cq_theta` arg-0 and F1's clause 3 re-checks the width (r1B mutant M4
//     survives the whole suite). It is the ABI half of the meaning:
//     `cqrt_alloc_<W>` takes nothing else.
// Rule 12 can supply no fixture for the two kept conjuncts; that is recorded
// here rather than implied by a green suite.
//
// ⚠ UNTAINTED IS ASKED OF `Taint` AS HANDED IN — at DETECTION that is round-1
// (or round-2) taint, NOT final. The L1 half is not this predicate's job: see
// `declineRound2QuantumPrepSeeds` below.
bool isRuntimeStatePrepSeed(Value *V, const TaintSet &Taint) {
  if (!V || (!isa<Instruction>(V) && !isa<Argument>(V)))
    return false;  // a `Constant` / `BasicBlock` / `InlineAsm` / `MetadataAsValue`.
  if (Taint.Tainted.count(V))
    return false;  // a REGISTER: a chained (in-place) base, not a seed.
  Type *Ty = V->getType();
  return Ty->isIntegerTy() || Ty->isFloatingPointTy();
}

// bd `test_C_libtooling-z0re` — the L1 re-ask (contract in `ArmAnalysis.h`,
// hazard in `TaintSet::RuntimeSeedSourceThetas`).
//
// ⚠ THE SLOT IS THE ARGUMENT, and it is AFTER `specialize()` on purpose. The
// question this re-asks is EXACTLY `lowerRotations`' `Chained =
// taint.Tainted.count(arg0)`, so it is asked at the taint `lowerRotations` starts
// from — the CQLoweringPass comment at the d88e re-ask records that nothing
// between `specialize()` and `lowerRotations` writes `taint.Tainted`. Placed
// earlier (beside `declineRound2TaintedArmCone`, before `specialize()`) it would
// be SOUND for the same reason — a seed untainted at classification is not a
// Phase-6 site that `specialize()` could re-mark — but it would decline the
// exotic seed that round 2 taints through a spec call and `specialize()` then
// scrubs back to classical, i.e. an over-decline for no unitary.
//
// WHAT IT WITNESSES AND WHAT IT DOES NOT. It witnesses that no recorded runtime
// seed is QUANTUM at the taint `lowerRotations` reads, i.e. that every recorded
// source theta lowers as the SOURCE (`cqrt_alloc_<W>(seed)`) its classifier
// accepted. It does NOT re-ask F1's identity clause or F2 (the SSA identity of the
// seed and the Pred incoming is preserved by every RAUW, which rewrites both
// uses at once; F2's relational half is argued in its own header) and it says
// nothing about a literal seed, which cannot turn quantum and is never recorded.
//
// Anchored at the SOURCE theta, which is the hoisted user `cq_theta` (it keeps
// the arm's `!dbg`) or the angle select's true-arm controlled gate `TA` (stamped with the
// select's `!dbg`), so the diagnostic points at the user's own rotation.
bool declineRound2QuantumPrepSeeds(Module &M, TaintSet &Taint) {
  // bd dm7f.53 — THE L1 RE-ASK OF F2'S SIBLING-CONDITION EXCLUSION
  // (`siblingConditionCompareOnWire`). The record is the `kF2SiblingMD` tag the
  // F2 test put on every collider it excluded; a compare its region already
  // lowered to a flag is erased or dead and has nothing left to ask. What
  // taint growth could falsify is the STRUCTURAL half, re-asked here at the
  // FINAL taint `lowerRotations` starts from: still an `icmp` of a QUANTUM
  // register against a literal, still used only as conditional-branch
  // conditions. (`CondWire` membership was a fact about a region now flattened;
  // the forcedness half is a CFG/LVI edge fact no taint growth changes.)
  // Unreachable from C today — no shipped round-2 emitter adds a data use to a
  // live compare — so this decline has no fixture; it is F2's own string,
  // anchored at the user's compare.
  // bd dm7f.54 (item A1) — THE L1 RE-ASK of `angleSelectLiteralSeedPinned`'s
  // classical pins: a value proven equal to an admitted angle select's
  // literal seed that was classical at classification must still be
  // classical now, or the source rotated a live register the module prepares
  // fresh (the review's p7 class, one taint round later). Unreachable from C
  // today (no shipped round-2 emitter taints a value that dominates such a
  // consumer under an equality pin), so it has no fixture; F2's own string.
  for (Function &F : M)
    for (Instruction &I : instructions(F))
      if (I.getMetadata(kAngleSelSeedPinMD) && Taint.Tainted.count(&I)) {
        diagnoseUnderControl(&I, "state prep seed is proven equal to the "
                                 "condition register");
        return true;
      }
  for (Function &F : M)
    for (Instruction &I : instructions(F)) {
      if (!I.getMetadata(kF2SiblingMD) || I.use_empty())
        continue;
      auto *C = dyn_cast<ICmpInst>(&I);
      bool Ok = C && siblingConditionCompareOnWire(C, /*CondWire=*/nullptr);
      if (Ok) {
        Ok = false;
        for (unsigned K = 0; K < 2; ++K)
          if (isa<ConstantInt>(C->getOperand(1 - K)) &&
              Taint.Tainted.count(C->getOperand(K)))
            Ok = true;
      }
      if (!Ok) {
        diagnoseUnderControl(&I, "state prep seed is proven equal to the "
                                 "condition register");
        return true;
      }
    }
  for (const WeakTrackingVH &H : Taint.RuntimeSeedSourceThetas) {
    auto *T = dyn_cast_or_null<CallInst>(static_cast<Value *>(H));
    // A nulled or re-typed entry names no theta any more: nothing will lower
    // `Chained` from it, so there is no unitary left to refuse.
    if (!T || !isThetaCall(T) || T->arg_size() < 1)
      continue;
    if (!Taint.Tainted.count(T->getArgOperand(0)))
      continue;
    diagnoseUnderControl(T, "state prep seed became quantum");
    return true;
  }
  return false;
}

bool reverifyRailCondReads(Module &M, TaintSet &Taint) {
  if (Taint.RailCondReads.empty())
    return false;  // no rail was ever read as a control — every module until 1b.
  // `M` is unused: the record is already module-wide (every emitter writes into
  // the one `TaintSet`), and each entry names its own function. It is kept in
  // the signature so the stage reads like its neighbours at both call sites, and
  // it is `(void)`-d rather than left to warn.
  (void)M;
  DenseMap<Function *, std::unique_ptr<DominatorTree>> Trees;
  SmallPtrSet<const Value *, 4> Diagnosed;
  bool Declined = false;
  for (const auto &E : Taint.RailCondReads) {
    // A NULLED handle is SKIPPED, and the direction is the argument: a read that
    // no longer exists is not a live control read, so there is no wrong unitary
    // left to refuse (and a rail whose def was erased has no wire to ask about).
    //
    // ⚠ THE `dyn_cast_or_null` COLLAPSES **THREE** CASES INTO ONE `continue`,
    // AND ONLY TWO OF THEM ARE COVERED BY THE SENTENCE ABOVE — Rule-13 round-1
    // finding F-P1-5. The third is a LIVE value of the wrong TYPE, which since
    // bd `3qps`/`4aiu` (Track P) has a real population: a region-merge `PHINode`
    // recorded by `emitCondNode`/`emitKickbackGroup` when the flat kickback is
    // emitted BEFORE its prep. For such an entry rungs (ii) and (iii) are not
    // re-asked AT ALL and nothing is printed — an INERT skip, not a conservative
    // one. It is unreachable today only because the prep's M-β RAUWs that φ to
    // the hoisted `cq_theta_i1` call before this stage runs and the record's
    // `WeakTrackingVH` follows the RAUW. THE FULL THREE-CASE STATEMENT AND THE
    // RETIREMENT TRIGGER LIVE WITH THE RECORD, in `TaintPropagation.h`'s
    // `RailCondReads` block — read it before widening either half; the day the
    // M-β premise can fail, this `continue` is a silent hole and must become a
    // loud decline.
    //
    // (Track A.1) UNCHANGED — the compare seeds live in their own record
    // (`CmpCondReads`) and are re-verified by `reverifyCmpCondReads` below,
    // because their rung (iii) must be asked over the whole cone AT ONCE. This
    // loop stays the rail ladder's, byte for byte.
    // bd dm7f.77 — A FOURTH CASE: a LIVE REGISTER CONDITION (RegCondLeaf.h), a
    // QQ xor read as its own register. It is NOT RAUW'd before this slot (it is
    // lowered by `lowerOps`, which runs later), so the case-(3) argument above
    // does not cover it: it is re-asked here, both rungs, over BOTH names of its
    // wire (the value and its in-place target) and with `regCondProvenance` as
    // rung (iii)'s seed set — the classifier's exact sets, at final taint.
    auto *RegI = dyn_cast_or_null<Instruction>(E.first);
    const bool Reg = isRegCondLeaf(RegI);
    auto *Rail = dyn_cast_or_null<CallInst>(E.first);
    auto *Read = dyn_cast_or_null<Instruction>(E.second);
    if ((!Rail && !Reg) || !Read || !Read->getFunction() ||
        Read->getFunction() != RegI->getFunction())
      continue;
    if (Diagnosed.count(RegI))
      continue;
    Function *F = Read->getFunction();
    auto &Slot = Trees[F];
    if (!Slot)
      Slot = std::make_unique<DominatorTree>(*F);
    DominatorTree *DT = Slot.get();
    if (Reg) {
      Value *Target = regCondTarget(RegI);  // null: a fresh rail.
      bool Measured = false;
      for (Value *Name : {static_cast<Value *>(RegI), Target})
        if (Name && railMeasuredBeforeReadPoint(Name, Read, Taint, DT))
          Measured = true;
      if (Measured) {
        diagnoseUnderControl(Read, "condition measured before the control route");
        Diagnosed.insert(RegI);
        Declined = true;
        continue;
      }
      SmallPtrSet<Value *, 8> Prov;
      regCondProvenance(RegI, Taint, Prov);
      SmallVector<Value *, 4> Seeds(Prov.begin(), Prov.end());
      if (findNonDiagonalWireGate(Seeds, /*CrossValueRouting=*/true,
                                  /*EmitPoint=*/nullptr, /*DT=*/nullptr, &Taint) &&
          findNonDiagonalWireGate(Seeds, /*CrossValueRouting=*/true,
                                  /*EmitPoint=*/Read, DT, &Taint)) {
        diagnoseUnderControl(Read, "condition predates a non-diagonal gate");
        Diagnosed.insert(RegI);
        Declined = true;
      }
      continue;
    }
    // RUNG (ii) — the register must not be MEASURED before this read point. The
    // ONE spelling (Rule 14), asked over the rail's WIRE (`railWireNamesBackward`,
    // round-1 item F-B1R1-1), which at FINAL taint crosses to the `%out`-derived
    // parent the round-1 ask stopped at.
    if (railMeasuredBeforeReadPoint(Rail, Read, Taint, DT)) {
      diagnoseUnderControl(Read, "condition measured before the control route");
      Diagnosed.insert(Rail);
      Declined = true;
      continue;
    }
    // RUNG (iii) — the WIRE question, both prongs, exactly as
    // `railCondWireDisposition` asks them at classification time: position-free
    // CLEAN ⇒ nothing to prove; otherwise the gate must be PROVABLY after every
    // execution of the read point (`EmitPoint = Read`), else decline. The DT is
    // non-null by construction here, so the classifier's "no tree, no proof"
    // decline has no counterpart.
    SmallVector<Value *, 1> Seeds{Rail};
    if (findNonDiagonalWireGate(Seeds, /*CrossValueRouting=*/true,
                                /*EmitPoint=*/nullptr, /*DT=*/nullptr, &Taint) &&
        findNonDiagonalWireGate(Seeds, /*CrossValueRouting=*/true,
                                /*EmitPoint=*/Read, DT, &Taint)) {
      diagnoseUnderControl(Read, "condition predates a non-diagonal gate");
      Diagnosed.insert(Rail);
      Declined = true;
    }
  }
  return Declined;
}

// (Track A.1) THE COMPARE HALF — bd test_C_libtooling-9pum, and it is the SAME
// window one leaf species over. Round-3 item F-B1R3-3 named it in advance:
// "for a MIXED tree the COMPARE leaves' wires are asked at round 1 only — that
// is the compare half of the window, bd `test_C_libtooling-9pum`, and the
// record's extension to compare seeds is where it closes." This is that
// extension.
//
// THE DEFECT, MEASURED (two TUs of plain C through the shipped 6.5 recipe):
//   int q = 3; cq_theta(&q,.5); int y = 5; if (q > 5) y = ext_f(7);
//   int b = y; cq_theta(&b,.25); int b3 = y; cq_theta(&b3,.9);
//   int a = (b == 1) ? 2 : 5;  return cq_measure(a) + cq_measure(b3);
// `y` is a 6.5 classical-call-arm `%out` derivative: CLASSICAL at round 1, so
// `b` and `b3` are two SOURCE thetas — two rails — to gate 2c's walk, and
// TAINTED after `repropagateControlMerges`, so `lowerRotations`
// (`Chained = taint.Tainted.count(arg0)`) puts them on ONE rail. The emitted
// stream is `ry(h2,.25); ry(h2,.9); icmp_eq(h2,1)` — the flag minted from
// `Ry(.9)Ry(.25)|y⟩` while the source compares `Ry(.25)|y⟩`. `opt` exit 0,
// verify-clean, STRICT-stage-2b clean, no diagnostic anywhere.
//
// WHY THE RAIL FIX DID NOT COVER IT: `reverifyRailCondReads` reads a record
// written only where a `_Bool` REGISTER is read as a control. Here the control
// read is a compare MINT, which recorded nothing until this increment.
//
// EVERYTHING IN `reverifyRailCondReads`' header applies verbatim and is not
// repeated: the placement argument, why re-asking AFTER emission is sound (the
// emitted gates are `cqrt_*`, which match no prefix the walker tests, and
// `taint.MeasureCalls` still holds `@cq_measure_*` calls because `lowerMeasures`
// has not run), the four post-slot taint mutations and their retirement trigger,
// and the `DS_Error`-exits-inside-diagnose reading of "loud and final".
//
// ONE THING IS THIS FUNCTION'S OWN, and it is why the two records are separate:
// rung (iii) is asked over the WHOLE recorded cone in one call. `gateIsHarmless`
// grows its barrier set from the seed set it is handed, so asking N singleton
// calls is strictly stricter than one N-seed call — measured as fourteen shipped
// in-loop accepts turning into declines. One entry, one cone, one call.
//
// ⚠ SAY WHERE THE TWO LADDERS DIVERGE, because "the compare half" reads like
// parity and is not (Rule-13 round-1 item F-A1-5(c)). THIS STAGE IS STRICTLY
// WEAKER THAN `reverifyRailCondReads` AT RUNG (iii). The rail twin asks both
// prongs UNCONDITIONALLY — position-free, then position-aware — about every gate
// on the wire. This one asks only about gates NOT in the taint-blind set — i.e.
// only about the round-2 crossing — AND ONLY FOR AN ENTRY WHOSE MINT RECORDS A
// ROUND-1 WIRE DISPOSITION (`CmpCondRead::WireRuled`, round-2 finding
// F-A1R2-1); for an `Unruled` entry it is the rail twin's unconditional re-ask.
// The narrowing exists because for the ruled compare consumers the round-1
// ruling can be an ACCEPT (`condWireDisposition`'s DT prong) that this stage
// cannot re-derive once `RegionFlatten` and `collapseFlattenedLoopRails` have
// erased the positions and the barrier phi it used — an argument that has no
// subject where no classifier ruled at all. The asymmetry is deliberate
// and measured (asking about everything costs twelve shipped in-loop accepts),
// but it is an asymmetry: a gate the CLASSIFIER accepted and the round-2 merge
// then moved is this stage's residual, and closing it needs the classifier's own
// disposition recorded per compare (IMPL_A1.md §7 O-3). Do not read the two
// functions as one ladder in two spellings; they answer different questions at
// rung (iii), and rung (ii) — which IS identical in both — is what makes this a
// real backstop.
//
// ⚠ RUNG (ii) IS ALSO NARROWER BY ONE DELIBERATE STEP: it asks about the
// compare's DIRECT tainted operands (`OperandSeeds`), never the whole cone
// (F-A1-3). The rail twin has no such distinction because a rail leaf's cone IS
// the singleton rail.
bool reverifyCmpCondReads(Module &M, TaintSet &Taint) {
  if (Taint.CmpCondReads.empty())
    return false;
  (void)M;  // module-wide record; each entry names its own function.
  DenseMap<Function *, std::unique_ptr<DominatorTree>> Trees;
  SmallPtrSet<const Value *, 4> Diagnosed;
  bool Declined = false;
  for (const auto &E : Taint.CmpCondReads) {
    auto *Read = dyn_cast_or_null<Instruction>(E.Read);
    if (!Read || !Read->getFunction())
      continue;  // the mint was erased — no live control read, nothing to refuse.
    if (Diagnosed.count(Read))
      continue;
    Function *F = Read->getFunction();
    // A NULLED seed is DROPPED, not fatal: `WeakTrackingVH` nulls what later
    // stages erase, and a cone member that no longer exists cannot carry a wire.
    // A seed from ANOTHER function is drift and is dropped for the same reason
    // the rail stage drops it — never guessed at.
    auto live = [&](ArrayRef<WeakTrackingVH> In, SmallVectorImpl<Value *> &Out) {
      for (const auto &S : In) {
        Value *V = S;
        if (!V)
          continue;
        if (auto *I = dyn_cast<Instruction>(V)) {
          if (I->getFunction() != F)
            continue;
        } else if (auto *A = dyn_cast<Argument>(V)) {
          if (A->getParent() != F)
            continue;
        } else {
          continue;  // a Constant cannot be tainted; anything else is drift.
        }
        Out.push_back(V);
      }
    };
    SmallVector<Value *, 16> Seeds;
    SmallVector<Value *, 2> OperandSeeds;
    live(E.Seeds, Seeds);
    live(E.OperandSeeds, OperandSeeds);
    // ⚠ THE ONE PLACE THIS STAGE FAILS TOWARD ACCEPT, said out loud rather than
    // left to be discovered (Rule-13 round-1 item F-A1-5(a)). Everywhere else it
    // fails toward a decline: `recordCondRead` defaults TRUE so a new emitter is
    // recorded by construction, and a missing per-activation barrier refuses.
    // Here an entry whose WHOLE seed set was erased or re-homed is SKIPPED, with
    // no rung (ii) and no rung (iii). The argument that this is safe is about
    // what erases a seed: `WeakTrackingVH` FOLLOWS a RAUW (the common case — a
    // cone member RAUW'd to a 6.5/4.5 `%out` by `SelectMergeEmit` — keeps its
    // entry and is re-asked on the NEW value), so a null here means the value was
    // ERASED outright, and an erased value carries no wire, has no `cq_measure`
    // user and can gain no gate. With EVERY seed gone there is no register left
    // to ask a question about, and the `Read` that remains is a flag mint whose
    // operands are constants. The retirement trigger is a stage that erases a
    // LIVE cone member without RAUW-ing it — then this `continue` would be
    // skipping a real obligation and must become a decline.
    //
    // The same reading covers an EMPTY `OperandSeeds` with a non-empty cone
    // (rung (ii) is then skipped and rung (iii) still asked): structurally that
    // needs a compare with a tainted ANCESTOR and no tainted OPERAND, which
    // cannot mint a quantum flag in the first place, so it should be
    // unreachable — but it is the same accept-direction branch and it is named
    // here rather than left to be found (round-2 question Q-4).
    if (Seeds.empty())
      continue;
    auto &Slot = Trees[F];
    if (!Slot)
      Slot = std::make_unique<DominatorTree>(*F);
    DominatorTree *DT = Slot.get();
    // RUNG (ii) — per DIRECT OPERAND (F-A1-3: the registers the control READS,
    // never the whole cone), over that operand's own wire closure (the measure
    // may name any SSA name of the register — round-1 item F-B1R1-1).
    bool Measured = false;
    for (Value *S : OperandSeeds)
      if (railMeasuredBeforeReadPoint(S, Read, Taint, DT)) {
        Measured = true;
        break;
      }
    if (Measured) {
      diagnoseUnderControl(Read, "condition measured before the control route");
      Diagnosed.insert(Read);
      Declined = true;
      continue;
    }
    // ── RUNG (iii) — THE ROUND-2 CROSSING, AND ONLY IT, AS A SET DIFFERENCE ──
    //
    // The gate to refuse is one the classifier COULD NOT HAVE SEEN, and the walk
    // itself says which those are. `findNonDiagonalWireGate` consults the taint
    // set in EXACTLY ONE place: the F-1b-1 ancestry crossing, which follows a
    // chained theta's arg-0 edge when that arg-0 is TAINTED — the same relation
    // `lowerRotations` builds a rail from (`Chained = taint.Tainted.count(arg0)`).
    // Its FORWARD half tests no taint at all. So the wire is walked TWICE:
    //   * TAINT-BLIND (`Taint=nullptr`) — every gate reachable without any
    //     taint-dependent crossing, ENUMERATED, and exempted as EVIDENCE only
    //     when this entry records that a classifier actually TOOK a wire
    //     disposition over this compare (`E.WireRuled`; see below and
    //     `TaintPropagation.h`). Where one did, `condWireDisposition` could
    //     still DT-prove such a gate post-region — it ran BEFORE `RegionFlatten`
    //     and before the round-2 `collapseFlattenedLoopRails` erased the
    //     loop-header rail phi that proof's barrier needs — so RESPECT THAT
    //     ANSWER, gate by gate: re-deriving it here is not possible, and asking
    //     about ALL of them anyway turns twelve shipped in-loop accepts into
    //     declines (MEASURED, `control_swap_inloop_post_region_theta.ll` and
    //     eleven siblings, every one an `ArmClassify` consumer).
    //   * TAINT-AWARE (`&Taint`, FINAL) with the blind set as `Covered` — what
    //     is left is reachable ONLY through the crossing, i.e. only because of a
    //     rail merge the classifier did not know about. That IS bd `9pum`:
    //     `b = y; cq_theta(&b,.25)` and `b3 = y; cq_theta(&b3,.9)` with `y` a 6.5 `%out`
    //     derivative — two rails to the classifier, ONE to `lowerRotations`, and
    //     `b3` reachable from `b` only by crossing `y`.
    //
    // ⚠ A SET DIFFERENCE, NEVER A BOOLEAN — Rule-13 round-1 finding F-A1-1, a
    // CONFIRMED silent miscompile and this stage's first spelling. That spelling
    // asked `findNonDiagonalWireGate(…, Taint=nullptr)` as a YES/NO and skipped
    // the entry when it said yes. But the walker returns ONE gate, so "SOME gate
    // is visible taint-blind" was standing in for "THIS gate is visible
    // taint-blind" — two different propositions — and one extra line of plain C
    // (`int b2 = b; cq_theta(&b2, -0.25);`, the shipped S† shape, which
    // `condWireDisposition`'s DT prong legitimately ACCEPTS as post-region)
    // suppressed the whole re-ask about the sibling `b3` that only round-2 taint
    // reveals. bd `9pum` returned verbatim, at `opt` exit 0, verify-clean and
    // STRICT-stage-2b clean, with the emitted stream byte-identical to the
    // pre-increment binary's; the discriminator `k9` (the same extra line on
    // ANOTHER register) still declined, i.e. the fence was defeated by making
    // the condition wire DIRTIER, which is the inverse of a safety property.
    // "The classifier ruled on it" is also not "the classifier declined it":
    // for the select/nest/switch, round-1 rung (iii) is position-free, so a
    // taint-blind-dirty wire had already declined and the suppression was
    // harmless — but `condWireDisposition` (the flat kickback, the value arm,
    // the 6.5 classical-call arm, the in-place-Ry arm) has a DT prong whose
    // answer can be ACCEPT, so the suppression discarded an obligation nobody
    // discharged. The exemption is now of the NAMED gates and of nothing else.
    //
    // The position-aware prong is then asked as a second chance about exactly
    // those remaining gates, as `condWireDisposition` asks it: a crossing-only
    // gate PROVEN after every execution of the read point invalidates nothing
    // (that is the sibling-AFTER-the-select accept the increment must keep).
    //
    // ⚠ THE RESIDUAL, NARROWED BUT NOT EMPTY: a gate that was already reachable
    // taint-blind at round 1, AT A MINT WHOSE CLASSIFIER RULED ON IT, and whose
    // WIRE the round-2 merge then changed, is exempted by identity here — what
    // this stage cannot do is re-derive the ruling after the flatten. What the
    // set difference buys is that the exemption no longer spreads from one gate
    // to every other gate on the same wire. Closing the rest needs the
    // classifier's own disposition recorded per compare (IMPL_A1.md §7 O-3).
    //
    // ⚠⚠ WHAT THE EXEMPTION MEANS, EXACTLY — and the earlier sentence here was
    // wrong TWICE (Rule-13 round-2 finding F-A1R2-4; the first half is finding
    // F-A1R2-1, a CONFIRMED silent miscompile ×2 from plain C). It read: "the
    // F-1b-1 crossing only ADDS values to the backward closure, so
    // `blind ⊆ round-1 ⊆ final` — exempting the blind set exempts no more than
    // the classifier actually saw". It does not hold as written:
    //
    //   (a) IT PRESUMES A CLASSIFIER WALK. For the 7.6 controlled I/O sink, the
    //       7.5 guarded Shadow store, the 6.5 classical-call arm and the 7.2
    //       abort park, NO classifier wire walk runs at all — `round-1` is the
    //       EMPTY SET while `blind` is not, so the containment is the wrong way
    //       round and the exemption exempted gates nobody had ruled on. That is
    //       not hypothetical: `io3.c` and `gs1.c` (review_a1_r2_probes) minted a
    //       controlled tape write / Shadow store from a register a sibling
    //       in-place Ry had relabelled, at `opt` exit 0. THE REPAIR IS THE
    //       PER-ENTRY BIT `E.WireRuled` below, supplied by the mint site.
    //   (b) `Covered` IS A SUPERSET OF WHAT THE ROUND-1 WALK EXAMINED, not a
    //       subset, because the two walks are built by different rules: in
    //       return-first mode `walkNonDiagonalWireGates` never PUSHES a staling
    //       gate — it returns it, or `continue`s without pushing when
    //       `gateIsHarmless` proves it harmless — while the ENUMERATING mode
    //       pushes it forward. So a gate `B` reachable only BEHIND a gate `A`
    //       that round 1 proved harmless was never examined at round 1 and is
    //       still in `Covered`. That extra membership is safe, by a derivation
    //       the code did not have and now does: with `A` harmless and
    //       `B->getArgOperand(0) == A`, (i) `DT.dominates(EmitPoint, A)` and `A`
    //       dominates `B` give `DT.dominates(EmitPoint, B)`; (ii) every path
    //       `B ⇝ EmitPoint` extends a path `A → B ⇝ EmitPoint`, so leg 1's
    //       `!isPotentiallyReachable(A, EmitPoint)` gives the same for `B`;
    //       (iii) leg 2 is the only seed-dependent leg, and reaching `B` from
    //       `A` across its barrier needs the wire to cross a back edge — a value
    //       crossing a back edge arrives as a PHI, which `CrossValueRouting`
    //       pushes in EVERY mode, round 1 included, so `B` is not behind-only.
    //
    // And the reason the measured cost of the exemption's OTHER direction is
    // zero is CONSTRUCTION, not luck (round-2 Q-2): `Seeds` is the
    // `condProvenance` CONE — every tainted ancestor — so a value the F-1b-1
    // crossing would reach BACKWARD is already its own seed in the blind walk,
    // and the blind forward walk from it finds the same gates; `round1 \ blind`
    // is near-empty. The crossing adds gates only when the ancestor was not
    // tainted at round 1, and then the blind walk cannot see them either.
    //
    // SO, PRECISELY: `Covered` is "a gate visible TAINT-BLIND at a mint whose
    // round-1 wire disposition was actually TAKEN by `ArmClassify` (through
    // `condWireDisposition` / `railCondWireDisposition`) or by `SelectClassify`'s
    // gate 2c". An `Unruled` entry exempts NOTHING and gets the full re-ask,
    // which is the correct question there.
    //
    // ⚠ WHAT THAT COSTS, MEASURED — and it is ONE MORE than the review predicted,
    // so do not repeat the prediction. The review's ground for the narrowing was
    // that it "cannot cost the twelve in-loop accepts, all of which are
    // `ArmClassify` consumers". ELEVEN of the twelve are, and are unmoved;
    // the twelfth, `lowering_live_record_tape_ctrl_observed_accept.ll`, is a 7.6
    // I/O-SINK consumer — i.e. one of the two this finding is about — and it
    // moves ACCEPT → DECLINE. Its circuit was FAITHFUL (the flag is minted from
    // an out-of-place `mul` rail written BEFORE the gate), so that decline is an
    // over-decline of that program; it is taken anyway because it is PARITY —
    // the same program at the flat kickback declines on `main` with the same
    // string (measured) — and because the alternative is to give the fence-less
    // consumers a NARROWER question than every classifier asks. The file is
    // `git mv`'d to `lowering_reject_live_record_tape_ctrl_cond_staler.ll`,
    // whose header carries the whole argument, the twin measurement, and the
    // open question (FIX_A1_R2.md Q-1: should rung (iii) seed from the CONE or
    // from the compare's DIRECT OPERAND wires, at every consumer?).
    SmallPtrSet<const CallInst *, 8> Covered;
    if (E.WireRuled) {
      SmallVector<CallInst *, 8> BlindGates;
      collectNonDiagonalWireGates(Seeds, /*CrossValueRouting=*/true,
                                  /*EmitPoint=*/nullptr, /*DT=*/nullptr,
                                  /*Taint=*/nullptr, BlindGates);
      Covered.insert(BlindGates.begin(), BlindGates.end());
    }
    if (!findNonDiagonalWireGate(Seeds, /*CrossValueRouting=*/true,
                                 /*EmitPoint=*/nullptr, /*DT=*/nullptr, &Taint,
                                 &Covered))
      continue;  // WireRuled: every gate at FINAL taint was already the
                 // classifier's. Unruled (`Covered` empty): there is no gate on
                 // the wire at all.
    if (findNonDiagonalWireGate(Seeds, /*CrossValueRouting=*/true,
                                /*EmitPoint=*/Read, DT, &Taint, &Covered)) {
      diagnoseUnderControl(Read, "condition predates a non-diagonal gate");
      Diagnosed.insert(Read);
      Declined = true;
    }
  }
  return Declined;
}

// (Track A.1) The write half of the compare record — see `ArmAnalysis.h`.
void markCmpCondRead(TaintSet &Taint, ArrayRef<Value *> Seeds,
                     ArrayRef<Value *> OperandSeeds, Instruction *Read,
                     bool WireRuled) {
  if (!Read || Seeds.empty())
    return;
  for (const auto &E : Taint.CmpCondReads)
    if (E.Read == Read)
      return;  // idempotent: one cone per mint.
  TaintSet::CmpCondRead Rec;
  for (Value *S : Seeds)
    Rec.Seeds.emplace_back(S);
  for (Value *S : OperandSeeds)
    Rec.OperandSeeds.emplace_back(S);
  Rec.Read = Read;
  Rec.WireRuled = WireRuled;
  Taint.CmpCondReads.push_back(std::move(Rec));
}

// ziov WI-1: disposition of the condition compare's NON-branch (data) uses. The
// condition `q>5` IS the control flag; when it is ALSO read as data (`int f =
// (q>5)`), the control stream ("the route" below, its pre-3qlq name) and the
// data use must share ONE physical flag (minted once, fed to both) — NOT a
// second mint. Sharing is sound iff the flag's eager strip+free can be SKIPPED,
// which holds exactly when the data lineage is owned downstream — it ESCAPES
// (`ret`) or is MEASURED — AND the flag is still COHERENT when the stream uses
// it as control.
//
// `RouteBlock` is the block the control stream is emitted into (`Region.Pred`,
// just before the branch). TWO hazards close the accept set (BOTH verify-clean
// silent miscompiles caught by the WI-1 Rule-13 adversarial review, 2026-06-15):
//   * MeasuredEarly — a measurement of the flag's lineage IN `RouteBlock` runs
//     BEFORE the stream (every pre-existing `RouteBlock` instruction precedes
//     it, since it is inserted at the branch). The stream would then be
//     controlled by an ALREADY-COLLAPSED flag, silently destroying the coherent
//     `if(q>5)` control (atk9: `bool f = cq_measure(q>5)` beside `if(q>5)`,
//     reachable from clang -O1). A measure DOWNSTREAM of the route (the merge
//     block or later) is fine — it owns the handle after the control use.
//   * Unowned — a lineage DEAD WITHIN THE FUNCTION (orphaned, no users) or
//     reaching an unrecognized hole (store / opaque call / `cq_invert` / phi /
//     select) leaves the flag a dirty entangled rail with no downstream owner
//     (Rule 6/8) — DECLINE PERMANENTLY. (ziov.2 proposed lifting this with a
//     deferred flag-strip; reviewed 2026-06-15 and CLOSED won't-fix — a
//     flag-ONLY strip is a verify-clean silent miscompile, since each data op
//     mints a FRESH rail [`cq_template_*` → `cqrt_alloc_handle`] holding a COPY
//     of `q>5` entangled with q, a which-region record the flag-strip never
//     touches that DEPHASES the arm's phase [SCOPING §3a is coherent only when
//     the flag is the SOLE ancilla]; and the shape is unreachable from -O1.) There
//     is NO `main`-name short-circuit — a dead lineage in `main` is the SAME
//     dirty-flag hazard as in any function and declines identically (FreePoint's
//     `main` rule governs the FREE question, never this strip/coherence one).
//
// Pure forward SSA walk (Rule 9 — before any mutation). `cq_invert_*` is NOT in
// the accept set: it is an un-laundered escape whose param width may mismatch the
// i32 flag (a contrived Broken-module hazard, WI-1 review finding D); declining it
// is safe and consistent with the pre-ziov decline. De-anonymized into the named
// `cq` namespace (declared in `ArmAnalysis.h`) so `RegionTreeDetect` (ziov.3)
// reuses the one predicate for the nested-path decline (Rule 14).
bool comparePredLowerable(const CmpInst *Cmp) {
  // NO SELF-OPERAND / ALIASED-OPERAND FENCE HERE, DELIBERATELY (bd big5,
  // 2026-07-31 — the revert of bd 7q3s / dd2c103). DO NOT RE-ADD ONE.
  // A condition compare whose operands resolve to one rail is CASE A: aliased
  // INPUTS of an OUT-OF-PLACE gate whose output is a FRESH flag rail, i.e. a
  // UNARY function of the shared operand, which every backend can realize and
  // which is usually degenerate and free. The retracted premise ("an ill-formed
  // physical gate no backend can realize") is refuted in full at the
  // `collectCondTree` leaf slot in SelectClassify.cpp; see also bd memory
  // [aliased-rail-gate-is-realizable-2026-07-31]. The shape a fence SHOULD
  // target is CASE B — an input aliasing a rail the gate WRITES — which this
  // mint can never be: the forward path is an unconditional
  // `CreateCall(Callee, {Lhs, Rhs}, "h_cmp")` (CompareLowering.cpp:262), so the
  // returned flag rail is a NEW value whatever the operands are. (State that as
  // a property of the MINT, not of flags in general: `rewriteCompare`
  // :414-417 can later RAUW a redundant data-position compare onto an
  // already-minted control flag via `taint.SharedCondFlags` — that makes a flag
  // and a user SSA name one Value, but never merges the flag rail with a DATA
  // rail, so it is not Case B either.)
  //
  // THE CALL-SITE LIST of this predicate, re-measured by grep at bd p3kd.7.1
  // (an earlier list named eight and missed five; the same change removed the
  // SpecializeReject `isLiftableFpSelect` call, whose compare the clone scan's
  // data-op whitelist already gates): THIRTEEN calls in thirteen functions:
  //   ArmClassify.cpp        condDataUseDisposition · classifyArms ·
  //                          classifyPhaseKickback · classifyPhaseKickbackNest ·
  //                          classifyClassicalCallArm · classifyAngleSelect
  //   SelectClassify.cpp     classifySelectRegion
  //   GuardedStoreArmEmit.cpp classifyGuardedStoreArm
  //   RegionTreeDetect.cpp   recoverRegionTree
  //   AbortParkEmit.cpp      classifyAbortPark
  //   AngleSelectEmit.cpp    emitPhaseAngleSelect · emitAngleSelectRegion
  //   SwapRouteEmit.cpp      emitValueRegion
  // `classifySelectRegion` matters most: it calls this per collected leaf right
  // after `collectCondTree`, so the 4.4 SELECT route was covered by TWO of the
  // three reverted fences, not one — the two removals are not independent, and
  // any blast-radius model that treats them as independent is wrong.
  //
  // Predicate axis of `compareInScope`; icmp vs fcmp family from the instruction
  // (their predicate-name strings overlap — `ugt`/`uge`/`ult`/`ule`). Width is
  // gated elsewhere (`abiWidthFromType`); this is the predicate-only check (jvun).
  return compareInScope(Cmp->isFPPredicate() ? "fcmp" : "icmp",
                        CmpInst::getPredicateName(Cmp->getPredicate()));
}

CondDataDisp condDataUseDisposition(Instruction *Cond,
                                    const BasicBlock *RouteBlock,
                                    const TaintSet &Taint) {
  if (!RouteBlock)
    return CondDataDisp::Unowned;  // no route anchor — cannot prove ordering.
  // The measurement allowlist is EXACT-MEMBERSHIP against `Taint.MeasureCalls`
  // (the recognized `@cq_measure_<sfx>` call sites), NOT a `starts_with(
  // "cq_measure_") || starts_with("cqrt_measure_")` prefix match — mirrors the G10
  // (SwitchClassify.cpp) / SelectClassify allowlists and `proveSwitchDataMux`.
  // Prefix-on-accept is spoofable: an opaque `cq_measure_evil` would confer false
  // ownership of a live flag lineage. For the `cq_measure_` family the check is
  // EQUIVALENT on reachable inputs (the lineage walked here is ALWAYS tainted, so
  // `declineTaintEscapes` (L64, pre-detection) has already rejected any unknown-
  // callee `cq_measure_evil` before this runs — the masking coincidence). It is
  // STRICTLY STRICTER on the dropped `cqrt_measure_` arm: a `cqrt_`-named callee is
  // whitelisted by `declineTaintEscapes` (not pre-masked), so a HAND-AUTHORED
  // `@cqrt_measure_<W>` on the lineage reaches here and now DECLINES (Unowned)
  // where the old prefix accepted (ShareOk) — the SAFE over-decline direction; the
  // frontend never emits `cqrt_measure_` pre-detection, so no legitimate input is
  // affected (control_swap_reject_cond_datause_cqrt_measure_spoof.ll). Defense-in-
  // depth + consistency (Rule 14, not re-derive the masking coincidence).
  SmallPtrSet<const CallInst *, 8> Sinks(Taint.MeasureCalls.begin(),
                                         Taint.MeasureCalls.end());
  SmallVector<Instruction *, 8> Work;
  SmallPtrSet<Instruction *, 16> Seen;
  for (User *U : Cond->users())
    if (!isa<BranchInst>(U))
      if (auto *I = dyn_cast<Instruction>(U))
        Work.push_back(I);
  while (!Work.empty()) {
    Instruction *I = Work.pop_back_val();
    if (!Seen.insert(I).second)
      continue;
    if (isa<ReturnInst>(I))
      continue;  // escape — a terminator, never in RouteBlock, always after the
                 // route; the caller owns the handle.
    if (auto *CI = dyn_cast<CallInst>(I)) {
      if (Sinks.count(CI)) {
        if (CI->getParent() == RouteBlock)
          return CondDataDisp::MeasuredEarly;  // collapses the flag pre-route.
        continue;  // measured downstream of the route — the measurement owns it.
      }
    }
    // A data CAST carries the lineage onward COHERENTLY only if it is actually
    // LOWERABLE. An unsupported source/dest width (`sext i1→i128`) or an
    // out-of-scope pair has NO template, so `lowerOps`/`rewriteCast` would
    // diagnose it — but only AFTER the region was emitted + `flattenRegion` erased
    // the diamond (mutate-then-decline; violates Rule 9 detect-before-mutate,
    // ziov.4). Mirror `rewriteCast`'s lowerability gate with the SAME pure
    // predicates (`abiWidthFromType` + `castInScope`; NO module-mutating template
    // mint, so detection stays read-only) and decline PRE-mutation. Widths read
    // live here are the TRUE types — detection runs before rotation lowering's
    // RAUW-to-i32-handle, unlike `rewriteCast` which needs captured widths.
    if (auto *Cast = dyn_cast<CastInst>(I)) {
      StringRef From = abiWidthFromType(Cast->getSrcTy());
      StringRef To = abiWidthFromType(Cast->getDestTy());
      if (From.empty() || To.empty() ||
          !castInScope(Cast->getOpcodeName(), From, To))
        return CondDataDisp::Unlowerable;
      if (Cast->use_empty())
        return CondDataDisp::Unowned;  // dead-within-function lineage.
      for (User *U : Cast->users())
        if (auto *UI = dyn_cast<Instruction>(U))
          Work.push_back(UI);
      continue;
    }
    // A data COMPARE carries the lineage onward only if its predicate is
    // LOWERABLE: an out-of-scope fcmp predicate (after 8rvn, only the degenerate
    // `true`/`false`) has no template, so `lowerOps`/`rewriteCompare` would mint a
    // non-existent symbol (it does NOT even decline — jvun) AFTER the diamond is
    // emitted+flattened. Gate the predicate here (the same `compareInScope`
    // `rewriteCompare` now consults) and decline PRE-mutation. Width needs no
    // separate check: the lineage seeds at the i1 compare result, so an
    // unsupported fp/int width only enters via a cast — already gated above.
    if (auto *Cmp = dyn_cast<CmpInst>(I)) {
      if (!comparePredLowerable(Cmp))
        return CondDataDisp::Unlowerable;
      if (Cmp->use_empty())
        return CondDataDisp::Unowned;  // dead-within-function lineage.
      for (User *U : Cmp->users())
        if (auto *UI = dyn_cast<Instruction>(U))
          Work.push_back(UI);
      continue;
    }
    // A tainted-result binop/unary carries the lineage onward COHERENTLY (a
    // reversible read, no collapse); keep walking its users. Binops reach an
    // unsupported width only THROUGH a cast (already gated); every supported
    // binop opcode has a template. An orphaned op (no users) is dead within the
    // function — the flag would leak.
    if (isa<BinaryOperator>(I) || isa<UnaryOperator>(I)) {
      if (I->use_empty())
        return CondDataDisp::Unowned;  // dead-within-function lineage.
      for (User *U : I->users())
        if (auto *UI = dyn_cast<Instruction>(U))
          Work.push_back(UI);
      continue;
    }
    return CondDataDisp::Unowned;  // unrecognized (store/opaque/cq_invert/phi/…).
  }
  return CondDataDisp::ShareOk;
}

namespace {

// issue a8c0 — the straight-through const-fold re-anchor (the Pred-edge analog of
// `tryEqFoldArm`). `clang -O1` reaches a diamond's straight-through (Pred→merge)
// edge ONLY when the branch proves the routed qubit holds a single value, so it
// value-propagates that phi incoming to a `ConstantInt` k (Rule 9: "value-
// propagating the straight-through edge to a constant"). For the pre-3qlq
// register-form phase `if (q != 0) q = cq_phi(q, θ)` the else edge folded to `0`,
// so the merge was `phi [phase(q), 0]` and the `Base == Routed` gate failed
// (`Routed` the folded `0`, `Base` the qubit) — an OVER-DECLINE of a clean phase
// arm. The register-free `cq_phi` arm has no merge φ (`classifyPhaseKickback`).
//
// This returns the tainted qubit `H` to re-anchor `Routed`/`RoutedBase` to, but
// ONLY when the branch condition SOUNDLY proves `H == k` on the straight-through
// edge — so `phi [phase(H), k] ≡ phi [phase(H), H]` there. Requirements:
//   * `Routed` (== the straight-through incoming) is a `ConstantInt` k;
//   * a DIAMOND (one content arm + a Pred straight edge) — an if/else has no
//     straight-through and never folds one;
//   * the condition is `icmp <eq|ne> H, C` — H a tainted handle == the arm's
//     phase-spine `Base` (the arm rotates the proven handle), C a `ConstantInt`;
//   * the folded constant equals the compare literal (`k == C`, width+value);
//   * the straight-through (Pred→merge) edge is the branch successor whose truth
//     value PROVES `H == C` (eq → true edge, ne → false edge).
// Any miss returns null → the ordinary decline runs unchanged (Prime Directive).
// A compound/nested condition (`Region.Condition` is a select, not an `ICmpInst`)
// and a value arm (`Base != H`) both miss — so the demo's `(b>4)||(b==0)` merge
// and every genuine value collapse stay correctly declined.
Value *straightThroughConstFoldHandle(const ControlRegion &Region, Value *Routed,
                                      Value *Base, const TaintSet &Taint) {
  auto *K = dyn_cast_or_null<ConstantInt>(Routed);
  if (!K)
    return nullptr;
  if (!Region.Arm || Region.ArmFalse)
    return nullptr;  // diamond only.
  auto *Cond = dyn_cast_or_null<ICmpInst>(Region.Condition);
  if (!Cond || !Cond->isEquality())
    return nullptr;
  // Position-free { ConstantInt C, non-constant handle H }.
  auto *C0 = dyn_cast<ConstantInt>(Cond->getOperand(0));
  auto *C1 = dyn_cast<ConstantInt>(Cond->getOperand(1));
  ConstantInt *C = nullptr;
  Value *H = nullptr;
  if (C1 && !C0) {
    C = C1;
    H = Cond->getOperand(0);
  } else if (C0 && !C1) {
    C = C0;
    H = Cond->getOperand(1);
  } else {
    return nullptr;  // two handles or two constants — not this shape.
  }
  if (H != Base)
    return nullptr;  // the arm must rotate the handle the compare constrains.
  if (!Taint.Tainted.count(H))
    return nullptr;  // criterion 3 — the routed handle is a tainted qubit.
  if (C->getType() != K->getType() || C->getValue() != K->getValue())
    return nullptr;  // the folded constant must equal the compare literal.
  // Soundness: the straight-through (Pred→merge) edge must PROVE H == C. Locate it
  // as the branch successor equal to the merge block, and check its truth value.
  auto *Br = dyn_cast<BranchInst>(Region.Pred->getTerminator());
  if (!Br || !Br->isConditional() || Br->getCondition() != Cond)
    return nullptr;
  const BasicBlock *MergeBB = Region.Merge->getParent();
  bool StraightIsTrueEdge;
  if (Br->getSuccessor(0) == MergeBB && Br->getSuccessor(1) != MergeBB)
    StraightIsTrueEdge = true;
  else if (Br->getSuccessor(1) == MergeBB && Br->getSuccessor(0) != MergeBB)
    StraightIsTrueEdge = false;
  else
    return nullptr;  // merge is both/neither successor — not a clean straight edge.
  bool StraightProvesEq = Cond->getPredicate() == CmpInst::ICMP_EQ
                              ? StraightIsTrueEdge
                              : !StraightIsTrueEdge;
  if (!StraightProvesEq)
    return nullptr;
  return H;
}

}  // namespace

// ── bd `test_C_libtooling-wx8g` — R7-LOOP CLAUSE (c): THE ITERATION-LOCAL RAIL ──
//
// (b)/(b′) above are about a rail that CROSSES THE BACK EDGE: some member of the
// rotated base's wire closure is a header φ, and `railPhiRootMint` proves round
// 2's `collapseRailPhisIn` will CLAIM it. An ITERATION-LOCAL register has no
// header φ at all, so (b) finds no member and `Rollable` stayed false BY
// CONSTRUCTION for every such program, forever — which `ArmClassify` itself said
// in writing above ("R7's LOOP half below is deliberately NOT skipped: it
// iterates `BaseWireOrder`, which is empty here, so `Rollable` stays false and
// every in-loop state prep declines `control flow inside a loop body` — the
// ITERATION-LOCAL spelling"). Two shipped decline fixtures pinned it:
// `control_inplace_ry_reject_inloop_iterlocal_base.ll` (a rotated base minted in
// the body) and `control_inplace_ry_reject_stateprep_inloop_iterlocal.ll` (the
// controlled state prep, whose `BaseWireOrder` is EMPTY because R4/R6 are
// SKIPPED for a prep).
//
// THE OBLIGATION IS A DIFFERENT ONE, AND IT IS NOT "the collapse will claim it":
// there is nothing to claim. It is **"the rolled body emits, per activation,
// exactly what the hand-unrolled twin emits for that trip"**. Three clauses
// prove it; the third is the one that is a UNITARY fence and not bookkeeping,
// and it has a MEASURED discriminating pair.
//
//   (c1) THE RAIL DOES NOT CROSS THE BACK EDGE. `Rollable == false` is NOT this
//        statement: a header φ that (b′) REFUSED (PRD §13.2 row DB, a DERIVED
//        out-of-place base) also leaves `Rollable` false, and that rail IS
//        carried — rolling it would be the X1 cross-iteration dirty rail. Asked
//        POSITIVELY, over the same `BaseWireOrder` (b) reads, plus the merge φ.
//
//   (c2) THE REGISTER IS MINTED FRESH ON EVERY ACTIVATION, INSIDE `L`. Asked by
//        CALLING `railChainRootMint` — `railPhiRootMint`'s own clean-rail-mint
//        tail (Rule 14, never a second spelling of "what mints this rail?") —
//        and then requiring `L->contains(Mint->getParent())` where (b′) requires
//        `DT.dominates(Mint, LHdr)`. The two are the complementary halves of one
//        dichotomy: minted ONCE before the loop, or minted FRESH every trip. A
//        clean mint lowers to `cqrt_alloc_<W>` + `cqrt_ry_<W>`, so a mint inside
//        the body IS K fresh rails — precisely what K copies of the arm do.
//        ⚠ For a STATE PREP the base is the SEED — a literal, or since bd z0re
//        a RUNTIME classical value, possibly one the loop re-computes every trip
//        (`s + k`), which the in-body alloc then reads per activation exactly as
//        the unrolled twin's k-th copy reads its own — and there is no
//        pre-region SSA name for the rail at all (§14.5); the mint is the
//        HOISTED `T` itself, which is why `MintSeed` is `T` there. That also
//        answers the deferred item recorded in
//        `control_inplace_ry_reject_stateprep_inloop_iterlocal.ll`'s header: it
//        reads the obstruction as POSITIONAL and concludes "a rolled in-loop
//        state prep would need the alloc hoisted OUT of the loop — a real
//        transformation with its own per-activation reset question (trip 2's
//        `f=0` component would read a rail trip 1 may have rotated)". That reset
//        question is a property of HOISTING, which this clause does not do and
//        must not: leaving the alloc IN the body is what makes trip 2's `f=0`
//        component read a FRESH |SEED⟩, exactly as the unrolled twin's second
//        block does.
//        ⚠ AND THE MINT MUST BE AN Ry. `railChainRootMint` deliberately does not
//        test the callee family (see LoopPlan.h): a register-free
//        `cq_phi(double)` has an untainted arg-0 — the ANGLE — and passes it.
//        `cq_phi` ALLOCATES NOTHING (Rule 3), so it cannot be a per-trip rail
//        mint; the family test is asked here, by the caller that needs it.
//
//   (c3) NO TAINTED VALUE DEFINED INSIDE `L` MAY HAVE A USER OUTSIDE `L`.
//        THIS IS THE CLAUSE THE INCREMENT TURNS ON, and it is the fence R7's (b)
//        comment already named without owning: "an ITERATION-LOCAL rotated
//        register … is measurably not twin-identical — its escape makes
//        `markIfRailLocal` refuse the marking, so the rolled form leaks the
//        condition chain once per trip while the hand-unrolled twin discharges
//        it. A DIFFERENT CIRCUIT."
//
//        MEASURED 2026-09-14 on the scaffolded subject with this clause ABSENT,
//        one pair differing in exactly one edge — where the iteration-local
//        register is read (`$SES/trackW/probes/ir/il_{escape,noescape}_{rolled,flat}.ll`,
//        a derived condition `(q>>i)&1` so the per-trip chain is the SPINE's to
//        discharge and not the emitter's):
//
//          ESCAPES `L` (measured after the loop): rolled **19** trace lines,
//            hand-unrolled twin **27**. The rolled form emits
//            `lshr; and; icmp; cry; icmp_unc; free(flag)` per trip and NEVER the
//            `and_unc`/`lshr_unc`/two frees — TWO entangled which-path records of
//            `q`'s bits leaked per activation. `opt` exit 0 on both, verify-clean
//            on both, and `free_pairing_check.py` is structurally blind (a
//            template-minted rail has no `cqrt_alloc` to count).
//          DOES NOT ESCAPE (measured inside the body): rolled == unrolled,
//            **BYTE-IDENTICAL**, every rail discharged.
//
//        So the clause is a real unitary fence with a control, not a guess.
//
//        ⚠ IT IS `markIfRailLocal`'s OWN ESCAPE CLAUSE, ASKED CONSERVATIVELY.
//        That function exempts values on a ROOT rail (`onRail`, keyed on the
//        `Roots` `collapseRailPhisIn` + `invariantRegisterRoots` supply AFTER the
//        flatten); this runs at DETECTION, where no `Roots` exists yet, and
//        therefore asks the question with the EMPTY exemption set. The direction
//        is the safe one and the argument is monotonicity, not luck: a LARGER
//        `Roots` exempts strictly MORE values from that escape check, so
//        "no tainted value defined in `L` escapes" ⇒ "no iteration-local temp
//        escapes", for every `Roots`. It can therefore only OVER-decline, never
//        under-. THE KNOWN OVER-DECLINE IS THE MIXED LOOP — a loop that ALSO
//        carries a rail whose exit value is read after the loop (`for (k) {
//        cq_theta(&q,.1); int r = 7; cq_theta(&r,.25); if (b) cq_theta(&r,.2); … }
//        return cq_measure(q);`) — which `markIfRailLocal` would have exempted.
//        Filed as a follow-on rather than approximated here, because predicting
//        `Roots` at detection is a SECOND SPELLING of two functions' claim
//        conditions (the drbq Inc-3 (b′) defect), and because a wrong prediction
//        inverts the monotonicity above into an under-decline.
//        RETIREMENT TRIGGER: widen this to a real root set only together with a
//        re-derivation of that monotonicity — and only by CALLING whatever owns
//        `Roots`, never by re-deriving it here.
//
// ⚠ WHAT THIS CLAUSE DELIBERATELY DOES **NOT** ASK, because another owner does:
// the loop's CFG shape (`flatRegionRollableInLoop` gates (A)-(D), already proved
// before `Region.InLoop` was set), the quantum-bounded exit (`taintedExit` / Q1,
// unconditional and untouched — a quantum-dependent trip count still declines
// loudly and the Rule-18 bound derivation is NOT built), the rotation angle (R2
// above), the condition's measurement and wire disposition (the §13.3 rail ladder
// / `condWireDisposition`, both already asked above and both loop-aware), and
// R6's per-activation record fence (`recordLivePerActivation`, immediately
// below). Pure analysis; mutates nothing (Rule 9).
static bool iterationLocalRollable(
    const llvm::Loop *L, const BasicBlock *LHdr, ArrayRef<Value *> BaseWireOrder,
    const PHINode *MergePhi, CallInst *T, bool StatePrep, Value *RotBase,
    const SmallPtrSetImpl<CallInst *> &GateCalls, const TaintSet &Taint,
    Instruction **EscOut = nullptr) {
  if (!L || !LHdr || !T)
    return false;  // no loop, no header, no gate — no proof (Prime Directive).
  if (!L->getLoopLatch())
    return false;  // single latch, as every other rail reader requires.

  // (c1) — positively: nothing on the rotated register's wire, nor the merge φ
  //        the emitter is about to dissolve, is a φ in `L`'s header.
  for (Value *B : BaseWireOrder)
    if (auto *P = dyn_cast<PHINode>(B))
      if (P->getParent() == LHdr)
        return false;
  if (MergePhi && MergePhi->getParent() == LHdr)
    return false;

  // (c2) — the rail is minted fresh, by an Ry, inside `L`.
  Value *MintSeed = StatePrep ? static_cast<Value *>(T) : RotBase;
  CallInst *Mint = railChainRootMint(MintSeed, GateCalls, Taint);
  if (!Mint || !L->contains(Mint->getParent()))
    return false;
  const Function *MF = Mint->getCalledFunction();
  if (!MF || !MF->getName().starts_with("cq_theta_"))
    return false;  // `cq_phi` is register-free: it allocates nothing (Rule 3).
  // ⚠ THE `cq_phi` HALF OF THAT TEST IS DEAD TODAY, and review round 1 supplied
  // a STRONGER ground for it than the one first recorded (H-3). It is not merely
  // that "a `void` call cannot be the base of an `i32` rail": `peelInPlaceStep`
  // steps THROUGH a `GateCalls` member only when `CI->getArgOperand(0)` is
  // TAINTED, and for the register-free `void cq_phi(double)` arg-0 is the
  // UNTAINTED ANGLE — so the peel STOPS AT a `cq_phi` rather than walking past
  // it, which means `railChainRootMint` can only return one if it was the input
  // `V` itself. Both callers pass a REGISTER-TYPED value (`railPhiRootMint` a φ
  // incoming; this clause `RotBase` or `T`), and a `void` call is never an
  // operand of anything. Deliberately NO FIXTURE: an unreachable negative is a
  // VACUOUS fixture, which PROTOCOL.md S3 names as a defect of its own.
  // RETIREMENT TRIGGER: the day `cq_phi` acquires a register operand — a Key
  // Prohibition today, but so was the retired `cq_phi_<sfx>` family — this test
  // goes LIVE, and `railPhiRootMint` (which does NOT have it) needs it too.

  // (c3) — nothing tainted that is DEFINED in `L` is READ outside `L`. Asked by
  //        CALLING `iterationLocalTaintEscape` (LoopPlan.h), because the SAME
  //        question is re-asked at FINAL taint after the round-2 fixpoint by
  //        `declineUnmarkedRolledIterLocal`. One body, two taint sets — never a
  //        second spelling that agrees today (the drbq Inc-3 (b′) defect).
  // bd `test_C_libtooling-8h7d.12` — REPORT THE ESCAPE, do not merely fail on
  // it. Every other conjunct above is a SHAPE the caller cannot name for the
  // user; this one has a concrete offending instruction and a concrete sentence
  // ("a value this iteration mints is read after the loop"), and reporting it as
  // the generic `control flow inside a loop body` reads as *"in-loop control flow
  // is unsupported"* when in-loop control flow SHIPS. CLAUDE.md L6: a structural
  // guard wearing a semantic label.
  Instruction *Esc = iterationLocalTaintEscape(L, Taint);
  if (Esc && EscOut)
    *EscOut = Esc;
  return Esc == nullptr;
}

// The Q+Q condition refusal string, shared by every leaf ladder in this file
// (see its full note at `classifyPhaseKickback`, where it used to be defined).
constexpr const char *kQQCondReason = "quantum-quantum compare condition";

// ── bd test_C_libtooling-dm7f.52 — THE CONDITION-TREE LEAF LADDER, ONE SPELLING.
//
// `classifyPhaseKickback` (the branch phase) and `classifyArms` (the in-place
// controlled Ry arm and the controlled state prep) both lower a compound
// `and`/`or`/`xor`/logical-`select` condition through the SAME network
// (`CondTreeEmit::emitCondNetwork` mint, `stripCondNetwork` LIFO strip), so the
// questions "can every leaf be minted at the branch and stripped exactly after
// the region?" are ONE set of predicates (Rule 12, L2). Before dm7f.52 they
// lived inline in `classifyPhaseKickback`; they were LIFTED here verbatim (same
// order, same strings, same anchors) so the phase classifier's every decline is
// byte-identical and the rotation consumer cannot drift from it. The phase-only
// steps (the merge-φ leaf ladder 5c, the single-compare `HasDataUse` share path)
// stay at their consumer.

// Step 5a of the ladder for ONE compare leaf: the mint exists, it is not Q+Q,
// and — for a COMPOUND tree only — the leaf is quantum, has a non-i1 operand and
// is mintable at the branch from its own block. Returns the refusal string, or
// null to admit. Every refusal anchors at `declAnchor(Region)`.
const char *condTreeCompareLeafRefusal(CmpInst *Leaf, bool IsTree,
                                       const ControlRegion &Region,
                                       TaintSet &Taint,
                                       const DominatorTree *DT) {
  if (!comparePredLowerable(Leaf))
    return "control condition has no template";
  if (Taint.Tainted.count(Leaf->getOperand(0)) &&
      Taint.Tainted.count(Leaf->getOperand(1)))
    return kQQCondReason;
  if (!compareFlagMintable(Leaf, Taint))
    return "control flow";
  if (!IsTree)
    return nullptr;
  // A CLASSICAL leaf has no quantum flag to mint (see `classifyPhaseKickback`
  // step 5a for why the 4.4 select's literal route is not used here).
  if (!Taint.Tainted.count(Leaf))
    return "control flow";
  // An i1-OPERAND leaf would smuggle a NOT past the grammar (SelectClassify gate 2).
  if (Leaf->getOperand(0)->getType()->isIntegerTy(1))
    return "control flow";
  if (Leaf->getParent() != Region.Pred &&
      !crossBlockCompareMintable(Leaf, Region.Pred,
                                 Region.Pred->getTerminator(), Taint, DT))
    return "control flow";
  return nullptr;
}

// Step 5b for ONE rail leaf (a `cq_theta_i1` register read as its own flag):
// tainted, and not measured before the branch.
const char *condTreeRailLeafRefusal(CallInst *Rail, const ControlRegion &Region,
                                    TaintSet &Taint, const DominatorTree *DT) {
  if (!Taint.Tainted.count(Rail))
    return "control flow";
  if (railMeasuredBeforeReadPoint(Rail, Region.Pred->getTerminator(), Taint,
                                  DT))
    return "condition measured before the control route";
  return nullptr;
}

// The tree-SHAPE fences: every node lives in `Pred` (the network is emitted at
// the branch, and the logical-`select` claim is per-block), and every compare
// leaf and node is read only inside the tree or by the branch itself — a
// COMPARE leaf's flag and every node's ancilla are minted, stripped and FREED
// inside the region, so an out-of-tree reader would read a freed rail. Rail and
// merge-φ leaves mint nothing and are deliberately outside the set (see
// `classifyPhaseKickback` step 5b/6).
const char *condTreeShapeRefusal(const CondTree &Tree,
                                 const ControlRegion &Region,
                                 const BranchInst *BI) {
  for (Instruction *N : Tree.Nodes)
    if (N->getParent() != Region.Pred)
      return "control flow";
  SmallPtrSet<const Value *, 16> TreeSet;
  for (CmpInst *Leaf : Tree.Leaves)
    TreeSet.insert(Leaf);
  for (Instruction *N : Tree.Nodes)
    TreeSet.insert(N);
  for (const Value *V : TreeSet)
    for (const User *U : V->users())
      if (U != BI && !TreeSet.count(U))
        return "condition used outside the branch";
  return nullptr;
}

// The provenance seed set of a compound tree: the UNION over its leaves (the
// 4.4 select's gate-2c rule). Seeding from the root would cross nodes that carry
// no wire; seeding from one leaf would miss the others' wires.
// (Moved from `classifyPhaseKickback` by bd dm7f.52, verbatim:)
// bd `4aiu` (Track P) — RUNG (iii) FOR AN INTERIOR φ LEAF, into the SAME seed
// set, because it IS the same question about the same kind of object: a
// physical register named by a value, whose wire must carry no off-ancestry
// non-diagonal gate. `condProvenance` needs nothing new for a φ (it walks
// operand edges and stops at each `cq_theta`, so a φ contributes `{φ, each
// incoming theta}` — exactly the wire).
// ⚠ OMITTING THIS WOULD BE THE WHOLE WIDENING'S OVER-ACCEPT: a φ leaf
// contributes to `Prov` through NO other clause, so the wire walk would never
// look at the prepped register at all. It is `SelectClassify`'s gate-2c note
// verbatim, one consumer over (L2).
void condTreeProvenance(const CondTree &Tree, TaintSet &Taint,
                        SmallPtrSetImpl<Value *> &Prov) {
  for (CmpInst *Leaf : Tree.Leaves)
    condProvenance(Leaf, Taint, Prov);
  for (CallInst *Rail : Tree.RailLeaves)
    condProvenance(Rail, Taint, Prov);
  for (PHINode *P : Tree.RailPhiLeaves)
    condProvenance(P, Taint, Prov);
}

// `condWireDisposition`'s positional prong scans from the ROOT to the branch;
// a compound tree's LEAVES are defined before the root, so each leaf's own
// window is scanned too. True = a chained theta stales some leaf.
// (Moved from `classifyPhaseKickback` by bd dm7f.52, verbatim:)
// ⚠ bd `drbq.12` (2026-09-17) — THE `scanForward` LAMBDA THAT STOOD HERE IS
// GONE, AND DELETING IT IS NOT A CLEANUP: it discharges the L8 RETIREMENT
// TRIGGER Track P′ wrote into this block in these words — *"the day step 5a's
// cross-block compare-leaf decline is widened, delete `scanForward` and give
// BOTH loops this helper — a single window must not survive as the weaker of
// two spellings of one question (L2)."* Step 5a is now widened, so the
// trigger has fired and is honoured: there is ONE window helper and both
// loops call it.
//
// ⚠ AND THE `getParent() == Region.Pred` GUARD IS THE OTHER HALF OF
// HONOURING IT, not a re-introduction of the weaker spelling. A CROSS-BLOCK
// compare leaf reaches this loop only because step 5a ADMITTED it, and step
// 5a admitted it by walking THIS SAME GAP with
// `crossBlockCompareMintable` — the CFG-bounded walk with the RAIL-SCOPED
// vocabulary. Asking the wire-BLIND walk again here would re-decline exactly
// what 5a proved, on evidence 5a measured and dismissed (the arm's own Ry on
// a disjoint rail). One question, asked ONCE, at the site that decides
// admission. For an in-`Pred` leaf — every leaf that reaches this loop today
// — `chainedThetaBetweenDefAndBranch` IS `scanForward`
// expression-for-expression (Track P′'s own measurement), so nothing that
// lowered before can move.
// bd `hn29` / `leyd` (Track P′) — A φ LEAF NO LONGER HAS TO LIVE IN `Pred`;
// it has to survive a scan of every program point between its definition and
// the mint. `chainedThetaBetweenDefAndBranch` IS `scanForward` for a leaf in
// `Pred` (expression-for-expression — so every shipped in-`Pred` φ accept and
// decline is unmoved) and is the CFG-bounded walk for one outside it.
//
// ⚠ THE PARAGRAPH THAT STOOD HERE IS HISTORY AND ITS TRIGGER HAS FIRED (bd
// `drbq.12`, 2026-09-17). It said the compare leaves above *"keep
// `scanForward`"* because *"a cross-block COMPARE leaf never reaches this
// loop at all"*, and carried the retirement trigger *"the day step 5a's
// cross-block compare-leaf decline is widened, delete `scanForward` and give
// BOTH loops this helper"*. That day is here: step 5a now admits a
// cross-block compare leaf whose gap `crossBlockCompareMintable` has walked,
// `scanForward` is deleted, and both loops call this helper. The compare loop
// additionally guards on `getParent() == Region.Pred` — see its own note for
// why that is the second half of honouring the trigger rather than a
// re-introduction of the weaker spelling.
//
// ⚠ RETIREMENT TRIGGER, REPLACED: the day a φ leaf gains a wire-scoped
// cross-block admission of its own (the φ analogue of
// `crossBlockCompareMintable`), this loop owes the same `getParent()` split
// for the same reason — one question, asked once, at the site that admits.
// (This loop is inside `IsTree`, where `declAnchor` is the tree ROOT and
// carries a `!dbg` — see the anchor note at step 5c. The φ-ROOT spelling
// reaches `condWireDisposition` instead, whose own anchor is unchanged.)
//
// bd dm7f.53 — THAT TRIGGER HAS FIRED: a CROSS-BLOCK φ leaf now asks the
// wire-scoped `crossBlockPhiLeafMintable` (which walks this same gap with the
// rail vocabulary); an in-`Pred` φ keeps `chainedThetaBetweenDefAndBranch`
// expression-for-expression, so every shipped in-`Pred` φ verdict is unmoved.
bool condTreeLeafWindowStale(const CondTree &Tree, const ControlRegion &Region,
                             TaintSet &Taint, const DominatorTree *DT) {
  const Instruction *Term = Region.Pred->getTerminator();
  for (CmpInst *Leaf : Tree.Leaves)
    if (Leaf->getParent() == Region.Pred &&
        chainedThetaBetweenDefAndBranch(Leaf, Region.Pred, Term, Taint))
      return true;
  for (PHINode *P : Tree.RailPhiLeaves) {
    if (P->getParent() != Region.Pred) {
      if (!crossBlockPhiLeafMintable(P, Region.Pred, Term, Taint, DT))
        return true;
      continue;
    }
    if (chainedThetaBetweenDefAndBranch(P, Region.Pred, Term, Taint))
      return true;
  }
  return false;
}

// The live-ancilla bound shared by both tree consumers (see the note at
// `classifyPhaseKickback` step 5).
constexpr size_t kCondTreeMaxLeaves = 8;
constexpr size_t kCondTreeMaxNodes = 8;
bool condTreeTooLarge(const CondTree &Tree) {
  return Tree.Leaves.size() + Tree.RailLeaves.size() +
                 Tree.RailPhiLeaves.size() >
             kCondTreeMaxLeaves ||
         Tree.Nodes.size() > kCondTreeMaxNodes;
}

enum class PhiLeafRefusal { None, Unclaimed, MeasuredEarly };

// bd test_C_libtooling-dm7f.53 — step 5c (the REGION-MERGE-φ LEAF ladder) for
// ONE φ leaf, lifted verbatim from `classifyPhaseKickback` so the in-place Ry /
// state-prep consumer CALLS it rather than re-spelling it (R12, the dm7f.52
// discipline). Rung 0: the φ is some region's committed `InPlaceRotation` merge
// (`preppedRailPhiRegionIdx`, CALLED); rung (i): tainted; rung (ii): no name in
// the φ's provenance closure is measured before the branch. `PrepIdx` receives
// rung 0's index. The caller picks the string for `Unclaimed` (the phase path
// keeps its root/leaf split) and owns the emission-order record.
PhiLeafRefusal condTreePhiLeafRefusal(PHINode *P, const ControlRegion &Region,
                                      const ControlPlan &plan, TaintSet &Taint,
                                      const DominatorTree *DT,
                                      unsigned &PrepIdx) {
  PrepIdx = preppedRailPhiRegionIdx(P, plan);
  if (PrepIdx == ControlRegion::kNoParent)
    return PhiLeafRefusal::Unclaimed;
  if (!Taint.Tainted.count(P))
    return PhiLeafRefusal::Unclaimed;
  SmallPtrSet<Value *, 16> PhiProv;
  condProvenance(P, Taint, PhiProv);
  for (Value *Name : PhiProv)
    if (railMeasuredBeforeReadPoint(Name, Region.Pred->getTerminator(), Taint,
                                    DT))
      return PhiLeafRefusal::MeasuredEarly;
  return PhiLeafRefusal::None;
}

// bd test_C_libtooling-dm7f.53 — THE ON-ANCESTRY PRODUCERS OF A CLAIMED φ LEAF.
//
// A φ leaf `P` claimed by rung 0 is the merge of an in-place Ry / state-prep
// region `R`. When `R` rotated a LIVE register `S` (`P = φ [T(S), arm], [S,
// pred]`), `condProvenance(P)` is `{P, T, S}` and `findNonDiagonalWireGate`
// closes each SEED backward on its own: relative to the seed `S`, `T` is an
// OFF-ancestry sibling gate, so every in-place-arm φ leaf declined `condition
// predates a non-diagonal gate` (reporter t6.c line 11, at both tree
// consumers) although the condition reads `P`, the record AFTER `T`.
//
// WHY `T` CANNOT STALE A READ OF `P`: `T` executes only on `R`'s arm, before
// `P` is defined, and `P` on that path IS `T`'s result; on the other path `T`
// does not execute. So `T` is a PRODUCER of the record the condition reads,
// exactly the on-ancestry gate the walker already exempts for a chained seed —
// it is only the per-seed closure that cannot see it through the φ. Every arm
// gate of `R` (both arms of an if/else) is such a producer.
//
// WHY IT IS NOT COVERED UNCONDITIONALLY: `Covered` is per-WALK, not per-seed.
// A different LEAF may read a pre-`T` name of the same wire (`bool old = q1;
// if (q0) cq_theta(&q1,.4); if (old ^ q1) …` — `old` aliases `S`'s register,
// and `T` is exactly the gate that makes `old` stale). So `T` is covered only
// when it is NOT staling evidence for the OTHER leaves: the gate SET reachable
// from every other leaf's provenance is enumerated (`collectNonDiagonalWireGates`,
// position-free — L3, a set question) and a member of it stays evidence. The
// positional scans (`chainedThetaBetweenDefAndBranch`) are untouched.
void condTreeCoveredPhiGates(const CondTree &Tree, const ControlPlan &plan,
                             TaintSet &Taint,
                             SmallPtrSetImpl<const CallInst *> &Covered) {
  for (PHINode *P : Tree.RailPhiLeaves) {
    if (preppedRailPhiRegionIdx(P, plan) == ControlRegion::kNoParent)
      continue;  // refused by rung 0 at the caller; nothing to cover.
    // The producers: the arm gates of EVERY claimed region whose merge lies in
    // `P`'s own provenance — `P`'s region, and (the Dicke chain `if (c == 0)
    // cq_theta(&q,·); if (c == 1) cq_theta(&q,·); … if (q & …)`) each earlier
    // region whose merge is a straight-through / arm-operand ancestor of `P`.
    // Each such gate's result is a dataflow ANCESTOR of the record `P` names,
    // so it executes before `P` is defined and cannot stale it.
    SmallPtrSet<Value *, 16> OwnProv;
    condProvenance(P, Taint, OwnProv);
    SmallVector<const CallInst *, 4> ArmGates;
    for (Value *V : OwnProv) {
      auto *Q = dyn_cast<PHINode>(V);
      if (!Q)
        continue;
      const unsigned Idx = preppedRailPhiRegionIdx(Q, plan);
      if (Idx == ControlRegion::kNoParent)
        continue;
      const ControlRegion &R = plan.Regions[Idx];
      for (ArrayRef<Instruction *> Sh : {ArrayRef<Instruction *>(R.Shadow),
                                         ArrayRef<Instruction *>(R.ShadowFalse)})
        for (Instruction *I : Sh)
          if (auto *CI = dyn_cast<CallInst>(I); CI && isThetaCall(CI))
            ArmGates.push_back(CI);
    }
    if (ArmGates.empty())
      continue;
    SmallPtrSet<Value *, 16> Other;
    for (CmpInst *Leaf : Tree.Leaves)
      condProvenance(Leaf, Taint, Other);
    for (CallInst *Rail : Tree.RailLeaves)
      condProvenance(Rail, Taint, Other);
    for (PHINode *Q : Tree.RailPhiLeaves)
      if (Q != P)
        condProvenance(Q, Taint, Other);
    SmallVector<Value *, 16> OtherSeeds(Other.begin(), Other.end());
    SmallVector<CallInst *, 8> Evidence;
    collectNonDiagonalWireGates(OtherSeeds, /*CrossValueRouting=*/true,
                                /*EmitPoint=*/nullptr, /*DT=*/nullptr, &Taint,
                                Evidence);
    for (const CallInst *G : ArmGates)
      if (!llvm::is_contained(Evidence, G))
        Covered.insert(G);
  }
}

// bd dm7f.52 — is this region a candidate for the COMPOUND-condition in-place
// Ry / state-prep accept? Pure analysis, no mutation: every content arm feeding
// the merge is exactly one `cq_theta` the rotation clause would itself admit
// (`inPlaceRotationArmTheta`, CALLED — the one spelling). Anything else keeps
// the pre-dm7f.52 `control flow` refusal at the condition gate, so no other arm
// class acquires a compound-condition path nobody cleared (the value arm under a
// tree is filed separately).
bool condTreeRotationCandidate(const ControlRegion &Region,
                               const PHINode *MergePhi, TaintSet &Taint) {
  if (!Region.Arm)
    return false;
  for (BasicBlock *ArmBB : {Region.Arm, Region.ArmFalse}) {
    if (!ArmBB)
      continue;
    if (MergePhi->getBasicBlockIndex(ArmBB) < 0)
      return false;
    bool StatePrep = false;
    if (!inPlaceRotationArmTheta(MergePhi->getIncomingValueForBlock(ArmBB),
                                 ArmBB, MergePhi, Taint, StatePrep))
      return false;
  }
  return true;
}

void condProvCoveredPhiGates(Value *Cond, const ControlPlan &plan,
                            TaintSet &Taint,
                            SmallPtrSetImpl<const CallInst *> &Covered) {
  // The provenance that does NOT pass through a claimed merge φ is `Other`;
  // the claimed φs it stops at are `Phis`.
  SmallVector<PHINode *, 2> Phis;
  SmallPtrSet<Value *, 16> Other;
  condProvenance(Cond, Taint, Other, [&](Value *V) {
    auto *Q = dyn_cast<PHINode>(V);
    if (!Q || preppedRailPhiRegionIdx(Q, plan) == ControlRegion::kNoParent)
      return false;
    Phis.push_back(Q);
    return true;
  });
  if (Phis.empty())
    return;
  for (PHINode *P : Phis)
    Other.erase(P);
  // The on-ancestry producers: each claimed region's arm gates whose merge is
  // in a stopped φ's own provenance — `condTreeCoveredPhiGates`' set, per φ.
  SmallVector<const CallInst *, 4> ArmGates;
  for (PHINode *P : Phis) {
    SmallPtrSet<Value *, 16> OwnProv;
    condProvenance(P, Taint, OwnProv);
    for (Value *V : OwnProv) {
      auto *Q = dyn_cast<PHINode>(V);
      if (!Q)
        continue;
      const unsigned Idx = preppedRailPhiRegionIdx(Q, plan);
      if (Idx == ControlRegion::kNoParent)
        continue;
      const ControlRegion &R = plan.Regions[Idx];
      for (ArrayRef<Instruction *> Sh : {ArrayRef<Instruction *>(R.Shadow),
                                         ArrayRef<Instruction *>(R.ShadowFalse)})
        for (Instruction *I : Sh)
          if (auto *CI = dyn_cast<CallInst>(I); CI && isThetaCall(CI))
            ArmGates.push_back(CI);
    }
  }
  if (ArmGates.empty())
    return;
  SmallVector<Value *, 16> OtherSeeds(Other.begin(), Other.end());
  SmallVector<CallInst *, 8> Evidence;
  collectNonDiagonalWireGates(OtherSeeds, /*CrossValueRouting=*/true,
                              /*EmitPoint=*/nullptr, /*DT=*/nullptr, &Taint,
                              Evidence);
  for (const CallInst *G : ArmGates)
    if (!llvm::is_contained(Evidence, G))
      Covered.insert(G);
}

ArmDisposition classifyArms(ControlRegion &Region, TaintSet &Taint,
                            const DominatorTree *DT, const LoopInfo *LI,
                            SmallPtrSetImpl<Instruction *> *ClaimedSelects,
                            const ControlPlan *Plan) {
  auto *MergePhi = dyn_cast_or_null<PHINode>(Region.Merge);
  if (!MergePhi) {
    diagnoseUnderControl(declAnchor(Region), "control flow");
    return ArmDisposition::Declined;
  }

  // The flag is minted from a SINGLE comparison (icmp/fcmp → `_hl` template). A
  // compound condition (clang's `select i1` for `&&`/`||`) or any non-compare i1
  // is not a 4.1-lowerable region — decline (closes the compound-cond
  // over-accept; WI-1 adversarial review 2026-06-09).
  //
  // ---- bd test_C_libtooling-l4x4, sub-increment l4x4.b — THE GATE, WIDENED TO
  //      A BARE `_Bool` (RAIL-ROOT) CONDITION.
  //
  // `isCondRailLeaf` is the user's own `_Bool` REGISTER (a `cq_theta_i1` result,
  // root or chained). `clang -O1` hands it to the pass as `br i1 %b` with NO
  // compare at all, from every natural `bool` spelling, and until l4x4.b every
  // such region died on this line. It mints NOTHING — the register IS its own
  // flag — so the three compare-shaped gates that follow (predicate template,
  // `HasDataUse`/`ShareCondFlag`, and `condWireDisposition`'s cross-block +
  // positional prongs) have no subject, and the §13.3 RAIL LADDER replaces them:
  //
  //   (i)   tainted — by construction (`cq_theta_i1` is the taint SOURCE),
  //         re-asked as defence in depth;
  //   (ii)  NOT measured before the READ POINT (`railMeasuredBeforeReadPoint` at
  //         `Pred->getTerminator()`, asked over the rail's WIRE and not over its
  //         SSA name — the r9e5 round-1 F-B1R1-1 widening);
  //   (iii) the WIRE question — `railCondWireDisposition`, which is
  //         `condWireDisposition` MINUS the P4 cross-block prong, MINUS the P5
  //         positional scan and MINUS the `ShareCondFlag` clause.
  //
  // ⚠ THE ACCEPT IS **TWO** ARM CLASSES, NOT ALL SIX, and the re-decline is
  // written AT EVERY OTHER ACCEPT SITE rather than once here (§2.6). l4x4.b ships
  // the CONTROL-IN-PLACE ROTATION arm and the controlled STATE PREP; the PHASE,
  // EQ-FOLD and VALUE classes keep `kBareRailCondReason` (bd `fg9k` owns the
  // value arm; the 6.5 classical-call arm never reaches here, refused by its own
  // `isa<CmpInst>` early return — bd `54ur`). That is deliberately the same
  // spelling homogeneity already uses — one flag, a clause at every accept site —
  // and for the same recorded reason: the one-directional version of that check
  // was already wrong once ("Luck is not a fence", `SawRotationArm` below).
  const bool RailCond = isCondRailLeaf(Region.Condition);
  // ---- bd test_C_libtooling-dm7f.52 — A COMPOUND CONDITION TREE on the in-place
  //      controlled Ry arm and the controlled state prep (`if (a & b)`,
  //      `if (a) if (b)` → `select i1 %a, %b, false`, `c = a + b; if (c == 1)` →
  //      `xor i1`, `if (x == 1 && y == 1)`).
  //
  // THE CIRCUIT is the branch phase's network with a different payload:
  //     f = CondTree(leaves)          ; `emitCondNetwork` — one flag per compare
  //                                   ;   leaf, one |0> ancilla per node, rail
  //                                   ;   leaves read as controls, minted nothing
  //     [x(f)] cRy(f, h, θ) [x(f)]    ; per arm, exactly the compare path's step 2
  //     strip(CondTree)               ; `stripCondNetwork`, the exact LIFO adjoint
  //     free(each ancilla)            ; proven |0> (R5)
  // The strip is exact iff no gate in the region relabels a LEAF's wire, and the
  // only gate is the Ry on the target — so the TARGET MUST NOT LIE ON ANY LEAF
  // WIRE. That is R4 below, asked over this tree's leaf-union `Prov`; a target on
  // a leaf wire (`if (a & b) cq_theta(&b, θ)`, `if (a ^ t) cq_theta(&a, θ)`) is
  // bd dm7f.51 / dm7f.9 territory and declines loudly there (`CondIsTree`
  // conjunct of the dm7f.4 kept-flag clause) — a tree flag is NEVER kept and NEVER
  // stripped against a rotated leaf, which would be a dirty free (a hidden
  // measurement).
  //
  // ADMITTED ONLY for a region whose every content arm is a rotation-clause
  // theta (`condTreeRotationCandidate`), so every other arm class keeps the
  // pre-dm7f.52 `control flow` here, byte-identical. The leaf ladder is the
  // branch phase's, CALLED (one spelling, R12): `condTreeCompareLeafRefusal`,
  // `condTreeRailLeafRefusal`, `condCmpMeasuredBeforeReadPoint`,
  // `condTreeShapeRefusal`, `condTreeProvenance`, `condTreeLeafWindowStale`.
  // A REGION-MERGE φ LEAF IS ADMITTED since bd dm7f.53 (`AllowRailPhi = true`),
  // on exactly the kickback's terms: step 5c's ladder, CALLED
  // (`condTreePhiLeafRefusal` — rung 0 needs the `Plan`, so a caller without
  // one refuses every φ leaf), and the kickback's emission-order obligation —
  // THIS region is emitted BEFORE the prep whose φ it reads, so the φ is still
  // a live `Value` when `emitCondNetwork` maps it to itself as a read-only
  // `cqrt_toffoli`/`cqrt_cnot` control; the prep's later M-β RAUW rewrites that
  // operand to the hoisted theta, which `lowerRotations` turns into the handle.
  // For a φ in `Pred` the bd `hcrg` alias edge forces that order; for a
  // cross-block φ the record `Region.PrepRegionIdxs` below supplies it (the
  // `BranchRegion` edge loop in `lowerControlRegions`, the kickback's loop one
  // `Kind` over). The customer is the Dicke cascade (reporter t6.c): `c = q0 +
  // q1` with `q1` conditionally rotated folds to `xor i1 %q0, %q1.phi`.
  // A φ ROOT (`if (b)` with `b` a prep's merge) has no nodes, so `CondIsTree`
  // stays false for it; it is admitted separately as `PhiRootCond` below (the
  // register-as-control, R11 round-1 item 2).
  //
  // Bennett.jl ground truth (824458d1): a block's path predicate is built from
  // the already-resolved predicate WIRES of its predecessors
  // (`src/lowering/phi.jl:31-60`, `_compute_block_pred!`), i.e. a later guard
  // reads an earlier merge's resolved wire as an ordinary control — the
  // φ-as-control reading this admits.
  //
  // Bennett.jl ground truth (824458d1): a branch condition is ONE resolved wire
  // (`src/lowering/driver.jl:408-420`); an `and`/`or`/`xor` i1 lowers to a fresh
  // ancilla by Toffoli / CNOT,CNOT,Toffoli / CNOT,CNOT
  // (`src/lowering/arith.jl:348-384`, `src/lowering/phi.jl:4-29`), and guarded
  // gates take that wire as an extra control (`src/shadow_memory.jl:98`). Bennett
  // uncomputes the predicate by the global reverse pass
  // (`src/bennett_transform.jl:375`); CQ strips it locally, LIFO, right after the
  // region, which is valid for the same reason (no leaf wire moves in between).
  // ---- bd test_C_libtooling-dm7f.77 (dm7f.51 step 2, design D3) — A REGISTER
  //      CONDITION (RegCondLeaf.h): the QQ xor `t ^ a` whose dead target `t`
  //      the late round overwrites in place. It is read as a REGISTER-AS-CONTROL
  //      exactly like the bare `_Bool` rail: never decomposed (the network would
  //      re-read the old `t` after the in-place gate), never minted, bracketed or
  //      freed. Its wire is `{V} ∪ wire(target)` (`regCondProvenance`), so a
  //      rotation of the xor's SOURCE is off the condition's wire. Admitted only
  //      for a region whose every arm is a rotation-clause theta, like the φ root;
  //      every rail-only clause below reads `RegCond`.
  const bool CommitCond = !RailCond && isRegCondLeaf(Region.Condition) &&
                          condTreeRotationCandidate(Region, MergePhi, Taint);
  CondTree RotTree;
  const bool CondIsTree =
      !RailCond && !CommitCond && !isa<CmpInst>(Region.Condition) &&
      collectCondTree(Region.Condition, RotTree, /*AllowLogicalSelect=*/true,
                      /*AllowRailPhi=*/true) &&
      !RotTree.Nodes.empty() &&
      condTreeRotationCandidate(Region, MergePhi, Taint);
  // ---- bd test_C_libtooling-dm7f.53 (round-1 item 2) — A REGION-MERGE φ AS THE
  //      WHOLE CONDITION (`if (a) Ry(t); if (!a) Ry(t); if (t) Ry(u)` — the Dicke
  //      cascade reaches it). It is the one-leaf tree `collectCondTree` returns
  //      for a φ root (no node), and it lowers as a REGISTER-AS-CONTROL exactly
  //      like the bare `_Bool` rail (`RailCond`): the φ IS t's rail, read only as
  //      the control of `cqrt_ry_<W>_controlled`, never minted, bracketed or
  //      freed. The admission is the φ leaf's (step 5c, CALLED through
  //      `condTreePhiLeafRefusal`), the wire question is the kickback φ root's
  //      (`condWireDisposition` with `CondIsClaimedRailPhi`, plus the producer
  //      gates `condTreeCoveredPhiGates` names), and every rail-only clause
  //      below reads `RegCond` so the φ root inherits the rail's per-arm-class
  //      re-declines verbatim. Only for a region whose every arm is a
  //      rotation-clause theta (`condTreeRotationCandidate`).
  CondTree PhiRootTree;
  const bool PhiRootCond =
      !RailCond && !CommitCond && !CondIsTree &&
      isCondRailPhiShape(Region.Condition) &&
      collectCondTree(Region.Condition, PhiRootTree,
                      /*AllowLogicalSelect=*/true, /*AllowRailPhi=*/true) &&
      PhiRootTree.Nodes.empty() && PhiRootTree.RailPhiLeaves.size() == 1 &&
      condTreeRotationCandidate(Region, MergePhi, Taint);
  // The register IS the flag: a `cq_theta_i1` rail or a claimed merge φ.
  const bool RegCond = RailCond || PhiRootCond || CommitCond;
  if (!isa<CmpInst>(Region.Condition) && !RegCond && !CondIsTree) {
    diagnoseUnderControl(declAnchor(Region), "control flow");
    return ArmDisposition::Declined;
  }
  if (CondIsTree) {
    auto *TreeBI = Region.Pred ? dyn_cast<BranchInst>(Region.Pred->getTerminator())
                               : nullptr;
    if (!TreeBI || !TreeBI->isConditional() ||
        TreeBI->getCondition() != Region.Condition) {
      diagnoseUnderControl(declAnchor(Region), "control flow");
      return ArmDisposition::Declined;
    }
    if (condTreeTooLarge(RotTree)) {
      diagnoseUnderControl(declAnchor(Region), "control condition tree too deep");
      return ArmDisposition::Declined;
    }
    for (CmpInst *Leaf : RotTree.Leaves)
      if (const char *Why = condTreeCompareLeafRefusal(Leaf, /*IsTree=*/true,
                                                       Region, Taint, DT)) {
        diagnoseUnderControl(declAnchor(Region), Why);
        return ArmDisposition::Declined;
      }
    for (CallInst *Rail : RotTree.RailLeaves)
      if (const char *Why = condTreeRailLeafRefusal(Rail, Region, Taint, DT)) {
        diagnoseUnderControl(declAnchor(Region), Why);
        return ArmDisposition::Declined;
      }
    // bd dm7f.53 — step 5c, CALLED (see the note above). The tree root is the
    // anchor (it carries a `!dbg`; a φ does not — the step-5c anchor note).
    Region.PrepRegionIdxs.clear();
    for (PHINode *P : RotTree.RailPhiLeaves) {
      unsigned PrepIdx = ControlRegion::kNoParent;
      const PhiLeafRefusal Why =
          Plan ? condTreePhiLeafRefusal(P, Region, *Plan, Taint, DT, PrepIdx)
               : PhiLeafRefusal::Unclaimed;
      if (Why == PhiLeafRefusal::Unclaimed) {
        diagnoseUnderControl(declAnchor(Region), "control flow");
        return ArmDisposition::Declined;
      }
      if (Why == PhiLeafRefusal::MeasuredEarly) {
        diagnoseUnderControl(declAnchor(Region),
                             "condition measured before the control route");
        return ArmDisposition::Declined;
      }
      // Only the CROSS-BLOCK leaves are recorded — the kickback's rule: for an
      // in-`Pred` φ the `hcrg` alias edge already says exactly this.
      if (P->getParent() != Region.Pred)
        Region.PrepRegionIdxs.push_back(PrepIdx);
    }
    if (condCmpMeasuredBeforeReadPoint(RotTree.Leaves,
                                       Region.Pred->getTerminator(), Taint,
                                       DT)) {
      diagnoseUnderControl(declAnchor(Region),
                           "condition measured before the control route");
      return ArmDisposition::Declined;
    }
    if (const char *Why = condTreeShapeRefusal(RotTree, Region, TreeBI)) {
      diagnoseUnderControl(declAnchor(Region), Why);
      return ArmDisposition::Declined;
    }
    if (condTreeLeafWindowStale(RotTree, Region, Taint, DT)) {
      diagnoseUnderControl(declAnchor(Region),
                           "condition predates a non-diagonal gate");
      return ArmDisposition::Declined;
    }
  }
  if (PhiRootCond) {
    // Step 5c for the root, anchored at the BRANCH (a merge φ carries no
    // `!dbg` — the kickback's `PhiAnchor` lesson).
    auto *RootBI = Region.Pred ? dyn_cast<BranchInst>(Region.Pred->getTerminator())
                               : nullptr;
    if (!RootBI || !RootBI->isConditional() ||
        RootBI->getCondition() != Region.Condition) {
      diagnoseUnderControl(declAnchor(Region), "control flow");
      return ArmDisposition::Declined;
    }
    PHINode *P = PhiRootTree.RailPhiLeaves.front();
    unsigned PrepIdx = ControlRegion::kNoParent;
    const PhiLeafRefusal Why =
        Plan ? condTreePhiLeafRefusal(P, Region, *Plan, Taint, DT, PrepIdx)
             : PhiLeafRefusal::Unclaimed;
    if (Why == PhiLeafRefusal::Unclaimed) {
      diagnoseUnderControl(RootBI, "control flow");
      return ArmDisposition::Declined;
    }
    if (Why == PhiLeafRefusal::MeasuredEarly) {
      diagnoseUnderControl(RootBI,
                           "condition measured before the control route");
      return ArmDisposition::Declined;
    }
    Region.PrepRegionIdxs.clear();
    if (P->getParent() != Region.Pred)
      Region.PrepRegionIdxs.push_back(PrepIdx);
  }
  if ((RailCond || CommitCond) && !Region.Pred) {
    // No pred, no branch, no read point — the ladder's rungs (ii)/(iii) have
    // nothing to anchor on. Loud, never a silent skip (Rule 1).
    diagnoseUnderControl(declAnchor(Region), "control flow");
    return ArmDisposition::Declined;
  }

  // The flag is minted FROM this compare's predicate; an out-of-scope fcmp
  // predicate (after 8rvn, only the degenerate `true`/`false` — see
  // `compareInScope`) has no template, so the mint would emit a non-existent
  // symbol. SwapRouteEmit's flag-null bail catches it
  // loudly, but only the FLAT mint is its emit step 1 — decline in DETECTION so
  // the posture is uniform with the nested path (whose inner mint followed the
  // outer route, pre-3qlq) and the reason is precise (test_C_libtooling-jvun).
  //
  // SKIPPED for a rail: there is no predicate and no `_hl` template — the
  // register is handed to `cqrt_ry_<W>_controlled` as arg-0 unchanged.
  if (!RegCond && !CondIsTree &&
      !comparePredLowerable(cast<CmpInst>(Region.Condition))) {
    diagnoseUnderControl(declAnchor(Region), "control condition has no template");
    return ArmDisposition::Declined;
  }

  // ---- l4x4.b, RUNG (i) + RUNG (ii) of the §13.3 rail ladder. Asked HERE, in
  //      `classifyArms`' own order, so that a rail region's message ordering
  //      mirrors the compare region's: rung (ii) stands exactly where
  //      `condDataUseDisposition`'s `MeasuredEarly` stands for a compare, and
  //      carries that clause's string.
  if (RailCond) {
    auto *Rail = cast<CallInst>(Region.Condition);
    if (!Taint.Tainted.count(Rail)) {
      diagnoseUnderControl(declAnchor(Region), "control flow");
      return ArmDisposition::Declined;
    }
    if (railMeasuredBeforeReadPoint(Rail, Region.Pred->getTerminator(), Taint,
                                    DT)) {
      diagnoseUnderControl(declAnchor(Region),
                           "condition measured before the control route");
      return ArmDisposition::Declined;
    }
  }
  // bd dm7f.77 — the same two rungs for a REGISTER CONDITION, asked over BOTH
  // names of its wire: the value itself and the in-place target it overwrites
  // (a measured target would make the in-place gate a gate on a measured
  // handle, and the control a post-measure read).
  if (CommitCond) {
    Value *Target = regCondTarget(Region.Condition);  // null: a fresh rail.
    if (!Taint.Tainted.count(Region.Condition)) {
      diagnoseUnderControl(declAnchor(Region), "control flow");
      return ArmDisposition::Declined;
    }
    for (Value *Name : {Region.Condition, Target})
      if (Name && railMeasuredBeforeReadPoint(Name, Region.Pred->getTerminator(),
                                              Taint, DT)) {
        diagnoseUnderControl(declAnchor(Region),
                             "condition measured before the control route");
        return ArmDisposition::Declined;
      }
  }

  // The condition compare may feed a DATA position in addition to the branch
  // (e.g. `c = icmp …; zext c; br c` — clang CSE of a reused `q>5` bound to a
  // variable `f`). The compare IS the control flag, so the control stream and the
  // data use must share ONE physical flag (ziov, owner 2026-06-15): the emitter
  // (`emitRegion`; `emitPhaseKickbackRegion` for a `cq_phi` arm) mints it once,
  // controls with it, feeds the SAME handle to the data use, and SKIPS the eager
  // flag strip+free — sound iff the data lineage is owned downstream AND the
  // flag is coherent at the stream (`condDataUseDisposition`, keyed on
  // `Region.Pred` = the stream block). A dead-within-function lineage orphans
  // the flag as a dirty entangled rail (declined permanently — ziov.2's
  // deferred-strip accept was closed won't-fix as a silent miscompile), and a
  // measure of the flag IN that block collapses it BEFORE the stream controls
  // on it — both decline LOUDLY (over-declining is always safe). This SUPERSEDES
  // the flat 4.1 blanket decline ("condition used outside the branch"). Pure SSA
  // analysis (Rule 9).
  //
  // ⚠ SKIPPED WHOLE FOR A RAIL, AND SKIPPING IS THE ANSWER RATHER THAN AN
  // OPTIMISATION (bd test_C_libtooling-l4x4, l4x4.b, hazard H-4). Left in, this
  // block is not merely inapplicable — it is WRONG ABOUT THE WRONG OBJECT. A
  // rail's `users()` are the user's own reads of a `_Bool` variable: the
  // increment's flagship program (`bool b = …; cq_theta(&b, …); if (b) …; return
  // cq_measure(b);`) has a `cq_measure_i1` user, so `HasDataUse` is TRUE and
  // `condDataUseDisposition` would adjudicate the USER'S REGISTER as a FLAG
  // LINEAGE. Every outcome is then a wrong answer about the wrong object:
  // `ShareOk` would set `Region.ShareCondFlag` (and R7 below would decline a
  // shape that is perfectly ordinary), `MeasuredEarly` / `Unowned` would decline
  // a register whose measurement or death is the program, not a defect. Nothing
  // is MINTED from a rail, so no flag can be shared with a data use or outlive
  // the region — the identical argument `classifyPhaseKickback` records at its
  // own `HasDataUse` guard and `SelectClassify` restates. Rung (ii) above is the
  // replacement for the one real question this block asked (a measurement that
  // precedes the control read), not a weaker version of it.
  // bd dm7f.52: SKIPPED for a compound tree too — its data-use question was
  // asked STRUCTURALLY by `condTreeShapeRefusal` above (a tree has no share path:
  // the shared object would be the root ancilla, stripped and freed here).
  bool HasDataUse = false;
  if (!RegCond && !CondIsTree)
    for (const User *U : Region.Condition->users())
      if (!isa<BranchInst>(U)) {
        HasDataUse = true;
        break;
      }
  if (HasDataUse) {
    switch (condDataUseDisposition(cast<Instruction>(Region.Condition),
                                   Region.Pred, Taint)) {
    case CondDataDisp::ShareOk:
      Region.ShareCondFlag = true;
      break;
    case CondDataDisp::MeasuredEarly:
      diagnoseUnderControl(declAnchor(Region),
                           "condition measured before the control route");
      return ArmDisposition::Declined;
    case CondDataDisp::Unowned:
      diagnoseUnderControl(declAnchor(Region),
                           "condition data use neither escaped nor measured");
      return ArmDisposition::Declined;
    case CondDataDisp::Unlowerable:
      // A data cast on the lineage has no template (unsupported width /
      // out-of-scope pair) — decline HERE, before `emitRegion` emits and
      // `flattenRegion` erases the diamond, instead of letting `lowerOps`
      // diagnose it post-mutation (Rule 9 detect-before-mutate; ziov.4).
      diagnoseUnderControl(declAnchor(Region),
                           "condition data use has no template");
      return ArmDisposition::Declined;
    }
  }

  // Backward tainted provenance of the condition — shared by the wire-walk
  // guard below (its seed set; direct-operand seeding misses a derived
  // condition's wire), the §3c clobber check on value arms, and — since the
  // 2026-09-11 owner ruling (bd `drbq.14`) — **F2's `CondWire` exclusion set**,
  // built from these same seeds a few dozen lines down. Three consumers now.
  SmallPtrSet<Value *, 16> Prov;
  // bd dm7f.52: a compound tree seeds from the UNION over its leaves — the same
  // `condTreeProvenance` the branch phase uses — so R4's condition-wire set below
  // covers EVERY leaf's wire (the target-not-on-any-leaf-wire fence).
  if (CondIsTree)
    condTreeProvenance(RotTree, Taint, Prov);
  else if (CommitCond)
    regCondProvenance(Region.Condition, Taint, Prov);  // bd dm7f.77: not the source.
  else
    condProvenance(Region.Condition, Taint, Prov);

  // The flag is minted at the BRANCH; a tainted-operand `cq_theta` (non-diagonal
  // Ry) between the compare and the branch makes that mint read a different
  // basis than the source compare — the wrong arm fires and the flag cannot be
  // stripped. Decline (see condWireDisposition, which owns the whole rationale
  // INCLUDING the Inc-4 position-aware accept and its five preconditions).
  //
  // ---- l4x4.b, RUNG (iii). A rail asks `railCondWireDisposition` — the same
  // walker over the same `Prov` (which for a bare rail is exactly `{rail}`:
  // `condProvenance` collects a theta's RESULT and stops), minus the two prongs
  // that have no subject for a register. Spelled EXACTLY as
  // `classifyPhaseKickback` spells the same dispatch, so the two consumers of
  // one ladder cannot drift. `condWireDisposition` asked of a rail returns
  // `DeclineNow` unconditionally — its P4 prong refuses a condition defined
  // outside `Pred`, which is where a `_Bool` register's def routinely sits.
  // bd dm7f.53: a tree's claimed φ leaves' arm gates are on-ancestry producers
  // of the record the leaf reads (`condTreeCoveredPhiGates`, shared with the
  // kickback). Empty for every non-tree condition and every φ-free tree, so
  // those walks are the shipped ones.
  SmallPtrSet<const CallInst *, 4> CoveredPhiGates;
  if (CondIsTree && Plan)
    condTreeCoveredPhiGates(RotTree, *Plan, Taint, CoveredPhiGates);
  if (PhiRootCond && Plan)
    condTreeCoveredPhiGates(PhiRootTree, *Plan, Taint, CoveredPhiGates);
  // bd dm7f.77 — a COMPARE whose operand chain reads a claimed merge φ, and a
  // REGISTER CONDITION whose in-place target is one (dicke.c's `q2 ^= q1` after
  // the controlled Ry on q2): the claimed region's own arm gate produced that
  // register's value and is on its ancestry.
  if (!CondIsTree && Plan &&
      ((!RegCond && isa<CmpInst>(Region.Condition)) || CommitCond))
    condProvCoveredPhiGates(Region.Condition, *Plan, Taint, CoveredPhiGates);
  // A φ ROOT takes `condWireDisposition` with `CondIsClaimedRailPhi` — the
  // kickback φ root's exact call (step 5c ran rung 0 above).
  const CondWireDisp WireDisp =
      RailCond     ? railCondWireDisposition(Region, Taint, Prov, DT)
      : CommitCond ? railCondWireDisposition(Region, Taint, Prov, DT,
                                             CoveredPhiGates.empty()
                                                 ? nullptr
                                                 : &CoveredPhiGates)
               : condWireDisposition(Region, Taint, Prov, DT,
                                     /*CondIsClaimedRailPhi=*/PhiRootCond,
                                     CoveredPhiGates.empty() ? nullptr
                                                             : &CoveredPhiGates);
  if (WireDisp == CondWireDisp::DeclineNow) {
    diagnoseUnderControl(PhiRootCond ? Region.Pred->getTerminator()
                                     : declAnchor(Region),
                         "condition predates a non-diagonal gate");
    return ArmDisposition::Declined;
  }
  // P1 is not decidable yet — `SawPhaseArm`/`SawValueArm` are set by the arm
  // loop below — so a ProvenPostRegion gate becomes a DEFERRED decline: every
  // decline the rest of this function can fire is re-spelled as the wire-gate
  // message, so a region that declines for ANY other reason keeps the exact
  // message (and anchor) it had before Increment 4. Rule 12's negative fixtures
  // mirror these strings character-for-character, so message churn is a defect
  // in its own right — this wrapper is what makes the restructure churn-free,
  // and it is also the P1 fence: a VALUE arm (or any non-phase disposition)
  // still declines on the position-free reading, exactly as before.
  const bool DeferredWireGate = WireDisp == CondWireDisp::ProvenPostRegion;
  auto declineArm = [&](Instruction *Where, StringRef What) {
    if (DeferredWireGate)
      diagnoseUnderControl(declAnchor(Region),
                           "condition predates a non-diagonal gate");
    else
      diagnoseUnderControl(Where, What);
  };
  // ---- l4x4.b §2.6 — THE PER-ARM-CLASS RE-DECLINE. The gate above admits a
  // bare `_Bool` condition for the TWO classes this increment ships (the
  // control-in-place ROTATION arm and the controlled STATE PREP); every other
  // class must keep the string its fixture pins, at the accept site that would
  // otherwise claim it. Routed through `declineArm` like every other decline
  // below the wire gate, so a region that ALSO carries a deferred wire gate
  // keeps that message — the wrapper's whole purpose.
  auto declineRailClass = [&]() {
    declineArm(declAnchor(Region), kBareRailCondReason);
    return ArmDisposition::Declined;
  };

  // The diamond's straight-through (Pred-edge) incoming — the muxed variable's
  // prior value AND the handle a phase arm must keep. Present only for a
  // diamond; an if/else has no Pred incoming (its routed handle is anchored on
  // the first arm's spine base below).
  Value *StraightThrough = nullptr;
  if (Region.Pred && MergePhi->getBasicBlockIndex(Region.Pred) >= 0)
    StraightThrough = MergePhi->getIncomingValueForBlock(Region.Pred);

  SmallVector<BasicBlock *, 2> Arms;
  if (Region.Arm)
    Arms.push_back(Region.Arm);
  if (Region.ArmFalse)
    Arms.push_back(Region.ArmFalse);

  // The single handle EVERY phase arm must rotate (the emitter RAUWs the merge to it):
  // the diamond's straight-through incoming, or — for an if/else — the base the
  // first arm's phase spine bottoms at. An arm whose spine hits a value-changing
  // op, or bottoms at a DIFFERENT handle / a fresh `cq_theta` source, is not a
  // pure phase arm over the routed handle (closes the cross-handle / new-source
  // / hoisted-value-op mis-accepts; WI-1 adversarial review 2026-06-09).
  Value *Routed = StraightThrough;

  // 4.2 homogeneity bookkeeping (PRD Part II §0/§10): a region lowers
  // all-phase (the 4.1 path) or all-value over ONE shared routed base; a
  // phase arm beside a value arm has no single lowering method (the value
  // merge's copy dephases the phase answer, Rule 7) → `mixed phase/value arm`.
  bool SawPhaseArm = false;
  bool SawValueArm = false;
  // drbq Inc 1 — a control-in-place ROTATION arm was classified. Homogeneity is
  // enforced against the other two flags in the clause itself; this one exists
  // so the accept can be recorded and so the final P1 fence below reads it.
  //
  // ⚠ CORRECTED 2026-09-05 (round-1 Rule-13 review, lens L6 finding F-5, a
  // PRE-EXISTING Inc-3 leftover). This used to say "`!SawPhaseArm` covers it:
  // the position-aware stale-condition accept was cleared for PHASE arms only,
  // and a rotation arm is not one" — i.e. that a rotation arm DECLINES at P1.
  // The shipped fence reads `(SawValueArm || !(SawPhaseArm || SawRotationArm))`,
  // which is the OPPOSITE: it DEFERS for a rotation arm, exactly as bd drbq
  // Inc 3 widened it to (PRD §13.4b, the Grover-with-Ry-reflection customer).
  // Inc 4 DEPENDS on the shipped reading — a state prep sets this flag, and
  // `control_inplace_ry_stateprep_post_region_theta_cond.ll` accepts because of
  // it — so the stale sentence was an argument for reverting a fence that is
  // load-bearing two increments later.
  //
  // ⚠ IT MUST BE READ AT EVERY OTHER ACCEPT SITE, NOT JUST WRITTEN AT THIS ONE.
  // The rotation clause's own homogeneity test only fires when the rotation arm
  // is processed SECOND; a rotation arm FIRST followed by a phase/value/eq-fold
  // arm is the same mixture and has to decline on the same string. (Measured
  // during the Inc-1 build: with only the one-directional test, `if(c)
  // cq_theta(&r,·); else r=cq_phi(r,·)` declined — but on R6's
  // stale-record string, by luck, because the sibling arm's `cq_phi` is a
  // post-region user of the base. Luck is not a fence.)
  bool SawRotationArm = false;

  for (BasicBlock *ArmBB : Arms) {
    if (MergePhi->getBasicBlockIndex(ArmBB) < 0) {
      // Arm block does not feed the merge phi — off-pattern shape.
      declineArm(declAnchor(Region), "control flow");
      return ArmDisposition::Declined;
    }
    Value *ArmIncoming = MergePhi->getIncomingValueForBlock(ArmBB);
    Value *Base = walkPhaseSpine(ArmIncoming, ArmBB);

    // Every angle on a `cq_phi_<sfx>` arm spine (retired register form; null on
    // an accepted module) must be CLASSICAL — quantum data in the angle slot has
    // no fixed unitary (see taintedAngleGate; the 9hh §8 probe family).
    if (CallInst *Bad = taintedAngleGate(ArmIncoming, ArmBB, Base, Taint)) {
      declineArm(Bad, "rotation angle");
      return ArmDisposition::Declined;
    }

    // (Pre-3qlq register form.) A `cq_phi` surfaced as the in-block base was a
    // PRE-REGION rotation, the DERIVED handle `%qd = cq_phi(%q,·)`, accepted as a
    // legitimate base (test_C_libtooling-9hh, 2026-06-10) through the leaf paths
    // below; the arm-block-bounded walks kept the shared pre-region phi from being
    // double-erased (see [[swap-route-ifelse-derived-base-boundary]]). That
    // family now declines at `resolveSources`, so no such base reaches here.

    // issue a8c0 — straight-through const-fold re-anchor. When `clang -O1` folded
    // the diamond's straight-through (Pred-edge) incoming to a `ConstantInt` that
    // the branch PROVES equals this arm's routed qubit on that edge (pre-3qlq e.g.
    // `if (q != 0) q = cq_phi(q, θ)` folded the else edge to `0`), re-anchor both
    // `Routed` (so the `Base == Routed` gate below accepts) and `Region.RoutedBase`
    // (so `SwapRouteEmit::emitRegion` RAUWs the merge to the qubit, NOT the folded
    // constant — the same emitter re-anchor `tryEqFoldArm` uses). Strictly
    // additive: fires ONLY on the proven folded-constant diamond phase arm; a
    // compound condition, a value arm (`Base != H`), or an unproven edge miss and
    // fall through to the existing decline (Prime Directive).
    if (Value *H = straightThroughConstFoldHandle(Region, Routed, Base, Taint)) {
      Routed = H;
      Region.setRoutedBase(H);
    }

    // Phase spine bottoming at the routed handle: accept this arm. With no
    // `cq_phi_<sfx>` spine (retired) this is a GATE-FREE arm. The routed handle
    // MAY itself be a value DERIVED before the region (an earlier `add`/cast) —
    // only a value op ON THE ARM SPINE (i.e. Base != Routed) is a value arm.
    // Criterion 3: the routed handle must be a tainted quantum handle
    // (control_tainted_diag.ll's classical %y0 is not).
    if (Routed && Base == Routed) {
      // A phase arm in a region that already classified a VALUE arm (the
      // routed base was anchored by its chain): heterogeneous if/else —
      // declined before the per-arm checks (the mixture is the region-level
      // defect; PRD §0/§10). An EMPTY arm (incoming == Routed, no gates)
      // classifies as phase here, so `value-chain + empty arm` also declines
      // mixed — safe over-decline; a WI-5+ increment may refine it.
      if (SawValueArm || SawRotationArm) {
        declineArm(declAnchor(Region), "mixed phase/value arm");
        return ArmDisposition::Declined;
      }
      if (!Taint.Tainted.count(Base)) {
        declineArm(declAnchor(Region), "control flow");
        return ArmDisposition::Declined;
      }
      if (!armBlockIsPureSpine(ArmBB, ArmIncoming)) {
        declineArm(declAnchor(Region), "impure phase arm");
        return ArmDisposition::Declined;
      }
      // §2.6 — PHASE class on a rail: out of l4x4.b. A register-carrying
      // `cq_phi` spine no longer exists (3qlq Inc 1, owner decision D1) and the
      // register-free one is pre-peeled by `classifyPhaseKickback`, so this is
      // unreachable from C; it is written because the gate above is shared and a
      // class must never acquire an accept nobody cleared it for.
      if (RegCond)
        return declineRailClass();
      SawPhaseArm = true;
      continue;
    }

    // 4.5 WI-5: equality-folded `br` diamond. `clang -O1` const-folded the
    // `q==k`-true arm's (pre-3qlq register-form) gate to `cq_phi(i32 k, θ)`, so
    // `walkPhaseSpine` bottomed at the literal `k` (≠ Routed) and the arm would
    // decline `control flow`. `tryEqFoldArm` re-recognizes a `ConstantInt k` base
    // as a PHASE arm over the icmp's tainted operand and re-anchors `Routed`
    // (recording the handle in `Region.RoutedBase` for `emitRegion`'s merge RAUW).
    // STRICTLY ADDITIVE: it fires AFTER the `Base == Routed` gate (so a real
    // cross-handle mux still falls through to decline) and BEFORE the leaf-base
    // path; a miss returns false and leaves `Routed`/`Region` untouched.
    if (tryEqFoldArm(Region, ArmBB, ArmIncoming, Base, Routed, Taint)) {
      // drbq Inc 1 — homogeneity, the THIRD direction (see `SawRotationArm`).
      if (SawRotationArm) {
        declineArm(declAnchor(Region), "mixed phase/value arm");
        return ArmDisposition::Declined;
      }
      // §2.6 — EQ-FOLD class on a rail: out of l4x4.b. `tryEqFoldArm`'s D2/D8
      // polarity proof is written over an `ICmpInst` and its `straightThrough`
      // re-anchor reads a compare literal; neither has a rail analogue (a rail
      // branch DOES pin `b` on its edges, and building that re-anchor is a
      // separate increment — an unbuilt re-anchor can only OVER-decline).
      if (RegCond)
        return declineRailClass();
      SawPhaseArm = true;
      continue;
    }

    // ---- CONTROL-IN-PLACE ROTATION ARM (control-in-place-PRD §4 R1-R7, bd
    //      test_C_libtooling-drbq Inc 1) ------------------------------------
    //
    // A single tainted-operand `cq_theta` (Ry) is the whole arm. It is NEITHER a
    // phase arm NOR a value arm (Rule 7): the retired swap route could not carry
    // it, because `Ry(θ)|0⟩ ≠ |0⟩` leaves the INACTIVE work rail dirty and
    // entangled with the flag (Rules 6/8, PRD §2), and the value merge's copy
    // would copy a basis LABEL and dephase the superposition that IS the answer.
    // So it lowers CONTROL-IN-PLACE: the theta is hoisted to the pred and becomes
    // `cqrt_ry_<W>_controlled(flag, R, θ)` on the user's own register, with the
    // flag minted at the compare and stripped by the same `icmp_..._unc`.
    //
    // STRICTLY ADDITIVE, and the position is what makes it so. Every arm shape
    // this clause claims declines TODAY — a diamond theta arm falls through to
    // the closing `control flow`, an if/else theta arm to `impure phase arm`
    // (its `armBlockIsPureSpine` walks a spine of `cq_phi`s and finds a theta
    // instead) — so no accepted region can move. It sits AFTER `tryEqFoldArm`
    // (whose D2 needs a `ConstantInt` base and cannot fire on a theta) and
    // BEFORE the if/else leaf-anchor below, which would otherwise treat the
    // theta itself as the routed leaf.
    bool StatePrep = false;
    if (CallInst *T = inPlaceRotationArmTheta(ArmIncoming, ArmBB, MergePhi,
                                              Taint, StatePrep)) {
      // Homogeneity (R3): a rotation arm beside a phase or value arm has no
      // single lowering method — the same region-level defect the phase/value
      // mixture has, and the same string.
      if (SawPhaseArm || SawValueArm) {
        declineArm(declAnchor(Region), "mixed phase/value arm");
        return ArmDisposition::Declined;
      }
      // ---- l4x4.b — THE RAIL-ONLY SCOPE FENCE, asked FIRST among this class's
      //      clauses and guarded by `RailCond`, so a COMPARE region's message
      //      ordering is byte-identical to the pre-l4x4.b binary by construction
      //      (the Inc-4 `StatePrep` precedent).
      //
      // ---- (a) THE IN-LOOP CARVE-OUT IS RETIRED — bd `test_C_libtooling-wx8g`
      //      (l4x4.c), 2026-09-14. It stood here as
      //
      //          if (RailCond && Region.InLoop) decline("control flow inside a
      //                                                  loop body");
      //
      //      and it was an owner-scoped increment boundary, not a fence: l4x4.b
      //      recorded in writing that the shape "is NOT refused for any reason
      //      intrinsic to [it]", that `flatRegionRollableInLoop` has already
      //      proved the CFG half, and that R7's (b)/(b′) clauses below "would
      //      carry unchanged, since both are questions about the ROTATED
      //      register and neither mentions the condition". Its two stated
      //      reasons were VERIFICATION reasons, and both are now measured FALSE:
      //
      //      REASON 1 — "there is no oracle twin", because the COMPARE spelling
      //      of the program declines `condition predates a non-diagonal gate`
      //      (CLAUDE.md row W). That sentence is TRUE and it is about the WRONG
      //      TWIN. The shipped witness for every piece of in-loop work in this
      //      tree is ROLLED versus HAND-UNROLLED (`e2e-*-twin-identical`, 34
      //      gates), never rolled-versus-compare — and the hand-unrolled `_Bool`
      //      twin is exactly what l4x4.b itself shipped. MEASURED on the frozen
      //      2026-09-14 ORACLE (`cq-opt` f7b65d8c…, built from 59ac5b7), three
      //      pairs, plain C at `-O1`, traces byte-compared:
      //
      //        `for (k<2) if (b) cq_theta(&r,.2);`        rolled == unrolled
      //                                                       (8 trace lines)
      //        the same with `if (!b)` (Ry additivity)        == (10 lines)
      //        one bool-controlled Ry + S†/S per trip         == (12 lines)
      //
      //      (probes `w_a_carried_bool`, `w_a_neg`, `w_grover_bool` and their
      //      `_unrolled` twins, `$SES/trackW/probes/`). The third is the
      //      sentence CLAUDE.md records as compiling in no spelling anywhere.
      //
      //      REASON 2 — "it is the C-1 mixture", the loop-INVARIANT condition
      //      beside a loop-CARRIED rotated register whose leak signature is a
      //      per-trip condition chain the rolled form never discharges. TRUE of
      //      a COMPARE or DERIVED condition and VACUOUS for a rail, and the
      //      asymmetry is the whole argument: **a bare `_Bool` condition MINTS
      //      NOTHING AND DERIVES NOTHING**. `emitInPlaceRotationRegion` step 1
      //      hands the register itself to `cqrt_ry_<W>_controlled` as arg-0 and
      //      steps 3's strip+free are SKIPPED WHOLE (§2.7), so there is no
      //      ancilla, no `cq_template_*` rail and no `_unc` for the whole-DAG
      //      spine to place — which is what the C-1 family leaks. The condition
      //      register itself is left allocated (Rule 6: `Ry(θ)|0⟩ ≠ |0⟩`),
      //      rolled and unrolled alike, and `markIfRailLocal` exempts it at its
      //      "accumulating loop-invariant tainted input" clause because
      //      `invariantRegisterRoots` admits exactly a classical-arg-0
      //      `cq_theta` dominating the header — which a `_Bool` mint is — on
      //      BOTH halves of `collapseFlattenedLoopRails`' dispatch.
      //
      //      ⚠ THE GROUND OF THE RETIREMENT IS **NOT** "THE CONDITION MINTS
      //      NOTHING", AND THIS COMMENT SAID SO FOR ONE REVIEW ROUND (corrected
      //      after round 2, 2026-09-14). That sentence is TRUE — it survived
      //      every attack rounds 1 and 2 built, ten byte-identical twin pairs
      //      among them — and IT IS NOT WHAT MAKES THE RETIREMENT SAFE. Two
      //      measurements settle that:
      //        * REASON 2 was never the FIRST wall it was taken for. For
      //          `w2e3_xor_on_rotated.c` (an in-loop rail Ry arm followed by
      //          `cq_measure(r ^ 5)`) the pre-increment ORACLE declines EARLIER
      //          than this carve-out ever ran — at `declineStaleRecordOps`, with
      //          the SAME string and the SAME anchor as this binary. The
      //          carve-out was a SCOPE BOUNDARY standing in front of fences that
      //          were already doing the work.
      //        * The leak it was imagined to hold back is minted by the BODY,
      //          not by the condition, so NO property of the condition can bound
      //          it. That is precisely how F-W1-2 got through: a loop-CARRIED
      //          rail under a bare `_Bool`, granted by (b′), leaking one
      //          `cq_template_and_i32_hl_unc` + `cqrt_free` per activation while
      //          "the condition mints nothing" was still true of it.
      //      THE HONEST GROUND, AND THE ONE TO QUOTE: **THE FENCE IS THE MARKING
      //      POSTCONDITION, AND THE CONDITION KIND IS IRRELEVANT TO IT.** Every
      //      in-loop leak the body can mint is refused by
      //      `declineUnmarkedRolledIterLocal`'s conjunct 2 — asked of EVERY
      //      R7-loop grant, asking nothing whatever about the condition — and
      //      the condition-mints-nothing observation is then a REMARK about why
      //      the `_Bool` shape has little left to refuse, not a fence.
      //      Stated this way the retirement PREDICTS F-W1-2 (a grant clause with
      //      no record is a grant with no fence) instead of being falsified by
      //      it, which is the test a safety ground has to pass. ⚠ And read the
      //      scope exactly: conjunct 2 covers every **R7-loop** grant, which is
      //      a STRICT SUBSET of the region-independent leak class (F-W2-3; see
      //      `TaintSet::RolledLoopRegionGates`).
      //      ⚠ AND ITS PREMISE ("rolled leaks no more than its unrolled
      //      twin") IS MEASURED FALSE for a loop-carried MERGE rail (bd memory
      //      `r7-loop-grant-twin-parity-falsified-2026-10-15`: 6 vs 4 rails on
      //      `slice_control_cascade_loop_carried_handle`, since bd r2j3.32
      //      reverses the twin's). Conjunct 2 cannot see a merge rail; the
      //      leak is accepted and its dephasing composition is fenced loudly
      //      by `MergeCarriedFence.h` (see `declineUnmarkedRolledIterLocal`).
      //
      //      WHAT REPLACES IT: nothing here. The region falls through to R7's
      //      loop half below, which now has THREE clauses — (b)/(b′) for the
      //      loop-CARRIED rail and (c) for the ITERATION-LOCAL one — and which
      //      asks its questions about the rotated register without caring what
      //      kind of value the condition is, exactly as l4x4.b predicted. A rail
      //      region in a loop therefore declines with the SAME string it always
      //      had whenever the rotated register is unproven; what changed is that
      //      a PROVEN one no longer declines.
      // (b) ONE CONTENT ARM ONLY. A two-arm if/else on a rail needs anti-control
      //     on the `¬b` arm, and l4x4.b's answer to anti-control (Ry ADDITIVITY,
      //     `ry(h,θ); cry(h_b,h,−θ)` — see `emitInPlaceRotationRegion` step 2)
      //     was argued and pinned for ONE arm. Chaining it for two
      //     (`ry(h,B); cry(h_b,h,−B); cry(h_b,h,A)`) is a different emission
      //     order with a different M-β target and owes its own round. It is
      //     `kBareRailCondReason` because the refusal is about the condition kind.
      //     ⚠ REACHABLE FROM PLAIN C SINCE bd test_C_libtooling-fmt3 (2026-09-28).
      //     This used to say "UNREACHABLE FROM PLAIN C — `-O1` (SimplifyCFG)
      //     merges two rotation arms into ONE call with an ANGLE SELECT", and that
      //     stopped being true when `include/CQ.h` put `nomerge` on every
      //     `cq_theta_*`: `bool b = …; if (b) cq_theta(&r,A); else
      //     cq_theta(&r,B);` now arrives as this two-arm if/else and declines
      //     HERE (`fmt3_probes/src/n23.c`, measured) with the SAME string it got at
      //     `classifyAngleSelect`'s l4x4.a gate before — so the verdict and the
      //     diagnostic are unchanged; only the fence that speaks moved.
      //
      //     ⚠ RETIRED by bd dm7f.54. Neither spelling above was built: the two-arm
      //     rail region takes a CNOT COPY FLAG (`CondTreeEmit`'s `CopyRailRoot`,
      //     the r9e5 4.4-select flag) and the compare path's X-bracket form on
      //     it, `bf = cnot-copy(b); cry(bf,h,A); x(bf); cry(bf,h,B); x(bf);
      //     un-copy; free(bf)`, per `owner-ruling-angle-select-xbracket-
      //     2026-10-13` (each angle in one gate, no `cqrt_x` on the register).
      //     The M-β target is the compare path's (`Gates.back()`). Every other
      //     clause of this class runs unchanged for it; a two-PREP if/else still
      //     declines below (§14.2e, owner ruling Q4).
      // R2 — the angle is CLASSICAL (Rule 3). `taintedAngleGate` above walks a
      // `cq_phi` SPINE and never inspects a theta at the arm incoming, so this
      // is the check for this class; same predicate, same string as the phase
      // path's.
      if (rotationAngleIsTainted(T, Taint)) {
        declineArm(T, "rotation angle");
        return ArmDisposition::Declined;
      }
      // ---- l4x4.b — the ANTI-CONTROL angle must be NEGATABLE WITHOUT CREATING
      //      A SECOND READING OF ONE LITERAL. For a NEGATED rail arm the emitter
      //      emits the rotation twice — `ry(h, θ)` unconditionally and
      //      `cry(h_b, h, −θ)` to cancel it — so an `undef`/`poison` angle would
      //      occupy TWO emitted gate slots and be read as TWO DIFFERENT VALUES at
      //      the `-O0` stage 3 (bd `xy9n`, `LiteralIntegrity.cpp`): the cancelling
      //      gate would then not cancel, on the `b = 1` branch, verify-clean.
      //      `declineUnpairedUndefLiterals` would catch it module-wide at the very
      //      end, but that is a decline AFTER mutation — Rule 9 says detect
      //      first, and the reason belongs where the second slot is created.
      //      Asked with `valueCarriesUndef` (the shared spelling, Rule 14), and
      //      only for the negated rail shape: nothing else duplicates an angle.
      if (RegCond && Region.ArmNegated && !Region.ArmFalse &&
          valueCarriesUndef(T->getArgOperand(1))) {
        declineArm(T, "rotation angle");
        return ArmDisposition::Declined;
      }
      // ---- l4x4.b round-1 finding F-1 declined a non-finite CONSTANT angle here
      //      (the negated rail form emits `ry(h, θ); cry(h_b, h, −θ)`, so on the
      //      `b = 1` branch the source's identity was `Ry(+inf)·Ry(−inf)`). RETIRED
      //      by owner ruling 2026-10-13 (`owner-ruling-nonfinite-angle-identity`):
      //      a rotation by a non-finite angle is the IDENTITY (a backend
      //      contract), so that pair is `I·I` and the cancellation holds for every
      //      angle, finite or not, constant or run-time. Fixture:
      //      `control_inplace_ry_rail_negated_inf_angle.ll` (was `..._reject_...`).
      //      The `undef` clause above stays: an undef angle is not a value at
      //      all, and it would fill two slots read as two values (bd xy9n).
      // R7 — the ziov SHARED condition flag. On that path `emitRegion` SKIPS
      // the strip+free because a downstream data lineage owns the flag; the
      // flag is then a LIVE record of the pre-Ry condition past the region,
      // while this class relabels a register in place. Nothing proves those
      // compose, and Inc 1 was not cleared for it (the PRD defers it to Inc 2,
      // where the Rz path already handles sharing). Decline.
      if (Region.ShareCondFlag) {
        declineArm(declAnchor(Region), "rotation arm shares the condition flag");
        return ArmDisposition::Declined;
      }
      // R7 — an ANGLE φ region (the cwk classical-fp angle mux) carries a second
      // lowering the in-place emitter does not run. Defence in depth: no path
      // that populates `AnglePhi` reaches this classifier today.
      if (!Region.AnglePhi.empty() || !Region.AngleConsumers.empty()) {
        declineArm(declAnchor(Region), "control flow");
        return ArmDisposition::Declined;
      }
      Value *RotBase = T->getArgOperand(0);
      const bool PreallocatedBankSeed =
          isRailBankSeedAlloc(dyn_cast<CallInst>(RotBase));

      // ---- CONTROLLED STATE PREP (PRD §14, bd test_C_libtooling-drbq Inc 4) --
      //
      // The three state-prep-only clauses, asked HERE — after every clause that
      // already existed and BEFORE R3 — for two reasons. (i) Every one of them is
      // guarded by `StatePrep`, so a CHAINED arm's message ordering is
      // byte-identical to the pre-Inc-4 binary by construction (witnessed by the
      // whole-corpus lowered-IR sweep, not asserted). (ii) They run before R3 so
      // that the diagnostic NAMES THE SEED rather than saying `control flow`:
      // R3's `RotBase != Routed` would already refuse an F1 violation on a
      // diamond, BY ACCIDENT OF POINTER IDENTITY ON UNIQUED CONSTANTS, with no
      // comment saying so and no fixture pinning it (§14.2a item 1 — the
      // "passes for a reason nobody wrote down" shape). R3 keeps its own string
      // for the shape it is about, a cross-handle mux.
      if (StatePrep) {
        // ---- §14.2e — the IF/ELSE clause, an OWNER RULING spelled out.
        //
        // F1 below would already refuse an if/else, because an if/else merge φ
        // has NO Pred-edge incoming at all. That is a fence that fires through
        // ABSENCE, and a fence nobody can find is a fence a later widener
        // removes without noticing there was one (§14.12 worry 3). It is also
        // NOT redundant with R3: for two arms whose seeds are the SAME constant,
        // `Routed` is anchored by the first arm to that `Constant` and the
        // second arm's `RotBase` is the pointer-identical `Constant`, so
        // `RotBase != Routed` is FALSE and R3 passes (measured).
        //
        // ⚠ AND THE OWNER RULED THIS DECLINE ON A LOWERING THAT IS PHYSICALLY
        // CORRECT. With two prep arms M-β would chain the hoisted gates and emit
        // ONE rail carrying `alloc(SEED); cRy(f,A); x; cRy(f,B); x` — which IS
        // `if (c) r = Ry(SEED,A); else r = Ry(SEED,B);`. Nothing allocates two
        // rails except a reading in which SSA names are wires. The observation is
        // on the owner's desk as PRD §14.11 Q4; do NOT "fix" it here.
        //
        // ⚠ REACHABLE FROM PLAIN C SINCE bd test_C_libtooling-fmt3 (2026-09-28).
        // It used to be unreachable because `-O1` (SimplifyCFG) merged the two
        // arms into ONE theta with a tainted-condition ANGLE SELECT, which lands in
        // `classifyAngleSelect`: a LITERAL seed is refused at S3 (probe `p14a`,
        // `rotation angle`; control_angle_select_reject_state_prep.ll, PRD §14.11
        // Q5 / `drbq.13`), and since bd z0re (owner ruling 2026-09-28) a RUNTIME
        // seed is ADMITTED there and lowered by difference on ONE fresh rail —
        // `alloc(t); ry(h, B); ry_controlled(f, h, A−B)` — the one-rail reading
        // Q4 describes. With `nomerge` on every `cq_theta_*` (CQ.h) the IF/ELSE
        // spelling no longer folds and reaches HERE. ⚠ CORRECTED by bd dm7f.54
        // round-2 review (L7): it no longer simply "declines here". Since item B
        // (delegated ruling `ruling-dm7f54-literal-base-and-ifelse-prep-
        // 2026-10-15`, Q2) two prep arms with the IDENTICAL literal seed lower as
        // the one-rail stream, and F2 below decides: drbq.13's own counter-example
        // `if (t == 5) { r = t; cq_theta(&r,.9); } else { r = 5; cq_theta(&r,.3); }`
        // (GVN makes both seeds 5) ACCEPTS, because the register pinned to 5 is
        // the CONDITION'S OWN (`CondWire`, the owner-ruled α trade; review probe
        // revC54r2/p6), while fmt3's no-region member `n9.c`, whose pinned `sdiv
        // q, 4` is OFF the condition's wire, is refused by F2 on the true arm edge
        // (`control_inplace_ry_reject_stateprep_nomerge_noregion_pin.ll`, now F2's
        // string). The TERNARY spelling (`r = SEED; cq_theta(&r, c ? A : B)`)
        // reaches S3, which asks the same F2 exclusions (`f2ExcludedAtTest`) at the
        // consumer, so both spellings answer alike. Different seeds per arm, or a
        // runtime seed, keep Q4's decline (the string below).
        //
        // ⚠ THE STRING IS SPLIT BY WHAT THE OTHER ARM IS, ADDED 2026-09-05
        // (round-1 Rule-13 review, lens L7 finding F-L7-8, owner-approved in the
        // fix brief). "…allocates two rails" is TRUE OF ONE SHAPE — two prep arms
        // — and HEAD printed it for `..._ifelse_mixed_chained.ll` and
        // `..._ifelse_mixed_phase.ll`, neither of which has two preps: there the
        // defect is a MIXTURE (one arm mints a rail, the other rotates a live
        // register or applies a phase), not a double allocation. The other arm is
        // re-classified with the SAME predicate this clause is inside — never a
        // second spelling of "is that a prep?" — so the two cannot drift.
        //
        // ⚠ bd dm7f.54 (item B; delegated ruling `ruling-dm7f54-literal-base-
        // and-ifelse-prep-2026-10-15`, Q2): THE Q4 DECLINE MOVES. Two prep arms
        // with the IDENTICAL literal seed (`bool t = 0; if (q) cq_theta(&t, A);
        // else cq_theta(&t, B);`) lower as the ONE-rail stream the paragraph
        // above describes, byte-identical to the ternary
        // `cq_theta(&t, q ? A : B)`: M-β chains the second hoisted gate on the
        // first, so the first is the SOURCE theta (`cqrt_alloc_<W>(SEED)`) and
        // the stream is `alloc; ry_c(f,h,A); x(f); ry_c(f,h,B); x(f)`. F1 has no
        // subject (an if/else merge has no straight-through edge: one prep runs
        // on every path, so the merge is faithful by construction), and F2 is
        // asked below exactly as for a diamond — `f2SeedPinnedByLiveRegister`
        // walks BOTH successor edges of the branch, i.e. EACH ARM EDGE, and
        // refuses on the first collider on either (the L3 set over both arms),
        // with its sibling-tag L1 re-ask in `declineRound2QuantumPrepSeeds`.
        // `control_inplace_ry_reject_stateprep_nomerge_noregion_pin.ll` (the
        // drbq.13 `sdiv q, 4` under `(q & -4) == 20` fold, now unmerged) is
        // what F2 must still refuse on the TRUE arm edge. DIFFERENT seeds (or a
        // runtime seed) per arm stay loud with the Q4 string — filed.
        bool TwinLiteralPrep = false;
        if (Arms.size() > 1) {
          bool OtherIsPrep = false;
          for (BasicBlock *Other : Arms) {
            if (Other == ArmBB)
              continue;
            const int OIx = MergePhi->getBasicBlockIndex(Other);
            if (OIx < 0)
              continue;
            bool OSP = false;
            if (CallInst *OT = inPlaceRotationArmTheta(
                    MergePhi->getIncomingValue(unsigned(OIx)), Other, MergePhi,
                    Taint, OSP);
                OT && OSP) {
              OtherIsPrep = true;
              TwinLiteralPrep = Arms.size() == 2 &&
                                OT->getArgOperand(0) == RotBase &&
                                (isa<ConstantInt>(RotBase) ||
                                 isa<ConstantFP>(RotBase));
            }
          }
          if (!TwinLiteralPrep) {
            declineArm(declAnchor(Region),
                       OtherIsPrep
                           ? "if/else state prep allocates two rails"
                           : "if/else state prep beside a chained or phase arm");
            return ArmDisposition::Declined;
          }
        }

        // ---- F1 — SEED IDENTITY: the merge is FAITHFUL, not a data mux.
        //
        // PHYSICS (§14.1): on the `f=0` component the fresh rail is never
        // touched, so it holds |SEED>. The merge is therefore faithful IFF the
        // source's value on the straight-through edge IS the seed. Anything else
        // is a mux between a prepared rail and an unrelated value, which is a
        // DATA MUX and has no rotation-arm lowering.
        //
        // THE SEED MUST BE A `ConstantInt`, A `ConstantFP`, OR A RUNTIME SSA
        // VALUE (`isRuntimeStatePrepSeed`: an untainted `Instruction` or
        // `Argument`). The two CONSTANT exclusions have DIFFERENT reasons, so
        // neither may be dropped as "obviously covered by the other":
        //   * a `ConstantExpr` (or a `GlobalValue` address) is a LINK-TIME
        //     constant whose value this compiler CANNOT READ, so "the rail starts
        //     at |SEED>" is unverifiable — the Inc-2b round-2 finding, one family
        //     over;
        //   * `undef`/`poison` is the bd `xy9n` literal-integrity defect
        //     (`LiteralIntegrity.cpp`): a literal `undef` in two emitted gate
        //     slots is read as TWO DIFFERENT VALUES at the `-O0` stage 3, so the
        //     claim is not even well-formed. This is also the `-O1` shape of
        //     `int r; if (…) { r = 0; cq_theta(&r,θ); }` (probe `p11`), i.e. reachable.
        //
        // ---- THE RUNTIME SEED — bd `test_C_libtooling-z0re`, OWNER RULING
        //      2026-09-28, option (a); PRD §14.11 Q2 GRANTED (bd `drbq.14`).
        //
        // A function ARGUMENT, a load, a call result, a classical φ, a
        // `cq_measure` RESULT (a measurement is the taint SINK — Rule 3 — so its
        // value is classical feed-forward, exactly as for an UNCONDITIONAL
        // `int r = cq_measure(q0); cq_theta(&r, θ)`, which the oracle already lowers to
        // `cqrt_alloc_<W>(<measured value>)`): probe `p16` and the z0re battery.
        // Until 2026-09-28 it was refused by this very test and it was a FREE
        // widening — the clause below (the Pred incoming must be POINTER-IDENTICAL
        // to the seed) makes the merge faithful by SSA identity, and
        // `cqrt_alloc_<W>` takes a runtime value at every width F1's third clause
        // admits. The owner granted it so that the hand-inlined twin of bd z0re's
        // spec-classical side door (`int t = m + 1;` in place of a clone call)
        // ACCEPTS with the side door's circuit instead of declining here.
        //
        // WHAT A RUNTIME SEED OWES THAT A LITERAL DOES NOT, and where each is paid:
        //   * F2 — re-asked for a non-`Constant` seed as a RELATIONAL question
        //     (`f2SeedPinnedByLiveRegister`'s header, "THE RUNTIME SEED").
        //   * L1 — a literal can never turn quantum; a runtime seed derived from
        //     a 6.5/4.5 `%out` can, between this round-1 verdict and
        //     `lowerRotations`' FINAL-taint `Chained` decision. The emitter
        //     RECORDS it (`TaintSet::RuntimeSeedSourceThetas`) and
        //     `declineRound2QuantumPrepSeeds` re-asks it in BOTH entry points.
        //   * `-0.0` — the `Constant` spelling was "what makes `-0.0` a decline,
        //     because value identity on a UNIQUED constant already IS bit
        //     identity". For a runtime seed SSA IDENTITY does the same job one
        //     level up: the `f=0` component's rail holds whatever BITS the one
        //     SSA value carries at run time, and the straight-through edge
        //     carries THOSE SAME bits, so there is no second value to disagree
        //     with. (`-0.0` is simply not a compile-time fact here.)
        //
        // BIT IDENTITY, SPELLED AS BIT IDENTITY. `-0.0` vs `0.0` must decline and
        // is reachable from plain C in BOTH directions (probes `p07b`/`p07c`).
        // Pointer equality is correct here precisely because LLVM uniques
        // `ConstantInt` on type+bits and `ConstantFP` on the `APFloat` BITS — a
        // hand-written `APFloat` comparison would have to use `bitwiseIsEqual`
        // and NEVER `compare`/`==`, which calls `-0.0 == 0.0`.
        // The one non-literal seed is compiler-owned: an exact preallocated
        // runtime-i32 rail for a promoted bank cell. It is already |0>, and the
        // faithful merge below must name that SAME handle on the skipped edge.
        // No source value is inferred or cloned, so F2's folded-live-register
        // rival has no subject. (It is ALSO an untainted `Instruction`, so
        // `isRuntimeStatePrepSeed` would admit it on its own; the explicit
        // disjunct is kept so its F2 skip and its record exclusion below stay
        // keyed on the one predicate that names it, `isRailBankSeedAlloc`.)
        if (!PreallocatedBankSeed && !isa<ConstantInt>(RotBase) &&
            !isa<ConstantFP>(RotBase) &&
            !isRuntimeStatePrepSeed(RotBase, Taint)) {
          declineArm(T, "state prep seed does not match the merge incoming");
          return ArmDisposition::Declined;
        }
        // The Pred-edge incoming, read from the φ rather than from `Routed`, so
        // this clause does not inherit whatever an earlier re-anchor did to
        // `Routed`. (`straightThroughConstFoldHandle` CANNOT fire on a state-prep
        // arm — it needs the compare's tainted operand `H` to equal the arm's
        // spine `Base`, and `walkPhaseSpine` bottoms at the theta CALL, so
        // `H != Base`. Measured, and `tryEqFoldArm` misses for the mirror reason:
        // its D2 needs a `ConstantInt` base. The accept therefore rests on F2,
        // not on those two misses.)
        //
        // ⚠ THE STRING IS SPLIT BY THE INCOMING'S NATURE, ADDED 2026-09-05
        // (round-1 Rule-13 review, lens L5 finding F-L5-1). A TAINTED pred
        // incoming is not a "seed mismatch" at all — it is a NO-CLONING MUX
        // between a prepared rail and a LIVE QUANTUM REGISTER (Rule 8), and the
        // author's fix is not "make the straight-through value the seed". Worse,
        // the single string made the most ordinary R4 program a user writes
        //
        //     for (…) { if (a == 5) cq_theta(&a, .9); }   // Ry ON THE
        //                                                     // CONDITION REGISTER
        //
        // print `state prep seed does not match the merge incoming` for a source
        // that contains no state prep and no seed: BOTH exist only because
        // `clang -O1` substituted `5` for `a` on the proving edge. The verdict
        // was right (it declines on both binaries) and the words described the
        // IR rather than the program. Splitting costs one predicate and names the
        // physics on the half where the physics is the defect.
        const int PredIdx =
            Region.Pred ? MergePhi->getBasicBlockIndex(Region.Pred) : -1;
        if (!TwinLiteralPrep && (PredIdx < 0 ||
            MergePhi->getIncomingValue(unsigned(PredIdx)) != RotBase)) {
          Value *In =
              PredIdx < 0 ? nullptr : MergePhi->getIncomingValue(unsigned(PredIdx));
          declineArm(T, In && Taint.Tainted.count(In)
                            ? "state prep merged with a quantum register"
                            : "state prep seed does not match the merge incoming");
          return ArmDisposition::Declined;
        }
        // F1's THIRD clause. `lowerRotations` derives the alloc symbol's width
        // from the CALLEE NAME (`wd.abiWidthFor(suffixFromName(T, "cq_theta_"))`)
        // while the argument it passes is the seed's ACTUAL LLVM type; this is
        // where the two are reconciled.
        //
        // ⚠ CORRECTED 2026-09-05 (round-1 Rule-13 review, lens L1 finding
        // F-L1-1). IT IS REACHABLE AND IT IS LOAD-BEARING — the shipped record
        // (notes §8 F-3, PRD §14.4) called it "structurally unreachable, defence
        // in depth, no fixture can be written". Both halves of that were wrong:
        //
        //   * THE STATED MECHANISM IS WRONG. "The LLVM verifier forces a call's
        //     argument to match its callee's parameter type" is false — LLVM 19
        //     PARSES AND VERIFIES a call whose `FunctionType` differs from its
        //     callee's (measured, `opt -passes=verify` exit 0). What blocks THAT
        //     route is `CallBase::getCalledFunction()`, which returns null in
        //     exactly that case, so `isThetaCall` is false and no theta is seen.
        //   * THE REACHABLE ROUTE IS AN UNRECOGNIZED SUFFIX, and it is the
        //     sibling-spelling shape: `isThetaCall` is a bare NAME-PREFIX test
        //     (`starts_with("cq_theta_")`) while `resolveSources` — and therefore
        //     `declMatchesPrototype` — only ever visits `wd.allSuffixes()`. So
        //     `@cq_theta_si32x(i32 0, double)` IS a theta here and has NO width:
        //     `abiWidthFor("si32x")` is empty and `llvmWidthType("")` is null.
        //     Without this clause that module ACCEPTS (R3 passes by
        //     uniqued-constant identity, the `!StatePrep` taint check is skipped,
        //     R4/R6 are skipped, and the detection width gate asks a DIFFERENT
        //     derivation, `abiWidthFromType`, which answers `i32`), the emitter
        //     hoists and flattens, and `lowerRotations` NEVER LOWERS IT —
        //     `taint.ThetaCalls` is populated only from `ThetaFns` — leaving a
        //     standing `@cq_theta_si32x` inside a flattened region wrapped in a
        //     flag mint/strip/free around nothing.
        //
        // RED-GREEN: `control_inplace_ry_reject_stateprep_unrecognized_suffix.ll`
        // and its one-token accept twin `..._stateprep_suffix_control.ll`.
        // `WidthDispatch`'s constructor only reads the DataLayout's pointer size,
        // so building one here costs nothing.
        WidthDispatch WdLocal(*T->getModule());
        Type *SeedTy = WdLocal.llvmWidthType(
            WdLocal.abiWidthFor(suffixFromName(T, "cq_theta_")));
        if (!SeedTy || SeedTy != RotBase->getType()) {
          declineArm(T, "state prep seed does not match the merge incoming");
          return ArmDisposition::Declined;
        }

        // ---- F2 — THE EDGE-PINNED-SEED FENCE. SEMANTIC, ON BOTH EDGES.
        //
        // ⚠ REWRITTEN 2026-09-05 (round-3 Rule-13 review, lens R3, findings
        // F-R3-1 / F-R3-2 / F-R3-3 — 42 plain-C programs, all CONFIRMED-
        // MISCOMPILE). THE THREE SYNTACTIC GENERATIONS AND THEIR MEASURED
        // DEFEATS ARE IN `f2SeedPinnedByLiveRegister`'s OWN HEADER; read that
        // before touching this. In one line: F2 asks a SEMANTIC question —
        // "could the arm's constant seed be `-O1`'s fold of a live tainted
        // register the source rotated in place?" — and answering it by
        // enumerating a set of syntactic shapes lost three rounds running, each
        // time to a different InstCombine rewrite (the literal; then `H`'s edge
        // range, defeated by a DOWNWARD rewrite onto an ancestor; then `H`'s
        // forward closure, defeated by a SIDEWAYS rewrite onto a sibling, by the
        // curated `llvm.*` rail family, and by the type gate that used to stand
        // one line below this comment).
        //
        // WHAT IS ASKED NOW: for BOTH edges of this region's branch, is ANY live
        // TAINTED value of the SEED'S TYPE provably equal to the seed? — answered
        // by `LazyValueInfo` on the edge (the BACKWARD direction, by a real edge
        // analysis rather than a preimage table) plus an abstract evaluation
        // forward over the tainted user graph (`ConstantRange` +
        // `ConstantFolding` + `KnownBits`, i.e. LLVM's own constant machinery,
        // with a conservative DECLINE wherever a pinned operand feeds something
        // that machinery cannot evaluate).
        //
        // STILL POLARITY-FREE: both edges are asked and either one declines, so
        // there is no edge to get backwards. (`tryEqFoldArm`'s D8 and
        // `straightThroughConstFoldHandle`'s `StraightProvesEq` each DO carry a
        // polarity test because each RE-ANCHORS onto a specific edge; F2 only
        // REFUSES.)
        //
        // NO TYPE GATE. The shipped `K->getType() == SeedI->getType()`
        // precondition skipped ALL of F2 whenever `-O1` narrowed the compare to
        // the taint root's width — which is what an ordinary `long long t = q;`
        // does — and F-R3-2 measured 8 plain-C accepts through it, each with the
        // CAST RAIL live, measured and unrotated. It is gone from the semantic
        // path; the fast path below keeps it because an `APInt` comparison needs
        // it, not because it discriminates anything.
        //
        // ⚠ AND THE OLD RATIONALE FOR IT IS RETIRED WITH IT (F-R3-7 item 1).
        // "A cast of `H` is a DIFFERENT PHYSICAL WIRE, so following casts would
        // be a pure over-decline" is true about wires and FALSE as a licence:
        // the cast rail being a different wire is exactly why preparing a THIRD
        // wire is wrong when the source rotates the second one and then reads
        // it. What actually separates the accept from the miscompile is not the
        // type at all — it is whether that other wire EXISTS in the module.
        // `..._stateprep_cond_cast_seed.ll` and `..._cond_bitcast_seed.ll` still
        // ACCEPT because `-O1` folded their cast away entirely and no `sext` /
        // `bitcast` instruction survives to be asked about; `g03_ll_eq5.c`
        // declines because its `sext` is live and MEASURED. The fence asks about
        // values that are IN THE FUNCTION, which is the honest form of that
        // distinction.
        //
        // MONOTONE: this block only ever DECLINES, so a range that is too WIDE
        // loses a decline (the residual, PRD §14.2b / §14.11 Q3 and notes §12)
        // and a range that is too NARROW — or a bound that trips — costs an
        // over-decline. Neither direction can turn a decline into an accept.
        // That is also why `computeKnownBits`' modulo-poison guarantee
        // (`PoisonFacts.h`) is admissible here where `QramLowering` had to refuse
        // it: a poison-derived "singleton" costs a decline, never a gate.
        //
        // fp CONDITIONS DO REACH A CLAUSE HERE, and this paragraph used to say
        // the opposite and to carry a FALSE retirement trigger — ⚠ CORRECTED
        // 2026-09-05 (round-4 Rule-13 review, lens R4, finding F-R4-1).
        //
        // WHAT WAS WRONG. The old text read: "RETIREMENT TRIGGER: if LLVM ever
        // gains an `oeq`-edge substitution, LVI gains it at the same moment and
        // this clause needs no change." Both halves are false.
        // `LazyValueInfo::getConstantRangeOnEdge` is defined over
        // `ConstantRange` — an INTEGER lattice — so LVI cannot acquire an fp
        // edge fact in a form F2 could consume, and F2's anchor list never
        // offered it an fp value anyway (`isIntegerTy()`-gated). As written the
        // trigger would let a future widener read "already covered" and ship.
        // R4 MEASURED the consequence: `hf01_fcmp_folded.ll` — a live f64 `%t`
        // pinned to 5.0 by the region's own `fcmp oeq`, seed 5.0, `%t` measured
        // UNROTATED — ACCEPTED, against an unconditional twin (`hf04`) that is
        // byte-identical on both binaries and rotates `%t` in place.
        //
        // WHAT IS TRUE NOW. The fp CONDITION side is covered by the fp ANCHOR in
        // `f2SeedPinnedByLiveRegister`'s edge loop (an equality `fcmp` against a
        // `ConstantFP` pins its tainted operand on the edge where the equality
        // holds; ±0.0 and NaN constants are refused, with the reason written
        // there), and the fp SEED side stays covered by `Constant *` identity
        // plus the exact fold (an `sitofp` of a pinned INTEGER folds exactly —
        // `..._reject_stateprep_fp_seed_sitofp.ll`).
        // `..._reject_stateprep_fcmp_oeq_folded.ll` is the anchor's red-green
        // decline; `..._reject_stateprep_fcmp_oeq_unfolded.ll` stays the control
        // for the shape `clang -O1` ACTUALLY produces, which is unchanged: at
        // LLVM 19 `propagateEquality` will NOT substitute across `fcmp oeq`
        // (`+0.0 == -0.0`), and `EarlyCSE` runs before `IPSCCP` so a pre-branch
        // fp derivation is CSE'd and `PredicateInfo` has nothing to rename (R4
        // measured seven `-O1` IR dumps, `p/fp01`-`fp12`). So the anchor is a
        // fence for a fold this clang does not perform — which is the correct
        // posture for a fence, and the REAL retirement trigger is now: if LLVM
        // gains that substitution, this clause already asks the question, but
        // its ±0.0 and NaN refusals must be RE-MEASURED against whatever
        // equality LLVM actually chose to propagate.
        //
        // ONE COMPARE, NO LEAF WALK — because a compound `&&`/`||` condition
        // reaches NO control accept path (`classifyArms` refuses a non-`CmpInst`
        // condition above, measured `prd/ir/q12`). RETIREMENT TRIGGER, written
        // now rather than discovered later (the bd 8h7d.5 F-1/F-3 discipline):
        // the day compound conditions are admitted to ANY control accept path,
        // the LVI half already handles them (it reads the BRANCH, not the
        // compare), but the (a) fast path did not — "delete it rather than
        // extend it" was this trigger's instruction.
        // ✅ **THAT HALF IS DISCHARGED**: the (a) fast path was DELETED on
        // 2026-09-11 for an unrelated reason (the `CondWire` narrowing made it
        // dead), so a compound condition would now meet only the LVI + forward
        // machinery, which reads the branch. ⚠ THE TRIGGER IS NOT FULLY SPENT:
        // `CondWire` is seeded from `Region.Condition` and `condProvenance` of
        // it, and for a compound condition "the condition's wire" has to mean
        // the union over the tree's LEAVES. Nothing here computes that, and no
        // fixture could be written for it today because the shape declines
        // upstream. Whoever admits compound conditions owes this clause a fresh
        // red-green family, not an assumption that it already works.
        //
        // SECOND RETIREMENT TRIGGER (L2 F-L2-6): an `__builtin_assume(q == 0)`-
        // folded seed is refused today only by `declineTaintEscapes` treating
        // `llvm.assume` as an unknown callee. F2 now DOES carry an
        // `AssumptionCache` (LVI needs one), so the day `llvm.assume` is
        // whitelisted this clause sees the fold for free — but it still owes a
        // fresh red-green family, because "for free" is a prediction until it is
        // measured.
        // ---- THE 2026-09-11 NARROWING (owner ruling; bd `drbq.14`) ----
        //
        // ⚠ THE PLAIN-LITERAL FAST PATH THAT STOOD HERE IS **DELETED**, NOT
        // LEFT TO ROT, AND ITS ARGUMENT IS RETIRED WITH IT RATHER THAN
        // SILENTLY DROPPED. It read `dyn_cast<ICmpInst>(Region.Condition)`,
        // took the compare's constant `K` and its other operand `H`, and set
        // `Pinned` on `K == Seed` with NO analysis at all — kept deliberately
        // as an analysis-free backstop ("if a future LLVM weakens
        // `LazyValueInfo`, the A1/A2 family must still decline").
        //
        // IT IS NOW DEAD BY CONSTRUCTION, WHICH IS WHY IT MUST GO: `H` is the
        // compare's own operand, hence unconditionally a member of `CondWire`
        // below, so the fast path would assert exactly the decline the
        // narrowing removes — `..._eqfold_coincidence{,_ne}.ll`, the two
        // fixtures that pinned it, are two of the nineteen the owner ruled must
        // now ACCEPT. Keeping it "just in case" would make the narrowing a
        // no-op for the commonest shape the ruling is about. The backstop
        // argument is gone with it: a future LLVM that weakens LVI costs
        // over-ACCEPTS here, and the answer to that is a fresh fence, not a
        // literal test that now contradicts the ruling. Measured proof that it
        // was load-bearing before and is inert after: with the conjunct absent
        // AND this path deleted, the `eqfold_*` family goes RED (IMPL §2).
        //
        // `CondWire` — the set the test excludes. Built by CALLING R4's own
        // `railWireClosure` on the same seeds R4 uses (`Region.Condition`, then
        // every member of `Prov` = `condProvenance(Region.Condition)`), so the
        // two fences cannot drift on what "the condition's wire" means (Rule
        // 14). ⚠ `railWireClosure(Region.Condition, …)` contributes EXACTLY ONE
        // element — a `CmpInst` is not a `BinaryOperator`, so the dispatch
        // inserts it and falls off the end — which is why the `Prov` LOOP is
        // the whole condition reach here just as it is at R4 (see R4's own
        // note).
        //
        // ⚠ BUT THE LOOP IS **NOT** THE SAME AS `Prov` ITSELF, AND THE SCOPING
        // NOTE THAT SAID SO WAS WRONG (measured 2026-09-11, IMPL §2c). The
        // argument "every backward rail hop is also an operand edge, so the
        // union IS `{Cond} ∪ condProvenance(Cond)`" holds for every hop EXCEPT
        // one: `condProvenance` stops at a theta (`if (isThetaCall(I))
        // continue;` — it collects the RESULT and deliberately does not enter
        // arg-0, so it cannot walk into a source theta's classical seed), while
        // `railWireClosure` CROSSES a chained theta's arg-0 because a chained Ry
        // is in place and the two names are ONE physical rail. So this loop is a
        // strict superset, by exactly the chained-theta ancestry. MEASURED: a
        // mutant building `CondWire` as `{Region.Condition} ∪ Prov` moves ONE
        // module in the whole tree —
        // `control_inplace_ry_stateprep_condwire_alias_accept.ll`, which is
        // committed for this reason — and leaves the rest of the state-prep
        // family's 53/56 split untouched. Deleting either call is therefore a
        // measurable behaviour change, not a simplification.
        //
        // It is BackwardOnly for R4's reason and for a second one that
        // is specific to F2: `BothWays` would sweep in every FORWARD user of
        // the condition's registers, i.e. exactly the F-R1-1 six, the sideways
        // pair, the casts, the curated intrinsics and the `sitofp` — all 21
        // recorded CONFIRMED miscompiles (SCOPE H-3).
        //
        // COMPUTED UNCONDITIONALLY (not inside `if (Pinned)`) and only in this
        // state-prep block, so no accepting path pays for it.
        bool Pinned = false;
        bool Truncated = false;
        SmallPtrSet<Value *, 16> CondWire;
        railWireClosure(Region.Condition, Taint, WireDir::BackwardOnly, nullptr,
                        nullptr, CondWire);
        for (Value *P : Prov)
          railWireClosure(P, Taint, WireDir::BackwardOnly, nullptr, nullptr,
                          CondWire);
        // THE SEMANTIC TEST. Asked of every tainted value of the function, on
        // both edges, with no gate on the condition's own shape — `Truncated`
        // reports an evaluation that could not be completed and declines with
        // the same string, because a search that stopped looking is exactly the
        // "we stopped and accepted" shape this fence exists to stop. (`Truncated`
        // is NOT narrowed by `CondWire`; SCOPE H-8.)
        //
        // bd `test_C_libtooling-z0re`: the seed is handed over as a `Value *`
        // (it was `cast<Constant>` while F1 admitted literals only). A RUNTIME
        // seed takes F2's RELATIONAL branch — the same function, the same
        // candidate list, the same three exclusions at the same TEST — whose
        // argument is in `f2SeedPinnedByLiveRegister`'s header ("THE RUNTIME
        // SEED"); a literal takes the constant-fold path byte-for-byte as before.
        Value *PinnedBy = nullptr;
        if (!PreallocatedBankSeed)
          Pinned = f2SeedPinnedByLiveRegister(Region, RotBase, Taint, DT,
                                              CondWire, Truncated, &PinnedBy) ||
                   Truncated;
        // R11 round 1 (A-F2): under a REGISTER CONDITION (dm7f.77) the pinning
        // register is not the condition — `t ^= a; if (t) prep b; c = t & d`
        // pins b's seed with `t & d` (review_s2A/p3.c) — so the string says
        // so. Every shipped F2 decline (61 fixtures, whose wording reads "the
        // condition register" for any register the condition pins) keeps its
        // string byte for byte. The admission itself is filed (dm7f.51.5).
        if (Pinned) {
          declineArm(declAnchor(Region),
                     PinnedBy && PinnedBy != Region.Condition &&
                             isRegCondLeaf(Region.Condition)
                         ? "state prep seed is proven equal to a live register "
                           "other than the condition"
                         : "state prep seed is proven equal to the condition "
                           "register");
          return ArmDisposition::Declined;
        }
      }

      // R3 — ONE base. A diamond's straight-through incoming IS the base; an
      // if/else anchors it on the first arm and the second must match. A
      // mismatch is a cross-handle multiplexer, not a rotation arm.
      if (Routed && RotBase != Routed) {
        declineArm(declAnchor(Region), "control flow");
        return ArmDisposition::Declined;
      }
      // ⚠ NO LONGER STRUCTURALLY UNREACHABLE — Inc 4 MADE IT REACHABLE, and
      // re-scoping it rather than deleting it is the whole point (PRD §14.4).
      // Until Inc 4 `inPlaceRotationArmTheta` required a TAINTED arg-0, so this
      // was defence in depth against a fall-through to a controlled rotation on
      // an untainted value; the round-1 Inc-1 review recorded it in place so
      // nobody would try to write a fixture nobody could write. A controlled
      // STATE PREP is exactly that untainted arg-0, ARRIVING DELIBERATELY — so
      // the check is now asked of the CHAINED class only, and the state-prep
      // class discharges the same obligation ABOVE, with a better string
      // (F1's `isa<ConstantInt>` / `isa<ConstantFP>` test, which is strictly
      // stronger than "untainted"). Deleting it silently is how a decline turns
      // into a fall-through.
      if (!StatePrep && !Taint.Tainted.count(RotBase)) {
        declineArm(declAnchor(Region), "control flow");
        return ArmDisposition::Declined;
      }
      // The ABI width must have a `cqrt_ry_<W>_controlled`. Checked HERE, in
      // DETECTION, because `lowerRotations` runs after the emitter has already
      // hoisted the theta and `RegionFlatten` has erased the diamond — a
      // decline there would be a decline after mutation (Rule 9).
      if (!abiWidthHasControlledRotation(abiWidthFromType(T->getType()))) {
        declineArm(T, "controlled rotation width");
        return ArmDisposition::Declined;
      }
      // R4 — DISJOINT PHYSICAL WIRES, the flag-strip's whole premise (PRD §3).
      // The strip `icmp_..._unc` recomputes the predicate on the condition's
      // registers and XORs it back onto the flag; that returns the flag to |0⟩
      // ONLY IF those registers still hold the basis the forward mint read. Rz
      // is diagonal so a phase arm may rotate a condition register freely (why
      // S8 accepts); an in-place Ry RELABELS it, and then the strip is not a
      // function of the source's condition. Since bd dm7f.4 the arm whose
      // register IS in the condition's provenance lowers WITHOUT a strip (the
      // flag is kept, see the clause at the intersection below); every other
      // overlap still declines.
      //
      // "Same wire" is a RAIL question, not an SSA one — see `railWireClosure`
      // for each admitted hop and for the deliberate over-approximation.
      //
      // ONE WALK, derived twice (finding J). `BaseWire` is the base's FULL
      // member set and is the SAME object R6 enumerates below, so R4 and R6
      // cannot drift on what "this wire" means. The CONDITION side stays
      // BACKWARD-ONLY on purpose and it costs nothing: two names of one wire
      // share a root, so a base member that is on the condition's wire is
      // already in the condition's backward closure. The forward half exists for
      // R6's user enumeration, which the condition side does not do.
      //
      // ⚠ THE `Prov` LOOP BELOW IS THE WHOLE CONDITION SIDE, AND THE
      // `Region.Condition` SEED CONTRIBUTES EXACTLY ONE ELEMENT (round-1 review
      // L1 §2, recorded because it is invisible and load-bearing). A `CmpInst`
      // is NOT a `BinaryOperator` in LLVM — it derives from `Instruction`
      // directly — so `railWireClosure`'s dispatch inserts the compare and falls
      // off the end without ever looking at its operands. R4's entire condition
      // reach is therefore `⋃_{P ∈ Prov} backwardClosure(P)`, and R4 is only as
      // complete as `condProvenance`'s backward operand cone.
      // NARROWING `condProvenance` IS A RULE-13 CHANGE TO R4: a "tidy-up" that
      // seeded only the compare's direct operands, or that stopped the cone at a
      // template producer the way this closure does, would make R4 VACUOUS with
      // every fixture still green (all four measured R4 declines reach through
      // `Prov`, none through the `Region.Condition` seed).
      const BasicBlock *ArmA = Region.Arm;
      const BasicBlock *ArmB = Region.ArmFalse;
      SmallPtrSet<Value *, 16> CondRails;
      SmallPtrSet<Value *, 16> BaseWire;
      SmallVector<Value *, 16> BaseWireOrder;
      // ⚠ R4 AND R6 ARE **SKIPPED** FOR A CONTROLLED STATE PREP — SKIPPED, NOT
      // HANDED AN EMPTY CLOSURE — AND THE DIFFERENCE IS MEASURED, NOT
      // STYLISTIC (PRD §14.5's trap; probe `q31`, pinned by
      // control_inplace_ry_stateprep_seed_other_users.ll).
      //
      // WHY THEY ARE VACUOUS, structurally rather than by a proof about the
      // program: the rotated rail is minted by the hoisted `T` ITSELF, so NO
      // PRE-REGION SSA NAME FOR IT EXISTS. There is no wire to intersect with the
      // condition's (R4) and no record that could be read after the region (R6);
      // every SSA name for the rail after the region is `T`'s result, which is
      // the POST-gate name by construction. The Inc-1 finding-K launder (a
      // classical join φ RAUW'd to the base by `liftOneRegisterMergePhi`) cannot
      // reach a name that does not exist. That also discharges R4's obligation
      // for the flag strip: the strip recomputes the predicate over the
      // condition's registers, and the prepped rail is disjoint from all of them
      // BY CONSTRUCTION — the one place Inc 4 is easier than Inc 1, not harder.
      //
      // WHY "PASS IT AN EMPTY SET" IS THE WRONG SPELLING: `railWireClosure` does
      // `Out.insert(W)` BEFORE its taint gate, so
      // `railWireClosure(ConstantInt 0, BothWays, …)` returns
      // `BaseWire = BaseWireOrder = { i32 0 }` — NOT empty. And an LLVM
      // `ConstantInt` is uniqued per `LLVMContext`, so its use list spans the
      // whole module: R6 would enumerate the literal's users, find an unrelated
      // `int z = 0; cq_theta(&z, ·)` sitting AFTER the region, fail `provablyBefore` on it,
      // and decline `stale rail record read past a controlled Ry` on a program
      // with no record at all. (Users in OTHER functions are skipped only because
      // `DT->isReachableFromEntry` returns false for a foreign block — i.e. by
      // accident of a guard written for a different purpose.) ⚠ bd z0re: a
      // RUNTIME seed makes the same point without the uniquing: `{ %s }` would
      // enumerate every CLASSICAL read of `s` after the region (`printf(s)`,
      // `return s + …`) as a "stale record" of a rail it never was — the skip
      // is what keeps those classical reads legal. R4 has the mirror
      // hazard in the harmless direction: a degenerate `cq_phi(0, θ)` on the
      // condition's provenance can put a `Constant` into `CondRails` (see
      // `railWireClosure`'s own comment), so R4 would decline on a literal
      // coincidence.
      //
      // R7's LOOP half below is deliberately NOT skipped, and WHAT IT DOES WITH
      // AN EMPTY `BaseWireOrder` CHANGED ON 2026-09-14 (bd
      // `test_C_libtooling-wx8g`). Until then it iterated `BaseWireOrder`, found
      // nothing, and every in-loop state prep declined `control flow inside a
      // loop body` — the ITERATION-LOCAL spelling (PRD §14.3 row L-2). Clause
      // (c) now asks the question this class CAN answer: the rail is minted by
      // the HOISTED `T` ITSELF, so (c2) is asked with `MintSeed = T` rather than
      // with `RotBase`, and an in-loop prep whose alloc repeats per activation
      // lowers ROLLED. The LOOP-CARRIED spelling (`int r = 0;` outside the loop)
      // still never gets here at all: its merge pred incoming is the loop's
      // header φ, so F1 killed it above as a data mux. "In-loop state prep"
      // sounds like one thing and is two; now one of the two lowers.
      if (!StatePrep) {
        railWireClosure(Region.Condition, Taint, WireDir::BackwardOnly, nullptr,
                        nullptr, CondRails);
        for (Value *P : Prov)
          railWireClosure(P, Taint, WireDir::BackwardOnly, nullptr, nullptr,
                          CondRails);
        railWireClosure(RotBase, Taint, WireDir::BothWays, ArmA, ArmB, BaseWire,
                        &BaseWireOrder, /*Exclude=*/MergePhi);
        // ---- bd `test_C_libtooling-dm7f.4` (owner ruling 2026-10-03, option
        //      (a)) — THE ARM ROTATES THE REGISTER THE CONDITION READS.
        //
        // `if (q > 5) cq_theta(&q, θ)`. The premise above fails BY CONSTRUCTION:
        // after the Ry the predicate is no longer a function of `q`'s basis, so
        // no strip can return the flag to |0>. That is a fact about the STRIP,
        // not about the program (CLAUDE.md L5): the circuit
        //     f = C(q) ; [x(f)] cRy(f, q, θ) [x(f)]          (f never stripped)
        // realizes the source on every basis branch, with the which-branch
        // record `f` left entangled. So the region LOWERS, the emitter skips
        // its strip and free (`ControlRegion::CondFlagKept`), the flag stays
        // allocated (R5: never freed, it is not provably |0>), and M-A's
        // `warnLiveRecordRotations` reports the record as a `DS_Warning` at the
        // gate (owner ruling lyyf: the leftover entanglement is the user's).
        // No measurement is inserted. Why each earlier premise still holds:
        //   * ARM SELECTION. The mint reads the pre-Ry basis: the wire gate
        //     above returned `ProvenPostRegion`, so no gate on this wire runs
        //     between the compare and the branch, and the emitter puts the mint
        //     BEFORE the hoisted gate. The `CmpCondRead` the mint records is
        //     re-asked at FINAL taint in both entry points (L1); the hoisted
        //     gate is visible taint-blind there and stays exempt.
        //   * THE CONDITION'S CHAIN is the uncompute spine's. A template chain
        //     (`(q & 3) == 1`, `sitofp`/`fmul`/`fcmp`, an `add` range test) is
        //     discharged by M-B right after the mint, before the gate, while
        //     `q` is unmoved. A chain rail the PROGRAM reads after the gate
        //     (`int d = q & 6; … cq_measure(d * 5)`) cannot be: its borrowed
        //     parent is moved by a `_controlled` Ry, which
        //     `preservesBorrowedParent` refuses, so it stays allocated as the
        //     program's own data (and, when it is the compare's operand, the
        //     flag is then stripped against it after the gate: round 2, F-A,
        //     below). ⚠ NOT EVERY CHAIN IS DISCHARGED, and this
        //     comment said so in 03d9ca8a: a LIFTED CALL's `__cq_q_*` result
        //     is never an interior producer (bd ln16), so `h(q) > 13` left an
        //     injective record of `q` live at the gate, a wrong unitary (review
        //     round 1, F1). That is now refused LOUDLY, after the spine has
        //     placed its discharges, by `declineUndischargedKeptFlagChains`
        //     (RotationLowering.h): every chain record but the flag must be
        //     gone or observed at the gate, asked with M-A's own predicates
        //     (control_inplace_ry_reject_cond_register_lifted_chain.ll).
        //   * STALE READS of the pre-Ry `q` after the region are R6's, below,
        //     unchanged.
        //   * NEGATION. The flag is a minted ANCILLA, so the else arm keeps the
        //     compare path's `cqrt_x(f)` bracket; nothing but the controlled Ry
        //     touches the user's register.
        // THE ACCEPT IS THREE CONJUNCTS; each miss keeps R4's decline:
        //   (K1) `!RailCond`. A `_Bool` rail IS the flag, so `cRy(b, b, θ)`
        //        would control a gate on its own target. That spelling needs a
        //        CNOT copy into a fresh flag and is not built. (Unreachable
        //        today: the rail ladder's rung (iii) refuses it earlier,
        //        control_inplace_ry_reject_rail_cond_wire.ll.)
        //   (K2) `!Region.InLoop`. A rolled region would keep one flag per
        //        trip; the R7 loop clauses and the marking postcondition were
        //        never argued for a kept flag
        //        (control_inplace_ry_reject_inloop_cond_register.ll). Measured
        //        with K2 dropped (mutant, 2026-10-05): that fixture lowers
        //        rolled, `icmp_sgt_hl` + `ry_i32_controlled` per trip, no strip,
        //        one M-A warning. Plausible, unreviewed; the loop owner's call.
        //   (K3) `Prov.count(RotBase)`: the rotated register is itself in the
        //        condition's tainted provenance (`condProvenance`, R4's own
        //        cone). An overlap reached only through `railWireClosure`'s
        //        add/sub/xor hops (`int b = q ^ 2; if (q > 5) cq_theta(&b, θ)`)
        //        rests on whether M-C later lowers that op in place, which
        //        detection cannot see; it keeps R4's own string
        //        (control_inplace_ry_reject_inplace_alias_base.ll).
        // Monotone across the two detection rounds: round-2 taint only grows
        // `Prov`, and a kept flag is never a dirty free.
        // RETIREMENT TRIGGER: the emitter's step-3 skip, its `cq.keptflag` tag
        // on the mint, and the absence of a `DischargedFlagGates` record are
        // this verdict's only consumers. A new consumer of "this region's flag
        // is stripped" must read the field.
        //
        // ---- REVIEW ROUND 2 (F-A): KEEP THE FLAG ONLY WHEN THE STRIP IS
        //      IMPOSSIBLE. The ruling keeps the flag BECAUSE it cannot be
        //      uncomputed. That holds when a tainted compare operand is on the
        //      rotated wire (`q > 5`), or is a temporary nothing reads after the
        //      region (`(q & 3) == 1`): the spine then discharges it before the
        //      gate, so nothing is left to recompute the predicate from. It
        //      FAILS when every tainted operand is a record the program reads
        //      after the region (`int d = q & 6; if (d == 2) …; … d …`): that
        //      rail is off the rotated wire, unchanged by the stream (mint,
        //      gate, `x` brackets on the flag), and still live after the gate,
        //      so the strip there is exact. Keeping the flag would add a
        //      `[d == 2]` record the source does not have, and a later Ry on `d`
        //      would then lose the coherence between the two branches
        //      (MEASURED wrong stream, `int d = q & 6; if (d == 2)
        //      cq_theta(&q,.9); cq_theta(&d,.4);`; pinned by
        //      control_inplace_ry_cond_register_strip_observed.ll). So that case
        //      strips and frees after the gate, as the disjoint path does.
        //      "Read after" = a user other than the compare that is not
        //      `provablyBefore` the branch. A wrong "yes" only strips a flag whose
        //      operand then stands unobserved at the gate, which the late chain
        //      check refuses loudly; a "no" is impossible for a live operand.
        for (Value *B : BaseWireOrder)
          if (CondRails.count(B)) {
            // (K4, bd dm7f.52) `Cmp` — the condition is a single COMPARE. A
            // compound tree on the rotated register (`if (a ^ t) cq_theta(&a,
            // θ)`, `if (a & b) cq_theta(&b, θ)`) is NOT admitted here: no kept
            // tree flag was argued, and stripping a tree whose leaf the gate just
            // rotated would free a dirty ancilla (a hidden measurement, R5). It
            // keeps R4's loud string below; bd dm7f.51 / dm7f.9 own the lowering.
            // A `dyn_cast`, never a `cast`: a Release build has no assert, so a
            // `cast` of a tree root here was UB (dm7f.51 design review).
            auto *Cmp = dyn_cast<CmpInst>(Region.Condition);
            if (Cmp && !RailCond && !CondIsTree && !Region.InLoop &&
                Prov.count(RotBase)) {
              const Instruction *Br = Region.Pred->getTerminator();
              bool StripExact = DT != nullptr;
              for (Value *Op : Cmp->operands()) {
                if (!StripExact)
                  break;
                if (!Taint.Tainted.count(Op))
                  continue;  // a classical operand: the strip reads it as is.
                if (BaseWire.count(Op)) {
                  StripExact = false;  // the rotated wire itself.
                  break;
                }
                bool ReadAfter = false;
                for (User *U : Op->users()) {
                  auto *UI = dyn_cast<Instruction>(U);
                  if (UI && UI != Cmp && !provablyBefore(UI, Br, *DT)) {
                    ReadAfter = true;
                    break;
                  }
                }
                StripExact = ReadAfter;
              }
              Region.CondOnRotatedRegister = true;
              Region.CondFlagKept = !StripExact;
              break;
            }
            declineArm(declAnchor(Region), "rotation arm on a condition wire");
            return ArmDisposition::Declined;
          }
      }
      // R6 — NO POST-REGION READ OF THE PRE-Ry RECORD. After the region the
      // register carries `Ry(θ)` on the `f=1` branch, so every consumer must
      // read the POST-region name (the merge φ, which the emitter RAUWs to the
      // base). An SSA name for the base that is READ after the region is a
      // stale record: the emitted gate would name the relabelled rail while the
      // source means the value before it — the wrong-VALUE class of bd 0njv,
      // still open. This fence is deliberately STRICTER than
      // `declineStaleRecordOps` (which covers pure ops only) so that hole is
      // not reachable through this accept: a `cq_measure`, a `ret`, a `store`,
      // an opaque call, a φ, ANY user that is not provably before the region
      // declines.
      //
      // ---- R7's LOOP half (bd test_C_libtooling-drbq Inc 3, PRD §13.2b) ----
      //
      // Asked HERE — immediately before R6 and nowhere earlier, so every other
      // clause's message ordering is byte-identical — because R6 is the ONE
      // clause whose proof changes inside a loop.
      //
      // UNTIL 2026-09-04 THIS WAS AN UNCONDITIONAL DECLINE. It is now the
      // ADMISSION half of the increment the owner scoped ("in a classical loop
      // (so classical bounds), cRy should NOT decline"). `ControlDetect` has
      // ALREADY proved the CFG half before `Region.InLoop` was ever set:
      // `flatRegionRollableInLoop` (A) a natural `LoopInfo` loop, (B) every
      // region block at exactly that depth, (C) a single latch, (D) no second
      // cycle through the entry. What is left for this clause is the two
      // questions that are about the ROTATED REGISTER rather than the CFG:
      //
      //   (b)  some member of `BaseWire` is a PHINode in `L`'s HEADER — i.e. the
      //        rotated base's rail CROSSES the back edge. This is a SCOPING
      //        clause, not a safety one: Inc 3 is the Ry arm on the loop's
      //        PERSISTENT register.
      //        ⚠ AND THE SENTENCE THAT USED TO FOLLOW WAS HALF RIGHT, WHICH IS
      //        WHY IT IS QUOTED RATHER THAN DELETED (bd `test_C_libtooling-wx8g`,
      //        2026-09-14). It read: *"An ITERATION-LOCAL rotated register
      //        (minted inside the body) is a different capability, and it is
      //        measurably not twin-identical — its ESCAPE makes `markIfRailLocal`
      //        refuse the marking, so the rolled form leaks the condition chain
      //        once per trip while the hand-unrolled twin discharges it."* THE
      //        MECHANISM IS REAL and it is now clause (c3)'s subject, measured on
      //        a pair differing in one edge (19 rolled vs 27 unrolled trace
      //        lines, `opt` exit 0 and STRICT stage-2b clean on both — see
      //        `iterationLocalRollable`). THE SCOPE CLAIM WAS WRONG: the
      //        divergence needs the ESCAPE, not the iteration-locality, and the
      //        NON-escaping spelling is byte-identical to its twin. So the
      //        capability is real, it is clause (c) below, and the fence is the
      //        escape rather than the shape.
      //
      //   (b') that header φ must be one `collapseFlattenedLoopRails` will
      //        actually CLAIM — its external incoming peels, through in-place
      //        steps, to a classical-arg-0 `cq_theta` mint dominating the header.
      //        ⚠ READ THAT AS THE SHARED HALF ONLY: step (1) additionally
      //        requires the CLOSED SELF-CYCLE on the LATCH incoming, which this
      //        clause does not ask, so a φ admitted here can still be refused at
      //        round 2 — loudly, with `kMsgCrossIter` (measured, lens L5 Q4).
      //        "Impossible by construction" is FALSE for that half; see
      //        `LoopPlan.h`.
      //        Asked by CALLING `LoopPlan.h`'s `railPhiRootMint`, which IS the
      //        round-2 collapse's step-(1) body (Rule 14 — never a second
      //        spelling of one claim condition). PRD §13.2 row DB is why: with a
      //        DERIVED OUT-OF-PLACE base (`int r = p * 5;` before the loop) the
      //        peel bottoms at a `mul`, step (1) `continue`s, the tainted header
      //        φ survives, and the module declines DOWNSTREAM of emission and of
      //        `flattenRegion` — at `declineClassicalMuxes`, whose
      //        `classical-condition phi` string mislabels a QUANTUM register.
      //        MEASURED, with R7 lifted and nothing else (2026-09-04, both
      //        binaries): that shape declines `stale rail record read past a
      //        controlled Ry` on the FLAT R6 predicates, and — with R6 also made
      //        per-activation — reaches the mux guard exactly as read. Declining
      //        HERE is a pre-mutation loud decline with an accurate string.
      //
      // A loop shape failing either declines with the string it has always had.
      // `LI` null (no tree, no proof) is the same decline — Prime Directive.
      if (Region.InLoop) {
        const Loop *L = LI ? LI->getLoopFor(Region.Pred) : nullptr;
        BasicBlock *LHdr = L ? L->getHeader() : nullptr;
        // ONE GateCalls RECIPE, built the way `lowerLoops` and
        // `collapseFlattenedLoopRails` build theirs (θ ∪ φ), because
        // `railPhiRootMint`'s peel is defined over exactly that set.
        //
        // ⚠ THE RECIPE IS SHARED; THE SET IS NOT (bd drbq Inc 3, round-1 lens
        // L5 Q4). `AngleSelectEmit` inserts the true-arm controlled gate `TA` it
        // mints into `ThetaCalls`/`PhiCalls`, and it runs after this stage and
        // before `collapseFlattenedLoopRails` — so ROUND 2 SEES A STRICT
        // SUPERSET of what is built here. That direction is SAFE, and the
        // argument is the monotonicity of the peel: `peelInPlaceBase` advances
        // only while a call is IN `GateCalls`, so a SMALLER vocabulary stops
        // EARLIER, and an early stop lands on a value that fails
        // `railPhiRootMint`'s `GateCalls.count(Mint)` test ⇒ null ⇒ this clause
        // DECLINES. Conservative by construction, not by luck.
        // RETIREMENT TRIGGER: it inverts silently if detection's vocabulary ever
        // becomes a superset of round 2's, or if the peel's stop condition stops
        // being monotone in `GateCalls`. Full statement at `LoopPlan.h`'s
        // declaration, including why "a divergence between the two callers is
        // impossible by construction" is FALSE for the unshared LATCH half.
        SmallPtrSet<CallInst *, 32> GateCalls;
        GateCalls.insert(Taint.ThetaCalls.begin(), Taint.ThetaCalls.end());
        GateCalls.insert(Taint.PhiCalls.begin(), Taint.PhiCalls.end());
        bool Rollable = false;
        // WHICH CLAUSE GRANTED IT — one bit, carried into the post-fixpoint
        // re-ask because the two conjuncts do NOT cover the same entries
        // (contract on `TaintSet::RolledLoopRegionGates`). `false` = (b)/(b'),
        // the loop-CARRIED rail; `true` = (c), the iteration-local one.
        bool GrantIterLocal = false;
        if (LHdr && DT)
          for (Value *B : BaseWireOrder) {
            auto *P = dyn_cast<PHINode>(B);
            // (b). ⚠ THE `!= LHdr` HALF IS DEFENCE IN DEPTH, NOT A LIVE WALL, and
            // it is recorded rather than deleted (measured 2026-09-04: relaxing it
            // to "any `BaseWire` φ" turns ZERO of 1459 fixtures red). It is
            // REDUNDANT under (b'): `railPhiRootMint` can only succeed for a φ with
            // exactly ONE incoming block outside `L`, and in a reducible
            // single-latch loop — gates (A)/(C) of `flatRegionRollableInLoop`, both
            // already proved before `Region.InLoop` was set — the header is the only
            // block with a predecessor outside `L`. What IS live in (b) is "there is
            // a rail φ AT ALL", pinned by
            // `control_inplace_ry_reject_inloop_iterlocal_base.ll` (an
            // ITERATION-LOCAL rotated register has none). Kept in the same style as
            // the two `STRUCTURALLY UNREACHABLE, kept as defence in depth` notes
            // above: the alternative to a redundant check is a silent fall-through.
            if (!P || P->getParent() != LHdr)
              continue;
            if (railPhiRootMint(*P, L, GateCalls, Taint, *DT))
              Rollable = true;                              // (b')
          }
        // (c) — THE ITERATION-LOCAL SPELLING (bd `test_C_libtooling-wx8g`).
        //      Asked ONLY when (b)/(b') found nothing, and it is the OTHER half
        //      of the dichotomy rather than a relaxation of this one: (b) proves
        //      a rail that CROSSES the back edge will be claimed by round 2; (c)
        //      proves a rail that does NOT cross it is re-minted every trip.
        //      `iterationLocalRollable` carries the full argument and the
        //      measured discriminating pair.
        Instruction *IterEsc = nullptr;
        if (!Rollable && L && LHdr && DT &&
            iterationLocalRollable(L, LHdr, BaseWireOrder, MergePhi, T,
                                   StatePrep, RotBase, GateCalls, Taint,
                                   &IterEsc)) {
          Rollable = true;
          GrantIterLocal = true;
        }
        if (!Rollable) {
          // bd `test_C_libtooling-8h7d.12` — THE HONEST STRING FOR THE ONE
          // CLAUSE THAT HAS A SUBJECT. `IterEsc` is non-null only when every
          // other (c) conjunct held and (c3) found a value THIS ITERATION MINTS
          // being read OUTSIDE the loop; that is a sentence about the user's
          // program, and the generic message is not. Anchored at the ESCAPING
          // VALUE when it carries a `!dbg` — the source line that reads it — and
          // at the region otherwise, the `anchorIsLocated` discipline the
          // conjunct-1 twin already uses (a lost `!dbg` reports `<unknown>:0:0`
          // and is invisible to every gate but a full-stderr hash).
          // ⚠ ROUTED THROUGH `declineArm`, like every other decline below the
          // wire gate, so a region that ALSO carries a DEFERRED wire gate keeps
          // that message — the wrapper's whole purpose, and the reason this
          // change moves no `condition predates a non-diagonal gate` fixture.
          // ⚠ BLAST RADIUS, MEASURED over all 2104 fixtures: ONE file,
          // `control_inplace_ry_reject_inloop_iterlocal_escape.ll`, and it is the
          // clause's own pin.
          if (IterEsc)
            declineArm(anchorIsLocated(IterEsc) ? IterEsc : declAnchor(Region),
                       "iteration-local value read after the loop");
          else
            declineArm(declAnchor(Region), "control flow inside a loop body");
          return ArmDisposition::Declined;
        }
        // ---- THE RECORD HALF (bd `test_C_libtooling-wx8g`; contract in
        //      `TaintPropagation.h`), ON THE FAR SIDE OF THE DECLINE SO IT
        //      CANNOT BE ATTACHED TO ONE CLAUSE.
        //
        // The R7-loop clauses prove the rolled body emits per activation what
        // the hand-unrolled twin emits per copy, and that proof has a consumer
        // in ANOTHER STAGE: `markIfRailLocal`'s iteration-local marking runs
        // after the flatten at FINAL taint and can refuse — or never be asked —
        // for reasons this classifier neither owns nor can see. Do not PREDICT
        // the marking: record the HOISTED GATE and re-ask the postcondition once
        // the taint is final (`declineUnmarkedRolledIterLocal`, both entry
        // points, before `lowerRotations`). The `RailCondReads` / bd `eqpx`
        // tripwire pattern.
        //
        // ⚠ IT WAS WRITTEN INSIDE THE CLAUSE-(c) BRANCH UNTIL REVIEW ROUND 1
        // (finding F-W1-2, 2026-09-14) AND THAT SHIPPED A SILENT MISCOMPILE: a
        // loop-CARRIED rail region under a bare `_Bool` is granted by (b'), so
        // it got no record, no re-ask and a stream missing one
        // `cq_template_and_i32_hl_unc` + `cqrt_free` per activation
        // (`d3_invariant_read.c`, 30 vs 34 trace lines, ORACLE DECLINE →
        // SUBJECT ACCEPT). CLAUDE.md's L1: THE RECORD MUST BE AT EVERY
        // **R7-LOOP** GRANT — read it as that and NOT as "every in-loop grant"
        // (bd `s82e`, 2026-09-14; the full scoping argument and its three
        // measured programs are in `TaintSet::RolledLoopRegionGates`). The leak
        // this record closes is REGION-INDEPENDENT, and the R7 slice is a
        // STRICT SUBSET of it: the rest is still a silent leak, and bd `s82e`
        // measured two further programs in which it is a WRONG UNITARY rather
        // than an accepted leak (a per-trip rail left entangled with a
        // loop-INVARIANT register that is afterwards re-rotated and measured).
        // Placing it after `if (!Rollable) return` — rather than in each
        // clause — is what makes that structural: a new clause sets `Rollable`
        // and falls through here, and the only way to miss the record is to
        // return early, which is a DECLINE.
        //
        // `T` is the `if (CallInst *T = inPlaceRotationArmTheta(…))` init of the
        // enclosing block and is non-null by construction; asserted by use.
        Taint.RolledLoopRegionGates.push_back({T, GrantIterLocal});
      }
      // OVER THE RAIL, NOT THE CHAIN (finding J). The scan ranges over EVERY
      // member of `BaseWire`, not over `RotBase` alone: a pre-3qlq register-form
      // `int mark = cq_phi(r,·)` before the region put a second SSA name on the
      // one physical rail, and the shipped direct-user scan saw `mark` (a user,
      // not a read) while `cq_measure(mark)` sat one hop out and lowered to a
      // measurement of the POST-Ry register. Measured, both directions, both verify- and
      // stage-2b-clean: `..._reject_stale_diag_alias_{forward,backward}.ll`, both
      // deleted since (see `railWireClosure`'s header for what pins it today).
      const Instruction *BI = Region.Pred ? Region.Pred->getTerminator()
                                          : nullptr;
      if (!BI || !DT) {
        declineArm(declAnchor(Region), "control flow");
        return ArmDisposition::Declined;  // no anchor / no tree, no proof.
      }
      for (Value *M : BaseWireOrder)
      for (User *U : M->users()) {
        if (U == T || U == MergePhi)
          continue;  // this gate itself, and the merge the emitter dissolves.
        auto *UI = dyn_cast<Instruction>(U);
        // A user INSIDE one of this region's own arm blocks is region-internal
        // and is adjudicated by the ARM CLASSIFIER, not by this fence: the
        // sibling arm's own gate in an if/else (hoisted with this one when it is
        // a rotation arm, declined `mixed phase/value arm` when it is not), or a
        // stray op in THIS arm (already refused by `inPlaceRotationArmTheta`).
        // Excluding them is what keeps the DIAGNOSTIC honest — without it a
        // mixed `if(c) cq_theta(&r,·); else r=cq_phi(r,·)` (pre-3qlq register
        // form) declined here, on the stale-record string, for a region whose
        // actual defect is the mixture.
        // (`railWireClosure` skips the same two blocks, so a member never comes
        // from inside the region either.)
        if (UI && (UI->getParent() == ArmA ||
                   (ArmB && UI->getParent() == ArmB)))
          continue;
        if (!UI) {
          declineArm(declAnchor(Region),
                     "stale rail record read past a controlled Ry");
          return ArmDisposition::Declined;  // a constant expression: no position.
        }
        if (!DT->isReachableFromEntry(UI->getParent()))
          continue;  // never executes, so never reads (the M-A F3 reading).
        // TWO SETS, TWO QUESTIONS — see `cannotFollowGate`. A member is an alias
        // HOP and owes only "cannot fire after the gate"; every other user owes
        // the shipped `provablyBefore`, unchanged.
        //
        // ⚠ THE ROUND-1 φ-CROSSING WIDENING MOVED THIS SKIP SET TOO, AND THAT IS
        // THE ANSWER, NOT AN OVERSIGHT (the bd 8h7d.5 F-1/F-3 discipline: when
        // you widen a set, ask what OTHER set is computed over the same
        // closure). `BaseWire` feeds THREE consumers — R4's intersection above,
        // R6's member enumeration, and this skip set — and all three grew. For
        // this one the relaxation is from `provablyBefore` to `cannotFollowGate`
        // (dropping the DOMINANCE conjunct) on a newly-admitted φ / select /
        // freeze, and it is sound because none of those is a RECORD READ: a
        // `PHINode` and a `freeze` emit no gate at all, and a `select` that
        // survives to lowering is a CNOT-class copy OFF the wire — for all
        // three the only thing that can go wrong is EXECUTING AFTER the hoisted
        // controlled Ry, which is exactly what `cannotFollowGate` refuses.
        // Dominance answers "did `U` definitely execute", which R6 never asks.
        //
        // IN-LOOP the two flat predicates are replaced — for this class ONLY —
        // by the PER-ACTIVATION certificate (`recordLivePerActivation`, bd drbq
        // Inc 3 / PRD §13.3). The two SETS above are untouched; what changes is
        // the predicate they feed, and only when `Region.InLoop`. A flat region
        // keeps `provablyBefore` / `cannotFollowGate` BYTE-FOR-BYTE, which is
        // what makes the whole-corpus acyclic sweep a real witness rather than a
        // regeneration.
        //
        // ⚠ THE TWO SPELLINGS ARE NOT EQUIVALENT, AND THE PAIR THAT PROVES IT IS
        // COMMITTED (bd drbq Inc 3, round-1 lens L1 Q2):
        // `control_inplace_ry_reject_flat_cond_pre_measure.ll` DECLINES and
        // `control_inplace_ry_inloop_cond_pre_measure.ll` ACCEPTS the SAME
        // relation between a record read and a region — once acyclic, once in
        // the rolled loop. THE CERTIFICATE IS THE GENERAL PREDICATE:
        // `provablyBefore ⇒ certificate` and `cannotFollowGate ⇒ certificate`,
        // because it drops the DOMINANCE conjunct, which answers "did `U`
        // definitely execute" — a question R6 has never needed. The flat pair is
        // a deliberately STRONGER LEGACY spelling, kept verbatim so that no
        // acyclic disposition moved in this increment. Replacing it with the
        // certificate is therefore a real WIDENING of the acyclic accept class
        // and owes its own adversarial round (Rule 13); the two fixtures are what
        // make that a deliberate day rather than a silent flip. bd
        // [[sibling-predicate-spelling-is-the-hole]].
        const bool Ok =
            Region.InLoop
                ? recordLivePerActivation(M, UI, BI)
                : (BaseWire.count(UI) ? cannotFollowGate(UI, BI, *DT)
                                      : provablyBefore(UI, BI, *DT));
        if (!Ok) {
          declineArm(UI, "stale rail record read past a controlled Ry");
          return ArmDisposition::Declined;
        }
      }
      // ACCEPT: record the class + the single hoisted gate for the emitter, and
      // pin the routed base by SSA identity (an if/else merge has no Pred edge
      // for the emitter to re-derive it from).
      if (ArmBB == Region.Arm) {
        Region.ClassArm = ArmClass::InPlaceRotation;
        Region.Shadow.assign(1, T);
      } else {
        Region.ClassArmFalse = ArmClass::InPlaceRotation;
        Region.ShadowFalse.assign(1, T);
      }
      Region.setRoutedBase(RotBase);
      Routed = RotBase;
      SawRotationArm = true;
      // l4x4.b §2.8 — THE CALLER-INDEPENDENT BACKSTOP. `ControlRegion::
      // RailLadderProven` means "some classifier ran the §13.3 rail ladder for
      // this region"; `emitInPlaceRotationRegion` REFUSES a rail condition
      // without it. One field, two writers (`classifySelectRegion` is the other),
      // one contract — a second field would be the `railOf`/`isAbiQramStore`
      // drift hazard (Rule 14). Set only when the condition IS a rail, so the
      // emitter's refusal cannot be satisfied by accident.
      if (RegCond)
        Region.RailLadderProven = true;
      // bd `test_C_libtooling-z0re` — CARRY the classifier's runtime-seed
      // verdict to the emitter, which records the source theta for the
      // post-fixpoint re-ask ON THIS FLAG and never on the taint it sees at
      // emission (a 6.5 region emitted earlier in the same loop can already have
      // RAUW'd the seed to its tainted `%out` — `ControlRegion::
      // RuntimeSeedAdmitted`'s header has the measured failure). The rail bank's
      // compiler-owned seed is excluded: `lowerRotations` adopts it through
      // `isRailBankSeedAlloc`, not through taint.
      if (StatePrep && !PreallocatedBankSeed &&
          isRuntimeStatePrepSeed(RotBase, Taint))
        Region.RuntimeSeedAdmitted = true;
      continue;
    }

    // If/else first arm: anchor the routed handle on a LEAF spine base (a value
    // op as the first arm's base is a value arm, handled below).
    if (!Routed && !isValueChangingOp(Base)) {
      if (!Taint.Tainted.count(Base)) {
        declineArm(declAnchor(Region), "control flow");
        return ArmDisposition::Declined;
      }
      if (!armBlockIsPureSpine(ArmBB, ArmIncoming)) {
        declineArm(declAnchor(Region), "impure phase arm");
        return ArmDisposition::Declined;
      }
      // drbq Inc 1 — unreachable while a rotation arm anchors `Routed` (this
      // branch needs `!Routed`), kept for the same reason the other three
      // homogeneity checks are: one flag, every accept site (see below).
      if (SawRotationArm) {
        declineArm(declAnchor(Region), "mixed phase/value arm");
        return ArmDisposition::Declined;
      }
      // §2.6 — PHASE class on a rail (the if/else leaf anchor): out of l4x4.b,
      // for the same reason as its diamond sibling above.
      if (RegCond)
        return declineRailClass();
      SawPhaseArm = true;
      Routed = Base;
      continue;
    }

    // ---- 4.2 value-arm classification (PRD Part II §8.3; IMPL-4.2 §3) ----
    if (Base == ArmIncoming) {
      // The phase spine consumed nothing — try the arm-block-bounded value
      // chain. `Routed` doubles as the QQ threading hint (see walkValueChain).
      ValueChain Chain = walkValueChain(ArmIncoming, ArmBB, Taint, Routed);

      // The chain ran into an in-arm `cq_phi_<sfx>` (retired register form;
      // declines at `resolveSources`): phase + value links in one lineage
      // (`rz(p,a); p=p+3`). The answer carries both a phase and a
      // changed basis — the CNOT copy copies only the basis label
      // (dephasing the Rz answer, Rule 7) and the flag-strip is invalid over
      // a changed basis. No copy-safe, strip-valid lowering exists (§6a
      // territory).
      if (Chain.MixedPhi) {
        declineArm(Chain.MixedPhi, "mixed phase/value arm");
        return ArmDisposition::Declined;
      }

      if (!Chain.Ops.empty()) {
        // Heterogeneous if/else: a value arm beside an already-classified
        // phase arm (the converse guard sits on the phase path above).
        if (SawPhaseArm || SawRotationArm) {
          declineArm(declAnchor(Region), "mixed phase/value arm");
          return ArmDisposition::Declined;
        }
        // ⚠ "An FP-typed merge under tainted control is categorically an ANGLE"
        // stood here and is FALSE (owner ruling 2026-10-08, CLAUDE.md R3): an fp
        // merge can carry quantum data, and angle use is decided at the rotation
        // consumers. Scalar-fp value diamonds are PredMux's (witness W5; W8 for
        // a switch), flattened to selects whose gate 3 refuses an angle reach and
        // whose kjd1 fp controlled copy lowers the data. A shape PredMux leaves
        // reaches this fence, and the 4.2 value emitter is integer-only
        // (`emitValueRegion`'s pre-flight), so it declines here as a LOWERING GAP,
        // not as an angle (bd dm7f.17).
        if (MergePhi->getType()->isFPOrFPVectorTy()) {
          declineArm(declAnchor(Region), "control flow");
          return ArmDisposition::Declined;
        }
        // POSITIVE half of criterion 3's "merge type is integer" (§8 review,
        // 2026-06-10): an integer VECTOR (<2 x i32>, reachable via the
        // escape-whitelisted bitcast of a tainted i64) or a non-ABI-width
        // integer (i128 via zext) is not routable data either — the WI-4
        // (pre-3qlq route) emitter could mint no alloc/copy/template symbol for
        // it (null FunctionCallee AFTER the route bracket was emitted — a
        // crash-on-valid-input, violating detect-before-mutate). The width
        // check is NECESSARY-not-sufficient and runs only AFTER the FP
        // decline above (f64 has a valid width, and this emitter has no fp copy).
        // n0ui Tier-1: `widthHasReversibleCopy`, NOT `.empty()` — i128 is a
        // recognized intermediate width with no `cqrt_copy_i128`, so a tainted
        // i128 value-merge phi must still DECLINE here (same fence as the
        // Select/Switch data-mux gates).
        if (!MergePhi->getType()->isIntegerTy() ||
            !widthHasReversibleCopy(abiWidthFromType(MergePhi->getType()))) {
          declineArm(declAnchor(Region), "control flow");
          return ArmDisposition::Declined;
        }
        // The chain must bottom OUTSIDE the arm (at the live routed register
        // in the pred); an in-arm bottoming value (a cast, an unsupported or
        // untainted op under the chain) is a broken lineage.
        if (auto *BaseInst = dyn_cast<Instruction>(Chain.Base);
            BaseInst && BaseInst->getParent() == ArmBB) {
          declineArm(declAnchor(Region), "control flow");
          return ArmDisposition::Declined;
        }
        // Base-identity — THE DEFECT-2 FIX (PRD §8.3): a chain that bottoms
        // anywhere but the routed slot is a data MUX of independently-derived
        // values (`t=q+7; if(q>5) t=q+3` — Defect-2; `if(q>5){p=q+1}` — the
        // condition READ). Replaying such a chain on the routed rail (the
        // pre-3qlq swap route) computed f(routed), not the source's f(base): a
        // verify-clean wrong unitary. Not routable, not a §3c clobber (the condition register is
        // never overwritten) — the 4.4 select-family mux. Declined with the
        // dedicated `non-routable value multiplexer` string (Phase 7.2 Inc 1 /
        // 65wb.1): a value if/else (or derived-base diamond) whose two arms
        // bottom at DIFFERENT bases reconverges structurally but has no single
        // routable base — it is the `exp2` two-base value-multiplexer surface,
        // conservatively DECLINED (owner decision 65wb.5; over-decline is safe).
        // REOPENABLE per PRD-7.2 §2.10/§5 (a tooling/canonicalization boundary,
        // not information-theoretic) — the data-mux emitter design is retained
        // as reference in IMPLEMENTATION-PLAN-7.2.md §3. The dedicated string is
        // distinct from §2.10's `non-reconverging value exit` (reserved for the
        // truly non-reconverging persisting-`ret`/`musttail` row, uncondSucc==
        // null); this shape DOES reconverge, so it gets its own `What`.
        if (Routed) {
          if (Chain.Base != Routed) {
            declineArm(declAnchor(Region), "non-routable value multiplexer");
            return ArmDisposition::Declined;
          }
        } else {
          // If/else first arm: the chain's base anchors the shared routed
          // slot (base-identity replaces the retired readsProvenance
          // fallback; the second arm must bottom at this same base).
          Routed = Chain.Base;
        }
        // §3c — ACTIVE (PRD §8.3 row 1; 4.1 shipped it vacuously): a ROUTABLE
        // chain whose routed register is in the condition's transitive taint
        // provenance rewrites the very register the flag was minted from. It
        // cannot be both kept and disentangled (conservation of information)
        // — the flag-strip premise `icmp_inv` reads the same basis as the
        // mint dies with the rewrite. PERMANENT reject, before the QQ defer
        // (so `if(q>5){q=q+p}` stays §3c, not deferred).
        //
        // The PERMANENT string fires ONLY on the proven diamond identity
        // (straight-through == direct provenance member): the merge
        // demonstrably overwrites the muxed condition register in the source
        // program. Everything else in the provenance-overlap family declines
        // GENERIC `control flow` (§8 review 2026-06-10 — the Defect-2 lesson,
        // inverted: never brand a shape information-theoretically impossible
        // on unproven evidence):
        //   * an IF/ELSE-anchored base (`t=q+1 else t=q+2`, incl. the no-hint
        //     QQ threading): the base was anchored heuristically from arm 1's
        //     chain — the region may be a fresh-value READ mux over a live
        //     `q` (writes a NON-condition variable), which must NEVER get the
        //     §3c string (bd swap-route-detect-known-limits; the same rule
        //     the retired readsProvenance fallback violated);
        //   * a DIAGONAL-ALIAS hit (pre-3qlq register form: `Routed = %qd =
        //     cq_phi(%q,·)`, condition reads `%q`): the source rewrites a
        //     DIFFERENT variable that merely shares the physical wire — declined
        //     revisitably, not permanently (see diagonalAliasHit).
        if (Value *Hit = diagonalAliasHit(Routed, Prov)) {
          if (StraightThrough && Hit == Routed) {
            declineArm(Chain.Ops.front(),
                                 "arm rewrites a condition operand");
          } else {
            declineArm(declAnchor(Region), "control flow");
          }
          return ArmDisposition::Declined;
        }
        // Criterion 3: the routed slot must be a tainted quantum register.
        if (!Taint.Tainted.count(Routed)) {
          declineArm(declAnchor(Region), "control flow");
          return ArmDisposition::Declined;
        }
        // Routed-base WIRE staleness (WI-5 §8 adversarial review,
        // 2026-06-11 — a latent WI-4 over-accept): the routed base's physical
        // wire must gain NO non-diagonal (Ry) in-place gate. The measured shape
        // was a chained `cq_theta` on a SIBLING SSA name of a pre-3qlq
        // `cq_phi` alias (`%qd = cq_phi(%q,·); %q2 = cq_theta(%q,·)`):
        // condProvenance stops AT a theta source, so no other guard reached
        // `%q`, and the route-in at the branch read the POST-Ry wire while the
        // chain's SSA base named the PRE-Ry RECORD — the stale-record family
        // (lowering_reject_stale_record_add.ll). Position-free walk — ANY theta
        // on the wire declines, including a post-region one (over-decline is
        // safe, Prime Directive). PHASE arms were immune: Rz is diagonal, so no
        // basis record is read (the same opcode-not-position rationale as
        // isValueChangingOp). The diagonal-alias closure that seeds the walk
        // lives in the WireWalk core itself since test_C_libtooling-6j1 (the
        // straight-line twin of this guard) — `Routed` alone seeds it.
        // CrossValueRouting=TRUE since bd tayx (uniform router posture; Rule
        // 14): a router phi forwards the same physical handle. For THIS value
        // path the flip is belt-and-braces — the router spelling's arm ops
        // read the stale wire and the PRE-detect `declineStaleRecordOps`
        // (position-aware, router-crossing) declines it first (pinned by
        // control_swap_reject_value_diamond_router_base_backstop.ll) — but
        // detection must not depend on that backstop coincidence (the same
        // principle the SwitchArmProve twin records).
        if (CallInst *Gate = findNonDiagonalWireGate(
                Routed, /*CrossValueRouting=*/true, /*EmitPoint=*/nullptr,
                /*DT=*/nullptr, &Taint)) {
          declineArm(Gate,
                               "routed base predates a non-diagonal gate");
          return ArmDisposition::Declined;
        }
        // A DERIVED routed base's OWN angle must be classical — the arg-1
        // parallel of criterion 3 (Rule 3). Only a `cq_phi_<sfx>` base has an
        // angle here, the retired register form that declines at
        // `resolveSources`, so this is vacuous on an accepted module. It was
        // added so mutation never preceded detection (§8 adversarial review,
        // 2026-06-11; control_swap_reject_value_derived_tainted_angle.ll).
        // ⚠ A `cq_theta` base with a quantum-derived angle is NOT matched: it
        // is caught, loudly, by `declineTaintedAngle` in `lowerRotations`,
        // AFTER `lowerControlRegions` has lowered this region (see the base
        // row of `taintedAngleGate`; measured 2026-10-05, bd tn85).
        if (auto *BaseCI = dyn_cast<CallInst>(Routed);
            BaseCI && isPhiCall(BaseCI) && BaseCI->arg_size() >= 2 &&
            Taint.Tainted.count(BaseCI->getArgOperand(1))) {
          declineArm(BaseCI, "rotation angle");
          return ArmDisposition::Declined;
        }
        // Rule 8 linearity + self-contained arm block (fan-out / stray op /
        // DAG sibling — see valueArmIsPureChain). Since bd
        // `test_C_libtooling-fn1q` increment 1 the helper ALSO collects the
        // arm's CLASSICAL CONE, which `emitValueRegion` hoists ahead of the
        // chain; the four conjuncts that make a cone member admissible are at
        // the helper, which is the only place that proves them (L1 — the
        // emitter must hoist exactly this set and re-derive nothing).
        SmallVector<Instruction *, 4> ArmCone;
        if (!valueArmIsPureChain(ArmBB, Chain.Ops, MergePhi, Taint, ArmCone)) {
          declineArm(declAnchor(Region), "impure value arm");
          return ArmDisposition::Declined;
        }
        // A Q+Q link (second tainted operand) is a recognized value shape this
        // class does not yet accept — defer with the 4.2 string.
        if (Chain.HasQQ) {
          declineArm(Chain.Ops.front(), "value-arm swap-route");
          return ArmDisposition::Declined;
        }
        // §2.6 — VALUE class on a rail: out of l4x4.b and filed as bd
        // `test_C_libtooling-fg9k` (1b-B.2b). The 3qlq Inc-2 value merge hoists
        // the arm's chain and merges by two X-BRACKETED
        // `cqrt_copy_<W>_controlled`, and the bracket is the thing Inc 1b forbids
        // on a user register — the rail root would need the 1b-B.1 `CopyRailRoot`
        // CNOT ancilla, which `emitValueRegion` does not route through. That is a
        // whole increment with its own Rule-13 round, not a fall-through.
        if (RegCond)
          return declineRailClass();
        // ACCEPT-class value arm: record the class + the ordered chain for
        // the emitter (Shadow = Region.Arm's chain, ShadowFalse =
        // Region.ArmFalse's; for an orientation-B diamond Region.Arm is the
        // FALSE successor — polarity rides ArmNegated, never edge truth).
        if (ArmBB == Region.Arm) {
          Region.ClassArm = ArmClass::Value;
          Region.Shadow.assign(Chain.Ops.begin(), Chain.Ops.end());
          Region.ShadowCone.assign(ArmCone.begin(), ArmCone.end());
        } else {
          Region.ClassArmFalse = ArmClass::Value;
          Region.ShadowFalse.assign(Chain.Ops.begin(), Chain.Ops.end());
          Region.ShadowConeFalse.assign(ArmCone.begin(), ArmCone.end());
        }
        SawValueArm = true;
        continue;
      }
      // Chain empty: ArmIncoming is not an in-arm link at all — fall through
      // to the hoisted/leaf dispositions below.
    } else if (auto *BaseInst = dyn_cast<Instruction>(Base);
               BaseInst && BaseInst->getParent() == ArmBB &&
               isValueChangingOp(Base)) {
      // The phase spine consumed ≥1 `cq_phi` link and bottomed at an IN-ARM
      // value op: an Rz stacked over a basis the arm itself changed
      // (`p=p+3; rz(p,a)`) — the mirror direction of the chain-hits-phi
      // mixed case above. Same physics, same string.
      declineArm(BaseInst, "mixed phase/value arm");
      return ArmDisposition::Declined;
    }

    if (isValueChangingOp(Base)) {
      // An OUT-OF-ARM value-changing merge contribution (the in-arm walks
      // consumed nothing): a HOISTED arm computation (Rule 9 — clang -O1
      // freely hoists a branch-invariant value op into a dominating block).
      // For a diamond, the 4.1 straight-through provenance proxy still
      // decides §3c (the hoisted clobber `if(q>5){q=q+3}` keeps its permanent
      // string regardless of schedule). The if/else `readsProvenance`
      // fallback is RETIRED (PRD §8.3): without a straight-through there is
      // no §3c evidence here — keep the deferred value-arm string (a safe
      // decline either way; acceptance always requires an IN-ARM chain).
      const bool Clobber =
          StraightThrough && Prov.count(StraightThrough) != 0;
      declineArm(cast<Instruction>(Base),
                           Clobber ? "arm rewrites a condition operand"
                                   : "value-arm swap-route");
      return ArmDisposition::Declined;
    }

    // A leaf base that is NOT the routed handle: a cross-handle multiplexer or a
    // fresh quantum source muxed against the routed slot — not a phase arm over
    // the routed handle. Decline (over-decline is safe; Prime Directive).
    declineArm(declAnchor(Region), "control flow");
    return ArmDisposition::Declined;
  }

  // Both staged flips are in (IMPLEMENTATION-4.2 §7): a value DIAMOND (WI-4)
  // and a two-arm value IF/ELSE (WI-5) both reach `emitValueRegion`, which reads
  // the recorded ClassArm/ClassArmFalse + Shadow/ShadowFalse. Homogeneity is
  // already proven here: a surviving two-arm region is either all-phase or
  // all-value over ONE shared routed base (the mixed declines above), and an
  // if/else second chain bottoming anywhere but the first arm's anchored base
  // declined `control flow` (base-identity).

  // P1 — the Inc-4 position-aware accept is for the arm classes whose emitted
  // stream is PROVABLY COMPLETE at the branch. A value arm keeps the
  // position-free reading verbatim (Rule 7: the value merge copies the routed
  // base's basis LABEL out to a fresh rail, so a later in-place Ry on that
  // wire is a real staleness hazard the phase path does not have — the phase
  // answer stays in place on `q` and the flag is stripped by the uncontrolled
  // `icmp_inv`). Every value-arm decline above is already wrapped, but the
  // ACCEPT-class value arm falls through to here, so this is the fence that
  // actually holds P1. `SawValueArm` also covers the mixed case by
  // construction (a mixed region declined above).
  //
  // ⚠ `SawRotationArm` WAS ADDED HERE BY bd test_C_libtooling-drbq INCREMENT 3
  // (PRD §13.4b), AND IT MOVES ACYCLIC PROGRAMS — say so plainly, because every
  // other part of that increment is about loops. Before it, a control-in-place
  // ROTATION arm set `SawRotationArm` and never `SawPhaseArm`, so `!SawPhaseArm`
  // was true and `if (q == 5) cq_theta(&r, .9); cq_theta(&q, .3);` declined
  // `condition predates a non-diagonal gate` with NO loop anywhere in it — while
  // the identical program with `q = cq_phi(q, .3)` ACCEPTED. The fence was keyed
  // on the arm's SPELLING, not on its physics (recorded over-decline bd drbq.7).
  //
  // THE ARGUMENT IS P1's OWN, WITH THE ARM CLASS SUBSTITUTED, and it is why the
  // rotation arm belongs on the phase arm's side of this disjunction rather than
  // the value arm's. An in-place rotation arm copies nothing, replays nothing and
  // allocates no work rail: its ENTIRE emitted stream is
  //     mint(f from C) ; [x(f)] cRy(f, R, θ) [x(f)] ; strip(f from C) ; free(f)
  // all inserted before `BI`. `ProvenPostRegion` means every wire gate `G`
  // satisfies `provablyBefore(BI, G)`, and `condWireDisposition`'s own lemma
  // carries that to each call in the stream — dominance over `BI` implies
  // dominance over calls that PRECEDE `BI` in `BI`'s own block, and
  // `!reachable(G, BI)` implies `!reachable(G, S)` for each. So when `G` fires the
  // flag is already stripped and freed and `R`'s relabelling is complete; and R4
  // has proved `R`'s wire ∉ `C`'s wires, so `G` is not on the register this arm
  // touched.
  // ⚠ bd dm7f.4: for a `CondFlagKept` region R4 proved the OPPOSITE, and the
  // argument changes rather than fails. There is no strip for `G` to stand in
  // front of: `f` is minted before the hoisted gate and never stripped or
  // freed, so a later `G` on `C`'s (= `R`'s) wire acts on a register whose
  // record `f` is still live. That is the dephasing class (owner ruling lyyf),
  // and M-A warns at `G` as well as at the arm's own gate (measured: two
  // warnings for `if (q > 5) cq_theta(&q, .3); cq_theta(&q, .2);`).
  //
  // THE RESIDUAL IS IDENTICAL TO THE PHASE ARM'S, not new: a DERIVED condition
  // leaves template rails entangled with `C` and live past the strip, which a
  // later Ry on `C` dephases. That is a property of the CONDITION's chain, not of
  // the arm class — CONFIRMED by independent measurement (round-1 lens L8): the
  // derived-`and` and derived-`sqrt` programs' traces are byte-identical to their
  // (pre-3qlq) `cq_phi`-arm twins apart from `rz`↔`ry` on one line, with the
  // whole chain `_unc`'d and freed BEFORE the deferred gate. Pinned by
  // `control_inplace_ry_post_region_theta_derived_cond.ll` and `..._negated.ll`.
  //
  // ⚠ WHAT THIS COMMENT USED TO ADD IS STRUCK: "and it has been owned since bd
  // lyyf by M-A's `warnLiveRecordRotations` as a `DS_Warning`" (lens L8, F-L8-1).
  // M-A does NOT fire for an ESCAPING condition record — `int d = q & 6;`
  // measured after the region leaves the `and` rail live and entangled when the
  // post-region Ry fires, and stderr is EMPTY. The gap is arm-class-independent
  // and PRE-EXISTING (the `cq_phi` twin is equally silent on the ORACLE), so it
  // is not this clause's to fix; it is simply not the thing that makes this
  // clause safe. The ORDER argument above is, and it is measured.
  //
  // WITHOUT THIS THE FLAGSHIP CUSTOMER DOES NOT COMPILE. Canonical Grover in a
  // rolled loop is an Rz oracle, a controlled Ry on an ancilla and an **Ry**
  // reflection on `q`; the loop half of Increment 3 clears R7 and this clause is
  // the SECOND, non-loop fence standing in front of it. Shipping only the first
  // would have delivered the Rz-reflection and dtzb-offset loops while still
  // declining the program the increment was scoped for — Rule 17.
  //
  // Pinned by the red-green pair `control_inplace_ry_post_region_theta_cond.ll`
  // (accept, flat) and `control_inplace_ry_reject_post_region_theta_stalecond.ll`
  // (the gate that is NOT provably post-region, still `DeclineNow` upstream), so
  // the two halves of `condWireDisposition` cannot drift.
  if (DeferredWireGate && (SawValueArm || !(SawPhaseArm || SawRotationArm))) {
    diagnoseUnderControl(declAnchor(Region),
                         "condition predates a non-diagonal gate");
    return ArmDisposition::Declined;
  }
  // bd dm7f.52 — a compound tree reaches this exit only through the rotation
  // clause (`condTreeRotationCandidate`); assert that by the recorded classes
  // rather than assume it, then CLAIM every logical `select i1` node so the
  // caller's tainted-select scan does not also lower it as an i1 data mux (the
  // branch phase's own accept does the same, for the same reason).
  if (CondIsTree || PhiRootCond) {
    if (Region.ClassArm != ArmClass::InPlaceRotation ||
        (Region.ArmFalse && Region.ClassArmFalse != ArmClass::InPlaceRotation) ||
        Region.CondOnRotatedRegister || Region.CondFlagKept ||
        Region.ShareCondFlag) {
      diagnoseUnderControl(declAnchor(Region), "control flow");
      return ArmDisposition::Declined;
    }
    if (ClaimedSelects)
      for (Instruction *N : RotTree.Nodes)
        if (isa<SelectInst>(N))
          ClaimedSelects->insert(N);
  }
  return ArmDisposition::Accept;
}

// ── bd test_C_libtooling-3qlq Inc 1 — P1, the FLAT KICKBACK DIAMOND ──────────
//
// `if (COND(q)) cq_phi(θ);` with the REGISTER-FREE `void @cq_phi(double)`
// (PRD `retire-swap-route-PRD.md` §6.2 row P1, owner decision D1).
//
// WHY THIS IS A SEPARATE CLASSIFIER AND NOT A `classifyArms` ARM CLASS. The arm
// carries no VALUE: `cq_phi` returns nothing, so the merge block has NO φ for
// this region at all. `recoverRegion`'s three shape recognizers each require a
// non-null `soleMergePhi`, so the region falls through to `RegionShape::
// OffPattern` and declines `control flow` (MEASURED on the pre-increment oracle
// for the flagship Grover customer). This is the same seam
// `lowerControlledIOSinks` (7.6) and `classifyAbortPark` (7.2 Inc 3) sit in, and
// it is a PRE-PEEL in `handleBranchRegion` for the same reason they are.
//
// THE LOWERING IS KICKBACK, AND IT TOUCHES `q` NOT AT ALL (PRD §3). With
// `f = COND(x)` minted into a |0⟩ ancilla the state is `Σ a_x |x⟩|c(x)⟩`;
// `P(θ) = diag(1, e^{iθ})` ON THE FLAG gives `Σ a_x e^{iθ c(x)} |x⟩|c(x)⟩`; the
// ordinary compare `_unc` strip (a permutation `|x, c(x)⟩ → |x, 0⟩`) returns the
// ancilla to |0⟩ ON EVERY BRANCH, and the phase is left on the BRANCH. That is
// why the emitted gate is `cqrt_rz_i1` on the FLAG and never a `_controlled`
// gate on the register: the register is not an operand of anything this region
// emits. (Under `Rz(θ) = diag(e^{−iθ/2}, e^{iθ/2})` the difference from `P(θ)`
// is a global phase — `cqrt_rz_i1` is the gate either way.)
//
// WHAT THE FENCES THEREFORE ARE, AND ARE NOT. The condition register is NOT
// relabelled by a kickback (no gate on `q`, diagonal or otherwise), so the
// register-side fences of the drbq rotation arm — R4's disjoint-wire proof, R6's
// stale-record read, the structural freeze — have no subject here and are not
// asked. The CONDITION-side fences are asked in full and are exactly
// `classifyArms`' own, in its order and with its strings: `CmpInst` +
// `comparePredLowerable`, `condDataUseDisposition` (the ziov shared-flag path),
// `condProvenance` + `condWireDisposition` (a non-diagonal Ry between compare
// and branch would make the mint read a different basis than the source
// compare), and `compareFlagMintable` (Q+Q has no mint).
//
// Returns `Accept` with `R` populated as a `PhaseKickback` region — `Merge` is
// deliberately NULL (there is no φ to dissolve) while `MergeBB` is set, exactly
// as `lowerControlledIOSinks` builds its synthetic flatten region.
bool phaseAngleTail(BasicBlock *MergeBB, const TaintSet &Taint, PHINode *&Phi,
                    CallInst *&Consumer) {
  // See ArmAnalysis.h for what this is and why the classifier must ask it about
  // EVERY merge, not only the ones it wants to widen to.
  PHINode *Found = nullptr;
  for (PHINode &P : MergeBB->phis()) {
    if (Found)
      return false;  // more than one phi — off-pattern.
    Found = &P;
  }
  if (!Found || !Found->getType()->isDoubleTy() ||
      Found->getNumIncomingValues() != 2)
    return false;
  // Both muxed angles must be CLASSICAL (Rule 3 — quantum data in the angle slot
  // is the f64/angle miscompile family).
  for (unsigned I = 0; I != 2; ++I)
    if (Taint.Tainted.count(Found->getIncomingValue(I)))
      return false;
  // Its SOLE user must be the angle slot of a register-free phase call sitting in
  // this same merge block. `hasOneUse` counts USES, so a phi feeding one call
  // twice is refused here too.
  if (!Found->hasOneUse())
    return false;
  auto *CI = dyn_cast<CallInst>(Found->user_back());
  if (!CI || CI->getParent() != MergeBB || !isRegisterFreePhaseCall(CI, Taint) ||
      CI->arg_size() != 1 || CI->getArgOperand(0) != Found)
    return false;
  Phi = Found;
  Consumer = CI;
  return true;
}

// ── bd test_C_libtooling-3qlq Inc 1 — P1, the FLAT KICKBACK REGION ───────────
//
// `if (COND(q)) cq_phi(θ);` (and its if/else and multi-gate generalizations)
// with the REGISTER-FREE `void @cq_phi(double)` (PRD
// `retire-swap-route-PRD.md` §6.2 row P1, owner decision D1).
//
// WHY THIS IS A SEPARATE CLASSIFIER AND NOT A `classifyArms` ARM CLASS. The arm
// carries no VALUE: `cq_phi` returns nothing, so the merge block has no φ for the
// region's gates. `recoverRegion`'s three shape recognizers each require a
// non-null `soleMergePhi`, so the region falls through to
// `RegionShape::OffPattern` and declines `control flow` (MEASURED on the
// pre-increment oracle for the flagship Grover customer). This is the same seam
// `lowerControlledIOSinks` (7.6) and `classifyAbortPark` (7.2 Inc 3) sit in, and
// it is a PRE-PEEL in `handleBranchRegion` for the same reason they are.
//
// THE LOWERING IS KICKBACK, AND IT TOUCHES `q` NOT AT ALL (PRD §3). With
// `f = COND(x)` minted into a |0⟩ ancilla the state is `Σ a_x |x⟩|c(x)⟩`;
// `P(θ) = diag(1, e^{iθ})` ON THE FLAG gives `Σ a_x e^{iθ c(x)} |x⟩|c(x)⟩`; the
// ordinary compare `_unc` strip (a permutation `|x, c(x)⟩ → |x, 0⟩`) returns the
// ancilla to |0⟩ ON EVERY BRANCH, and the phase is left on the BRANCH. That is
// why the emitted gate is `cqrt_rz_i1` on the FLAG and never a `_controlled` gate
// on the register: the register is not an operand of anything this region emits.
// (Under `Rz(θ) = diag(e^{−iθ/2}, e^{iθ/2})` the difference from `P(θ)` is a
// global phase — `cqrt_rz_i1` is the gate either way.)
//
// N GATES PER ARM ARE ADMITTED, NOT DECLINED (orchestrator decision 2026-09-05,
// on the prep-b measurement OQ-5). PRD §6.3's first decline row refuses "an arm
// with N>1 `cq_phi` calls" on the ground that "summing angles is the 2b rounding
// class again" — and that ground is a Ry-STEM ground that does not survive the
// surface change. Under kickback there is NOTHING TO SUM: N gates on the SAME
// minted flag are N `cqrt_rz_i1(f, θ_i)` emitted in source order, each angle
// passed through verbatim, and they compose to `P(Σθ_i)` on the branch BY THE
// PHYSICS of §3 — not by any floating-point arithmetic this compiler performed.
// No `fsub`, no residual, no bound. Refusing them would also regress four SHIPPED
// e2e accepts (`slice_control_phase_diamond`, `slice_control_cond_datause`,
// `slice_control_switch_eqfold`, `slice_control_phase_ifelse_derived`).
//
// WHAT THE FENCES THEREFORE ARE, AND ARE NOT. The condition register is NOT
// relabelled by a kickback (no gate on `q`, diagonal or otherwise), so the
// register-side fences of the drbq rotation arm — R4's disjoint-wire proof, R6's
// stale-record read, the structural freeze — have no subject here and are not
// asked. The CONDITION-side fences are asked in full and are exactly
// `classifyArms`' own, in its order and with its strings: `CmpInst` +
// `comparePredLowerable`, `condDataUseDisposition` (the ziov shared-flag path),
// `condProvenance` + `condWireDisposition`, and `compareFlagMintable`.
//
// Returns `Accept` with `R` populated as a `PhaseKickback` region — `Merge` is
// deliberately NULL (there is no φ for the gates to merge; a MERGE-TAIL ANGLE
// PHI, when present, is claimed through `phaseAngleTail` and ERASED by the
// emitter before the flatten) while `MergeBB` is set, exactly as
// `lowerControlledIOSinks` builds its synthetic flatten region.
// THE Q+Q CONDITION REASON, ONE SPELLING FOR THE WHOLE PHASE PATH — bd
// test_C_libtooling-3qlq Inc 1, Rule-13 ROUND-2 finding F-B2-2 (prep_b2's
// golden-regeneration measurement).
//
// A kickback whose condition compares TWO tainted registers has no flag mint at
// any width (`CompareLowering` builds `cq_template_icmp_<pred>_<W>_hl(q, lit)` —
// a HANDLE-and-LITERAL template) and must decline. It always DID decline, but on
// the SINGLE-COMPARE path it declined in the OPCODE layer, at
// `no template for opcode 'icmp i1' in tainted context`, because
// `classifyPhaseKickback` deliberately did not ask the question and the emitter's
// `lowerCompareToFlag` returned null as its first emission. THAT IS A RULE-1
// PROBLEM, not a message-cosmetics one: a tainted `br` must be CLAIMED OR
// DECLINED BY THE CONTROL LAYER, and "the flag mint happens to have no template"
// is a third path — it works only for as long as no other stage claims the
// compare first, and it names an opcode where the user wrote a branch. The
// pre-3qlq ORACLE declined the same shape in the control layer
// (`control flow under quantum control`), so this also restores the layer the
// diagnostic came from.
//
// Asked BEFORE any emission, for EVERY leaf, on the single-compare path and
// inside a condition tree alike, with ONE string. The nest (P4) asks the same
// thing at its own leaf ladder. The switch (P5) is exempt STRUCTURALLY, not by
// omission: its flags are `scrutinee == <ConstantInt>`, so a Q+Q eq-flag cannot
// be built. The value path carries the identical fence from Inc 2's own round-1.
// (`kQQCondReason` itself is defined above `classifyArms` since bd dm7f.52,
// whose tree ladder shares it.)

PhaseKickbackDisp classifyPhaseKickback(
    BranchInst *BI, TaintSet &Taint, ControlRegion &Region,
    const ControlPlan &plan, const DominatorTree *DT, const LoopInfo *LI,
    SmallPtrSetImpl<Instruction *> *ClaimedSelects) {
  if (!BI->isConditional())
    return PhaseKickbackDisp::NotApplicable;
  BasicBlock *Pred = BI->getParent();
  BasicBlock *S0 = BI->getSuccessor(0);
  BasicBlock *S1 = BI->getSuccessor(1);

  // ---- 1. SHAPE — a DIAMOND in either polarity (Rule 9: `clang -O1`
  // canonicalizes `if(q!=k)` so the gate arm is the FALSE successor), or an
  // IF/ELSE whose two single-predecessor arms reconverge at a common merge.
  BasicBlock *Arm = nullptr;
  BasicBlock *ArmFalse = nullptr;
  BasicBlock *MergeBB = nullptr;
  bool Negated = false;
  if (uncondSucc(S0) == S1 && S0->getSinglePredecessor() == Pred) {
    Arm = S0;
    MergeBB = S1;
  } else if (uncondSucc(S1) == S0 && S1->getSinglePredecessor() == Pred) {
    Arm = S1;
    MergeBB = S0;
    Negated = true;
  } else if (BasicBlock *M = uncondSucc(S0);
             M && M == uncondSucc(S1) && M != S0 && M != S1 &&
             S0->getSinglePredecessor() == Pred &&
             S1->getSinglePredecessor() == Pred) {
    // IF/ELSE. `Arm` is the TRUE successor and `ArmFalse` the FALSE one, so
    // `Negated` stays false and the FALSE arm's gates carry the `cqrt_x` bracket
    // — the same field convention every other emitter in the tree uses (`Shadow`
    // is `Arm`'s content and `ShadowFalse` is `ArmFalse`'s, BY FIELD IDENTITY,
    // not by edge truth).
    Arm = S0;
    ArmFalse = S1;
    MergeBB = M;
  } else {
    return PhaseKickbackDisp::NotApplicable;
  }
  // The merge must be the clean TWO-predecessor join.
  //
  // LOAD-BEARING TWICE, not a tidiness check. (i) `flattenRegion` SPLICES the
  // arms and merge into `Pred` and ERASES them; a THIRD predecessor (a back
  // edge, a `goto` target) would have its edge silently destroyed. (ii) it is
  // what makes `lowerControlRegions`' STRUCTURAL LEMMA — and therefore the hcrg
  // sequential-chain reordering this Kind is admitted to — hold here: for a
  // `BranchRegion` the lemma reads "a merge has exactly two preds" off
  // `soleMergePhi`'s 2-incoming φ, and a kickback merge has no φ to read it off,
  // so the fact must be asked directly. `lowerControlledIOSinks` asks the same
  // question of its own phi-less void diamond, for the same reason.
  if (!MergeBB->hasNPredecessors(2))
    return PhaseKickbackDisp::NotApplicable;

  // ---- 2. ARM CONTENT. Each arm is exactly `{ N × call void @cq_phi(double
  // θ); br merge }` with N ≥ 0 — block size N+1 with the phase calls FIRST, the
  // strict spelling `lowerControlledIOSinks` uses for its void arm
  // (`IOSinkLowering.cpp:587`), generalized from N = 1. Strictness is
  // load-bearing twice over: it puts every ANGLE's definition OUTSIDE the arm (so
  // each dominates the branch the gates are hoisted to), and it is what makes
  // "this arm is a pure phase" a structural fact rather than a walk.
  //
  // A phase call BESIDE anything else (an Ry, a value op) is NotApplicable, and
  // the fall-through owns it: with a merge φ present `classifyArms` declines
  // `impure phase arm`, and without one `recoverRegion` declines `control flow`.
  // Both are loud; neither is this shape.
  auto collectArm = [&](BasicBlock *BB, SmallVectorImpl<Instruction *> &Out) {
    unsigned N = 0;
    for (Instruction &I : *BB) {
      if (I.isTerminator())
        break;
      auto *CI = dyn_cast<CallInst>(&I);
      if (!CI || !isRegisterFreePhaseCall(CI, Taint) || CI->arg_size() != 1)
        return false;  // anything that is not a phase call → off-pattern.
      Out.push_back(CI);
      ++N;
    }
    return BB->size() == N + 1;  // N phase calls + the terminator, nothing else.
  };
  SmallVector<Instruction *, 4> ArmGates, ArmFalseGates;
  if (!collectArm(Arm, ArmGates))
    return PhaseKickbackDisp::NotApplicable;
  if (ArmFalse && !collectArm(ArmFalse, ArmFalseGates))
    return PhaseKickbackDisp::NotApplicable;

  // ---- 3. THE MERGE-TAIL ANGLE PHI (optional), and the fence that makes the
  // plain accept sound. Every φ in the merge must be accounted for: this one,
  // which the emitter erases, or none at all. See `phaseAngleTail` and the
  // BROKEN-MODULE note in its header.
  PHINode *TailPhi = nullptr;
  CallInst *TailCall = nullptr;
  const bool HasTail = phaseAngleTail(MergeBB, Taint, TailPhi, TailCall);
  if (!HasTail && !MergeBB->phis().empty())
    return PhaseKickbackDisp::NotApplicable;
  if (HasTail) {
    // Both incomings must name blocks THIS region owns, or the polarity of a
    // muxed angle is not decidable from the region alone.
    for (unsigned I = 0; I != 2; ++I) {
      BasicBlock *In = TailPhi->getIncomingBlock(I);
      if (In != Arm && In != ArmFalse && In != Pred)
        return PhaseKickbackDisp::NotApplicable;
    }
  }

  // Nothing to lower is not this shape (an empty tainted diamond is somebody
  // else's — `emitRegion`'s identity-region path, or a generic decline).
  if (ArmGates.empty() && ArmFalseGates.empty() && !HasTail)
    return PhaseKickbackDisp::NotApplicable;

  // ---- 4. EVERY ANGLE IS CLASSICAL (Rule 3). A tainted angle would put quantum
  // data in a gate's classical slot; it declines in the SAME dialect and with the
  // SAME string the retired suffixed family used
  // (`RotationLowering::declineTaintedAngle`), so no fixture learns a new
  // spelling for an unchanged rule. (`phaseAngleTail` already refused a tainted
  // tail incoming, by returning false rather than declining — a tainted merge
  // angle is somebody else's shape, not a broken instance of this one.)
  for (ArrayRef<Instruction *> Gates : {ArrayRef<Instruction *>(ArmGates),
                                        ArrayRef<Instruction *>(ArmFalseGates)})
    for (Instruction *G : Gates)
      if (Taint.Tainted.count(cast<CallInst>(G)->getArgOperand(0))) {
        diagnoseUnderControl(G, "rotation angle");
        return PhaseKickbackDisp::Declined;
      }

  // ---- 4b. POPULATE THE REGION before the condition fences, so every
  // diagnostic below can anchor on it exactly as `classifyArms`' do.
  Region.Kind = ControlRegion::PhaseKickback;
  Region.Condition = BI->getCondition();
  Region.Pred = Pred;
  Region.Arm = Arm;
  Region.ArmFalse = ArmFalse;
  Region.MergeBB = MergeBB;
  Region.Merge = nullptr;  // there is no GATE φ — see the header note.
  Region.ArmNegated = Negated;
  Region.Shadow.assign(ArmGates.begin(), ArmGates.end());
  Region.ShadowFalse.assign(ArmFalseGates.begin(), ArmFalseGates.end());
  Region.ClassArm = ArmClass::Phase;
  Region.ClassArmFalse = ArmClass::Phase;

  // ---- 5. THE CONDITION MUST BE A LOWERABLE COMPARE, OR A COMPOUND TREE OVER
  // LOWERABLE COMPARES (P3, bd test_C_libtooling-3qlq Inc 1 part B).
  //
  // A bare tainted `i1` (`_Bool b = b0; cq_theta(&b,θ); if (b) cq_phi(θ);`) is NOT
  // this shape and gets its own message: the correct lowering there mints
  // NOTHING — the gate belongs directly on `b`'s own rail — and that is filed as
  // Inc 1b's bare-i1 row (PRD §6.3, §9, owner question Q4 assumed answer).
  //
  // A COMPOUND condition IS this shape since part B. `clang -O1` hands
  // `if (q==5 && r==3) cq_phi(θ)` a `select i1 %a, i1 %b, i1 false` branch
  // condition (MEASURED; and `if (q==5) { if (r==3) cq_phi(θ); }` folds to the
  // BYTE-IDENTICAL function body), so the tree is not an exotic spelling — it is
  // the ONLY spelling the language's `&&` produces. The lowering is the 4.4
  // select's condition NETWORK, now shared through `CondTreeEmit` (Rule 14): one
  // flag rail per leaf, one `|0>` ancilla per `and`/`or`/`xor` node, the root
  // ancilla carrying the whole predicate, and an exact-LIFO strip. `cqrt_rz_i1`
  // then rides the ROOT exactly as it rides a single compare's flag — the
  // kickback argument of §3 does not care how the flag was computed, only that
  // the ancilla is returned to |0> on every branch, which the LIFO strip does.
  //
  // The tree grammar is asked with `AllowLogicalSelect = TRUE`, which the 4.4
  // DATA select deliberately does not do — see SelectClassify.h.
  //
  // ---- TWO MESSAGES ON THE REFUSAL PATH, NOT ONE — Rule-13 round-1 findings
  // F-L3-7 / F-L5-5, MERGED WITH PART B'S TREE ADMISSION (this clause is the one
  // content conflict between the two branches, resolved to keep BOTH behaviours).
  //
  // Part A gave EVERY condition it could not use the message
  // `branch phase on a bare i1 condition`, deliberately ("a compound `select i1`
  // is not a `CmpInst` either, so it takes the same partitioned message"). That
  // was MEASURED FALSE about the two commonest programs reaching it, and a
  // diagnostic REGRESSION against the pre-3qlq oracle, which said `control flow`
  // and was right about both:
  //
  //   `if (c) { if (q==5) cq_phi(θ); }` with `c` a `volatile int`, and
  //   `for(i<3){ if (i) { if (q==5) cq_phi(θ); } … }`
  //
  // Both arrive as `select i1 %classical, i1 %tainted_cmp, i1 false` — a
  // condition TREE, one of them mixing a CLASSICAL guard with a tainted compare,
  // and neither containing a bare `i1` from `cq_theta` anywhere. A user was being
  // sent to look for a `_Bool` that does not exist.
  //
  // PART B NARROWS WHAT REACHES HERE BUT DOES NOT CLOSE THE HOLE: with
  // `AllowLogicalSelect` on, the `&&`/`||`/folded-nest spellings are now
  // ACCEPTED, so they no longer take any message at all — but `collectCondTree`
  // still REFUSES a tree that is structurally off-pattern (the two NOT-carrying
  // complements, a constant child, an over-deep or cross-block tree), and every
  // one of those is still a TREE and still not a bare `i1`. So the split stays,
  // asked only on the refusal:
  //   * NOT an instruction, or a tainted `i1` VALUE (a `cq_theta` result, a
  //     `zext`/`trunc` of one, a load — anything that is not a condition TREE)
  //     keeps `branch phase on a bare i1 condition`. That is the bare-i1 shape,
  //     where the correct lowering mints NOTHING.
  //   * a condition TREE the grammar refuses takes the pre-existing
  //     `control flow` message the oracle used.
  // Keeping the two apart is what lets the bare-i1 fixture stay a
  // DISCRIMINATOR: when that shape is built, its string must stop firing, and
  // under one shared message it would go on firing for every refused tree with
  // no fixture able to tell.
  // bd `3qps` / bd `4aiu` (Track P) — `AllowRailPhi = true`, THE SECOND CALLER
  // (bd dm7f.53 added a third: `classifyArms`' in-place Ry tree, which CALLS
  // this step's 5c ladder through `condTreePhiLeafRefusal`). The grammar now
  // admits a 2-incoming `i1` φ as a leaf at ANY position; everything that makes it an ACCEPT is step 5c's ladder below, not the walk.
  // The emitter re-derives the tree with the IDENTICAL pair of flags, so
  // detection and emission cannot drift (Rule 14).
  CondTree Tree;
  if (!collectCondTree(Region.Condition, Tree, /*AllowLogicalSelect=*/true,
                       /*AllowRailPhi=*/true)) {
    const bool IsCondTree = [&] {
      if (isa<SelectInst>(Region.Condition))
        return true;
      if (const auto *BO = dyn_cast<BinaryOperator>(Region.Condition))
        return BO->getType()->isIntegerTy(1) &&
               (BO->getOpcode() == Instruction::And ||
                BO->getOpcode() == Instruction::Or ||
                BO->getOpcode() == Instruction::Xor);
      return false;
    }();
    diagnoseUnderControl(BI, IsCondTree
                                 ? "control flow"
                                 : "branch phase on a bare i1 condition");
    return PhaseKickbackDisp::Declined;
  }
  // A SINGLE-LEAF tree is the pre-part-B path and every gate below runs exactly
  // as part A wrote it (same order, same strings, byte-identical stream). The
  // extra per-leaf gates are for the COMPOUND path only, and each is an
  // over-decline: with one flag per leaf the mint is no longer ATOMIC, so a leaf
  // the emitter cannot mint must be refused HERE, before the first ancilla
  // exists (the ziov.4 mutate-then-decline class — the same reason
  // `classifySelectRegion` gained its per-leaf ladder).
  const bool IsTree = !Tree.Nodes.empty();
  // SIZE BOUND, stated rather than implied: each leaf costs one flag rail and
  // each node one ancilla, all live simultaneously between the mint and the
  // strip, so an unbounded tree is an unbounded live ancilla set. Eight of each
  // is far past anything `clang -O1` builds from a C `&&`/`||` chain (the
  // measured customers have 1 leaf / 0 nodes and 2 leaves / 1 node); the bound
  // exists so the resource claim is a FACT and not a hope. Over-declining is
  // safe (Prime Directive).
  // bd `4aiu` (Track P): φ leaves count toward the bound like every other leaf —
  // each one is a live control rail between the mint and the strip. L2: the set
  // was widened, so every predicate computed over "the leaves" is re-asked.
  // (bd dm7f.52: the bound is `condTreeTooLarge`, shared with the Ry consumer.)
  if (condTreeTooLarge(Tree)) {
    diagnoseUnderControl(BI, "branch phase condition tree too deep");
    return PhaseKickbackDisp::Declined;
  }
  // A tree with no nodes has exactly ONE leaf, of one of three kinds: a COMPARE
  // (`Cmp`, the pre-1b path, byte-for-byte), a RAIL (`RailCond` — bd 3qlq.4, the
  // `_Bool` register itself: no mint, no strip, no free) or — bd `3qps` — a
  // REGION-MERGE φ (`RailPhiCond`), which by emit time IS that register and is
  // treated identically from here on.
  //
  // A φ leaf needs no local here: every gate it owes is a LOOP over
  // `Tree.RailPhiLeaves` (step 5c and the two wire clauses), and the EMITTER
  // re-derives its own `RailPhiCond` from the same tree.
  auto *Cmp = IsTree || Tree.Leaves.empty() ? nullptr : Tree.Leaves.front();
  CallInst *RailCond =
      !IsTree && !Tree.RailLeaves.empty() ? Tree.RailLeaves.front() : nullptr;
  for (CmpInst *Leaf : Tree.Leaves) {
    // bd dm7f.52: every check of this step is `condTreeCompareLeafRefusal`,
    // shared with the in-place Ry consumer; the notes below describe its
    // clauses, in its order.
    if (const char *Why =
            condTreeCompareLeafRefusal(Leaf, IsTree, Region, Taint, DT)) {
      diagnoseUnderControl(declAnchor(Region), Why);
      return PhaseKickbackDisp::Declined;
    }
    // Q+Q — EXPLICIT, IN THE CONTROL LAYER, FOR EVERY LEAF (Rule-13 round-2
    // F-B2-2; see `kQQCondReason`). `compareFlagMintable` ADMITS a Q+Q leaf (bd
    // adia lifted that decline for the 4.4 select, which does have a Q+Q mint),
    // so it cannot carry this and never could: on the single-compare path the
    // refusal used to happen in the emitter's first `lowerCompareToFlag`, whose
    // null return left the tainted `br` neither claimed nor declined by this
    // layer — the opcode net then reported `no template for opcode 'icmp i1'`.
    // The remaining un-mintable widths / out-of-scope shapes. Asked by the SAME
    // dry-run predicate the mint itself uses (Rule 14), so detection and
    // emission cannot disagree.
    // A CLASSICAL leaf has no quantum flag to mint, and promoting it would put
    // a classical runtime value in the i32 HANDLE slot (the §5.2 prohibition —
    // a phantom rail id aliasing an unrelated qubit). The hybrid
    // classical∧quantum conjunction is out of scope HERE (the branch phase);
    // ⚠ since bd `test_C_libtooling-xdu2.13` the 4.4 DATA select lowers it —
    // the classical child of an `and`/`or` becomes a `cq_template_<op>_i1_hl`
    // LITERAL (`CondLiteral.h`) — so the two consumers no longer agree. This
    // decline is pinned by `condtree_classical_leaf_reject_phase.ll`; widening
    // it means routing the same literal through `emitCondNetwork` for the
    // kickback AND re-asking the literal in `declineQuantumCondLiterals`.
    // (The Q+Q leaf is refused ABOVE, for tree and single-compare alike, with
    // `kQQCondReason`. It used to be refused only HERE, and only for a tree —
    // "keeping the two paths' DISPOSITION identical even though their message
    // differs" — which round-2 finding F-B2-2 showed was not a message
    // difference but a LAYER difference: the single-compare path was declining
    // in the opcode net, not in this one. One question, one spelling, one layer.)
    // An i1-OPERAND leaf is non-canonical (InstCombine rewrites i1 eq/ne to
    // xor/not forms) and would smuggle a boolean NOT past the tree grammar; its
    // mint also passes a raw i1 into the i32 handle slot. The 4.4 select fences
    // it identically (SelectClassify gate 2). Over-decline-safe: no `-O1`
    // canonical shape lands here.
    // The positional half of the stale-condition guard below scans each leaf
    // forward to the branch, which is only a BOUNDED window when the leaf is in
    // `Pred`. A cross-block leaf declines conservatively — exactly what
    // `RegionTreeDetect::staleCond` does for the same reason.
    //
    // ⚠ bd `drbq.12` (2026-09-17) — UNLESS `crossBlockCompareMintable` HAS
    // WALKED THE GAP. The customer is the twin-matrix cell
    // `m_none_ablphi_none_none_binv`, `for (…) { if (b && a == 5) cq_phi(π); }`,
    // whose FLAT twin ACCEPTS on the oracle while the rolled form dies HERE —
    // `a` is loop-invariant, so LICM hoists the `a == 5` leaf out of `Pred`
    // while the `_Bool b` rail leaf stays. This is the SAME question
    // `condWireDisposition`'s P4 asks about a single compare, so it CALLS the
    // same predicate (Rule 14: the drbq Inc-3 (b′) defect is a SECOND SPELLING
    // of a predicate the tree already owned). `ShareCondFlag` needs no clause
    // here — it *"cannot be set for a tree"* (step 5d's own note).
  }
  // ---- 5b. RAIL LEAVES (bd test_C_libtooling-3qlq.4, Inc 1b). A leaf that is
  // the `_Bool` register itself (`isCondRailLeaf`: a `cq_theta_i1` result, root
  // or chained). It mints NOTHING — the register is its own flag — so none of
  // the compare-leaf gates (predicate, template, Q+Q, i1-operand, in-`Pred`)
  // has a subject. What it needs instead:
  //   (i)   tainted — by construction (`cq_theta_i1` is the taint source),
  //         re-asked as defence in depth;
  //   (ii)  NOT measured before the branch (`railMeasuredBeforeReadPoint`,
  //         read point = the branch) —
  //         the mirror of the compare's `MeasuredEarly`;
  //   (iii) the WIRE question, asked below over `Prov` (a rail seeds its own
  //         wire): a non-diagonal gate on the register between its def and
  //         the branch stales the name the branch reads.
  // Its OTHER users are ordinary — it is the user's register, read by
  // measures, compares and arithmetic as before — so the tree-wide "used
  // outside the branch" fence deliberately excludes rail leaves, and the
  // single-leaf `HasDataUse`/`ShareCondFlag` machinery (a COMPARE read as data
  // must share ONE minted flag) has no subject: nothing is minted.
  //
  // ⚠ THE SAME SANCTION IS GRANTED TO A REGION-MERGE φ LEAF (5c), AND IT IS
  // STATED HERE BECAUSE IT IS A MEASURED ACCEPT ASYMMETRY, NOT AN OVERSIGHT —
  // Rule-13 round-1 finding F-P1-3(c). Step 6's `TreeSet` fence is built from
  // `Tree.Leaves` + `Tree.Nodes` only, so NEITHER a rail leaf NOR a φ leaf is
  // asked "are your users inside the tree?". For a COMPARE leaf that fence
  // fires (`control_swap_reject_*` / probe `r25`: `if (q>3 && r>5) cq_phi(θ);`
  // plus a second `if (q>3)` declines `condition used outside the branch`); for
  // a φ leaf with a data use the module ACCEPTS
  // (`control_phase_kickback_mergephi_tree_leaf_data_use.ll`, probe `r08`).
  //
  // WHY THE ASYMMETRY IS SOUND, and it is the rail argument one construct over.
  // The fence exists because a COMPARE leaf's answer lives in a flag this
  // emitter MINTS, STRIPS and FREES inside the region — an out-of-tree reader
  // would read a freed rail, and the single-compare `ShareCondFlag` path (the
  // only sanctioned sharing) cannot be lifted to a tree because the shared
  // object would have to be the ROOT ANCILLA, which is also stripped and freed.
  // A φ leaf mints NOTHING: `CondTreeEmit` maps it to ITSELF (`FlagOf[V] = V`)
  // and the node gate reads it in a `cqrt_toffoli` CONTROL slot — diagonal,
  // read-only, basis-label-preserving — so the register is exactly the value it
  // was and an ordinary out-of-branch consumer lowers through the ordinary
  // opcode net. MEASURED end to end on `r08`: the data use becomes
  // `cq_template_zext_i1_to_i32(h2) -> h5; cq_template_add_i32(h0,h5) -> h6`
  // with its own `_unc` and `cqrt_free(h5)`, the kickback's only reads of `h2`
  // are the two self-inverse toffoli controls, no `cqrt_x` anywhere, and STRICT
  // stage 2b reports `4 rail mint(s) of which 3 left allocated, 3 cqrt_free
  // site(s): 3 verified, 0 violation(s), 0 unproven`.
  //
  // ⚠ RETIREMENT TRIGGER: the day a φ leaf is given a MINT of its own (a copy
  // ancilla, an inverted flag, anything `stripCondNetwork` tears down), this
  // sanction dies with the "nothing is minted" premise and the φ leaves must be
  // added to `TreeSet` at step 6. The rail leaf owes the identical re-derivation
  // at the identical moment; ask both, or neither.
  for (CallInst *Rail : Tree.RailLeaves)
    if (const char *Why = condTreeRailLeafRefusal(Rail, Region, Taint, DT)) {
      diagnoseUnderControl(declAnchor(Region), Why);
      return PhaseKickbackDisp::Declined;
    }
  // ---- 5c. REGION-MERGE-φ LEAVES (bd `3qps` / bd `4aiu`, Track P). Step 5b one
  // construct over: the leaf is not a `cq_theta_i1` CALL but the MERGE φ of a
  // diamond ALREADY in the plan as a controlled in-place Ry / state PREP. It is
  // the SAME ladder `classifySelectRegion`'s §M.0 runs, asked through the SAME
  // helpers, with the BRANCH as the read point instead of the select:
  //
  //   rung 0    the φ is some region's committed `InPlaceRotation` merge —
  //             `preppedRailPhiRegionIdx`, the ONE spelling, CALLED not
  //             re-derived (Rule 14; it is why that helper left `SelectClassify`'s
  //             anonymous namespace);
  //   rung (i)  tainted — true by construction, re-asked as defence in depth;
  //   rung (ii) NOT measured before the BRANCH, asked over the φ's OWN PROVENANCE
  //             CLOSURE and not over the hoisted theta alone. LOAD-BEARING, and
  //             MEASURED as such at the select (bd `boi6` H-2): the user writes
  //             `cq_measure(b1)`, which after `-O1` names the **φ**, while
  //             `railWireNamesBackward` `break`s at the first non-call — so a
  //             closure seeded only from the theta is the singleton `{T}` and the
  //             measurement is INVISIBLE. `condProvenance(P)` is `{P, T}`, which
  //             is ALSO exactly the seed set rung (iii) walks: ONE closure, two
  //             rungs (L2). Probe `p08` is the red-green program;
  //   rung (iii) the WIRE question — `condWireDisposition` over `Prov` below,
  //             which already receives the φ's provenance (see there).
  //
  // ⚠ WHY AN IN-`Pred` φ NEEDS NO `plan` MUTATION, unlike the select's F-M1 edge
  // — AND WHY A φ OUTSIDE `Pred` DOES (bd `hn29`/`leyd`/`52og`, Track P′,
  // 2026-09-15: the heading used to read "WHY THIS DOES NOT NEED A `plan`
  // MUTATION" full stop, and that is now true of one half of the population).
  // A `PhaseKickback` has REAL block fields, so `lowerControlRegions`' bd `hcrg`
  // alias pre-flight already sees that this region's `Pred` IS the prep's
  // `MergeBB` and takes the sanctioned `sequentialChainAlias` edge
  // `Precedes[kickback] = {prep}` — the kickback is emitted FIRST, while the φ is
  // still LIVE, which is precisely what its emitter wants (a φ is just another
  // `Value *` control, and the prep's later M-β RAUW rewrites the emitted gate's
  // operand to the theta call, which `lowerRotations` then RAUWs to the `i32`
  // handle). Recording the SELECT's edge here would demand the OPPOSITE
  // order and close a precedence CYCLE, declining the whole module — and that
  // last clause is true of EVERY φ kickback that lowers, not only of the probed
  // ones (round-1 item 4), because the hcrg edge below is FORCED **whenever its
  // hypothesis holds**:
  //
  //   THE THEOREM (round-1 item 3, attacked and unbroken). `P->getParent() ==
  //   Region.Pred` ∧ `preppedRailPhiRegionIdx(P, plan) = j` ⟹ `P` IS
  //   `plan.Regions[j].Merge`, which lives in `Regions[j].MergeBB` ⟹
  //   `kickback.Pred == prep.MergeBB` ⟹ `MergeBB ∈ doomedBlocks(prep)` ⟹ the
  //   `Aliases` test fires ⟹ EITHER `sequentialChainAlias` returns true (edge
  //   added, `Precedes[kickback] = {prep}`, kickback emitted first with the φ
  //   live) OR `declineRegion` fires and the module lowers nothing. There is no
  //   third outcome.
  //
  // ⚠ THAT HYPOTHESIS IS NO LONGER SUPPLIED BY THE FENCES, AND THE THEOREM IS
  // THEREFORE NOT VACUOUSLY TOTAL ANY MORE. It used to be handed `P->getParent()
  // == Region.Pred` for a TREE by the step-6 positional loop's
  // `P->getParent() != Region.Pred` conjunct and for a φ ROOT by
  // `condWireDisposition`'s `Cond->getParent() != R.Pred → DeclineNow`. Track P′
  // replaced BOTH with `chainedThetaBetweenDefAndBranch`, a real CFG-bounded
  // scan, so a φ leaf may now be admitted from another block — and for exactly
  // those the alias edge is ABSENT and plan order emits the prep first. The
  // record collected below (`PrepIdxs` → `Region.PrepRegionIdxs`) plus the
  // `PhaseKickback` edge loop in `SwapRouteEmit::lowerControlRegions` supply the
  // SAME direction the alias supplied, deduped against it. Read the two together:
  // for an in-`Pred` φ the theorem still forces the order and the record is
  // redundant; for a cross-block φ the record IS the order.
  //
  // ⚠ THE "IN-`Pred` REQUIREMENT" THIS PARAGRAPH IS ABOUT NO LONGER EXISTS
  // (Track P′, bd `hn29`/`leyd`) — but the paragraph is KEPT, because its
  // conclusion was never really about blocks and the multi-φ hazard it describes
  // is unchanged. Read every "in-`Pred`" below as "admitted by this ladder".
  // Track P′'s own customer is the two-CONDITIONALLY-prepped-bools conjunction
  // (`trackP/probes/p20.c` ≡ `trackX/probes/fp_x3_…`), which is TWO SEPARATE
  // diamonds with TWO merge blocks and therefore TWO `R.Merge` fields — it is the
  // shape this paragraph says is fine, not the fused one it says is refused.
  //
  // AT MOST ONE φ LEAF PER REGION, AND THE
  // REASON IS `R.Merge`, NOT BLOCK COUNTING (Rule-13 round-1 finding F-P1-1,
  // with a MEASURED counterexample to the reason that used to be given). It is
  // NOT "two diamonds have two merge blocks": `-O1` FUSES two same-condition
  // preps into ONE diamond whose ONE merge block carries TWO prep φs, both in
  // this kickback's `Pred` (bd `b6ap`'s own construct; probe
  // `review_r1_probes/r07_two_phi_fused.c` — `if (b0) { cq_theta(&b1,.5);
  // cq_theta(&b2,.9); } if (b1 && b2) cq_phi(.3);`). The real invariant is
  // rung 0's: `preppedRailPhiRegionIdx` requires `R.Merge == P` and a
  // `ControlRegion` has exactly ONE `Merge` FIELD, so a fused diamond's SECOND
  // φ matches no region, returns `kNoParent`, and declines the whole tree —
  // whatever block it lives in. (Today an earlier fence absorbs that shape:
  // `soleMergePhi` refuses a 2-φ merge and the region is never recovered, so
  // `r07` declines `nested control flow` identically on both binaries.)
  //
  // ⚠ RETIREMENT TRIGGER for the paragraph above — re-derive it, do not re-read
  // it, the day `soleMergePhi` admits a multi-φ merge or `MergePhiPeel`'s entry
  // gate peels an arm-defined incoming. Two φ leaves in ONE `Pred` is a MEASURED
  // shape, not a hypothetical, and the only thing between it and a two-leaf
  // accept is which φ happens to be the region's `Merge`.
  //
  // ⚠ RETIREMENT TRIGGER — bd `3d8q`. Rung 0 admits a region whose
  // `ClassArm`/`ClassArmFalse` is `InPlaceRotation` with a non-empty `Shadow`.
  // The in-place-ARM φ (a SECOND Ry arm conditioned on a prep's merge φ) is a
  // DECLINE today only because `classifyArms` refuses that region, so it never
  // reaches the plan with that verdict. The day bd `3d8q` flips it to an ACCEPT,
  // its region starts matching this rung and the ladder below (rungs (i)/(ii)/
  // (iii) and step 6's wire disposition) becomes the SOLE fence in front of a
  // NEW population. Re-derive the ladder against that population before landing
  // `3d8q`; do not assume this increment's clearance covers it.
  // ⚠ bd dm7f.53 FIRED THIS TRIGGER (the Ry consumer now admits a φ-leaf tree,
  // so a region conditioned on a φ is itself a claimed `InPlaceRotation` whose
  // merge rung 0 admits — reporter t6.c's third region). RE-DERIVED, not
  // assumed: every rung asks about the φ's own RAIL (the rotated target's
  // register), and how that region's condition was spelled changes nothing a
  // rung reads — rung (ii) walks `condProvenance(φ)`, rung (iii) seeds the same
  // closure, and the region's arm gates are covered only as PRODUCERS of the φ
  // (`condTreeCoveredPhiGates`). Pinned by
  // `control_inplace_ry_tree_mergephi_leaf_chain.ll` and the t6 slice.
  //
  // ⚠ THE REFUSAL STRING IS THE SHAPE'S PRE-INCREMENT ONE, DELIBERATELY, AND IT
  // IS A MEASURED REQUIREMENT RATHER THAN A COURTESY. Admitting the φ at the
  // GRAMMAR moves every φ that rungs 0/(i) then refuse out of
  // `collectCondTree`'s `IsCondTree` split, which is where its message used to
  // come from. Left alone, that silently re-labelled SHIPPED DISCRIMINATOR
  // fixtures: `control_phase_kickback_reject_bare_i1_loop_phi.ll` (bd `boi6`, the
  // loop-carried `_Bool` header φ) went from `branch phase on a bare i1
  // condition` to `control flow` with NO change of disposition — caught by
  // `ir-pass-lit`, and it is exactly the H-8 hazard ("decide ONCE which string a
  // φ takes at every consumer"). So the split is reproduced here verbatim:
  //   * the φ IS the whole condition  → `branch phase on a bare i1 condition`
  //     (a bare `i1` value this consumer does not lower — which is precisely what
  //     an unclaimed φ is, and what that string has always meant);
  //   * the φ is a LEAF of a tree      → `control flow` (a condition TREE the
  //     grammar cannot use — the message the oracle gave, and the one a user
  //     sent looking for a `_Bool` would be misled by).
  // The ONE string that moves in this increment is the one whose DISPOSITION
  // moves: a claimed prep's φ is now an ACCEPT.
  const char *PhiRefusal =
      IsTree ? "control flow" : "branch phase on a bare i1 condition";
  // ⚠ AND THE ANCHOR IS `BI`, NOT `declAnchor(Region)` — Rule 1, "diagnostics
  // carry the offending instruction's `!dbg` so they are SOURCE-LOCATED".
  // `declAnchor` returns `R.Condition`, which for this construct IS THE φ, and a
  // merge φ carries no `!dbg`: every message below came out as
  // `<unknown>:0:0` instead of `p1.c:10:13`. MEASURED, and not by reading — the
  // corpus sweep's FULL-STDERR byte-compare caught it on bd `boi6.a`'s own probe
  // (`trackL/probes/p1.c`, the loop-carried `_Bool` header φ) as a row whose two
  // sides carry the SAME message text and DIFFERENT stderr hashes. That is
  // exactly the hole PROTOCOL S3 says a message-only tag regex hides, and it is
  // why the sweep hashes the whole stream. `BI` is also the anchor
  // `collectCondTree`'s refusal used before this increment, so the φ-root row is
  // byte-identical to the ORACLE's again rather than merely same-string.
  // For a TREE the φ is a leaf and `declAnchor` gives the `and`/`select` ROOT,
  // which does carry a `!dbg` — so that case keeps the established anchor.
  //
  // ⚠ USED BY EVERY DECLINE BELOW THAT CAN NOW SEE A φ CONDITION — the ladder
  // here AND the wire disposition at step 6 — because the same `<unknown>:0:0`
  // loss applies to `condition predates a non-diagonal gate` (probe `p12`, the
  // in-place-ARM φ). For a COMPARE or RAIL condition `RailPhiLeaves` is empty and
  // this IS `declAnchor(Region)` expression-for-expression, so every pre-existing
  // shape's message is byte-identical.
  //
  // ⚠ THE PREMISE HAS TWO HALVES AND THE COMMENT USED TO CARRY ONE (Rule-13
  // round-1 finding F-P1-2). "A merge φ carries no `!dbg`" is the first half;
  // the second is that `-O1` also stamps merge φs with a `!DILocation(line: 0,
  // scope: …)`, so the message comes out as `file.c:0:0` — a FILE with LINE
  // ZERO, not `<unknown>`, and equally unusable. `PhiAnchor` covers both because
  // it never reads the φ's location at all; a future repair that tests
  // `Cond->getDebugLoc()` for null instead would fix only half the class.
  // MEASURED: `review_r1_probes/r16_inplace_arm_phi.c` and `r22` come out at
  // `…c:0:0`, `r12` at `<unknown>:0:0` — all three IDENTICAL on both binaries
  // (pre-existing, not this increment's, and each is a residual site OUTSIDE
  // this classifier: `classifyAngleSelect`'s `rotation angle` and
  // `classifyArms`' `control flow` ×2).
  //
  // ⚠ THE STRUCTURAL LESSON, and it is why F-P2 survived every gate in the tree:
  // NO HAND-WRITTEN `.ll` FIXTURE CAN EVER PIN A DIAGNOSTIC'S LOCATION. The
  // fixtures in `ir-pass/test` carry no debug info, so every decline in all 1946
  // of them is `<unknown>:0:0` whether the anchor is right or wrong; a 0-MISSED
  // injection matrix and a byte-identical 288-file family cannot see it either,
  // because none of them reads a location. The ONLY instrument that can is a
  // `-g`-compiled `.c` probe whose FULL STDERR is byte-compared against the
  // oracle's. Row 14's "identical on both binaries" was itself measured with
  // `.ll` probes (`d_angle`, `d_angle_ry`) and was therefore structurally blind
  // to exactly this property — it was re-measured from C as `r12`.
  Instruction *const PhiAnchor =
      (!IsTree && !Tree.RailPhiLeaves.empty()) ? static_cast<Instruction *>(BI)
                                               : declAnchor(Region);
  // bd `hn29` / `leyd` / `52og` (Track P′) — THE EMISSION-ORDER OBLIGATION,
  // COLLECTED HERE AND COMMITTED AT THE ACCEPT.
  //
  // The comment above ("WHY THIS DOES NOT NEED A `plan` MUTATION") states a
  // THEOREM whose hypothesis is `P->getParent() == Region.Pred`: only then is
  // `kickback.Pred == prep.MergeBB`, only then does the bd `hcrg` `Aliases` test
  // fire, and only then is `Precedes[kickback] = {prep}` FORCED. This increment
  // admits φ leaves that do NOT satisfy that hypothesis, so for them the theorem
  // says nothing and — MEASURED, probe `a1_clean_gap2.ll` — nothing else orders
  // the pair either: the Kahn sort falls back to plan index, which is DETECTION
  // order, which puts the prep FIRST. The prep's M-β then RAUWs the branch
  // operand to the hoisted theta and `flattenRegion` frees the φ, and
  // `emitPhaseKickbackRegion`'s `CondV != R.Condition` identity check turns the
  // whole module into a loud `control flow` decline. Widening the positional
  // fence alone would therefore have moved this shape from one decline string to
  // another and called it a fix.
  //
  // ⚠ SO THE BEAD'S PREMISE IS WRONG AND THE FIXTURE HEADER IS RIGHT (CLAUDE.md
  // L6, run in the other direction). bd `hn29` records that *"the Kahn chain
  // already schedules every kickback before every prep, so the emission order
  // would be right"*. That is TRUE for the two-prep customer (`p20`, where the
  // chain `kickback.Pred == prep2.MergeBB == …` supplies it) and FALSE the
  // moment a block with no region in it sits between the φ and the branch, which
  // is bd `52og`'s whole shape and `..._reject_mergephi_cross_block.ll`'s.
  // `control_phase_kickback_reject_mergephi_cross_block.ll`'s header had it
  // exactly right — *"Break the adjacency and that edge does not fire: nothing
  // then orders the two"*. Do not re-derive the bead's version.
  //
  // WHAT IS RECORDED, and in which DIRECTION. One entry per admitted φ leaf, the
  // index the ONE spelling `preppedRailPhiRegionIdx` just returned — CALLED, not
  // re-derived (Rule 14). `lowerControlRegions` turns each into
  // `Precedes[kickback] = {prep}`: the KICKBACK FIRST, while the φ is still live.
  // ⚠ That is the OPPOSITE direction from the identically-named field on a
  // `SelectRegion` (bd `boi6` F-M1 — "prep before select"), and the asymmetry is
  // the two emitters' opposite needs, not an accident: `SelectMergeEmit` RE-READS
  // its condition and therefore wants M-β to have run, while
  // `emitPhaseKickbackRegion` consumes the φ AS A VALUE and wants it still there.
  // The edge loop in `SwapRouteEmit` keys on `Kind`, so the two can never be
  // confused; both are spelled out at the field's declaration in `ControlPlan.h`.
  // ⚠ ONLY THE **CROSS-BLOCK** LEAVES ARE RECORDED, AND THAT IS WHAT MAKES THIS
  // INCREMENT ZERO-RISK IN THE DECLINE DIRECTION — BY CONSTRUCTION, NOT BY
  // ARGUMENT. For an in-`Pred` φ the theorem above still FORCES the hcrg alias
  // edge, so a record would be redundant; leaving it out means every kickback
  // that lowered before this increment carries an EMPTY `PrepRegionIdxs`, its
  // plan is bit-identical, and the new edge loop in `SwapRouteEmit` is a literal
  // no-op for it. A record-everything-and-dedupe spelling would have been
  // arithmetically equivalent *given* that the alias edge always exists, which is
  // a claim about `coordinated()` and `sequentialChainAlias`'s own preconditions
  // that this track has not measured. Narrowing the WRITE is cheaper than
  // proving the dedupe total. (The dedupe in the edge loop is kept anyway, as
  // defence in depth for a future widening of what gets recorded.)
  SmallVector<unsigned, 2> PrepIdxs;
  // (bd dm7f.53: rungs 0/(i)/(ii) are `condTreePhiLeafRefusal`, shared with the
  // in-place Ry consumer; same order, same strings, same anchor.)
  for (PHINode *P : Tree.RailPhiLeaves) {
    unsigned PrepIdx = ControlRegion::kNoParent;
    switch (condTreePhiLeafRefusal(P, Region, plan, Taint, DT, PrepIdx)) {
    case PhiLeafRefusal::Unclaimed:
      diagnoseUnderControl(PhiAnchor, PhiRefusal);
      return PhaseKickbackDisp::Declined;
    case PhiLeafRefusal::MeasuredEarly:
      diagnoseUnderControl(PhiAnchor,
                           "condition measured before the control route");
      return PhaseKickbackDisp::Declined;
    case PhiLeafRefusal::None:
      break;
    }
    if (P->getParent() != Region.Pred)
      PrepIdxs.push_back(PrepIdx);
  }
  // RUNG (ii) FOR THE COMPARE LEAVES — Track A.1, bd test_C_libtooling-r903
  // item (b). THE PARITY REPAIR, and the one-token discriminator is the whole
  // argument: `int q = 0; cq_theta(&q,.5); int m = cq_measure(q); if (q > 3)
  // cq_phi(.3);` ACCEPTED and emitted `cq_template_icmp_sgt_i32_hl(%h, 3)` AFTER
  // `cqrt_measure_i32(%h)` — a flag minted from a COLLAPSED register, Rule 6's
  // loud-reject class — while its `_Bool` twin (`bool b = 0; cq_theta(&b,.5);
  // m = cq_measure(b); if (b) cq_phi(.3);`) DECLINED through step 5b's rail
  // rung (ii) above. Same ladder, same helper, same string; the read point is
  // `Pred->getTerminator()` because the kickback's stream lands AT the branch,
  // so a `cq_measure` user (never a terminator) in `Pred` always precedes it.
  //
  // NOT FOLDED INTO `condDataUseDisposition`'s `MeasuredEarly` below, and the
  // two must stay apart: that one asks whether the FLAG's own data lineage was
  // collapsed before the stream (the ziov `atk9` share-path hazard), this one
  // asks whether the condition REGISTER was. A program can fail either
  // independently, and the share path has no subject when the compare has no
  // data use at all — which is exactly the shape above.
  //
  // Asked for BOTH the single-compare and the tree spellings: `Tree.Leaves` is
  // populated in either case (the single compare is a one-leaf tree).
  if (CmpInst *Bad = condCmpMeasuredBeforeReadPoint(
          Tree.Leaves, Region.Pred->getTerminator(), Taint, DT)) {
    (void)Bad;
    diagnoseUnderControl(declAnchor(Region),
                         "condition measured before the control route");
    return PhaseKickbackDisp::Declined;
  }

  // Every NODE must live in `Pred` too. Two reasons, both concrete: the network
  // is emitted at the branch, so a node defined elsewhere is either not
  // available there or is shared with code this region does not own; and the
  // `ClaimedSelects` hand-off below is what stops the caller's tainted-`select`
  // scan from ALSO claiming a logical-select node as an i1 data mux — that scan
  // is per-block and runs after the block's own terminator, so a node in another
  // block could be visited BEFORE this region claims it.
  // (bd dm7f.52: asked, together with the `TreeSet` fence below, by
  // `condTreeShapeRefusal` — the nodes-in-`Pred` half first, as here.)

  // ---- 6. THE CONDITION'S DATA USES AND ITS WIRE — `classifyArms`' fences,
  // verbatim in content, order and string.
  //
  // FOR A COMPOUND TREE (P3) BOTH ARE ASKED OVER THE WHOLE TREE, and the data-use
  // question is asked STRUCTURALLY rather than through `condDataUseDisposition`:
  // a leaf's legitimate user IS a tree node, so "any non-`br` user" is the wrong
  // test. Every tree instruction's users must lie inside the tree or be the
  // branch itself. A use OUTSIDE it declines `condition used outside the branch`
  // — the string `RegionTreeDetect` already uses for exactly this situation, and
  // for exactly this reason: there is no shared-flag path here. The ziov
  // `ShareCondFlag` accept is SINGLE-COMPARE ONLY and cannot be lifted to a tree
  // by inspection: the shared object would have to be the ROOT ANCILLA, which
  // this emitter strips and frees inside the region, so a downstream data use
  // would read a freed rail. Sharing a tree's predicate is a real capability and
  // a separate increment, not a side effect of this one.
  //
  // ⚠ `TreeSet` IS `Leaves` + `Nodes` AND NOT `RailLeaves` / `RailPhiLeaves`,
  // DELIBERATELY — Rule-13 round-1 finding F-P1-3(c), and the argument is step
  // 5b's header, which is the one place it is written out. Both excluded leaf
  // species mint NOTHING (`CondTreeEmit` maps them to themselves and the node
  // gate reads them as read-only diagonal controls), so there is no ancilla an
  // out-of-branch reader could read after this emitter freed it — which is the
  // hazard this fence is about. A COMPARE leaf's flag IS minted, stripped and
  // freed here, so it stays inside the set. ACCEPT pin:
  // `control_phase_kickback_mergephi_tree_leaf_data_use.ll` (a φ leaf with a
  // `zext`+`add` data use after the region); DECLINE pin: any compare-leaf twin
  // (probe `r25`). Widen the set the day either species acquires a mint.
  if (IsTree)
    if (const char *Why = condTreeShapeRefusal(Tree, Region, BI)) {
      diagnoseUnderControl(declAnchor(Region), Why);
      return PhaseKickbackDisp::Declined;
    }
  bool HasDataUse = false;
  if (!IsTree && Cmp)  // a RAIL's data uses are ordinary (5b) — no share path.
    for (const User *U : Region.Condition->users())
      if (!isa<BranchInst>(U)) {
        HasDataUse = true;
        break;
      }
  if (HasDataUse) {
    switch (condDataUseDisposition(Cmp, Region.Pred, Taint)) {
    case CondDataDisp::ShareOk:
      Region.ShareCondFlag = true;
      break;
    case CondDataDisp::MeasuredEarly:
      diagnoseUnderControl(declAnchor(Region),
                           "condition measured before the control route");
      return PhaseKickbackDisp::Declined;
    case CondDataDisp::Unowned:
      diagnoseUnderControl(declAnchor(Region),
                           "condition data use neither escaped nor measured");
      return PhaseKickbackDisp::Declined;
    case CondDataDisp::Unlowerable:
      diagnoseUnderControl(declAnchor(Region),
                           "condition data use has no template");
      return PhaseKickbackDisp::Declined;
    }
  }

  // The provenance seed set. For a COMPOUND tree it is the UNION over the LEAVES
  // (the 4.4 select's gate-2c rule, verbatim): a walk seeded from the root alone
  // would cross the tree nodes, which carry no rotation wire of their own, and a
  // walk seeded from ONE leaf would accept a chained theta staling the OTHER
  // leaf's wire. The nodes need no seed — an `and`/`or` result's basis
  // provenance IS the union of its leaves'.
  SmallPtrSet<Value *, 16> Prov;
  if (IsTree) {
    // bd dm7f.52: the leaf-union seed set (compare, rail and φ leaves — see
    // the bd 3qlq.4 / `4aiu` notes above) is `condTreeProvenance`, shared with
    // the in-place Ry consumer.
    condTreeProvenance(Tree, Taint, Prov);
  } else {
    // bd `3qps`: for a φ ROOT this is `condProvenance(φ)` — the same closure step
    // 5c's rung (ii) walked, by construction rather than by a second call.
    condProvenance(Region.Condition, Taint, Prov);
  }
  // The flag is minted at the BRANCH. A tainted-operand `cq_theta` (a
  // NON-DIAGONAL Ry, which genuinely moves the register) between the compare and
  // the branch makes that mint read a different basis than the source compare —
  // the wrong branch is marked and the strip does not return the flag to |0⟩.
  //
  // ⚠ P1's `ProvenPostRegion` HALF IS AN ACCEPT HERE, and the reason is exactly
  // the argument drbq Inc 3 used to widen it from `!SawPhaseArm` to
  // `!(SawPhaseArm || SawRotationArm)`: `ProvenPostRegion` means the offending
  // gate is proven to execute AFTER this region, and a kickback — which copies
  // nothing, replays nothing and allocates no work rail — leaves nothing behind
  // for that later gate to invalidate. A kickback is strictly LESS invasive than
  // an in-place rotation arm, which already carries the accept. So the
  // disposition is: DeclineNow declines, ProvenPostRegion accepts.
  // bd 3qlq.4: a single RAIL condition asks `railCondWireDisposition` — the
  // same walker over the same `Prov`, minus the two prongs that have no subject
  // for a register (see its header); a tree with rail leaves goes through
  // `condWireDisposition` unchanged, its root being a `Pred`-resident node and
  // the rails' wires riding in `Prov`.
  //
  // ⚠ bd `3qps` (Track P) — A φ CONDITION TAKES THE `condWireDisposition` ARM,
  // DELIBERATELY, AND THE TERNARY IS UNCHANGED TO SAY SO (L3: when a set is
  // narrowed, ask what OTHER predicate names the same object — and the answer is
  // not always "narrow it too"). `RailCond` is a `CallInst *` and stays one, so a
  // φ root falls to the compare arm, which is STRICTLY MORE CONSERVATIVE: it adds
  // the same-block positional scan (the φ is the first instruction of `Pred`, so
  // its window to the branch is bounded and real) and the `ShareCondFlag` prong
  // (vacuous here — nothing is minted for a φ, so the flag cannot outlive the
  // region). `railCondWireDisposition` drops those two on a ground argued about a
  // `cq_theta_i1` NAME, and transplanting an unmeasured structural argument onto
  // a different species is how an over-accept ships.
  // bd `hn29` / `52og` (Track P′) — the THIRD argument of that compare arm. A φ
  // ROOT is exactly the case `PhiAnchor` already identifies (`!IsTree` and a
  // non-empty `RailPhiLeaves`), and by the time control reaches here step 5c has
  // run rung 0 on it — `preppedRailPhiRegionIdx(P, plan) != kNoParent`, the ONE
  // spelling, CALLED — so "claimed" is a fact this function was handed, not one
  // it re-derives (Rule 14). It flips ONLY P4's cross-block bail into the
  // CFG-bounded scan; the wire walk, `ShareCondFlag` and the DT prong are
  // untouched, and every non-φ condition passes the parameter's default.
  const bool PhiRootCond = !IsTree && !Tree.RailPhiLeaves.empty();
  // bd dm7f.53 — the claimed φ leaves' on-ancestry arm gates (see
  // `condTreeCoveredPhiGates`), for a TREE and for a φ ROOT alike: a φ root is
  // the one-leaf tree `collectCondTree` returned (its `RailPhiLeaves` holds it),
  // there is no other leaf to read a pre-region name, so its region's arm gates
  // are covered outright. A compare or rail condition has no φ leaf: empty set,
  // shipped walk.
  SmallPtrSet<const CallInst *, 4> CoveredPhiGates;
  if (IsTree || PhiRootCond)
    condTreeCoveredPhiGates(Tree, plan, Taint, CoveredPhiGates);
  if ((RailCond ? railCondWireDisposition(Region, Taint, Prov, DT)
                : condWireDisposition(Region, Taint, Prov, DT, PhiRootCond,
                                      CoveredPhiGates.empty()
                                          ? nullptr
                                          : &CoveredPhiGates)) ==
      CondWireDisp::DeclineNow) {
    // `PhiAnchor` == `declAnchor(Region)` for every compare/rail condition; it
    // differs ONLY when the condition IS a merge φ, which carries no `!dbg`
    // (Rule 1 — see step 5c's anchor note).
    diagnoseUnderControl(PhiAnchor, "condition predates a non-diagonal gate");
    return PhaseKickbackDisp::Declined;
  }
  // `condWireDisposition`'s POSITIONAL prong scans from `R.Condition` (the tree
  // ROOT) to the branch. For a compound tree the LEAVES are defined before the
  // root, so that window does not cover them — scan each leaf's own window too
  // (all leaves are in `Pred`, proven above). Same predicate, same string; it
  // only ever DECLINES more.
  //
  // bd `4aiu` (Track P) — A φ LEAF GETS THE SAME SCAN, and the choice is worth a
  // sentence because it is NOT what a RAIL leaf gets. `railCondWireDisposition`
  // drops the positional prong on a STRUCTURAL ground specific to a
  // `cq_theta_i1` name (M-C's G6 refuses the in-place `add`/`xor` conversion on a
  // register that is read later by its own branch). That ground is an argument
  // about a CALL, and a φ is not one; rather than transplant it unmeasured, the
  // φ keeps the strictly more conservative compare-leaf treatment. A φ ROOT gets
  // it from `condWireDisposition` itself (its `Cond` IS the φ, in `Pred`), so
  // this loop is the tree spelling of the same window. Over-declining is safe
  // (Prime Directive); the measured customers scan an empty-or-pure window.
  if (IsTree && condTreeLeafWindowStale(Tree, Region, Taint, DT)) {
    // (bd dm7f.52: the per-leaf window scan described above is
    // `condTreeLeafWindowStale`, shared with the in-place Ry consumer.)
    diagnoseUnderControl(declAnchor(Region),
                         "condition predates a non-diagonal gate");
    return PhaseKickbackDisp::Declined;
  }

  // ---- 7. LOOPS (P6). A region on a CFG cycle is admitted only when
  // `flatRegionRollableInLoop` proves it sits wholly inside ONE reducible
  // `LoopInfo` loop at one depth with a single latch and no second cycle through
  // the entry — the 8h7d.5 predicate, unchanged and asked from here for the same
  // reason `handleBranchRegion` asks it for a flat region: BEFORE anything
  // mutates the CFG. Everything else on a cycle (irreducible, multi-latch,
  // nested) keeps the existing decline and its existing string.
  //
  // A kickback needs NOTHING from the round-2 rail collapse: it emits no gate on
  // the loop-carried register, so `collapseFlattenedLoopRails` finds nothing to
  // collapse for it and `staleRailRecordRead` has no rail record to invalidate.
  if (regionEntryInLoop(BI)) {
    if (!LI || !flatRegionRollableInLoop(Region, *LI)) {
      diagnoseUnderControl(BI, "control flow inside a loop body");
      return PhaseKickbackDisp::Declined;
    }
    Region.InLoop = true;
  }
  // ACCEPT. Claim every LOGICAL `select i1` node of the condition tree so the
  // caller's tainted-select scan leaves it alone — see the header note; without
  // this the flagship `&&` customer SIGSEGVs in `emitSelectRegion`.
  if (ClaimedSelects)
    for (Instruction *N : Tree.Nodes)
      if (isa<SelectInst>(N))
        ClaimedSelects->insert(N);
  // bd `hn29` / `leyd` / `52og` (Track P′) — COMMIT the order record collected at
  // step 5c, and commit it HERE rather than there. `Region` is the caller's
  // SCRATCH object: `handleBranchRegion` only `push_back`s it on `Accept`, and on
  // `NotApplicable` it resets it — but a `Declined` return leaves it untouched,
  // so a field written mid-ladder would be visible to nothing yet would still be
  // a write to a half-classified region. Writing it at the single accept exit
  // keeps "the plan records only what the ladder proved" literally true.
  // Empty for every compare/rail-conditioned kickback, so the pre-existing
  // population's plan is bit-identical.
  Region.PrepRegionIdxs = PrepIdxs;
  return PhaseKickbackDisp::Accept;
}


// ── bd test_C_libtooling-3qlq Inc 1 part B — P4, the GENUINE depth-2 NEST ────
//
// `if (COND1(q)) { …cq_phi…; if (COND2(q)) { …cq_phi… } }` that `clang -O1` did
// NOT fold into one compound branch (PRD §6.2 row P4). The fold is the normal
// outcome and it is P3 — SimplifyCFG turns `if(a){if(b) X;}` into
// `br (a && b)` whenever the outer arm holds nothing but the inner branch, and
// the two `@slice` bodies are then BYTE-IDENTICAL (measured). What keeps a nest
// GENUINE is content in the outer arm: an opaque `call void @cq_phi(double)` is
// not speculatable, so the two levels survive.
//
// WHY THIS IS ONE REGION AND NOT THE 4.3 PARENT/CHILD PAIR. The 4.3 nest
// (`NestedRouteEmit`, deleted in 3qlq part B) existed to ROUTE: it cswapped `q`
// onto rail1 under f1, replayed the outer arm's Rz there, minted f2 FROM RAIL1
// (the register `%g` was stale on the f1=1 path), and tore the two levels down
// LIFO. Every one of those steps was a consequence of
// the arm gate CARRYING A REGISTER. Under D1/D2 it does not: `cq_phi` is
// `void(double)`, no register is relabelled anywhere in the nest, so the inner
// condition reads exactly the registers it reads in the source and its flag can
// be minted at the OUTER branch from those same registers. What is left is pure
// boolean algebra — the inner arm fires iff `c1 ∧ c2` — which is ONE
// `cqrt_toffoli` onto a fresh |0> ancilla, i.e. the SAME conjunction node the
// 4.4 select network has always used and that P3 now uses for `&&`. Two rails
// (the two condition roots) plus one ancilla, versus the retired route's two
// work rails and four `cqrt_cswap`.
//
// THE EMITTED UNITARY, stated so it can be checked without running anything.
// With f1 = c1(x) and f2 = c2(x) minted into |0> ancillas and
// g = (f1 ⊕ NegOuter) ∧ (f2 ⊕ NegInner):
//   * the OUTER arm's phases ride f1 (X-bracketed when the outer content arm is
//     the false successor), so branch x picks up e^{iθ} exactly when x is in the
//     outer arm — which is what the source says, since the outer arm's phase
//     calls run whenever the outer condition holds, inner condition or not;
//   * the INNER arm's phases ride g, i.e. exactly when BOTH hold;
//   * every ancilla is returned to |0> on EVERY branch (the toffoli is its own
//     inverse, each `_unc` strip is a permutation) and freed clean (Rule 6).
// No gate anywhere in this region takes a data register as an operand, so no
// register-side fence (R4 disjoint wires, R6 stale record, the structural
// freeze) has a subject here — exactly as for the flat kickback.
//
// SCOPE, and it is deliberately narrow. The outer arm may hold phase calls and
// the inner condition tree AND NOTHING ELSE; a `cq_theta` there is the MIXED
// nest (prep-b's `slice_control_phase_nest_deep.c`) and stays a decline — an Ry
// in the outer arm RELABELS a register, which would make the inner flag minted
// at the outer branch read a different basis than the source compare, the very
// staleness the guards below exist to refuse. Depth 3+, an if/else at either
// level, a merge φ of any kind, a value arm, a loop, and a condition used
// outside its own branch all decline.
PhaseKickbackDisp classifyPhaseKickbackNest(
    BranchInst *BI, TaintSet &Taint, ControlRegion &Region,
    const DominatorTree *DT, const LoopInfo *LI,
    SmallPtrSetImpl<BranchInst *> *ClaimedBranches,
    SmallPtrSetImpl<Instruction *> *ClaimedSelects) {
  if (!BI->isConditional())
    return PhaseKickbackDisp::NotApplicable;
  BasicBlock *Pred = BI->getParent();
  BasicBlock *S0 = BI->getSuccessor(0);
  BasicBlock *S1 = BI->getSuccessor(1);

  // ---- 1. SHAPE. Exactly ONE outer successor ends in a tainted conditional
  // branch (the inner diamond); the other is the shared merge, reached straight
  // from `Pred`. Both or neither is not a one-content-arm nest — the same
  // criterion-1 partition `recoverRegionTree` uses, and for the same reason.
  const bool T0 = hasTaintedCondBranch(S0, Taint);
  const bool T1 = hasTaintedCondBranch(S1, Taint);
  if (T0 == T1)
    return PhaseKickbackDisp::NotApplicable;
  BasicBlock *Mid = T0 ? S0 : S1;
  BasicBlock *Merge = T0 ? S1 : S0;
  const bool OuterNeg = !T0;
  if (Mid->getSinglePredecessor() != Pred)
    return PhaseKickbackDisp::NotApplicable;
  auto *InnerBI = dyn_cast<BranchInst>(Mid->getTerminator());
  if (!InnerBI || !InnerBI->isConditional())
    return PhaseKickbackDisp::NotApplicable;
  BasicBlock *IS0 = InnerBI->getSuccessor(0);
  BasicBlock *IS1 = InnerBI->getSuccessor(1);
  BasicBlock *InnerArm = nullptr;
  bool InnerNeg = false;
  if (IS1 == Merge && uncondSucc(IS0) == Merge &&
      IS0->getSinglePredecessor() == Mid) {
    InnerArm = IS0;
  } else if (IS0 == Merge && uncondSucc(IS1) == Merge &&
             IS1->getSinglePredecessor() == Mid) {
    InnerArm = IS1;
    InnerNeg = true;
  } else {
    // Also the DEPTH CAP: a depth-3 inner arm ends in a tainted `br`, so
    // `uncondSucc` is null and neither orientation matches.
    return PhaseKickbackDisp::NotApplicable;
  }
  // The merge must be the clean THREE-predecessor join {Pred, Mid, InnerArm} —
  // the same thing the flat kickback asks of its two-predecessor merge, and for
  // the same two reasons: `flattenRegionTree` erases all three arms and would
  // silently destroy a fourth edge, and the block-lifetime pre-flight in
  // `lowerControlRegions` reads this region's doomed set off these fields.
  if (!Merge->hasNPredecessors(3))
    return PhaseKickbackDisp::NotApplicable;
  {
    SmallPtrSet<const BasicBlock *, 4> Want{Pred, Mid, InnerArm};
    for (const BasicBlock *PB : predecessors(Merge))
      if (!Want.count(PB))
        return PhaseKickbackDisp::NotApplicable;
  }
  // ANY φ in the merge makes this NotApplicable. The flat path can claim ONE
  // 2-incoming `phi double` as a merge-tail ANGLE (`phaseAngleTail`); a 3-pred
  // merge φ has three incomings and that predicate refuses it outright, so there
  // is no φ this emitter knows how to account for — and a φ left standing in a
  // block `flattenRegionTree` splices away is a BROKEN MODULE at `opt` exit 0
  // (measured on the flat path in part A). Refuse rather than flatten over it.
  if (!Merge->phis().empty())
    return PhaseKickbackDisp::NotApplicable;

  // ---- 2. THE TWO CONDITION TREES, through the shared grammar (Rule 14). A
  // level whose condition is neither a compare nor a decomposable tree is the
  // bare-i1 shape composed with a nest — out of scope, and NotApplicable so the
  // ordinary `recoverRegion` fall-through owns the (loud) decline.
  CondTree OuterTree, InnerTree;
  if (!collectCondTree(BI->getCondition(), OuterTree,
                       /*AllowLogicalSelect=*/true) ||
      !collectCondTree(InnerBI->getCondition(), InnerTree,
                       /*AllowLogicalSelect=*/true))
    return PhaseKickbackDisp::NotApplicable;

  // ---- 3. ARM CONTENT.
  //   Mid       = { N × call void @cq_phi(double), the INNER condition tree, br }
  //   InnerArm  = { M × call void @cq_phi(double), br }
  // with N + M >= 1. Mid's membership test is by SET rather than by position, so
  // a compare scheduled before the phase calls is admitted (nothing in the tree
  // has an ordering requirement — the network reads the leaves' OPERANDS, not
  // the compares). ANYTHING ELSE in either block — an Ry, a value op, a store —
  // is off-pattern and falls through to the ordinary loud decline.
  SmallPtrSet<const Value *, 8> InnerTreeSet;
  for (CmpInst *L : InnerTree.Leaves)
    InnerTreeSet.insert(L);
  for (Instruction *N : InnerTree.Nodes)
    InnerTreeSet.insert(N);
  SmallVector<Instruction *, 4> MidGates, InnerGates;
  for (Instruction &I : *Mid) {
    if (I.isTerminator())
      break;
    auto *CI = dyn_cast<CallInst>(&I);
    if (CI && isRegisterFreePhaseCall(CI, Taint) && CI->arg_size() == 1) {
      MidGates.push_back(CI);
      continue;
    }
    if (InnerTreeSet.count(&I))
      continue;  // part of the inner condition, consumed by the network.
    return PhaseKickbackDisp::NotApplicable;
  }
  for (Instruction &I : *InnerArm) {
    if (I.isTerminator())
      break;
    auto *CI = dyn_cast<CallInst>(&I);
    if (!CI || !isRegisterFreePhaseCall(CI, Taint) || CI->arg_size() != 1)
      return PhaseKickbackDisp::NotApplicable;
    InnerGates.push_back(CI);
  }
  if (InnerArm->size() != InnerGates.size() + 1)
    return PhaseKickbackDisp::NotApplicable;
  if (MidGates.empty() && InnerGates.empty())
    return PhaseKickbackDisp::NotApplicable;  // an identity nest is nobody's.

  // ---- 4. EVERY ANGLE IS CLASSICAL (Rule 3), same dialect and string as the
  // flat path's.
  for (ArrayRef<Instruction *> Gates : {ArrayRef<Instruction *>(MidGates),
                                        ArrayRef<Instruction *>(InnerGates)})
    for (Instruction *G : Gates)
      if (Taint.Tainted.count(cast<CallInst>(G)->getArgOperand(0))) {
        diagnoseUnderControl(G, "rotation angle");
        return PhaseKickbackDisp::Declined;
      }

  // ---- 4b. POPULATE before the condition fences so every diagnostic anchors on
  // the region exactly as the flat classifier's do.
  Region.Kind = ControlRegion::PhaseKickbackNest;
  Region.Condition = BI->getCondition();
  Region.InnerCondition = InnerBI->getCondition();
  Region.Pred = Pred;
  Region.Arm = Mid;
  Region.ArmFalse = InnerArm;
  Region.MergeBB = Merge;
  Region.Merge = nullptr;
  Region.ArmNegated = OuterNeg;
  Region.InnerArmNegated = InnerNeg;
  Region.Shadow.assign(MidGates.begin(), MidGates.end());
  Region.ShadowFalse.assign(InnerGates.begin(), InnerGates.end());
  Region.ClassArm = ArmClass::Phase;
  Region.ClassArmFalse = ArmClass::Phase;

  // ---- 5. PER-LEVEL CONDITION LADDER. Identical in content to P3's, run twice.
  // The `HomeBB` argument is the block the level's tree must live in: `Pred` for
  // the outer level, `Mid` for the inner (a tree hoisted into `Pred` is admitted
  // for the inner level too — it is still available at the outer branch, which
  // is where BOTH networks are minted).
  auto levelOk = [&](const CondTree &T, BasicBlock *HomeBB,
                     BranchInst *LevelBI) -> bool {
    constexpr size_t kMaxLeaves = 8;
    constexpr size_t kMaxNodes = 8;
    if (T.Leaves.size() + T.RailLeaves.size() > kMaxLeaves ||
        T.Nodes.size() > kMaxNodes) {
      diagnoseUnderControl(BI, "branch phase condition tree too deep");
      return false;
    }
    for (CmpInst *Leaf : T.Leaves) {
      if (!comparePredLowerable(Leaf)) {
        diagnoseUnderControl(BI, "control condition has no template");
        return false;
      }
      // Q+Q first, and with the PHASE PATH'S OWN STRING (Rule-13 round-2
      // F-B2-2, `kQQCondReason`) — the same question P1 asks one classifier up,
      // so the two cannot drift about what a Q+Q condition is called.
      if (Taint.Tainted.count(Leaf->getOperand(0)) &&
          Taint.Tainted.count(Leaf->getOperand(1))) {
        diagnoseUnderControl(BI, kQQCondReason);
        return false;
      }
      if (!compareFlagMintable(Leaf, Taint) || !Taint.Tainted.count(Leaf) ||
          Leaf->getOperand(0)->getType()->isIntegerTy(1)) {
        // Un-mintable width / out-of-scope predicate, a CLASSICAL leaf (nothing
        // to mint — the §5.2 classical-as-handle prohibition), or an i1-operand
        // leaf (a smuggled boolean NOT). Each would fail MID-network, which is
        // the ziov.4 mutate-then-decline class; refuse here.
        diagnoseUnderControl(BI, "control flow");
        return false;
      }
      if (Leaf->getParent() != HomeBB && Leaf->getParent() != Pred) {
        diagnoseUnderControl(BI, "control flow");
        return false;
      }
      // THE DOMINANCE FACT THE WHOLE NEST RESTS ON, asked rather than assumed:
      // BOTH networks are minted at the OUTER branch, so every leaf OPERAND must
      // be available there. It is structural — `Mid` defines nothing but void
      // phase calls and the tree itself, so no leaf operand can be defined in
      // `Mid` or in `InnerArm` — but a structural fact that is load-bearing for
      // a use-before-def is worth a line of code rather than a line of prose.
      for (Value *Op : Leaf->operands())
        if (auto *OpI = dyn_cast<Instruction>(Op))
          if (OpI->getParent() == Mid || OpI->getParent() == InnerArm) {
            diagnoseUnderControl(BI, "control flow");
            return false;
          }
    }
    // bd 3qlq.4 — RAIL LEAVES at either level: the same three questions the
    // flat classifier asks (5b), plus one the nest owns: the rail must be
    // defined OUTSIDE the nest's own blocks, because both networks are emitted
    // at the OUTER branch and a `cq_theta_i1` inside `Mid`/`InnerArm` is not
    // hoistable (it is a rotation under the outer condition, not a phase call —
    // the `Mid` content scan above already refuses it, since rail leaves are
    // deliberately NOT in `InnerTreeSet`; this is the belt to that brace).
    for (CallInst *Rail : T.RailLeaves) {
      if (!Taint.Tainted.count(Rail) || Rail->getParent() == Mid ||
          Rail->getParent() == InnerArm) {
        diagnoseUnderControl(BI, "control flow");
        return false;
      }
      if (railMeasuredBeforeReadPoint(Rail, Pred->getTerminator(), Taint,
                                      DT)) {
        diagnoseUnderControl(BI, "condition measured before the control route");
        return false;
      }
    }
    for (Instruction *N : T.Nodes)
      if (N->getParent() != HomeBB && N->getParent() != Pred) {
        diagnoseUnderControl(BI, "control flow");
        return false;
      }
    // DATA USES, structurally: every tree instruction's users must be inside the
    // SAME tree or be that level's own branch. There is no shared-flag path here
    // (the roots are stripped and freed inside the region), so an outside use
    // would read a freed rail.
    SmallPtrSet<const Value *, 16> TreeSet;
    for (CmpInst *Leaf : T.Leaves)
      TreeSet.insert(Leaf);
    for (Instruction *N : T.Nodes)
      TreeSet.insert(N);
    for (const Value *V : TreeSet)
      for (const User *U : V->users())
        if (U != LevelBI && !TreeSet.count(U)) {
          diagnoseUnderControl(BI, "condition used outside the branch");
          return false;
        }
    // STALE-CONDITION guard, the `RegionTreeDetect::staleCond` form (Rule 14 —
    // the same two prongs, the same string): position-free, router-crossing wire
    // walk over the level's whole leaf-union provenance, plus a bounded
    // positional scan from each leaf to its own block's terminator. The
    // positional prong is exact here for a reason worth stating: `Mid` contains
    // ONLY void phase calls and the tree, so nothing between the inner compare
    // and the outer branch can move a wire — a `cq_theta` anywhere near this
    // region is caught by the position-free prong.
    SmallPtrSet<Value *, 16> Prov;
    for (CmpInst *Leaf : T.Leaves)
      condProvenance(Leaf, Taint, Prov);
    for (CallInst *Rail : T.RailLeaves)
      condProvenance(Rail, Taint, Prov);  // bd 3qlq.4: the register's own wire.
    SmallVector<Value *, 16> Seeds(Prov.begin(), Prov.end());
    if (findNonDiagonalWireGate(Seeds, /*CrossValueRouting=*/true,
                                /*EmitPoint=*/nullptr, /*DT=*/nullptr,
                                &Taint)) {
      diagnoseUnderControl(BI, "condition predates a non-diagonal gate");
      return false;
    }
    for (CmpInst *Leaf : T.Leaves) {
      const Instruction *Term = Leaf->getParent()->getTerminator();
      for (const Instruction *I = Leaf->getNextNode(); I && I != Term;
           I = I->getNextNode()) {
        const auto *CI = dyn_cast<CallInst>(I);
        if (!CI)
          continue;
        const Function *F = CI->getCalledFunction();
        if (F && F->getName().starts_with("cq_theta_") &&
            CI->arg_size() >= 1 && Taint.Tainted.count(CI->getArgOperand(0))) {
          diagnoseUnderControl(BI, "condition predates a non-diagonal gate");
          return false;
        }
      }
    }
    return true;
  };
  if (!levelOk(OuterTree, Pred, BI) || !levelOk(InnerTree, Mid, InnerBI))
    return PhaseKickbackDisp::Declined;
  // bd 3qlq.4 — a NEGATED level whose root is a bare RAIL is a RESIDUAL of Inc
  // 1b, declined with the bare-i1 string. The nest's conjunction ancilla
  // `g = rootA ∧ rootB` realizes a negated control by `cqrt_x`-BRACKETING that
  // control (`CondNetwork::Node::NegL/NegR`), and this increment's invariant
  // is that NO non-diagonal gate is ever emitted on a user's register (the
  // outer arm's own phases on a negated rail root use the diagonal
  // `rz(rail, −θ)` form, which has no analogue for a Toffoli control). The
  // identity `Toff(¬a,b,g) = CNOT(b,g)·Toff(a,b,g)` would lift it with no gate
  // on `a`; filed, not built — over-declining is safe.
  const bool OuterRootIsRail =
      OuterTree.Nodes.empty() && !OuterTree.RailLeaves.empty();
  const bool InnerRootIsRail =
      InnerTree.Nodes.empty() && !InnerTree.RailLeaves.empty();
  if ((OuterRootIsRail && OuterNeg) || (InnerRootIsRail && InnerNeg)) {
    diagnoseUnderControl(BI, "branch phase on a bare i1 condition");
    return PhaseKickbackDisp::Declined;
  }
  (void)DT;
  (void)LI;

  // ---- 6. LOOPS. A nest on a CFG cycle keeps the d8jl decline and its existing
  // string: the 8h7d.5 rolled-in-loop narrowing was proven for the FLAT region
  // only (`flatRegionRollableInLoop` names a single Arm and a single MergeBB),
  // and nothing has re-derived it for a three-block region tree. Over-declining
  // is safe; widening it is a separate increment with its own twin matrix.
  if (regionEntryInLoop(BI)) {
    diagnoseUnderControl(BI, "nested control flow");
    return PhaseKickbackDisp::Declined;
  }

  // ACCEPT. Claim the INNER branch so the detection loop does not revisit it and
  // false-decline (the FA0 blocker, verbatim from the 4.3 path), and claim every
  // logical `select i1` node of BOTH trees so the tainted-select scan leaves
  // them alone (see `classifyPhaseKickback`'s header for what happens otherwise).
  if (ClaimedBranches)
    ClaimedBranches->insert(InnerBI);
  if (ClaimedSelects)
    for (const CondTree *T : {&OuterTree, &InnerTree})
      for (Instruction *N : T->Nodes)
        if (isa<SelectInst>(N))
          ClaimedSelects->insert(N);
  return PhaseKickbackDisp::Accept;
}

// 6.5 — recognize the §2.13 classical-call-under-control shape (DD-7). Pure SSA
// analysis, before any mutation (Rule 9). See ArmClassify.h for the disposition
// contract. This runs BEFORE `classifyArms`: a positive match short-circuits the
// phase/value classifier (whose `isValueChangingOp(call)`-true path would
// otherwise decline the same shape as a §3c clobber — a safe over-decline, but
// not the 6.5 lowering).
// bd 9hea — see ArmClassify.h for the full contract. Whitelist by construction.

ClassicalCallDisp classifyClassicalCallArm(ControlRegion &Region,
                                           TaintSet &Taint) {
  auto *MergePhi = dyn_cast_or_null<PHINode>(Region.Merge);
  if (!MergePhi)
    return ClassicalCallDisp::NotApplicable;  // classifyArms diagnoses.

  // The flag is minted (and `_inv`-stripped) from a SINGLE lowerable compare. A
  // compound condition (clang's `select i1` for `&&`/`||`) or an out-of-scope
  // predicate has no `lowerCompareToFlag` template — defer to `classifyArms`,
  // which owns those condition declines (`control flow` / `control condition has
  // no template`) at DETECTION. Checking here keeps detect-before-mutate (Rule 9):
  // the emitter calls `lowerCompareToFlag` only AFTER hoisting the call, so a
  // post-hoist mint failure would be a mutate-then-decline. Mirror the
  // `classifyArms` gates so a bad-condition classical-call diamond never reaches
  // the emitter.
  if (!isa<CmpInst>(Region.Condition) ||
      !comparePredLowerable(cast<CmpInst>(Region.Condition)))
    return ClassicalCallDisp::NotApplicable;

  // DIAMOND only — one content arm (`Region.Arm`) plus the straight-through
  // Pred edge (the tainted routed base `q`). An if/else (both arms content,
  // `Region.ArmFalse` set, no Pred edge) is out of 6.5 scope — defer to
  // `classifyArms` (over-decline is safe; the §2.13 e2e/accept shape is the
  // `if (q>k) y = f(args);` diamond).
  if (Region.ArmFalse || !Region.Arm || !Region.Pred)
    return ClassicalCallDisp::NotApplicable;
  if (MergePhi->getBasicBlockIndex(Region.Pred) < 0 ||
      MergePhi->getBasicBlockIndex(Region.Arm) < 0)
    return ClassicalCallDisp::NotApplicable;

  Value *StraightThrough = MergePhi->getIncomingValueForBlock(Region.Pred);
  Value *ArmIncoming = MergePhi->getIncomingValueForBlock(Region.Arm);

  // The arm's merge contribution must be a DIRECT call DEFINED IN the arm whose
  // result is CLASSICAL (not in `taint.Tainted`). The non-tainted-RESULT gate is
  // load-bearing on TWO axes:
  //   * it keeps a value chain (`add`, tainted; pre-3qlq also a register-form
  //     `cq_phi`) OUT of this path — it classifies in `classifyArms`;
  //   * the all-classical-INPUTS check (§2.13 / WI-5.6 / Rule 3): the clone ×
  //     route composition (quantum data under quantum control) is OUT of 6.5
  //     (deferred Phase 4×6) and is excluded HERE — it declines via `classifyArms`
  //     rather than being mis-claimed as a 6.5 site.
  //   ⚠ THE SECOND AXIS USED TO BE THE FIRST GATE ALONE, AND bd cepm FALSIFIED THE
  //     PROXY (CLAUDE.md L3). The text here said "`propagate` taints EVERY
  //     non-measure, non-angle user of a tainted value … A CLASSICAL result
  //     therefore proves every input is classical". Since bd cepm it does NOT: a
  //     would-be Phase-6 site whose callee is predicted to return a classical value
  //     (`specCallResultPredictedClassical`) reads a quantum argument and has an
  //     UNTAINTED result. So the inputs are now asked DIRECTLY (`readsTaintedValue`,
  //     the one operand test — arguments, bundle operands and the called operand),
  //     which keeps this path's population exactly the pre-cepm one: such a site
  //     reaches `classifyArms` as it did when its result was tainted.
  auto *Call = dyn_cast<CallInst>(ArmIncoming);
  if (!Call || Call->getParent() != Region.Arm ||
      Taint.Tainted.count(Call) || readsTaintedValue(*Call, Taint))
    return ClassicalCallDisp::NotApplicable;

  // A front-end intrinsic (`cq_theta`/`cq_phi`/`cq_measure`) is NEVER a 6.5
  // classical call — a `cq_measure` arm is a measurement under control (Rule 5),
  // owned by `classifyArms`'s `impure phase arm` / the FreePoint net, never
  // route-merged here. Exclude by name; an indirect call (null callee) is also
  // not a provable-pure classical call — defer to `classifyArms` (over-decline).
  Function *Callee = Call->getCalledFunction();
  if (!Callee || Callee->getName().starts_with("cq_"))
    return ClassicalCallDisp::NotApplicable;

  // From here the shape IS a classical-call arm; a failed precondition DECLINES
  // loudly (owning the diagnostic) rather than deferring — `classifyArms` would
  // otherwise mislabel it `arm rewrites a condition operand`.

  // The arm block must be EXACTLY the call + its unconditional terminator. A
  // larger arm hides a second instruction the flatten would ERASE: a side
  // effect dropped (a silent miscompile) or a value-changing op the hoist
  // cannot carry. `recoverRegion` already proved the terminator is the single
  // unconditional `br` to the merge. (WI-5.8 multi-instruction probe.)
  if (Region.Arm->size() != 2 || &Region.Arm->front() != Call) {
    diagnoseUnderControl(Call, "control flow");
    return ClassicalCallDisp::Declined;
  }

  // The call result feeds ONLY the merge phi — a second user (in- or out-of-arm)
  // means routing the result into `%out` leaves that user reading the wrong (or
  // a freed) value. (WI-5.8 multi-user probe.)
  if (!Call->hasOneUse()) {
    diagnoseUnderControl(Call, "control flow");
    return ClassicalCallDisp::Declined;
  }

  // PURITY (§2.13 / WI-5.4): the unconditional hoist into `Pred` requires a
  // side-effect-free, memory-independent, terminating callee.
  // `doesNotAccessMemory()` (readnone) makes the result depend solely on its args;
  // `!mayThrow()` adds nounwind. A readonly / writing / throwing callee DECLINES.
  // TERMINATION is the route's since batch 053: Direct needs `willreturn`, Twin
  // bounds every loop of its twin by a ScalarEvolution trip counter (see the
  // gate below). An unprovably terminating callee still declines.
  //
  // *** THIS PAIR IS NECESSARY AND IS NOT SUFFICIENT — bd wve8. *** The sentence
  // that stood here said the hoist is observationally inert "ONLY for a
  // side-effect-free, memory-independent, will-return callee", which reads as
  // SUFFICIENCY and is false; it is necessity at best. `mayHaveSideEffects()` is
  // `mayWriteToMemory() || mayThrow() || !willReturn()`, and IMMEDIATE UB INSIDE
  // THE CALLEE IS NONE OF THOSE. So `__attribute__((const)) int recip100(int x)`
  // with the body `return 100 / x;` passed this gate cleanly, and
  //     int q = cq_theta_si32(0, 0.0);  int y = q;
  //     if (q > 3) y = recip100(0);     return cq_measure_si32(y);
  // — a source with NO UB on ANY basis state, because Ry(0) is the identity so
  // `q == 0` everywhere and `q > 3` has ZERO AMPLITUDE — compiled to a program
  // that calls `recip100(0)` unconditionally and SIGFPEd. Reproduced end to end
  // at commit 9dc909e: `opt` exit 0, in-process verifier clean,
  // `free_pairing_check.py` 1 verified / 0 violations / 0 unproven, run_exit=136.
  // (`__attribute__((const))` puts `mustprogress nofree nosync nounwind willreturn
  // memory(none)` on the declaration; the CALL SITE carries exactly
  // `nounwind willreturn memory(none)`, which is the set the fixtures use.)
  // The trap is the LOUD form. The SILENT form is the same defect with a
  // pure-but-partial callee that returns garbage instead of trapping — hoisted
  // identically and route-merged into `%out` by `cqrt_copy_<W>_controlled`, where
  // NO gate in this tree can see it. PURITY IS NOT TOTALITY.
  //
  // The shape of the mistake is bd s6ao's, one level up: do not scan for which
  // bad properties are PRESENT; ask whether the call can be proven SAFE TO
  // SPECULATE. LLVM asks precisely that, and its answer for a call is the
  // `speculatable` attribute and nothing weaker — ValueTracking's own reason,
  // verbatim, is "The called function could have undefined behavior or
  // side-effects, even if marked readnone nounwind", which is bd wve8's finding
  // in LLVM's words. MEASURED: stock clang refuses this very hoist at -O1/-O2/-O3
  // on the source above (the call stays inside the guarded block at all three).
  // CQ was performing a transform LLVM declines, on a strictly weaker proof than
  // LLVM demands for it.
  //
  // TOTALITY, therefore, by either of two proofs, plus an argument clause below:
  //
  //   * `isSafeToSpeculativelyExecute` — LLVM's own answer. *** TWO DRAFTS OF
  //     THIS BULLET WERE WRONG, IN OPPOSITE DIRECTIONS; READ THE THIRD. *** Draft
  //     1 said "C has no spelling for `speculatable`, so this row has zero
  //     population": the premise is FALSE — clang stamps the attribute on the
  //     INTRINSICS it emits for builtins (`__builtin_abs` -> `llvm.abs.i32`
  //     carries it at -O1). Draft 2 then concluded that
  //     `if (q > 3) y = __builtin_abs(a);` LOWERS THROUGH THIS ROW and called the
  //     disjunct "load-bearing for ordinary C": ALSO FALSE, and it was an
  //     inference from an exit code rather than a measurement. That C never
  //     reaches this gate — clang -O1's own SimplifyCFG speculates the lone
  //     `speculatable` call into a `select`, so the module has ZERO `br i1`, the
  //     pure-callee proof is queried ZERO times, and the accept comes from the
  //     4.4 tainted-SELECT owner.
  //     THE TRUTH IS STRUCTURAL, not accidental, and squeezes the witness out
  //     from both sides: an arm that is exactly ONE `speculatable` call is
  //     exactly the shape SimplifyCFG speculates into a select (4.4's), and an
  //     arm SimplifyCFG declines to speculate has >= 2 instructions and fails
  //     6.5's own arm-shape gate. 14 builtin probes (abs, popcount, clz, ctz,
  //     bswap32/64, rotate, fabs, sqrt, ...) produced NO witness. So: no measured
  //     C witness at this gate, for that reason — which is NOT the same claim as
  //     "zero population" and must not be simplified back into it. The row is
  //     kept because it is LLVM's own answer to precisely the question this gate
  //     asks, and it is pinned at the IR level by
  //     control_classical_call_arm_accept_speculatable_decl.ll.
  //   * `isSpeculatableTotalCallee` (PredMuxFlatten.h) — the in-tree body walk,
  //     in its STRICT mode. Read that function's definition before touching this:
  //     the LAX form (`isSpeculatablePureCallee`, which S1/S2/S3 use) is NOT a
  //     totality proof, because two of its clauses defer their obligation to a
  //     clone that 6.5 never mints. Using the lax form here was the FIRST bd wve8
  //     fix and a Rule-13 lens broke it with six lines of C: a `static const`
  //     lookup table read, hoisted out of a zero-amplitude guard, SIGSEGV.
  //     Content clauses of the strict walk, each with its own decline fixture:
  //     visible + link-exact (`calleeBodyTrusted(F, AssumeOfLinkedCall)`, i.e.
  //     `hasExactDefinition`: weak_odr/linkonce_odr/available_externally refused
  //     too, because the hoisted call runs the LINKED body, bd p3kd.2) +
  //     non-varargs; no
  //     call-graph cycle; no CFG cycle; every block ending br/ret; NO memory op
  //     at all; NO conditional branch; and every remaining instruction
  //     `isSpeculatableDataflow` — which is where the division guard lives:
  //     `udiv`/`urem`/`sdiv`/`srem` are admitted only on a ConstantInt divisor
  //     that is non-zero, and the extra `-1` exclusion applies to the SIGNED
  //     forms only (`udiv`/`urem` by -1 are total and are admitted).
  //
  // *** DO NOT READ THE BODY WALK AS A DEFINEDNESS PROOF *** — the caps warning
  // is at `PureCalleeQuery` in PredMuxFlatten.cpp (the deleted S4, bd 3c6m.14.2);
  // the header carries no such caveat. This site does not need one. The
  // obligation HERE is that EXECUTING the call must not introduce UB the source
  // did not have. The RESULT's definedness is a different question, and it is not
  // observed on a shielded state: `cqrt_copy_<W>_controlled` is the identity
  // wherever the flag is 0, so on exactly the basis states the source shielded,
  // the hoisted value never reaches `%out`. What reaches `%out` on the states the
  // source did take is the value the source itself computed. That asymmetry is
  // pinned deliberately by control_classical_call_arm_accept_poisonselect_callee.ll,
  // which KEEPS a poison-producing `shl` in the callee and still lowers. ⚠ It
  // holds only while no `noundef` SINK sees poison (bd bwfp): a `noundef` return
  // turns it into UB at the callee's own `ret`, so such a callee is hoisted as a
  // twin with that `ret` frozen (bd dm7f.21, `classicalCallHoistRoute` below;
  // control_classical_call_arm_twin_accept_noundef_return_poison.ll).
  //
  // COST, MEASURED, AND STATED IN FULL — an earlier draft said only "what narrows
  // is the OPAQUE-DECLARATION shape", which is false. Six shapes accepted before
  // this gate and decline after it: an opaque declaration; a visible body with any
  // memory op (including the ordinary alloca/store/load helper); a body with a
  // conditional branch; a body with any CFG loop; `available_externally` /
  // `linkonce_odr` / `weak_odr` / interposable linkage; and a call passing a
  // not-provably-defined value to a `noundef` parameter. All are over-declines
  // (Prime Directive) and none is exotic — `available_externally` is what a C99
  // `inline` becomes in an importing TU. What that costs on the corpus: NOTHING.
  // Over the whole e2e layer the 6.5 arm accepts at TWELVE sites, all `ext_f` from
  // classical_call_under_control_lib.c, and all twelve still ACCEPT — measured as
  // a full `ctest -j6` 253/253 AFTER the argument clause landed, not merely as a
  // callee-proof result, because that clause can decline a site whose callee is
  // impeccable and the callee number alone would not establish it. All twelve
  // also pass the strict walk
  // (`run_slice_multi.sh` llvm-links every TU before the single cq-lowering run,
  // so the definition IS visible — the structural guarantee that slice's own
  // header describes). ZERO of the 220 single-TU stage-1 modules reach this gate
  // at all, so libm coverage is untouched.
  // UPDATE, batch 053: of those six, the conditional branch, the CFG loop with a
  // ScalarEvolution trip bound, the non-constant divisor and (a `speculatable`
  // one) the declaration now ACCEPT through the Twin route; memory ops,
  // non-exact linkage and an unbounded or irreducible loop still decline.

  // Batch 053 (bd dm7f.27/.29/.30/.26/.25) — PURITY stays here: memory(none) and
  // nounwind. TERMINATION (`willreturn`) and TOTALITY (`speculatable` or the
  // strict walk above) are now `classicalCallHoistRoute`'s (PoisonFlow.h), the one
  // owning predicate the emitter also asks: its Direct route keeps both, and its
  // Twin route stands in for them with a twin total and terminating by
  // construction (TwinTotality.h: frozen branch conditions, guarded divisors,
  // ScalarEvolution trip counters). So the paragraph above that lists a
  // conditional branch, a CFG loop and a non-constant divisor among the declines
  // now describes the Direct route only. The route also sees what the body proofs
  // do not: a mismatched calling convention (UB at the call), and POISON reaching
  // a `noundef` sink in the call tree (bd bwfp, measured on e0af16ed: `ret noundef
  // poison` hoisted out of a zero-amplitude guard; bd dm7f.21: such a sink is
  // frozen in the twin, owner ruling 2026-10-08).
  if (!Call->doesNotAccessMemory() || Call->mayThrow() ||
      classicalCallHoistRoute(Call) == HoistRoute::Unsafe) {
    diagnoseUnderControl(Call, "control flow");
    return ClassicalCallDisp::Declined;
  }

  // TOTALITY, THE ARGUMENT HALF. The two proofs above are about the CALLEE. A
  // call can also be UB for a reason that lives entirely at the CALL: passing
  // `poison` to a parameter attributed `noundef` is immediate UB, and the hoist
  // creates it out of nothing when the source's guard excluded the call. Probed
  // and REACHED post-fix: `%p = shl i32 1, %n` (poison for `%n >= 32`) computed
  // in the pred and passed as `call i32 @pf(i32 noundef %p)` accepted at exit 0
  // with both callee proofs satisfied, because `@pf`'s own body is impeccable.
  //
  // `noundef` IS THE WHOLE CHECK, and that is a completeness argument rather than
  // an enumeration (bd s6ao: never scan for the channels you happened to think
  // of). If a parameter is NOT `noundef`, passing it poison is simply not UB. The
  // pointer-side attributes do not reopen it: a `nonnull`/`align`/`dereferenceable`
  // violation yields poison rather than UB, and the place that would turn such a
  // pointer INTO UB is a memory access inside the callee — which the strict twin
  // refuses outright. Note clang -O1 stamps `noundef` on scalar parameters as a
  // matter of course, so this is the live surface for real input, not a corner.
  //
  // *** AND IT COSTS AN ORDINARY SHAPE. SAY SO — THE CORPUS HAD NO POWER TO SEE
  // IT. *** `if (q > 5) y = ext_f(u + 1);` DECLINES: clang stamps `nsw` on the
  // `add`, which makes it poison-capable, and `ext_f`'s parameter is `noundef`.
  // The "zero corpus cost" measured for this gate is real but PROVES LESS THAN IT
  // LOOKS, because every 6.5 site in the corpus passes a CONSTANT argument — the
  // probe could not have detected this cost. The decline is nevertheless exactly
  // the UB condition and stays (over-accepting is the unforgivable direction).
  // THE REMEDY IS KNOWN AND DELIBERATELY NOT TAKEN HERE: `freeze` the hoisted
  // argument, which turns poison into an arbitrary DEFINED value and restores the
  // shape. That is an EMITTER change on a Rule-13 path and needs its own round;
  // filed rather than smuggled in at the end of this one. Do NOT instead reach for
  // `dropPoisonGeneratingFlags` on the argument — 9dc909e established that flag
  // drops have a live decline->ACCEPT inverter in `Fp80Union.cpp`'s PaddingWalk.
  //
  // AND `isGuaranteedNotToBeUndefOrPoison` IS SOUND *HERE* THOUGH IT IS CIRCULAR
  // ONE GATE OVER. Measured at this exact position on the probe above: `gnp=0`
  // for the `shl`. Contrast the branch-condition position inside the callee,
  // where the same predicate answers 1 for `icmp(shl)` because it also reasons
  // from USES and a `br` is UB on poison (see the terminator clause in
  // PredMuxFlatten.cpp). Same predicate, opposite usefulness, decided by position
  // — which is why both were measured rather than argued.
  // bd 9hea — DISCHARGED BY `freeze` WHERE `freeze` ACTUALLY DISCHARGES IT, refused
  // otherwise. The clause above stated its own cost and it was real: `if (q > 5)
  // y = ext_f(u + 1);` — ordinary C — declined, because clang stamps `nsw` on the
  // `add` (poison-capable) and `noundef` on the parameter. The remedy is to `freeze`
  // the hoisted argument in the emitter: freeze turns poison into an arbitrary
  // DEFINED value, so the `noundef` contract holds and the hoist creates no UB. On
  // the basis states the source took the arm its own argument was poison there, so
  // any frozen value is a legal refinement; on the states it did not, the controlled
  // copy is the identity and the value is never merged. `freeze` is a codegen no-op,
  // so the emitted CIRCUIT is unchanged.
  //
  // NOT a flag drop on the argument. Commit 9dc909e established that flag drops have
  // a live decline->ACCEPT inverter in this tree (`Fp80Union.cpp`'s `PaddingWalk`
  // reads `nsw`/`nuw`/`exact` as BLOCKERS), so removing the `nsw` could flip an
  // unrelated region into an accept. `freeze` ADDS a fact; a drop REMOVES one.
  //
  // `freezeDischargesHoistedArg` owns the whole decision and the EMITTER CALLS THE
  // SAME PREDICATE — read its header for why that sharing is load-bearing, why the
  // attribute test is a WHITELIST, and why both callers must query BEFORE the hoist
  // (bd iwz1: post-hoist the predicate self-licenses, 0 -> 1).
  // bd bwfp: `hoistedArgPoisonIsUB` widens "a `noundef` parameter" to each
  // argument whose poison the call tree forwards to a `noundef` sink (a per-
  // argument dataflow over the bodies); the emitter asks the same predicate.
  for (unsigned Ai = 0, Ae = Call->arg_size(); Ai != Ae; ++Ai)
    if (hoistedArgPoisonIsUB(Call, Ai) &&
        !llvm::isGuaranteedNotToBeUndefOrPoison(Call->getArgOperand(Ai)) &&
        !freezeDischargesHoistedArg(Call, Ai)) {
      diagnoseUnderControl(Call, "control flow");
      return ClassicalCallDisp::Declined;
    }

  // §3c (DD-7) — the call result `Call` and (by the classical-result gate above)
  // EVERY input are NON-TAINTED, hence disjoint from the condition's all-tainted
  // provenance by construction: the classical-call analog of the select §16.6
  // §3c-vacuity (a controlled-copy merge writes only `%out`, never the condition
  // register `q`, so the `icmp_inv` flag-strip stays valid). A merge contribution
  // that value-CHANGES a condition operand (`q2 = add q, Call`) is NOT a
  // direct-call merge incoming — it never reaches here, declining instead via
  // `classifyArms`' value-arm §3c (`arm rewrites a condition operand`).
  // `StraightThrough` (the tainted routed base) names that obligation's subject.
  (void)StraightThrough;

  // MERGE-OUT ESCAPE adjudication (was the 8mld gate here; MOVED post-emit by dugh,
  // Phase 4×6). The merge phi is data-untainted whenever the straight-through is a
  // classical constant (`int y = 5; if (q>k) y = f(a)`), so the FIRST forward taint
  // propagation never saw `%out`'s onward consumers — the very reason 8mld declined
  // any non-measure/non-i32-ret merge user HERE. dugh instead re-seeds a SECOND
  // propagation from the emitted `%out` (`repropagateControlMerges`, run right after
  // `lowerControlRegions`) and re-runs the existing taint-gated nets on the now-
  // tainted onward flow:
  //   * onward QUANTUM flow (arith / phase / local-array Shadow store) is re-tainted
  //     and LOWERS — the (A2) subset this bead accepts;
  //   * an onward CLASSICAL escape (opaque store `kMsgStore`, opaque call
  //     `kMsgUnknownCallee`, non-i32 `ret` `kMsgNonI32Return`) declines via the
  //     precise `declineTaintEscapes` net — the (A1) subset that stays declined;
  //   * a NEW tainted-condition br/switch/select on `%out` declines via
  //     `declineReClassifiedControl`.
  // A measurement sink / i32 `ret` (the two shapes 8mld allowed) lowers exactly as
  // before (the second propagation stops at a sink and accepts an i32 ret). So the
  // detection-time gate is retired: accept the region and let the post-emit net
  // adjudicate its onward flow.

  // ACCEPT — the route-merged classical-call arm (the fp/i128 RESULT gate is the
  // emitter's `copyControlledFn` non-null check, DD-7). The emitter re-derives the
  // call as the `Arm`-edge merge incoming (a pure consumer of the plan).
  Region.Kind = ControlRegion::ClassicalCallArm;
  return ClassicalCallDisp::Accept;
}


// ---- ANGLE SELECT (control-in-place-PRD §12.3, bd test_C_libtooling-drbq
//      Inc 2b; X-BRACKET Ry stem since bd dm7f.6) — BOTH STEMS --------------
//
// THE SHAPE, which is what `clang -O1` makes of the C the user writes:
//
//     cq_theta(&r, q == 5 ? A : B);                  // the select, written out
//     if (q == 5) cq_phi(A); else cq_phi(B);            // phase stem: still merged
//
// `include/CQ.h` puts `nomerge` on every `cq_theta_*` (bd fmt3, 2026-09-28), so
// the Ry if/else stays an if/else and lowers through the in-place Ry arm; for
// `cq_phi` (no `nomerge`) SimplifyCFG still merges the two arms into ONE call
// whose ANGLE is a select, so the branch CFG is GONE before the pass runs
// (Rule 9). Either way the IR is (Ry stem shown):
//
//     %c = icmp eq i32 %q, 5
//     %a = select i1 %c, double A, double B          ; A, B CLASSICAL
//     %t = call i32 @cq_theta_si32(i32 %r, double %a) ; %r TAINTED, %a ONLY arg-1
//
// THE REGISTER-FREE PHASE STEM `cq_phi(c ? A : B)` IS A KICKBACK: `cqrt_rz_i1`
// on the flag, `P(B)` on ¬f and `P(A)` on f, each angle verbatim (see the
// `IsPhase` split in the body). THE Ry STEM (bd dm7f.6, owner ruling 2026-10-13
// `owner-ruling-angle-select-xbracket`) is the X-BRACKET form on the flag
// ancilla, the stream the if/else in-place Ry arm emits for the same program:
//
//     f = icmp_<pred>_hl(q, 5)      ; flag mint, unchanged from every other path
//     R_controlled(f, r, A)         ; fires on f = 1
//     cqrt_x(f); R_controlled(f, r, B); cqrt_x(f)   ; fires on f = 0
//     icmp_<pred>_hl_unc(f, q, 5)   ; flag strip
//     cqrt_free(f)
//
// Each arm's double reaches exactly ONE controlled gate: no arithmetic, no
// freeze, and the f = 1 branch never touches `B` (nor f = 0 `A`).
// There is NO polarity case: `select %c, A, B` always means "A when the flag is
// 1" (a `!=` source, which `clang` canonicalizes to `icmp eq` with the select
// operands SWAPPED, needs nothing special), and both arms are read by SSA
// identity.
//
// THE FENCES, and which ones are stem-split:
//   S1  `double` select, both data operands CLASSICAL (a tainted A/B is the
//       f64/angle miscompile family, Rule 3) and DEFINED
//       (`angleSelectArmsDefined`: no literal undef/poison, the one arm-value
//       question left). RUN-TIME, NON-FINITE and LINK-TIME-CONSTANT arms are
//       admitted on BOTH stems (owner ruling 2026-10-03, items (2), (4), (5));
//       see the comment above `angleSelectArmsDefined`.
//   S2  EXACTLY ONE user of the select: a rotation's arg-1 with a different
//       arg-0. N consumers is a recorded follow-on — S6's positional scan is
//       wire-blind, which makes an N-consumer accept ORDER-dependent.
//   S3  arg-0 TAINTED — a classical arg-0 is controlled STATE PREP (PRD S5,
//       Inc 4), which needs its alloc hoisted and a seed-identity fence.
//   S4  a BARE lowerable compare with EXACTLY ONE tainted operand and EXACTLY
//       ONE user (the select). The single-user clause is what declines a
//       compare shared with a `br` region, with a second select (two gates per
//       arm), or with a `ShareCondFlag`-style data use.
//   S5  the ABI width has a controlled rotation (`abiWidthHasControlledRotation`),
//       asked through the MINT's own expression (`suffixFromName` + `abiWidthFor`).
//   S7  NOT inside a loop OR ON A CYCLE (Inc 3 owns loops) — asked BEFORE the
//       positional and wire clauses so the loop message wins, exactly as
//       `classifyArms` asks R7's loop clause before R6. THREE prongs since the
//       round-1 Rule-13 review, because the shipped `LoopInfo`-only spelling was
//       narrower than every sibling's: (i) `LI->getLoopFor` of `Cond`/`Sel`/`T`'s
//       blocks, (ii) `blockOnCycle` of the same three (irreducible cycles are
//       invisible to `LoopInfo`), (iii) either question of every member of the
//       ROTATED REGISTER's rail closure, for BOTH stems.
//   S6  `Cond`, `Sel`, `T` in ONE block in that order, with no in-place `Ry` in
//       `(Cond, T)` — gate 2c's prong (c) with its window extended from the
//       select to the CONSUMER, because the mint now happens at `T`.
//   S8  Ry ONLY — R4 disjoint wires. The flag strip recomputes the predicate on
//       the condition's registers; an in-place Ry on one of them relabels the
//       basis the mint read, so `f` does not return to |0⟩ (Rules 6/8). The phase
//       stem puts no gate on the register at all, so it is exempt (PRD §3c).
//   S9  Ry ONLY — R6 stale record, `classifyArms`' clause verbatim with the
//       consumer `T` in the barrier role `BI` played. Rz exempt (§12.1
//       transparency: a diagonal gate moves no basis label, so a pre-gate SSA
//       record read afterwards denotes the same measurement statistics).
//   S10 nothing else already claims `T` or `Sel`.
//
// Everything outside this returns `NotApplicable` and the caller fires its
// pre-existing `rotation angle` decline unchanged.


// ---- THE ARM-VALUE QUESTION (S1's second half) ------------------------------
//
// HISTORY, one paragraph because every clause it names is gone. The drbq Inc-2b
// Ry stem realized `B + fl(A−B)` on the true edge, so its arm fence
// (`angleSelectArmsAdmissible`) refused a non-finite arm, a non-finite
// difference of finite arms, a rounding residual above a placeholder 2^-40 rad,
// a link-time constant it could not evaluate and, after the Rule-13 clearance
// finding F-11, every run-time arm. The owner ruling of 2026-10-03 on bd dm7f.6
// retired the subtraction and with it every one of those clauses: no difference
// is computed, so there is nothing to round, to overflow or to evaluate, and a
// non-finite angle is a classical value passed to the backend (ruling item (5)).
//
// WHAT REMAINS is the undef clause: an arm that is a literal `undef`/`poison`, or
// a `ConstantExpr` carrying one (`bitcast (i64 undef to double)`), would land
// verbatim in an emitted gate slot — twice for the Ry stem's false arm — and a
// literal undef is materialized per use (the bd xy9n literal-integrity class).
// Asked through the shared `valueCarriesUndef` (Rule 14), never a bare
// `isa<UndefValue>`. It calls the NON-global-skipping variant, so an arm that is
// the address of a global whose initializer holds `undef` is refused too (an
// over-decline, hand IR only). A RUN-TIME arm that MAY be poison is NOT refused:
// each arm fills exactly one gate slot, so a per-use refinement has no second
// read to disagree with.
bool angleSelectArmsDefined(const Value *A, const Value *B) {
  // Self-contained: it is also the emitter's step-0 re-ask, so it establishes
  // its own premise rather than inheriting S1's `double` test.
  if (!A || !B || !A->getType()->isDoubleTy() || !B->getType()->isDoubleTy())
    return false;
  return !valueCarriesUndef(A) && !valueCarriesUndef(B);
}

// bd dm7f.54 — the header (`ArmAnalysis.h`) carries the argument. The CALL-SITE
// attribute list only (`getAttributes()`, never `hasFnAttr`, which also reads
// the callee): a devirtualized indirect call names a `nomerge` callee without
// having been protected by it when SimplifyCFG ran (bd 4e4p).
bool collectAngleMux(SelectInst *Root, const TaintSet &Taint,
                     SmallVectorImpl<SelectInst *> &Members,
                     SmallVectorImpl<Value *> &Leaves) {
  Members.clear();
  Leaves.clear();
  bool Ok = true;
  std::function<void(SelectInst *)> Walk = [&](SelectInst *S) {
    if (!Ok)
      return;
    if (Members.size() >= kAngleMuxMaxMembers) {
      Ok = false;
      return;
    }
    Members.push_back(S);
    for (Value *V : {S->getTrueValue(), S->getFalseValue()}) {
      auto *C = dyn_cast<SelectInst>(V);
      if (C && angleMuxParent(C, Taint) == S)
        Walk(C);
      else
        Leaves.push_back(V);
    }
  };
  if (!Root)
    return false;
  Walk(Root);
  return Ok;
}

bool angleSelectLiteralSeedAdmissible(const CallInst *T) {
  if (!T || T->arg_size() < 2)
    return false;
  const Value *Seed = T->getArgOperand(0);
  if (!isa<ConstantInt>(Seed) && !isa<ConstantFP>(Seed))
    return false;
  return T->getAttributes().hasFnAttr(Attribute::NoMerge);
}

// bd dm7f.54 (item A1, delegated ruling `ruling-dm7f54-literal-base-and-ifelse-
// prep-2026-10-15`) — THE NON-MERGE ROUTE TO A LITERAL SEED. `nomerge` rules out
// the SimplifyCFG sink, NOT a value substitution: GVN / IPSCCP / InstCombine
// replace a register by the literal it is PINNED to on a dominating equality
// edge with no merge at all (review probe revC54b/p7: `int t = k; cq_theta(&t,
// .5); if (t == 5) cq_theta(&t, c ? .9 : .3);` reaches the pass as
// `cq_theta_si32(i32 5, sel)` on a `nomerge` call, while the source rotated `t`
// IN PLACE). So the literal is refused when some value `V` is PROVEN EQUAL to
// it at the consumer: F2's question (`f2SeedPinnedByLiveRegister`), asked with
// `T` as the context instead of a region edge, by LLVM's own machinery —
// `LazyValueInfo::getConstantRange(V, T)` folds every dominating edge and
// `llvm.assume` — for an integer seed; for an fp seed (LVI has no fp lattice)
// the dominating branches whose taken edge dominates `T` are read for an
// equality `fcmp` against the seed's bits (`fcmpEqualityHoldsOnEdge`, F2's
// fp anchor table). ⚠ The LVI precondition F2 records (never ask about a value
// that does not dominate the context: a Release `cq-opt` SIGSEGVs) is honoured
// by asking only about arguments and instructions that dominate `T`.
//
// A pinned TAINTED `V` is returned (the caller declines with F2's string). A
// pinned CLASSICAL instruction is harmless today — rotating a classical
// register prepares a fresh rail from its value, which IS the literal — but it
// is classical at ROUND-1 taint only (CLAUDE.md L1: a 6.5/4.5 `%out` derivative
// turns quantum at round 2). Each one is therefore TAGGED `kAngleSelSeedPinMD`
// (defined beside `kF2SiblingMD`)
// and `declineRound2QuantumPrepSeeds` re-asks its taint after the round-2
// fixpoint in both entry points. Arguments never change taint across rounds.
Value *angleSelectLiteralSeedPinned(CallInst *T, const TaintSet &Taint,
                                    const DominatorTree &DT,
                                    const SmallPtrSetImpl<Value *> &CondWire) {
  auto *Seed = dyn_cast<Constant>(T->getArgOperand(0));
  Function *F = T->getFunction();
  if (!Seed || !F)
    return nullptr;
  SmallVector<Instruction *, 4> ClassicalPins;
  Value *Hit = nullptr;
  // round-2 review F2: F2's own exclusions, by the ONE spelling
  // (`f2ExcludedAtTest`, no merge so no `PhiDesc`): a pin of a value on the
  // angle select's CONDITION wire is the owner-ruled α trade here exactly as at
  // the if/else's F2, so the two spellings of one program answer alike.
  auto note = [&](Value *V) {
    if (f2ExcludedAtTest(V, CondWire, Taint, /*PhiDesc=*/nullptr))
      return;
    if (Taint.Tainted.count(V)) {
      if (!Hit)
        Hit = V;
    } else if (auto *I = dyn_cast<Instruction>(V)) {
      ClassicalPins.push_back(I);
    }
  };
  if (isa<ConstantInt>(Seed)) {
    // F2's machinery, at the consumer: every integer value that dominates `T`
    // gets LVI's range AT `T` (sharpened by `f2Refine`), and `f2Model`
    // evaluates FORWARD from there — LVI alone does not re-evaluate a value
    // defined above the pinning edge (measured: under `(q & -4) == 20` it knows
    // `q` and not `sdiv q, 4`; `opt -passes=correlated-propagation` folds
    // `q >= 20` there and leaves `t == 5`), which is exactly the reason F2 has
    // its forward half. A value is a HIT when it dominates `T` and `f2Exact`
    // gives the seed. A tainted user that cannot be modelled while a pinned
    // operand feeds it is F2's conservative `Truncated` — the decline
    // direction, returned as the user itself; a classical one ends the walk on
    // that path (it is no register).
    const DataLayout &DL = F->getParent()->getDataLayout();
    AssumptionCache AC(*F);
    LazyValueInfo LVI(&AC, &DL);
    F2State S;
    SmallVector<Value *, 32> Cand;
    for (Argument &A : F->args())
      if (A.getType()->isIntegerTy())
        Cand.push_back(&A);
    for (Instruction &In : instructions(*F))
      if (In.getType()->isIntegerTy() && &In != T && DT.dominates(&In, T))
        Cand.push_back(&In);
    for (Value *V : Cand) {
      const ConstantRange CR =
          LVI.getConstantRange(V, T, /*UndefAllowed=*/false);
      if (CR.isFullSet() || CR.isEmptySet())
        continue;
      f2Note(V, f2Refine(V, CR, DL, &AC, &DT), S);
    }
    unsigned Steps = 0;
    while (!S.WL.empty()) {
      if (++Steps > kF2MaxSteps)
        return T;  // F2's step cap: the decline direction.
      Value *V = S.WL.pop_back_val();
      auto *VI = dyn_cast<Instruction>(V);
      const bool Dominates =
          isa<Argument>(V) || (VI && VI != T && DT.dominates(VI, T));
      if (Dominates && V->getType() == Seed->getType() &&
          f2Exact(V, S) == Seed)
        note(V);
      for (User *U : V->users()) {
        auto *I = dyn_cast<Instruction>(U);
        if (!I || I->getFunction() != F || I->getType()->isVoidTy() ||
            !I->getType()->isIntegerTy())
          continue;
        if (!f2Model(I, S, DL, &AC, &DT) && Taint.Tainted.count(I))
          return I;  // F2's `Truncated`: refuse.
      }
    }
  } else if (auto *SeedF = dyn_cast<ConstantFP>(Seed)) {
    // Walk the dominator tree up from `T`'s block: every conditional branch
    // whose taken edge dominates `T`'s block contributes its equality fcmp.
    BasicBlock *Here = T->getParent();
    for (DomTreeNode *N = DT.getNode(Here); N && N->getIDom();
         N = N->getIDom()) {
      BasicBlock *Up = N->getIDom()->getBlock();
      auto *BI = dyn_cast<BranchInst>(Up->getTerminator());
      if (!BI || !BI->isConditional())
        continue;
      // round-2 review H5: every `fcmp` the edge FORCES (F2's own
      // `forcedFcmpLeavesOf`), not only a bare-`fcmp` condition, so an fp pin
      // under an `&&`/`||` tree is seen as the integer path's LVI sees it.
      // (`llvm.assume` of a tainted condition is a taint escape, declined
      // before detection, so there is no assume pin to read.)
      for (unsigned E = 0; E < 2; ++E) {
        if (!DT.dominates(BasicBlockEdge(Up, BI->getSuccessor(E)), Here))
          continue;
        for (auto [FC, Holds] : forcedFcmpLeavesOf(BI->getCondition(), E == 0)) {
          if (!fcmpEqualityHoldsOnEdge(FC->getPredicate(), /*TrueEdge=*/Holds))
            continue;
          for (unsigned K = 0; K < 2; ++K)
            if (auto *C = dyn_cast<ConstantFP>(FC->getOperand(K));
                C && C->getValueAPF().bitwiseIsEqual(SeedF->getValueAPF()) &&
                !isa<Constant>(FC->getOperand(1 - K)))
              note(FC->getOperand(1 - K));
        }
      }
    }
  }
  if (!Hit)
    for (Instruction *I : ClassicalPins)
      I->setMetadata(kAngleSelSeedPinMD, MDNode::get(I->getContext(), {}));
  return Hit;
}


AngleSelectDisp classifyAngleSelect(SelectInst *Sel, const CondTree &Tree,
                                    TaintSet &Taint, WidthDispatch &wd,
                                    DominatorTree *DT, LoopInfo *LI,
                                    ControlPlan &plan) {
  // S1 — a `double` select over two CLASSICAL operands. Every `CQ.h` rotation
  // takes a `double` angle, so a narrower/wider select reaches the angle slot
  // only through a CAST, which is a different (still-declining) shape. A
  // TAINTED A or B is quantum data in the angle slot (Rule 3) — the f64/angle
  // miscompile family; it stays with the caller's decline.
  if (!Sel->getType()->isDoubleTy())
    return AngleSelectDisp::NotApplicable;
  // bd dm7f.54 (item E) — the operands may be INNER MUX MEMBERS
  // (`collectAngleMux`, `c1 ? A : (c2 ? B : C)`): S1 is then asked of every
  // LEAF angle, and every member's condition is asked S4 below. A single
  // select is the one-member mux whose leaves are exactly `A`, `B`.
  SmallVector<SelectInst *, 4> Members;
  SmallVector<Value *, 8> MuxLeaves;
  if (!collectAngleMux(Sel, Taint, Members, MuxLeaves))
    return AngleSelectDisp::NotApplicable;
  const bool IsMux = Members.size() > 1;
  for (Value *L : MuxLeaves)
    if (Taint.Tainted.count(L) || !angleSelectArmsDefined(L, L))
      return AngleSelectDisp::NotApplicable;
  Value *A = Sel->getTrueValue();
  Value *B = Sel->getFalseValue();
  if (!IsMux && (Taint.Tainted.count(A) || Taint.Tainted.count(B)))
    return AngleSelectDisp::NotApplicable;
  // ... and both arms DEFINED: `angleSelectArmsDefined`, the one arm-value
  // question left, asked for BOTH stems with ONE spelling (bd dm7f.6). Neither
  // stem performs arithmetic on an arm, so a run-time, non-finite or link-time
  // constant arm is admitted; a literal undef/poison one is not (the comment
  // above `angleSelectArmsDefined`). For the phase stem this is the clause that
  // Rule-13 round-1 finding F-L4-1 found missing: an `undef` arm reached
  // `cqrt_rz_i1(f, double undef)` (measured, hand IR), where the pre-3qlq oracle
  // declined.
  if (!IsMux && !angleSelectArmsDefined(A, B))
    return AngleSelectDisp::NotApplicable;
  //
  // S2's consumer lookup is split by stem: the ARG INDEX differs (a suffixed
  // rotation takes `(handle, angle)` and reads the select at arg 1; the
  // register-free phase takes `(angle)` and reads it at arg 0).
  if (!Sel->hasOneUse())
    return AngleSelectDisp::NotApplicable;
  auto *T = dyn_cast<CallInst>(Sel->user_back());
  if (!T)
    return AngleSelectDisp::NotApplicable;
  const bool IsPhase = isRegisterFreePhaseCall(T, Taint);
  if (IsPhase && (T->arg_size() != 1 || T->getArgOperand(0) != Sel))
    return AngleSelectDisp::NotApplicable;

  // S2 — EXACTLY ONE user, and it is a rotation reading the select ONLY as its
  // angle. `hasOneUse` counts USES, so a select feeding both arg-0 and arg-1 of
  // one call is refused here too. Anything else (an fpext/fptrunc/bitcast/
  // freeze/phi carrier, a nested select, a store, a second rotation) keeps the
  // caller's `rotation angle` decline. (bd dm7f.54 item E: a nested select that
  // is an INNER MUX MEMBER — `angleMuxParent` — never reaches here: gate 3
  // defers it to its root, whose `collectAngleMux` covers it.)
  const bool IsTheta = !IsPhase && isThetaCall(T);
  const bool IsPhi = !IsPhase && isPhiCall(T);
  if (!IsPhase) {
    if (T->arg_size() < 2 || T->getArgOperand(1) != Sel ||
        T->getArgOperand(0) == Sel)
      return AngleSelectDisp::NotApplicable;
    if (!IsTheta && !IsPhi)
      return AngleSelectDisp::NotApplicable;
  }
  // A nested mux is a Ry-stem construct only (the phase stem keeps its
  // two-arm kickback pair; widening it is a separate follow-on).
  if (IsMux && !IsTheta)
    return AngleSelectDisp::NotApplicable;

  // S3 — THE ROTATION'S arg-0. A TAINTED base is a CHAINED rotation on a live
  // register (Inc 2b, byte-for-byte unchanged). An UNTAINTED base is controlled
  // STATE PREP on a fresh rail — the plain-C spelling of the if/else two-prep
  // shape, `if (c) { r = t; cq_theta(&r, A); } else { r = t; cq_theta(&r, B); }`, which `-O1`'s
  // SimplifyCFG sinks into ONE theta reading an angle `select` (PRD §14.2e /
  // §14.11 Q5, bd `drbq.13`).
  //
  // ---- bd `test_C_libtooling-z0re` (OWNER RULING 2026-09-28, option (a)) —
  //      A RUNTIME UNTAINTED BASE IS ADMITTED, Ry STEM ONLY.
  //
  // The emitter's stream then reads `f = mint; alloc(t); ry_controlled(f, h, A);
  // x(f); ry_controlled(f, h, B); x(f)` (bd dm7f.6): the theta is UNCONDITIONAL in
  // the source (only its ANGLE is conditional), so the fresh rail is prepared at
  // |t⟩ on BOTH components and rotated by exactly `A` or exactly `B` — there is no
  // "inactive component" whose `prepped vs |0⟩` disposition could be unproven
  // (the concern this clause used to cite, which was the DIAMOND prep's, not
  // this shape's). S1's arm question (`angleSelectArmsDefined`) ran above and
  // applies unchanged. What is SKIPPED
  // for it is the base's wire closure (S7's rail prong, S8, S9 below), for the
  // §14.5 reason: the rotated rail is MINTED by the emitter's true-arm gate
  // (the source theta), so NO pre-region SSA name for it exists — no wire to intersect with
  // the condition's (S8), no record to read stale (S9), no pre-region rail to be
  // in a cycle (S7-rail) — and walking the classical `t` instead would
  // enumerate its CLASSICAL users as "stale records" (the literal-use-list
  // hazard §14.5 measured for a `ConstantInt`). ⚠ A base that is untainted HERE
  // can be quantum at FINAL taint (a 6.5/4.5 `%out` derivative, CLAUDE.md L1),
  // and then `lowerRotations` lowers the twin CHAINED on it — a tainted-base
  // select S8/S9 never vetted. The emitter RECORDS the twin
  // (`TaintSet::RuntimeSeedSourceThetas`) and `declineRound2QuantumPrepSeeds`
  // re-asks in both entry points.
  //
  // ---- A LITERAL BASE STAYS DECLINED (bd `drbq.13` — NOT covered by this
  //      increment, and the reason is a MEASURED counter-example, not scope).
  //
  // At the DIAMOND prep of a literal F2 asks whether a live tainted register is
  // pinned to the literal on one of the REGION'S two edges — `-O1`'s IPSCCP folds
  // a register the condition tests into the literal on that edge. ⚠ CORRECTED
  // (Rule-13 r1A F-r1A-2, L7): the first spelling of this sentence said the
  // diamond "is safe ONLY because" of that, which reads as "the diamond IS
  // safe". It is not, in general: bd `fmt3` (PRE-EXISTING P1, lowered IR
  // byte-identical on the oracle) is this very fold NESTED inside a diamond prep
  // — the pinning branch is an INNER one that `-O1` deletes, so F2, anchored on
  // the OUTER region's edges, never sees it (r1A probe `a6`; its flat twin `a6f`
  // declines at F2). fmt3 is its own track; what matters HERE is that the
  // diamond's F2 is NOT a fence the literal angle select could borrow even in
  // principle. The angle select inherits the hazard and then HIDES the edge:
  // `int t = q / 4; int r; if (t == 5) { r = t; cq_theta(&r, .9); } else {
  // r = 5; cq_theta(&r, .3); } … cq_measure(t)` (probe `a1`, TRACK_Z0RE.md §4) compiles
  // at `-O1` to `cq_theta(i32 5, select((q & -4) == 20, .9, .3))` with `t =
  // sdiv q, 4` STILL LIVE and measured — IPSCCP pinned `t` to 5 in the true arm,
  // SimplifyCFG sank the two now-arg-0-identical thetas, and InstCombine moved
  // the compare SIDEWAYS off `t`. Admitting a literal base would prepare a fresh
  // |5⟩ and leave `t` unrotated where the source rotated `t` in place (the
  // F-R1-1 class, off the condition's wire, so not the owner-ruled α trade). F2
  // cannot be asked here: it is an EDGE analysis (`getConstantRangeOnEdge`)
  // and a select has no edge; LLVM 19 exposes LVI's condition analysis only
  // through a branch edge or a select-OPERAND use. So the literal stays on the
  // owner's desk (bd drbq.13), refused with the string it has always had.
  // ⚠ NARROWED by bd dm7f.54 (below): a literal on a `nomerge` call site cannot
  // be this fold's image and is admitted; this paragraph now describes the
  // population WITHOUT the call-site attribute.
  // A RUNTIME base cannot be the image of that CONSTANT fold: IPSCCP
  // substitutes only constants, and SimplifyCFG sinks a call only when at most
  // ONE operand needs a φ (`NumPHIInsts <= 1`), so arg-0 must already AGREE in
  // both arms before the sink — measured, `a3`/`a4` keep the if/else unsunk.
  // (The RELATIONAL select fold of bd `zt0b` — `select (q == s), q, s → s` —
  // can put a runtime `s` into an arg-0; its diamond-prep image is a module
  // indistinguishable from a legitimate program, see F2's runtime-seed header and
  // bd `fmt3`. An ANGLE-SELECT image of it would need two such inner folds under
  // an outer if/else that differ only in the angle; MEASURED on
  // `z0re_probes/src/r2as1.c` that `-O1` keeps a 4-predecessor merge instead and
  // it declines `nested control flow` on both binaries.)
  //
  // ⚠ WHAT bd `fmt3` OPTION B (`nomerge` on `cq_theta_*`, landing AFTER z0re)
  // DOES TO THIS ADMISSION — ONLY THE IF/ELSE SPELLING STOPS REACHING IT. The
  // if/else `if (c) { r = t; cq_theta(&r, A); } else { r = t; cq_theta(&r, B); }` reaches S3 only
  // because SimplifyCFG MERGES the two thetas; under `nomerge` the if/else
  // survives and declines `if/else state prep allocates two rails` (owner ruling
  // Q4). The TERNARY spelling `r = t; cq_theta(&r, c ? A : B);` produces the SAME
  // one-theta-on-an-angle-select IR with NO merge at all, so it is untouched by
  // `nomerge` and this untainted-base admission STAYS A PLAIN-C ACCEPT SURFACE
  // (Rule-13 r2 F-r2-1, measured with a `nomerge` `CQ.h`: probe `t1nm` accepts
  // with a trace byte-identical to `slice_z0re_angle_select_runtime_base_exact`'s
  // golden). ⚠ CORRECTED (L7): the round-2 spelling of this paragraph said the
  // whole admission becomes UNREACHABLE FROM C — false; the ternary reaches it.
  // So when fmt3 lands, the if/else C slices `slice_z0re_angle_select_runtime_base*`
  // are to be RESPELLED as ternaries (which keeps their goldens), not turned into
  // declines. The IR-level pins `control_angle_select_ry_runtime_base{,_i8,_f64}.ll`
  // and `spec_angle_select_runtime_base_side_door{,_twin}.ll` hold either way.
  //
  // NO SUBJECT for the register-free phase stem: it has no arg-0, no register
  // and therefore no state-prep ambiguity to fence. `RotBase` stays null there
  // and every clause below that reads it is `IsPhase`-guarded.
  //
  // ---- bd test_C_libtooling-dm7f.54 — A `nomerge` LITERAL BASE IS ADMITTED
  //      (`angleSelectLiteralSeedAdmissible`), which NARROWS the drbq.13 decline
  //      above to the population its counter-example lives in. That
  //      counter-example is a SimplifyCFG SINK of two thetas, and LLVM 19 sinks
  //      no call that `cannotMerge()`; every direct `cq_theta_*` call clang emits
  //      from `CQ.h` carries `nomerge` at the call site (measured, stage-1 IR
  //      `attributes #N = { nomerge nounwind }`), so such a module is the user's
  //      `bool t = 0; cq_theta(&t, c ? A : B)` (CQ_FINDINGS F4, reporter t4). The
  //      stream is the runtime base's with `alloc(SEED)`: a fresh rail rotated
  //      by exactly `A` or exactly `B`. Without the call-site attribute (hand
  //      IR; a devirtualized function pointer, bd 4e4p) the decline stands with
  //      its string, pinned by `..._reject_literal_base_offwire_fold.ll` and
  //      `..._reject_state_prep.ll`. ⚠ CORRECTED (round-1 review, L7): `nomerge`
  //      rules out the MERGE route only. A literal can also be the image of a
  //      VALUE SUBSTITUTION on a dominating equality edge (review p7), so S3
  //      also asks `angleSelectLiteralSeedPinned` (F2's question at the
  //      consumer, below the `DT` guard), and a pinned value that is classical
  //      at round 1 IS recorded for the L1 re-ask (`kAngleSelSeedPinMD`). The
  //      literal itself cannot turn quantum; the value it stands for can.
  Value *RotBase = IsPhase ? nullptr : T->getArgOperand(0);
  const bool UntaintedBase = !IsPhase && !Taint.Tainted.count(RotBase);
  const bool LiteralSeed =
      UntaintedBase && IsTheta && angleSelectLiteralSeedAdmissible(T);
  if (UntaintedBase && !LiteralSeed &&
      !(IsTheta && isRuntimeStatePrepSeed(RotBase, Taint)))
    return AngleSelectDisp::NotApplicable;

  // S4 — a BARE lowerable compare, ONE tainted operand, ONE user.
  //
  // The single-user clause carries three declines at once and they are worth
  // naming, because each is a real shape and none has an emitter here: the
  // compare ALSO controlling a `br` region (two owners of one flag), the
  // compare ALSO read as data (`ShareCondFlag`, whose strip is SKIPPED — this
  // stream's is not), and the compare feeding a SECOND angle select (two gates
  // per arm, which `clang -O1` produces from `if(c){g1;g2}else{g3;g4}`). All
  // three are recorded follow-ons, not defects.
  //
  // ---- bd test_C_libtooling-dm7f.54 — THE Ry STEM TAKES EVERY CONDITION KIND
  //      THE 4.4 SELECT TAKES: a bare `_Bool` RAIL, a claimed region-merge φ
  //      ROOT, or a COMPOUND tree (`and`/`or`/`xor`/logical `select i1` over
  //      compare, rail and φ leaves; `SelectClassify` collects the tree with
  //      `AllowLogicalSelect` for an angle select). `NetCond`: the flag is the
  //      root of `CondTreeEmit`'s network minted at `T` with `CopyRailRoot`, so
  //      it is ALWAYS an ancilla this region owns (a rail or φ root gets the
  //      `cqrt_cnot` copy) and the X-bracket form of the owner ruling
  //      (`owner-ruling-angle-select-xbracket-2026-10-13`) applies verbatim: no
  //      `cqrt_x` ever touches a user register, and each arm reaches one gate.
  //      The bare single COMPARE keeps the shipped path byte-for-byte. The PHASE
  //      stem keeps its shipped scope (compare or bare rail); widening it to a
  //      tree or φ root is a separate follow-on.
  const bool SingleCmp = Tree.Nodes.empty() && Tree.Leaves.size() == 1 &&
                         Tree.RailLeaves.empty() && Tree.RailPhiLeaves.empty();
  const bool NetCond = IsTheta && !SingleCmp && Tree.LiteralLeaves.empty() &&
                       (!Tree.Nodes.empty() || Tree.RailLeaves.size() == 1 ||
                        Tree.RailPhiLeaves.size() == 1);
  if (!NetCond && (!Tree.Nodes.empty() || !Tree.RailPhiLeaves.empty() ||
                   Tree.Leaves.size() + Tree.RailLeaves.size() != 1))
    return AngleSelectDisp::NotApplicable;  // a compound `&&`/`||` tree.
  // bd 3qlq.4 — the single leaf is a COMPARE (every pre-1b line below) or a
  // RAIL (`_Bool b = …; cq_theta(&b, …); if (b) cq_phi(A); else cq_phi(B);`, which
  // `clang -O1` folds to `select i1 %b, double A, double B` feeding ONE
  // `cq_phi`). A rail condition is admitted for the PHASE stem only: its
  // kickback pair is `rz(b, −B); rz(b, A)` on the register itself (no mint,
  // no strip, no free, nothing non-diagonal on `b`). The Ry stem — a
  // `cqrt_ry_<W>_controlled(b, …)` controlled on the register — is follow-on
  // 1b-C and DECLINES with `kBareRailCondReason` (not `NotApplicable`, which the
  // caller would report as `rotation angle`, the wrong reason).
  // ⚠ bd dm7f.54: the `cq_theta` Ry stem on a rail no longer reaches that
  // decline — it is `NetCond` above (the CNOT copy flag). What still declines
  // it is the retired register-form `cq_phi_<sfx>` stem (`IsPhi`).
  const bool RailCond = !NetCond && !Tree.RailLeaves.empty();
  // For `NetCond`, `Cond` is the tree ROOT: a node, a rail or a φ.
  Instruction *Cond =
      NetCond    ? dyn_cast<Instruction>(Sel->getCondition())
      : RailCond ? static_cast<Instruction *>(Tree.RailLeaves.front())
                 : static_cast<Instruction *>(Tree.Leaves.front());
  if (!Cond || Cond != Sel->getCondition())
    return AngleSelectDisp::NotApplicable;
  // The root is a value this region's emitter may ERASE (a tree node) or a
  // register the user owns (a rail call or a claimed φ, never erased).
  const bool NetRegRoot =
      NetCond && (isCondRailLeaf(Cond) || isa<PHINode>(Cond));
  if (NetCond) {
    // A node root's ONLY user is the select: the network is minted from it and
    // erased once dead, and a second consumer (a `br` region, a second select,
    // a data use) would be a second owner of one predicate — the S4
    // single-user clause, one node up.
    // bd dm7f.54 (item D, review F3): a node ROOT may have OTHER users (`_Bool c
    // = a && b; cq_theta(&t, c ? A : B); cq_measure(c)`). The network is minted
    // from the LEAVES, so the root instruction is not consumed: the emitter
    // erases it only when dead, and its other users lower on their own (a
    // logical-select root with a data use is not pre-claimed and lowers as its
    // own 4.4 data select, emitted AFTER this region by the precedence edge in
    // `lowerControlRegions`). A root shared with another CONTROL region is
    // refused at S10 with its own string.
    // Every COMPARE leaf mints through `lowerCompareToFlag` with NO Q+Q width
    // (`AllowQQLeaves = false`, the in-place Ry tree's policy), so each must
    // have exactly one tainted operand — asked HERE, before any emission, since
    // a mid-network mint failure would leave sibling flags dangling (the ziov.4
    // discipline). Gate 2 already asked predicate scope and mintability.
    for (CmpInst *Leaf : Tree.Leaves) {
      const bool LT = Taint.Tainted.count(Leaf->getOperand(0)) != 0;
      const bool RT = Taint.Tainted.count(Leaf->getOperand(1)) != 0;
      if (LT == RT || !comparePredLowerable(Leaf) ||
          !compareFlagMintable(Leaf, Taint))
        return AngleSelectDisp::NotApplicable;
    }
    for (CallInst *Rail : Tree.RailLeaves)
      if (!Taint.Tainted.count(Rail))
        return AngleSelectDisp::NotApplicable;
  } else if (RailCond) {
    if (!IsPhase) {
      diagnoseUnderControl(Sel, kBareRailCondReason);
      return AngleSelectDisp::Declined;
    }
    if (!Taint.Tainted.count(Cond))
      return AngleSelectDisp::NotApplicable;
    // A rail's other uses are ordinary (it is the user's register) — no
    // `hasOneUse` fence; the compare's exists because its FLAG is minted and
    // erased by this emitter, and a rail is neither.
  } else {
    auto *Cmp = cast<CmpInst>(Cond);
    if (!Cmp->hasOneUse())
      return AngleSelectDisp::NotApplicable;
    const bool LTainted = Taint.Tainted.count(Cmp->getOperand(0)) != 0;
    const bool RTainted = Taint.Tainted.count(Cmp->getOperand(1)) != 0;
    if (LTainted == RTainted)
      return AngleSelectDisp::NotApplicable;  // Q+Q, or all-classical.
    if (!comparePredLowerable(Cmp) || !compareFlagMintable(Cmp, Taint))
      return AngleSelectDisp::NotApplicable;
  }

  // bd dm7f.54 (item E) — S4 FOR EVERY INNER MUX MEMBER, the root's clauses
  // verbatim per member: a bare compare (single user, one tainted operand,
  // lowerable, mintable) or a `NetCond` tree (literal-free; every compare leaf
  // one tainted operand and mintable; every rail tainted). Each member's tree
  // is collected with gate 2's grammar for a mux member (`AllowLogicalSelect`,
  // `AllowRailPhi`). `MuxConds` holds every member's (root included) condition
  // tree for S7, S8, S11 and the precedence record below.
  struct MuxCond {
    SelectInst *S;
    CondTree Tree;
    Instruction *Cond;
    bool Net;
  };
  SmallVector<MuxCond, 4> MuxConds;
  MuxConds.push_back({Sel, Tree, Cond, NetCond});
  for (SelectInst *M : Members) {
    if (M == Sel)
      continue;
    MuxCond MC{M, CondTree(), dyn_cast<Instruction>(M->getCondition()), false};
    if (!MC.Cond ||
        !collectCondTree(M->getCondition(), MC.Tree,
                         /*AllowLogicalSelect=*/true, /*AllowRailPhi=*/true) ||
        !MC.Tree.LiteralLeaves.empty())
      return AngleSelectDisp::NotApplicable;
    const CondTree &Tm = MC.Tree;
    MC.Net = !(Tm.Nodes.empty() && Tm.Leaves.size() == 1 &&
               Tm.RailLeaves.empty() && Tm.RailPhiLeaves.empty());
    if (MC.Net && Tm.Nodes.empty() &&
        Tm.RailLeaves.size() + Tm.RailPhiLeaves.size() != 1)
      return AngleSelectDisp::NotApplicable;
    if (!MC.Net && !MC.Cond->hasOneUse())
      return AngleSelectDisp::NotApplicable;
    for (CmpInst *Leaf : Tm.Leaves) {
      const bool LT = Taint.Tainted.count(Leaf->getOperand(0)) != 0;
      const bool RT = Taint.Tainted.count(Leaf->getOperand(1)) != 0;
      if (LT == RT || !comparePredLowerable(Leaf) ||
          !compareFlagMintable(Leaf, Taint))
        return AngleSelectDisp::NotApplicable;
    }
    for (CallInst *Rail : Tm.RailLeaves)
      if (!Taint.Tainted.count(Rail))
        return AngleSelectDisp::NotApplicable;
    MuxConds.push_back(std::move(MC));
  }

  // S5 — the ABI width must have a `cqrt_ry_<W>_controlled` (Ry stem), asked through
  // the expression `lowerRotations` MINTS from (`RotationLowering.h`'s note on
  // `suffixFromName`). Inc-1's R4 asks `abiWidthFromType(T->getType())`; the two
  // agree for every `CQ.h` suffix measured, and asking the mint's own expression
  // is what keeps a divergence from becoming a decline AFTER mutation.
  //
  // NO SUBJECT for the register-free phase stem (3qlq Inc 1): it emits no
  // `_controlled` gate at all — the two gates are UNCONTROLLED `cqrt_rz_i1` on
  // the flag ancilla — so there is no per-width controlled symbol to look up,
  // and no `cq_{theta,phi}_<sfx>` name to strip a suffix from. Asking it anyway
  // would call `suffixFromName(T, "cq_phi_")` on a callee named exactly
  // `cq_phi`, get the empty suffix, and decline every phase select.
  if (!IsPhase && !abiWidthHasControlledRotation(wd.abiWidthFor(
                      suffixFromName(T, IsTheta ? "cq_theta_" : "cq_phi_"))))
    return AngleSelectDisp::NotApplicable;

  // S10 — nothing else already claims this gate or this select. `plan` may
  // already carry a `BranchRegion` whose arm gate is `T` (an in-place rotation
  // arm) or a `SelectRegion` on `Sel`; emitting twice would double the stream.
  // Cheap linear scan — a plan holds a handful of regions.
  if (Taint.ControlledRotations.count(T))
    return AngleSelectDisp::NotApplicable;
  for (const ControlRegion &R : plan.Regions) {
    // (A RAIL condition may legitimately be another region's condition too —
    // nothing is minted or erased for it, so two regions on one register do
    // not contend; the compare clause exists because a compare's flag is.)
    // (bd dm7f.54: a `NetCond` rail or φ ROOT is a register too.)
    if (R.Merge == Sel || (!RailCond && !NetRegRoot && !NetCond &&
                           R.Condition == Cond))
      return AngleSelectDisp::NotApplicable;
    // bd dm7f.54 (item D): a shared NODE root names its true reason.
    if (NetCond && !NetRegRoot && R.Condition == Cond) {
      diagnoseUnderControl(Sel, "angle select condition shared with another "
                                "control region");
      return AngleSelectDisp::Declined;
    }
    for (SelectInst *M : Members)
      if (M != Sel && R.Merge == M)
        return AngleSelectDisp::NotApplicable;
    for (Instruction *I : R.Shadow)
      if (I == T)
        return AngleSelectDisp::NotApplicable;
    for (Instruction *I : R.ShadowFalse)
      if (I == T)
        return AngleSelectDisp::NotApplicable;
  }

  // S7 — FLAT ONLY (Inc 3 = drbq.4 owns the rolled in-loop form). Asked HERE,
  // before the positional and wire clauses, so a loop shape gets the LOOP
  // message rather than a positional one that mislabels it: `clang -O1` LICM-
  // hoists the loop-invariant compare and select out of the body and leaves the
  // consumer inside, so S6's "one block" clause would otherwise fire first and
  // say nothing true about why the shape is refused. `classifyArms` asks R7's
  // loop clause before R6 for exactly this reason. All THREE blocks are asked
  // (over-decline is safe): a select inside a loop whose consumer is outside is
  // as unproven as the reverse.
  //
  // *** IT SHIPPED ASKING A NARROWER QUESTION THAN EVERY SIBLING, AND THAT WAS
  // TWO OVER-ACCEPTS *** (bd drbq Inc 2b ROUND-1 RULE-13 review, lenses L3-1 and
  // L2-1). `LI->getLoopFor` of three blocks is a NATURAL-loop question about the
  // three ANCHOR positions; the siblings ask two other things:
  //
  //  (a) `ControlDetect::regionEntryInLoop` — a reducibility-INDEPENDENT CFG
  //      successor walk. An IRREDUCIBLE cycle (`goto` into a loop body / Duff's
  //      device, reachable from real `clang -O1`) has NO `LoopInfo` loop, so the
  //      `getLoopFor` spelling was VACUOUS on it and the angle select ACCEPTED —
  //      where the manual by-difference DIAMOND over the same cycle declines
  //      `control flow inside a loop body`, and the plain UNCONTROLLED rotation
  //      declines `tainted handle live range crosses a loop backedge`. Every
  //      downstream guard that adjudicates a cycle (`LoopLowering`'s Case-A rail
  //      analysis, `markIfIterationLocal`, `FreePoint`'s back-edge live-range
  //      reject) is `LoopInfo`-gated, so accepting there put a controlled
  //      rotation and a mint/strip/free quadruple inside a cycle nobody checks,
  //      and the freeze SILENCED the pre-existing loud Rule-6 reject.
  //
  //  (b) whether the ROTATED REGISTER'S RAIL is in a loop, which is a question
  //      about the register, not about the three anchors. `lowerLoops` runs at
  //      `CQLoweringPass.cpp:310`, BEFORE detection (:322) and emission (:323),
  //      and its `staleRailRecordRead` fence refuses the DIAMOND spelling of a
  //      loop-rail read in the loop's EXIT block — but 2b's unconditional twin
  //      `T0` is inserted THIRTEEN pipeline steps later, so that fence
  //      structurally cannot see it. The twin declines and the select form
  //      accepted: the 8h7d.5 lesson verbatim, a fence that runs before the
  //      emitter is not a fence on what the emitter adds.
  //
  // So S7 asks three questions, ORed. The walk in (a) is `ControlShape.h`'s
  // `blockOnCycle` — the SAME function `regionEntryInLoop` is built from,
  // exported rather than re-implemented (Rule 14: a second reachability here is
  // how two spellings of one relation eventually disagree).
  //
  // *** WHAT THE THREE PRONGS DO NOT ASK — TWO ASYMMETRIES, BOTH DELIBERATE,
  // *** BOTH MEASURED SOUND, AND NEITHER OF THEM "OVER-DECLINING BY
  // *** CONSTRUCTION" (bd drbq Inc 2b ROUND-2 review, lens R1 item 2; the first
  // *** draft of this paragraph said exactly that and it is false).
  //
  //  1. THE RAIL FORWARD OF `T`. Prong (ii) asks three ANCHOR blocks; prong (iii)
  //     asks the closure, which carries `Exclude = T` and therefore stops there.
  //     A cycle that contains a gate on the SAME rail but is not any of the three
  //     anchor blocks is asked by NEITHER — measured: a downstream (pre-3qlq)
  //     `cq_phi(%t, 0.1)` inside an irreducible cycle, and the same inside a natural loop,
  //     both ACCEPT (`review2b_r2/R1/probes/s7/{fwd,nat}_sel_{ry,rz}.ll`), while
  //     the plain UNCONTROLLED rotation over the same cycle declines `tainted
  //     handle live range crosses a loop backedge`. That is the same "a loud
  //     decline becomes silence" shape prong (a) above was built for, so it is
  //     stated rather than left implicit — but it IS SOUND and it is NOT 2b's:
  //     the manual by-difference twin over the same cycle lowered on the PRE-2b
  //     binary with `@example` bodies BYTE-IDENTICAL to the 2b stream of the time
  //     (the dm7f.6 stream adds one more controlled gate on the same rail, which
  //     the argument below covers unchanged), so the
  //     silencing belongs to Inc-1's structural freeze
  //     (`ChainWalk::railCarriesControlledRotation` stops the uncompute spine
  //     walking a rail that carries a controlled rotation), which reproduces on
  //     the oracle. Accept fixture:
  //     `control_angle_select_forward_rail_cycle_frozen.ll` (re-spelled by bd
  //     3paw to the register-free form, a natural loop, collapsed; the pre-3qlq
  //     argument above is in its git history).
  //     The `Exclude = T` rationale is correspondingly narrower than it reads: it
  //     is a statement about `T`'s OWN POSITION (asked directly by prong (ii)),
  //     NOT about the rail past `T`. Crossing `T` would sweep every legitimate
  //     post-region consumer into the closure and collapse the accept class,
  //     which is why the exclusion stays.
  //
  //  2. THE CONDITION REGISTER'S RAIL. Prong (iii) asks the ROTATED register's
  //     closure only. The mirror shape — the CONDITION register is the loop rail,
  //     read in the exit block, the rotated register outside — ACCEPTS
  //     (`review2b_r2/R1/probes/s7/oa2_condrail_loop_{ry,rz}.ll`) and was again
  //     BYTE-IDENTICAL to its manual twin on the pre-2b oracle (the by-difference
  //     stream, before dm7f.6). Sound, and stated
  //     here because it is the half L2-1 happened not to land on; both
  //     `control_angle_select_reject_loop_rail_exit_block{,_rz}.ll` headers say
  //     so too.
  //
  // *** AND WHAT PRONG (iii)'s COVERAGE OF THE L2-1 FAMILY ACTUALLY RESTS ON ***
  // (round-2 review, lens R1 item 3). It is CONTINGENT on an EARLIER STAGE's
  // rewrite, not on the closure this clause computes: `lowerLoops` runs at
  // `CQLoweringPass.cpp:310`, BEFORE detection, and its Case-A persistent-rail
  // COLLAPSE rewrites a loop header phi that carries the rail, which turns the
  // in-loop gate into a DIRECT forward user of `RotBase` — that is the only
  // reason prong (iii) sees it despite `Exclude = T`. So a future change to
  // Case-A's collapse SILENTLY NARROWS S7, with no fixture here to notice — the
  // 8h7d.5 lesson running in the opposite direction.
  // ⚠ CORRECTED by bd 3paw (L7). This paragraph also said that a FORWARD loop
  // with a header phi (`oa1_var_seed_t.ll`) DECLINES while the identical read
  // without one (`nat_sel_rz.ll`) ACCEPTS. The decline was the collapse's
  // re-spelling, not a cycle question about `T`: a name the collapse moved onto
  // `RotBase` from a POST-gate value is now skipped by this prong and by S9 (the
  // `CollapsedRail` note below), so both spellings accept. What still rests on
  // the collapse is the BACKWARD half only, a loop that runs before `T`
  // (`control_angle_select_reject_backward_rail_cycle.ll`).
  if (!DT || !LI)
    return AngleSelectDisp::NotApplicable;  // no analysis, no proof.
  //
  // MEMOIZED per block. `blockOnCycle` is an O(V+E) successor walk and the rail
  // prong below asks it of every closure member; a closure has a handful of
  // members but they routinely share blocks, and the `LoopInfo` half
  // short-circuits only for blocks that ARE in a natural loop — the walk is paid
  // exactly on the blocks that are not.
  //
  // COST, since the memo's scope is easy to over-read: it is per SELECT, not per
  // module, so classification costs O(S·(V+E)) over S angle selects, and the
  // `LoopInfo` short-circuit never helps a straight-line function (no block is in
  // a natural loop, so every one pays the full walk). Measured 0.42 s for 200
  // angle selects over a 4,200-block CFG (round-2 review, lens R1 item 7) — no
  // blow-up at any size this project meets, and worth knowing before the memo is
  // "simplified" away or hoisted to module scope.
  DenseMap<const BasicBlock *, bool> CycleCache;
  auto blockInAnyCycle = [&](BasicBlock *BB) {
    if (LI->getLoopFor(BB))
      return true;
    auto It = CycleCache.find(BB);
    if (It != CycleCache.end())
      return It->second;
    const bool OnCycle = blockOnCycle(BB);
    CycleCache[BB] = OnCycle;
    return OnCycle;
  };
  if (blockInAnyCycle(T->getParent()) || blockInAnyCycle(Sel->getParent()) ||
      blockInAnyCycle(Cond->getParent())) {
    diagnoseUnderControl(Sel, "control flow inside a loop body");
    return AngleSelectDisp::Declined;
  }
  // bd dm7f.54 — a `NetCond` tree has more than one anchor: every LEAF is a
  // position the network reads (a compare is re-minted from, a rail or φ is
  // read as a control), so each is asked the same cycle question `Cond` is.
  // (bd dm7f.54 E: and every inner mux member, its condition and leaves.)
  for (const MuxCond &MC : MuxConds) {
    if (!MC.Net && MC.S == Sel)
      continue;  // the root's single compare: asked just above.
    SmallVector<Instruction *, 8> LeafAnchors(MC.Tree.Leaves.begin(),
                                              MC.Tree.Leaves.end());
    LeafAnchors.append(MC.Tree.RailLeaves.begin(), MC.Tree.RailLeaves.end());
    LeafAnchors.append(MC.Tree.RailPhiLeaves.begin(),
                       MC.Tree.RailPhiLeaves.end());
    LeafAnchors.push_back(MC.S);
    LeafAnchors.push_back(MC.Cond);
    for (Instruction *L : LeafAnchors)
      if (blockInAnyCycle(L->getParent())) {
        diagnoseUnderControl(Sel, "control flow inside a loop body");
        return AngleSelectDisp::Declined;
      }
  }

  // S7's RAIL prong. The base's wire closure is computed HERE — BEFORE the
  // stem split — and for BOTH stems, because the loop question is not a
  // basis-label question and the Rz stem's §12.1 diagonal exemption says nothing
  // about it. The Rz stem previously computed NO closure at all.
  //
  // *** WHAT OTHER SET IS COMPUTED OVER THIS CLOSURE (the 8h7d.5 F-1/F-3
  // discipline). *** THREE consumers, and this change adds a FOURTH without
  // altering any of them: S8's intersection with `CondRails` reads `BaseWireOrder`;
  // S9's member enumeration reads `BaseWireOrder`; S9's SKIP SET reads `BaseWire`.
  // The closure is now computed once and REUSED by all of them rather than
  // recomputed — same seed (`RotBase`), same direction (`BothWays`), same arm
  // blocks (none), same `Exclude = T`, so the three existing readers see exactly
  // the set they saw before. The only new reader is this loop question.
  //
  // `Exclude = T` is kept for this question too, and the reason is the same one
  // it exists for: `T`'s RESULT is the POST-GATE name of the register, so
  // crossing it would sweep every legitimate post-region consumer into the
  // closure and collapse the accept class.
  //
  // *** THE CORRECT READING OF THAT EXCLUSION, and the first draft got it wrong
  // *** (round-2 review, lens R1 item 2): it said "`T`'s own block is asked
  // *** DIRECTLY above, so NOTHING about the consumer's position is lost". That
  // *** is true of `T`'s POSITION and FALSE OF THE RAIL PAST `T` — a cycle
  // *** carrying a gate on this same rail, in none of the three anchor blocks, is
  // *** asked by neither prong and ACCEPTS. It is sound (byte-identical to the
  // *** manual twin on the pre-2b oracle; the silence belongs to Inc-1's
  // *** structural freeze) and it is pinned by the accept fixture
  // *** `control_angle_select_forward_rail_cycle_frozen.ll`. The full argument is
  // *** in the S7 header comment above; do not re-derive it from this line.
  // Note also that the closure asked here is the ROTATED register's only; the
  // CONDITION register's rail is never asked (asymmetry 2 in the header).
  //
  // SKIPPED WHOLE for the register-free phase stem: `RotBase` is null because
  // there IS no rotated register — the two gates land on the flag ancilla, which
  // is minted, used, stripped and freed between the mint and the free, entirely
  // inside whatever block `T` sits in. The ANCHOR prong above still runs and
  // still declines a phase select anywhere on a cycle. (That anchor decline is a
  // deliberate OVER-decline for this stem and a recorded follow-on: the in-loop
  // phase select's per-iteration stream is the SAME quadruple the P1 in-loop
  // kickback already emits, so it is very likely sound — but admitting it needs
  // a `flatRegionRollableInLoop`-equivalent for a region that has no
  // Pred/Arm/MergeBB at all, and the 8h7d.5 record says budget adversarial
  // rounds for every loop widening.)
  SmallPtrSet<Value *, 16> BaseWire;
  SmallVector<Value *, 16> BaseWireOrder;
  // bd z0re — SKIPPED WHOLE for an UNTAINTED (runtime) base, and so are the
  // two readers below that iterate `BaseWireOrder` (S8, S9): the rotated rail is
  // minted by the emitter's unconditional twin, so it has no pre-region SSA
  // name for this closure to collect (S3's comment carries the argument). An
  // EMPTY `BaseWireOrder` makes all three loops vacuous — which is the skip, and
  // it is NOT "hand `railWireClosure` the classical seed", whose `Out.insert(W)`
  // runs BEFORE its taint gate and would enumerate `t`'s classical users as
  // stale records of a rail they never were (§14.5's measured trap).
  if (!IsPhase && !UntaintedBase)
    railWireClosure(RotBase, Taint, WireDir::BothWays, nullptr, nullptr,
                    BaseWire, &BaseWireOrder, /*Exclude=*/T);

  // ---- bd `test_C_libtooling-3paw` — A NAME THE ROUND-1 COLLAPSE RE-SPELT.
  //
  // `Exclude = T` keeps the post-gate register out of this closure, and Case-A
  // undoes that before detection runs. `tryCaseA` (in `lowerLoops`) RAUWs every
  // rail φ it claims, among them the header φ and the exit φ of a loop AFTER
  // `T`, both post-gate names, to the rail's ROOT MINT. When `RotBase` is on that
  // rail, the loop's `cq_theta(root, ·)` and the exit's `cq_measure(root)` read a
  // name the closure collects. Here the prong below called the loop gate a cycle
  // member of the base's wire, and S9 called the measure a stale record. That
  // declined `cq_theta(&r, c ? A : B); for (…) cq_theta(&r, .1);`, a sound
  // program (`control_angle_select_forward_rail_cycle_frozen.ll`, e2e
  // `slice_control_angle_select_ry_forward_loop`).
  //
  // THE SKIP. A member (this prong) or a reader (S9) is skipped when the rail is
  // CLAIMED (`TaintSet::ClaimedRailRoots`, written by both collapse sites, holds
  // `RotBase`'s root mint for some loop) AND `T` DOMINATES it. `T`'s anchors are
  // on no cycle (asked above), so `T` runs at most once per activation and every
  // execution of a dominated name follows it. Dominance, not reachability: it is
  // exact, where `isPotentiallyReachable` answers `true` past its block budget,
  // and it keeps a loop BEFORE `T` declining
  // (`control_angle_select_reject_backward_rail_cycle.ll`).
  //
  // WHY THE SKIP IS SOUND, AND WHAT IT RESTS ON. It is exact only because the
  // collapse's own fence refuses, on the PRE-collapse IR and with `T` in its gate
  // set, every claimed rail in which a dominated name reads a PRE-gate record.
  // `T` is an in-place gate on `RotBase`, and `RotBase` peels in place to the
  // claimed root, so `T` is in `tryCaseA`'s `railRoot` and in the gate set of
  // its `staleRailRecordRead`. For a pre-gate record `M` (its definition
  // dominates `T`) and a reader `U` that `T` dominates, the path `M → T → U`
  // exists and cannot re-run `M`'s definition without putting `T` on a cycle,
  // which the anchor prong above refused. So that fence finds a gate between `M`
  // and `U` for each of the three ways `U` can read `M`:
  //   * a measure / `ret` (any non-member user): `staleReadOfValue`'s positional
  //     test, at the instruction;
  //   * a rail φ (a member the collapse folds onto the root): the same test on
  //     each incoming EDGE. ⚠ Only since bd g35c. Before it `staleReadOfValue`
  //     skipped member users wholesale, so the zero-trip exit φ
  //     `phi [%pre-gate, guard], [%post, latch]` was never asked, and this skip
  //     passed its `ret` and its `xor` + measure as post-gate reads, a silent
  //     miscompile (`control_angle_select_reject_forward_rail_cycle_zero_trip_
  //     {stale,ret}.ll`). The header φ seeded with a pre-gate alias
  //     (`control_angle_select_reject_forward_rail_cycle_stale_alias.ll`) is the
  //     same edge test;
  //   * a second in-place gate on `M`: `tryCaseA`'s fan-out guard (`T` is the
  //     first). Its CLOSURE leaves the rail unclaimed for any other user.
  // A dominated reader that survives is therefore a reader of a post-gate name,
  // which is what the handle holds once `lowerRotations` RAUWs the rail onto it.
  // The emitter's mint, true-arm gate and opening `x(f)` land contiguously
  // immediately before `T` (and the closing `x(f)` right after it), so no read
  // lies between them and the fence's answer does not change with them.
  //
  // `recordStaleQuantumReaders` is NOT what makes the skip exact: it never asks a
  // `ret`, and it did not reach the pre-gate record through the exit φ and an
  // `xor` (bd g35c, measured). It does refuse a `cq_theta` / `cq_measure` reader
  // of a stale name, including one on a frozen identity carry, so for that
  // sub-shape it is a SECOND wall, and in the round-2 shape below it is the ONLY
  // one.
  //
  // ⚠ THE ROUND-2 WRITER IS NOT COVERED BY THIS ARGUMENT (Rule-11 round-2 review,
  // finding F2). `railChainRootMint` peels any `add`/`xor` by SHAPE
  // (`peelInPlaceBase` with `AsLowered=false`), while `collapseRailPhisIn`'s
  // gate set (`collectRailGates`) follows an `add`/`xor` only when it is marked
  // in place. So for a `T` classified at ROUND 2 (a 6.5 `%out` condition) whose
  // base reaches the claimed root only through an OUT-OF-PLACE `x = r ^ 1`,
  // `CollapsedRail` is true while `T` is in no claiming fence's gate set: with
  // `keep = x; cq_theta(&x, y == k ? .9 : .3);` and a round-2-claimed loop on `r`,
  // `return keep` (a pre-`T` read that `T` dominates) is skipped by S9 and asked
  // by nobody here. Today `recordStaleQuantumReaders` declines that program at the
  // loop's `cq_theta(&r, .1)` (`rotation/measure operand predates a non-diagonal
  // gate`), and that decline is itself an OVER-decline: `T` moves `x`'s fresh
  // rail, not `r`'s. RETIREMENT TRIGGER: fixing that over-decline re-opens this
  // hole unless the skip is keyed on the claiming fence's own gate set (`T` in
  // it) or the root is found with the lowered-aware peel (`AsLowered=true`).
  //
  // Population note (L9): the skip hands angle selects to Case-A-claimed loops,
  // so a gap in that fence's loop-gate questions is reachable through them too;
  // bd hk9y (a member gate on a frozen identity carry, fixed in
  // `staleReadOfValue`) was one, `control_angle_select_reject_forward_rail_cycle_
  // frozen_carry_xor.ll`.
  // RETIREMENT TRIGGER: re-introducing any member skip in `staleReadOfValue`
  // beyond a member φ's self edge and a member gate on a refreshing record,
  // dropping `T` (a collected `cq_theta`) from the collapse's gate set, or a third
  // collapse site that writes `ClaimedRailRoots` without that fence, re-opens
  // this skip.
  bool CollapsedRail = false;
  if (!IsPhase && !UntaintedBase) {
    SmallPtrSet<CallInst *, 32> GateCalls;  // the `lowerLoops` recipe (θ ∪ φ)
    GateCalls.insert(Taint.ThetaCalls.begin(), Taint.ThetaCalls.end());
    GateCalls.insert(Taint.PhiCalls.begin(), Taint.PhiCalls.end());
    if (CallInst *Root = railChainRootMint(RotBase, GateCalls, Taint))
      for (Loop *L : LI->getLoopsInPreorder())
        if (Taint.ClaimedRailRoots.count({Root, L->getHeader()})) {
          CollapsedRail = true;
          break;
        }
  }
  auto collapsedPostGateName = [&](const Instruction *I) {
    return CollapsedRail && DT->dominates(T, I);
  };

  for (Value *W : BaseWireOrder) {
    auto *WI = dyn_cast<Instruction>(W);
    if (WI && blockInAnyCycle(WI->getParent()) && !collapsedPostGateName(WI)) {
      diagnoseUnderControl(Sel, "control flow inside a loop body");
      return AngleSelectDisp::Declined;
    }
  }

  // S6 — POSITION. `Cond`, `Sel` and `T` in ONE block, in that order, with no
  // in-place `Ry` between the compare and the CONSUMER.
  //
  // The window ends at `T`, not at `Sel`, and that extension is the whole
  // difference from gate 2c's prong (c): `SelectMergeEmit` mints its flag AT
  // THE SELECT, this emitter mints it at the CONSUMER, so the gap that can
  // stale the flag is the longer one. Wire-blind by design (a theta on ANOTHER
  // register also declines) — the same conservatism `condWireDisposition` and
  // gate 2c prong (c) already carry, and the same reason: a positional scan
  // that tried to be wire-aware would have to answer the rail-identity question
  // this classifier only answers later, in S8.
  //
  // bd dm7f.54 — FOR `NetCond` THE WINDOW STARTS AT THE SELECT. The root may
  // sit in another block (a rail defined in the entry, a φ in a merge block, a
  // tree whose leaves are anywhere): what this clause protected — "no gate
  // between the mint's operands and the mint" — is asked per leaf species by
  // the wire walks instead: gate 2c's position-free prong over every compare
  // leaf's provenance and its per-leaf positional prong up to `Sel`, and for
  // every rail/φ leaf the DT prong, re-asked below at `T` (the mint point).
  // The `(Sel, T)` stretch keeps this wire-blind scan.
  //
  // bd dm7f.54 (item E): for a mux every member sits in `T`'s block before `T`
  // (each bare-compare member's compare too, before its select), and the
  // window starts at the EARLIEST of them: every flag of the mux is minted at
  // `T`, so the window that can stale any of them is the longest one.
  BasicBlock *BB = T->getParent();
  const Instruction *WindowStart = nullptr;
  for (const MuxCond &MC : MuxConds) {
    if (MC.S->getParent() != BB || (!MC.Net && MC.Cond->getParent() != BB))
      return AngleSelectDisp::NotApplicable;
    if ((!MC.Net && !MC.Cond->comesBefore(MC.S)) || !MC.S->comesBefore(T))
      return AngleSelectDisp::NotApplicable;
    const Instruction *Start = MC.Net ? MC.S : MC.Cond;
    if (!WindowStart || Start->comesBefore(WindowStart))
      WindowStart = Start;
  }
  for (const Instruction *I = WindowStart->getNextNode();
       I && I != T; I = I->getNextNode()) {
    const auto *CI = dyn_cast<CallInst>(I);
    if (!CI)
      continue;
    const Function *F = CI->getCalledFunction();
    if (F && F->getName().starts_with("cq_theta_") && CI->arg_size() >= 1 &&
        Taint.Tainted.count(CI->getArgOperand(0)))
      return AngleSelectDisp::NotApplicable;
  }

  // The suffixed Rz stem (`IsPhi`: the retired `cq_phi_<sfx>` register form,
  // which declines at `resolveSources`) stopped here (PRD §12.1 transparency).
  // S8 and S9 below exist because an in-place `Ry` RELABELS the register's
  // basis; a controlled `Rz` is DIAGONAL, so it moved no basis label (which is
  // why `q = cq_phi(q, q==5?A:B)` accepted and its `cq_theta` twin declines —
  // the stem separator). Its unconditional `rz(h, B)` was bd `wt3l`'s
  // cancel/leak/keep question.
  //
  // THE REGISTER-FREE PHASE STEM STOPS HERE TOO (3qlq Inc 1, PRD §6.2 row P2),
  // and for a STRICTLY STRONGER reason than the suffixed Rz stem's: that stem's
  // exemption was that a controlled `Rz` is DIAGONAL and so moves no basis label;
  // this one emits nothing on the register AT ALL. S8's disjoint-wire question
  // and S9's stale-record question are both about a gate on the rotated
  // register, and there is no such gate — the two `cqrt_rz_i1`s land on the flag
  // ancilla, which is minted after the compare and freed before anything else
  // reads the register.
  if (IsPhi || IsPhase) {
    ControlRegion R;
    R.Kind = ControlRegion::AngleSelectRegion;
    R.Merge = Sel;
    R.Condition = Cond;
    R.Shadow.assign(1, T);
    plan.Regions.push_back(R);
    return AngleSelectDisp::Accepted;
  }

  // S8 — DISJOINT PHYSICAL WIRES (R4), Ry stem only. Identical in substance to
  // `classifyArms`' clause: the condition side is `condProvenance`'s cone closed
  // BACKWARD through `railWireClosure` (the `Cond` seed itself contributes only
  // the compare — a `CmpInst` is not a `BinaryOperator`, so that walk stops
  // dead), and the base side is the base's FULL member set. Narrowing
  // `condProvenance` is a Rule-13 change to this clause exactly as it is to R4's.
  //
  // `BaseWire` / `BaseWireOrder` are the closure S7 already computed — the SAME
  // seed, direction and `Exclude = T` this clause used to compute for itself
  // (round-1 Rule-13 review: it moved UP so the Rz stem reaches it too, not
  // sideways). `Exclude = T`: `T` is a chained-theta user of the base, so
  // `forwardRailHop` admits it — but `T`'s RESULT is the POST-GATE name of the
  // register (the emitter rewires `T`'s operands and leaves the call standing),
  // so every consumer of it already reads the relabelled register. Crossing it
  // would make each of those a member's user and collapse the entire accept
  // class. This is the same argument the Inc-1 caller makes for its merge φ,
  // which is why the parameter names the CONTRACT rather than one caller's
  // spelling of it.
  SmallPtrSet<Value *, 16> Prov;
  SmallPtrSet<Value *, 16> CondRails;
  // (bd dm7f.54 E: the union over every mux member's condition.)
  for (const MuxCond &MC : MuxConds) {
    condProvenance(MC.Cond, Taint, Prov);
    railWireClosure(MC.Cond, Taint, WireDir::BackwardOnly, nullptr, nullptr,
                    CondRails);
  }
  for (Value *P : Prov)
    railWireClosure(P, Taint, WireDir::BackwardOnly, nullptr, nullptr,
                    CondRails);
  for (Value *W : BaseWireOrder)
    if (CondRails.count(W)) {
      diagnoseUnderControl(Sel, "rotation arm on a condition wire");
      return AngleSelectDisp::Declined;
    }

  // bd dm7f.54 (item A1) — S3's literal half: no value may be PROVEN EQUAL to
  // the seed at the consumer (`angleSelectLiteralSeedPinned`; the non-merge
  // substitution route). F2's string, because it is F2's question, asked with
  // F2's exclusions over the SAME condition wire F2 uses (`CondRails` here is
  // F2's `CondWire`, spelled identically: the conditions' backward rail
  // closure over their `condProvenance`; round-2 review F2). Asked after S8
  // for that reason.
  if (LiteralSeed)
    if (Value *Pin = angleSelectLiteralSeedPinned(T, Taint, *DT, CondRails)) {
      (void)Pin;
      diagnoseUnderControl(Sel, "state prep seed is proven equal to the "
                                "condition register");
      return AngleSelectDisp::Declined;
    }

  // S9 — NO POST-GATE READ OF THE PRE-Ry RECORD (R6), Ry stem only, with the
  // consumer `T` in the barrier role `classifyArms` gives its region branch.
  // Every user of every member of the base's rail closure must be provably
  // before `T` — a member's user is an ALIAS HOP and owes only "cannot fire
  // after the gate" (`cannotFollowGate`), every other user owes the full
  // `provablyBefore`. TWO SETS, TWO QUESTIONS: the skip set is `BaseWire` and
  // the member set is `BaseWireOrder`, exactly as at the Inc-1 site.
  //
  // The barrier is sound at `T` because the emitter inserts its whole stream
  // IMMEDIATELY BEFORE `T` (the mint, the true-arm gate, the opening `x(f)`),
  // so nothing lands between a user proven before `T` and the first relabelling
  // gate.
  //
  // ⚠ AND IT IS THE FLAT SPELLING ON PURPOSE, EVEN THOUGH A WEAKER ONE EXISTS
  // (bd drbq Inc 3, round-1 lens L1 Q2). `ArmClassify`'s in-loop R6 site now has
  // a PER-ACTIVATION certificate that is analytically implied by both predicates
  // used here, so it accepts strictly more — see the committed pair
  // `control_inplace_ry_reject_flat_cond_pre_measure.ll` (declines) /
  // `control_inplace_ry_inloop_cond_pre_measure.ll` (accepts). This site keeps
  // `provablyBefore` / `cannotFollowGate` because an angle select is ACYCLIC by
  // S7 and because adopting the certificate here would WIDEN the 2b accept class,
  // which owes its own adversarial round (Rule 13). Do not "unify" the two
  // spellings as a cleanup: the asymmetry is the decision.
  for (Value *M : BaseWireOrder)
    for (User *U : M->users()) {
      if (U == T || U == Sel)
        continue;  // the gate itself, and the angle select the emitter erases.
      auto *UI = dyn_cast<Instruction>(U);
      if (!UI) {
        diagnoseUnderControl(Sel, "stale rail record read past a controlled Ry");
        return AngleSelectDisp::Declined;  // a constant expression: no position.
      }
      if (!DT->isReachableFromEntry(UI->getParent()))
        continue;  // never executes, so never reads.
      // bd 3paw: a reader `T` dominates on a collapse-claimed rail reads the
      // post-gate register (the `CollapsedRail` note at S7's rail prong).
      const bool Ok = collapsedPostGateName(UI) ||
                      (BaseWire.count(UI) ? cannotFollowGate(UI, T, *DT)
                                          : provablyBefore(UI, T, *DT));
      if (!Ok) {
        diagnoseUnderControl(UI, "stale rail record read past a controlled Ry");
        return AngleSelectDisp::Declined;
      }
    }

  // S11 (bd dm7f.54) — `NetCond` ONLY: THE RAIL LADDER RE-ASKED AT THE MINT
  // POINT. `classifySelectRegion` asked rung (ii) (not measured before) and
  // rung (iii) (the wire's DT prong) with the SELECT as read point, which is
  // exact for the 4.4 data select, whose stream lands before `Sel`. This
  // stream's first read of a rail is the network's `cqrt_cnot`/node gate,
  // emitted immediately before `T`, so both rungs are re-asked with `T` — the
  // SAME helpers, the SAME seed sets (the leaf union's `condProvenance`), only
  // the read point moves. A COMPARE leaf's rung (ii) moves with it
  // (`condCmpMeasuredBeforeReadPoint`); its rung (iii) is gate 2c's
  // position-free prong, which has no read point to move.
  // (bd dm7f.54 E: asked of EVERY `NetCond` mux member, each with its own
  // tree and covered set; all of them read at `T`.)
  for (const MuxCond &MC : MuxConds) {
    if (!MC.Net)
      continue;
    const CondTree &Tree = MC.Tree;
    SmallPtrSet<Value *, 16> RailProv;
    for (CallInst *Rail : Tree.RailLeaves)
      condProvenance(Rail, Taint, RailProv);
    for (PHINode *P : Tree.RailPhiLeaves)
      condProvenance(P, Taint, RailProv);
    for (Value *Name : RailProv)
      if (railMeasuredBeforeReadPoint(Name, T, Taint, DT)) {
        diagnoseUnderControl(Sel, "condition measured before the control route");
        return AngleSelectDisp::Declined;
      }
    if (condCmpMeasuredBeforeReadPoint(Tree.Leaves, T, Taint, DT)) {
      diagnoseUnderControl(Sel, "condition measured before the control route");
      return AngleSelectDisp::Declined;
    }
    if (!RailProv.empty()) {
      SmallVector<Value *, 16> RailSeeds(RailProv.begin(), RailProv.end());
      // The same covered producer set gate 2c used (dm7f.53's one spelling).
      SmallPtrSet<const CallInst *, 4> CoveredPhiGates;
      condTreeCoveredPhiGates(Tree, plan, Taint, CoveredPhiGates);
      const SmallPtrSetImpl<const CallInst *> *Cov =
          CoveredPhiGates.empty() ? nullptr : &CoveredPhiGates;
      if (findNonDiagonalWireGate(RailSeeds, /*CrossValueRouting=*/true,
                                  /*EmitPoint=*/nullptr, /*DT=*/nullptr,
                                  &Taint, Cov) &&
          findNonDiagonalWireGate(RailSeeds, /*CrossValueRouting=*/true,
                                  /*EmitPoint=*/T, DT, &Taint, Cov)) {
        diagnoseUnderControl(Sel, "condition predates a non-diagonal gate");
        return AngleSelectDisp::Declined;
      }
    }
  }

  ControlRegion R;
  R.Kind = ControlRegion::AngleSelectRegion;
  R.Merge = Sel;
  R.Condition = Cond;
  R.Shadow.assign(1, T);
  // bd `test_C_libtooling-z0re` — the classifier's runtime-base verdict, carried
  // to `emitAngleSelectRegion` for the L1 record (see
  // `ControlRegion::RuntimeSeedAdmitted`). The Ry stem is the only one that can
  // reach here with an untainted base (S3). bd dm7f.54: a LITERAL seed is not a
  // runtime one (no L1 record; the emitter re-asks
  // `angleSelectLiteralSeedAdmissible` instead).
  R.RuntimeSeedAdmitted = UntaintedBase && !LiteralSeed;
  // bd dm7f.54 — a `NetCond` region carries the two records a `SelectRegion`
  // carries for the same tree: the rail ladder was asked (gate 2 + S11), and
  // one precedence edge per claimed φ leaf so that the prep whose M-β turns the
  // φ into its hoisted `cq_theta_i1` is emitted FIRST (the emitter re-reads its
  // tree off the live select, exactly as `SelectMergeEmit` does). The index is
  // the ONE owner's answer (`preppedRailPhiRegionIdx`), never re-derived.
  // (bd dm7f.54 E: over every mux member.)
  for (const MuxCond &MC : MuxConds) {
    if (!MC.Net)
      continue;
    if (!MC.Tree.RailLeaves.empty() || !MC.Tree.RailPhiLeaves.empty())
      R.RailLadderProven = true;
    for (PHINode *P : MC.Tree.RailPhiLeaves) {
      const unsigned Idx = preppedRailPhiRegionIdx(P, plan);
      if (Idx == ControlRegion::kNoParent)
        return AngleSelectDisp::NotApplicable;  // gate 2 refused it already.
      if (!llvm::is_contained(R.PrepRegionIdxs, Idx))
        R.PrepRegionIdxs.push_back(Idx);
    }
  }
  plan.Regions.push_back(R);
  return AngleSelectDisp::Accepted;
}

}  // namespace cq
