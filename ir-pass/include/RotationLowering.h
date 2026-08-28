// RotationLowering.h — Lower `@cq_theta_<sfx>` and `@cq_phi_<sfx>` to
// runtime rotation calls. Replaces the retired mid-struct rebind module:
// under the plain-SSA surface there are no mid-structs to rebind, so
// gate-triggered allocation now happens here, at the theta call site.
//
// Contract (algorithm in RotationLowering.cpp; backend.md §5.1):
//   * The arg-1 ANGLE of EITHER rotation must be classical (untainted). A
//     quantum-derived angle has no fixed unitary → loud decline before any
//     emission, rotation left standing (test_C_libtooling-659; the
//     straight-line twin of ArmClassify::taintedAngleGate).
//   * `@cq_theta_<sfx>(operand, angle)`:
//       - classical operand → emit `cqrt_alloc_<W>(operand)` then
//         `cqrt_ry_<W>(handle, angle)`; RAUW the theta result to the i32
//         alloc handle; mark the handle tainted; seed `taint.BirthOrder`.
//       - tainted operand (a chained theta) → emit `cqrt_ry_<W>` on the
//         existing handle only; RAUW the theta result to that operand.
//   * `@cq_phi_<sfx>(operand, angle)`:
//       - tainted operand → emit `cqrt_rz_<W>(handle, angle)`.
//       - classical operand → no rz (Rz on a basis state is unobservable).
//       - RAUW the phi result to its operand either way, then erase.
//
// The theta result's natural type (e.g. `double` for f64) may differ from
// the i32 handle it is RAUW'd to — that cross-type RAUW is laundered by
// erasure (every tainted user is itself lowered to a handle-consuming call
// and erased before the verifier; see IMPLEMENTATION.md §1). The void
// `ry`/`rz` call is NEVER the RAUW target (PRD §2.5).

#ifndef CQ_IRPASS_ROTATION_LOWERING_H_
#define CQ_IRPASS_ROTATION_LOWERING_H_

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Module.h"

