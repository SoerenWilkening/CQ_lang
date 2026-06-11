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

// Post-lift stale-record re-sweep (test_C_libtooling-2qyz) — PURE ANALYSIS,
// mutates no IR. Must run AFTER `declineClassicalMuxes` (whose one-register
// merge-phi lift RAUWs a phi to its wire base, exposing a stale-record consumer
// the earlier `declineStaleRecordOps` could not see through the opaque PHINode)
// and BEFORE any rotation lowering (pre-RAUW SSA identity). When a lift occurred
// (`taint.LiftedConsumers` non-empty) it re-runs the COMPLETE
// `declineStaleRecordOps` sweep on the post-lift IR — NOT scoped to the recorded
// direct consumers, because a stale op can sit any number of in-place-gate hops
// (Rz / chained Ry) downstream of the lifted phi (a Rule-13 adversarial finding;
// the direct-consumer subset is incomplete). The post-lift phi is the base SSA
// value, so the unchanged `WireWalk` closure walks every consumer's full wire.
// Idempotent — `checkStaleOp` skips `StaleDeclined`, so the first pass's
// diagnostics are never duplicated or re-pointed; only newly-exposed ops are
// diagnosed. Gated on the lift witness so non-lift modules incur no churn
// (opt exits at the first DS_Error). A no-op when nothing was lifted.
void declineLiftedStaleRecordOps(llvm::Module &M, TaintSet &taint);

// Walks tainted BinaryOperators in `M`, lowers each in BB order to
// its per-width template (or emits a "no template" diagnostic), and
// updates `taint` as template-call SSA values replace ops. Operand
// canonicalization reads `taint.BirthOrder` (seeded by RotationLowering).
// Skips `taint.StaleDeclined` members (diagnosed by `declineStaleRecordOps`).
void lowerOps(llvm::Module &M, WidthDispatch &wd, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_OPCODE_LOWERING_H_
