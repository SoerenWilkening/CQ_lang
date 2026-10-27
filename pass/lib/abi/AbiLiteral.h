// Module abi, private (not a frozen name; cq-arch freeze rule covers pass/include/cq only).
//
// CR §1.2 (3aaafe1, ruling cq-5iy at 8b52487): a commutative fp op swaps its classical operand behind
// the handle unless that operand is a compile-time NaN constant, which keeps its position; a run-time
// classical operand is always swapped. So fadd/fmul _lh and fma lqq/lql are valid names, but only for
// a call whose leading literal is a NaN constant. The name does not carry the literal, so this is a
// check on the call, not on the TemplateSpec.
#pragma once

#include <string>

#include "llvm/IR/InstrTypes.h"

namespace cq::abi::detail {
// Empty when `call` (a call of a cq_template_*) puts only a compile-time NaN constant (ConstantFP) in
// a position that only a NaN literal keeps (data operand 0 of fadd/fmul _lh and of fma lqq/lql); else
// the reason. A non-NaN constant or a run-time operand there is rejected: it should have been _hl
// (qlq/qll). A call of anything that is not a canonical template is an error.
std::string checkFpLiteralPosition(const llvm::CallBase &call);
} // namespace cq::abi::detail
