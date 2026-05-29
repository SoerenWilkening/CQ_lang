// OpcodeLowering.h — Lower tainted arithmetic opcodes to per-width
// template calls. Originally inline in `CQLoweringPass.cpp` step 5.
//
// Contract: walk every tainted BinaryOperator, dispatch Q+Q vs Q+C
// from operand-taint membership, and emit the matching template:
//
//   * `add iW`  for W ∈ {1, 8, 16, 32, 64}
//   * `fadd fW` for fW ∈ {float (f32), double (f64)}
//
// Width comes from `Type::getIntegerBitWidth()` / `isFloatTy()` /
// `isDoubleTy()`; the symbol is `WidthDispatch::addTemplate(W, isQQ)`.
//
// Operand canonicalization (invariants preserved):
//   * Q+Q: operands ordered by `BirthOrder` (lower-birth becomes lhs).
//     Stabilizes the trace across clang versions that may swap
//     commutative-add operands by SSA index.
//   * Q+C: handle is always lhs, classical operand always rhs. The
//     `_hl` template's signature is `(handle, classical)`; we swap
//     when LLVM landed the classical on the lhs.
//
// "Classical" = taint-set non-membership, NOT `isa<ConstantInt>`: a
// function arg never touched by a handle is classical too. The
// `lowering_q_plus_arg.ll` LIT fixture pins this.
//
// Negative path: a tainted op whose opcode is not `add`/`fadd` (e.g.
// `sub`), or whose width has no template (e.g. `i128`, `half`), emits
// a `DiagnosticInfoUnsupported` "no template for opcode" error. PRD
// §"Diagnostics baseline" mandates this stay loud, not silent;
// template coverage will widen later.
//
// Mutates `taint`: the template result inherits the op's taint and the
// next `taint.BirthOrder` slot; the original op is dropped from the set.

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
