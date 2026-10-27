// Stub (cq-w0-scaffold). Every public function calls cq::unimplemented("<module>: <function>").
// Ownership passes to the module bead when wave 0 closes. Module loops-classical (cq-w1-loops-classical).
#include "cq/Loops.h"

namespace cq::loops {
void lowerClassical(LoweringContext &, llvm::Loop &, Case) { unimplemented("loops-classical: loops::lowerClassical"); }
} // namespace cq::loops
