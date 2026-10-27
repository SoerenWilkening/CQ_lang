// TEST DOUBLE (tests/spine, cq-w0-construct). NOT the calls module. Stands in for pass/lib/calls
// while it is a stub (cq-by8): finalize is the identity, which is exact for a module with no clone,
// the only kind the straight-line examples produce. Every other entry point is an internal error.
#include "cq/Calls.h"

using namespace llvm;

namespace cq::calls {
Function *materialize(Module &, const Specialization &) { internalError("calls double: materialize"); }
void lowerLifted(LoweringContext &, CallBase &c) { internalError("calls double: lowerLifted", &c); }
void lowerIndirect(LoweringContext &, CallBase &c) { internalError("calls double: lowerIndirect", &c); }
void lowerDeclared(LoweringContext &, CallBase &c) { internalError("calls double: lowerDeclared", &c); }
void lowerVarargs(LoweringContext &, Instruction &i) { internalError("calls double: lowerVarargs", &i); }
void lowerAsm(LoweringContext &, CallBase &c) { internalError("calls double: lowerAsm", &c); }
void emitTwin(LoweringContext &, CallBase &c) { internalError("calls double: emitTwin", &c); }
void finalize(Module &M) {
  for (Function &F : M)
    if (F.getName().starts_with("__cq_q_"))
      internalError("calls double: finalize of a module with a clone", &F);
}
} // namespace cq::calls
