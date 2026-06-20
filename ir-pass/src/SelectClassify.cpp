// SelectClassify.cpp — the §0 prove-or-decline ladder for a tainted-condition
// `select` (swap-route 4.4 WI-1; PRD Part IV §16; IMPLEMENTATION-4.4 §3).
//
// Pure analysis — NO IR is mutated (Rule 9). Every gate reads SSA-value
// identities that survive rotation lowering's later RAUW-to-handle: detection
// runs at the pipeline's `detectControlRegions` step (L83), the eventual
// `SelectMergeEmit` runs at `lowerControlRegions` (L84), and rotation lowering
// only at L110 — so the select and its operands still carry their real logical
// types here. See `SelectClassify.h` for the six-gate contract.

#include "SelectClassify.h"

#include "ArmAnalysis.h"     // comparePredLowerable, diagonalAliasHit
#include "ControlPlan.h"     // diagnoseUnderControl, ControlPlan, ControlRegion
#include "OpcodeSupport.h"   // abiWidthFromType
#include "TaintPropagation.h"  // TaintSet

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Type.h"

using namespace llvm;

namespace cq {

namespace {

// TU-local name-prefix predicates (deliberately NOT exported — they collide with
// the same-named anonymous helpers in ArmClassify.cpp / WireWalk.cpp /
// RegionTreeDetect.cpp; ArmAnalysis.h header note).
bool isCallToPrefix(const Value *V, StringRef Prefix) {
  const auto *CI = dyn_cast<CallInst>(V);
  if (!CI)
    return false;
  const Function *F = CI->getCalledFunction();
  return F && F->getName().starts_with(Prefix);
}
bool isPhiCall(const Value *V) { return isCallToPrefix(V, "cq_phi_"); }
bool isThetaCall(const Value *V) { return isCallToPrefix(V, "cq_theta_"); }
bool isRotationCall(const Value *V) { return isPhiCall(V) || isThetaCall(V); }

// GATE 3 (the §3.2 BLOCKER) — does `%sel`'s value reach a rotation's arg-1 ANGLE
// slot through value-preserving carriers? A NEW forward worklist walk: no
// existing helper walks FORWARD from a value to a rotation arg-1
// (`taintedAngleGate` walks arm spines backward; `condProvenance` walks operands
// backward; `findNonDiagonalWireGate` follows arg-0 handle wires). It reuses the
// carrier-set pattern from `WireWalk.cpp:105-113` (PHI/SelectInst value-operand
// routing) and the per-use arg-1 angle predicate from
// `TaintPropagation.cpp:300-303` (`getArgOperand(1)==V && getArgOperand(0)!=V`).
//
// The carriers are exactly the VALUE-PRESERVING subset of the ops
// `declineTaintEscapes` WHITELISTS as benign tainted-value users
// (`isa<CastInst>`/`PHINode`/`SelectInst`, plus — as of Phase-7.1 Increment B —
// `FreezeInst`): `fpext`/`fptrunc`/`bitcast` (value-preserving casts) + nested
// `select`/`phi` + `freeze`. This set need not — and must not — be larger:
//   * `freeze` is a VALUE-PRESERVING carrier (freeze of an already-defined value
//     is identity). Phase-7.1 Increment B makes `declineTaintEscapes` SKIP an
//     FP-typed tainted `freeze` (the integer case is folded as a basis identity)
//     so an `(q>5)?θa:θb`-style angle routed THROUGH a `freeze` no longer hits
//     the blunt kMsgOther backstop — it must reach a rotation arg-1 here and be
//     declined `rotation angle`. Hence the walk MUST cross `freeze`
//     (control_swap_reject_select_freeze.ll, now flipped to the GATE-3 brand,
//     pins exactly this). Omitting it would re-open the FP-angle leak the escape
//     guard no longer catches — a silent miscompile, not dead code. (This
//     supersedes the pre-7.1 "adding `isa<FreezeInst>` would be untestable dead
//     code" note, which was true only while the escape guard still declined every
//     freeze at kMsgOther.)
//   * a value-CHANGING op (arithmetic, an int<->fp domain cast `sitofp`/…) RE-
//     REALIZES the value into a NEW tainted SSA value, which `declineTaintedAngle`
//     (`taint.Tainted.count(arg1)`) catches when it lands in a rotation arg-1 —
//     so those are correctly NOT crossed (crossing them would only change a loud
//     WI-3 decline's string, never prevent a miscompile).
// A nested `select`/`phi` carries `%sel` onward only as a VALUE operand, never as
// the condition (the `CompareLowering.cpp:54-56` discriminator).
//
// The FAN-OUT rule (PRD §16.2): a single arg-1 reach declines the WHOLE select.
// `%sel` may be tainted-as-data AND feed an arg-1 angle at once (the arg-1
// exclusion is per-operand-use, not global), but splitting — merge for the data
// uses, rotate for the angle use — double-realizes the value (a silent
// miscompile). So ANY reach returns true; never split.
bool selReachesRotationArg1(SelectInst *Sel) {
  SmallVector<Value *, 8> Work;
  SmallPtrSet<Value *, 16> Visited;
  Work.push_back(Sel);
  Visited.insert(Sel);
  while (!Work.empty()) {
    Value *U = Work.pop_back_val();
    for (User *X : U->users()) {
      // arg-1 angle reach — the per-use predicate (the angle operand of a
      // cq_phi/cq_theta is classical; a value reaching it as data is the
      // f64/angle miscompile family).
      if (auto *CI = dyn_cast<CallInst>(X))
        if (isRotationCall(CI) && CI->arg_size() >= 2 &&
            CI->getArgOperand(1) == U && CI->getArgOperand(0) != U)
          return true;  // angle — decline the WHOLE select (fan-out rule).

      // value-preserving carriers only (do NOT cross arithmetic/compare).
      // `freeze` is value-preserving (Phase-7.1 Increment B); the escape guard no
      // longer backstops an FP-routed angle through it, so this walk must cross it.
      if (isa<FPExtInst>(X) || isa<FPTruncInst>(X) || isa<BitCastInst>(X) ||
          isa<FreezeInst>(X) || isa<PHINode>(X)) {
        if (Visited.insert(X).second)
          Work.push_back(X);
      } else if (auto *Inner = dyn_cast<SelectInst>(X)) {
        // a nested select carries U onward only as a VALUE operand (true/false),
        // not as the condition — a condition use is not a value-routing edge.
        if (U != Inner->getCondition() && Visited.insert(Inner).second)
          Work.push_back(Inner);
      }
    }
  }
  return false;
}

// GATE 5 (the §16.7 PHASE-CARRIER half — the WI-3 Rule-13 dephasing finding) — is
// the tainted value `Op` ITSELF a relative-phase (Rz) carrier? The controlled-XOR
// copy merge is a CNOT basis copy: it copies a basis LABEL, not a phase (Rule 7),
// so an operand whose backward lineage includes a `cq_phi` (Rz) — a non-basis,
// COMPLEX-phase superposition — is DEPHASED into a wrong %out (the 0.585->0.500
// family; verify-clean-invisible — the adversarial review's confirmed blocker). A
// `cq_theta` (Ry) result is a REAL-amplitude basis superposition (no relative
// phase) and IS the canonical accept, so the backward walk STOPS at theta (its
// operands are the classical seed + angle, untainted). Walks every tainted
// producer backward (the cq_phi arg-0 wire + arithmetic/cast data inputs);
// over-decline-safe (any phi in the lineage declines the whole select).
//
// This is the BACKWARD twin of `hasCoherentDownstreamUse` (which catches an
// operand whose lineage FEEDS a downstream rotation — channel B). Together they
// enforce the §16.7 "decline coherent operands" intent that the forward-only
// proxy alone missed. See [[select-merge-phase-operand-dephasing]].
//
// CROSS-MODULE INVARIANT (WI-5 Rule-13 clearance, the one non-material residual):
// the walk only recurses through `taint.Tainted` operands, so a `cq_phi` on a
// CLASSICAL operand (untainted result) is correctly NOT flagged — it carries no
// real relative phase because `RotationLowering` deletes a classical-operand
// `cq_phi` (Rz on a basis state is unobservable; Rule 3). If classical-`cq_phi`
// handling ever changes (its result becomes tainted, or it stops being deleted),
// this gate must be re-reviewed — a classical phase reaching the basis copy would
// otherwise leak. Holds at HEAD; flagged here per the §8.3 second-review note.
bool operandCarriesPhase(Value *Op, const TaintSet &Taint) {
  SmallVector<Value *, 8> Work;
  SmallPtrSet<Value *, 16> Visited;
  Work.push_back(Op);
  Visited.insert(Op);
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (isPhiCall(V))
      return true;  // an Rz (cq_phi) in the lineage — a relative-phase carrier.
    auto *I = dyn_cast<Instruction>(V);
    if (!I)
      continue;  // an argument / constant root — basis, not a phase.
    for (Value *In : I->operands())
      if (Taint.Tainted.count(In) && Visited.insert(In).second)
        Work.push_back(In);
  }
  return false;
}

// GATE 5 (the §16.7 conservative coherent-operand default, decidable v1 proxy) —
// does a tainted value `Op` have a QUANTUM use beyond this select: a downstream
// rotation (`cq_phi`/`cq_theta`) ON its wire (arg-0) whose interference would
// observe its coherence (the channel-B dephasing case)? Reads by the condition
// `icmp`, the select's own copy, a downstream `cq_measure`, or `ret` do NOT count
// (those are owned by the mint / select / measurement / caller — the §16.5
// operand-disposition matrix). A forward value walk: arithmetic/cast carriers are
// crossed (the operand's coherence is preserved through them) so a downstream
// rotation on a derived value is still caught; the arg-1 angle use is gate 3's
// domain, not gate 5's. Conservative (over-decline-safe) and accepts §15's
// canonical `(q>5)?q:x` / `(q>5)?q:q+1`; the exact coherent-vs-basis boundary is
// the binding Rule-13 clearance item (§8) — re-pin here if it moves.
bool hasCoherentDownstreamUse(Value *Op, SelectInst *Sel, TaintSet &Taint) {
  Value *Cond = Sel->getCondition();
  // The downstream-measurement allowlist is EXACT-MEMBERSHIP against
  // `Taint.MeasureCalls` (the recognized `@cq_measure_<sfx>` call sites), NOT the
  // old `starts_with("cq_measure_") || starts_with("cqrt_measure_")` prefix match
  // — mirrors `proveSwitchDataMux`'s sink test and the G10 scrutinee allowlist
  // (SwitchClassify.cpp). Prefix-on-accept is spoofable: an opaque `cq_measure_evil`
  // would confer false ownership of a live rail. For the `cq_measure_` family the
  // check is EQUIVALENT on reachable inputs: `Op` is ALWAYS tainted (the caller
  // gates on `taint.Tainted.count(Op)`), so `declineTaintEscapes` (L64, pre-
  // detection) has already rejected any unknown-callee `cq_measure_evil`. It is
  // STRICTLY STRICTER on the dropped `cqrt_measure_` arm (whitelisted by the escape
  // guard, so a hand-authored runtime-symbol measure reaches here) — the SAFE
  // over-decline direction; the frontend never emits `cqrt_measure_` pre-detection.
  // Consistency + defense-in-depth (Rule 14).
  SmallPtrSet<const CallInst *, 8> Sinks(Taint.MeasureCalls.begin(),
                                         Taint.MeasureCalls.end());
  SmallVector<Value *, 8> Work;
  SmallPtrSet<Value *, 16> Visited;
  Work.push_back(Op);
  Visited.insert(Op);
  while (!Work.empty()) {
    Value *U = Work.pop_back_val();
    for (User *X : U->users()) {
      if (X == Sel || X == Cond)
        continue;  // the select's own copy / the flag mint — owned.
      if (auto *CI = dyn_cast<CallInst>(X)) {
        if (Sinks.count(CI))
          continue;  // a recognized measurement sink owns the handle.
        if (isRotationCall(CI)) {
          if (CI->arg_size() >= 1 && CI->getArgOperand(0) == U)
            return true;  // a rotation ON the operand's wire — coherent.
          continue;  // arg-1 angle use is gate 3's domain, not coherence here.
        }
        // Any other call: `declineTaintEscapes` (L64, before detection at L83)
        // already declined unknown callees module-wide, so a surviving tainted
        // call user is benign here. (void) — keep scanning the rest.
        continue;
      }
      if (isa<ReturnInst>(X))
        continue;  // escapes via ret — the caller owns the handle.
      // value carrier / arithmetic — keep walking forward to find a rotation.
      if (auto *I = dyn_cast<Instruction>(X))
        if (Visited.insert(I).second)
          Work.push_back(I);
    }
  }
  return false;
}

// GATE 6 (the §16.9 aliasing guard, conservative form) — do the two value
// operands resolve to the SAME post-lowering register? The dangerous alias is
// literal only AFTER rotation lowering RAUWs a `%qd = cq_phi(%q,·)` and its `%q`
// to one i32 handle, which pre-mutation SSA cannot see — so materialize `A`'s
// pre-region `cq_phi` arg-0 diagonal-alias closure and test `B` against it via
// `diagonalAliasHit` (which walks `B`'s own `cq_phi` arg-0 chain). A `Constant`
// operand never aliases a handle. A fresh out-of-place template result (`q+1` → a
// new `cq_template_add` handle distinct from `q`) has a disjoint closure →
// `(q>5)?q:q+1` accepts; the hoisted-in-place family (two `cq_phi`s of one base)
// intersects → decline.
bool operandsAlias(Value *A, Value *B) {
  if (isa<Constant>(A) || isa<Constant>(B))
    return false;  // a classical literal never aliases a quantum handle.
  SmallPtrSet<Value *, 8> Closure;
  for (Value *V = A;;) {
    Closure.insert(V);
    auto *CI = dyn_cast<CallInst>(V);
    if (!CI || !isPhiCall(CI) || CI->arg_size() < 1)
      break;  // the wire origin (theta source / template result / argument).
    V = CI->getArgOperand(0);
  }
  return diagonalAliasHit(B, Closure) != nullptr;  // shared physical wire.
}

}  // namespace

