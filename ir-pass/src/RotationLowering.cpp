// RotationLowering.cpp — Lower tainted `@cq_theta_<sfx>` / `@cq_phi_<sfx>`
// rotations to runtime calls. See header for the contract; backend.md §5.1
// for the operand-dispatch table and IMPLEMENTATION.md §1 for the
// cross-type-RAUW invariant.
//
// Single pass over the already-collected work lists (`taint.ThetaCalls`,
// `taint.PhiCalls` — populated by `propagate`); no module re-walk.

#include "RotationLowering.h"

#include "ControlPlan.h"
#include "ControlledSymbols.h"
#include "OpcodeSupport.h"  // abiWidthFromType
#include "TaintPropagation.h"
#include "WidthDispatch.h"
#include "WireWalk.h"  // provablyBefore (the shared position-aware proof)

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

#include <optional>
#include <string>
#include <vector>

using namespace llvm;

namespace cq {

namespace {

// Strip a known prefix (`cq_theta_` / `cq_phi_`) from the call's callee
// name → suffix (`si32`). Returns "" on mismatch (callee absent or name
// doesn't start with the prefix).
StringRef suffixFromName(const CallInst *CI, StringRef Prefix) {
  Function *Callee = CI->getCalledFunction();
  if (!Callee)
    return {};
  StringRef N = Callee->getName();
  if (!N.starts_with(Prefix))
    return {};
  return N.substr(Prefix.size());
}

// "Unsupported rotation" diagnostic — mirrors MeasureLowering's surface so
// the pass speaks one diagnostic dialect. Failure is loud, not silent: the
// offending call is left in place to surface at the verifier. The call's
// `!dbg` is attached so the rejection is source-located (same surface as
// `diagnoseUnderControl`).
void diagnoseUnsupported(CallInst *CI, const char *What) {
  std::string Msg = std::string("cq rotation lowering: unsupported ") + What;
  CI->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *CI->getFunction(), Msg, CI->getDebugLoc()));
}

// Straight-line tainted-ANGLE gate (test_C_libtooling-659): quantum-derived
// data in a rotation's arg-1 ANGLE slot has NO fixed unitary — angle =
// f(quantum value), value in superposition — so there is nothing correct to
// emit. The taint discipline keeps the angle operand classical PER-USE (taint
// never propagates THROUGH an arg-1 edge, Rule 3), but the angle VALUE itself
// is tainted when derived from a handle elsewhere (`sitofp(%q)`, `ext(%q)`).
// Two loud-but-wrong outcomes without this guard, both found by the
// test_C_libtooling-9hh §8 adversarial clearance (2026-06-10):
//   (a) cast family — CastLowering cross-type-RAUWs the f64 cast result to an
//       i32 handle inside the already-emitted `cqrt_rz`/`cqrt_ry`, which is
//       FINAL (never erased): Broken module, opt exit 134;
//   (b) opaque-call family — `%ang = call double @ext(i32 %q)` survives
//       well-typed and, after the RAUW-to-handle, reads the i32 RUNTIME
//       HANDLE TAG: a verify-clean silent miscompile.
// The region-level twin is ArmClassify::taintedAngleGate (arms/derived base);
// this is the straight-line root fix: decline loudly BEFORE any emission.
// Returns true (and diagnoses) iff the rotation's angle is tainted.
bool declineTaintedAngle(CallInst *Rot, const TaintSet &taint) {
  if (Rot->arg_size() < 2 || !taint.Tainted.count(Rot->getArgOperand(1)))
    return false;
  diagnoseUnsupported(Rot, "quantum-derived rotation angle");
  return true;
}

