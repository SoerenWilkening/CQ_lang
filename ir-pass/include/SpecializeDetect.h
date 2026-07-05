// SpecializeDetect.h — the pure-analysis specialization pre-pass (C-Plan).
//
// Mirrors `ControlDetect`: pure analysis by SSA/pointer identity, NO IR
// mutation, runs BEFORE `declineTaintEscapes` in both pipeline entry points.
// Walks `M` for tainted-arg DIRECT `CallInst` sites, computes the LSB=param0
// taint mask, and runs the single authoritative `classifyCandidate`:
//   * Accept  → the site enters `SpecPlan.Pending` (membership ⇔ proven
//     specializable — the only thing the `:419` carve-out's `shouldSpecialize`
//     consults).
//   * a CLASSIFIED reject (cq_*, measure, in-body control, recursion, fp/i128,
//     arity) → LOUD `diagnoseReject` HERE (source-located on the offending
//     instruction) + the site is recorded in `SpecPlan.Diagnosed` so the
//     carve-out suppresses its generic `kMsgUnknownCallee` (exactly one message).
//   * a SHAPE reject (invoke/callbr → not a `CallInst`; indirect → null callee;
//     declaration-only → no IR) → SILENT here; the site is neither in `Pending`
//     nor `Diagnosed`, so the carve-out fires `kMsgUnknownCallee` (DD-2 no-IR
//     contract; keeps `_opaque_call`/`_deep_arg`/`_indirect_call` green).
//
// bd 9paa (round-2 spec DETECTION): the SAME walk is RE-RUN from
// `repropagateControlMerges` on the second-propagation taint (the DETECTION twin
// of `replanReseedSpecialization`), so a wholly-new candidate `g(%out)` whose args
// were ALL classical at round 1 (never in the plan) is detected and cloned by the
// step-262 driver. A NON-null `reseed` selects round-2 mode: only a site whose
// newly-tainted arg is a reseed value, and not already Pending/Diagnosed, is
// considered. `reseed == nullptr` (the round-1 call sites) is byte-unchanged.

#ifndef CQ_IRPASS_SPECIALIZE_DETECT_H_
#define CQ_IRPASS_SPECIALIZE_DETECT_H_

#include "llvm/ADT/SmallPtrSet.h"

namespace llvm {
class Module;
class Value;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;
struct SpecPlan;

// `reseed` (bd 9paa): non-null ⇒ round-2 re-detection restricted to sites reading
// a reseed value (the control-merge `%out` or a `%out` derivation) and not already
// Pending/Diagnosed. Null (default) ⇒ round-1 detection over every tainted-arg
// candidate, unchanged.
void detectSpecializations(llvm::Module &M, const TaintSet &taint,
                           WidthDispatch &wd, SpecPlan &out,
                           const llvm::SmallPtrSetImpl<llvm::Value *> *reseed =
                               nullptr);

}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZE_DETECT_H_
