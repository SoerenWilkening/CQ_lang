#ifndef CQ_SPECULATION_SAFETY_H
#define CQ_SPECULATION_SAFETY_H

namespace llvm {
class CallInst;
class Function;
class Instruction;
}
namespace cq {
struct TaintSet;

// A scalar classical call may be hoisted only if every defined scalar input
// yields a defined result without memory, cycles, or immediate UB.
bool classicalCallCanBeSpeculated(const llvm::CallInst *Call);

// Remember source instructions while moving them. After data lowering, only
// classical source instructions survive. Stabilize their observable literals
// before the clone mirror, or after main's adjoints have been emitted.
void markSpeculatedValue(llvm::Instruction &I);
void stabilizeSpeculatedValues(llvm::Function &F, const TaintSet &Taint);
// PHI replacement creates predicate users before the outer pass re-seeds taint.
void refreshSpeculationTaint(llvm::Function &F, TaintSet &Taint);
}
#endif
