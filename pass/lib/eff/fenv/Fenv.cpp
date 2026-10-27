// Stub (cq-w0-scaffold). Every public function calls cq::unimplemented("<module>: <function>").
// Ownership passes to the module bead when wave 0 closes. Module eff-fenv (cq-w1-eff-fenv).
#include "cq/Effects.h"

namespace cq::fenv {
void lowerConstrained(LoweringContext &, llvm::CallBase &) { unimplemented("eff-fenv: fenv::lowerConstrained"); }
void lowerFenvCall(LoweringContext &, llvm::CallBase &) { unimplemented("eff-fenv: fenv::lowerFenvCall"); }
} // namespace cq::fenv
