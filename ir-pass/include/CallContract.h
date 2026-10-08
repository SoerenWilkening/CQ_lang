// CallContract.h — bd bwfp: may a classical call run where its source did not?
// The call-site, parameter and return contracts a hoisted call (and every call
// in its tree) must meet, and the poison dataflow behind the 6.5 hoist
// (`hoistedCallTreeIsUBFree`, `hoistedArgPoisonIsUB`: SpeculationSafety.h;
// `freezeDischargesHoistedArg`: ArmClassify.h). The strict totality walk
// (`classicalCallCanBeSpeculated`) stays in SpeculationSafety.cpp and asks these.
#ifndef CQ_CALL_CONTRACT_H
#define CQ_CALL_CONTRACT_H

namespace llvm {
class AttributeSet;
class CallInst;
class Function;
class Type;
}  // namespace llvm

namespace cq {

// An integer or floating-point scalar: the only values a hoisted call trades.
bool speculationScalar(llvm::Type *T);

// Executing the call site is defined (`callExecutionIsDefined`), its result is
// a scalar, and it carries no poison-generating flags or metadata.
bool basicCallContractHolds(const llvm::CallInst *C);

// Every value-constraining return attribute in `AS` holds for `F`'s body: a
// `range` proven from each `ret` (LLVM's range and known-bits facts), anything
// beyond the inert set (`noundef`/`zeroext`/`signext`/`inreg`) refused. A
// declaration proves no range.
bool returnAttrsHold(llvm::AttributeSet AS, const llvm::Function &F);

// `basicCallContractHolds`, scalar arguments with inert attributes on call site
// and callee (`returned` only where every `ret` returns that parameter), and the
// call site's return contract proven from the callee body.
bool callContractIsInert(const llvm::CallInst *C);

// An intrinsic call's contract: inert return and parameter attributes, an
// `immarg` only on a constant.
bool intrinsicContractHolds(const llvm::CallInst *C);

}  // namespace cq

#endif  // CQ_CALL_CONTRACT_H
