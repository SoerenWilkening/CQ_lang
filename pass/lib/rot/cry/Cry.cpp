// Stub (cq-w0-scaffold). Every public function calls cq::unimplemented("<module>: <function>").
// Ownership passes to the module bead when wave 0 closes. Module rot-cry (cq-w1-rot-cry).
#include "cq/Rotation.h"

namespace cq::rot {
void lowerControlledTheta(LoweringContext &, llvm::CallInst &, llvm::Value *) { unimplemented("rot-cry: rot::lowerControlledTheta"); }
void lowerStatePrepMerge(LoweringContext &, llvm::PHINode &) { unimplemented("rot-cry: rot::lowerStatePrepMerge"); }
} // namespace cq::rot
