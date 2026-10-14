// RailBankUnrollUtil.h — bd `test_C_libtooling-01po.19`: LLVM-utility helpers of
// `unrollQuantumArrayWalks` (RailBankUnroll.h has the contract).

#ifndef CQ_IRPASS_RAILBANK_UNROLL_UTIL_H_
#define CQ_IRPASS_RAILBANK_UNROLL_UTIL_H_

#include <string>

namespace llvm {
class AssumptionCache;
class DominatorTree;
class Function;
class Loop;
class LoopInfo;
class ScalarEvolution;
}  // namespace llvm

namespace cq {

// The full-unroll count for `L`: its SCEV constant MAX trip when that is at most
// `MaxTrip` and agrees with any constant exact trip; 0 when not unrollable.
unsigned unrollTrip(llvm::Loop *L, llvm::ScalarEvolution &SE, unsigned MaxTrip);

// One full unroll of `L` by `Trip` (true iff `UnrollLoop` fully unrolled it).
bool fullyUnroll(llvm::Function &F, llvm::Loop *L, unsigned Trip,
                 llvm::DominatorTree &DT, llvm::LoopInfo &LI,
                 llvm::ScalarEvolution &SE, llvm::AssumptionCache &AC);

// The stock scalar cleanup a hand-unrolled source gets at `clang -O1`
// (`Full` adds SROA, EarlyCSE and InstCombine to InstSimplify + SimplifyCFG).
void runCleanup(llvm::Function &F, bool Full);

// `L`'s header printed as an operand (`%A`, `%12`), for the debug lever.
std::string headerName(const llvm::Loop *L);

}  // namespace cq

#endif  // CQ_IRPASS_RAILBANK_UNROLL_UTIL_H_
