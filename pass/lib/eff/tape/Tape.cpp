// Stub (cq-w0-scaffold). Every public function calls cq::unimplemented("<module>: <function>").
// Ownership passes to the module bead when wave 0 closes. Module eff-tape (cq-w1-eff-tape).
#include "cq/Effects.h"

namespace cq::tape {
void lowerHostEffect(LoweringContext &, llvm::CallBase &) { unimplemented("eff-tape: tape::lowerHostEffect"); }
void lowerNoreturn(LoweringContext &, llvm::CallBase &) { unimplemented("eff-tape: tape::lowerNoreturn"); }
} // namespace cq::tape