// Frozen-quantum-wire guard (test_C_libtooling-4i7r): a tainted `FreezeInst`
// whose result type is NOT `i32` is UN-LAUNDERABLE. The runtime handle is
// ALWAYS i32 (Rule 15); every lowering path RAUWs a tainted quantum value to a
// `cqrt_alloc_*` / `cq_template_*` i32 handle — but a `freeze` is NEVER erased
// by any stage (`declineTaintEscapes` SKIPS an fp freeze so it can ride the
// GATE-3 angle fence; it is never folded). So once the wire under it is
// RAUW'd, `%f = freeze <fp> %handle` is ill-typed AND any `cqrt_*`/`cq_template_*`
// call reading `%f` gets an fp value in an i32 handle slot. With no
// measure/uncompute owner (a dead sibling while the wire is measured/escaped
// elsewhere) NOTHING declines it and `opt` ABORTS on the broken module
// (SIGABRT 134, "Call parameter type does not match function signature")
// instead of the house decline — a crash on VALID input (Rule 1). Scan and
// decline BEFORE the first RAUW so every freeze stays well-typed and `opt`
// exits with the source-located diagnostic, never a crash.
//
// COMPLETENESS: a tainted value derives (transitively) from a `@cq_theta`
// result — the sole taint source — whose lowering yields an i32 handle, so a
// tainted freeze at a non-i32 result type is invariably inconsistent with that
// i32 handle and cannot be lowered. An i32 tainted freeze self-launders
// (`freeze i32 %handle` is well-typed) and is not flagged; a non-i32 INTEGER
// freeze is already declined upstream at `declineTaintEscapes` (kMsgOther, the
// non-foldable `freezeResultWouldEscape` path) so in practice only fp freezes
// reach here — the `!isIntegerTy(32)` test is defensively complete for any
// non-i32 remnant. A CLASSICAL freeze (untainted) is left untouched (its
// operand keeps its own type across every RAUW).
//
// FIXTURE INVARIANT: the SELECT-mediated fp-freeze spellings decline EARLIER at
// `detectControlRegions` (which runs strictly before `lowerRotations`) — the
// kjd1 operand/condition fences (`taintedLineageHasFreeze` + the
// condition-provenance `FreezeInst` scan) and the GATE-3 angle walk
// (`selReachesRotationArg1`) — so this guard NEVER fires on those four fixtures
// (`control_swap_reject_select_fp_freeze_{operand,cond}.ll`,
// `control_swap_reject_select_freeze.ll`,
// `control_swap_reject_freeze_phi_angle.ll`); it owns ONLY the straight-line
// frozen-wire shape the detection fences never see. Walk in BB order for a
// deterministic, source-located first report (the DS_Error diagnose exits).
bool declineFrozenWire(Module &M, const TaintSet &taint) {
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *FI = dyn_cast<FreezeInst>(&I))
          if (taint.Tainted.count(FI) && !FI->getType()->isIntegerTy(32)) {
            F.getContext().diagnose(DiagnosticInfoUnsupported(
                F,
                "cq rotation lowering: unsupported frozen quantum wire",
                FI->getDebugLoc()));
            return true;
          }
  }
  return false;
}

}  // namespace

bool emitRz(CallInst *Phi, Value *Handle, Value *Angle, WidthDispatch &wd,
            bool controlled, Value *Flag,
            SmallPtrSetImpl<const CallInst *> *Rec) {
  StringRef Sfx = suffixFromName(Phi, "cq_phi_");
  StringRef Abi = wd.abiWidthFor(Sfx);
  IRBuilder<> Builder(Phi);
  if (!controlled) {
    // Uncontrolled gate body: `cqrt_rz_<W>(handle, angle)`.
    FunctionCallee Rz = Abi.empty() ? FunctionCallee() : wd.rzRtFn(Abi);
    if (!Rz) {
      diagnoseUnsupported(Phi, "phi suffix/width");
      return false;  // leave the phi in place for the verifier.
    }
    CallInst *RzCall = Builder.CreateCall(Rz, {Handle, Angle});
    if (DebugLoc DL = Phi->getDebugLoc())
      RzCall->setDebugLoc(DL);
    // M-A Inc 1: a USER `cq_phi` gate. Recorded so the late live-record guard
    // does not read it as the spine's negated-angle adjoint Rz (textually the
    // same call) — see TaintSet::UserPhaseRotations.
    if (Rec)
      Rec->insert(RzCall);
    return true;
  }
  // Controlled gate body: `cqrt_rz_<W>_controlled(flag, handle, angle)`, the
  // i32 control flag prepended as arg 0 (PRD §1.2).
  ControlledSymbols csyms(*Phi->getModule(), wd);
  FunctionCallee Rz =
      Abi.empty() ? FunctionCallee() : csyms.controlledRotationFn(Abi);
  if (!Rz) {
    diagnoseUnsupported(Phi, "controlled phi suffix/width");
    return false;
  }
  CallInst *RzCall = Builder.CreateCall(Rz, {Flag, Handle, Angle});
  if (DebugLoc DL = Phi->getDebugLoc())
    RzCall->setDebugLoc(DL);
  return true;
}

