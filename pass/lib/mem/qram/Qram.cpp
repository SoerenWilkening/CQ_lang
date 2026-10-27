// Stub (cq-w0-scaffold). Every public function calls cq::unimplemented("<module>: <function>").
// Ownership passes to the module bead when wave 0 closes. Module mem-qram (cq-w1-mem-qram).
#include "cq/Memory.h"

namespace cq::mem {
void lowerQramLoad(LoweringContext &, llvm::LoadInst &) { unimplemented("mem-qram: mem::lowerQramLoad"); }
void lowerQramStore(LoweringContext &, llvm::StoreInst &) { unimplemented("mem-qram: mem::lowerQramStore"); }
void allocateQram(LoweringContext &, llvm::Instruction &) { unimplemented("mem-qram: mem::allocateQram"); }
void endQramLifetime(LoweringContext &, ObjectId, llvm::Instruction *) { unimplemented("mem-qram: mem::endQramLifetime"); }
void lowerMemIntrinsic(LoweringContext &, llvm::MemIntrinsic &) { unimplemented("mem-qram: mem::lowerMemIntrinsic"); }
} // namespace cq::mem
