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

#include "llvm/ADT/DenseSet.h"
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
#include <utility>
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


// ── M-A (Increments 1 + 3) — the LATE live-record guard (bd test_C_libtooling-6uqc) ──
//
// See RotationLowering.h for the ruled predicate, the three clause-1 closures
// (descendants · ancestors + copy-destination · descendants-of-ancestors), and
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
//   * lowering_live_record_derived_cond_theta_discharged.ll (bd 6uqc's own P4
//     shape — RE-DISPOSITIONED to an ACCEPT by M-B Increment 5b: the four
//     condition rails are now `_unc`'d and freed BEFORE the chained Ry, so
//     clause 2 exempts them and nothing here changed. The REGION spelling,
//     control_swap_accept_post_region_theta_derived_cond.ll, followed at M-B
//     Increment 6 once the emitter-recorded flag strip gave its chain an anchor;
//     the decline twin that remains is
//     lowering_uncompute_interior_leak_parent_ry_between.ll — a chained Ry INSIDE
//     the discharge interval, which no anchor can move.)
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
// Increment 3 — the ANCESTOR half and the copy-destination class:
//   * lowering_reject_live_record_anc_alloc_parent_mul.ll  (bd nepx's `h0` class:
//       a dead `cqrt_alloc_*` parent, one producer hop up)
//   * lowering_reject_live_record_anc_two_hop.ll           (ancestor transitivity)
//   * lowering_reject_live_record_anc_router_phi.ll        (ancestor behind the bd
//       tayx one-register router phi)
//   * lowering_reject_live_record_anc_dead_sibling.ll      (THE sibling-closure
//       pin: a dead sibling under a LIVE, exempt ancestor)
//   * lowering_reject_live_record_clone_return_rail.ll     (copy-destination class
//       via a Phase-6 clone's `cqq.out` return — Increment 1's owned residual)
//   * lowering_reject_live_record_select_merge_out.ll      (severance class 2, the
//       4.4 merge out — MEASURED `opt` exit 0 at HEAD, i.e. a live over-accept,
//       NOT the lom0-masked shape the Inc-1 note claimed)
//   * lowering_reject_live_record_select_merge_tainted_src.ll (same, with a
//       tainted copy SOURCE so the decline does not rest on constant ancillas)
//   * lowering_reject_live_record_qram_fp64_load_index.ll  (the load-INDEX
//       ancestors of a QRAM read; reverses bd 38t2's shipped positive by owner
//       ruling, and shows the class-4 array boundary in the same module)
//   * lowering_reject_live_record_io_tape_chained_theta.ll (SPIKE §2R.5's
//       CANONICAL case, ruled in by the spine-aware reading §2R.5a)
// Increment 3 — boundary pins that decline at an EARLIER stage, kept so
// Increment 4 has to re-measure them rather than re-derive them:
//   * lowering_reject_live_record_switch_mux_out_masked.ll     ("control flow
//       under quantum control", SwitchClassify)
//   * lowering_reject_live_record_valuearm_merge_out_masked.ll ("value-arm
//       swap-route under quantum control", ArmClassify/SwapRouteEmit)
//   * lowering_reject_live_record_routed_base_anc.ll (RENAMED at Increment 4,
//       was `..._anc_masked.ll`) — the only one that really was bd
//       test_C_libtooling-lom0's "condition predates a non-diagonal gate", and
//       the only one whose message MOVED when Inc 4 lifted that decline: it now
//       lands here, on kMsgLiveRecord. Re-measured, not re-derived.
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
//   * lowering_live_record_anc_measured_before_theta_accept.ll  clause 4 on an
//       ANCESTOR record
//   * lowering_live_record_anc_observed_after_theta_accept.ll   clause 3 on an
//       ANCESTOR record — the ruled accept, and the one-instruction twin of the
//       dead-sibling reject
//   * lowering_live_record_clone_return_rail_measured_accept.ll clause 4 on the
//       COPY-DESTINATION class (this file used to be the ruled-deferred residual
//       over-accept `..._clone_return_rail_accept.ll`; M-C 2a made its `u = r+1`
//       an in-place `cqrt_addc` on the returned rail, so the user's measurement
//       lands on that rail and the accept is now physical, not a scope gap)
//   * lowering_live_record_clone_return_rail_live_accept.ll     clause 3 on the
//       same class
// INCREMENT 3's RULE-13 ROUND (2026-08-28) — the two owner-ruled fixes. Its "F1"
// rewrote clause 3 from "mentioned later" to "reaches an OBSERVING SINK"; its
// "F2" added the clause-6 existence skip. (Both round labels are reused from the
// Inc-1 and Inc-2c rounds, which numbered their own findings the same way — the
// Inc-2c "F2" is the ROTATION ruling pinned by
// lowering_reject_live_record_post_theta_user_rz.ll above. Go by the description,
// not the letter.) Negatives:
//   * lowering_reject_live_record_sibling_region_after_theta.ll  THE F1 fixture:
//       a dead sibling whose only post-gate fate is a compare feeding a phase
//       region — routed, stripped, freed, never observed. MEASURED `opt` exit 0
//       pre-fix; its region-BEFORE twin
//       (lowering_reject_live_record_anc_dead_sibling.ll) always declined, and
//       closing that before/after asymmetry is what the ruling is for
//   * lowering_reject_live_record_qram_store_no_readback.ll      the array HOP in
//       its FALSE direction: a record stored into a cell nothing ever loads.
//       MEASURED `opt` exit 0 pre-fix
//   * lowering_reject_live_record_post_gate_record_loop.ll       the clause-6
//       back-edge pin (a REGRESSION pin, not an isolating witness — read its
//       header: clause 3's own position test already declines every loop body)
// ACCEPT controls added in the same round:
//   * lowering_live_record_post_gate_record_accept.ll            THE F2 fixture —
//       a dead rail minted strictly AFTER the gate. MEASURED `opt` exit 1 pre-fix
//       (a FALSE decline); the module needs BOTH fixes, since its ancestor is
//       exempt only under F1's "template read that flows to a sink"
//   * lowering_live_record_sibling_region_then_measured_accept.ll the ONE-
//       INSTRUCTION discrimination twin of the F1 negative (`cq_measure(c)`)
//   * lowering_live_record_sibling_qram_store_load_measure_accept.ll the array
//       hop in its TRUE direction (store → load → copy-out → measure)
//   * lowering_live_record_sibling_read_taped_accept.ll          the sink is a 7.6
//       TAPE write, with no measurement anywhere in the module
//   * lowering_live_record_sibling_clone_arg_measured_accept.ll  the sink is
//       reached THROUGH a Phase-6 clone call — and, since ROUND 2 below, ALSO the
//       used-parameter control for the per-argument clone hop (its `inner(int x)`
//       really does read `x`)
// ROUND 2 OF THAT SAME RULE-13 ROUND (2026-08-28) — three exact fixes to the F1
// walk's grammar, found by the independent reviewer on the shipped round-1 tree.
// TWO OF THEM WIDEN AN EXEMPTION (the dangerous direction) and are carried by a
// C-REACHABLE MEASUREMENT, not an argument; the third is a decline. ACCEPT
// controls, each `opt` exit 1 on the round-1 tree and exit 0 after:
//   * lowering_live_record_condtree_toffoli_observed_accept.ll  N1, the AND node:
//       a CONTROL of `cqrt_toffoli` HOPS to the node ancilla, so a sibling read by
//       a condition tree whose merge result is measured IS observed. The route
//       rationale that had filed cnot/toffoli as non-uses is true for `cqrt_cswap`
//       and false for these two
//   * lowering_live_record_condtree_xor_observed_accept.ll      N1, the XOR node
//       (`cqrt_cnot` pair — bd 3c6m.67's openlibm ulp-direction idiom), which the
//       AND fixture's toffoli CHECK cannot cover
//   * lowering_live_record_tape_ctrl_observed_accept.ll         N2: the CTRL slot
//       of `cqrt_tape_write_<W>_controlled` is a SINK — the entry's presence or
//       absence reveals the flag. Its SRC-slot twin always accepted, so this was
//       one slot's worth of asymmetry
// Negatives:
//   * lowering_reject_live_record_condtree_out_unobserved.ll    THE N1
//       DISCRIMINATOR (unchanged by the fix, `opt` exit 1 both sides — that IS its
//       job): the same AND-node module with the merge OUT never read. The hop
//       reaches the out rail; the out rail is not a sink. Without it the two N1
//       accepts read as "a condition-tree gate exempts whatever flows into it",
//       which is the retired MENTIONED-LATER reading
//   * lowering_reject_live_record_clone_unused_arg.ll           N3: the clone hop
//       must not cross an argument the callee IGNORES. MEASURED `opt` exit 0 on
//       the round-1 tree (an over-accept), exit 1 after. IR-ONLY — `clang -O1` DAE
//       drops the dead parameter — and ruled on constructed probes exactly as F1
//       and F2 were
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
//   * `cqrt_alloc_*` — a rail, but ITS OWN predicate (`isAllocRail`, Increment 3):
//     it is a record and the walk stops at its classical seed operand.
//   * `cqrt_qram_alloc_*` — the QRAM ARRAY record class, RULED DEFERRED (owner
//     2026-08-27 (4)); `isQramArrayHandle` stops the walk there. Pinned by
//     lowering_qram_array_record_chained_theta_accept.ll.
//   * `cqrt_tape_write_*` — an OUTPUT sink's kept entry (`taint.OutputRails`),
//     never a scratch record.
//   * anything VOID (`cqrt_qram_store_*`, the route/copy gates, the rotations) —
//     an in-place mutation mints no rail at all.
//   * the `_unc` / `_inv` twins — adjoints, not forward producers.
//
// ── THE SEVERANCE CLASSES: WHERE THEY STAND AFTER INCREMENT 3 ────────────────
//
// A production that mints a basis record of the wire through a VOID writer into
// an ALLOC-MINTED destination is invisible to a PRODUCER-edge walk, because there
// is no producer edge to follow: the record's SSA value comes from
// `cqrt_alloc_<W>`, whose only operand is a classical seed. Four such classes
// exist; Increment 3 closes the first three with the COPY-DESTINATION edge in
// `collectAncestorRecords`/`collectDescendantRecords` (a rail that is the DST
// operand of a void `cqrt_copy_<W>` / `cqrt_copy_<W>_controlled` is a record, and
// the walk crosses to its SRC and CONTROL flag):
//
//   1. `cqrt_copy_<W>(src, out)` DESTINATIONS — the Phase-4 method-B value-arm
//      answer rail and a Phase-6 clone's Bennett return (`cqq.out`). **CLOSED.**
//      The clone-return sub-case was Increment 1's owned residual over-accept and
//      is now `lowering_reject_live_record_clone_return_rail.ll`.
//   2. SELECT-MERGE out rails (4.4) and SWITCH DATA-MUX out rails (4.5) — the
//      `cqrt_copy_<W>_controlled` destinations. **CLOSED** at this guard.
//   3. VALUE-ARM MERGE outs. **CLOSED** at this guard.
//   4. `cqrt_qram_store_<W>` ARRAY CELLS — **STILL THE RULED-DEFERRED CLASS**
//      (owner 2026-08-27, second round, point 4). `isQramArrayHandle` stops the
//      walk dead in both directions; pinned by
//      lowering_qram_array_record_chained_theta_accept.ll.
//
// REACHABILITY, RE-MEASURED FOR INCREMENT 3 — and the Increment-1 note here was
// WRONG about it, in the over-accepting direction. That note said classes (2) and
// (3) "ARE masked today" by bd test_C_libtooling-lom0's position-free
// `condWireDisposition` over-decline. Measured on the four natural C
// spellings, that is FOUR different facts:
//
//   * a tainted `?:` — and a `switch` whose cases `clang -O1` folds into
//     arithmetic — canonicalize to a **`select`**. `SelectClassify` DOES run a
//     position-free wire walk (SelectClassify.cpp ~691, the lom0 mechanism
//     transplanted), but it is seeded from the CONDITION's provenance, and the
//     merge OUT is a fresh `cqrt_alloc`-minted rail that is not on that wire —
//     so a chained theta on the OUT is invisible to it. Both compiled end to end
//     at HEAD (`opt` exit 0): a **LIVE OVER-ACCEPT**, never masked at all. Closed by
//     the copy-destination edge; the flag itself is usually exempt (stripped and
//     freed by the region teardown) but the walk passes THROUGH it to the
//     condition's own operands, which are not.
//     (lowering_reject_live_record_select_merge_out.ll,
//      lowering_reject_live_record_select_merge_tainted_src.ll)
//   * a real `switch` + merge phi declines at `SwitchClassify` with "control flow
//     under quantum control" (lowering_reject_live_record_switch_mux_out_masked.ll).
//   * a real `br` value-arm diamond declines with "value-arm swap-route under
//     quantum control" (lowering_reject_live_record_valuearm_merge_out_masked.ll).
//   * of the four pins only the ROUTED-BASE phase region wore lom0's own
//     message — note `SelectClassify` emits the SAME string for a theta on the
//     condition wire of a `?:`, which is a different shape from the OUT-rail one
//     above.
// RE-MEASURED AT INCREMENT 4 (the lift landed): that one moved to
// `kMsgLiveRecord` and is now `lowering_reject_live_record_routed_base_anc.ll`;
// the other three are byte-identical (they never declined at ArmClassify's wire
// walk). None landed on `opt` exit 0.
//
// The `_unc` twins of all four writers are adjoints, not forward producers, and
// are excluded above for that reason, not as part of any scope gap.
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
// "NOT TEARDOWN" IS NOT "DATA USE", AND THIS PARAGRAPH USED TO SAY IT WAS.
// The retired wording read: "EVERYTHING ELSE IS A USER DATA USE — a forward
// template read, `cqrt_measure_*`, a cswap/route slot, a copy/tape sink, a clone
// call, a plain-IR use … a forward Phase-4 route on a record is a real, reachable
// shape the ruling says to ACCEPT." Two owner rulings retired it in two steps:
// 2026-08-28's F2 ruling for rotations, and the SAME DAY's F1 ruling for the
// rest — "a record exempts only if its lineage reaches an OBSERVING sink after
// the gate — measure / ret / tape / a template read that itself flows to one".
//
// So a ROUTE IS NOW A NON-USE, not a data use. `cqrt_cswap` / `cqrt_x` /
// `cqrt_cnot` / `cqrt_toffoli` move a value onto a work rail and back onto its
// own rail; nothing is observed, and if the rail is measured later that measure
// is a DIRECT user of the rail and counts on its own. The over-accept this
// closed is measured, not hypothetical: a dead sibling whose only post-gate fate
// was a compare feeding a phase region — flag routed, stripped and freed —
// exempted on the route/compare mentions and the module ACCEPTED, while the same
// program with the region moved BEFORE the gate DECLINED on identical rails
// (lowering_reject_live_record_sibling_region_after_theta.ll vs
// lowering_reject_live_record_anc_dead_sibling.ll).
//
// WHAT THIS FUNCTION STILL DECIDES, AND ITS FAIL DIRECTION. It answers only "is
// this the compiler undoing ITSELF?", and it is consumed by
// `reachesObservingSink` as ONE of the non-use categories. The three sources
// above stay exactly as written, including the rotation arm — "a user
// `cqrt_ry`/`cqrt_rz` naming a record ⇒ not teardown" is still true, the walk
// simply treats user rotations as non-uses of its own (F2). Because the walk's
// DEFAULT is now "not a sink", an UNRECORDED self-inverse gate no longer
// exempts anything, which reverses the fail direction recorded in
// TaintPropagation.h's `SpineOps` comment for THIS consumer: a missed
// `SpineOps` recording can now only over-DECLINE here. The `BennettWrap`
// residual documented there is unchanged and still structurally unreachable
// from a guard site (its emissions live inside a clone body, and a clone is
// theta-free by construction, so it holds no `UserChainedRotations` member).
// Pinned by lowering_reject_live_record_post_theta_user_rz.ll (F2) and
// lowering_reject_live_record_sibling_region_after_theta.ll (F1).
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
//
// ...AND THE SAME MODALITY HAS A COST IN THE *OTHER* DIRECTION, INSIDE A LOOP.
// This is the reviewer's N4 from round 2 of the Increment-3 Rule-13 round
// (2026-08-28), recorded here as a note; NOTHING in this file changes for it, and
// it is tracked in bd rather than fixed under this increment.
//
// `provablyBefore(T, Use)` is `DT.dominates(T, Use) && !isPotentiallyReachable(
// Use, T)`. Inside a LOOP BODY the second half fails for EVERY use — the back edge
// makes `T` reachable again — so NO RECORD IN A LOOP BODY CAN EVER BE EXEMPTED BY
// AN IN-BODY OBSERVATION, no matter how directly the program measures it. That is
// the same back edge the clause-6 existence skip needs (and correctly gets:
// lowering_reject_live_record_post_gate_record_loop.ll), read from the other side.
//
// MEASURED, on ordinary C through the real pipeline:
//     for (int i = 0; i < n; i++) {
//         int q = cq_theta(u0, 0.25);
//         int w = q * 2;
//         w = cq_theta(w, 0.5);                    // T
//         acc += cq_measure(q) + cq_measure(w);    // BOTH rails measured, in body
//     }
// HEAD (d2828e3) `opt` exit 0; Increment 3, both round 1 and round 2, exit 1. Every
// record is measured in the iteration that mints it, so nothing is dead at the gate
// — the ancestor rail declines anyway. It is an OVER-decline (the safe direction,
// not a Prime-Directive defect), but it is a real capability loss on the shape
// Grover repetition is written in. A fix belongs with a LOOP-AWARE clause 3 — an
// observation anywhere in the same iteration's body, or a post-dominance reading
// that admits the back edge — which is a scope decision, not a bug fix, and which
// would also hand the loop fixture the isolating F2 witness its header wants.