void lowerRotations(Module &M, WidthDispatch &wd, TaintSet &taint,
                    const ControlPlan *plan) {
  if (taint.ThetaCalls.empty() && taint.PhiCalls.empty())
    return;

  // Frozen-quantum-wire guard (test_C_libtooling-4i7r): decline any tainted
  // non-i32 `freeze` BEFORE the cross-type RAUW-to-handle below breaks it into a
  // verify-clean-invisible SIGABRT. See `declineFrozenWire` for the invariant.
  // The DS_Error diagnose exits `opt` non-zero; return is a belt-and-braces
  // "lower nothing" for any future non-exiting diagnostic handler.
  if (declineFrozenWire(M, taint))
    return;

  IRBuilder<> Builder(wd.context());
  std::vector<Instruction *> ToErase;

  // --- THETA. Iterate in collection (BB) order. Forward order matters: a
  // chained theta N+1 takes theta N's result as its operand, and lowering
  // theta N RAUWs that result to the handle — so when we re-read theta
  // N+1's operand it is already the handle (tainted), routing it to the
  // ry-only path with no second allocation.
  for (CallInst *Theta : taint.ThetaCalls) {
    StringRef Sfx = suffixFromName(Theta, "cq_theta_");
    StringRef Abi = wd.abiWidthFor(Sfx);
    FunctionCallee Ry = Abi.empty() ? FunctionCallee() : wd.ryRtFn(Abi);
    if (!Ry) {
      diagnoseUnsupported(Theta, "theta suffix/width");
      continue;
    }
    Value *Op = Theta->getArgOperand(0);  // re-read: RAUW may have updated it
    Value *Angle = Theta->getArgOperand(1);
    // Quantum-derived angle → loud decline BEFORE any emission (no alloc, no
    // ry); the theta is left standing (test_C_libtooling-659).
    if (declineTaintedAngle(Theta, taint))
      continue;
    Builder.SetInsertPoint(Theta);

    Value *Handle;
    const bool Chained = taint.Tainted.count(Op) != 0;
    if (Chained) {
      // Tainted operand (chained theta) → ry only on the existing handle.
      Handle = Op;
    } else {
      // Classical operand → mint a fresh handle, then ry on it.
      FunctionCallee Alloc = wd.allocFn(Abi);
      CallInst *H = Builder.CreateCall(Alloc, {Op}, "h");
      if (DebugLoc DL = Theta->getDebugLoc())
        H->setDebugLoc(DL);
      Handle = H;
      taint.Tainted.insert(H);
      taint.BirthOrder[H] = taint.NextBirth++;  // BB-order seed → stable Q+Q
      // §5.6: record the handle's LOGICAL width from the classical `cq_theta`
      // operand, on the freshly minted i32 handle, BEFORE the RAUW below
      // launders the theta result's type away. Read later when building a Q+Q
      // control condition (PRD §2.4), where both operands are i32 handles.
      // `abiWidthFromType` returns a stable StringRef literal (no storage
      // lifetime concern).
      taint.HandleWidth[H] = abiWidthFromType(Op->getType());
    }

    CallInst *RyCall = Builder.CreateCall(Ry, {Handle, Angle});
    if (DebugLoc DL = Theta->getDebugLoc())
      RyCall->setDebugLoc(DL);
    // M-A Inc 1 (bd test_C_libtooling-6uqc). Record the gate we just minted, and
    // which KIND of user theta minted it. This is THE fact the late live-record
    // guard cannot recover from the lowered text: the spine's adjoint
    // `cqrt_ry(h, -θ)` is textually indistinguishable from a user's chained
    // theta, and the Inc-0 census's angle-pairing heuristic for telling them
    // apart measured wrong in both directions (SPIKE §1.4 blind spot A8). Only
    // this stage knows, because only this stage lowers `@cq_theta`.
    (Chained ? taint.UserChainedRotations : taint.UserSourceRotations)
        .insert(RyCall);

    // RAUW to the HANDLE (i32) — never to the void ry call (§1, PRD §2.5).
    // The handle's i32 type may differ from the theta result's type; that
    // mismatch is transient and laundered by erasure of the tainted users.
    Theta->replaceAllUsesWith(Handle);
    ToErase.push_back(Theta);
  }

  // --- PHI. Iterate in collection order (collected regardless of taint).
  for (CallInst *Phi : taint.PhiCalls) {
    // `plan->InShadow` names cq_phi gate bodies a control emitter handles
    // itself (so they must NOT be lowered here). For the 4.1 swap-route emitter
    // (`SwapRouteEmit::lowerControlRegions`) this set is EMPTY: that emitter runs
    // BEFORE this pass and ERASES each arm cq_phi (scrubbing it from
    // taint.PhiCalls), so an in-shadow phi never reaches this loop. The guard is
    // retained for forward control work that keeps gate bodies in place (the
    // §6a control-in-place peephole).
    if (plan && plan->InShadow.count(Phi))
      continue;
    Value *Op = Phi->getArgOperand(0);
    Value *Angle = Phi->getArgOperand(1);
    // Quantum-derived angle → loud decline BEFORE any emission, on the
    // classical-operand path too (deleting an Rz whose angle is entangled
    // data would silently drop a quantum-dependent operation; over-declining
    // is safe). The phi is left standing (test_C_libtooling-659).
    if (declineTaintedAngle(Phi, taint))
      continue;
    if (taint.Tainted.count(Op)) {
      // Tainted operand → emit uncontrolled rz on the handle. A failed emit
      // (unsupported width) leaves the phi standing for the verifier — do not
      // erase it.
      if (!emitRz(Phi, Op, Angle, wd, /*controlled=*/false, /*flag=*/nullptr,
                  &taint.UserPhaseRotations))
        continue;
    }
    // Classical operand → no rz (Rz on a basis state is unobservable,
    // PRD §4.1). RAUW the phi result to its operand either way (the
    // quantum value is unchanged at the handle level), then erase.
    Phi->replaceAllUsesWith(Op);
    ToErase.push_back(Phi);
  }

  for (Instruction *I : ToErase)
    I->eraseFromParent();
}


