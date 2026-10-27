// Stub (cq-w0-scaffold). Every public function calls cq::unimplemented("<module>: <function>").
// Ownership passes to the module bead when wave 0 closes. Module eff-invert (cq-w1-eff-invert).
#include "cq/Effects.h"

namespace cq::invert {
void lowerRegion(LoweringContext &, llvm::CallInst &, llvm::CallInst &) { unimplemented("eff-invert: invert::lowerRegion"); }
} // namespace cq::invert