// A Phase-6 SPECIALIZED CLONE call returning a value (`__cq_q_<callee>_<mask>`).
// A value-preserving HOP the walk crosses in both directions — AND, since M-A
// Increment 3, a RECORD in its own right: the result is a `cqrt_alloc`-minted
// `cqq.out` rail written by a VOID `cqrt_copy_<W>` inside the clone body, i.e.
// the COPY-DESTINATION class (severance class 1), which this increment closes.
// The `_unc` twin (`@__cq_q_<inner>_<mask>_unc`, 6.3) is void and adjoint
// traffic, never a forward hop.
bool isCloneCallHop(const CallInst *CI) {
  if (CI->getType()->isVoidTy())
    return false;
  StringRef N = emittedCalleeName(CI);
  return N.starts_with("__cq_q_") && !N.ends_with("_unc");
}

// …BUT THE HOP IS PER-ARGUMENT, and only the observing-sink walk is allowed to
// assume otherwise (round 2 of the Increment-3 Rule-13 round, 2026-08-28).
//
// `isCloneCallHop` says "this call forwards a value"; it does NOT say that THIS
// argument is one of the values forwarded. A clone that IGNORES a parameter
// returns a result independent of it, so exempting a record on "the clone's
// result is measured" was an OVER-ACCEPT — the record stands dephasing at the
// gate and nothing anywhere observes it. Measured on
// `@__cq_q_inner_11(%x, %y)` with `%x` unread: `opt` exit 0 in the pre-round-2
// tree, and the whole module's only sink is `cqrt_measure(%r)`. Pinned by
// lowering_reject_live_record_clone_unused_arg.ll.
//
// IR-ONLY, and said plainly because it changes how the pin must be read: `clang
// -O1` runs DAE and DROPS a parameter no callee body reads, so the natural C
// spelling never reaches the pass in this shape (measured — the dead sibling is
// DCE'd with it). The ruling direction is the F2/F1 one: a construct nothing
// observes buys nothing by being accepted, and both of those were likewise ruled
// on constructed probes.
//
// FAIL DIRECTION — an UNRESOLVABLE callee gets NO hop. `getCalledFunction()` is
// null for a `GlobalAlias` and every name test then silently fails open (the bd
// xy9n lesson this file already obeys via `emittedCalleeName`), so the callee is
// resolved by an explicit `dyn_cast<Function>` on the called OPERAND — an alias,
// a bitcast or an indirect call does not resolve, and an unresolved callee, a
// body-less declaration and an argument past a varargs boundary all return false.
// That is the DECLINE direction, which is the safe one here.
//
// WHAT THE TEST IS, PRECISELY: a USE test, not a DATAFLOW test — "an argument
// the callee never READS" (`Argument::use_empty()`), not "an argument the result
// cannot depend on". The residual one level up is therefore known and IR-only
// (Inc-3 Rule-13 round 2, reviewer probe q3): a parameter read only by an
// in-body compare that is stripped and freed, with the return computed from the
// OTHER parameter, still hops. `clang -O1` DCEs that dead compare and DAE then
// drops the parameter, so C does not reach it; a dataflow test would be the fix
// if it ever does.
//
// NOT APPLIED TO THE CLAUSE-1 WALKS, deliberately. `collectDescendantRecords` /
// `collectAncestorRecords` cross a clone call to decide what COUNTS as a record;
// crossing an unused parameter there only ADDS records, i.e. over-declines, so
// tightening it would be a scope change with no safety argument behind it.
bool cloneArgReachesResult(const CallInst *CI, const Value *In) {
  const auto *F = dyn_cast<Function>(CI->getCalledOperand());
  if (!F || F->isDeclaration())
    return false;
  for (unsigned K = 0, E = CI->arg_size(); K != E; ++K) {
    if (CI->getArgOperand(K) != In)
      continue;
    if (K >= F->arg_size())
      return false;  // past the varargs boundary — no `Argument` to interrogate.
    if (!F->getArg(K)->use_empty())
      return true;
  }
  return false;
}

