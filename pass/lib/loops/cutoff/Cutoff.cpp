// Stub (cq-w0-scaffold). Every public function calls cq::unimplemented("<module>: <function>").
// Ownership passes to the module bead when wave 0 closes. Module loops-cutoff (cq-w1-loops-cutoff).
#include "cq/Loops.h"

namespace cq::loops {
void lowerCutoff(LoweringContext &, llvm::Loop &, unsigned, std::optional<uint64_t>) { unimplemented("loops-cutoff: loops::lowerCutoff"); }
std::optional<uint64_t> tripBound(const llvm::Loop &, llvm::ScalarEvolution &) { unimplemented("loops-cutoff: loops::tripBound"); }
unsigned resolveK(const llvm::Function &, const KOptions &) { unimplemented("loops-cutoff: loops::resolveK"); }
void lowerQuantumDepthRecursion(LoweringContext &, llvm::CallBase &, unsigned, std::optional<uint64_t>) { unimplemented("loops-cutoff: loops::lowerQuantumDepthRecursion"); }
} // namespace cq::loops
