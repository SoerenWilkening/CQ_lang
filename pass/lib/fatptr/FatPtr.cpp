// Stub (cq-w0-scaffold). Every public function calls cq::unimplemented("<module>: <function>").
// Ownership passes to the module bead when wave 0 closes. Module fatptr (cq-w1-fatptr).
#include "cq/FatPtr.h"

namespace cq::fatptr {
FatPtr lower(LoweringContext &, const llvm::Value *) { unimplemented("fatptr: fatptr::lower"); }
void lowerLoad(LoweringContext &, llvm::LoadInst &) { unimplemented("fatptr: fatptr::lowerLoad"); }
void lowerStore(LoweringContext &, llvm::StoreInst &) { unimplemented("fatptr: fatptr::lowerStore"); }
llvm::Value *lowerCompare(LoweringContext &, llvm::ICmpInst &) { unimplemented("fatptr: fatptr::lowerCompare"); }
void lowerPtrToInt(LoweringContext &, llvm::Instruction &) { unimplemented("fatptr: fatptr::lowerPtrToInt"); }
void lowerIntToPtr(LoweringContext &, llvm::Instruction &) { unimplemented("fatptr: fatptr::lowerIntToPtr"); }
Triple passAcrossCall(LoweringContext &, const llvm::Value *) { unimplemented("fatptr: fatptr::passAcrossCall"); }
} // namespace cq::fatptr
