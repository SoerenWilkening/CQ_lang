// Module-internal interface of fatptr for mem-qram (both stream C's, not frozen): pointers held in a
// QRAM of pointers (rule 21, 88).
#pragma once

#include <utility>

#include "cq/Common.h"
#include "cq/Lowering.h"
#include "llvm/IR/Value.h"

namespace cq::fatptr {
// The fat pointer (tag, idx) of ptr as two i32 operands (each a rail or a classical i32): what a QRAM
// of pointers stores. The tag is ptr's root number in its function's object table; the idx a cell index.
std::pair<Operand, Operand> storedFields(LoweringContext &, const llvm::Value *ptr);
// A pointer loaded from a QRAM of pointers (or through a fat pointer over such QRAMs) is bound by its
// loader with ctx.bindFields(load, {tag, idx}), two i32 rails; fatptr's derivation reads them back.
}