// ── M-A Increment 3 — the ANCESTOR half of clause 1 ──────────────────────────
//
// A `cqrt_alloc_<W>` WORK RAIL. bd test_C_libtooling-nepx's `h0` class: the
// source rail an out-of-place `_hl` template leaves standing behind its own
// result, and the DESTINATION every void copy gate writes into. Increment 1
// excluded it by scope; the ruled predicate's clause 1 says "alloc-minted rails
// included", and this is that clause. NOT `cqrt_qram_alloc_<W>` — the prefixes
// are disjoint (`cqrt_alloc_` vs `cqrt_qram_alloc_`) and the array class is
// ruled DEFERRED, below.
bool isAllocRail(const CallInst *CI) {
  return emittedCalleeName(CI).starts_with("cqrt_alloc_");
}

// A QRAM ARRAY handle (`cqrt_qram_alloc_<W>`) — SEVERANCE CLASS 4, RULED
// DEFERRED (owner 2026-08-27, second round, point 4). The walk STOPS here in
// BOTH directions: the handle is never pushed as a record, and the walk never
// follows a `cqrt_qram_store_<W>` into a cell. Pinned by
// lowering_qram_array_record_chained_theta_accept.ll; the boundary is visible in
// lowering_reject_live_record_qram_fp64_load_index.ll, where the decline is
// carried entirely by the load's INDEX operands while the carrier reachable only
// THROUGH the array stays uncounted.
bool isQramArrayHandle(const CallInst *CI) {
  return emittedCalleeName(CI).starts_with("cqrt_qram_alloc_");
}