namespace llvm {
class CallInst;
class Value;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;
struct ControlPlan;

// Lowers every `@cq_theta_<sfx>` / `@cq_phi_<sfx>` collected by
// `propagate` (in `taint.ThetaCalls` / `taint.PhiCalls`), in BB order, and
// erases the originals. Mutates `taint`: inserts minted alloc handles into
// `taint.Tainted`, seeds `taint.BirthOrder`, and records each handle's logical
// ABI width in `taint.HandleWidth` (from the `cq_theta` classical operand,
// before any RAUW launders it — §5.6). `plan` (may be null) names the
// in-shadow gate-body `cq_phi` calls: those are skipped here. For the 4.1
// swap-route emitter (`SwapRouteEmit::lowerControlRegions`) this set is EMPTY
// — it runs before this pass and erases each arm `cq_phi` (§3), so the skip
// never fires; the hook is retained for the §6a control-in-place peephole.
void lowerRotations(llvm::Module &M, WidthDispatch &wd, TaintSet &taint,
                    const ControlPlan *plan = nullptr);

// Emit the `cq_phi` gate body as a runtime Rz on the i32 `handle`, controlled
// or uncontrolled (IMPLEMENTATION §5.1/§5.4). Uncontrolled →
// `cqrt_rz_<W>(handle, angle)`; controlled → `cqrt_rz_<W>_controlled(flag,
// handle, angle)` with the flag prepended as arg 0 (PRD §1.2, via
// `ControlledSymbols::controlledRotationFn`). `phi` supplies the width suffix,
// debug loc, and insertion point; the Rz is inserted before it. Returns true
// iff the Rz was emitted (false ⇒ unsupported width, diagnosed loudly, `phi`
// left standing for the verifier). Today only `lowerRotations` calls it
// (uncontrolled); the controlled form is retained solely for the optional §6a
// control-in-place peephole (`ControlledSymbols::controlledRotationFn` reserve
// — `ControlledSubstitution` was excised in 7cde677). PRECONDITION: the caller has
// verified `angle` is classical (untainted) — `lowerRotations` declines a
// tainted angle before calling (test_C_libtooling-659).
// `rec` (M-A Inc 1, bd test_C_libtooling-6uqc), when non-null, receives the
// UNCONTROLLED Rz this call mints — `lowerRotations` passes
// `&taint.UserPhaseRotations` so the late live-record guard can tell a USER
// `cq_phi` gate from the spine's negated-angle adjoint Rz (the two are the same
// call textually).
bool emitRz(llvm::CallInst *phi, llvm::Value *handle, llvm::Value *angle,
            WidthDispatch &wd, bool controlled, llvm::Value *flag,
            llvm::SmallPtrSetImpl<const llvm::CallInst *> *rec = nullptr);

// ── M-A Increment 1 — the LATE live-record guard (bd test_C_libtooling-6uqc) ──
//
// A chained `cq_theta` is an IN-PLACE, NON-DIAGONAL `Ry` on a wire that may
// still carry basis RECORDS of its own value — `cq_template_*` /
// `cqrt_qram_load_*` rails computed from that wire and never uncomputed, never
// freed. A record entangled with the wire when the `Ry` fires makes the wire's
// reduced state diagonal, so the rotation cannot interfere amplitudes: the
// emitted unitary diverges from the source's. `opt -verify` is clean, the golden
// trace is self-consistent, and `free_pairing_check.py` reports zero violations
// (bd 1739's template-rail blindness) — the exact silent-miscompile signature
// this project exists to stop.
//
// SCOPE — INCREMENT 1 IS THE **DESCENDANT** HALF ONLY. A rail counts against a
// chained rotation `T` on wire `W` iff ALL of:
//   1. it is a DESCENDANT record of `W` — transitively minted FROM `W` (or from
//      another counting record) by a `cq_template_*` / `cqrt_qram_load_*`
//      producer. ANCESTORS (incl. the `cqrt_alloc_*`-minted parent and an
//      out-of-place `_hl` template's source rail) are **Inc 3**, deliberately
//      NOT implemented here: they carry `slice_control_seq_grover`, whose golden
//      must not redden before M-C (Inc 2) removes the ancestor mint.
//   2. it is NOT DISCHARGED before `T` — no `cqrt_free(R)`, and no `_unc` whose
//      OUT slot is `R`, provably before `T`.
//   3. it is DEAD as user data at `T` — no use of `R` after `T` other than
//      teardown traffic (its own discharge, an `_unc` that merely READS it, the
//      spine's adjoint rotations, and the recorded `SpineOps`). A post-`T`
//      `cqrt_measure_*`, a forward template read, a route/copy/tape sink or a
//      plain-IR use IS user data ⇒ the record is LIVE ⇒ **ACCEPT**: a live
//      record is the program's own data and its dephasing is source semantics
//      (owner ruling 2026-08-27; this is what preserves
//      `lowering_stale_record_add_before_theta.ll` and its alias sibling BY
//      PRINCIPLE, not as a special case).
//   4. it is not MEASURED before `T` (collapse exemption).
//   5. it is not `W` itself.
// Clause 1's walk DOES cross a Phase-6 `__cq_q_*` clone call (a value-preserving
// hop) without recording its result — putting an expression behind a `noinline
// static` must not change the verdict.
//
// ⚠ WHAT CLAUSE 1 STILL CANNOT SEE — READ THIS BEFORE WIDENING ANYTHING. A basis
// record written through a VOID gate into a `cqrt_alloc_*`-minted destination has
// NO producer edge to follow, so a producer walk cannot reach it at all. Four
// such classes exist: `cqrt_copy_<W>` DESTINATIONS (a value-arm answer rail, a
// clone's Bennett `cqq.out` return), SELECT-MERGE / SWITCH-DATA-MUX out rails,
// VALUE-ARM MERGE outs, and `cqrt_qram_store_<W>` ARRAY CELLS. Their measured
// reachability is NOT uniform, and the difference is the whole point:
//   * the select/switch and value-arm classes are unreachable today only because
//     bd test_C_libtooling-lom0's UNRELATED position-free over-decline rejects
//     their programs first. That is incidental cover, and **Increment 4 must
//     re-close them BEFORE it lifts that decline** — otherwise lifting converts a
//     masked severance into a live over-accept.
//   * the clone-return rail is **NOT covered by anything and IS reachable from
//     plain straight-line C today** — this guard accepts it (measured; pinned by
//     `lowering_live_record_clone_return_rail_accept.ll`). So Increment 1 does
//     NOT fully close bd 6uqc's P4 even without control flow.
//   * QRAM ARRAY handles (`cqrt_qram_alloc_*`) are the RULED-DEFERRED class
//     (owner 2026-08-27, point 4), pinned by
//     `lowering_qram_array_record_chained_theta_accept.ll`.
// The per-class detail and the measured spellings live at `isRecordProducer` in
// RotationLowering.cpp.
//
// WHY THE LATE SLOT. Run post-`uncompute`, module-wide, on the
// `declineUnpairedUndefLiterals` precedent: only here are "still undischarged at
// the gate" and "no user reads it after the gate" FACTS about the emitted stream
// rather than PREDICTIONS about what Phase 4's strip and Phase 5's placement are
// going to do. Earlier-stage declines still own their messages — `opt` exits at
// the first `DS_Error`, long before this slot.
//
// Returns true (and has diagnosed the FIRST offending rotation loudly, with its
// `!dbg`) iff a live-record violation was found. Pure analysis — mutates nothing.
bool declineLiveRecordRotations(llvm::Module &M, const TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_ROTATION_LOWERING_H_
