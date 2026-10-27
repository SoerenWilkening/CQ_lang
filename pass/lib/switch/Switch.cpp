// Stub (cq-w0-scaffold). Every public function calls cq::unimplemented("<module>: <function>").
// Ownership passes to the module bead when wave 0 closes. Module switch (cq-w1-switch).
#include "cq/Switch.h"

namespace cq::sw {
EdgePreds switchEdges(const llvm::SwitchInst &, const TaintInfo &, const Specialization &) { unimplemented("switch: sw::switchEdges"); }
void lowerSwitch(LoweringContext &, llvm::SwitchInst &) { unimplemented("switch: sw::lowerSwitch"); }
} // namespace cq::sw