// A void BASIS COPY gate. Two spellings, and the DESTINATION is the LAST operand
// in both — verified against runtime/cq_runtime.h:293-343
// (`void cqrt_copy_<W>(src, dst)`, `void cqrt_copy_<W>_controlled(ctrl, src,
// dst)`) and against every emission site rather than assumed — all ten put the
// destination last: BennettWrap.cpp:82 `{ResultRail, Out}`, SwapRouteEmit.cpp:361
// `{Q, Out}`, SelectMergeEmit.cpp:242/250 and SwitchDataMuxEmit.cpp:200
// `{Flag, Src, Out}`, IOSinkLowering.cpp:779/782, ClassicalCallArmEmit.cpp:233/241,
// Specialization.cpp:351/361/369, BreakReversePlay.cpp:552-660, QramLowering.cpp:1883
// (re-verified by the Inc-3 Rule-13 round, 2026-08-28).
// The family is SELF-INVERSE, so there is no `_unc`/`_inv` twin to exclude
// (cq_runtime.h:269, :317).
bool isCopyGate(const CallInst *CI) {
  if (!CI->getType()->isVoidTy())
    return false;
  StringRef N = emittedCalleeName(CI);
  if (!N.starts_with("cqrt_copy_"))
    return false;
  return CI->arg_size() == 2 || CI->arg_size() == 3;
}

// What the walk does with a value it has reached.
enum class RailKind {
  Opaque,     // not a rail the walk understands — stop, record nothing
  Record,     // a producer / alloc / clone-return rail — count it, keep walking
  Router,     // a phi/select of handles — an ALIAS of the wire, never a record
  QramArray,  // the ruled-deferred class 4 — stop dead
};

