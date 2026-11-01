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
// cq-0umd (166, rule 26): binds a composite orig field-wise where scalar leaf k has perLeaf[k] fields (a
// packed integer leaf, the coerced inner struct of { i64, double }: its fields, low bits first). The
// extractvalue of such a leaf is bound to its fields (spine unpacks them); insertvalue keeps the counts.
void bindLeafFields(LoweringContext &, const llvm::Value *orig, llvm::ArrayRef<Operand> fields,
                    llvm::ArrayRef<unsigned> perLeaf);
}
