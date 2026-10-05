// OpcodeLowering.h — The single ordered driver for tainted data-opcode
// lowering (Phase 3). Originally inline in `CQLoweringPass.cpp` step 5;
// in Phase 3 it is the collect-classify-dispatch-erase loop and the
// per-instruction emit moves out to the class lowerers.
//
// Contract: ONE program-order walk over all four tainted instruction
// classes (`BinaryOperator`, `UnaryOperator`, `CmpInst`, `CastInst`)
// builds a program-order work list (and captures each cast's (from,to)
// ABI widths BEFORE any RAUW corrupts the operand type; PRD §2.3). The
// driver then rewrites in program order — dispatching by `dyn_cast` to
// `ArithLowering::rewriteBinary` / `rewriteUnary` (live in WP3) and the
// compare/cast arms (inert until WP4/WP5) — and finally erases ONLY the
// instructions a rewriter actually rewrote. A rewriter that diagnoses or
// leaves an op un-lowered returns false, and the driver leaves that op in
// the IR (erasing a still-used value would break `opt -verify`).
//
// Single program-order collection (not per-class) keeps producer-before-
// consumer without per-class ordering assumptions: SSA dominance ⇒
// producers precede consumers, so a consumer's operands are already
// template handles (and already tainted) when it is rewritten.
//
// Operand classification / canonicalization and the loud "no template"
// diagnostic live in the lowerers + `OpcodeSupport`; see `ArithLowering.h`.
//
// Mutates `taint`: each rewriter promotes its template result into the
// taint set with the next `taint.BirthOrder` slot and drops the original.

#ifndef CQ_IRPASS_OPCODE_LOWERING_H_

#include "llvm/ADT/SmallPtrSet.h"
#define CQ_IRPASS_OPCODE_LOWERING_H_

#include "llvm/IR/Module.h"

