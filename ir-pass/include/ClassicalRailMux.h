// ClassicalRailMux.h — bd dm7f.15 / dm7f.16: a CLASSICAL-condition `select` or
// merge `phi` over quantum values in a top-level (non-clone) function, lowered as
// a classical CHOICE OF RAIL HANDLE.
//
// THE SHAPE. `int r = d != 0 ? b + c / d : b;` with `b` quantum keeps its
// classical branch at -O1 (the division cannot be speculated) and reaches
// `declineClassicalMuxes` as `phi [%t, %arm], [%b, %entry]` under a CLASSICAL
// branch; `r = cls(x1) ? q0 : x1` inside a quantum arm reaches it as a
// classical-condition `select`. Both declined `cq taint escape: tainted value
// muxed by a classical-condition {phi,select}` on the ground that "the
// record/uncompute story is path-dependent and unproven". That is bookkeeping,
// not physics (CLAUDE.md L5): the condition is classical, the hardware knows it,
// and which rail holds the value is a classical fact.
//
// THE LOWERING (owner question dm7f.15 (a) vs (b), chosen here; both realize the
// same unitary). A phi KEEPS its classical branch and becomes a phi of i32 rail
// handles (option (a), the bd zujr loop-carried-handle precedent); a select —
// which -O1 already speculated, so both arms exist on every path — becomes a
// select of i32 rail handles through the shared `rewriteRailSelects`
// (CloneRailSelect.h, the bd p3kd.7.2 clone rewrite; called, never copied). A
// classical arm/incoming is materialized to its own |v> rail with
// `materializeCopySource` (the one materializer). Option (b) (speculate the
// classical branch and select) was NOT taken for main: it needs a totalized arm
// (a safe divisor, a clamped index) that main has no builder for, and it would
// compute every quantum arm op on the classically UNTAKEN path too, leaving that
// garbage rail entangled with its source (main has no Bennett wrap to reverse
// it). Keeping the branch computes each arm exactly where the source does.
//
// THE SOUNDNESS ARGUMENT, per basis state. The condition (or the taken edge) is
// classical, so on every execution the router names exactly one rail, the same
// one for every basis state of the quantum registers. Every forward consumer and
// every later adjoint of a consumer reads that SAME SSA router value, which is
// fixed once defined, so forward and reverse name the same rail. The router is
// not a gate and mints nothing: it is never freed (`railBornZero` is false for a
// phi/select root, so the uncompute spine freezes it), and each leaf rail it
// reads keeps a non-call user, so the spine's closure scan marks every DAG that
// contains a leaf `NotClosed` (a leak, R5, never a dirty free). A materialized
// classical rail is untainted separable classical data, left allocated.
//
// THE INVARIANT: A ROUTER IS READ-ONLY. Everywhere else in the pass a handle-
// valued SSA value owns its rail; a router does not — its rail IS one of its leaf
// rails, which other names still read (`r` and `b` are the same qubits on one
// path). So nothing may write the router or any leaf after the choice, and the
// RECORD proves it, position-free (ClassicalRailMuxFence.h, R1-R4): no
// non-diagonal gate on any leaf wire (WireWalk, which walks THROUGH the router, so
// `cq_theta(&r, ·)` counts), no loop-owned in-place rail op, every router user a
// reader, no measurement of the alias set before a coherent read of it, and no
// emitted write (in-place gate, park `cqrt_cswap`, copy-in) on it. Position-free
// because the straight-line stale-record and stale-reader guards cannot see a
// read THROUGH a router (their backward closure stops at a phi/select) and the
// uncompute spine's parent-unmoved reasoning does not follow a router to its
// leaves. The one write a LATER stage could still pick is the M-C in-place
// reassignment of a router PARENT (`r ^ 5` lowered onto the router's own rail,
// i.e. onto a leaf — measured); its shared fence refuses any
// `isClassicalRailMuxValue` parent (ArithLowering.cpp `inPlaceFenceHolds`, both
// rounds). Every program the fence refuses declines loudly with the guard's own
// string, as before; the over-declines among them (`if (c) cq_theta(&q,a);
// r = d ? q : x;`, a rotation of a router whose leaves are dead) are gaps to
// close, not limits. Also outside the record: a router or a leaf on a CFG cycle
// (the loop-rail machinery owns those), a leaf that is a load, an argument or an
// unrecorded phi/select, and a type with no `cqrt_alloc_<W>` for a classical arm.
// Leaves are collected THROUGH nested router-shaped operands, so `a ? (b ? q :
// x) : y` fences `q`.
//
// L1 (THE ROUND-2 AND SCRUB WINDOWS). `declineClassicalMuxes` runs after the
// round-2 control fixpoint, so the record reads final control taint. Between the
// record and the rewrite only `specialize()` changes taint, and only by
// SHRINKING it (its scrub); so the rewrite RE-ASKS each arm's taint at the taint
// that is there: a recorded-quantum arm the scrub made classical is materialized
// (it is a classical value now), and a router left with no quantum arm is a
// classical select/phi the backend lowers natively. A clone never reaches this
// file: `declineClassicalMuxes` is not on the clone stage list, and a clone's
// classical branches are speculated by PredMux `claimAll` and its classical
// selects recorded by `recordCloneRailSelects` and rewritten by the same
// `rewriteRailSelects` (owner ruling owner-ruling-clone-classical-control-
// 2026-10-06).
//
// RECORD THEN REWRITE (L3 gate set). Every RECORDED router must be REWRITTEN (its
// original instruction erased, its uses reading an i32 router) or be found
// classical at rewrite time; the set difference recorded − (rewritten ∪
// classical) must be empty, else the pass fails loudly. No path leaves a
// classical select/phi over quantum values unlowered.

