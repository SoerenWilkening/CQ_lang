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

#ifndef CQ_IRPASS_SPECIALIZE_DETECT_H_
#define CQ_IRPASS_SPECIALIZE_DETECT_H_

namespace llvm {
class Module;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;
struct SpecPlan;

void detectSpecializations(llvm::Module &M, const TaintSet &taint,
                           WidthDispatch &wd, SpecPlan &out);

}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZE_DETECT_H_
