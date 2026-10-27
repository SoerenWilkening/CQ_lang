// Frozen interface (cq-arch). Changes only under cq-arch's freeze rule.
#pragma once

#include "cq/Lowering.h"
#include "cq/Predicate.h"
#include "cq/Taint.h"
#include "llvm/IR/Instructions.h"

// Switch.h  (rule 13)
namespace cq::sw {
EdgePreds switchEdges(const llvm::SwitchInst &, const TaintInfo &, const Specialization &);
void lowerSwitch(LoweringContext &, llvm::SwitchInst &);
}
