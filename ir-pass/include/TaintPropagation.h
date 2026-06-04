// TaintPropagation.h — Forward taint propagation from quantum rotation
// sources. Originally inline in `CQLoweringPass.cpp` step 4.
//
// Contract: walk the module, collect every `@cq_theta_<sfx>` (rotation
// source), `@cq_phi_<sfx>` (rotation that propagates but does not
// introduce taint), and `@cq_measure_<sfx>` (sink) call site in
// basic-block order, seed the taint set with each theta's RESULT SSA
// value, and forward-propagate through user instructions. Measurement
// stops propagation — it is the canonical point where quantum state
// becomes classical. A `@cq_phi_<sfx>` on a tainted operand is reached by
// propagation as an ordinary user, so its result stays tainted (Rz
// preserves the quantum value); a phi on a classical operand is still
// collected so the lowering can delete it (else an unresolved
// `@cq_phi_*` extern is a Stage-3 link error). The source/sink sets span
// every suffix in `WidthDispatch::allSuffixes()`.
//
// All call sites are collected into `TaintSet` so the rotation / opcode /
// measure lowering passes do not re-walk the module. The pass operates on
// plain scalar SSA — `@cq_theta_<sfx>` returns the suffix's natural ABI
// scalar (no mid-struct wrapper, no extractvalue/insertvalue traffic).

#ifndef CQ_IRPASS_TAINT_PROPAGATION_H_
#define CQ_IRPASS_TAINT_PROPAGATION_H_

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include <set>

namespace cq {

class WidthDispatch;

struct TaintSet {
  // Front-end intrinsic call sites collected during the propagation walk,
  // in basic-block order. `ThetaCalls` seeds the taint sources and feeds
  // `RotationLowering`; `PhiCalls` is collected unconditionally (a phi on a
  // classical operand must still be deleted) but does NOT seed taint;
  // `MeasureCalls` is the work list for `MeasureLowering`. Collecting them
  // here avoids re-walking the module from those passes.
  llvm::SmallVector<llvm::CallInst *, 8> ThetaCalls;
  llvm::SmallVector<llvm::CallInst *, 8> PhiCalls;
  llvm::SmallVector<llvm::CallInst *, 8> MeasureCalls;

  // All SSA values that carry quantum taint at any point in the pipeline.
  // `RotationLowering` mutates this set (inserts alloc handles minted at
  // classical-operand thetas); `OpcodeLowering` mutates it again as tainted
  // adds get rewritten to template-call results.
  std::set<llvm::Value *> Tainted;

  // SSA-value birth order for stable Q+Q operand canonicalization,
  // formerly carried by the now-removed rebind side-table.
  // `RotationLowering` seeds
  // one slot per minted alloc handle (in basic-block order); `OpcodeLowering`
  // extends it for template results and reads it back to order commutative
  // adds so the lowered trace is stable across clang versions. 0 means
  // "not assigned"; only canonicalized values have non-zero entries.
  llvm::DenseMap<llvm::Value *, unsigned> BirthOrder;
  unsigned NextBirth = 1;

  // Phase 4 (PRD §2.8). Logical ABI width of each quantum handle, recorded
  // at its rotation mint point (`RotationLowering`) from the `cq_theta`
  // classical operand. Read when building Q+Q control conditions (PRD §2.4),
  // where both operands are i32-laundered handles and the width is otherwise
  // unrecoverable. Populated and consumed by later WPs; unread this WP.
  llvm::DenseMap<llvm::Value *, llvm::StringRef> HandleWidth;

  // Phase 4 (PRD §2.10). Maps an in-shadow op result to its controlling i32
  // flag handle. Built by the control-flag / flag-conjunction passes and
  // consumed by controlled substitution and `OpcodeLowering`. The region
  // list and in-shadow set are NOT here — they ride the `ControlPlan` struct
  // returned by region detection (epic D4). Populated by later WPs; unread
  // this WP.
  llvm::DenseMap<llvm::Value *, llvm::Value *> ControlFlag;

  // Phase 5 Step 0 (Phase-5 IMPLEMENTATION §2.4 / §4.0). Maps a control flag to
  // the FIRST instruction of its Phase-4 teardown — the `_inv` compare (plain)
  // or `cqrt_toffoli_inv`/`cqrt_x` bracket head (conjunction) minted by
  // `emitUncompute` (`ControlledLowering.cpp`). That teardown is NOT discoverable
  // by SSA dataflow: it runs over the condition's DATA handles, not the flag, and
  // the merge block that anchored it is erased post-linearization. Phase 5's
  // in-shadow keep-alive (PRD §2.7) reads `FlagTeardown[ControlFlag[handle]]` and
  // anchors the controlled data-adjoint immediately before this instruction so
  // the adjoint nests OUTSIDE the entire (LIFO) flag teardown. Populated by
  // `emitUncompute`; unread until Phase 5 Step 4.
  llvm::DenseMap<llvm::Value * /*flag*/, llvm::CallInst * /*firstTeardown*/>
      FlagTeardown;
};

// Walks every non-declaration function in `M`, collects theta/phi/measure
// intrinsic call sites in basic-block order, and runs the forward taint
// propagation. The work-list is seeded with each theta's RESULT (the
// suffix's natural ABI scalar — plain SSA, no struct wrapper).
TaintSet propagate(llvm::Module &M, WidthDispatch &wd);

}  // namespace cq

#endif  // CQ_IRPASS_TAINT_PROPAGATION_H_
