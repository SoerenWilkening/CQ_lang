// Stub (cq-w0-scaffold). Every public function calls cq::unimplemented("<module>: <function>").
// Ownership passes to the module bead when wave 0 closes. Module aggr (cq-w1-aggr).
#include "cq/Aggregates.h"

namespace cq::aggr {
void lowerExtractValue(LoweringContext &, llvm::ExtractValueInst &) { unimplemented("aggr: aggr::lowerExtractValue"); }
void lowerInsertValue(LoweringContext &, llvm::InsertValueInst &) { unimplemented("aggr: aggr::lowerInsertValue"); }
void lowerVectorOp(LoweringContext &, llvm::Instruction &) { unimplemented("aggr: aggr::lowerVectorOp"); }
llvm::SmallVector<Operand, 4> flattenResult(LoweringContext &, const llvm::Value *) { unimplemented("aggr: aggr::flattenResult"); }
} // namespace cq::aggr