// ── M-A Increment 1 — the LATE live-record guard (bd test_C_libtooling-6uqc) ──
//
// See RotationLowering.h for the ruled predicate, the descendant-only scope, and
// why this runs post-`uncompute`. The implementation notes that do not belong in
// a header:
//
// EVERY POINTER IN THE RECORDED SETS IS STILL VALID HERE, and that is a checked
// property, not an assumption: no stage between `lowerRotations` and this slot
// erases an emitted rotation. `lowerOps` erases the ORIGINAL tainted IR ops (it
// never touches the calls it minted), `lowerMeasures` erases `@cq_measure_*`,
// `lowerBreakReversePlay` erases one branch terminator, and `uncompute` only
// emits. The set is nonetheless consulted ONLY by membership while walking the
// LIVE instruction list (the `StaleDeclined` idiom) — a recorded pointer is never
// dereferenced — and each candidate is re-checked to be a 2-arg `cqrt_ry_*` call,
// so even a hypothetical address reuse cannot manufacture a site.
namespace {

// Rule-12 mirror, character-for-character:
//   * lowering_reject_live_record_derived_cond_theta.ll   (bd 6uqc's own P4 shape)
//   * lowering_reject_live_record_two_hop.ll              (a dead INTERIOR record)
//   * lowering_reject_live_record_qram_load.ll            (a `cqrt_qram_load_` record)
//   * lowering_reject_live_record_spine_only_use.ll       (post-T mention is an
//       `_unc` READ of a DIFFERENT rail — the spine-aware reading's defining case)
//   * lowering_reject_live_record_sibling_alias.ll        (record off the `cq_phi`
//       sibling name of the wire)
//   * lowering_reject_live_record_router_phi.ll           (record behind the bd
//       tayx one-register router phi)
//   * lowering_reject_live_record_clone_call_hop.ll       (the record sits behind
//       a Phase-6 `__cq_q_*` clone call — the F1 severance)
//   * lowering_reject_live_record_unreachable_use.ll      (the post-gate data use
//       is in an unreachable block — the F3 vacuous exemption)
//   * lowering_reject_live_record_dead_compare_flag.ll    (per-RECORD exemption:
//       a live measured zext does not rescue its dead i1 sibling — a deliberate
//       over-decline, the M-B customer; see the fixture's physics paragraph)
//   * lowering_reject_live_record_qram_borrowed_index_xor.ll (a KNOWN, DELIBERATE
//       over-decline: the dephasing at the gate provably cancels in that module)
// ACCEPT controls, each pinning a clause this change must NOT widen:
//   * lowering_stale_record_add_before_theta.ll  }  clause 3 — the ruled LIVE
//   * lowering_stale_record_alias_before_theta.ll}  record boundary (pre-existing)
//   * lowering_live_record_discharged_before_theta.ll   clause 2
//   * lowering_live_record_measured_before_theta.ll     clause 4
//   * lowering_live_record_source_theta_accept.ll       source thetas are not sites
//   * lowering_live_record_clone_call_measured_accept.ll  the clone hop must not
//       turn every clone-calling program into a decline
//   * lowering_qram_array_record_chained_theta_accept.ll the RULED-DEFERRED
//       QRAM-array record class
//   * lowering_reject_live_record_post_theta_user_rz.ll  the RULED F2 boundary
//       (2026-08-28): a bare post-gate user rotation is a liveness NON-use, so
//       the record stays dead and declines — read its header before touching
//       `isTeardownUse`'s rotation arm or the clause-3 loop
//   * lowering_live_record_region_owner_probe.ll         an earlier stage still
//       owns its own message; this guard re-owns none
//   * lowering_live_record_clone_return_rail_accept.ll   the MEASURED RESIDUAL
//       over-accept (copy-destination severance class, ruled-deferred to Inc 3;
//       see the SCOPE note above and bd 6uqc)
constexpr char kMsgLiveRecord[] =
    "cq rotation lowering: non-diagonal gate over a live derived record";

// The called OPERAND's own name, never `getCalledFunction()` — the bd xy9n
// lesson (LiteralIntegrity.cpp): `getOrInsertFunction` may resolve to a
// `GlobalAlias`, for which `getCalledFunction()` is null and every name test
// silently fails open.
StringRef emittedCalleeName(const CallInst *CI) {
  const auto *GV = dyn_cast_or_null<GlobalValue>(CI->getCalledOperand());
  return GV ? GV->getName() : StringRef();
}

// A RECORD PRODUCER mints a FRESH rail holding a basis function of its operands:
// the `cq_template_*` data/compare/cast family and the 7.5 `cqrt_qram_load_*`
// (a Toffoli copy-out). Clause 1 of the ruled predicate names exactly these two.
//
// DELIBERATELY NOT PRODUCERS, each for its own reason:
//   * `cqrt_alloc_*` — an ANCESTOR-class rail (bd nepx's `h0`). Inc 3.
//   * `cqrt_qram_alloc_*` — the QRAM ARRAY record class, RULED DEFERRED for this
//     increment (owner 2026-08-27 (4)); pinned by
//     lowering_qram_array_record_chained_theta_accept.ll.
//   * `cqrt_tape_write_*` — an OUTPUT sink's kept entry (`taint.OutputRails`),
//     never a scratch record.
//   * anything VOID (`cqrt_qram_store_*`, the route/copy gates, the rotations) —
//     an in-place mutation mints no rail at all.
//   * the `_unc` / `_inv` twins — adjoints, not forward producers.
//
// ── THE SEVERANCE CLASSES: WHAT THIS WALK STILL CANNOT SEE ───────────────────
//
// A production that mints a basis record of the wire through a VOID writer into
// an ALLOC-MINTED destination is invisible to a producer-edge walk, because
// there is no producer edge to follow: the record's SSA value comes from
// `cqrt_alloc_<W>`, whose only operand is a classical seed. The complete list at
// this increment, so the next reader does not have to re-derive it —
//
//   1. `cqrt_copy_<W>(src, out)` DESTINATIONS. The Phase-4 method-B value-arm
//      answer rail, and a Phase-6 clone's Bennett return (`cqq.out`). `out` holds
//      a basis copy of `src`, which is a record of the wire by every part of
//      clause 1 except the edge that would let us find it.
//   2. SELECT-MERGE out rails (4.4) and SWITCH DATA-MUX out rails (4.5) — the
//      `cqrt_copy_<W>_controlled` destinations, same shape as (1).
//   3. VALUE-ARM MERGE outs — the register a routed value arm copies its answer
//      into, again alloc-minted and written by a void gate.
//   4. `cqrt_qram_store_<W>` ARRAY CELLS — the RULED-DEFERRED array class
//      (owner 2026-08-27 (4)), pinned by
//      lowering_qram_array_record_chained_theta_accept.ll.
//
// REACHABILITY, MEASURED PER CLASS — do NOT read the list as uniformly masked:
//
//   * (2) and (3) ARE masked today, by an unrelated guard. Both need a chained
//     `cq_theta` on the wire AFTER a tainted-condition region, and bd
//     test_C_libtooling-lom0's position-free `nonDiagonalGateBeforeBranch`
//     over-decline rejects every such program at `ArmClassify` with
//     "condition predates a non-diagonal gate under quantum control" — long
//     before this slot. Measured on the two natural C spellings (a tainted
//     `?:` data mux, and a value-arm `if`, each followed by a chained theta).
//     The masking is INCIDENTAL: a different guard declining for a different
//     reason, and lom0 is an OPEN P1 whose whole purpose is to be LIFTED.
//     **INCREMENT 4 MUST RE-CLOSE (2) AND (3) BEFORE IT LIFTS THAT DECLINE**, or
//     lifting turns an unreachable severance into a reachable over-accept — the
//     exact F1 defect, which was measured rather than hypothesized.
//
//   * (1) IS **NOT** MASKED. Its clone-return sub-case is REACHABLE FROM PLAIN C
//     TODAY and this increment ACCEPTS IT — measured, no control flow involved:
//         static int inner(int x){ return x + 3; }          // noinline
//         a = cq_theta(a,0.5); int r = inner(a); int u = r + 1;
//         int m = cq_measure(u); a = cq_theta(a,0.7);
//     `u` is a clause-1 record but is measured before the gate, so it is exempt;
//     the clone's `cqq.out` rail — a full basis record of the wire, never
//     uncomputed and never freed in the caller — is the only thing left standing
//     at the `Ry`, and clause 1 cannot see it. This is bd 6uqc's own P4 shape
//     wearing a clone call, so **Increment 1 does not fully close P4 even for
//     straight-line programs**. It is pinned by
//     lowering_live_record_clone_return_rail_accept.ll and reported on bd 6uqc;
//     it is NOT closed here because the rail is `cqrt_alloc`-minted, i.e. the
//     ancestor/copy class the owner ruled deferred for this increment, and
//     counting it is a scope change with unmeasured blast radius, not a bug fix.
//     The clone-call HOP is now crossed (see `isCloneCallHop`), which reaches
//     records DOWNSTREAM of the result; the result rail itself is still class 1.
//
//   * (4) is reachable too, and is the RULED deferral — see the array bullet
//     above and its accept fixture.
//
// The `_unc` twins of all four writers are adjoints, not forward producers, and
// are excluded above for that reason, not as part of this scope gap.
bool isRecordProducer(const CallInst *CI) {
  if (CI->getType()->isVoidTy())
    return false;
  StringRef N = emittedCalleeName(CI);
  if (N.ends_with("_unc") || N.ends_with("_inv"))
    return false;
  return N.starts_with("cq_template_") || N.starts_with("cqrt_qram_load_");
}

// R's OWN discharge: `cqrt_free(R)`, or an out-first `_unc` whose OUT slot is R
// (the DD-3 convention every adjoint but the QRAM store follows — a store `_unc`
// takes the same args as its forward and mints no rail, so it discharges none).
bool isDischargeOf(const CallInst *CI, const Value *R) {
  StringRef N = emittedCalleeName(CI);
  if (N == "cqrt_free")
    return CI->arg_size() == 1 && CI->getArgOperand(0) == R;
  if (!N.ends_with("_unc") || N.starts_with("cqrt_qram_store_"))
    return false;
  return CI->arg_size() >= 1 && CI->getArgOperand(0) == R;
}

bool isRecordedUserRotation(const CallInst *CI, const TaintSet &taint) {
  return taint.UserSourceRotations.count(CI) ||
         taint.UserChainedRotations.count(CI) ||
         taint.UserPhaseRotations.count(CI);
}

// TEARDOWN traffic — the compiler undoing ITSELF, which the owner ruled is NOT a
// user data use (2026-08-27 (3); SPIKE §2R.5a). Three sources, in order of force:
//   1. `taint.SpineOps` — EMITTER-RECORDED. The only way to recognize a
//      re-emitted SELF-INVERSE gate (`cqrt_cswap` route-back, `cqrt_x` bracket,
//      `cqrt_toffoli`/`cqrt_cnot`, `cqrt_copy_*_controlled`, `cqrt_xorc/addc`),
//      which is byte-identical to its own forward.
//   2. structural, and exact: `cqrt_free` is compiler-emitted only (Rule 6), and
//      the `_unc` family is minted only by `EmitInverse` — no user surface spells
//      either.
//   3. a rotation that is NOT a recorded user gate is the spine's negated-angle
//      adjoint. This is the emitter-keyed answer to census blind spot A8.
//
// EVERYTHING ELSE IS A USER DATA USE — a forward template read, `cqrt_measure_*`,
// a cswap/route slot, a copy/tape sink, a clone call, a plain-IR use. That list
// is clause 3's own wording (SPIKE §2R.1) and it is why an UNRECORDED self-inverse
// gate defaults to "data use": a forward Phase-4 route on a record is a real,
// reachable shape the ruling says to ACCEPT, so defaulting the other way would
// over-decline it. The residual — one `emitInverseCall` caller (`BennettWrap`)
// does not record — is structurally unreachable from a guard site: it emits only
// inside a Phase-6 clone body, and a clone is theta-free by construction, so it
// holds no `UserChainedRotations` member to guard.
//
// THE ROTATION ARM BELOW IS ABOUT TEARDOWN ONLY, NOT ABOUT LIVENESS (owner ruling
// 2026-08-28, bd test_C_libtooling-6uqc, closing the Rule-13 round's F2 finding).
// "A user `cqrt_ry`/`cqrt_rz` naming a record ⇒ not teardown" is still true —
// but the clause-3 loop no longer reads "not teardown" as "data use": a USER
// rotation on a record after the gate is a liveness NON-use (it observes
// nothing), and the record exempts only if its lineage reaches an observing
// sink. So `c = a+3; T; c = cq_phi(c,·)` now DECLINES exactly like
// `c = a+3; c = cq_phi(c,·); T` — same rails standing at the gate, same verdict.
// Pinned by lowering_reject_live_record_post_theta_user_rz.ll.
bool isTeardownUse(const CallInst *CI, const TaintSet &taint) {
  if (taint.SpineOps.count(CI))
    return true;
  StringRef N = emittedCalleeName(CI);
  if (N == "cqrt_free" || N.ends_with("_unc"))
    return true;
  if (N.starts_with("cqrt_ry_") || N.starts_with("cqrt_rz_"))
    return !isRecordedUserRotation(CI, taint);
  return false;
}

// `provablyBefore` — "IF `B` executes, `A` has already executed, and `A` never
// runs again after it." NO LONGER DEFINED HERE: it is `WireWalk.h`'s exported
// spelling (bd 6uqc Inc 2a folded this private copy into it when the M-C
// deadness fence became a third caller — Rule 14; two spellings of one relation
// are how `railOf`/`isAbiQramStore` came to disagree). The modality note below
// is retained because it is about THIS file's clauses, not about the helper.
//
// READ THE MODALITY, because the two callers need DIFFERENT ones and this helper
// supplies only the first:
//   * CLAUSES 2 and 4 ask "did the discharge / measurement HAPPEN before the
//     gate?" — a CONDITIONAL-on-B property, and `provablyBefore(Use, T)` is
//     exactly it: `T` is the gate, so if the gate executes the discharge did.
//     Sound as written.
//   * CLAUSE 3 asks "WILL a user read this record after the gate?" — an
//     UNCONDITIONAL property (post-dominance), which dominance does NOT give.
//     `provablyBefore(T, Use)` proves only that IF the use runs, it runs after
//     the gate. So a record read on ONE arm of a CLASSICAL branch that follows
//     the gate is EXEMPTED even though the other arm never reads it. That gap is
//     KNOWN and measured, not overlooked:
//       - `b1`: `theta; %d = add; T; br i1 %c` with `measure(%d)` in one arm and
//         nothing in the other  ⇒ ACCEPTS (the permissive edge).
//       - `b2`: the reader in one arm and the chained theta in the OTHER
//         ⇒ DECLINES (dominance fails, so no exemption — the conservative side).
//     Tightening clause 3 to a `PostDominatorTree` query would flip `b1` to a
//     decline; it is left permissive deliberately, on the ruled ground that a
//     record any user can still read is the program's own data. Changing this is
//     a scope decision (bd test_C_libtooling-6uqc), not a bug fix.

// A Phase-6 SPECIALIZED CLONE call returning a value (`__cq_q_<callee>_<mask>`).
// Not a record producer — its result is a `cqrt_alloc`-minted `cqq.out` rail
// written by a VOID `cqrt_copy_<W>`, i.e. the deferred copy-destination class —
// but it IS a value-preserving HOP the descendant walk must cross. The `_unc`
// twin (`@__cq_q_<inner>_<mask>_unc`, 6.3) is void and adjoint traffic, never a
// forward hop.
bool isCloneCallHop(const CallInst *CI) {
  if (CI->getType()->isVoidTy())
    return false;
  StringRef N = emittedCalleeName(CI);
  return N.starts_with("__cq_q_") && !N.ends_with("_unc");
}

// Collect the transitive DESCENDANT record closure of `W` (clause 1). Ancestors
// are Inc 3 and are deliberately not walked.
//
// THE WALK CROSSES A CLONE CALL WITHOUT RECORDING IT (the Rule-13 round's F1
// blocker, measured). A non-void `__cq_q_*` clone result severed the walk, so
// every `cq_template_*` rail computed from a clone's return value was invisible
// and the program compiled end to end — while the SAME program written inline
// (`int r = a + 3;` instead of `int r = inner(a);`) declined. Putting an
// expression behind a `noinline static` cannot change what the wire is entangled
// with, so answering differently for the two spellings was an over-accept, not a
// scope choice. The clone's own result is traversed but NOT pushed to `Out`:
// counting it would silently widen the increment into the deferred
// copy-destination class (see the scope note in RotationLowering.h).
void collectDescendantRecords(Value *W, SmallVectorImpl<CallInst *> &Out) {
  SmallVector<Value *, 8> Work;
  SmallPtrSet<const Value *, 16> Seen;
  Work.push_back(W);
  Seen.insert(W);
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    for (User *U : V->users()) {
      auto *CI = dyn_cast<CallInst>(U);
      if (!CI)
        continue;
      const bool Producer = isRecordProducer(CI);
      if (!Producer && !isCloneCallHop(CI))
        continue;
      if (!Seen.insert(CI).second)
        continue;
      if (Producer)
        Out.push_back(CI);  // a record minted FROM a record counts too
      Work.push_back(CI);
    }
  }
}