RailKind classifyRail(const Value *V) {
  if (isa<PHINode>(V) || isa<SelectInst>(V))
    return RailKind::Router;
  const auto *CI = dyn_cast<CallInst>(V);
  if (!CI)
    return RailKind::Opaque;
  if (isQramArrayHandle(CI))
    return RailKind::QramArray;
  if (isRecordProducer(CI) || isAllocRail(CI) || isCloneCallHop(CI))
    return RailKind::Record;
  return RailKind::Opaque;
}

// One record set, built by two walks that share a `Recorded` set (so a rail
// reached from both directions is pushed once) and a `Wire` exclusion (clause 5).
struct RecordSet {
  const Value *Wire = nullptr;
  SmallVectorImpl<CallInst *> &Out;
  SmallPtrSet<const Value *, 32> Recorded;

  explicit RecordSet(const Value *W, SmallVectorImpl<CallInst *> &O)
      : Wire(W), Out(O) {}

  void push(Value *V) {
    if (V == Wire)  // clause 5 — the in-place gate chain on the same handle
      return;
    auto *CI = dyn_cast<CallInst>(V);
    if (!CI || classifyRail(V) != RailKind::Record)
      return;
    if (Recorded.insert(CI).second)
      Out.push_back(CI);
  }
};

// Collect the transitive DESCENDANT record closure of `Seed` (clause 1, forward).
//
// THE WALK CROSSES A CLONE CALL (the Increment-1 Rule-13 round's F1 blocker,
// measured): a non-void `__cq_q_*` result used to sever the walk, so every
// `cq_template_*` rail computed from a clone's return value was invisible and the
// program compiled end to end — while the SAME program written inline declined.
// Putting an expression behind a `noinline static` cannot change what the wire is
// entangled with. Increment 3 additionally PUSHES the clone result (the
// copy-destination class, severance class 1) and follows the forward
// `cqrt_copy_<W>` SRC→DST edge, so a basis copy of the wire is a record wherever
// the void gate put it.
void collectDescendantRecords(Value *Seed, RecordSet &RS,
                              SmallPtrSetImpl<const Value *> &Seen) {
  SmallVector<Value *, 8> Work;
  if (!Seen.insert(Seed).second)
    return;
  Work.push_back(Seed);
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (classifyRail(V) == RailKind::QramArray)
      continue;  // never follow a store into an array cell
    for (User *U : V->users()) {
      auto *CI = dyn_cast<CallInst>(U);
      if (!CI)
        continue;
      // COPY-DESTINATION edge, forward: `V` is the SRC, so the DST records it.
      if (isCopyGate(CI)) {
        unsigned N = CI->arg_size();
        if (CI->getArgOperand(N - 2) != V)
          continue;
        Value *Dst = CI->getArgOperand(N - 1);
        if (!Seen.insert(Dst).second)
          continue;
        RS.push(Dst);
        Work.push_back(Dst);
        continue;
      }
      if (!isRecordProducer(CI) && !isCloneCallHop(CI))
        continue;
      if (!Seen.insert(CI).second)
        continue;
      RS.push(CI);  // a record minted FROM a record counts too
      Work.push_back(CI);
    }
  }
}

// Collect the transitive ANCESTOR record closure of `W` (clause 1, backward) and
// hand back every rail it reached in `Seeds`, so the caller can run the forward
// walk from each — that second pass is what reaches a DEAD SIBLING under a LIVE
// ancestor, which is the ruling's "transitively entangled" and is pinned by
// lowering_reject_live_record_anc_dead_sibling.ll.
//
// THREE EDGES, and the third is the one that crosses a SEVERANCE:
//   (a) the PRODUCER edge — a `cq_template_*` / `cqrt_qram_load_*` / clone-call
//       definition's own i32 rail operands. Only `Instruction` operands are
//       followed: a literal is a `ConstantInt` and a function parameter is an
//       `Argument`, so both stop the walk without a grammar test (an `_hl` vs
//       `_lh` vs `_qq` suffix parse would be a second spelling of the ABI —
//       Rule 14 says don't mint one).
//   (b) a `cqrt_alloc_<W>` is a RECORD but its operand is a CLASSICAL SEED — the
//       walk stops there rather than wandering into classical provenance.
//   (c) the COPY-DESTINATION edge — if the reached rail is the DST operand of a
//       void copy gate, its SRC (and, for the controlled form, its CONTROL flag)
//       are ancestors. This is the only way to reach the four rails whose basis
//       content arrives through a void writer into an alloc-minted destination:
//       value-arm answer rails, clone `cqq.out` returns, select-merge outs and
//       switch-data-mux outs. Note the flag is USUALLY exempt on its own (it is
//       `_unc`-stripped and freed by the region teardown before the gate) — the
//       walk still passes THROUGH it to reach the condition's own operands, which
//       are typically not.
// A phi/select of handles is NOT a record (it is an alias of the wire — the bd
// tayx one-register router forwards the same physical handle); the walk recurses
// into its incoming values. Void users (`cqrt_addc`/`subc`/`xorc`, the rotations,
// the routes) mint no rail and are never producers — the backward walk looks only
// at DEFINITIONS, plus the copy-destination USER scan of (c).
void collectAncestorRecords(Value *W, RecordSet &RS,
                            SmallVectorImpl<Value *> &Seeds) {
  SmallVector<Value *, 8> Work;
  SmallPtrSet<const Value *, 16> Visited;
  auto enqueue = [&](Value *V) {
    if (V && Visited.insert(V).second)
      Work.push_back(V);
  };
  enqueue(W);
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    RailKind K = classifyRail(V);
    if (K == RailKind::QramArray)
      continue;  // severance class 4, ruled deferred
    if (K != RailKind::Opaque) {
      RS.push(V);          // no-op for the wire itself and for a Router
      Seeds.push_back(V);  // ...but every rail seeds the sibling pass
    }

    // (c) COPY-DESTINATION edge, backward.
    for (User *U : V->users()) {
      auto *CI = dyn_cast<CallInst>(U);
      if (!CI || !isCopyGate(CI))
        continue;
      unsigned N = CI->arg_size();
      if (CI->getArgOperand(N - 1) != V)
        continue;  // V must be the DESTINATION
      enqueue(CI->getArgOperand(N - 2));  // the copied SOURCE
      if (N == 3)
        enqueue(CI->getArgOperand(0));  // the CONTROL flag
    }

    if (K == RailKind::Router) {
      if (auto *Phi = dyn_cast<PHINode>(V)) {
        for (Value *In : Phi->incoming_values())
          enqueue(In);
      } else {
        auto *Sel = cast<SelectInst>(V);
        enqueue(Sel->getTrueValue());
        enqueue(Sel->getFalseValue());
      }
      continue;
    }
    auto *CI = dyn_cast<CallInst>(V);
    if (!CI)
      continue;
    if (isAllocRail(CI))
      continue;  // (b) classical seed — stop
    if (!isRecordProducer(CI) && !isCloneCallHop(CI))
      continue;
    for (Value *Op : CI->args())  // (a)
      if (isa<Instruction>(Op))
        enqueue(Op);
  }
}

