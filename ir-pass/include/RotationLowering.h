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

// ── M-A — the LATE live-record guard (bd test_C_libtooling-6uqc) ─────────────
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
// SCOPE — INCREMENTS 1 + 3 (descendants, then ancestors + the copy-destination
// class). A rail counts against a chained rotation `T` on wire `W` iff ALL of:
//   1. it is ENTANGLED with `W` — transitively, **ANCESTORS AND DESCENDANTS**,
//      `cqrt_alloc_*`-minted rails included (the ruled clause 1). Three closures,
//      unioned, all built in `declineLiveRecordRotations`:
//        (a) ANCESTORS of `W` — backward from its DEFINITION through
//            `cq_template_*` / `cqrt_qram_load_*` / `__cq_q_*` clone-call rail
//            operands, through phi/select router incomings, and — the edge that
//            crosses a severance — from a rail that is the DESTINATION operand of
//            a void `cqrt_copy_<W>` / `cqrt_copy_<W>_controlled` back to its SRC
//            and CONTROL flag. A `cqrt_alloc_*` is a record but its operand is a
//            classical seed, so the walk stops there.
//        (b) DESCENDANTS of `W` — forward, the Increment-1 half, now also
//            pushing a `__cq_q_*` clone RESULT and following the copy SRC→DST
//            edge.
//        (c) DESCENDANTS OF EVERY ANCESTOR — the ruling's "transitively
//            entangled". This is the only closure that reaches a DEAD SIBLING
//            standing under a LIVE (exempt) ancestor; pinned by
//            `lowering_reject_live_record_anc_dead_sibling.ll`.
//   2. it is NOT DISCHARGED before `T` — no `cqrt_free(R)`, and no `_unc` whose
//      OUT slot is `R`, provably before `T`.
//   3. it is DEAD as user data at `T` — **no use of `R` after `T` whose lineage
//      reaches an OBSERVING SINK**. This is the ruled wording verbatim (owner
//      2026-08-28, closing the Inc-3 Rule-13 round's F1 finding): "a record
//      exempts only if its lineage reaches an OBSERVING sink after the gate —
//      measure / ret / tape / a template read that itself flows to one (the
//      enumerated list stands as written)". `reachesObservingSink`
//      (RotationLowering.cpp) owns the grammar:
//        SINKS    `cqrt_measure_*` · `ret` (escape) · `cqrt_tape_write_*` in its
//                 written slot AND — round 2, below — in the CTRL slot of its
//                 3-argument guarded spelling.
//        HOPS     a non-void forward `cq_template_*` / `cqrt_qram_load_*` read ·
//                 a `__cq_q_*` clone call, but ONLY for an argument the clone
//                 actually READS (round 2) · a void `cqrt_copy_<W>[_controlled]`
//                 SRC/CTRL → its DST rail · `phi`/`select` ·
//                 `cqrt_qram_store_<W>[_controlled]` → through the array to every
//                 later load on the same handle · a CONTROL of the condition-tree
//                 node gates `cqrt_cnot`/`cqrt_toffoli` → their TARGET ancilla
//                 (round 2).
//        NON-USES `cqrt_free` · every `_unc`/`_inv` · `taint.SpineOps` · ALL
//                 rotations (the F2 ruling — a phase written onto a register
//                 nothing observes is unobservable) · the ROUTE/BRACKET gates
//                 `cqrt_cswap`/`cqrt_x` (a routed value returns to its own rail;
//                 a later measurement of that rail is a DIRECT user of it and
//                 counts on its own) · the TARGET slot of `cqrt_cnot`/
//                 `cqrt_toffoli` (the written rail's own users are scanned
//                 independently) · anything the walk does not model, which is the
//                 DECLINE direction.
//      ROUND 2 OF THE INC-3 RULE-13 ROUND (2026-08-28) MOVED THREE ENTRIES, TWO
//      OF THEM IN THE ACCEPT DIRECTION — say that plainly, because widening an
//      exemption grammar is the dangerous direction and each one is measured:
//        N1  `cqrt_cnot`/`cqrt_toffoli` were NON-USES beside `cqrt_cswap`/
//            `cqrt_x`, and the cswap rationale does NOT transfer: a route brings
//            a value back to its own rail, while a CNOT/Toffoli writes the
//            CONTROLS' information into a FRESH ancilla the merge then reads —
//            the `and`/`or`/`xor` node of a condition tree. A C-reachable
//            OVER-DECLINE, measured (`((c>3) & (d<9)) ? 10 : 20` with the result
//            measured). Pinned by
//            `lowering_live_record_condtree_toffoli_observed_accept.ll`,
//            `lowering_live_record_condtree_xor_observed_accept.ll`, and — the
//            discriminator that keeps the hop a HOP —
//            `lowering_reject_live_record_condtree_out_unobserved.ll`.
//        N2  a guarded tape write's CTRL slot is a SINK: the entry's PRESENCE OR
//            ABSENCE reveals the flag to whoever reads the tape. Also a
//            C-reachable over-decline, measured, while its SRC-slot twin always
//            accepted. Pinned by
//            `lowering_live_record_tape_ctrl_observed_accept.ll`.
//        N3  the DECLINE direction, and the only one of the three: the clone hop
//            no longer crosses an argument the callee IGNORES (its result cannot
//            depend on it). IR-only — `clang -O1` DAE drops such a parameter —
//            and ruled on constructed probes exactly as F1 and F2 were. Pinned by
//            `lowering_reject_live_record_clone_unused_arg.ll`; the used-parameter
//            control is `lowering_live_record_sibling_clone_arg_measured_accept.ll`.
//      A record that IS observed is LIVE ⇒ **ACCEPT**: it is the program's own
//      data and its dephasing is source semantics (owner ruling 2026-08-27; this
//      is what preserves `lowering_stale_record_add_before_theta.ll` and its
//      alias sibling BY PRINCIPLE, not as a special case).
//      ⚠ THE RETIRED READING WAS "MENTIONED LATER" AND IT OVER-ACCEPTED. Until
//      the F1 fix, ANY post-gate use that was not teardown exempted — so a dead
//      sibling whose only post-gate fate was a compare feeding a phase region
//      (flag routed, stripped, freed) exempted on route+compare mentions and the
//      module ACCEPTED, while the SAME program with the region written BEFORE the
//      gate DECLINED on identical rails
//      (`lowering_reject_live_record_sibling_region_after_theta.ll` vs
//      `lowering_reject_live_record_anc_dead_sibling.ll`).
//   4. it is not MEASURED before `T` (collapse exemption).
//   5. it is not `W` itself.
//   6. **it EXISTS at `T`** — `provablyBefore(T, R)` is FALSE. The F2 fix
//      (2026-08-28): a rail minted strictly after the gate is not allocated when
//      the `Ry` fires and cannot dephase it, so it is skipped before clauses 2-4
//      are ever asked. Read the modality — `provablyBefore(T, R)` is the
//      CONDITIONAL-on-`R` property (if `R` runs, `T` already did AND never runs
//      again), so a loop back edge that re-runs `T` over the record keeps it
//      counted (`lowering_reject_live_record_post_gate_record_loop.ll`).
//      Pinned by `lowering_live_record_post_gate_record_accept.ll`.
// Clause 1's walk DOES cross a Phase-6 `__cq_q_*` clone call (a value-preserving
// hop) — putting an expression behind a `noinline static` must not change the
// verdict — and since Increment 3 it also RECORDS the clone's result rail, which
// is the copy-destination class (`lowering_reject_live_record_clone_return_rail.ll`).
//
// ⚠ WHAT CLAUSE 1 STILL CANNOT SEE — READ THIS BEFORE WIDENING ANYTHING. A basis
// record written through a VOID gate into a `cqrt_alloc_*`-minted destination has
// NO producer edge to follow. Increment 3 closes three of the four such classes
// with the copy-destination edge above — `cqrt_copy_<W>` DESTINATIONS (value-arm
// answer rails, a clone's Bennett `cqq.out` return), SELECT-MERGE /
// SWITCH-DATA-MUX out rails, and VALUE-ARM MERGE outs. **`cqrt_qram_store_<W>`
// ARRAY CELLS remain the RULED-DEFERRED class** (owner 2026-08-27, second round,
// point 4): the walk stops dead at any `cqrt_qram_alloc_*` handle in both
// directions and never follows a store into a cell. Pinned by
// `lowering_qram_array_record_chained_theta_accept.ll`; visible as a boundary in
// `lowering_reject_live_record_qram_fp64_load_index.ll`, where the decline is
// carried entirely by the load's INDEX operands.
//
// ⚠ AND A MEASURED CORRECTION TO WHAT INCREMENT 1's NOTE SAID HERE. That note
// claimed the select/switch and value-arm classes were "unreachable today"
// because bd test_C_libtooling-lom0's position-free over-decline rejects their
// programs first. **Re-measured for Increment 3, that is three different facts,
// not one, and one of them was FALSE:**
//   * the `?:` SELECT spelling of the select-merge class was **NOT masked at
//     all** — `clang -O1` canonicalizes the natural C into a `select`;
//     `SelectClassify`'s position-free wire walk (SelectClassify.cpp ~691) is
//     seeded from the CONDITION's provenance, and the merge OUT is a fresh rail
//     off that wire, so a chained theta on the OUT never reaches it and the
//     program compiled end to end. A LIVE over-accept reachable from three lines of C.
//     Increment 3 closes it (`lowering_reject_live_record_select_merge_out.ll`,
//     `..._select_merge_tainted_src.ll`, both measured `opt` exit 0 at HEAD).
//   * a real `switch` + merge phi IS masked, but by `SwitchClassify`'s own
//     "control flow under quantum control", not by lom0
//     (`lowering_reject_live_record_switch_mux_out_masked.ll`).
//   * a real `br` value-arm diamond IS masked, by "value-arm swap-route under
//     quantum control" (`lowering_reject_live_record_valuearm_merge_out_masked.ll`).
// Of the four pins only the ROUTED-BASE phase region wears lom0's message
// (`lowering_reject_live_record_routed_base_anc_masked.ll`; `SelectClassify`
// emits the same string for a theta on a `?:`'s CONDITION wire — a different
// shape from the OUT rail). **Increment 4 must
// re-measure those four fixtures when it lifts lom0's decline**: each must land on
// this guard's message, never on `opt` exit 0.
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
