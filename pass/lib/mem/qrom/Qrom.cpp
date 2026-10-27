// Stub (cq-w0-scaffold). Every public function calls cq::unimplemented("<module>: <function>").
// Ownership passes to the module bead when wave 0 closes. Module mem-qrom (cq-w1-mem-qrom).
#include "cq/Memory.h"

namespace cq::mem {
void lowerQromLoad(LoweringContext &, llvm::LoadInst &) { unimplemented("mem-qrom: mem::lowerQromLoad"); }
} // namespace cq::mem
