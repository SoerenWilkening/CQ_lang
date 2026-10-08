#ifndef CQ_SPECULATION_SAFETY_H
#define CQ_SPECULATION_SAFETY_H

namespace llvm {
class CallBase;
class CallInst;
class Function;
class Instruction;
}
namespace cq {
struct TaintSet;

// A scalar classical call may be hoisted only if every defined scalar input
// yields a defined result without memory, cycles, or immediate UB.
bool classicalCallCanBeSpeculated(const llvm::CallInst *Call);

// bd bwfp — the call-site half of every classical-call hoist: executing the call
// itself is not UB (direct callee, matching calling convention, no operand
// bundle, not noreturn/convergent/noduplicate/musttail/returns_twice).
bool callExecutionIsDefined(const llvm::CallInst *Call);

// bd bwfp — the 6.5 hoist's question: running `Call` on a basis state its guard
// excluded introduces no UB. The 6.5 owner deliberately lets a poison RESULT
// through (it is never merged on a shielded state), so it does not need the
// strict proof above. It needs: the call site's contract (above), inert
// parameter attributes on the call itself (a `range`/`nonnull` with `noundef` is
// UB for a defined but out-of-domain argument), and no poison reaching a
// `noundef` SINK anywhere in the call tree (a `noundef` return, an inner call's
// `noundef` parameter), where an unproven `range`/`nofpclass` on any return is a
// poison source — a dataflow over the bodies, with every argument whose
// poison would reach one frozen (`hoistedArgPoisonIsUB`). Inner calls must also
// match their callee's calling convention and carry inert parameter contracts.
bool hoistedCallTreeIsUBFree(const llvm::CallInst *Call);

// bd bwfp — would a poison argument `N` of the hoisted `Call` be UB? Yes for a
// `noundef` parameter (bd 9hea), and when the call tree forwards that poison to
// a `noundef` sink. The 6.5 claim and emitter ask this, through
// `freezeDischargesHoistedArg`, before the hoist.
bool hoistedArgPoisonIsUB(const llvm::CallBase *Call, unsigned N);

// Remember source instructions while moving them. After data lowering, only
// classical source instructions survive. Stabilize their observable literals
// before the clone mirror, or after main's adjoints have been emitted.
void markSpeculatedValue(llvm::Instruction &I);
void stabilizeSpeculatedValues(llvm::Function &F, const TaintSet &Taint);
// PHI replacement creates predicate users before the outer pass re-seeds taint.
void refreshSpeculationTaint(llvm::Function &F, TaintSet &Taint);
}
#endif
