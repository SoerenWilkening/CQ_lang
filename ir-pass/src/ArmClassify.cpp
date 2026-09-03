// ArmClassify.cpp — Per-arm lineage classification + §3c provenance walk.
// See ArmClassify.h for the contract; swap-route 4.1 IMPLEMENTATION §3 (phase
// arms) + 4.2 IMPLEMENTATION-4.2 §3 / PRD Part II §8.3 (value arms).
//
// All analysis is by SSA-value identity, before any mutation (Rule 9). The
// classifier walks each arm's contribution to the merge `φ` back along its
// PHASE spine (the chain of `cq_phi`/Rz handle edges); what the spine bottoms
// at decides the arm's class:
//   * a leaf handle (a value defined OUTSIDE the arm — including a PRE-REGION
//     `cq_phi`, the live DERIVED base — or a `cq_theta` source) equal to the
//     routed slot → pure PHASE arm — accept iff tainted (criterion 3);
//   * no spine at all → try the arm-block-bounded VALUE chain walk
//     (`walkValueChain`): a pure linear chain of supported tainted integer
//     `BinaryOperator`s bottoming at exactly the routed slot is the 4.2
//     value-arm class — §3c PERMANENT reject if the routed register is in the
//     condition's transitive taint provenance (ACTIVE since WI-3), accept
//     class otherwise: a value DIAMOND (WI-4) and a two-arm value IF/ELSE over
//     ONE shared routed base (WI-5) both lower via the method-B §4 emitter;
//     everything off-pattern declines with its precise string (mux/FP →
//     `control flow`; mixed content → `mixed phase/value arm`; fan-out/stray
//     → `impure value arm`; Q+Q link → `value-arm swap-route`).

#include "ArmClassify.h"

#include "ArmAnalysis.h"
#include "CompareLowering.h"   // compareFlagMintable (2b angle-select S4)
#include "ControlPlan.h"
#include "ControlShape.h"     // blockOnCycle (2b angle-select S7 cycle prong)
#include "EqFoldArm.h"
#include "LiteralIntegrity.h"  // valueCarriesUndef (2b angle-select S1 arm fence)
#include "OpcodeSupport.h"
#include "PredMuxFlatten.h"
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
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"

#include <algorithm>

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

bool isPhiCall(const Value *V) { return isCallToPrefix(V, "cq_phi_"); }
bool isThetaCall(const Value *V) { return isCallToPrefix(V, "cq_theta_"); }

}  // namespace

// The per-arm analyses below are de-anonymized into the named `cq` namespace
// (declared in ArmAnalysis.h, WI-0/MD1) so the 4.3 RegionTreeDetect /
// ArmHomogeneity TUs can reuse them. PURE REFACTOR — definitions and behavior
// unchanged; the tiny `isPhiCall`/`isThetaCall`/`isCallToPrefix` predicates above
// stay TU-local (they collide with same-named anon helpers in other TUs). The
// remaining internal-only helpers keep their own (reopened) anonymous blocks.