namespace cq {

class WidthDispatch;
struct TaintSet;

// Straight-line stale-record guard (test_C_libtooling-uzb) — PURE ANALYSIS,
// mutates no IR; must run BEFORE any lowering (Rule 9): it needs SSA-record
// identity (rotation lowering's RAUW collapses the pre-Ry and post-Ry values
// onto one i32 handle) and the original schedule (the positions templates and
// ry calls will be emitted at). For every instruction `lowerOps` would lower,
// it walks each tainted operand's forward in-place-gate wire
// (`WireWalk::findNonDiagonalWireGate`, position-aware mode) and — when the
// wire gains a tainted-operand `cq_theta` (non-diagonal Ry) that is not
// provably after every execution of the op — fires the loud
// `DiagnosticInfoUnsupported` and records the op in `taint.StaleDeclined` so
// `lowerOps` lowers nothing for it. SSA says the operand denotes the wire's
// PRE-Ry record; the template, an opaque call emitted at the op's scheduled
// position, would read the POST-Ry basis: a verify-clean wrong unitary
// (MINT_AT_COMPARE.md §4 residual exposure; oracle P2 fidelity cos^2(t2/2)).
// Branch/select-condition compares are excluded — they are Phase 4's, and
// ArmClassify's provenance-seeded wire walk owns their stale check.
void declineStaleRecordOps(llvm::Module &M, TaintSet &taint);

// (bd test_C_libtooling-3d8q, P1) THE STALE-READER BACKSTOP, in two halves.
//
// `recordStaleQuantumReaders` is PURE ANALYSIS at the EARLY slot (beside
// `declineStaleRecordOps`, before `lowerLoops` / the peel / control detection):
// it asks the same linear rule, of the same walker, for the reader families
// `inLowerOpsScope` does not cover — a `@cq_theta_<sfx>` (ARG-0 ONLY, Rule 3) or
// `@cq_measure_<sfx>` call reading a name the wire has moved past — and RECORDS
// the offenders in `taint.StaleQuantumReaders`. It diagnoses NOTHING.
//
// `declineRecordedStaleQuantumReaders` emits the loud decline at the LATE slot
// (after the round-2 fixpoint, before `declineClassicalMuxes` and
// `lowerRotations`), for every recorded reader that still exists.
//
// The split is load-bearing in BOTH directions and `TaintSet::StaleQuantumReaders`
// carries the measurements: analysed late, the loop-rail collapse has replaced the
// per-trip barrier φ with the loop-invariant mint and 9 shipped ACCEPT fixtures
// flip; diagnosed early, this fence preempts 68 shipped negative fixtures whose
// subjects are other, more precise owners.
// `Delta` (bd 3d8q, the round-2 half): when non-null, ONLY readers whose record
// operand is a member are analysed. That is how the taint-GROWTH events pay the
// L1 obligation without re-asking the whole module on rewritten IR — see the .cpp.
void recordStaleQuantumReaders(
    llvm::Module &M, TaintSet &taint,
    const llvm::SmallPtrSetImpl<llvm::Value *> *Delta = nullptr);
void declineRecordedStaleQuantumReaders(llvm::Module &M, TaintSet &taint);

// Post-lift stale-record re-sweep (test_C_libtooling-2qyz) — PURE ANALYSIS,
// mutates no IR. Must run AFTER `declineClassicalMuxes` (whose one-register
// merge-phi lift RAUWs a phi to its wire base, exposing a stale-record consumer
// the earlier `declineStaleRecordOps` could not see through the opaque PHINode)
// and BEFORE any rotation lowering (pre-RAUW SSA identity). When a lift occurred
// (`taint.LiftedMergePhis` non-empty — the lift EVENT, bd ec7r) it re-runs the COMPLETE
// `declineStaleRecordOps` sweep on the post-lift IR — NOT scoped to the recorded
// direct consumers, because a stale op can sit any number of in-place-gate hops
// (Rz / chained Ry) downstream of the lifted phi (a Rule-13 adversarial finding;
// the direct-consumer subset is incomplete). The post-lift phi is the base SSA
// value, so the unchanged `WireWalk` closure walks every consumer's full wire.
// Idempotent — `checkStaleOp` skips `StaleDeclined`, so the first pass's
// diagnostics are never duplicated or re-pointed; only newly-exposed ops are
// diagnosed. Gated on the lift witness so non-lift modules incur no churn
// (opt exits at the first DS_Error). A no-op when nothing was lifted.
// PER USE (bd test_C_libtooling-dm7f.1 / -r2j3.11): a read the lift recorded as a
// read of the phi (`TaintSet::LiftedMergePhi::Uses`, directly or through an
// in-place `cq_theta` chain) is exempt from the gates on that phi's per-path
// record and nothing else, and the `@cq_theta_*` / `@cq_measure_*` readers of a
// lifted phi are re-asked here under the same exemption (recorded into
// `taint.StaleQuantumReaders` for the late drain).
void declineLiftedStaleRecordOps(llvm::Module &M, TaintSet &taint);

// Walks tainted BinaryOperators in `M`, lowers each in BB order to
// its per-width template (or emits a "no template" diagnostic), and
// updates `taint` as template-call SSA values replace ops. Operand
// canonicalization reads `taint.BirthOrder` (seeded by RotationLowering).
// Skips `taint.StaleDeclined` members (diagnosed by `declineStaleRecordOps`).
//
// `inBennettClone` (bd test_C_libtooling-6uqc Inc 2a) — set by `specialize`,
// which calls this on a Phase-6 SPECIALIZATION CLONE body under a disjoint
// `cloneTaint`. It disables the M-C in-place-reassignment widening, and that is
// a CORRECTNESS fence, not a scope preference:
//   * a clone's forward stream is captured AFTERWARDS by scanning the body for
//     `isForwardTemplate` / clone-call / select-op members. A `cqrt_addc_<W>` is
//     none of those, so it would be SILENTLY OMITTED from `ForwardStream` and
//     `emitBennettWrap` would never reverse it — a permanent, unpaired mutation
//     of a rail, in a function whose whole contract is that it is reversed;
//   * worse, the parent it mutates is typically a BORROWED clone ARGUMENT, and
//     Bennett's `|x>|0> -> |x>|f(x)>` requires the inputs to come back untouched.
//     Mutating one in place breaks the wrap's `_unc` twin for every caller.
// The same-named parameter on `lowerQramReads` sets the precedent for spelling
// this as an explicit flag rather than inferring "am I in a clone?" from the IR.
void lowerOps(llvm::Module &M, WidthDispatch &wd, TaintSet &taint,
              bool inBennettClone = false);

}  // namespace cq

#endif  // CQ_IRPASS_OPCODE_LOWERING_H_
