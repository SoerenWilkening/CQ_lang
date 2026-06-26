// ArithLowering.h — Lower tainted data-arithmetic opcodes to template
// calls. Split out of `OpcodeLowering` in Phase 3 (PRD §1, IMPLEMENTATION
// §3): the driver owns collection / ordering / erase; this TU owns the
// per-instruction emit + RAUW + taint bookkeeping for the two data classes
// it covers:
//
//   * `BinaryOperator` — all 16 in-scope stems (int arith/bitwise + fp
//     arith), HH/HL/LH operand shapes, commutativity-gated BirthOrder.
//   * `UnaryOperator`  — `fneg` (fp only), the single unary data op.
//
// (`fneg` lives here rather than its own TU per Decision D3 — it is ~30 LOC
// and shares the data-handle bookkeeping. Split point if this TU nears
// 300.)
//
// Operand classification (PRD §2.4) reads `taint.Tainted` membership — NOT
// `isa<Constant>` — so it correctly treats tainted args/loads as handles
// and untainted args/literals/globals as classical:
//
//   * HH (both tainted): symmetric QQ template. Commutative stems order
//     operands by `BirthOrder` (lower-birth → LHS) for clang-version-stable
//     traces; non-commutative stems PRESERVE source operand order (the
//     BirthOrder swap is gated OFF — operand order is semantic).
//   * HL/LH (one tainted): commutative ops canonicalize the literal to the
//     RHS → `_hl(handle, classical)`. Non-commutative ops preserve order:
//     handle-on-left → `_hl(handle, classical)`; literal-on-left → `_lh`
//     `(classical, handle)` (e.g. `100 - x`, `3 << x`).
//
// Each rewriter performs emit + RAUW + taint/BirthOrder bookkeeping but
// does NOT erase the original — the driver owns erase (the work list IS the
// set of originals). An unsupported stem or width emits the loud
// `diagnoseNoTemplate` and leaves the op un-lowered (the driver then must
// not erase it; see the driver's erase contract).

#ifndef CQ_IRPASS_ARITH_LOWERING_H_
#define CQ_IRPASS_ARITH_LOWERING_H_

namespace llvm {
class BinaryOperator;
class UnaryOperator;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;

// Lower one tainted `BinaryOperator` to its data template. Returns true if
// the op was rewritten (RAUW'd, bookkept) and is therefore safe for the
// driver to erase; false if it was diagnosed/left un-lowered (the driver
// must NOT erase it). All 16 in-scope stems; HH/HL/LH per the rules above.
bool rewriteBinary(llvm::BinaryOperator *bo, WidthDispatch &wd,
                   TaintSet &taint);

// Lower one tainted `UnaryOperator` (`fneg`) to `cq_template_fneg_<W>`.
// Same return contract as `rewriteBinary`. FP widths only.
bool rewriteUnary(llvm::UnaryOperator *uo, WidthDispatch &wd, TaintSet &taint);

// Issue dtzb — lower a recognized loop-rail SELF-UPDATE (`bo` ∈
// `taint.InPlaceRailOps`, a `lowerLoops`-proven `q = q OP c` with OP ∈
// {add, xor} and a classical immediate) to the IN-PLACE
// `cqrt_{addc,xorc}_<W>(handle, imm)` instead of the out-of-place data template
// `rewriteBinary` would emit (which mints a fresh per-iteration rail — the X1
// dirty rail). By this stage the rail operand is the i32 handle (rotation
// lowering already ran); `imm` is the classical operand at the rail's logical
// width. The result is RAUW'd to the handle (in-place keeps the same register).
// Same return contract as `rewriteBinary`; only reached for a proven in-place
// rail op (the caller gates on `InPlaceRailOps` membership).
bool rewriteInPlaceValueRail(llvm::BinaryOperator *bo, WidthDispatch &wd,
                             TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_ARITH_LOWERING_H_
