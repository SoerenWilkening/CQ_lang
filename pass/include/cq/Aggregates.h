// Frozen interface (cq-arch). Changes only under cq-arch's freeze rule.
#pragma once

#include "cq/Lowering.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Instructions.h"

// Aggregates.h  (rules 25, 26)
namespace cq::aggr {
void lowerExtractValue(LoweringContext &, llvm::ExtractValueInst &);
void lowerInsertValue(LoweringContext &, llvm::InsertValueInst &);
void lowerVectorOp(LoweringContext &, llvm::Instruction &);
llvm::SmallVector<Operand, 4> flattenResult(LoweringContext &, const llvm::Value *);
}