#ifndef CQ_IRPASS_CLASSICAL_RAIL_MUX_H_
#define CQ_IRPASS_CLASSICAL_RAIL_MUX_H_

namespace llvm {
class Instruction;
class Module;
class Value;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;

// Is `T` a CLASSICAL `br`/`switch` (an unconditional `br`, or a conditional
// `br`/`switch` on an untainted condition)? Exotic terminators (invoke,
// indirectbr, ...) are unproven shapes: false. Spelled over
// `isTaintedBranchTerminator` (TaintedControlDependence.h, bd dm7f.24), never a
// second test of the condition. Moved here from TaintPropagation.cpp (the
// one-register lift's (5) asks it too).
bool terminatorIsClassical(const llvm::Instruction *T, const TaintSet &taint);

// Start a module's record (clears any record a previous module left behind).
// Called once at the top of `declineClassicalMuxes`.
void beginClassicalRailMuxRecord();

// `Mux` is a LIVE select/phi reading a tainted value under classical control that
// neither the one-register lift nor the bd zujr carried-handle accept took. Prove
// the fence above and RECORD it for the post-`lowerOps` rewrite. Pure analysis:
// mutates nothing. True iff recorded (the caller then does not decline); false
// leaves the caller's loud decline exactly as before.
bool recordClassicalRailMux(llvm::Instruction *Mux, const TaintSet &taint);

// THE POST-`lowerOps` HOOK, in BOTH entry points (CQLoweringPass.cpp), before
// `lowerMeasures` (which needs an i32 handle operand): rewrite every recorded
// router into a select/phi of rail handles, then check the gate set. Reads the
// record once and clears it. Returns true iff it declined.
bool rewriteClassicalRailMuxes(llvm::Module &M, TaintSet &taint,
                               WidthDispatch &wd);

// Is `V` a rail router `rewriteClassicalRailMuxes` BUILT in this module (an
// identity question on its own record, `WeakVH`: never a shape or name test)?
// Its one reader is `FreePoint::computeFreePoint` (the coordinator's L1 carve-out,
// batch 053): a terminal whose user is such a router is LEFT ALLOCATED
// (`Escaped`: no adjoint, no free, R5), the same verdict the DAG closure scan
// already gives every DAG that reaches the leaf (a non-call user → `NotClosed`).
// The record is cleared by `beginClassicalRailMuxRecord`, so a clone built inside
// `specialize()` (before the hook) and any other phi/select — a bd zujr
// carried-handle phi included — is never a member.
bool isClassicalRailMuxRouter(const llvm::Value *V);

// Is `V` a RECORDED classical rail mux still pending its rewrite (the source-typed
// select/phi `declineClassicalMuxes` recorded), or a router the rewrite built?
// The M-C in-place fence (`ArithLowering::inPlaceFenceHolds`, both rounds) refuses
// such a parent: a router's rail IS one of its leaf rails, which other SSA names
// still read, so the fence's "the parent is dead after the site" scan over the
// parent's own users is not a deadness proof for it. Identity on the record,
// never a shape test.
bool isClassicalRailMuxValue(const llvm::Value *V);

}  // namespace cq

#endif  // CQ_IRPASS_CLASSICAL_RAIL_MUX_H_