// A Phase-7.5 Shadow STORE, either spelling, and where its ARRAY operand sits.
// Verified against runtime/cq_runtime.h:553-603:
//   `void cqrt_qram_store_<W>(arr, idx, val)`                  — 3 args, arr = 0
//   `void cqrt_qram_store_<W>_controlled(pred, arr, idx, val)` — 4 args, arr = 1
// The `_unc` twins of both are classified as teardown BEFORE this runs, so there
// is no exclusion to make here.
bool isQramStoreGate(const CallInst *CI, unsigned &ArrPos) {
  if (!CI->getType()->isVoidTy())
    return false;
  StringRef N = emittedCalleeName(CI);
  if (!N.starts_with("cqrt_qram_store_"))
    return false;
  if (N.ends_with("_controlled") && CI->arg_size() == 4) {
    ArrPos = 1;
    return true;
  }
  if (!N.ends_with("_controlled") && CI->arg_size() == 3) {
    ArrPos = 0;
    return true;
  }
  return false;
}

// ── CLAUSE 3's OBSERVING-SINK WALK (owner ruling 2026-08-28, the F1 fix) ─────
//
// "A record exempts only if its lineage reaches an OBSERVING sink after the gate
// — measure / ret / tape / a template read that itself flows to one."
//
// WHAT THIS REPLACED, AND WHY IT HAD TO. Until this fix clause 3 exempted `R` on
// ANY post-gate use that was neither teardown nor a recorded user rotation. That
// read "somebody mentions it later" as "the program's own data", and the two are
// not the same thing: a dead sibling whose only post-gate fate is a COMPARE whose
// flag a Phase-4 region strips and frees is mentioned four times and observed
// zero times. It exempted, and the module ACCEPTED — while the SAME program with
// the region moved BEFORE the gate DECLINED, on identical rails standing at the
// gate with identical physics. That before/after asymmetry is exactly what the F2
// ruling was made to eliminate for rotations; this is the same ruling applied to
// the rest of the use grammar.
//
// Returns true iff a forward walk of the VALUE FLOW out of `U` (the post-gate use
// of record `R`) reaches an OBSERVING SINK. The three categories, and note that
// the SAFE direction is "not a sink": a use the walk does not understand exempts
// nothing, so the module declines.
//
//   SINKS   — `cqrt_measure_*` (any operand: the collapse observes the rail),
//             `ret` (an ESCAPE; the caller owns the register and may observe it),
//             `cqrt_tape_write_*` in its WRITTEN slot (the 7.6 output tape — its
//             `out_handle` is `taint.OutputRails`, a kept output, never freed)
//             AND, since round 2, in the CTRL slot of its guarded 3-argument
//             spelling (the entry's presence or absence reveals the flag).
//   HOPS    — the value flows onward and the walk continues from what it became:
//             a non-void forward `cq_template_*` read or `cqrt_qram_load_*`
//             (`isRecordProducer`) → its result; a `__cq_q_*` clone call
//             (`isCloneCallHop`) → its result, but ONLY for an argument the
//             clone's body actually reads (`cloneArgReachesResult`, round 2); a
//             void `cqrt_copy_<W>` / `_controlled` with the value in the SRC or
//             CTRL slot → the DST rail; a `phi`/`select` → its result; a
//             `cqrt_qram_store_<W>` / `_controlled` with the value in the IDX,
//             VAL or PRED slot → THROUGH THE ARRAY, i.e. the result of every
//             later `cqrt_qram_load_*` on the same array handle (the array-cell
//             class is ruled-deferred as a RECORD — `isQramArrayHandle` — but
//             that is about what counts against the gate; this is about whether
//             the user can still SEE the value, and through a store-then-load
//             they can); and a CONTROL slot of `cqrt_cnot` / `cqrt_toffoli` →
//             their TARGET ancilla (round 2 — the condition-tree node).
//   NON-USES— `cqrt_free`, every `_unc`/`_inv`, `taint.SpineOps` (the compiler
//             undoing itself), ALL rotations (the F2 ruling: a phase written onto
//             a never-observed register is unobservable, so `cqrt_ry`/`cqrt_rz`
//             observe nothing whether the emitter recorded them as USER gates or
//             not), the ROUTE/BRACKET gates `cqrt_cswap` / `cqrt_x`, and the
//             TARGET slot of `cqrt_cnot` / `cqrt_toffoli`. A ROUTE is not an
//             observation: a routed value comes back to its own rail, and if that
//             rail is later measured the measurement is a DIRECT user of the rail
//             and counts on its own. Anything else — a plain-IR instruction, an
//             unmodelled call — is conservatively neither, which is the decline
//             direction.
//
// ROUND 2 OF THIS RULE-13 ROUND (2026-08-28) MOVED THREE ENTRIES OF THAT GRAMMAR,
// and TWO of them WIDEN the exemption — the dangerous direction, so each one is
// stated with the measurement that forced it. The per-entry argument lives at the
// code below; here is the shape of it:
//   N1  `cqrt_cnot`/`cqrt_toffoli`: NON-USE → CONTROL-slot HOP. They had been
//       filed with `cqrt_cswap`/`cqrt_x` on the route argument, which is FALSE for
//       them — they write the controls' information into a FRESH ancilla the merge
//       reads, not back onto the value's own rail. Measured C-reachable
//       over-decline (an `&`/`^` of two tainted compares steering a `?:` whose
//       result is measured): HEAD `opt` exit 0, pre-round-2 tree exit 1.
//   N2  a guarded `cqrt_tape_write_<W>_controlled`'s CTRL slot: not-a-sink → SINK.
//       Measured C-reachable over-decline (`if (c > 3) printf("%d", a);`) whose
//       SRC-slot twin (`printf("%d", c)`) always accepted.
//   N3  the clone hop: unconditional → per-argument. The DECLINE direction, and
//       IR-only (`clang -O1` DAE removes an unread parameter), ruled on
//       constructed probes exactly as F1 and F2 were.
//
// A COMPARE whose flag is only stripped needs no rule of its own: the compare is
// a HOP, and the flag's users are then `cqrt_cswap` / `_unc` / `cqrt_free`, all
// non-uses, so the walk simply runs out. That is the h4 shape. A compare whose
// flag feeds a condition-tree NODE is the N1 shape and does hop — but only as far
// as the node ancilla, so if nothing reads the merge OUT the walk still runs out
// (`lowering_reject_live_record_condtree_out_unobserved.ll`).
//
// Deeper nodes carry NO position test — they are downstream of `U`, which the
// caller has already proved is after the gate — but they DO carry the F3
// reachability test: a sink in a block with no entry path cannot observe
// anything.
bool reachesObservingSink(Instruction *U, Value *R, const TaintSet &taint,
                          const DominatorTree &DT) {
  // Worklist entries are (INCOMING VALUE, USE) pairs, not bare instructions: a
  // copy gate and a QRAM store classify by WHICH SLOT the tracked value sits in,
  // so the walk has to remember what reached them.
  SmallVector<std::pair<Value *, Instruction *>, 8> Work;
  DenseSet<std::pair<const Value *, const Instruction *>> SeenUse;
  SmallPtrSet<const Value *, 16> Scanned;

  auto pushUse = [&](Value *In, Instruction *Use) {
    if (!In || !Use)
      return;
    if (!DT.isReachableFromEntry(Use->getParent()))
      return;  // F3 — an instruction that can never execute observes nothing.
    if (SeenUse.insert({In, Use}).second)
      Work.push_back({In, Use});
  };
  auto pushValue = [&](Value *V) {
    if (!V || !Scanned.insert(V).second)
      return;
    for (User *X : V->users())
      if (auto *XI = dyn_cast<Instruction>(X))
        pushUse(V, XI);
  };

  pushUse(R, U);
  while (!Work.empty()) {
    auto [In, I] = Work.pop_back_val();
    if (isa<ReturnInst>(I))
      return true;  // SINK — escape; the caller owns the register.
    if (isa<PHINode>(I) || isa<SelectInst>(I)) {
      pushValue(I);  // HOP — a router forwards the same content.
      continue;
    }
    auto *CI = dyn_cast<CallInst>(I);
    if (!CI)
      continue;  // conservative: any other plain-IR instruction observes nothing.
    StringRef N = emittedCalleeName(CI);

    // ── SINKS ──
    if (N.starts_with("cqrt_measure_"))
      return true;
    if (N.starts_with("cqrt_tape_write_") && CI->arg_size() >= 2 &&
        CI->getArgOperand(CI->arg_size() - 1) == In)
      return true;  // the WRITTEN slot (`…(tape, src)` / `…(ctrl, tape, src)`).
    // …and so is the CTRL slot of the GUARDED spelling (round 2 of the Inc-3
    // Rule-13 round, 2026-08-28). `cqrt_tape_write_<W>_controlled(ctrl, tape,
    // src)` writes an entry IFF `ctrl` is set, so the PRESENCE OR ABSENCE of that
    // entry on the output tape reveals the flag to whoever reads the tape. A
    // record whose lineage reaches the flag is therefore observed just as surely
    // as one that reaches `src` — the reader learns a bit of it either way.
    // MEASURED as a C-reachable OVER-DECLINE: `c = a*k; a = cq_theta(a,.25);
    // if (c > 3) printf("%d", a);` — `opt` exit 0 at HEAD, exit 1 in the
    // pre-round-2 tree; its SRC-slot twin (`printf("%d", c)`) always accepted.
    // Pinned by lowering_live_record_tape_ctrl_observed_accept.ll.
    //
    // ARITY, not the `_controlled` suffix, is the discriminator, and it is exact:
    // `cqrt_tape_write_<W>(tape, src)` is i32(i32,i32) and the `_controlled` twin
    // is i32(i32,i32,i32) — runtime/cq_runtime.h:445-454, WidthDispatch.cpp:242
    // and ControlledSymbols.cpp:147. Neither has an `_unc`/`_inv` twin (a tape
    // entry is a KEPT output, `taint.OutputRails`, never uncomputed), so the
    // prefix test cannot pick up adjoint traffic.
    if (N.starts_with("cqrt_tape_write_") && CI->arg_size() == 3 &&
        CI->getArgOperand(0) == In)
      return true;  // the CTRL slot of the guarded write.

    // ── NON-USES ── (`isTeardownUse` is REUSED verbatim for the spine half —
    // `SpineOps`, `cqrt_free`, the `_unc` family, the spine's negated-angle
    // adjoint rotations — so the two callers cannot drift, Rule 14.)
    if (isTeardownUse(CI, taint))
      continue;
    if (N.ends_with("_inv"))
      continue;  // the pre-8txa adjoint spelling, same reading as `_unc`.
    if (N.starts_with("cqrt_ry_") || N.starts_with("cqrt_rz_"))
      continue;  // the F2 ruling: a USER rotation observes nothing either.
    if (N == "cqrt_cswap" || N == "cqrt_x")
      continue;  // route / bracket gates — a routed value returns to its rail.

    // ── HOPS ──
    // CONDITION-TREE NODE GATES — a CONTROL slot HOPS to the TARGET (round 2 of
    // the Increment-3 Rule-13 round, 2026-08-28). `cqrt_cnot` and `cqrt_toffoli`
    // used to sit on the NON-USE line above beside `cqrt_cswap`/`cqrt_x`, and the
    // cswap rationale DOES NOT TRANSFER: a route puts a value on a work rail and
    // brings it back to its OWN rail, whereas a CNOT/Toffoli WRITES the controls'
    // information into a FRESH `|0⟩` ancilla that somebody else then reads. That
    // ancilla is the `and`/`or`/`xor` node of a condition tree
    // (`SelectClassify`/`ArmClassify`; the xor node is the openlibm ulp-direction
    // idiom bd 3c6m.67 admitted), and the merge reads it as the copy CONTROL.
    // MEASURED as a C-reachable OVER-DECLINE: `((c>3) & (d<9)) ? 10 : 20` with the
    // select's result measured left `c` exempt-less because the walk stopped dead
    // at the toffoli — `opt` exit 0 at HEAD, exit 1 in the pre-round-2 tree.
    // Pinned by lowering_live_record_condtree_toffoli_observed_accept.ll (AND) and
    // lowering_live_record_condtree_xor_observed_accept.ll (XOR).
    //
    // THE TARGET IS THE LAST OPERAND in both spellings — `void cqrt_cnot(ctrl,
    // tgt)` / `void cqrt_toffoli(c1, c2, tgt)` (runtime/cq_runtime.h:227-228),
    // re-verified against every mint site rather than assumed:
    // ControlledSymbols.cpp:57/69 declare them that way, and the four emitters put
    // the ancilla last — SelectMergeEmit.cpp:192/193/196 (forward) and :279/281/282
    // (the LIFO strip), Specialization.cpp:187/188/191, BreakReversePlay.cpp:568
    // (`{G, Fire}`), :589 and :685 (`{…, Efl, Fire}`). Both gates are involutions,
    // so there is no `_unc`/`_inv` twin to exclude; the arity test keeps the
    // 3-argument `cqrt_cnot_controlled` (cq_runtime.h:239) OUT of this arm, where
    // it falls through to "everything else" — the decline direction, since no
    // emitter mints it today.
    //
    // WHEN `In` IS THE TARGET this is a NON-USE, deliberately: the ancilla's own
    // users are scanned independently the moment some path pushes the rail itself,
    // so treating the write as an observation of the written rail would be a
    // second, weaker spelling of the same edge.
    if ((N == "cqrt_cnot" && CI->arg_size() == 2) ||
        (N == "cqrt_toffoli" && CI->arg_size() == 3)) {
      const unsigned NA = CI->arg_size();
      for (unsigned K = 0; K + 1 < NA; ++K)
        if (CI->getArgOperand(K) == In) {
          pushValue(CI->getArgOperand(NA - 1));  // CONTROL → the TARGET ancilla.
          break;
        }
      continue;
    }
    if (isCopyGate(CI)) {
      unsigned NA = CI->arg_size();
      if (CI->getArgOperand(NA - 2) == In ||
          (NA == 3 && CI->getArgOperand(0) == In))
        pushValue(CI->getArgOperand(NA - 1));  // the DESTINATION rail.
      continue;
    }
    unsigned ArrPos = 0;
    if (isQramStoreGate(CI, ArrPos)) {
      bool Feeds = false;
      for (unsigned K = 0, E = CI->arg_size(); K != E; ++K)
        if (K != ArrPos && CI->getArgOperand(K) == In)
          Feeds = true;  // IDX, VAL or (guarded form) PRED.
      if (!Feeds)
        continue;
      Value *Arr = CI->getArgOperand(ArrPos);
      for (User *X : Arr->users()) {
        auto *L = dyn_cast<CallInst>(X);
        if (!L || L->getType()->isVoidTy())
          continue;
        StringRef LN = emittedCalleeName(L);
        if (!LN.starts_with("cqrt_qram_load_") || LN.ends_with("_unc"))
          continue;
        if (!provablyBefore(CI, L, DT))
          continue;  // "SUBSEQUENT" — a load that already ran read the old cell.
        pushValue(L);
      }
      continue;
    }
    if (!CI->getType()->isVoidTy() && isCloneCallHop(CI)) {
      if (cloneArgReachesResult(CI, In))
        pushValue(CI);  // a clone's returned `cqq.out` rail.
      continue;         // …otherwise the argument is DEAD in the callee — no hop.
    }
    if (!CI->getType()->isVoidTy() && isRecordProducer(CI)) {
      pushValue(CI);  // a forward template read or QROM load.
      continue;
    }
    // Everything else: not a sink, not a hop — the decline direction.
  }
  return false;
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
    }
    // clause 3 — an OBSERVED use provably AFTER the gate: the record is LIVE,
    // it is the program's own data, and its dephasing is source semantics.
    //
    // "OBSERVED", NOT "MENTIONED" (owner ruling 2026-08-28, the F1 fix). The use
    // exempts only if its lineage reaches an observing sink — see
    // `reachesObservingSink`, which owns the whole SINK / HOP / NON-USE grammar
    // (teardown traffic and the F2 rotation arm included, so this loop no longer
    // pre-filters them: one place decides what a use means).
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
    if (!provablyBefore(T, UI, DT))
      continue;
    if (reachesObservingSink(UI, R, taint, DT))
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
        // Clause 1, in three passes over ONE shared record set (Inc 3):
        //   1. ANCESTORS of the wire, backward through producer / alloc /
        //      clone-return / copy-destination edges;
        //   2. DESCENDANTS of the wire, forward — the Increment-1 half;
        //   3. DESCENDANTS OF EVERY ANCESTOR — the ruling's "transitively
        //      entangled". This is the only pass that reaches a DEAD SIBLING
        //      standing under a LIVE (exempt) ancestor
        //      (lowering_reject_live_record_anc_dead_sibling.ll).
        // Clauses 2-5 are unchanged and are evaluated per record below.
        Value *W = T->getArgOperand(0);
        SmallVector<CallInst *, 8> Records;
        RecordSet RS(W, Records);
        SmallVector<Value *, 8> Seeds;
        collectAncestorRecords(W, RS, Seeds);
        SmallPtrSet<const Value *, 32> Seen;
        collectDescendantRecords(W, RS, Seen);
        for (Value *S : Seeds)
          collectDescendantRecords(S, RS, Seen);
        if (Records.empty())
          continue;
        if (!DT)
          DT.emplace(F);
        for (CallInst *R : Records) {
          // A record MINTED STRICTLY AFTER THE GATE cannot dephase it (the
          // Rule-13 round's F2 finding: the guard never tested that `R` exists
          // at `T`, so `q=theta; w=q*2; T; z=q*3` — `z` dead — DECLINED, a
          // false decline on a rail that is not allocated when the `Ry` fires).
          //
          // READ THE MODALITY. `provablyBefore(T, R)` is the CONDITIONAL-on-`R`
          // property: IF `R` executes then `T` already did, AND `T` is not
          // reachable again from `R`. That is exactly what is needed — a rail
          // that exists only after the gate is not standing at it — and the
          // second half is load-bearing, not decoration: a LOOP whose back edge
          // re-runs `T` over a record minted in the body fails
          // `isPotentiallyReachable`, so the record still counts. Skipping here
          // rather than inside `recordIsExemptAt` keeps the two questions apart:
          // this is "does R exist at the gate?" (clause 1's implicit premise),
          // not "is R live?" (clause 3).
          if (provablyBefore(T, R, *DT))
            continue;
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
