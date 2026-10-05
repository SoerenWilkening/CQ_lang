// Uncomputation.h — Thin per-function orchestrator for Phase 5 (PRD §2.2/§2.8/
// §2.10). Wired as the LAST mutation in both CQLoweringPass entry points, so
// `taint` is in its final post-lowering state. Composes the Phase-5 units
// (ChainWalk / FreePoint / InShadowAdjoint) + the EmitInverse spine; owns only
// the target-set partition, terminal selection, and emit ordering.
//
// Step 1 is a CONSERVATIVE slice (no ChainWalk / no full FreePoint / no
// in-shadow yet): it emits the adjoint + `cqrt_free` ONLY for a rotation-only,
// single-register terminal handle — a `cqrt_alloc_<W>` result whose every user
// is an uncontrolled `cqrt_ry/rz_<W>` gate on the handle, with a non-escaping
// post-dominating last use. Every other terminal is left untouched, so the
// pass is live in both entry points from commit 1 without disturbing the
// existing suite. Later steps generalize selection (Step 2), placement /
// measure / escape classification (Step 3), and the in-shadow controlled
// adjoint nested in the Phase-4 flag bracket (Step 4).

#ifndef CQ_IRPASS_UNCOMPUTATION_H_
#define CQ_IRPASS_UNCOMPUTATION_H_

#include "llvm/ADT/DenseMap.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

namespace llvm {
class DominatorTree;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;

// Walk every non-declaration function in `M`; for each selected tainted
// terminal handle, emit its whole-chain adjoint at the SSA last-use point
// followed by `cqrt_free`. Reads `taint` in its final post-lowering state.
void uncompute(llvm::Module &M, WidthDispatch &wd, TaintSet &taint);

// ── THE M-B INTERIOR DISCHARGE PLAN (bd test_C_libtooling-x67f) ──────────────
//
// The PURE-ANALYSIS half of the M-B interior partition, published so the M-C
// late reassignment round (`ArithLowering::lowerLateReassignments`) can ask
// "will this rail be zeroed and freed, and WHERE?" instead of reading an IR
// that has not been written yet.
//
// WHY IT EXISTS. `lowerOps` runs BEFORE `uncompute`, so M-C's prior-use fence
// (`priorUseIsSettled` arm (d)) could only ever see discharges some EARLIER
// emitter had already inlined — the Phase-4 flag strip. A rail the M-B spine is
// about to discharge looked exactly like an undischarged prior reader, so
// `a -= off` after a derived-condition region minted a fresh rail and the whole
// program then declined at the M-A guard with a message naming the wrong cause.
//
// WHAT IT IS AND IS NOT. `GateAt[G]` is the insertion point the interior
// partition WOULD use for the component containing forward gate `G`; every
// adjoint of that component is emitted strictly BEFORE it. It is a PREDICTION,
// and the only thing a consumer may do with it is DECLINE TO CONVERT when the
// prediction is missing or badly placed. It is never authority to emit: the
// planning runs again inside `uncompute`, on the post-conversion module, and it
// is THAT run which decides what is emitted. A prediction that stops holding
// costs a LEAK (clause (d) refuses a component whose borrowed parent is mutated
// inside its interval — and an M-C in-place gate IS such a mutation), never a
// misplaced adjoint.
//
// IT IS DELIBERATELY CONSERVATIVE ABOUT THE OTHER PARTITION. At emit the
// dead-terminal groups run FIRST and claim gates the interior partition then
// skips (`ReversedGates`/`ReversedRails`, Rule 8's single ownership). Those sets
// are empty when this plan is computed, so instead every gate the dead-terminal
// spine could POSSIBLY reach is WITHHELD from `GateAt`: the whole DAG recovered
// from EVERY terminal candidate, whether or not that group would go on to emit.
// That matters because that spine places its adjoints at a FreePoint with no
// clause-(d) scan behind it, so a mis-prediction there would NOT degrade to a
// leak.
//
// THE WHOLE ARGUMENT, ON THE FINAL MODULE RATHER THAN ON THE DELTA. The M-C
// fence walks EVERY user of the parent rail `P`, so for each producer reading
// `P` one of two things is true after the conversion: its rail was already
// `_unc`'d AND freed (arm (d) — and a `cqrt_free` user is what makes
// `recoverDataDag`'s closure scan mark a DAG `NotClosed`, so the terminal spine
// emits nothing for it), or it is in `GateAt` and therefore NOT in this
// superset. So no gate of any emit-time terminal DAG reads `P` — which also
// disposes of the in-place gate the conversion adds: the terminal spine would
// adjoint it only by visiting `P`, and visiting `P` makes its closure scan see
// those same unrecovered producer consumers and bail.
struct InteriorDischargePlan {
  llvm::DenseMap<const llvm::CallInst *, llvm::Instruction *> GateAt;
};

// Compute the plan for one function. Pure analysis — emits nothing, mutates
// nothing, diagnoses nothing (a `diagnose` here would double-fire against
// `uncompute`'s own).
InteriorDischargePlan planInteriorDischarges(llvm::Function &F, TaintSet &taint);

// ── THE WINDOW SCAN (bd test_C_libtooling-cmr9) ─────────────────────────────
//
// True iff no execution of any user of the rail `P` can MOVE `P`'s basis label
// strictly inside the window `(First, At)`: every user is proven label-preserving
// (a forward template read, a diagonal rotation, and, with `AdmitCloneCalls`, a
// clone call proven read-only on `P`), or provably outside the window on every
// path (the (W2) certificate: every path from it to `At` re-executes `First`),
// or a complete recorded restoring route. A non-call user (a φ/select alias, a
// store) or anything unproven answers false. `Opener`, when non-null, is the
// window's opening event, which the caller vouches does not move `P`.
//
// PRECONDITION: `First` dominates `At` and `First != At`.
//
// TWO CALLERS, ONE QUESTION (Rule 12):
//   * M-B clause (d), `borrowedParentsUnmoved` (Uncomputation.cpp): a borrowed
//     parent must hold, at the adjoints inserted before `At`, the label it held
//     when the first gate reading it ran. `Opener` is null.
//   * M-A clause 4, `recordIsExemptAt` (RotationLowering.cpp): a record measured
//     at `First` is still collapsed when the gate `At` fires only if nothing
//     writes it in between. `Opener` is the measurement.
bool railUnmovedInWindow(llvm::Value *P, llvm::CallInst *First,
                         llvm::Instruction *At, const llvm::DominatorTree &DT,
                         const TaintSet &taint, bool AdmitCloneCalls,
                         const llvm::Instruction *Opener);

}  // namespace cq

#endif  // CQ_IRPASS_UNCOMPUTATION_H_