// Walk the PHASE spine WITHIN one arm block: while `V` is a `cq_phi` (Rz) call
// DEFINED IN `ArmBB`, follow its arg-0 handle operand (arg 1 is the classical
// angle). Returns the first value the chain bottoms at — the arm's base handle, a
// value-changing op, OR a `cq_phi` defined OUTSIDE `ArmBB` (a pre-region rotation,
// i.e. the live DERIVED base handle the arm extends).
//
// Bounding at the arm-block boundary is LOAD-BEARING (not a tidy-up): an
// UNBOUNDED walk hops past a pre-region `cq_phi` all the way to the `cq_theta`
// source, so a derived routed handle (`%qd = cq_phi(%q,·)` before the branch,
// shared by both arm spines) is misread as the theta `%q`. For a diamond that was
// caught downstream (`Base != StraightThrough` → decline); for an if/else, which
// has NO straight-through to compare against, both arms appeared to bottom at the
// same theta and the region was ACCEPTED, then the emitter collected the shared
// pre-region phi ONCE PER ARM → double-erase SIGSEGV (verify-clean over-accept;
// §8 adversarial review 2026-06-09, reproduced as exit 139). A `cq_phi` surfaced
// as a base here is the live DERIVED base handle — the caller routes it like any
// other tainted leaf (test_C_libtooling-9hh, 2026-06-10; criterion 3 permits a
// derived tainted base).
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
// non-terminator instruction in `ArmBB` is a `cq_phi` on the spine of
// `ArmIncoming`. One check that rejects two distinct silent-miscompile/crash
// paths the swap-route emitter cannot handle (both confirmed by the WI-2 §8
// adversarial review, 2026-06-09):
//   * FAN-OUT — a spine `cq_phi` reused by a sibling `cq_phi` (Rule 8 linearity).
//     The emitter replays + erases ONLY the merge-feeding spine, so the off-spine
//     sibling dangles in `taint.PhiCalls` → use-after-free when `lowerRotations`
//     re-reads its freed operand (reproduced as a broken module).
//   * STRAY op in the arm — a `cq_measure` / `cq_theta` / arithmetic the emitter
//     neither replays nor scrubs. `RegionFlatten` erases the arm BLOCK, so the
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
// `cq_theta` source, a `cq_phi` (Rz) result, a function argument, or a constant;
// ANY other instruction (add/mul/cast/select/non-rotation call/…) defining a new
// value from a quantum operand is value-changing.
//
// `cq_phi` is a leaf BY OPCODE: Rz = diag(1, e^{iθ}) is DIAGONAL, so it preserves
// the computational-basis value no matter which block clang placed it in — the
// block-position trap above cannot arise for it (and `-O1` never hoists an
// opaque external `cq_*` call anyway). The arm-bounded spine walk consumed every
// IN-arm `cq_phi` before this is consulted, so one reaching here is a PRE-REGION
// rotation: the live DERIVED base handle the arm extends
// (test_C_libtooling-9hh; §0 criterion 3 permits a derived tainted base).
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
// TaintPropagation.cpp VERBATIM — the angle operand of a `cq_phi` is classical
// and must never be collected as a condition operand (the f64/angle miscompile
// family). Only tainted values are recorded; classical scaffolding (constants,
// the classical seed of a theta) is traversed-through but never collected.
//
// ⚠ THIS CONE IS ALSO R4's COMPLETENESS CARRIER, which its original callers did
// not need it to be (round-1 Rule-13 review of bd test_C_libtooling-drbq, lens
// L1 §2). `classifyArms`' R4 clause seeds `CondRails` with
// `railWireClosure(Region.Condition, BackwardOnly, …)` — which stops dead,
// because a `CmpInst` is not a `BinaryOperator` and that walk has no `CmpInst`
// arm — and then closes over EVERY member of this set. So "the rotated wire is
// not a condition wire" is proved from THIS function's reach, not from the
// compare's. NARROWING IT (stopping at a template producer, collecting only
// direct operands, dropping a hop) IS A RULE-13 CHANGE TO R4, and R4 is the
// fence whose failure is a flag stripped against a relabelled register — a
// `cqrt_free` of an entangled ancilla (Rules 6/8).
void condProvenance(Value *Cond, TaintSet &Taint,
                    SmallPtrSetImpl<Value *> &Out) {
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
    if (!I)
      continue;
    if (isThetaCall(I))
      continue;  // source: collected V already; do NOT enter the classical seed.
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
// pre-region `cq_phi` arg-0 chain from `Routed`: rotation lowering RAUWs a
// `%qd = cq_phi(%q, ·)` and its `%q` to the SAME i32 handle, so SSA-value
// disjointness from the condition's provenance is NOT wire disjointness — a
// value arm routed over `%qd` while the condition reads `%q` transforms the
// very physical wire the `icmp_inv` flag-strip reads (§8 review 2026-06-10:
// the §8.2 "no reliance on the reverse-play" rationale is false for that
// shape; mid-stream the wire holds the muxed value and only the §4
// strip-after-R† order would save it). Enforcing provenance disjointness
// through this closure keeps the accept class inside the documented
// rationale. Pure reading walk — no collection, so the arm-block bounding
// discipline (which guards COLLECTION) does not apply; the chain terminates
// at the first non-`cq_phi` (a theta source, template-derived value, or
// argument — all genuinely fresh wires post-lowering).
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
// both measured wrong-VALUE silent miscompiles). That is the bd 8h7d.5 F-1/F-3
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
//   * `cq_phi(x, θ)` — Rz is diagonal and ALWAYS lowers in place on `x`'s
//     handle. This is `diagonalAliasHit`'s hop, generalized.
//   * `cq_theta(x, θ)` with `x` TAINTED — a CHAINED Ry lowers in place on `x`'s
//     handle too (`RotationLowering`'s `Chained` branch mints no alloc). A
//     SOURCE theta (classical arg-0) mints a fresh rail, so the walk stops
//     there — that is what makes `int q = cq_theta(0,·); int r = cq_theta(0,·)`
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
//     so. Measured cost: `int r = 5 - p; if (q==5) r = cq_theta(r,.9); …
//     cq_measure(p);` declines R6, while its `cq_phi` twin accepts and emits
//     `cq_template_sub_i32_lh(5, h1)` on a fresh rail where `p` was never
//     touched. Over-declining is safe (Prime Directive), so this is recorded and
//     not fixed — but PRD §11.5 obligation 2 makes NARROWING this hop a Rule-13
//     change, and whoever performs it must not reason from the M-C-fence premise
//     for the `sub` half: it does not apply.
//
// Everything else STOPS: a `cq_template_*` producer (mul, cast, compare, the
// out-of-place arith) mints a FRESH rail, so it is its own root. That is not a
// shortcut — a value entangled with the condition but living on its own rail is
// genuinely a different wire, and rotating it leaves the condition's BASIS
// untouched, which is all the `icmp_inv` flag strip needs (PRD §3).
//
// FORWARD hops (`WireDir::BothWays` only) are the exact MIRROR of the backward
// list — a user whose RESULT keeps the member's own handle: `cq_phi(M,·)`, a
// CHAINED `cq_theta(M,·)`, an `add`/`sub`/`xor` whose sole tainted operand is
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
//     CLASSICAL join φ (`int m; if (c) m = cq_phi(r,.1); else m = r;`) was a
//     plain user that passed `provablyBefore` honestly, so its OWN users were
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
// refuses `if (q==5) r = cq_theta(r,·)` when `r = q + 1`, even though M-C would
// in fact lower that out of place. Over-declining is always safe (Prime
// Directive) and the shape is outside the Inc-1 accept class either way.
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
  // omission: `int m; if (c) m = cq_phi(r,.1); else m = r;` — a purely CLASSICAL
  // diamond — made the join φ a plain *user* of a member. It passes
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
    // is the `..._stale_diag_alias_backward.ll` shape).
    //
    // The taint gate is not decoration. Every hop above pushes only tainted
    // values EXCEPT the backward `cq_phi` one, which pushes arg-0
    // unconditionally — so a degenerate `cq_phi(0, θ)` (deleted at lowering,
    // Rule 3) can put a CONSTANT in the set, and forward-walking a constant
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
// dead `z = cq_theta(r_pre, ·)` written after the region), and every hop's own
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
//   * arg-0 TAINTED — a CHAINED Ry on a live register. A CLASSICAL arg-0 is
//     controlled STATE PREP (PRD S5): it needs an alloc hoisted with it and a
//     seed-identity fence on the merge phi's pred incoming, which is Inc 4;
//   * SOLE USER is the merge phi (no fan-out — Rule 8 linearity: the emitter
//     RAUWs the phi to the base, and a second consumer of the theta result
//     would be left reading a value that no longer exists);
//   * NOTHING ELSE in the arm block. `RegionFlatten` ERASES the arm block, so a
//     stray op is silently DROPPED from the IR and its taint work-list pointer
//     dangles — `armBlockIsPureSpine`'s two reasons, verbatim, which is why the
//     shape is tested the same way rather than by a second spelling.
CallInst *inPlaceRotationArmTheta(Value *ArmIncoming, const BasicBlock *ArmBB,
                                  const PHINode *MergePhi, TaintSet &Taint) {
  auto *T = dyn_cast<CallInst>(ArmIncoming);
  if (!T || !isThetaCall(T) || T->getParent() != ArmBB || T->arg_size() < 2)
    return nullptr;
  if (!Taint.Tainted.count(T->getArgOperand(0)))
    return nullptr;  // classical seed — controlled state prep, Inc 4.
  if (!T->hasOneUse() || T->user_back() != MergePhi)
    return nullptr;  // fan-out, or it does not feed the merge.
  for (const Instruction &I : *ArmBB)
    if (!I.isTerminator() && &I != T)
      return nullptr;  // a stray op the flatten would drop.
  return T;
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
// arms' chains (the double-erase/UAF family once the emitter replays+erases).
//
// A Q+Q link (both operands tainted) sets `HasQQ` and threads the operand
// IDENTICAL to `RoutedHint` when exactly one matches (so `if(q>5){q=q+p}`
// bottoms at the routed `%q` and stays eligible for the §3c PERMANENT reject
// rather than the QQ defer — the PRD §8.3 disposition order runs the
// provenance check first), falling back to operand 0 (every QQ chain declines
// either way; the fallback only picks WHICH safe string fires).
//
// FP chains are walked like integer ones (fadd/fmul/… are supported stems) —
// the CALLER declines any FP-typed merge as an angle (`control flow`) before
// reading the base; never key the decision on abiWidthFromType() validity
// (f64 has a valid width yet is an angle — the f64 miscompile family).
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
//     the WI-4 emitter replays + erases ONLY the chain, and `RegionFlatten`
//     erases the arm BLOCK — a stray op is silently DROPPED (a vanishing user
//     measurement, Rule 5) and its taint work-list pointer dangles (UAF).
//   * FAN-OUT of a chain link: whole-chain reversal needs LINEAR lineage —
//     reverse-playing a shared link double-uncomputes the shared prefix
//     (use-after-free + double-free, Rule 8). Each link's ONLY user must be
//     the next link; the merge-feeding link's only user the merge `φ` itself.
// The base handle the chain bottoms at is NOT in `ArmBB` (it is the live
// routed register in the pred), so it is correctly never inspected here.
bool valueArmIsPureChain(const BasicBlock *ArmBB,
                         ArrayRef<Instruction *> ChainOps,
                         const PHINode *MergePhi) {
  SmallPtrSet<const Instruction *, 8> OnChain(ChainOps.begin(),
                                              ChainOps.end());
  for (const Instruction &I : *ArmBB) {
    if (I.isTerminator())
      continue;
    if (!OnChain.count(&I))
      return false;  // a stray op / DAG sibling beside the chain.
  }
  for (size_t Idx = 0; Idx < ChainOps.size(); ++Idx) {
    const Instruction *I = ChainOps[Idx];
    const User *Expected = (Idx + 1 < ChainOps.size())
                               ? cast<User>(ChainOps[Idx + 1])
                               : cast<const User>(MergePhi);
    if (!I->hasOneUse() || *I->user_begin() != Expected)
      return false;  // fan-out, or a link consumed out of chain order.
  }
  return true;
}

// An instruction to anchor a generic decline diagnostic on (for the !dbg /
// source location). Prefer the tainted condition; fall back to the merge phi.
Instruction *declAnchor(const ControlRegion &R) {
  if (auto *I = dyn_cast_or_null<Instruction>(R.Condition))
    return I;
  return R.Merge;
}

}  // namespace

// The first rotation whose arg-1 ANGLE operand is TAINTED — i.e. quantum-derived
// data in the angle slot — among the arm's IN-BLOCK spine gates and (for a
// derived base) the pre-region base `cq_phi` itself. Null if every angle is
// classical. The emitter replays each spine gate's angle operand VERBATIM onto
// the rail (`cqrt_rz(rail, angle)`), and nothing downstream lowers a tainted
// non-template angle producer — after rotation lowering's RAUW it reads the i32
// RUNTIME HANDLE, a fixed per-run tag, while the source semantics
// (angle = f(quantum value), value in superposition) admit NO fixed unitary.
// That is a verify-clean silent miscompile (found by the test_C_libtooling-9hh
// §8 adversarial review, 2026-06-10 — probe: `%ang = call double @ext(i32 %qd)`
// in the pred, arm gate `cq_phi(%qd, %ang)`; the lowered trace prints
// `cqrt_rz(rail, ext(handle_id))`). The only sound disposition is a loud
// decline — the angle-classicality precondition is the criterion-3 parallel for
// arg-1 (Rule 3: the angle operand is classical, per-operand-use).
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
// follow in-place gate user edges — a `cq_phi` user taking the value as its
// arg-0 handle is DIAGONAL (basis preserved; keep walking its result, the
// same physical wire), a `cq_theta` user is an in-place Ry AFTER the compared
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
CallInst *wireGainsNonDiagonalGate(const SmallPtrSetImpl<Value *> &Prov,
                                   const Instruction *EmitPoint,
                                   const DominatorTree *DT) {
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
  return findNonDiagonalWireGate(Seeds, /*CrossValueRouting=*/true, EmitPoint,
                                 DT);
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
// a = cq_theta(a, 0.5); a += off;` — state prep is Ry THEN +off, and no source
// spelling of S itself got past the walk).
//
// THE EMISSION CONTRACT IS THE PREDICATE. `SwapRouteEmit::emitRegion` builds
// with `IRBuilder<> B(BI)` where `BI == R.Pred->getTerminator()`: the flag
// mint, the work-rail allocs, the route-in `cqrt_cswap`s, the verbatim arm
// `cqrt_rz`s, the route-back, the rail frees, the `_unc` flag strip and the
// flag free ALL land before `BI`, in `R.Pred`. So a theta `T` runs after the
// entire stream — mint, use, strip and free — exactly when
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
//      positional compare→branch scan — are UNCHANGED and still decline
//      immediately (the positional scan fires even for a theta on ANOTHER
//      wire, which no wire walk can see).
CondWireDisp condWireDisposition(const ControlRegion &R, TaintSet &Taint,
                                 const SmallPtrSetImpl<Value *> &Prov,
                                 const DominatorTree *DT) {
  auto *Cond = dyn_cast_or_null<Instruction>(R.Condition);
  if (!Cond || !R.Pred)
    return CondWireDisp::DeclineNow;  // cannot reason about the gap (Prime Directive).
  if (Cond->getParent() != R.Pred)
    return CondWireDisp::DeclineNow;  // unbounded gap across blocks.
  const Instruction *BI = R.Pred->getTerminator();
  // The POSITIONAL scan (P5) is unconditional and runs first: a tainted-operand
  // theta between the compare and the branch is a decline even on another wire,
  // and no position-aware proof can reach it (it is not dominated by `BI`
  // anyway, but the scan also covers wires the walk never sees).
  for (const Instruction *I = Cond->getNextNode(); I && I != BI;
       I = I->getNextNode()) {
    const auto *CI = dyn_cast<CallInst>(I);
    if (!CI)
      continue;
    const Function *F = CI->getCalledFunction();
    if (F && F->getName().starts_with("cq_theta_") && CI->arg_size() >= 1 &&
        Taint.Tainted.count(CI->getArgOperand(0)))
      return CondWireDisp::DeclineNow;  // chained Ry on a live handle after the compare.
  }
  // Position-FREE first: no gate at all is the ordinary accept path, and it
  // must not pay for a dominator query.
  if (!wireGainsNonDiagonalGate(Prov, /*EmitPoint=*/nullptr, /*DT=*/nullptr))
    return CondWireDisp::None;
  if (R.ShareCondFlag)
    return CondWireDisp::DeclineNow;  // P2 — the flag outlives the region.
  if (!DT)
    return CondWireDisp::DeclineNow;  // no tree, no proof (Prime Directive).
  if (wireGainsNonDiagonalGate(Prov, BI, DT))
    return CondWireDisp::DeclineNow;  // some gate is NOT provably post-stream.
  return CondWireDisp::ProvenPostRegion;
}

}  // namespace

// ziov WI-1: disposition of the condition compare's NON-branch (data) uses. The
// condition `q>5` IS the control flag; when it is ALSO read as data (`int f =
// (q>5)`), the route and the data use must share ONE physical flag (minted once,
// fed to both) — NOT a second mint. Sharing is sound iff the flag's eager
// strip+free can be SKIPPED, which holds exactly when the data lineage is owned
// downstream — it ESCAPES (`ret`) or is MEASURED — AND the flag is still COHERENT
// when the route uses it as control.
//
// `RouteBlock` is the block the route stream is emitted into (`Region.Pred`, just
// before the branch). TWO hazards close the accept set (BOTH verify-clean silent
// miscompiles caught by the WI-1 Rule-13 adversarial review, 2026-06-15):
//   * MeasuredEarly — a measurement of the flag's lineage IN `RouteBlock` runs
//     BEFORE the route (every pre-existing `RouteBlock` instruction precedes the
//     route, which is inserted at the branch). The cswap route would then be
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
  // THE TRUE CALL-SITE LIST of this predicate, measured — an earlier comment
  // named five and there are EIGHT, in eight distinct functions:
  //   ArmClassify.cpp        condDataUseDisposition · classifyArms ·
  //                          classifyClassicalCallArm
  //   SelectClassify.cpp     classifySelectRegion
  //   SpecializeReject.cpp   isLiftableFpSelect
  //   GuardedStoreArmEmit.cpp classifyGuardedStoreArm
  //   RegionTreeDetect.cpp   recoverRegionTree
  //   AbortParkEmit.cpp      classifyAbortPark
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
    // diagnose it — but only AFTER `emitRegion` routed + `flattenRegion` erased
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
    // routed+flattened. Gate the predicate here (the same `compareInScope`
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
// propagating the straight-through edge to a constant"). For the idiomatic
// conditional phase `if (q != 0) q = cq_phi(q, θ)` the else edge folds to `0`, so
// the merge is `phi [phase(q), 0]` and the classifier's `Base == Routed` gate
// fails (`Routed` is the folded `0`, `Base` is the qubit) — a verify-clean OVER-
// DECLINE of a clean phase arm.
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

ArmDisposition classifyArms(ControlRegion &Region, TaintSet &Taint,
                            const DominatorTree *DT) {
  auto *MergePhi = dyn_cast_or_null<PHINode>(Region.Merge);
  if (!MergePhi) {
    diagnoseUnderControl(declAnchor(Region), "control flow");
    return ArmDisposition::Declined;
  }

  // The flag is minted from a SINGLE comparison (icmp/fcmp → `_hl` template). A
  // compound condition (clang's `select i1` for `&&`/`||`) or any non-compare i1
  // is not a 4.1-lowerable region — decline (closes the compound-cond
  // over-accept; WI-1 adversarial review 2026-06-09).
  if (!isa<CmpInst>(Region.Condition)) {
    diagnoseUnderControl(declAnchor(Region), "control flow");
    return ArmDisposition::Declined;
  }

  // The flag is minted FROM this compare's predicate; an out-of-scope fcmp
  // predicate (after 8rvn, only the degenerate `true`/`false` — see
  // `compareInScope`) has no template, so the mint would emit a non-existent
  // symbol. SwapRouteEmit's flag-null bail catches it
  // loudly, but only the FLAT mint is its emit step 1 — decline in DETECTION so
  // the posture is uniform with the nested path (whose inner mint follows the
  // outer route) and the reason is precise (test_C_libtooling-jvun).
  if (!comparePredLowerable(cast<CmpInst>(Region.Condition))) {
    diagnoseUnderControl(declAnchor(Region), "control condition has no template");
    return ArmDisposition::Declined;
  }

  // The condition compare may feed a DATA position in addition to the branch
  // (e.g. `c = icmp …; zext c; br c` — clang CSE of a reused `q>5` bound to a
  // variable `f`). The compare IS the control flag, so the route and the data use
  // must share ONE physical flag (ziov, owner 2026-06-15): `SwapRouteEmit::
  // emitRegion` mints it once, routes with it, feeds the SAME handle to the data
  // use, and SKIPS the eager flag strip+free — sound iff the data lineage is owned
  // downstream AND the flag is coherent at the route (`condDataUseDisposition`,
  // keyed on `Region.Pred` = the route block). A dead-within-function lineage
  // orphans the flag as a dirty entangled rail (declined permanently — ziov.2's
  // deferred-strip accept was closed won't-fix as a silent miscompile), and a
  // measure of the flag IN the route block collapses it BEFORE the route controls
  // on it — both decline LOUDLY (over-declining is always safe). This SUPERSEDES
  // the flat 4.1 blanket decline ("condition used outside the branch"). Pure SSA
  // analysis (Rule 9).
  bool HasDataUse = false;
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
      // out-of-scope pair) — decline HERE, before `emitRegion` routes and
      // `flattenRegion` erases the diamond, instead of letting `lowerOps`
      // diagnose it post-mutation (Rule 9 detect-before-mutate; ziov.4).
      diagnoseUnderControl(declAnchor(Region),
                           "condition data use has no template");
      return ArmDisposition::Declined;
    }
  }

  // Backward tainted provenance of the condition — shared by the wire-walk
  // guard below (its seed set; direct-operand seeding misses a derived
  // condition's wire) and the §3c clobber check on value arms.
  SmallPtrSet<Value *, 16> Prov;
  condProvenance(Region.Condition, Taint, Prov);

  // The flag is minted at the BRANCH; a tainted-operand `cq_theta` (non-diagonal
  // Ry) between the compare and the branch makes that mint read a different
  // basis than the source compare — the wrong arm fires and the flag cannot be
  // stripped. Decline (see condWireDisposition, which owns the whole rationale
  // INCLUDING the Inc-4 position-aware accept and its five preconditions).
  const CondWireDisp WireDisp =
      condWireDisposition(Region, Taint, Prov, DT);
  if (WireDisp == CondWireDisp::DeclineNow) {
    diagnoseUnderControl(declAnchor(Region),
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

  // The diamond's straight-through (Pred-edge) incoming — the muxed variable's
  // prior value AND the handle a phase arm must route. Present only for a
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

  // The single handle EVERY phase arm must rotate (and that the emitter routes):
  // the diamond's straight-through incoming, or — for an if/else — the base the
  // first arm's phase spine bottoms at. An arm whose spine hits a value-changing
  // op, or bottoms at a DIFFERENT handle / a fresh `cq_theta` source, is not a
  // pure phase arm over the routed handle (closes the cross-handle / new-source
  // / hoisted-value-op mis-accepts; WI-1 adversarial review 2026-06-09).
  Value *Routed = StraightThrough;

  // 4.2 homogeneity bookkeeping (PRD Part II §0/§10): a region lowers
  // all-phase (the 4.1 path) or all-value over ONE shared routed base; a
  // phase arm beside a value arm has no single lowering method (the copy-out
  // dephases the phase answer, Rule 7) → `mixed phase/value arm`.
  bool SawPhaseArm = false;
  bool SawValueArm = false;
  // drbq Inc 1 — a control-in-place ROTATION arm was classified. Homogeneity is
  // enforced against the other two flags in the clause itself; this one exists
  // so the accept can be recorded and so the final P1 fence below reads it
  // (`!SawPhaseArm` covers it: the Inc-4 position-aware stale-condition accept
  // was cleared for PHASE arms only, and a rotation arm is not one).
  //
  // ⚠ IT MUST BE READ AT EVERY OTHER ACCEPT SITE, NOT JUST WRITTEN AT THIS ONE.
  // The rotation clause's own homogeneity test only fires when the rotation arm
  // is processed SECOND; a rotation arm FIRST followed by a phase/value/eq-fold
  // arm is the same mixture and has to decline on the same string. (Measured
  // during the Inc-1 build: with only the one-directional test, `if(c)
  // r=cq_theta(r,·) else r=cq_phi(r,·)` declined — but on R6's
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

    // Every angle on the arm spine (and a derived base's own angle) must be
    // CLASSICAL — quantum-derived data in the angle slot has no fixed unitary
    // and the emitter would replay it as a handle tag (see taintedAngleGate; the
    // §8 adversarial probe family for test_C_libtooling-9hh).
    if (CallInst *Bad = taintedAngleGate(ArmIncoming, ArmBB, Base, Taint)) {
      declineArm(Bad, "rotation angle");
      return ArmDisposition::Declined;
    }

    // A `cq_phi` surfaced as the in-block base is a PRE-REGION rotation: the arm
    // rotates a DERIVED handle (`%qd = cq_phi(%q,·)` before the branch). That is
    // a legitimate routed base (test_C_libtooling-9hh, 2026-06-10): %qd is
    // tainted with theta lineage (criterion 3), Rz is diagonal so the flag
    // minted from icmp(q) stays recoverable by icmp_inv(q), and rotation
    // lowering RAUWs %q and %qd to the SAME i32 handle — routing the live SSA
    // register is exactly what the emitter does for an un-derived base. It flows
    // through the leaf paths below (isValueChangingOp treats `cq_phi` as a
    // leaf); the WI-3 crash family stays foreclosed by the arm-block-bounded
    // walks here and in SwapRouteEmit (the shared pre-region phi is never
    // collected as an arm gate, so it cannot be double-erased — see
    // [[swap-route-ifelse-derived-base-boundary]]).

    // issue a8c0 — straight-through const-fold re-anchor. When `clang -O1` folded
    // the diamond's straight-through (Pred-edge) incoming to a `ConstantInt` that
    // the branch PROVES equals this arm's routed qubit on that edge (e.g.
    // `if (q != 0) q = cq_phi(q, θ)` folds the else edge to `0`), re-anchor both
    // `Routed` (so the `Base == Routed` gate below accepts) and `Region.RoutedBase`
    // (so `SwapRouteEmit::emitRegion` cswaps/RAUWs the qubit, NOT the folded
    // constant — the same emitter re-anchor `tryEqFoldArm` uses). Strictly
    // additive: fires ONLY on the proven folded-constant diamond phase arm; a
    // compound condition, a value arm (`Base != H`), or an unproven edge miss and
    // fall through to the existing decline (Prime Directive).
    if (Value *H = straightThroughConstFoldHandle(Region, Routed, Base, Taint)) {
      Routed = H;
      Region.setRoutedBase(H);
    }

    // Pure phase chain bottoming at the routed handle: accept this arm. The
    // routed handle MAY itself be a value DERIVED before the region (an earlier
    // `add`/cast, or the pre-region `cq_phi` above) — that is fine; only a value
    // op ON THE ARM SPINE (i.e. Base != Routed) is a value/permutation arm.
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
      SawPhaseArm = true;
      continue;
    }

    // 4.5 WI-5: equality-folded `br` diamond. `clang -O1` const-folds the
    // `q==k`-true arm's gate to `cq_phi(i32 k, θ)`, so `walkPhaseSpine` bottoms
    // at the literal `k` (≠ Routed) and this arm would otherwise decline
    // `control flow`. `tryEqFoldArm` re-recognizes it as a pure PHASE arm over
    // the icmp's tainted operand and re-anchors `Routed` (recording the handle
    // in `Region.RoutedBase` for `emitRegion`'s eq-fold IF/ELSE routing).
    // STRICTLY ADDITIVE: it fires AFTER the `Base == Routed` gate (so a real
    // cross-handle mux still falls through to decline) and BEFORE the leaf-base
    // path; a miss returns false and leaves `Routed`/`Region` untouched.
    if (tryEqFoldArm(Region, ArmBB, ArmIncoming, Base, Routed, Taint)) {
      // drbq Inc 1 — homogeneity, the THIRD direction (see `SawRotationArm`).
      if (SawRotationArm) {
        declineArm(declAnchor(Region), "mixed phase/value arm");
        return ArmDisposition::Declined;
      }
      SawPhaseArm = true;
      continue;
    }

    // ---- CONTROL-IN-PLACE ROTATION ARM (control-in-place-PRD §4 R1-R7, bd
    //      test_C_libtooling-drbq Inc 1) ------------------------------------
    //
    // A single tainted-operand `cq_theta` (Ry) is the whole arm. It is NEITHER a
    // phase arm NOR a value arm (Rule 7): the swap route cannot carry it at all,
    // because `Ry(θ)|0⟩ ≠ |0⟩` leaves the INACTIVE work rail dirty and entangled
    // with the flag (Rules 6/8, PRD §2), and method-B's copy-out would copy a
    // basis LABEL and dephase the superposition that IS the answer. So it lowers
    // CONTROL-IN-PLACE: the theta is hoisted to the pred and becomes
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
    if (CallInst *T =
            inPlaceRotationArmTheta(ArmIncoming, ArmBB, MergePhi, Taint)) {
      // Homogeneity (R3): a rotation arm beside a phase or value arm has no
      // single lowering method — the same region-level defect the phase/value
      // mixture has, and the same string.
      if (SawPhaseArm || SawValueArm) {
        declineArm(declAnchor(Region), "mixed phase/value arm");
        return ArmDisposition::Declined;
      }
      // R2 — the angle is CLASSICAL (Rule 3). `taintedAngleGate` above walks a
      // `cq_phi` SPINE and never inspects a theta at the arm incoming, so this
      // is the check for this class; same predicate, same string as the phase
      // path's.
      if (rotationAngleIsTainted(T, Taint)) {
        declineArm(T, "rotation angle");
        return ArmDisposition::Declined;
      }
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
      // R3 — ONE base. A diamond's straight-through incoming IS the base; an
      // if/else anchors it on the first arm and the second must match. A
      // mismatch is a cross-handle multiplexer, not a rotation arm.
      if (Routed && RotBase != Routed) {
        declineArm(declAnchor(Region), "control flow");
        return ArmDisposition::Declined;
      }
      // STRUCTURALLY UNREACHABLE, kept as defence in depth (round-1 review, lens
      // L6 §4 — recorded in place so nobody tries to write a fixture nobody can
      // write). `inPlaceRotationArmTheta` already required
      // `Taint.Tainted.count(T->getArgOperand(0))` as R1's "chained, not state
      // prep" half, and `RotBase` IS that operand. The same style as finding C's
      // note on the R1 fan-out clause: the alternative to a redundant check is a
      // silent fall-through to a controlled rotation on an untainted value.
      if (!Taint.Tainted.count(RotBase)) {
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
      // S8 accepts); an in-place Ry RELABELS it, and then neither the arm
      // selection nor the strip is a function of the source's condition.
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
      railWireClosure(Region.Condition, Taint, WireDir::BackwardOnly, nullptr,
                      nullptr, CondRails);
      for (Value *P : Prov)
        railWireClosure(P, Taint, WireDir::BackwardOnly, nullptr, nullptr,
                        CondRails);
      SmallPtrSet<Value *, 16> BaseWire;
      SmallVector<Value *, 16> BaseWireOrder;
      railWireClosure(RotBase, Taint, WireDir::BothWays, ArmA, ArmB, BaseWire,
                      &BaseWireOrder, /*Exclude=*/MergePhi);
      for (Value *B : BaseWireOrder)
        if (CondRails.count(B)) {
          declineArm(declAnchor(Region), "rotation arm on a condition wire");
          return ArmDisposition::Declined;
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
      // R7's LOOP half, asked HERE — immediately before R6 and nowhere earlier,
      // so every other clause's message ordering is byte-identical — because R6
      // is the ONE clause whose proof is not valid inside a loop. Both position
      // predicates below are flat: neither `provablyBefore` nor
      // `cannotFollowGate` has a per-activation reading, so a loop-carried
      // register's own header φ, reached as a wire member around the BACK EDGE,
      // reads as a stale record when it is simply the NEXT activation's value
      // (the bd 8h7d.5 `provablyBeforePerActivation` distinction, which this
      // epic's Inc 3 owns together with the loop accept). The class declines in
      // a loop regardless — `handleBranchRegion`'s in-loop scope fence part 3 is
      // kept as the backstop — so ask the loop question first rather than answer
      // R6's with the wrong barrier and emit a message that mislabels the region.
      // MEASURED: without this, `control_inplace_ry_reject_in_loop.ll` declines
      // on the stale-record string, correctly but for the wrong stated reason.
      if (Region.InLoop) {
        declineArm(declAnchor(Region), "control flow inside a loop body");
        return ArmDisposition::Declined;
      }
      // OVER THE RAIL, NOT THE CHAIN (finding J). The scan ranges over EVERY
      // member of `BaseWire`, not over `RotBase` alone: `int mark = cq_phi(r,·)`
      // before the region puts a second SSA name on the one physical rail, and
      // the shipped direct-user scan saw `mark` (a user, not a read) while
      // `cq_measure(mark)` sat one hop out and lowered to a measurement of the
      // POST-Ry register. Measured, both directions, both verify- and
      // stage-2b-clean: `..._reject_stale_diag_alias_{forward,backward}.ll`.
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
        // mixed `if(c) r=cq_theta(r,·) else r=cq_phi(r,·)` declines here, on the
        // stale-record string, for a region whose actual defect is the mixture.
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
        const bool Ok = BaseWire.count(UI) ? cannotFollowGate(UI, BI, *DT)
                                           : provablyBefore(UI, BI, *DT);
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
      SawPhaseArm = true;
      Routed = Base;
      continue;
    }

    // ---- 4.2 value-arm classification (PRD Part II §8.3; IMPL-4.2 §3) ----
    if (Base == ArmIncoming) {
      // The phase spine consumed nothing — try the arm-block-bounded value
      // chain. `Routed` doubles as the QQ threading hint (see walkValueChain).
      ValueChain Chain = walkValueChain(ArmIncoming, ArmBB, Taint, Routed);

      // The chain ran into an in-arm `cq_phi`: phase + value links in one
      // lineage (`rz(p,a); p=p+3`). The answer carries both a phase and a
      // changed basis — the CNOT copy-out copies only the basis label
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
        // An FP-typed merge under tainted control is categorically an ANGLE,
        // never routable data — even though f64 has a valid ABI width (the
        // f64 silent-miscompile family; PRD §8.1). isFPOrFPVectorTy, not the
        // scalar-only isFloatingPointTy (which misses <2 x double>).
        if (MergePhi->getType()->isFPOrFPVectorTy()) {
          declineArm(declAnchor(Region), "control flow");
          return ArmDisposition::Declined;
        }
        // POSITIVE half of criterion 3's "merge type is integer" (§8 review,
        // 2026-06-10): an integer VECTOR (<2 x i32>, reachable via the
        // escape-whitelisted bitcast of a tainted i64) or a non-ABI-width
        // integer (i128 via zext) is not routable data either — the WI-4
        // emitter could mint no alloc/copy/template symbol for it (null
        // FunctionCallee AFTER the route bracket is emitted — a
        // crash-on-valid-input, violating detect-before-mutate). The width
        // check is NECESSARY-not-sufficient and runs only AFTER the FP
        // decline above — never key the DECISION on abiWidthFromType()
        // validity (f64 has a valid width yet is an angle, the f64 trap).
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
        // condition READ). Replaying such a chain on the routed rail would
        // compute f(routed), not the source's f(base): a verify-clean wrong
        // unitary. Not routable, not a §3c clobber (the condition register is
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
        //   * a DIAGONAL-ALIAS hit (`Routed = %qd = cq_phi(%q,·)`, condition
        //     reads `%q`): the source rewrites a DIFFERENT variable that
        //     merely shares the physical wire post-RAUW — lowerable in
        //     principle under a binding strip-after-R† order, so declined
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
        // 2026-06-11 — a latent WI-4 over-accept): the routed base's
        // physical wire — its diagonal-alias closure, the same backward
        // `cq_phi` chain diagonalAliasHit walks — must gain NO non-diagonal
        // (Ry) in-place gate. A chained `cq_theta` reaching the wire through
        // a SIBLING SSA name of the closure (`%qd = cq_phi(%q,·);
        // %q2 = cq_theta(%q,·)`) is invisible to every other guard:
        // condProvenance stops AT a theta source (never entering its tainted
        // arg-0), so neither the condition-seeded wire walk nor
        // diagonalAliasHit ever reaches `%q` — yet post-RAUW the route-in at
        // the branch reads the POST-Ry wire while the chain's SSA base names
        // the PRE-Ry RECORD: the stale-record family
        // (lowering_reject_stale_record_add.ll), replayed onto the rail as a
        // verify-clean wrong unitary. Position-free walk — ANY theta on the
        // wire declines, including a post-region one (over-decline is safe,
        // Prime Directive). PHASE arms are immune and unguarded: `cq_phi` is
        // wire-named and diagonal — replaying Rz on the live wire at the
        // branch is exactly the source's program order; no basis record is
        // read (the same opcode-not-position rationale as isValueChangingOp).
        // The diagonal-alias closure that seeds the walk lives in the
        // WireWalk core itself since test_C_libtooling-6j1 (the straight-line
        // twin of this guard) — `Routed` alone seeds the full backward
        // `cq_phi` chain.
        // CrossValueRouting=TRUE since bd tayx (uniform router posture; Rule
        // 14): a router phi forwards the same physical handle. For THIS value
        // path the flip is belt-and-braces — the router spelling's arm ops
        // read the stale wire and the PRE-detect `declineStaleRecordOps`
        // (position-aware, router-crossing) declines it first (pinned by
        // control_swap_reject_value_diamond_router_base_backstop.ll) — but
        // detection must not depend on that backstop coincidence (the same
        // principle the SwitchArmProve twin records).
        if (CallInst *Gate = findNonDiagonalWireGate(
                Routed, /*CrossValueRouting=*/true)) {
          declineArm(Gate,
                               "routed base predates a non-diagonal gate");
          return ArmDisposition::Declined;
        }
        // A DERIVED routed base's OWN angle must be classical — the arg-1
        // parallel of criterion 3 (Rule 3). The phase path declines this via
        // taintedAngleGate's base check, but that helper inspects the PHASE
        // spine's base, which for a value arm is the arm's first binop (the
        // spine consumed nothing) — so the value chain's real base must be
        // checked here. Loud either way (RotationLowering's own guard fires
        // later), but mutation must never precede detection: without this the
        // region is fully emitted and flattened before that downstream
        // decline (§8 adversarial review, 2026-06-11; same string as the
        // phase-path twin, control_swap_reject_value_derived_tainted_angle.ll).
        if (auto *BaseCI = dyn_cast<CallInst>(Routed);
            BaseCI && isPhiCall(BaseCI) && BaseCI->arg_size() >= 2 &&
            Taint.Tainted.count(BaseCI->getArgOperand(1))) {
          declineArm(BaseCI, "rotation angle");
          return ArmDisposition::Declined;
        }
        // Rule 8 linearity + self-contained arm block (fan-out / stray op /
        // DAG sibling — see valueArmIsPureChain).
        if (!valueArmIsPureChain(ArmBB, Chain.Ops, MergePhi)) {
          declineArm(declAnchor(Region), "impure value arm");
          return ArmDisposition::Declined;
        }
        // A Q+Q link (second tainted operand) is a recognized value shape the
        // routed replay does not yet handle — defer with the 4.2 string.
        if (Chain.HasQQ) {
          declineArm(Chain.Ops.front(), "value-arm swap-route");
          return ArmDisposition::Declined;
        }
        // ACCEPT-class value arm: record the class + the ordered chain for
        // the emitter (Shadow = Region.Arm's chain, ShadowFalse =
        // Region.ArmFalse's; for an orientation-B diamond Region.Arm is the
        // FALSE successor — polarity rides ArmNegated, never edge truth).
        if (ArmBB == Region.Arm) {
          Region.ClassArm = ArmClass::Value;
          Region.Shadow.assign(Chain.Ops.begin(), Chain.Ops.end());
        } else {
          Region.ClassArmFalse = ArmClass::Value;
          Region.ShadowFalse.assign(Chain.Ops.begin(), Chain.Ops.end());
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
  // and a two-arm value IF/ELSE (WI-5) both reach the §4 emitter, which reads
  // the recorded ClassArm/ClassArmFalse + Shadow/ShadowFalse. Homogeneity is
  // already proven here: a surviving two-arm region is either all-phase or
  // all-value over ONE shared routed base (the mixed declines above), and an
  // if/else second chain bottoming anywhere but the first arm's anchored base
  // declined `control flow` (base-identity).

  // P1 — the Inc-4 position-aware accept is PHASE-ONLY. A value arm keeps the
  // position-free reading verbatim (Rule 7: method-B copies a basis LABEL out
  // and replays the chain on the routed rail, so a later in-place Ry on that
  // wire is a real staleness hazard the phase path does not have — the phase
  // answer stays in place on `q` and the flag is stripped by the uncontrolled
  // `icmp_inv`). Every value-arm decline above is already wrapped, but the
  // ACCEPT-class value arm falls through to here, so this is the fence that
  // actually holds P1. `SawValueArm` also covers the mixed case by
  // construction (a mixed region declined above).
  if (DeferredWireGate && (SawValueArm || !SawPhaseArm)) {
    diagnoseUnderControl(declAnchor(Region),
                         "condition predates a non-diagonal gate");
    return ArmDisposition::Declined;
  }
  return ArmDisposition::Accept;
}

// 6.5 — recognize the §2.13 classical-call-under-control shape (DD-7). Pure SSA
// analysis, before any mutation (Rule 9). See ArmClassify.h for the disposition
// contract. This runs BEFORE `classifyArms`: a positive match short-circuits the
// phase/value classifier (whose `isValueChangingOp(call)`-true path would
// otherwise decline the same shape as a §3c clobber — a safe over-decline, but
// not the 6.5 lowering).
// bd 9hea — see ArmClassify.h for the full contract. Whitelist by construction.
bool freezeDischargesHoistedArg(const llvm::CallBase *Call, unsigned Ai) {
  if (!Call->paramHasAttr(Ai, Attribute::NoUndef))
    return false;  // nothing to discharge — poison here is simply not UB.

  // *** AUDIT THE SAME SET THE TRIGGER READ, WHICH IS THE UNION — NOT THE CALL SITE.
  // THE FIRST DRAFT OF THIS FUNCTION GOT THIS WRONG AND IT WAS A LIVE OVER-ACCEPT
  // (bd 9hea Rule-13 blocker). *** `CallBase::paramHasAttr` FALLS BACK to the
  // callee's `AttributeList` (InstrTypes.h), while `CallBase::getAttributes()` does
  // NOT — it is the call site alone. Auditing the narrower set while triggering off
  // the wider one meant a callee-side `range`/`nonnull`/`align`/`dereferenceable`/
  // `nofpclass` was INVISIBLE here: the loop saw only `{noundef}`, hit `continue`,
  // and returned true while the attribute bound in full force.
  // MEASURED, one token: deleting `range(i32 0, 10)` from the CALL SITE of
  // `..._reject_frozen_arg_range.ll` — leaving it on the `define` — flipped that
  // module from a loud decline to an accept that froze the argument. And it is
  // reachable from ordinary legal C through the real multi-TU pipeline, because a
  // gnu attribute on a definition in one TU need not appear on the prototype in
  // another: `clang -O1` emits `nonnull` on the definition and NOT on the call site,
  // and the hoist then called a `nonnull` parameter with an arbitrary pointer on a
  // guard of ZERO amplitude — bd wve8's own finding, one attribute lookup over.
  // *** CALLEE-SIDE IS THE CANONICAL HOME FOR A PARAMETER ATTRIBUTE, and for the
  // `speculatable`-declaration totality route it is the ONLY place one can live. ***
  //
  // `freeze` yields SOME defined value and promises nothing further, so every OTHER
  // attribute on the parameter must be one an arbitrary defined value cannot
  // violate. Enumerate the INERT ones and refuse anything unlisted (never the
  // converse — bd s6ao). The four admitted are ABI/calling-convention only: they
  // describe how the value is passed, not which values are legal.
  const auto inertSet = [](const llvm::AttributeSet &AS) {
    for (const llvm::Attribute &A : AS) {
      if (!A.isEnumAttribute())
        return false;  // parameterised (range/align/byval/...) or string — refuse.
      switch (A.getKindAsEnum()) {
      case Attribute::NoUndef:
      case Attribute::ZExt:
      case Attribute::SExt:
      case Attribute::InReg:
        continue;  // freeze-inert.
      default:
        return false;  // every poison-conditional fact lands here.
      }
    }
    return true;
  };

  // An INDIRECT call has no callee set to audit, so there is no way to know what the
  // parameter asserts — refuse outright rather than audit half the union.
  const llvm::Function *Callee = Call->getCalledFunction();
  if (!Callee)
    return false;

  return inertSet(Call->getAttributes().getParamAttrs(Ai)) &&
         (Ai >= Callee->arg_size() ||
          inertSet(Callee->getAttributes().getParamAttrs(Ai)));
}

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
  //   * it keeps a phase gate (`cq_phi`, tainted) and a value chain (`add`,
  //     tainted) OUT of this path — they classify in `classifyArms`;
  //   * it IS the all-classical-INPUTS check (§2.13 / WI-5.6 / Rule 3). `propagate`
  //     taints EVERY non-measure, non-angle user of a tainted value
  //     (TaintPropagation.cpp:307), and a generic (non-`cq_`) call has no
  //     angle-operand exclusion — so ANY tainted operand (an argument OR the
  //     called operand, an indirect call through a tainted pointer) taints the
  //     result. A CLASSICAL result therefore proves every input is classical:
  //     the clone × route composition (quantum data under quantum control) is OUT
  //     of 6.5 (deferred Phase 4×6) and is excluded HERE — it declines via
  //     `classifyArms` (a tainted call result is value-changing → `arm rewrites a
  //     condition operand`, WI-5.6) rather than being mis-claimed as a 6.5 site.
  auto *Call = dyn_cast<CallInst>(ArmIncoming);
  if (!Call || Call->getParent() != Region.Arm ||
      Taint.Tainted.count(Call))
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
  // side-effect-free, memory-independent, will-return callee.
  // `doesNotAccessMemory()` (readnone) makes the result depend solely on its args;
  // `!mayHaveSideEffects()` adds nounwind + willreturn (no throw, no infinite loop).
  // A readonly / writing / throwing / non-returning callee DECLINES (over-decline
  // is safe; the rejection set is load-bearing for the inert-hoist claim).
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
  //     visible + non-interposable (`hasExactDefinition`) + non-varargs; no
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
  // which KEEPS a poison-producing `shl` in the callee and still lowers.
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

  if (!Call->doesNotAccessMemory() || Call->mayHaveSideEffects()) {
    diagnoseUnderControl(Call, "control flow");
    return ClassicalCallDisp::Declined;
  }
  if (!llvm::isSafeToSpeculativelyExecute(Call) &&
      !isSpeculatableTotalCallee(Callee)) {
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
  for (unsigned Ai = 0, Ae = Call->arg_size(); Ai != Ae; ++Ai)
    if (Call->paramHasAttr(Ai, Attribute::NoUndef) &&
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


// ---- ANGLE-SELECT BY DIFFERENCE (control-in-place-PRD §12.3, bd
//      test_C_libtooling-drbq Inc 2b) — BOTH ROTATION STEMS ------------------
//
// THE SHAPE, which is exactly what `clang -O1` makes of the C the user writes:
//
//     if (q == 5) r = cq_theta(r, A); else r = cq_theta(r, B);   // or cq_phi
//     r = cq_theta(r, q == 5 ? A : B);                           // same IR
//
// SimplifyCFG merges the two arms into ONE call whose ANGLE is a select, so the
// branch CFG is GONE before the pass runs (Rule 9) and there is no diamond to
// route:
//
//     %c = icmp eq i32 %q, 5
//     %a = select i1 %c, double A, double B          ; A, B CLASSICAL
//     %t = call i32 @cq_theta_si32(i32 %r, double %a) ; %r TAINTED, %a ONLY arg-1
//
// THE LOWERING IS ANGLE ADDITIVITY ON ONE AXIS, not a new mechanism:
// `Ry(A) = Ry(B)·Ry(A−B)` and, under this project's `Rz = diag(1, e^{iθ})`
// convention, `Rz(A) = Rz(B)·Rz(A−B)` EXACTLY (no global-phase residue — the
// two diagonals multiply entrywise). So with `f = [pred(C)]`:
//
//     R(r, B)                       ; unconditional, the FALSE-arm angle
//     f = icmp_<pred>_hl(q, 5)      ; flag mint, unchanged from every other path
//     R_controlled(f, r, A−B)       ; the drbq Inc-1 / Inc-2a in-place gate
//     icmp_<pred>_hl_unc(f, q, 5)   ; flag strip
//     cqrt_free(f)
//
// f=0 leaves `R(B)`; f=1 gives `R(B)·R(A−B) = R(A)`. There is NO polarity case:
// `select %c, A, B` always means "A when the flag is 1", so a `!=` source (which
// `clang` canonicalizes to `icmp eq` with the select operands SWAPPED) needs
// nothing special and no `cqrt_x` bracket ever appears in this stream.
//
// WHY THIS IS NOT A NEW UNITARY CLAIM: the emitted stream is BYTE-IDENTICAL to
// the manual by-difference twin `r = R(r, B); if (q == 5) r = R(r, A−B);`, which
// is an Inc-1 (Ry) / Inc-2a (Rz) in-place DIAMOND that already lowers on the
// pre-2b binary. The increment's central witness is that byte identity, not a
// fresh argument (see CONTROL_IN_PLACE_INC2B_NOTES.md §6).
//
// THE FENCES, and which ones are stem-split:
//   S1  `double` select, both data operands CLASSICAL (a tainted A/B is the
//       f64/angle miscompile family, Rule 3), AND the arm VALUES realizable —
//       BOTH ARMS `ConstantFP`, neither carrying undef/poison (incl. inside a
//       ConstantExpr), neither non-finite, their difference finite, and its
//       by-difference ROUNDING residual under `kAngleSelectMaxRoundingRad`.
//       A RUN-TIME arm (a parameter, a load, a call result, an `fpext`, a
//       run-time `fsub`) DECLINES: the compiler would synthesize an `fsub` the
//       source never wrote, whose rounding error is unbounded in absolute
//       radians and whose result can be `inf`/`NaN` from two finite arms —
//       neither fenceable at compile time, both measured from plain C, and the
//       manual by-difference twin of that shape declines on both binaries, so
//       the class was reachable only through 2b. The value half is the round-1
//       Rule-13 review's, the link-time-constant clause the round-2 one's, and
//       the constant-arms-only narrowing the CLEARANCE review's (finding F-11,
//       owner option (2)); see the block comment above
//       `angleSelectArmsAdmissible`.
//   S2  EXACTLY ONE user of the select: a rotation's arg-1 with a different
//       arg-0. N consumers is a recorded follow-on — S6's positional scan is
//       wire-blind, which makes an N-consumer accept ORDER-dependent.
//   S3  arg-0 TAINTED — a classical arg-0 is controlled STATE PREP (PRD S5,
//       Inc 4), which needs its alloc hoisted and a seed-identity fence.
//   S4  a BARE lowerable compare with EXACTLY ONE tainted operand and EXACTLY
//       ONE user (the select). The single-user clause is what declines a
//       compare shared with a `br` region, with a second select (two gates per
//       arm), or with a `ShareCondFlag`-style data use.
//   S5  the ABI width has a `cqrt_{ry,rz}_<W>_controlled`, asked through the
//       MINT's own expression (`suffixFromName` + `abiWidthFor`).
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
//       basis the mint read, so `f` does not return to |0⟩ (Rules 6/8). Rz is
//       DIAGONAL and exempt (PRD §3c) — `q = cq_phi(q, q==5?A:B)` accepts.
//   S9  Ry ONLY — R6 stale record, `classifyArms`' clause verbatim with the
//       consumer `T` in the barrier role `BI` played. Rz exempt (§12.1
//       transparency: a diagonal gate moves no basis label, so a pre-gate SSA
//       record read afterwards denotes the same measurement statistics).
//   S10 nothing else already claims `T` or `Sel`.
//
// Everything outside this returns `NotApplicable` and the caller fires its
// pre-existing `rotation angle` decline unchanged — so no shape that declined
// before this increment moves, except the ones this shape now LOWERS.


// ---- THE ARM-VALUE FENCE (S1's second half) — bd drbq Inc 2b ROUND-1 RULE-13
//      review, lenses L5-1 / L7-F1 / L7-F2 / L7-F6 ---------------------------
//
// NOTHING IN S1–S10 AS SHIPPED INSPECTED THE VALUES OF `A` AND `B` — only their
// TYPE and their TAINT. Three families of arm value get through that and produce
// a stream the source never described. All three are refused HERE, by returning
// `NotApplicable`, so the caller's pre-existing `rotation angle` decline fires
// and no new diagnostic string enters the dialect.
//
//  (1) UNDEF / POISON. `select c, 0.9, undef` folds `fsub 0.9, undef` to a
//      CONCRETE quiet NaN, so the DEFINED arm is destroyed by the undefined one
//      (`Ry(undef)·Ry(NaN)` is not `Ry(0.9)` under any refinement of `undef`);
//      `select c, poison, 0.3` puts a raw `double poison` in a gate slot.
//      `LiteralIntegrity`'s guard 1 is CORRECT to stay silent — it counts ONE
//      undef slot, the other being the folded NaN — which is exactly why the
//      neighbouring `0.9, poison` and `undef, undef` cells were loud and this one
//      was not. Asked through the SHARED `valueCarriesUndef` (Rule 14), never a
//      bare `isa<UndefValue>`: an arm may be a `ConstantExpr` that CARRIES undef
//      (`bitcast (i64 undef to double)`), which the bare test misses.
//
//  (2) A NON-FINITE CONSTANT ARM, or a NON-FINITE DIFFERENCE OF FINITE ARMS. The
//      by-difference identity is an identity over the REALS; `+inf` / `NaN` arms
//      and the OVERFLOW of `DBL_MAX − (−DBL_MAX)` each MANUFACTURE a value the
//      source never named and destroy the arm that was well defined. Note the
//      second half is not implied by the first: both arms of the overflow case
//      are perfectly ordinary finite doubles.
//
//  (3) ROUNDING. `R(A) = R(B)·R(A−B)` is exact in real arithmetic; the emitted
//      stream realizes `B + fl(A−B)`, whose error is
//
//          delta = A − (B + fl(A−B))          |delta| <= 1/2 ulp(A−B)
//
//      i.e. roughly `|A−B|·2^-53` — 2^-54 rad on the flagship `0.9 / 0.3` (which
//      is physically nothing and IS the shape we set out to build, Rule 17), but
//      0.858 rad on `pi / 1e16` and a full 1.0 rad on `1.0 / 1e300`, both of
//      which the PRE-2b binary declined LOUDLY. Turning a loud refusal into a
//      silently wrong unitary is the one unforgivable outcome, so constant arms
//      are fenced at `kAngleSelectMaxRoundingRad` below.
//
//  (4) A RUN-TIME ARM AT ALL — clause (2c). *** THE ACCEPT CLASS IS CONSTANT
//      ARMS ONLY. *** Two earlier drafts of this paragraph described run-time
//      arms as ACCEPTED and carrying a documented residual (round-1: "the
//      bound"; round-2: both halves, after lens R1 item 1 graded it
//      CONFIRMED-MISCOMPILE). The independent Rule-13 CLEARANCE review then
//      ranked it a BLOCKER (finding F-11 / B1) and the orchestrator ruled option
//      (2): narrow to constants. Both residual halves therefore no longer exist
//      in the shipped accept class, and the sentences that described them here
//      are kept only as the REASON for the refusal:
//
//        (i)  ROUNDING — `|delta| <= 1/2 ulp(A−B)`, which is a bound on the
//             DIFFERENCE and is UNBOUNDED in absolute radians. Measured from
//             plain C: `pi` and `1e16` as run-time angles give a realized
//             true-arm angle of 4.0 rad where the source wrote `Ry(pi)`, i.e.
//             0.858 rad wrong. The CONSTANT spelling of that same pair declines
//             at clause (3) below — so before the narrowing the fence depended
//             on how the user SPELLED the angle.
//        (ii) NON-FINITENESS — `fl(A−B)` can be `inf`/`NaN` from two perfectly
//             ORDINARY FINITE arms. Measured from plain C:
//             `+8.98846567431158e307` and its negation emit
//             `cqrt_ry_i32_controlled(f, h, inf)`. Half an ulp does not describe
//             `inf`, so this class is named separately and never folded into
//             "the bound".
//
//      NEITHER IS FENCEABLE AT COMPILE TIME — the `fsub` happens at run time —
//      which under the Prime Directive is a reason to DECLINE, not to accept: the
//      precondition here is DISPROVEN on reachable plain-C inputs, not merely
//      unproven, and the PRE-2b binary declined every one of them loudly.
//
//      AND THE MITIGATION THAT MADE THE EARLIER DISPOSITION LOOK REASONABLE IS
//      FALSE (clearance observation 1). "It is the same arithmetic the manual
//      by-difference C twin performs" is true of the ARITHMETIC and false of any
//      PROGRAM CQ will compile: that twin, with run-time arms, DECLINES
//      `control flow under quantum control` on BOTH binaries, because `clang -O1`
//      sinks the `fsub` into the arm block and `inPlaceRotationArmTheta` refuses
//      a stray op there — measured with the subtraction inline and hoisted. The
//      only compilable "twin" is `tools/angle_select_twin_matrix.py`'s `args`
//      cells, which take the difference in as a PARAMETER and perform no
//      subtraction at all. So this residual was reachable ONLY through 2b.
//
// Both halves are retired OUTRIGHT — for run-time arms too — by the
// two-controlled form `x(f)·R_c(f,h,B)·x(f)·R_c(f,h,A)`, which performs no
// subtraction at all. That is option (3) of the owner-desk three-way choice in
// notes §9/§11; option (1), widening back to run-time arms, is the one line at
// clause (2c).

// The placeholder bound on the by-difference ROUNDING error, in RADIANS.
//
// *** THIS IS A PLACEHOLDER ON THE OWNER'S DESK, NOT A DERIVED CONSTANT. ***
// It is chosen to separate two measured populations and nothing more: every
// ordinary-angle pair in this tree's fixtures, goldens and twin matrix has
// `|delta| <= 2^-54` or `delta == 0` exactly, while every macroscopic case the
// round-1 review found is `>= 1e-20`... and, in the cases that matter, `>= 0.85`.
// 2^-40 rad (~9.1e-13) sits 2^14 above the first population and far below the
// second. The ruling that would REMOVE it, and the exact alternative if the
// answer goes the other way, are recorded verbatim in
// `docs/prd/phase-04-swap-route-control/CONTROL_IN_PLACE_INC2B_NOTES.md` §9,
// with the clearance record and the shipped answer in §11:
// (i) is round-to-nearest angle arithmetic IN the semantic model (the `fenv`
// analogue)? then this constant goes — and so does clause (2c), since the two
// are the same question asked of a constant and of a run-time value; or (ii) if
// the emitted stream must denote the source's angle EXACTLY, the alternative is
// the two-controlled form `x(f)·R_c(f,h,B)·x(f)·R_c(f,h,A)` — no `fsub`, no
// rounding, no inf/NaN manufacture, no undef fold, existing symbols only. That
// is a PRD §12.3 design change and was NOT made in this session. What DID ship
// is the third answer, option (2): keep this bound and refuse run-time arms
// outright at (2c), so the fence no longer depends on how the user spelled the
// angle.
static const double kAngleSelectMaxRoundingRad = 0x1p-40;

bool angleSelectArmsAdmissible(const Value *A, const Value *B) {
  // Self-contained: the caller's S1 already proved the select is `double`, but
  // this predicate is ALSO the emitter's step-0 re-ask, so it establishes its own
  // premise rather than inheriting one. Anything else over-declines (safe).
  if (!A || !B || !A->getType()->isDoubleTy() || !B->getType()->isDoubleTy())
    return false;

  // (1) undef / poison, including a ConstantExpr that carries one.
  //
  // ASKED FIRST, DELIBERATELY, AND IT IS NOW BEHAVIOURALLY SUBSUMED BY (1b)
  // BELOW (bd drbq Inc 2b ROUND-2 review, lens R1 items 4 and 5). For a `double`
  // arm the only `Constant` subclasses are `ConstantFP`, `UndefValue` /
  // `PoisonValue` and `ConstantExpr`, so every value this clause refuses is also
  // refused by (1b) — no fixture can red-green this clause on its own any more,
  // and `control_angle_select_reject_undef_constexpr_arm.ll`'s header says so
  // rather than claiming otherwise. IT IS KEPT for two reasons that are not
  // "otherwise we would accept": the ORDER makes `undef` the recorded reason for
  // an arm that is both (the specific fact, with the fold-to-NaN derivation),
  // and (1b) is the clause a future widening would narrow — admitting a
  // link-time constant once its value is provably finite and well-rounded is the
  // obvious next step, and it needs this clause standing underneath it.
  //
  // ONE PRECISION ABOUT THE RECORDED REASON (Rule-13 clearance review,
  // non-blocking observation 8). This calls the NON-global-skipping
  // `valueCarriesUndef`, so an arm that is a relocatable ADDRESS whose global's
  // INITIALIZER contains `undef` is refused here as "carries undef" even though
  // the address itself is perfectly well defined — `LiteralIntegrity.cpp`
  // documents exactly that distinction for its slot variant. The DISPOSITION is
  // right either way (the class is refused by (1b) two clauses down, as a
  // link-time constant this compiler cannot evaluate), but the reason this
  // clause records for it is the weaker of the two. Left as-is deliberately:
  // over-declining is safe, and a global-skipping variant here would make the
  // undef fence depend on which of two spellings a future reader picked.
  if (valueCarriesUndef(A) || valueCarriesUndef(B))
    return false;

  const auto *CA = dyn_cast<ConstantFP>(A);
  const auto *CB = dyn_cast<ConstantFP>(B);

  // (1b) A `Constant` THAT IS NOT A `ConstantFP` — in practice a `double`-typed
  // `ConstantExpr` such as `bitcast (i64 ptrtoint (ptr @g to i64) to double)`.
  //
  // *** ROUND-2 RULE-13 REVIEW FINDING (lens R1 item 5). *** The `!CA || !CB`
  // line below used to take this class, under the comment "at least one runtime
  // arm: no compile-time difference exists", and that sentence is FALSE of it: a
  // relocatable address is a LINK-TIME constant, so the difference does exist —
  // it is simply not evaluable HERE, which means clauses (2a), (2b) and (3) all
  // silently did not run and the emitted controlled gate's angle was a
  // reinterpreted address that may be a NaN, an infinity, or 1e300 rad from
  // anything the source named. Nothing downstream could bound it either. So the
  // split was by EVALUABILITY, not by constness: a genuine run-time value
  // carried the documented residual while a constant this compiler cannot read
  // declined. *** SINCE THE CLEARANCE NARROWING AT (2c) BOTH SIDES OF THAT SPLIT
  // DECLINE, so this clause no longer changes a disposition — it survives to
  // keep the REASON precise (a link-time constant is refused for being
  // unevaluable HERE, which is a different fact from being unevaluable at all),
  // and because it is the clause a future widening would narrow: admitting a
  // relocatable address once its value is provably finite and well-rounded is
  // orthogonal to owner option (1), which is about run-time values.
  // Over-declining is safe and this class is hand-IR-only — every C punning idiom
  // measured goes through a `load`, and a literal `bitcast (i64 K to double)` is
  // folded to a `ConstantFP` by the LLVM-19 parser.
  // Fixture: `control_angle_select_reject_constexpr_arm.ll`.
  if ((isa<Constant>(A) && !CA) || (isa<Constant>(B) && !CB))
    return false;

  // (2a) a non-finite CONSTANT arm. Since the clearance narrowing at (2c) below
  // this clause no longer changes any DISPOSITION — a module it refuses with one
  // constant and one run-time arm would be refused two lines later anyway — but
  // it still decides the recorded REASON, which is the whole point of the
  // ordering (see (1)'s note): a `+inf` arm beside a parameter is the
  // non-finite-arm case, not the run-time case. Keeping the `CA &&` / `CB &&`
  // guards also means (2c)'s widening back (owner option (1), one line) cannot
  // silently unfence this class along with the run-time one.
  if (CA && !CA->getValueAPF().isFinite())
    return false;
  if (CB && !CB->getValueAPF().isFinite())
    return false;
  if (!CA || !CB)
    // (2c) *** AT LEAST ONE ARM IS A GENUINE RUN-TIME VALUE — REFUSED. ***
    //
    // An argument, a load, a call result, an `fpext` of a float, a runtime
    // `fsub`; after (1b) that is the only way to reach here with a
    // non-`ConstantFP` arm. THE ACCEPT CLASS IS CONSTANT ARMS ONLY. This line
    // shipped as `return true;` and was the Increment-2b CLEARANCE BLOCKER (bd
    // `test_C_libtooling-drbq`, the independent Rule-13 clearance review, finding
    // F-11 / ranked blocker B1, graded CONFIRMED-MISCOMPILE and BLOCKING;
    // orchestrator decision on that verdict: ship option (2), narrow to constant
    // arms). No new diagnostic string: `NotApplicable` here means the caller's
    // pre-existing `rotation angle` decline fires, byte-identically to the
    // PRE-2b disposition of the same module.
    //
    // THE REASON, and it is not "the residual is large" — it is that the
    // precondition is DISPROVEN rather than merely unproven. The by-difference
    // identity `R(A) = R(B)·R(A−B)` is exact over the REALS; what the machine
    // realizes on the true edge is `B + fl(A−B)`. For a CONSTANT pair the
    // compiler evaluates that difference and clauses (2a)/(2b)/(3) below decide
    // it. For a RUN-TIME pair the compiler instead SYNTHESIZES AN `fsub` THE
    // SOURCE NEVER WROTE, and two things ride on it that no compile-time fence
    // can see:
    //
    //   (i)  ROUNDING, UNBOUNDED IN ABSOLUTE RADIANS. `|delta| <= 1/2 ulp(A−B)`
    //        is a bound on the DIFFERENCE's magnitude, not on the angle the user
    //        named. Measured from plain C with the two angles as `volatile
    //        double`s (`clearance2b/p3/r01_rt_pi_sel.c`): `A = pi`, `B = 1e16`
    //        emits `cqrt_ry_i32(h1, 0x1.1c37937e08p+53)` then
    //        `cqrt_ry_i32_controlled(h2, h1, -0x1.1c37937e07ffep+53)`, i.e. a
    //        realized true-arm angle of 4.0 rad where the source wrote `Ry(pi)`
    //        — 0.858 rad wrong. The CONSTANT spelling of that same pair declines
    //        at clause (3).
    //   (ii) NON-FINITENESS, WHICH IS NOT A ROUNDING OF ANYTHING. `fl(A−B)` can
    //        be `inf` or `NaN` from two perfectly ORDINARY FINITE arms —
    //        `r02_rt_ovf_sel.c` (`A = +8.98846567431158e307`, `B = −A`) emits
    //        `cqrt_ry_i32_controlled(h2, h1, inf)`; `r03_rt_nan_sel.c` puts a
    //        run-time NaN in the slot directly. Half an ulp does not describe
    //        either. The clearance also reproduced the class on the **Rz** stem
    //        (`r04_rt_rz_pi_sel.c`) and on a mul-DERIVED base
    //        (`r05_rt_ovf_mul_meas_sel.c`), and on plain function parameters with
    //        no `volatile` at all (`clearance2b/rt/t_param_sel.c`).
    //
    // AND THE "IT IS THE SAME ARITHMETIC THE MANUAL TWIN PERFORMS" DEFENCE IS
    // FALSE OF ANY PROGRAM THIS COMPILER WILL COMPILE (clearance observation 1,
    // recorded by neither review round). The natural twin
    // `r = R(r,B); if (c) r = R(r, A−B);` with run-time arms **DECLINES
    // `control flow under quantum control` on BOTH binaries** — measured with the
    // `fsub` written inline (`r01_rt_pi_twn`, `r07_twn` even at delta = 0,
    // `rt/t_param_twin`) and hoisted before the branch (`r06`): `clang -O1` sinks
    // it into the arm block and `inPlaceRotationArmTheta` refuses a stray op
    // there. The only compilable "twin" is `tools/angle_select_twin_matrix.py`'s
    // `args` cells, which take the difference in as a PARAMETER and therefore
    // perform no subtraction at all. So the residual was reachable ONLY through
    // 2b — it is not inherited from a shape the compiler already accepted — and
    // the PRE-2b binary declined every one of the six reproducers loudly. Prime
    // Directive: a disproven precondition declines.
    //
    // WIDENING BACK IS THE OWNER'S CALL AND IS THIS ONE LINE. Option (1) of the
    // three-way owner-desk item (notes §9 / §11, PRD §12.3) restores `return
    // true;`, flips `control_angle_select_reject_runtime_arms{,_rz,}.ll`,
    // `control_angle_select_reject_runtime_one_arm.ll` and
    // `control_swap_reject_switch_datamux_angle_runtime.ll` back to accepts, and
    // moves the twin matrix's 16 `args` cells out of its
    // EXPECTED-DECLINE-RUNTIME-ARMS class. It requires an explicit ruling that
    // round-to-nearest angle arithmetic AND non-finite angle arithmetic are both
    // IN the semantic model — the second half is the one option (1)'s stated
    // reasoning did not reach. Option (3), the two-controlled form
    // `x(f)·R_c(f,h,B)·x(f)·R_c(f,h,A)`, performs no subtraction at all and is
    // exact for run-time arms too.
    return false;

  const APFloat &Av = CA->getValueAPF();
  const APFloat NegB = neg(CB->getValueAPF());

  // (2b) the DIFFERENCE must be finite. `IRBuilder`'s constant folder performs
  // exactly this APFloat subtract at round-to-nearest, so `S` below IS the
  // constant that will land in the controlled gate's angle slot.
  //
  // *** THE ORDER (2b) BEFORE (3) IS LOAD-BEARING, NOT TIDINESS *** (Rule-13
  // clearance review, non-blocking observation 9 — recorded here because it was
  // an unpinned premise). `APFloat::compare` on a NaN returns `cmpUnordered`,
  // and (3)'s test is `!= cmpGreaterThan`, so a NaN `Delta` would ACCEPT. A NaN
  // `Delta` is exactly what the TwoSum produces from a non-finite `S` (`inf −
  // inf`), i.e. from the overflow class (2b) exists to refuse. Swapping these
  // two clauses therefore silently re-opens the round-1 finding F-2
  // (`reject_overflow_difference.ll`) while leaving every other fixture green —
  // the fixture that reddens on the swap is that one, and only because (2b)
  // still runs at all.
  APFloat S = Av;
  S.add(NegB, APFloat::rmNearestTiesToEven);
  if (!S.isFinite())
    return false;

  // (3) THE ROUNDING RESIDUAL, computed EXACTLY by the TwoSum error-free
  // transformation (Knuth). For finite `a`, `b` with `s = fl(a+b)` finite,
  //
  //     bb = fl(s − a) ;  e = fl(fl(a − fl(s − bb)) + fl(b − bb))
  //
  // gives `a + b = s + e` EXACTLY — every intermediate is representable, so `e`
  // is not itself rounded. Apply it to `a = A`, `b = −B`:
  //
  //     A − B = S + e     hence     fl(A−B) = S = (A − B) − e
  //
  // and the angle the device realizes on the TRUE edge is
  //
  //     B + S = B + (A − B) − e = A − e
  //
  // so `delta = A − (B + S) = e`. The TwoSum residual IS the angle error; no
  // extended precision and no simulation is needed to know it. Verified against
  // an independent C computation of the same six operations on the round-1
  // review's 25 measured pairs (flagship `0.9/0.3` → `-0x1p-54`, `pi/1e16` →
  // `-0x1.b7812aeef4bap-1`, `1.0/1e300` → `0x1p+0`).
  APFloat Bb = S;
  Bb.subtract(Av, APFloat::rmNearestTiesToEven);
  APFloat T1 = S;
  T1.subtract(Bb, APFloat::rmNearestTiesToEven);
  APFloat T2 = Av;
  T2.subtract(T1, APFloat::rmNearestTiesToEven);
  APFloat T3 = NegB;
  T3.subtract(Bb, APFloat::rmNearestTiesToEven);
  APFloat Delta = T2;
  Delta.add(T3, APFloat::rmNearestTiesToEven);
  Delta.clearSign();

  // `> bound`, not `>=`: an exact difference (delta == 0 — Sterbenz pairs,
  // ±0.0, equal arms, 2^60/2^59) always passes, and so does anything strictly at
  // the bound. The test is ABSOLUTE, in radians, deliberately: a RELATIVE reading
  // would decline `1e-20 / 1.0` (100% relative error, 1e-20 rad absolute —
  // physically nothing) and would ACCEPT nothing extra.
  return Delta.compare(APFloat(kAngleSelectMaxRoundingRad)) !=
         APFloat::cmpGreaterThan;
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
  Value *A = Sel->getTrueValue();
  Value *B = Sel->getFalseValue();
  if (Taint.Tainted.count(A) || Taint.Tainted.count(B))
    return AngleSelectDisp::NotApplicable;
  // ... and the arm VALUES must be realizable: BOTH arms `ConstantFP`, no
  // undef/poison, no `Constant` that is not a `ConstantFP`, no non-finite
  // constant arm, no non-finite difference, and a by-difference ROUNDING
  // residual under the placeholder bound. The clauses are ORDERED, and the order
  // is the recorded REASON rather than the disposition: undef first, link-time
  // constant second, non-finite arm third, RUN-TIME arm fourth. See the block
  // comment above `angleSelectArmsAdmissible`; added by the round-1 Rule-13
  // review (lenses L5-1, L7-F1, L7-F2, L7-F6), which found that S1–S10 asked
  // about the arms' TYPE and TAINT and never about their VALUES; extended by the
  // round-2 one (lens R1 items 4/5), which found the `ConstantFP`-only split
  // treating a link-time constant as a run-time value; and NARROWED TO CONSTANT
  // ARMS ONLY by the CLEARANCE review (finding F-11 / blocker B1, owner option
  // (2)), which found that the run-time half of that same split was a
  // reachable-from-plain-C wrong unitary the pre-2b binary declined loudly.
  if (!angleSelectArmsAdmissible(A, B))
    return AngleSelectDisp::NotApplicable;

  // S2 — EXACTLY ONE user, and it is a rotation reading the select ONLY as its
  // angle. `hasOneUse` counts USES, so a select feeding both arg-0 and arg-1 of
  // one call is refused here too. Anything else (an fpext/fptrunc/bitcast/
  // freeze/phi carrier, a nested select, a store, a second rotation) keeps the
  // caller's `rotation angle` decline.
  if (!Sel->hasOneUse())
    return AngleSelectDisp::NotApplicable;
  auto *T = dyn_cast<CallInst>(Sel->user_back());
  if (!T || T->arg_size() < 2 || T->getArgOperand(1) != Sel ||
      T->getArgOperand(0) == Sel)
    return AngleSelectDisp::NotApplicable;
  const bool IsTheta = isThetaCall(T);
  const bool IsPhi = isPhiCall(T);
  if (!IsTheta && !IsPhi)
    return AngleSelectDisp::NotApplicable;

  // S3 — a CHAINED rotation on a live register. A classical arg-0 is controlled
  // state prep (PRD S5 / Inc 4): the alloc would have to move with the gate and
  // the "prepped vs |0⟩" disposition of the fresh rail is unproven here.
  Value *RotBase = T->getArgOperand(0);
  if (!Taint.Tainted.count(RotBase))
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
  if (!Tree.Nodes.empty() || Tree.Leaves.size() != 1)
    return AngleSelectDisp::NotApplicable;  // a compound `&&`/`||` tree.
  CmpInst *Cond = Tree.Leaves.front();
  if (Cond != Sel->getCondition() || !Cond->hasOneUse())
    return AngleSelectDisp::NotApplicable;
  const bool LTainted = Taint.Tainted.count(Cond->getOperand(0)) != 0;
  const bool RTainted = Taint.Tainted.count(Cond->getOperand(1)) != 0;
  if (LTainted == RTainted)
    return AngleSelectDisp::NotApplicable;  // Q+Q, or all-classical.
  if (!comparePredLowerable(Cond) || !compareFlagMintable(Cond, Taint))
    return AngleSelectDisp::NotApplicable;

  // S5 — the ABI width must have a `cqrt_{ry,rz}_<W>_controlled`, asked through
  // the expression `lowerRotations` MINTS from (`RotationLowering.h`'s note on
  // `suffixFromName`). Inc-1's R4 asks `abiWidthFromType(T->getType())`; the two
  // agree for every `CQ.h` suffix measured, and asking the mint's own expression
  // is what keeps a divergence from becoming a decline AFTER mutation.
  if (!abiWidthHasControlledRotation(wd.abiWidthFor(
          suffixFromName(T, IsTheta ? "cq_theta_" : "cq_phi_"))))
    return AngleSelectDisp::NotApplicable;

  // S10 — nothing else already claims this gate or this select. `plan` may
  // already carry a `BranchRegion` whose arm gate is `T` (an in-place rotation
  // arm) or a `SelectRegion` on `Sel`; emitting twice would double the stream.
  // Cheap linear scan — a plan holds a handful of regions.
  if (Taint.ControlledRotations.count(T))
    return AngleSelectDisp::NotApplicable;
  for (const ControlRegion &R : plan.Regions) {
    if (R.Merge == Sel || R.Condition == Cond)
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
  //     anchor blocks is asked by NEITHER — measured: a downstream `cq_phi(%t,
  //     0.1)` inside an irreducible cycle, and the same inside a natural loop,
  //     both ACCEPT (`review2b_r2/R1/probes/s7/{fwd,nat}_sel_{ry,rz}.ll`), while
  //     the plain UNCONTROLLED rotation over the same cycle declines `tainted
  //     handle live range crosses a loop backedge`. That is the same "a loud
  //     decline becomes silence" shape prong (a) above was built for, so it is
  //     stated rather than left implicit — but it IS SOUND and it is NOT 2b's:
  //     the manual by-difference twin over the same cycle lowers on the PRE-2b
  //     binary and the emitted `@example` bodies are BYTE-IDENTICAL, so the
  //     silencing belongs to Inc-1's structural freeze
  //     (`ChainWalk::railCarriesControlledRotation` stops the uncompute spine
  //     walking a rail that carries a controlled rotation), which reproduces on
  //     the oracle. Accept fixture:
  //     `control_angle_select_forward_rail_cycle_frozen.ll`, whose header carries
  //     the argument in full.
  //     The `Exclude = T` rationale is correspondingly narrower than it reads: it
  //     is a statement about `T`'s OWN POSITION (asked directly by prong (ii)),
  //     NOT about the rail past `T`. Crossing `T` would sweep every legitimate
  //     post-region consumer into the closure and collapse the accept class,
  //     which is why the exclusion stays.
  //
  //  2. THE CONDITION REGISTER'S RAIL. Prong (iii) asks the ROTATED register's
  //     closure only. The mirror shape — the CONDITION register is the loop rail,
  //     read in the exit block, the rotated register outside — ACCEPTS
  //     (`review2b_r2/R1/probes/s7/oa2_condrail_loop_{ry,rz}.ll`) and is again
  //     BYTE-IDENTICAL to its manual twin on the pre-2b oracle. Sound, and stated
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
  // reason prong (iii) sees it despite `Exclude = T`. Measured both ways: with
  // the header phi (`oa1_var_seed_t.ll`) the shape DECLINES; without one
  // (`nat_sel_rz.ll`) the identical forward read ACCEPTS. So a future change to
  // Case-A's collapse SILENTLY NARROWS S7, with no fixture here to notice — the
  // 8h7d.5 lesson running in the opposite direction.
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
  SmallPtrSet<Value *, 16> BaseWire;
  SmallVector<Value *, 16> BaseWireOrder;
  railWireClosure(RotBase, Taint, WireDir::BothWays, nullptr, nullptr, BaseWire,
                  &BaseWireOrder, /*Exclude=*/T);
  for (Value *W : BaseWireOrder) {
    auto *WI = dyn_cast<Instruction>(W);
    if (WI && blockInAnyCycle(WI->getParent())) {
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
  BasicBlock *BB = T->getParent();
  if (Sel->getParent() != BB || Cond->getParent() != BB)
    return AngleSelectDisp::NotApplicable;
  if (!Cond->comesBefore(Sel) || !Sel->comesBefore(T))
    return AngleSelectDisp::NotApplicable;
  for (const Instruction *I = Cond->getNextNode(); I && I != T;
       I = I->getNextNode()) {
    const auto *CI = dyn_cast<CallInst>(I);
    if (!CI)
      continue;
    const Function *F = CI->getCalledFunction();
    if (F && F->getName().starts_with("cq_theta_") && CI->arg_size() >= 1 &&
        Taint.Tainted.count(CI->getArgOperand(0)))
      return AngleSelectDisp::NotApplicable;
  }

  // The Rz stem stops here (PRD §12.1 transparency). S8 and S9 below both exist
  // because an in-place `Ry` RELABELS the register's basis; a controlled `Rz` is
  // DIAGONAL, so it moves no basis label at all:
  //   * the flag strip stays valid even when the rotated register IS a condition
  //     register (which is why `q = cq_phi(q, q==5?A:B)` accepts and its
  //     `cq_theta` twin declines — the stem separator);
  //   * a pre-gate SSA record of the register read after the gate denotes the
  //     same computational-basis label, so there is no stale record to fence.
  // NOTE for the reader of a trace: the UNCONDITIONAL `rz(h, B)` this lowering
  // adds is an ordinary USER Rz on a register that may be dead afterwards — bd
  // `wt3l`'s cancel/leak/keep question. 2b does not move that in either
  // direction; the twin emits the identical line.
  if (IsPhi) {
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
  condProvenance(Cond, Taint, Prov);
  SmallPtrSet<Value *, 16> CondRails;
  railWireClosure(Cond, Taint, WireDir::BackwardOnly, nullptr, nullptr,
                  CondRails);
  for (Value *P : Prov)
    railWireClosure(P, Taint, WireDir::BackwardOnly, nullptr, nullptr,
                    CondRails);
  for (Value *W : BaseWireOrder)
    if (CondRails.count(W)) {
      diagnoseUnderControl(Sel, "rotation arm on a condition wire");
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
  // IMMEDIATELY BEFORE `T` (the unconditional twin, then the mint), so nothing
  // lands between a user proven before `T` and the first relabelling gate.
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
      const bool Ok = BaseWire.count(UI) ? cannotFollowGate(UI, T, *DT)
                                         : provablyBefore(UI, T, *DT);
      if (!Ok) {
        diagnoseUnderControl(UI, "stale rail record read past a controlled Ry");
        return AngleSelectDisp::Declined;
      }
    }

  ControlRegion R;
  R.Kind = ControlRegion::AngleSelectRegion;
  R.Merge = Sel;
  R.Condition = Cond;
  R.Shadow.assign(1, T);
  plan.Regions.push_back(R);
  return AngleSelectDisp::Accepted;
}

}  // namespace cq