void classifySelectRegion(SelectInst *Sel, TaintSet &taint, ControlPlan &plan) {
  // GATE 1 — entry: only tainted-condition selects are ours. A classical-cond
  // select is `declineClassicalMuxes`'s domain (L96) and stays declined
  // untouched; the caller already guards this, re-checked here defensively.
  if (!taint.Tainted.count(Sel->getCondition()))
    return;  // not ours; leave for declineClassicalMuxes.

  // GATE 2 — lowerable compare condition. A non-`CmpInst` tainted i1 (a compound
  // `&&`/`||`, a `trunc`, …) or an out-of-scope `fcmp` predicate has no flag-mint
  // template; decline generic `control flow` (a select has no straight-through
  // edge, so the §3c clobber proof obligation can never be met — never brand it
  // `control condition has no template`/clobber; IMPLEMENTATION-4.4 §0).
  auto *Cond = dyn_cast<CmpInst>(Sel->getCondition());
  if (!Cond || !comparePredLowerable(Cond))
    return diagnoseUnderControl(Sel, "control flow");

  // GATE 2b — HL-only flag mint. A Q+Q condition (BOTH compare operands tainted,
  // e.g. `icmp sgt %q, %y`) has no flag-mint template — `lowerCompareToFlag` is
  // HL-only (handle + literal). Decline HERE in the CONTROL dialect rather than
  // let `emitSelectRegion`'s step-1 mint reach the data-path `no template` bail
  // (the message would mis-brand as a straight-line lowering failure — WI-3
  // adversarial review NIT). Over-decline-safe; a Q+Q select condition is out of
  // scope this increment regardless.
  if (Cond->getNumOperands() >= 2 && taint.Tainted.count(Cond->getOperand(0)) &&
      taint.Tainted.count(Cond->getOperand(1)))
    return diagnoseUnderControl(Sel, "control flow");

  // GATE 3 — the §3.2 BLOCKER: NOT an angle. FIRST among the type gates (the
  // FP-use fence precedes the width gate, exactly as ArmClassify.cpp:820 precedes
  // :834). There is NO downstream backstop, so the angle MUST be caught here.
  if (selReachesRotationArg1(Sel))
    return diagnoseUnderControl(Sel, "rotation angle");

  // GATE 4 — ABI-width scalar-integer result (§16.9), AFTER the FP-use fence.
  // Rejects fp-as-DATA (staged out, §16.4) + integer vector / i128 / pointer /
  // aggregate (empty width — the null-callee trap). Necessary-not-sufficient;
  // NEVER key the decision on `abiWidthFromType` alone (f64 has a valid width yet
  // is an angle — caught above). `isFPOrFPVectorTy`, not the scalar-only
  // `isFloatingPointTy` (which misses `<2 x double>`).
  Type *T = Sel->getType();
  if (T->isFPOrFPVectorTy() || !T->isIntegerTy() || abiWidthFromType(T).empty())
    return diagnoseUnderControl(Sel, "control flow");

  // GATE 5 — conservative coherent-operand default (§16.7), BOTH halves. A
  // tainted value operand is declined if it (a) IS itself a relative-phase (Rz)
  // carrier — `operandCarriesPhase`, the WI-3 dephasing finding — or (b) FEEDS a
  // downstream rotation beyond the select — `hasCoherentDownstreamUse`, channel B.
  // Either makes the basis CNOT-copy merge produce a wrong/dephased %out. Declined
  // until the §8 Rule-13 clearance widens this.
  for (Value *Op : {Sel->getTrueValue(), Sel->getFalseValue()})
    if (taint.Tainted.count(Op) &&
        (operandCarriesPhase(Op, taint) ||
         hasCoherentDownstreamUse(Op, Sel, taint)))
      return diagnoseUnderControl(Sel, "control flow");

  // GATE 6 — distinct operands / aliasing guard (§16.9). The two operands must
  // resolve to provably-disjoint post-lowering registers.
  if (operandsAlias(Sel->getTrueValue(), Sel->getFalseValue()))
    return diagnoseUnderControl(Sel, "control flow");

  // ACCEPT — all six gates pass. Push a `SelectRegion` for `SelectMergeEmit`
  // (WI-3, dispatched from `lowerControlRegions` on `Kind==SelectRegion`). No
  // `ControlPlan` field is added: `Kind::SelectRegion` + the `Instruction* Merge`
  // slot already hold a `SelectInst`, and the emitter reads `TrueValue`/
  // `FalseValue` off `cast<SelectInst>(R.Merge)` and the width off
  // `abiWidthFromType(Sel->getType())` (valid at emit time — L84 precedes
  // rotation lowering at L110). The block/depth fields stay null (a select has no
  // CFG diamond), which makes it inert to the cross-region pre-flight.
  ControlRegion R;
  R.Kind = ControlRegion::SelectRegion;
  R.Merge = Sel;  // a SelectInst fits the Instruction* Merge slot.
  R.Condition = Sel->getCondition();
  plan.Regions.push_back(R);
}

}  // namespace cq
