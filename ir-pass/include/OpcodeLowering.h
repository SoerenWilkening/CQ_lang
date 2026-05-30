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

// Walks tainted BinaryOperators in `M`, lowers each in BB order to
// its per-width template (or emits a "no template" diagnostic), and
// updates `taint` as template-call SSA values replace ops. Operand
// canonicalization reads `taint.BirthOrder` (seeded by RotationLowering).
void lowerOps(llvm::Module &M, WidthDispatch &wd, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_OPCODE_LOWERING_H_
