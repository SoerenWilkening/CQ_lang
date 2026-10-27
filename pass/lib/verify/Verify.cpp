// Stub (cq-w0-scaffold). Every public function calls cq::unimplemented("<module>: <function>").
// Ownership passes to the module bead when wave 0 closes. Module verify (cq-w0-verify).
#include "cq/Common.h"
#include "cq/Verify.h"

namespace cq {
void verifyLowered(const llvm::Module &, const VerifyOptions &) { unimplemented("verify: verifyLowered"); }
} // namespace cq
