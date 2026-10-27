// Stub (cq-w0-scaffold). Every public function calls cq::unimplemented("<module>: <function>").
// Ownership passes to the module bead when wave 0 closes. Module eff-conc (cq-w1-eff-conc).
#include "cq/Effects.h"

namespace cq::conc {
void lowerAtomic(LoweringContext &, llvm::Instruction &) { unimplemented("eff-conc: conc::lowerAtomic"); }
void lowerVolatile(LoweringContext &, llvm::Instruction &) { unimplemented("eff-conc: conc::lowerVolatile"); }
void lowerThreadCall(LoweringContext &, llvm::CallBase &) { unimplemented("eff-conc: conc::lowerThreadCall"); }
void lowerSetjmp(LoweringContext &, llvm::CallBase &) { unimplemented("eff-conc: conc::lowerSetjmp"); }
void lowerLongjmp(LoweringContext &, llvm::CallBase &) { unimplemented("eff-conc: conc::lowerLongjmp"); }
} // namespace cq::conc
