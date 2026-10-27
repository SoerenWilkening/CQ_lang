// Stub (cq-w0-scaffold). Every public function calls cq::unimplemented("<module>: <function>").
// Ownership passes to the module bead when wave 0 closes. Module calls (cq-w1-calls). calls::classify is the spine's.
// calls::finalize is implemented in Finalize.cpp (cq-by8, owner ruling option (a)).
#include "cq/Calls.h"

namespace cq::calls {
llvm::Function *materialize(llvm::Module &, const Specialization &) { unimplemented("calls: calls::materialize"); }
void lowerLifted(LoweringContext &, llvm::CallBase &) { unimplemented("calls: calls::lowerLifted"); }
void lowerIndirect(LoweringContext &, llvm::CallBase &) { unimplemented("calls: calls::lowerIndirect"); }
void lowerDeclared(LoweringContext &, llvm::CallBase &) { unimplemented("calls: calls::lowerDeclared"); }
void lowerVarargs(LoweringContext &, llvm::Instruction &) { unimplemented("calls: calls::lowerVarargs"); }
void lowerAsm(LoweringContext &, llvm::CallBase &) { unimplemented("calls: calls::lowerAsm"); }
void emitTwin(LoweringContext &, llvm::CallBase &) { unimplemented("calls: calls::emitTwin"); }
} // namespace cq::calls
