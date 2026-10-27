// Stub (cq-w0-scaffold). Every public function calls cq::unimplemented("<module>: <function>").
// Ownership passes to the module bead when wave 0 closes. Module rot-qangle (cq-w1-rot-qangle).
#include "cq/Rotation.h"

namespace cq::rot {
void lowerQuantumAngleTheta(LoweringContext &, llvm::CallInst &, llvm::Value *) { unimplemented("rot-qangle: rot::lowerQuantumAngleTheta"); }
void lowerQuantumAnglePhase(LoweringContext &, llvm::CallInst &, llvm::Value *) { unimplemented("rot-qangle: rot::lowerQuantumAnglePhase"); }
} // namespace cq::rot
