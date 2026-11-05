// Rule 20 Host-resident: an access whose pointer operand is, through getelementptrs with untainted indices only, a
// host-resident object stays the plain LLVM instruction, when no quantum predicate is in scope at the access.
#include "cq/Bus.h"
#include "cq/Predicate.h"

namespace cq::bus {
bool hostAccess(LoweringContext &ctx, const llvm::Instruction &access) {
  return ctx.T.hostObjectOf(access, ctx.S) != nullptr && !ctx.T.controlTainted(access.getParent(), ctx.S) && !ctx.S.ctl;
}
}
