// Module abi, private (not a frozen name; cq-arch freeze rule covers pass/include/cq only).
//
// CR §1.2 (3aaafe1): a commutative fp op swaps a literal operand behind the handle only when the
// literal is not a NaN; a NaN literal keeps its position. So fadd/fmul _lh and fma lqq/lql are
// valid names, but only for a call whose leading literal is a NaN. The name does not carry the
// literal, so this is a check on the call, not on the TemplateSpec.
#pragma once

#include <string>

#include "llvm/IR/InstrTypes.h"

namespace cq::abi::detail {
// Empty when `call` (a call of a cq_template_*) puts no non-NaN constant in a position that only a
// NaN literal keeps (data operand 0 of fadd/fmul _lh and of fma lqq/lql); else the reason. A
// classical operand that is not a constant is accepted: its NaN-ness is not known when lowering
// (open question cq-5iy). A call of anything that is not a canonical template is an error.
std::string checkFpLiteralPosition(const llvm::CallBase &call);
} // namespace cq::abi::detail
