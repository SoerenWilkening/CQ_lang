// OpcodeLowering.h — Lower tainted arithmetic opcodes to template
// calls. Was inline in `CQLoweringPass.cpp` step 5 (pre-Phase-2-M12).
//
// M12 contract: walk every tainted `add i32` in the module, dispatch
// Q+Q vs Q+C based on taint-set membership of the operands, and emit
// the corresponding template call (`@cq_template_add_i32` or
// `..._hl`). Operand canonicalization rules (Phase 1 invariants):
//
//   * Q+Q: operands ordered by `BirthOrder` (lower-birth handle becomes
//     lhs). Stabilizes the trace `(h<lhs>, h<rhs>)` across clang
//     versions that may swap commutative-add operands by SSA index.
//   * Q+C: the handle is always lhs, the classical operand is always
//     rhs. The `_hl` template's C signature is `(handle, classical)`,
//     so swapping when LLVM landed the classical on the lhs is
//     required.
//
// "Classical" is determined by taint-set non-membership, not by
// `isa<ConstantInt>`: a function arg or runtime-loaded value that
// never touched a handle is just as classical as a literal `5`. The
// `lowering_q_plus_arg.ll` LIT fixture pins this.
//
// Mutates `taint` and `rebind`:
//   - The template result inherits the original add's taint; insert it,
//     erase the add from the taint set.
//   - `BirthOrder` gets a new entry for the template result so later
//     Q+Q canonicalization sees it.
//
// M13–M16 generalize the opcode set (`add iW` for W ∈ {1,8,16,32,64};
// `fadd fW` for fW ∈ {float, double}) by switching the type check on
// `Type::getIntegerBitWidth` / `Type::isFloatingPointTy` and routing
// the suffix through `WidthDispatch`.
//
// Spec: phases/phase2/PLAN.md §4.12, §4.16.

#ifndef CQ_IRPASS_OPCODE_LOWERING_H_
#define CQ_IRPASS_OPCODE_LOWERING_H_

#include "llvm/IR/Module.h"

namespace cq {

class WidthDispatch;
struct TaintSet;
struct RebindMap;

// Walks tainted i32 adds across `M`, lowers each in BB order, and
// updates `taint`/`rebind` as the new template-call SSA values replace
// the old adds.
void lowerOps(llvm::Module &M, WidthDispatch &wd, TaintSet &taint,
              RebindMap &rebind);

}  // namespace cq

#endif  // CQ_IRPASS_OPCODE_LOWERING_H_
