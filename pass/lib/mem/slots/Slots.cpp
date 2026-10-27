// Stub (cq-w0-scaffold). Every public function calls cq::unimplemented("<module>: <function>").
// Ownership passes to the module bead when wave 0 closes. Module mem-slots (cq-w1-mem-slots).
#include "cq/Memory.h"

namespace cq::mem {
void lowerSlotLoad(LoweringContext &, llvm::LoadInst &) { unimplemented("mem-slots: mem::lowerSlotLoad"); }
void lowerSlotStore(LoweringContext &, llvm::StoreInst &) { unimplemented("mem-slots: mem::lowerSlotStore"); }
void allocateSlots(LoweringContext &, llvm::Instruction &) { unimplemented("mem-slots: mem::allocateSlots"); }
void endSlotLifetime(LoweringContext &, ObjectId, llvm::Instruction *) { unimplemented("mem-slots: mem::endSlotLifetime"); }
} // namespace cq::mem
