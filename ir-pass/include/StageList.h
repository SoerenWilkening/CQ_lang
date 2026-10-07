// StageList.h — the one spelling of the stage sequence that main and a lifted
// clone share (bd p3kd.7.8, owner direction 2026-10-07, design note
// docs/design/clone-one-pipeline.md).
//
// `run()`, the `runOnFunction` unit shim and `buildClone` call these two drivers
// with their own `StageScope`: how taint is re-derived after a stage rewrites the
// IR (module `propagate`, the shim's filtered `propagate`, a clone's param-rooted
// reseed), the PredMux mode of the nested fixpoints, and the two stages one
// caller does not run. Every stage is module-scoped and acts only on values in
// the `TaintSet` it is given, so a clone's disjoint `cloneTaint` scopes the whole
// sequence to the clone (the precedent `lowerOps(M, wd, cloneTaint)` relies on).
#ifndef CQ_IRPASS_STAGE_LIST_H_
#define CQ_IRPASS_STAGE_LIST_H_

#include "llvm/ADT/STLFunctionalExtras.h"
#include <memory>

namespace llvm {
class Module;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;
struct SpecPlan;
struct ControlPlan;
struct PredMuxRailPhiRecord;

struct StageScope {
  // Re-derive `taint` after a stage changed the IR. Main: `taint =
  // propagate(M, wd)`; a lifted clone: `reseedCloneTaintFromParams`.
  llvm::function_ref<void()> Repropagate;
  // PredMux mode of the fixpoints nested in the loop pre-passes. Main: false; a
  // lifted clone: true (owner-ruling-clone-classical-control-2026-10-06).
  bool ClaimAll = false;
  // `collapseFlattenedLoopRails` (round 2 of the bounded-loop pass).
  bool CollapseLoopRails = true;
  // A lifted clone skips `declineQuantumReturnCalls` (see StageList.cpp).
  bool LiftedClone = false;
};

// The static-K unroll and the ctlz-idiom pre-passes, each a fixpoint with the
// PredMux fixpoint nested in it. `railPhiRec` is the caller's cross-claim record
// (bd woa0); the caller re-asks it after this returns.
void runLoopPrepasses(llvm::Module &M, TaintSet &taint,
                      PredMuxRailPhiRecord &railPhiRec, const StageScope &S);

// `lowerLoops` through the round-2 re-asks: the merge-phi peel, control
// detection and emission, the second loop round, `repropagateControlMerges` and
// the L1 re-asks after it. Returns the control plan (`lowerRotations` takes it).
std::unique_ptr<ControlPlan> runControlChain(llvm::Module &M, WidthDispatch &wd,
                                             TaintSet &taint, SpecPlan &plan6,
                                             const StageScope &S);

}  // namespace cq

#endif  // CQ_IRPASS_STAGE_LIST_H_