// Clauses 2-4 for ONE record. Returns true iff `R` is EXEMPT at `T`.
bool recordIsExemptAt(CallInst *R, CallInst *T, const TaintSet &taint,
                      const DominatorTree &DT) {
  for (User *U : R->users()) {
    auto *UI = dyn_cast<Instruction>(U);
    if (!UI)
      continue;
    if (auto *CI = dyn_cast<CallInst>(UI)) {
      // clause 2 — R's own discharge, provably before the gate.
      if (isDischargeOf(CI, R) && provablyBefore(CI, T, DT))
        return true;
      // clause 4 — measured before the gate (collapsed; nothing left to dephase).
      if (emittedCalleeName(CI).starts_with("cqrt_measure_") &&
          provablyBefore(CI, T, DT))
        return true;
      // clause 3 — teardown traffic is not user data (spine-aware, ruled).
      if (isTeardownUse(CI, taint))
        continue;
      // clause 3, F2 (owner ruling 2026-08-28): a USER rotation on R after the
      // gate is a NON-use for liveness — neither teardown nor data. A phase
      // written onto a register nothing ever observes is unobservable, so it
      // cannot make R "the program's own data"; R exempts only if its lineage
      // reaches an OBSERVING sink (measure / ret / tape / a template read that
      // flows to one). This gives the rotation-AFTER spelling the same verdict
      // as the rotation-BEFORE spelling (h2) for the same physics at the gate.
      // Pinned by lowering_reject_live_record_post_theta_user_rz.ll.
      if (isRecordedUserRotation(CI, taint))
        continue;
    }
    // clause 3 — a USER DATA use provably AFTER the gate: the record is LIVE,
    // it is the program's own data, and its dephasing is source semantics.
    //
    // REACHABILITY FIRST. Both halves of `provablyBefore` are VACUOUSLY TRUE for
    // an instruction in a block with no entry path — LLVM's dominator tree treats
    // an unreachable block as dominated by everything, and nothing is reachable
    // from it — so without this test a use that can NEVER EXECUTE exempted the
    // record (the Rule-13 round's F3 finding). A use that never runs is not the
    // program reading its data; the record stays dead and the module declines.
    // Pinned by lowering_reject_live_record_unreachable_use.ll.
    if (!DT.isReachableFromEntry(UI->getParent()))
      continue;
    if (provablyBefore(T, UI, DT))
      return true;
  }
  return false;
}

}  // namespace

bool declineLiveRecordRotations(Module &M, const TaintSet &taint) {
  if (taint.UserChainedRotations.empty())
    return false;  // no site in the whole module — every other cost is skipped.
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    std::optional<DominatorTree> DT;  // built lazily, only for a function with a site
    // BB order, so the FIRST offending gate is the source-located one reported
    // (the DS_Error diagnose exits `opt`).
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *T = dyn_cast<CallInst>(&I);
        if (!T || !taint.UserChainedRotations.count(T))
          continue;
        // Structural re-check — see the file-scope note on pointer validity.
        if (T->arg_size() != 2 ||
            !emittedCalleeName(T).starts_with("cqrt_ry_"))
          continue;
        SmallVector<CallInst *, 8> Records;
        collectDescendantRecords(T->getArgOperand(0), Records);
        if (Records.empty())
          continue;
        if (!DT)
          DT.emplace(F);
        for (CallInst *R : Records) {
          if (recordIsExemptAt(R, T, taint, *DT))
            continue;
          F.getContext().diagnose(
              DiagnosticInfoUnsupported(F, kMsgLiveRecord, T->getDebugLoc()));
          return true;
        }
      }
    }
  }
  return false;
}

}  // namespace cq
