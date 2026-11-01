// mem-slots internal interface (not frozen): pointer-kind cells (cq-oocu; CR rules 20, 21; 107).
#pragma once

#include "cq/Lowering.h"
#include "llvm/IR/Argument.h"

namespace cq::mem {
// In a clone: formal A is a T4 triple (with or without its cell count) onto a caller's slot object whose cells
// the clone accesses are all of pointer kind (two mask digits per accessed cell, CR §1.4). mem-slots lowers its
// accesses (spine dispatch routes them there, not to fatptr's bound slot loads).
bool isPointerKindFormal(LoweringContext &, const llvm::Argument &A);
}
