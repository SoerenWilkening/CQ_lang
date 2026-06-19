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
#include "ControlPlan.h"
#include "EqFoldArm.h"
#include "OpcodeSupport.h"
#include "TaintPropagation.h"
#include "WireWalk.h"

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
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
    return CI->arg_size() >= 2 && Taint.Tainted.count(CI->getArgOperand(1));
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
// `WireWalk::findNonDiagonalWireGate` (Rule 14). This caller is the
// POSITION-FREE mode: the flag is minted at the BRANCH, a point unrelated to
// the compare's own schedule, so no positional accept is possible here — any
// theta on the wire declines.
bool wireGainsNonDiagonalGate(const SmallPtrSetImpl<Value *> &Prov) {
  SmallVector<Value *, 16> Seeds(Prov.begin(), Prov.end());
  return findNonDiagonalWireGate(Seeds, /*CrossValueRouting=*/false) !=
         nullptr;
}

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
bool nonDiagonalGateBeforeBranch(const ControlRegion &R, TaintSet &Taint,
                                 const SmallPtrSetImpl<Value *> &Prov) {
  auto *Cond = dyn_cast_or_null<Instruction>(R.Condition);
  if (!Cond || !R.Pred)
    return true;  // cannot reason about the gap — decline (Prime Directive).
  if (Cond->getParent() != R.Pred)
    return true;  // unbounded gap across blocks — conservative decline.
  if (wireGainsNonDiagonalGate(Prov))
    return true;  // chained Ry on the condition's wire, schedule-independent.
  const Instruction *BI = R.Pred->getTerminator();
  for (const Instruction *I = Cond->getNextNode(); I && I != BI;
       I = I->getNextNode()) {
    const auto *CI = dyn_cast<CallInst>(I);
    if (!CI)
      continue;
    const Function *F = CI->getCalledFunction();
    if (F && F->getName().starts_with("cq_theta_") && CI->arg_size() >= 1 &&
        Taint.Tainted.count(CI->getArgOperand(0)))
      return true;  // chained Ry on a live handle after the compare.
  }
  return false;
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
    // LOWERABLE: an out-of-scope fcmp predicate (outside {oeq,une,olt,ogt,ole,
    // oge}) has no template, so `lowerOps`/`rewriteCompare` would mint a
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

ArmDisposition classifyArms(ControlRegion &Region, TaintSet &Taint) {
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
  // predicate (outside {oeq,une,olt,ogt,ole,oge}) has no template, so the mint
  // would emit a non-existent symbol. SwapRouteEmit's flag-null bail catches it
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
  // stripped. Decline (see nonDiagonalGateBeforeBranch).
  if (nonDiagonalGateBeforeBranch(Region, Taint, Prov)) {
    diagnoseUnderControl(declAnchor(Region),
                         "condition predates a non-diagonal gate");
    return ArmDisposition::Declined;
  }

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

  for (BasicBlock *ArmBB : Arms) {
    if (MergePhi->getBasicBlockIndex(ArmBB) < 0) {
      // Arm block does not feed the merge phi — off-pattern shape.
      diagnoseUnderControl(declAnchor(Region), "control flow");
      return ArmDisposition::Declined;
    }
    Value *ArmIncoming = MergePhi->getIncomingValueForBlock(ArmBB);
    Value *Base = walkPhaseSpine(ArmIncoming, ArmBB);

    // Every angle on the arm spine (and a derived base's own angle) must be
    // CLASSICAL — quantum-derived data in the angle slot has no fixed unitary
    // and the emitter would replay it as a handle tag (see taintedAngleGate; the
    // §8 adversarial probe family for test_C_libtooling-9hh).
    if (CallInst *Bad = taintedAngleGate(ArmIncoming, ArmBB, Base, Taint)) {
      diagnoseUnderControl(Bad, "rotation angle");
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
      if (SawValueArm) {
        diagnoseUnderControl(declAnchor(Region), "mixed phase/value arm");
        return ArmDisposition::Declined;
      }
      if (!Taint.Tainted.count(Base)) {
        diagnoseUnderControl(declAnchor(Region), "control flow");
        return ArmDisposition::Declined;
      }
      if (!armBlockIsPureSpine(ArmBB, ArmIncoming)) {
        diagnoseUnderControl(declAnchor(Region), "impure phase arm");
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
      SawPhaseArm = true;
      continue;
    }

    // If/else first arm: anchor the routed handle on a LEAF spine base (a value
    // op as the first arm's base is a value arm, handled below).
    if (!Routed && !isValueChangingOp(Base)) {
      if (!Taint.Tainted.count(Base)) {
        diagnoseUnderControl(declAnchor(Region), "control flow");
        return ArmDisposition::Declined;
      }
      if (!armBlockIsPureSpine(ArmBB, ArmIncoming)) {
        diagnoseUnderControl(declAnchor(Region), "impure phase arm");
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
        diagnoseUnderControl(Chain.MixedPhi, "mixed phase/value arm");
        return ArmDisposition::Declined;
      }

      if (!Chain.Ops.empty()) {
        // Heterogeneous if/else: a value arm beside an already-classified
        // phase arm (the converse guard sits on the phase path above).
        if (SawPhaseArm) {
          diagnoseUnderControl(declAnchor(Region), "mixed phase/value arm");
          return ArmDisposition::Declined;
        }
        // An FP-typed merge under tainted control is categorically an ANGLE,
        // never routable data — even though f64 has a valid ABI width (the
        // f64 silent-miscompile family; PRD §8.1). isFPOrFPVectorTy, not the
        // scalar-only isFloatingPointTy (which misses <2 x double>).
        if (MergePhi->getType()->isFPOrFPVectorTy()) {
          diagnoseUnderControl(declAnchor(Region), "control flow");
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
        if (!MergePhi->getType()->isIntegerTy() ||
            abiWidthFromType(MergePhi->getType()).empty()) {
          diagnoseUnderControl(declAnchor(Region), "control flow");
          return ArmDisposition::Declined;
        }
        // The chain must bottom OUTSIDE the arm (at the live routed register
        // in the pred); an in-arm bottoming value (a cast, an unsupported or
        // untainted op under the chain) is a broken lineage.
        if (auto *BaseInst = dyn_cast<Instruction>(Chain.Base);
            BaseInst && BaseInst->getParent() == ArmBB) {
          diagnoseUnderControl(declAnchor(Region), "control flow");
          return ArmDisposition::Declined;
        }
        // Base-identity — THE DEFECT-2 FIX (PRD §8.3): a chain that bottoms
        // anywhere but the routed slot is a data MUX of independently-derived
        // values (`t=q+7; if(q>5) t=q+3` — Defect-2; `if(q>5){p=q+1}` — the
        // condition READ). Replaying such a chain on the routed rail would
        // compute f(routed), not the source's f(base): a verify-clean wrong
        // unitary. Not routable, not a §3c clobber (the condition register is
        // never overwritten) — the 4.4 select-family mux, declined generic.
        if (Routed) {
          if (Chain.Base != Routed) {
            diagnoseUnderControl(declAnchor(Region), "control flow");
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
            diagnoseUnderControl(Chain.Ops.front(),
                                 "arm rewrites a condition operand");
          } else {
            diagnoseUnderControl(declAnchor(Region), "control flow");
          }
          return ArmDisposition::Declined;
        }
        // Criterion 3: the routed slot must be a tainted quantum register.
        if (!Taint.Tainted.count(Routed)) {
          diagnoseUnderControl(declAnchor(Region), "control flow");
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
        if (CallInst *Gate = findNonDiagonalWireGate(
                Routed, /*CrossValueRouting=*/false)) {
          diagnoseUnderControl(Gate,
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
          diagnoseUnderControl(BaseCI, "rotation angle");
          return ArmDisposition::Declined;
        }
        // Rule 8 linearity + self-contained arm block (fan-out / stray op /
        // DAG sibling — see valueArmIsPureChain).
        if (!valueArmIsPureChain(ArmBB, Chain.Ops, MergePhi)) {
          diagnoseUnderControl(declAnchor(Region), "impure value arm");
          return ArmDisposition::Declined;
        }
        // A Q+Q link (second tainted operand) is a recognized value shape the
        // routed replay does not yet handle — defer with the 4.2 string.
        if (Chain.HasQQ) {
          diagnoseUnderControl(Chain.Ops.front(), "value-arm swap-route");
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
      diagnoseUnderControl(BaseInst, "mixed phase/value arm");
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
      diagnoseUnderControl(cast<Instruction>(Base),
                           Clobber ? "arm rewrites a condition operand"
                                   : "value-arm swap-route");
      return ArmDisposition::Declined;
    }

    // A leaf base that is NOT the routed handle: a cross-handle multiplexer or a
    // fresh quantum source muxed against the routed slot — not a phase arm over
    // the routed handle. Decline (over-decline is safe; Prime Directive).
    diagnoseUnderControl(declAnchor(Region), "control flow");
    return ArmDisposition::Declined;
  }

  // Both staged flips are in (IMPLEMENTATION-4.2 §7): a value DIAMOND (WI-4)
  // and a two-arm value IF/ELSE (WI-5) both reach the §4 emitter, which reads
  // the recorded ClassArm/ClassArmFalse + Shadow/ShadowFalse. Homogeneity is
  // already proven here: a surviving two-arm region is either all-phase or
  // all-value over ONE shared routed base (the mixed declines above), and an
  // if/else second chain bottoming anywhere but the first arm's anchored base
  // declined `control flow` (base-identity).
  return ArmDisposition::Accept;
}

// 6.5 — recognize the §2.13 classical-call-under-control shape (DD-7). Pure SSA
// analysis, before any mutation (Rule 9). See ArmClassify.h for the disposition
// contract. This runs BEFORE `classifyArms`: a positive match short-circuits the
// phase/value classifier (whose `isValueChangingOp(call)`-true path would
// otherwise decline the same shape as a §3c clobber — a safe over-decline, but
// not the 6.5 lowering).
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

  // PURITY (§2.13 / WI-5.4): the unconditional hoist into `Pred` is observationally
  // inert ONLY for a side-effect-free, memory-independent, will-return callee.
  // `doesNotAccessMemory()` (readnone) makes the result depend solely on its args;
  // `!mayHaveSideEffects()` adds nounwind + willreturn (no throw, no infinite loop).
  // A readonly / writing / throwing / non-returning callee DECLINES (over-decline
  // is safe; the rejection set is load-bearing for the inert-hoist claim).
  if (!Call->doesNotAccessMemory() || Call->mayHaveSideEffects()) {
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

  // ACCEPT — the route-merged classical-call arm (the fp/i128 RESULT gate is the
  // emitter's `copyControlledFn` non-null check, DD-7). The emitter re-derives the
  // call as the `Arm`-edge merge incoming (a pure consumer of the plan).
  Region.Kind = ControlRegion::ClassicalCallArm;
  return ClassicalCallDisp::Accept;
}

}  // namespace cq
