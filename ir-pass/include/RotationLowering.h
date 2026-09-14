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
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Module.h"

namespace llvm {
class CallInst;
class Value;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;
struct ControlPlan;

// Strip a known prefix (`cq_theta_` / `cq_phi_`) from a rotation call's callee
// name → the intrinsic suffix (`si32`). Returns "" on mismatch (indirect callee,
// or a name that does not start with `Prefix`).
//
// EXPORTED since bd drbq Inc 2b, and the reason is a recorded hazard rather than
// convenience (Inc-1 notes §3d, the "latent" row): detection and mint derive the
// ABI width from two different EXPRESSIONS — `ArmClassify`'s R4 asks
// `abiWidthHasControlledRotation(abiWidthFromType(T->getType()))` while
// `lowerRotations` mints from `wd.abiWidthFor(suffixFromName(T, "cq_theta_"))`.
// The PREDICATE is shared; its ARGUMENT was not, so a divergence would decline
// AFTER mutation. `classifyAngleSelect` therefore asks the MINT's expression
// verbatim, which is only possible with this declaration. Inc 1's own spelling is
// deliberately left alone (changing it is a Rule-13 change to R4's accept set);
// they agree for every `CQ.h` suffix measured.
llvm::StringRef suffixFromName(const llvm::CallInst *CI, llvm::StringRef Prefix);

// bd z9t1 (owner ruling 2026-09-14) — THE UNDEF SEED IS A ZERO AT THE
// ALLOCATION. Rewrites a whole-value `undef`/`poison` arg-0 of ONE SOURCE
// `@cq_theta_<sfx>` call to `Constant::getNullValue` of that type, AND every
// `UndefValue` incoming of EVERY `phi` that has this theta's result as an
// operand. Returns true iff it changed anything. SILENT by ruling: no
// diagnostic, no warning, exit 0.
//
// ⚠ THE PHI HALF IS A SUPERSET OF "THE SAME UNINITIALIZED OBJECT READ TWICE",
// which is the MOTIVATION and was once written here as if it were the scope
// (review round 2 F-U2-2, re-measured at scale by round 3 F-U3-2). Several phis
// per theta, several incomings per phi, and objects the source never equated
// all move; the soundness ground is the per-`undef` REFINEMENT, and the
// widening it admits is DISCLOSED at the definition, not fenced. Counts,
// population and probes: the definition's scope + disclosure paragraphs.
//
// CALLED FROM `collectAndSeed` (TaintPropagation.cpp), i.e. from inside
// `propagate`, which is the ONE funnel both pipeline entry points and every
// re-propagate fixpoint round come through — see the long comment at the
// definition for the placement argument and for what the rule deliberately does
// NOT reach. ⚠ That funnel discharges L1 for the SEED half; the PHI half is
// ONE-SHOT (the `valueCarriesUndef` gate makes it unreachable after round 1)
// and rests on three MEASURED facts with three retirement triggers — F-U3-4,
// at the definition's PLACEMENT section.
//
// ⚠ WHEN THIS CALL'S ANGLE (arg-1) ALSO CARRIES AN UNDEF, THE REWRITE DELETES
// ONE OF THE TWO SLOTS `declineUnpairedUndefLiterals` (GUARD 1) WAS COUNTING,
// and a module the ORACLE declined compiles silently emitting
// `cqrt_ry_<W>(h, undef)` — review round 1, finding F-U1-1, MEASURED. No
// conjunct is added for it: whether that decline was protecting a real pairing
// break or was a `undef`-is-uniqued-per-type COINCIDENCE is an OPEN OWNER
// QUESTION. See the definition's F-U1-1 paragraph and `$SES/trackU/FIX_U_R1.md`.
// A DEFINED seed with an undef angle is a different, BLESSED case and is not
// affected either way.
bool normalizeUndefRotationSeed(llvm::CallInst *Theta);

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

// ⚠ `emitRz` IS **DELETED** (bd test_C_libtooling-3qlq Inc 1 part B) — the
// `cq_phi` gate-body emitter of the retired REGISTER form, whose two arms minted
// the TENSORED `cqrt_rz_<W>` / `cqrt_rz_<W>_controlled`. See the note at the top
// of RotationLowering.cpp for why that gate was wrong and what replaced it
// (kickback: an UNCONTROLLED `cqrt_rz_i1` on the condition FLAG). Do not
// reintroduce a per-register Rz for a `cq_phi`.

// ── M-A — the LATE live-record WARNING (bd test_C_libtooling-6uqc / lyyf) ────
//
// A chained `cq_theta` is an IN-PLACE, NON-DIAGONAL `Ry` on a wire that may
// still carry basis RECORDS of its own value — `cq_template_*` /
// `cqrt_qram_load_*` rails computed from that wire and never uncomputed, never
// freed. A record entangled with the wire when the `Ry` fires makes the wire's
// reduced state diagonal, so the rotation cannot interfere amplitudes: the
// circuit computes different measurement statistics than a reader of the source
// would expect. `opt -verify` is clean, the golden trace is self-consistent, and
// `free_pairing_check.py` reports zero violations (bd 1739's template-rail
// blindness), so nothing else in the pipeline can see it either.
//
// ⚠ IT IS A WARNING, NOT A DECLINE — OWNER RULING 2026-08-29 (bd lyyf,
// implemented as Increment 7b). Verbatim: "w is entangled, but we can always
// apply any unitary operation we want. Again, it is the user's fault to have
// produced a badly functioning code", and "we do not want to decline any kind of
// code that is in principle compilable" (Rule 17). The dephasing-by-leftover-
// record class is the USER's circuit: every gate this guard names is a perfectly
// realizable unitary, so the compiler emits it and SAYS SO. Lowering proceeds,
// and the named record is LEFT ALLOCATED — Rule 6 is untouched, because nothing
// here ever freed anything: this function is pure analysis and the record's
// non-free is the M-B spine's own leak-first fallback.
//
// WHAT THE RULING DOES NOT COVER, and the line is not a matter of taste. It
// reverses the DECLINE half of the 2026-08-27 M-A ruling and NOTHING ELSE. The
// WRONG-VALUE guards — `declineStaleRecordOps`, `ArmClassify`'s condition-wire
// and mint-at-compare fences, `declineTaintEscapes`, `declineClassicalMuxes` —
// and the DIRTY-FREE guards — `FreePoint`'s and `Uncomputation`'s loud declines
// — stay LOUD. Those are miscompile classes: a wrong basis label, or a
// `cqrt_free` on a rail that is not `|0>` (a hidden measurement that collapses
// the register). "The user asked for a badly-conditioned circuit" is a defence
// for a dephased answer; it is not a defence for computing a different function
// or for measuring a register the user never measured.
//
// WHY IT STILL SPEAKS AT ALL, since the ruling would also permit silence: the
// user is told WHICH gate carries a live record, which is the one fact no
// downstream artifact can recover (the trace shows angles, stage 2b shows rail
// pairing, and neither can say "this Ry was dephased"). Orchestrator's call,
// recorded on bd lyyf; the owner may drop the diagnostic later.
//
// SCOPE — INCREMENTS 1 + 3 (descendants, then ancestors + the copy-destination
// class). A rail counts against a chained rotation `T` on wire `W` iff ALL of:
//   1. it is ENTANGLED with `W` — transitively, **ANCESTORS AND DESCENDANTS**,
//      `cqrt_alloc_*`-minted rails included (the ruled clause 1). Three closures,
//      unioned, all built in `warnLiveRecordRotations`:
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
//      A record that IS observed is LIVE ⇒ **NO WARNING**: it is the program's
//      own data and its dephasing is source semantics (owner ruling 2026-08-27;
//      this is what preserves `lowering_stale_record_add_before_theta.ll` and its
//      alias sibling BY PRINCIPLE, not as a special case). Note the clause is
//      still worth its full cost under the 2026-08-29 ruling: a warning on every
//      chained rotation over live user data would be noise, and this is what
//      keeps the report down to the genuinely dead residue.
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
// Of the four pins only the ROUTED-BASE phase region wore lom0's message
// (`SelectClassify` emits the same string for a theta on a `?:`'s CONDITION
// wire — a different shape from the OUT rail). RE-MEASURED AT INCREMENT 4, when
// lom0's position-free decline was lifted for the flat phase shape: that one
// fixture DID move to this guard's message and was renamed
// `lowering_reject_live_record_routed_base_anc.ll` (its `mul`-minted `r` leaves
// `q`'s alloc rail live, dead and entangled); the other three are byte-identical
// across the lift, since none of them ever declined at `ArmClassify`'s wire
// walk. None landed on `opt` exit 0.
// The per-class detail and the measured spellings live at `isRecordProducer` in
// RotationLowering.cpp.
//
// WHY THE LATE SLOT. Run post-`uncompute`, module-wide, on the
// `declineUnpairedUndefLiterals` precedent: only here are "still undischarged at
// the gate" and "no user reads it after the gate" FACTS about the emitted stream
// rather than PREDICTIONS about what Phase 4's strip and Phase 5's placement are
// going to do. Earlier-stage DECLINES still own their messages — `opt` exits at
// the first `DS_Error`, long before this slot — and that ordering is now the
// reason this one is reached at all rather than a reason it is last.
//
// Warns once per OFFENDING GATE (the first record that counts against it), with
// that gate's `!dbg`, at `DS_Warning` — so `opt` prints `warning: …` and exits
// ZERO. It no longer stops at the first: a decline had to (the pass was over),
// while a warning that hid the second site would send the author round the loop
// once per record. Returns true iff any gate was warned about; the caller does
// NOT branch on it (there is nothing left to abandon), and it exists for
// unit-level callers and for the fixture that asserts silence. Pure analysis —
// mutates nothing.
bool warnLiveRecordRotations(llvm::Module &M, const TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_ROTATION_LOWERING_H_
