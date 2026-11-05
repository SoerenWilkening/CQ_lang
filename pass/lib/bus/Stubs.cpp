// The constructions of the one bus not built yet (CR rules 5, 16, 20 to 22): an internal error per entry, removed as
// each lands in its own file (pass/lib/bus/{Bus,InPlace,Intrinsics,Alloc,Version}.cpp).
#include "cq/Bus.h"
#include "llvm/Support/ErrorHandling.h"

using namespace llvm;

namespace cq::bus {
namespace {
[[noreturn]] void stop(const char *what) {
  report_fatal_error(Twine("cq: unimplemented: bus: ") + what, /*gen_crash_diag=*/false);
}
} // namespace

void lowerMemIntrinsic(LoweringContext &, MemIntrinsic &) { stop("lowerMemIntrinsic"); }
void lowerCopy(LoweringContext &, Operand, Operand, Operand, Value *, Instruction &) { stop("lowerCopy"); }
void lowerAlloc(LoweringContext &, Instruction &) { stop("lowerAlloc"); }
void lowerRealloc(LoweringContext &, CallBase &) { stop("lowerRealloc"); }
unsigned K2(const LoweringContext &) { stop("K2"); }
}
