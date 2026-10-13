// CallContract.h — bd bwfp: may a classical call run where its source did not?
// The call-site, parameter and return contracts a hoisted call (and every call
// in its tree) must meet. The poison dataflow behind the 6.5 hoist lives in
// PoisonFlow.cpp, its predicates in HoistRoute.cpp (bd dm7f.21, batch 053;
// `hoistedCallTreeIsUBFree`, `hoistedArgPoisonIsUB`:
// SpeculationSafety.h; `freezeDischargesHoistedArg`: ArmClassify.h). The strict
// totality walk (`classicalCallCanBeSpeculated`) stays in SpeculationSafety.cpp.
#ifndef CQ_CALL_CONTRACT_H
#define CQ_CALL_CONTRACT_H

#include "llvm/ADT/ArrayRef.h"
#include "llvm/IR/Attributes.h"

namespace llvm {
class AttributeSet;
class CallBase;
class CallInst;
class Function;
class Type;
}  // namespace llvm

namespace cq {

// An integer or floating-point scalar: the only values a hoisted call trades.
bool speculationScalar(llvm::Type *T);

// Every attribute in `AS` is one a defined value cannot violate: `noundef`,
// `zeroext`, `signext`, `inreg`.
bool inertAttrs(llvm::AttributeSet AS);

// Argument `N`'s attributes (call site and callee) hold for any defined value:
// the inert set and a `returned` every `ret` honours. `paramContractIsInert`
// also admits an intrinsic's `immarg` on a constant.
bool argAttrsAreInert(const llvm::CallBase *C, unsigned N);
bool paramContractIsInert(const llvm::CallInst *C, unsigned N);

// bd dm7f.25: the parameter attributes a speculation-safe twin DROPS, on its own
// parameters and at every call site pointed at it: a value constraint (`range`,
// `nofpclass`) a frozen value may violate, and a `returned` its frozen `ret`s
// no longer honour. Dropping one never makes a defined value poison.
// `twinParamContractHolds` is `paramContractIsInert` once those are dropped.
llvm::ArrayRef<llvm::Attribute::AttrKind> twinDroppedParamAttrs();
bool twinParamContractHolds(const llvm::CallInst *C, unsigned N);

// The call site's own return contract: a `range` proven from the callee body,
// or for ctpop/ctlz/cttz from the intrinsic's semantics; otherwise only the
// inert set. A violated value constraint makes the result poison.
bool callSiteReturnHolds(const llvm::CallInst &C);

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

// An intrinsic call's contract: its call-site return contract holds
// (`callSiteReturnHolds`), scalar arguments, and inert parameter attributes with
// an `immarg` only on a constant (`paramContractIsInert`). Its poison is
// `createsPoison`'s question (FlagProof.h), not this one (bd dm7f.20).
bool intrinsicContractHolds(const llvm::CallInst *C);

}  // namespace cq

#endif  // CQ_CALL_CONTRACT_H
