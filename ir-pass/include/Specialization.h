// Specialization.h — the Phase 6 specialization driver + the `:419` carve-out's
// membership predicate.
//
// `specialize()` is the step-14 stage (between `declineClassicalMuxes` and — via
// the bd d88e lift re-ask and the bd 2qyz stale re-sweep — `lowerRotations`,
// DD-1): it DRAINS the already-classified `SpecPlan.Pending`,
// and per Accept candidate clones → seeds a FRESH disjoint `cloneTaint` → drives
// the clone through the scoped data lowering → captures the forward stream →
// Bennett-wraps → retargets via `setCalledFunction`, deduping clones by
// `(callee, mask)` (C7). After the drain it re-marks each retargeted call result
// into the ORIGINAL `taint.Tainted` per `SpecRecord.ReturnTainted` (§2.7,
// C-Taint) — scrubbing the conservative call-result taint when the clone proves
// a classical return. It NEVER calls `uncompute` (the single module-wide
// uncompute at `:115`/`:174` owns reversal; the clone bodies are invisible to it
// because `cloneTaint` is never unioned into `taint`, DD-2).
//
// `shouldSpecialize` is the thin pure plan-membership lookup the carve-out
// consults (no second classifier — Rule 14).

#ifndef CQ_IRPASS_SPECIALIZATION_H_
#define CQ_IRPASS_SPECIALIZATION_H_

namespace llvm {
class CallInst;
class Module;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;
struct SpecPlan;

void specialize(llvm::Module &M, WidthDispatch &wd, TaintSet &taint,
                SpecPlan &plan);

// True iff `CI` is a proven-Accept site in `plan.Pending` (the carve-out
// suppresses `kMsgUnknownCallee` for it). The carve-out ALSO suppresses for
// `plan.Diagnosed` sites (already loud-declined with a specialization message);
// that check lives at the carve-out, not here.
bool shouldSpecialize(const llvm::CallInst *CI, const SpecPlan &plan);

}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZATION_H_
